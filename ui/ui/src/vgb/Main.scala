package vgb

import cats.effect.IO
import tyrian.Html.*
import tyrian.*

import scala.scalajs.js.annotation.*
import org.scalajs.dom.Element

@JSExportTopLevel("TyrianApp")
object Main extends TyrianApp[Msg, Model]:

  def init(flags: Map[String, String]): (Model, Cmd[IO, Msg]) =
    (???, Cmd.None)

  def update(model: Model): Msg => (Model, Cmd[IO, Msg]) =
    _ => (model, Cmd.None)

  def view(model: Model): Html[Msg] =
    div()()

  def subscriptions(model: Model): Sub[IO, Msg] =
    Sub.None

  val topLeftKey: String        = "q"
  val topRightKey: String       = "w"
  val leftKey: String           = "a"
  val rightKey: String          = "s"
  val bottomLeftKey: String     = "z"
  val bottomRightKey: String    = "x"
  val undoLimit: Int            = 25
  val boardTutorialStep: Int    = 0
  val roomCodeTutorialStep: Int = 1
  val menuTutorialStep: Int     = 2
  val lastTutorialStep: Int     = 3

// Double definition
// final case class PieceModel(isDragging: Boolean, coords: Option[(Int, Int)], piece: Piece)

// Double definition
// final case class BoardOverlayModel(isDragging: Boolean, coords: Option[(Int, Int)], overlay: BoardOverlay)

final case class TransientClientSettings(
    roomCode: (String, String),
    summonsColour: String,
    showRoomCode: Boolean,
    boardOnly: Boolean,
    fullscreen: Boolean,
    envelopeX: Boolean
)

enum LoadingState:
  case Loaded
  case Loading(state: GameStateScenario)
  case Failed

enum ConnectionStatus:
  case Connected
  case Disconnected
  case Reconnecting
