package vgb.ui

import cats.effect.IO
import tyrian.*
import tyrian.Html.*
import org.scalajs.dom.document
import vgb.game.{Main => VgbGame}
import vgb.common.*

import scala.scalajs.js.annotation.*

enum Msg:
  case IndigoReceive(msg: GloomhavenMsg) extends Msg
  case IndigoSend(msg: GloomhavenMsg)    extends Msg
  case StartIndigo                       extends Msg

@JSExportTopLevel("TyrianApp")
object Main extends TyrianApp[Msg, Model]:
  val gameDivId = "map-container"

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

  def view(model: Model): Html[Msg] =
    div(`class` := "main")(
      div(id := "map-container")()
    )

  def subscriptions(model: Model): Sub[IO, Msg] =
    Sub.Batch {
      model.bridge.subscribe { case msg =>
        Some(Msg.IndigoReceive(msg))
      }
    }

  def updateIndigoReceive(msg: GloomhavenMsg, model: Model): (Model, Cmd[IO, Msg]) =
    msg match {
      case _ =>
        (model, Cmd.None)
      // (model, cmd.map(Msg.IndigoSend(_)))
    }
