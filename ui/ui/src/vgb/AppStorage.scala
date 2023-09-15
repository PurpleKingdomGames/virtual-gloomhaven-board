package vgb

object AppStorage:

  val defaultSummonsColour: String = "#963f9d"

final case class StoredData(config: Config, gameState: GameState)

final case class Config(
    appMode: AppModeType,
    gameMode: GameModeType,
    roomCode: Option[String],
    summonsColour: String,
    showRoomCode: Boolean,
    envelopeX: Boolean,
    boardOnly: Boolean,
    campaignTracker: Option[CampaignTrackerUrl],
    tutorialStep: Int
)

final case class MapData(
    scenarioTitle: String,
    roomData: List[ExtendedRoomData],
    overlays: List[BoardOverlay],
    monsters: List[ScenarioMonster]
)

final case class ExtendedRoomData(data: RoomData, rotationPoint: (Int, Int))

final case class AppOverrides(
    initScenario: Option[Int],
    initPlayers: Option[List[CharacterClass]],
    initRoomCodeSeed: Option[Int],
    lockScenario: Boolean,
    lockPlayers: Boolean,
    lockRoomCode: Boolean,
    campaignTracker: Option[CampaignTrackerUrl]
)

enum CampaignTrackerUrl:
  case CampaignTrackerUrl(name: String, url: String)

enum GameModeType:
  case MovePiece
  case KillPiece
  case MoveOverlay
  case DestroyOverlay
  case LootCell
  case RevealRoom
  case AddPiece

enum AppModeType:
  case Game
  case ScenarioDialog
  case ConfigDialog
  case PlayerChoiceDialog

final case class MoveablePiece(ref: MoveablePieceType, coords: Option[(Int, Int)], target: Option[(Int, Int)])

enum MoveablePieceType:
  case OverlayType(overlay: BoardOverlay, position: Option[(Int, Int)])
  case PieceType(typ: Piece)
  case RoomType(room: RoomData)
