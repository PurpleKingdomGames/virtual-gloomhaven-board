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

final case class Model(
    game: Game,
    config: Config,
    currentLoadState: LoadingState,
    currentScenarioType: Option[GameStateScenario],
    currentScenarioInput: Option[String],
    currentClientSettings: Option[TransientClientSettings],
    currentPlayerList: Option[List[CharacterClass]],
    currentSelectedFile: Option[(String, Option[(Either[String, Scenario])])],
    currentSelectedCell: Option[(Int, Int)],
    deadPlayerList: List[CharacterClass],
    currentDraggable: Option[MoveablePiece],
    connectionStatus: ConnectionStatus,
    undoStack: List[GameState],
    menuOpen: Boolean,
    sideMenuOpen: Boolean,
    fullscreen: Boolean,
    lockScenario: Boolean,
    lockPlayers: Boolean,
    lockRoomCode: Boolean,
    roomCodeSeed: Option[Int],
    keysDown: List[String],
    roomCodePassesServerCheck: Boolean,
    tooltipTarget: Option[(Element, String)],
    contextMenuState: ContextMenu,
    contextMenuPosition: (Int, Int),
    contextMenuAbsPosition: (Int, Int)
)

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

enum Msg:
  // case LoadedScenarioHttp Seed GameStateScenario (Maybe Game.GameState) Bool (Result Http.Error Scenario)
  // case LoadedScenarioJson Seed GameStateScenario (Maybe Game.GameState) Bool (Result Decode.Error Scenario)
  // case ReloadScenario
  // case ChooseScenarioFile
  // case ExtractScenarioFile File
  // case LoadScenarioFile String
  // case MoveStarted MoveablePiece (Maybe ( DragDrop.EffectAllowed, Decode.Value ))
  // case MoveTargetChanged ( Int, Int ) (Maybe ( DragDrop.DropEffect, Decode.Value ))
  // case MoveCanceled
  // case MoveCompleted
  // case TouchStart MoveablePiece
  // case TouchMove ( Float, Float )
  // case TouchCanceled
  // case TouchEnd ( Float, Float )
  // case CellFromPoint ( Int, Int, Bool )
  // case GameStateUpdated Game.GameState
  // case AddOverlay BoardOverlay
  // case AddToken BoardOverlay
  // case AddHighlight BoardOverlay
  // case AddPiece Piece
  // case RotateOverlay Int
  // case RemoveOverlay BoardOverlay
  // case RemovePiece Piece
  // case PhasePiece Piece
  // case ChangeGameMode GameModeType
  // case ChangeAppMode AppModeType
  // case RevealRoomMsg (List MapTileRef) ( Int, Int )
  // case ChangeScenario GameStateScenario Bool
  // case SelectCell ( Int, Int )
  // case OpenContextMenu
  // case ChangeContextMenuState ContextMenu
  // case ChangeContextMenuAbsposition ( Int, Int )
  // case ToggleCharacter CharacterClass Bool
  // case ToggleBoardOnly Bool
  // case ToggleFullscreen Bool
  // case ToggleEnvelopeX Bool
  // case ToggleMenu
  // case ChangePlayerList
  // case EnterScenarioType GameStateScenario
  // case EnterScenarioNumber String
  // case UpdateTutorialStep Int
  // case ChangeRoomCodeInputStart String
  // case ChangeRoomCodeInputEnd String
  // case ChangeShowRoomCode Bool
  // case ChangeSummonsColour String
  // case ChangeClientSettings (Maybe TransientClientSettings)
  // case GameSyncMsg GameSync.Msg
  // case PushToUndoStack GameState
  // case Undo
  // case KeyDown String
  // case KeyUp String
  // case Paste String
  // case VisibilityChanged Visibility
  // case PushGameState Bool
  // case InitTooltip String String
  // case SetTooltip String (Result BrowserDom.Error BrowserDom.Element)
  // case ResetTooltip
  // case ExitFullscreen ()
  // case Reconnect
  case NoOp
