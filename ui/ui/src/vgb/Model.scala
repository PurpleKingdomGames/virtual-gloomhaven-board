package vgb

import org.scalajs.dom.Element

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

  init : ( Maybe Decode.Value, Maybe Decode.Value, Int ) -> ( Model, Cmd Msg )
  init ( oldState, maybeOverrides, seed ) =
      let
          overrides =
              case maybeOverrides of
                  Just o ->
                      case loadOverrides o of
                          Ok ov ->
                              ov

                          _ ->
                              emptyOverrides

                  Nothing ->
                      emptyOverrides

          ( gs, initConfig ) =
              case oldState of
                  Just s ->
                      case loadFromStorage s of
                          Ok ( g, c ) ->
                              ( g
                              , { c
                                  | roomCode =
                                      case overrides.initRoomCodeSeed of
                                          Just _ ->
                                              Nothing

                                          Nothing ->
                                              c.roomCode
                                  , campaignTracker =
                                      case overrides.campaignTracker of
                                          Just t ->
                                              Just t

                                          Nothing ->
                                              c.campaignTracker
                                }
                              )

                          Err _ ->
                              AppStorage.empty

                  Nothing ->
                      AppStorage.empty

          forceScenarioRefresh =
              (case overrides.initPlayers of
                  Nothing ->
                      List.length gs.players == 0

                  Just p ->
                      (List.length p > 0 && p /= gs.players)
                          || (List.length gs.players == 0)
              )
                  || (case overrides.initScenario of
                          Just newScenario ->
                              case gs.scenario of
                                  InbuiltScenario Gloomhaven oldScenario ->
                                      newScenario /= oldScenario

                                  _ ->
                                      True

                          Nothing ->
                              False
                     )

          initGameState =
              { gs
                  | updateCount = 0
                  , players =
                      case overrides.initPlayers of
                          Just p ->
                              if List.length p > 0 then
                                  p

                              else
                                  gs.players

                          Nothing ->
                              gs.players
                  , roomCode =
                      case overrides.initRoomCodeSeed of
                          Just _ ->
                              ""

                          Nothing ->
                              gs.roomCode
              }

          initGame =
              Game.empty

          initScenario =
              case overrides.initScenario of
                  Just i ->
                      InbuiltScenario Gloomhaven i

                  Nothing ->
                      initGameState.scenario

          model =
              Model
                  { initGame | state = initGameState }
                  initConfig
                  (Loading initGameState.scenario)
                  Nothing
                  Nothing
                  Nothing
                  Nothing
                  Nothing
                  Nothing
                  (getDeadPlayers initGameState)
                  Nothing
                  Disconnected
                  []
                  False
                  False
                  False
                  overrides.lockScenario
                  overrides.lockPlayers
                  overrides.lockRoomCode
                  overrides.initRoomCodeSeed
                  []
                  True
                  Nothing
                  Closed
                  ( 0, 0 )
                  ( 0, 0 )
      in
      case initScenario of
          InbuiltScenario _ _ ->
              ( model
              , Cmd.batch
                  [ connectToServer
                  , loadScenarioById
                      initScenario
                      (LoadedScenarioHttp
                          (Random.initialSeed seed)
                          initScenario
                          (if forceScenarioRefresh then
                              Nothing

                           else
                              Just initGameState
                          )
                          False
                      )
                  ]
              )

          CustomScenario s ->
              let
                  ( m, msg ) =
                      update
                          (LoadedScenarioJson
                              (Random.initialSeed seed)
                              initScenario
                              (if forceScenarioRefresh then
                                  Nothing

                               else
                                  Just initGameState
                              )
                              False
                              (decodeString decodeScenario s)
                          )
                          model
              in
              ( m, Cmd.batch [ connectToServer, msg ] )
