package vgb.ui

import cats.effect.IO
import tyrian.*
import tyrian.Html.*
import org.scalajs.dom.document
import org.scalajs.dom.window
import vgb.game.{Main => VgbGame}
import vgb.common.*

import scala.scalajs.js.annotation.*
import scala.concurrent.duration.DurationDouble
import vgb.ui.models.components.ContextMenuComponent
import vgb.ui.models.components.MainMenuComponent
import indigo.shared.collections.Batch
import indigo.shared.datatypes.Point
import vgb.common.{MenuItem, MenuSeparator}
import vgb.ui.models.UiModel
import vgb.ui.scenes.CreatorModel
import tyrian.cmds.Logger

enum Msg:
  case NoOp
  case RetryIndigo
  case IndigoReceive(msg: GloomhavenMsg)
  case IndigoSend(msg: GloomhavenMsg)
  case StartIndigo
  case OpenContextItem(itemId: Byte)
  case CloseContextItem(itemId: Byte)
  case CloseContextMenu
  case ToggleMainMenu

@JSExportTopLevel("TyrianApp")
object Main extends TyrianApp[Msg, Model]:
  val gameDivId  = "board"
  val appVersion = "2.0.0-alpha"

  def router: Location => Msg = Routing.none(Msg.NoOp)

  def init(flags: Map[String, String]): (Model, Cmd[IO, Msg]) =
    (Model(), Cmd.Emit(Msg.StartIndigo))

  def update(model: Model): Msg => (Model, Cmd[IO, Msg]) =
    case Msg.IndigoReceive(msg) =>
      updateIndigoReceive(msg, model)
    case Msg.IndigoSend(msg) =>
      (model, model.bridge.publish(IndigoGameId(gameDivId), msg))
    case Msg.StartIndigo =>
      val task: IO[Msg] =
        IO {
          if gameDivExists(gameDivId) then
            VgbGame(model.bridge.subSystem(IndigoGameId(gameDivId)))
              .launch(
                gameDivId,
                "width"  -> "1620",
                "height" -> "800"
              )
            Msg.NoOp
          else Msg.RetryIndigo
        }

      (model, Cmd.Run(task))
    case Msg.RetryIndigo =>
      (model, Cmd.emitAfterDelay(Msg.StartIndigo, 0.1.seconds))
    case Msg.CloseContextMenu =>
      (
        model.copy(sceneModel = model.sceneModel.updateContextMenu(None)),
        Cmd.None
      )
    case Msg.OpenContextItem(i) =>
      model.sceneModel.contextMenu match {
        case Some((p, menu)) =>
          val newMenu = (p, menu.updateItems(updateContextMenuItem(menu.items, i, true)))
          (
            model.copy(sceneModel = model.sceneModel.updateContextMenu(Some(newMenu))),
            Cmd.None
          )
        case None => (model, Cmd.None)
      }

    case Msg.CloseContextItem(i) =>
      model.sceneModel.contextMenu match {
        case Some((p, menu)) =>
          val newMenu = (p, menu.updateItems(updateContextMenuItem(menu.items, i, false)))
          (
            model.copy(sceneModel = model.sceneModel.updateContextMenu(Some(newMenu))),
            Cmd.None
          )
        case None => (model, Cmd.None)
      }
    case Msg.NoOp => (model, Cmd.None)
    case Msg.ToggleMainMenu =>
      (
        model.copy(sceneModel = model.sceneModel.toggleMainMenu()),
        Cmd.None
      )

  def view(model: Model): Html[Msg] =
    val sceneModel = model.scene.getModel(model)

    div(
      id := "content",
      `class` := s"""content ${sceneModel match {
          case _: CreatorModel => "scenario-creator"
          case _               => ""
        }}"""
    )(
      div(`class` := "header")(
        List(
          MainMenuComponent.render(sceneModel.mainMenu, sceneModel.showMainMenu)
        ) ++
          model.scene
            .getHeader(sceneModel)
      ),
      div(`class` := "main", attribute("aria-label", "Gloomhaven board layout"))(
        List(div(`class` := "map-bg")()) ++
          model.scene
            .getBoardAdditions(sceneModel)
          ++
          (
            sceneModel.contextMenu match {
              case Some(m) =>
                m match {
                  case (pos, menu) =>
                    List(
                      div(id := gameDivId, `class` := "board-wrapper")(),
                      ContextMenuComponent.render(pos, menu)
                    )
                }
              case None => List(div(id := gameDivId, `class` := "board-wrapper")())
            }
          )
      ),
      footer(
        div(`class` := "credits")(
          span(`class` := "gloomCopy")(
            text("Gloomhaven and all related properties and images are owned by "),
            a(href := "http://www.cephalofair.com/")("Cephalofair Games")
          ),
          span(`class` := "any2CardCopy")(
            text("Additional card scans courtesy of "),
            a(href := "https://github.com/any2cards/worldhaven")("Any2Cards")
          )
        ),
        div(`class` := "pkg")(
          span(`class` := "pkgCopy")(
            text("Developed by"),
            a(href := "https://purplekingdomgames.com/")("Purple Kingdom Games")
          ),
          div(`class` := "sponsor")(
            iframe(
              `class` := "sponsor-button",
              src     := "https://github.com/sponsors/PurpleKingdomGames/button",
              title   := "Sponsor Purple Kingdom Games",
              attribute("aria-hidden", "true")
            )()
          ),
          a(
            target := "_new",
            href   := "https://github.com/PurpleKingdomGames/virtual-gloomhaven-board/issues/new/choose"
          )("Report a bug"),
          span(s"""Version ${appVersion}""")
        )
      )
    )

  def subscriptions(model: Model): Sub[IO, Msg] =
    Sub.Batch {
      model.bridge.subscribe { case msg =>
        Some(Msg.IndigoReceive(msg))
      }
    }

  def updateIndigoReceive(msg: GloomhavenMsg, model: Model): (Model, Cmd[IO, Msg]) =
    (msg, model.sceneModel) match {
      case (msg: GeneralMsgType, _) =>
        msg match {
          case GeneralMsgType.ShowContextMenu(p, m) =>
            val someMenu =
              if m.isEmpty then None
              else
                val newMenu = Menu()
                  .add(
                    m.items.map(i =>
                      i match {
                        case i: MenuItem => assignCancelButtons(i)
                        case _           => i
                      }
                    )
                  )
                  .add(MenuSeparator())
                  .add(MenuItem("Cancel", Batch.empty))

                Some(getContextPosition(p), newMenu)
            (
              model.copy(sceneModel = model.sceneModel.updateContextMenu(someMenu)),
              Cmd.None
            )
          case GeneralMsgType.CloseContextMenu =>
            (model.copy(sceneModel = model.sceneModel.updateContextMenu(None)), Cmd.None)
        }
      case _ =>
        val (sceneModel, cmd) = model.scene.update(msg, model.scene.getModel(model))
        (model.copy(sceneModel = sceneModel), cmd.map(Msg.IndigoSend(_)))
    }

  def updateContextMenuItem(
      items: Batch[MenuItemTrait | MenuSeparator],
      idToFind: Byte,
      opened: Boolean
  ): Batch[MenuItemTrait | MenuSeparator] =
    items
      .map(item =>
        item match {
          case i: MenuItem =>
            i.copy(
              open = (i.id == idToFind) && opened,
              subItems = updateContextMenuItem(i.subItems, idToFind, opened)
            )
          case _ => item
        }
      )

  @SuppressWarnings(Array("scalafix:DisableSyntax.null"))
  private def gameDivExists(id: String): Boolean =
    document.getElementById(id) != null

  private def getContextPosition(p: Point) =
    document.getElementById(gameDivId) match {
      case null => p
      case gameWrapper =>
        val padding = 22
        Point(
          (p.x + padding - gameWrapper.scrollLeft).toInt,
          (p.y + padding - gameWrapper.scrollTop).toInt
        )
    }

  private def assignCancelButtons(item: MenuItem): MenuItem =
    if item.hasSubMenu then
      val subItems = item.subItems
        .map(item =>
          item match {
            case i: MenuItem => assignCancelButtons(i)
            case _           => item
          }
        )

      item
        .copy(subItems =
          subItems :+
            MenuSeparator() :+
            MenuItem("Cancel", Batch.empty)
        )
    else item
