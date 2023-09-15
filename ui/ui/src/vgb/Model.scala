package vgb

import org.scalajs.dom.Element
import cats.effect.IO
import tyrian.*

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

object Model:

  def init(oldState: Option[String], maybeOverrides: Option[String], seed: Int): (Model, Cmd[IO, Msg]) = {
    val overrides =
      maybeOverrides match
        case Some(o) =>
          loadOverrides(o) match
            case Ok(ov) =>
              ov

            case _ =>
              emptyOverrides

        case None =>
          emptyOverrides

    val (gs, initConfig) =
      oldState match
        case Some(s) =>
          loadFromStorage(s) match
            case Ok((g, c)) =>
              (
                g,
                c.copy(
                  roomCode = overrides.initRoomCodeSeed match {
                    case Some(_) =>
                      Nothing

                    case None =>
                      c.roomCode
                  },
                  campaignTracker = overrides.campaignTracker match {
                    case Some(t) =>
                      Option(t)

                    case None =>
                      c.campaignTracker
                  }
                )
              )

            case Err(_) =>
              AppStorage.empty

        case None =>
          AppStorage.empty

    val forceScenarioRefresh =
      (overrides.initPlayers match
        case None =>
          gs.players.length == 0

        case Some(p) =>
          (p.length > 0 && p /= gs.players) || (gs.players.length == 0)
      )
        || (overrides.initScenario match
          case Some(newScenario) =>
            gs.scenario match
              case InbuiltScenario(Gloomhaven, oldScenario) =>
                newScenario /= oldScenario

              case _ =>
                true

          case None =>
            false
        )

    val initGameState =
      gs.copy(
        updateCount = 0,
        players = overrides.initPlayers match
          case Some(p) =>
            if p.length > 0 then p else gs.players

          case None =>
            gs.players
        ,
        roomCode = overrides.initRoomCodeSeed match
          case Some(_) =>
            ""

          case None =>
            gs.roomCode
      )

    val initGame =
      Game.empty

    val initScenario =
      overrides.initScenario match
        case Some(i) =>
          InbuiltScenario(Gloomhaven, i)

        case None =>
          initGameState.scenario

    val model =
      Model(
        initGame.copy(state = initGameState),
        initConfig,
        Loading(initGameState.scenario),
        None,
        None,
        None,
        None,
        None,
        None,
        getDeadPlayers(initGameState),
        Nothing,
        Disconnected,
        Nil,
        false,
        false,
        false,
        overrides.lockScenario,
        overrides.lockPlayers,
        overrides.lockRoomCode,
        overrides.initRoomCodeSeed,
        Nil,
        true,
        None,
        Closed,
        (0, 0),
        (0, 0)
      )

    initScenario match
      case InbuiltScenario(_, _) =>
        (
          model,
          Cmd.Batch(
            connectToServer,
            loadScenarioById(
              initScenario,
              LoadedScenarioHttp(
                Random.initialSeed(seed),
                initScenario,
                if forceScenarioRefresh then None
                else Option(initGameState),
                false
              )
            )
          )
        )

      case CustomScenario(s) =>
        val (m, msg) =
          update(
            LoadedScenarioJson(
              Random.initialSeed(seed),
              initScenario,
              if forceScenarioRefresh then None else Option(initGameState),
              false,
              (decodeString decodeScenario s)
            ),
            model
          )

        (m, Cmd.Batch(connectToServer, msg))
  }
