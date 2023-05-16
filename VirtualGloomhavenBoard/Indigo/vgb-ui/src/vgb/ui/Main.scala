package vgb.ui

import cats.effect.IO
import tyrian.*
import tyrian.Html.*
import org.scalajs.dom.document
import vgb.game.{Main => VgbGame}
import vgb.common.*

import scala.scalajs.js.annotation.*
import vgb.ui.models.components.ContextMenuComponent
import indigo.shared.collections.Batch

enum Msg:
  case IndigoReceive(msg: GloomhavenMsg) extends Msg
  case IndigoSend(msg: GloomhavenMsg)    extends Msg
  case StartIndigo                       extends Msg
  case OpenContextItem(item: MenuItem)   extends Msg
  case CloseContextMenu                  extends Msg

@JSExportTopLevel("TyrianApp")
object Main extends TyrianApp[Msg, Model]:
  val gameDivId  = "board"
  val appVersion = "2.0.0-alpha"

  def init(flags: Map[String, String]): (Model, Cmd[IO, Msg]) =
    (Model(), Cmd.Emit(Msg.StartIndigo))

  def update(model: Model): Msg => (Model, Cmd[IO, Msg]) =
    case Msg.IndigoReceive(msg) =>
      updateIndigoReceive(msg, model)
    case Msg.IndigoSend(msg) =>
      (model, model.bridge.publish(IndigoGameId(gameDivId), msg))
    case Msg.StartIndigo =>
      (
        model,
        Cmd.SideEffect {
          VgbGame(model.bridge.subSystem(IndigoGameId(gameDivId)))
            .launch(
              gameDivId,
              "width"  -> "1620",
              "height" -> "800"
            )
        }
      )
    case Msg.CloseContextMenu =>
      (
        model.copy(sceneModel = model.sceneModel.updateContextMenu(None)),
        Cmd.None
      )
    case Msg.OpenContextItem(item) =>
      model.sceneModel.contextMenu match {
        case Some((p, menu)) =>
          val newMenu = (p, menu.copy(items = updateContextMenuItem(menu.items, item)))
          (
            model.copy(sceneModel = model.sceneModel.updateContextMenu(Some(newMenu))),
            Cmd.None
          )
        case None => (model, Cmd.None)
      }

  def view(model: Model): Html[Msg] =
    div(id := "content", `class` := "content")(
      div(`class` := "header")(
        model.scene
          .header(model.scene.getModel(model))
          .map(Msg.IndigoSend(_))
      ),
      div(`class` := "main", attribute("aria-label", "Gloomhaven board layout"))(
        model.sceneModel.contextMenu match {
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
          div(`class` := "copy-wrapper")(
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
            )
          ),
          div(`class` := "version")(
            a(
              target := "_new",
              href   := "https://github.com/PurpleKingdomGames/virtual-gloomhaven-board/issues/new/choose"
            )("Report a bug"),
            span(s"""Version ${appVersion}""")
          )
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
            val newMenu = if m.items.isEmpty then None else Some(p, m)
            (model.copy(sceneModel = model.sceneModel.updateContextMenu(newMenu)), Cmd.None)
          case GeneralMsgType.CloseContextMenu =>
            (model.copy(sceneModel = model.sceneModel.updateContextMenu(None)), Cmd.None)
        }
      case _ =>
        val (sceneModel, cmd) = model.scene.update(msg, model.scene.getModel(model))
        (model.copy(sceneModel = sceneModel), cmd.map(Msg.IndigoSend(_)))
    }

  def updateContextMenuItem(
      items: Batch[MenuItem | MenuSeparator],
      selectedItem: MenuItem
  ): Batch[MenuItem | MenuSeparator] =
    items
      .map(item =>
        item match {
          case i: MenuItem =>
            i.copy(selected = i == selectedItem, subItems = updateContextMenuItem(i.subItems, selectedItem))
          case _ => item
        }
      )
