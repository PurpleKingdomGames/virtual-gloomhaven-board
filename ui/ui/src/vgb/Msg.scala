package vgb

import org.scalajs.dom.Element
import org.scalajs.dom.PageVisibility

enum Msg:
  case LoadedScenarioHttp(
      seed: Long,
      scenario: GameStateScenario,
      state: Option[GameState],
      addToUndo: Boolean,
      loadedScenario: Either[String, Scenario]
  )
  case LoadedScenarioJson(
      seed: Long,
      scenario: GameStateScenario,
      state: Option[GameState],
      addToUndo: Boolean,
      loadedScenario: Either[String, Scenario]
  )
  case ReloadScenario
  case ChooseScenarioFile
  case ExtractScenarioFile(file: String)
  case LoadScenarioFile(file: String)
  case MoveStarted(piece: MoveablePiece, result: Option[(String, String)])
  case MoveTargetChanged(target: (Int, Int), result: Option[(String, String)])
  case MoveCanceled
  case MoveCompleted
  case TouchStart(piece: MoveablePiece)
  case TouchMove(position: (Float, Float))
  case TouchCanceled
  case TouchEnd(position: (Float, Float))
  case CellFromPoint(at: (Int, Int, Boolean))
  case GameStateUpdated(state: GameState)
  case AddOverlay(overlay: BoardOverlay)
  case AddToken(overlay: BoardOverlay)
  case AddHighlight(overlay: BoardOverlay)
  case AddPiece(piece: Piece)
  case RotateOverlay(turns: Int)
  case RemoveOverlay(overlay: BoardOverlay)
  case RemovePiece(piece: Piece)
  case PhasePiece(piece: Piece)
  case ChangeGameMode(mode: GameModeType)
  case ChangeAppMode(mode: AppModeType)
  case RevealRoomMsg(refs: List[MapTileRef], position: (Int, Int))
  case ChangeScenario(newScenario: GameStateScenario, forceReload: Boolean)
  case SelectCell(cell: (Int, Int))
  case OpenContextMenu
  case ChangeContextMenuState(state: ContextMenu)
  case ChangeContextMenuAbsposition(position: (Int, Int))
  case ToggleCharacter(character: CharacterClass, enabled: Boolean)
  case ToggleBoardOnly(boardOnly: Boolean)
  case ToggleFullscreen(fullscreen: Boolean)
  case ToggleEnvelopeX(envelopeX: Boolean)
  case ToggleMenu
  case ChangePlayerList
  case EnterScenarioType(scenario: GameStateScenario)
  case EnterScenarioNumber(id: String)
  case UpdateTutorialStep(step: Int)
  case ChangeRoomCodeInputStart(id: String)
  case ChangeRoomCodeInputEnd(id: String)
  case ChangeShowRoomCode(visible: Boolean)
  case ChangeSummonsColour(colour: String)
  case ChangeClientSettings(settings: Option[TransientClientSettings])
  case GameSyncMsg(msg: GameSync.Msg)
  case PushToUndoStack(state: GameState)
  case Undo
  case KeyDown(key: String)
  case KeyUp(key: String)
  case Paste(value: String)
  case VisibilityChanged(visibility: PageVisibility)
  case PushGameState(addToUndo: Boolean)
  case InitTooltip(id: String, text: String)
  case SetTooltip(id: String, element: Either[String, Element])
  case ResetTooltip
  case ExitFullscreen()
  case Reconnect
  case NoOp
