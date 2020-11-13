port module Main exposing (main)

import AppStorage exposing (AppModeType(..), Config, GameModeType(..), MoveablePiece, MoveablePieceType(..), decodeMoveablePiece, emptyOverrides, encodeMoveablePiece, loadFromStorage, loadOverrides, saveToStorage)
import Array exposing (Array, fromList, length, toIndexedList, toList)
import Bitwise
import BoardMapTile exposing (MapTileRef(..), refToString)
import BoardOverlay exposing (BoardOverlay, BoardOverlayDirectionType(..), BoardOverlayType(..), ChestType(..), CorridorMaterial(..), DifficultTerrainSubType(..), DoorSubType(..), ObstacleSubType(..), TrapSubType(..), TreasureSubType(..), getBoardOverlayName, getOverlayLabel)
import Browser
import Browser.Dom as BrowserDom exposing (Error)
import Browser.Events exposing (Visibility(..), onKeyDown, onKeyUp, onVisibilityChange)
import Character exposing (CharacterClass(..), characterToString)
import Debug
import Dict exposing (Dict)
import Dom exposing (Element)
import Game exposing (AIType(..), Cell, Game, GameState, Piece, PieceType(..), RoomData, SummonsType(..), assignIdentifier, assignPlayers, generateGameMap, getPieceName, getPieceType, moveOverlay, movePiece, removePieceFromBoard, revealRooms)
import GameSync exposing (Msg(..), connectToServer, update)
import Html exposing (a, div, footer, header, iframe, img, span, text)
import Html.Attributes exposing (alt, attribute, checked, class, href, id, maxlength, minlength, required, src, style, tabindex, target, title, value)
import Html.Events exposing (on, onClick)
import Html.Events.Extra.Drag as DragDrop
import Html.Events.Extra.Touch as Touch
import Html.Lazy exposing (lazy, lazy2, lazy3, lazy6, lazy7, lazy8)
import Http exposing (Error)
import Json.Decode as Decode
import Json.Encode as Encode
import List exposing (all, any, filter, filterMap, head, map, member, reverse, sort, sortWith, take)
import List.Extra exposing (uniqueBy)
import Monster exposing (BossType(..), Monster, MonsterLevel(..), MonsterType(..), NormalMonsterType(..), monsterTypeToString, stringToMonsterType)
import Process
import Random exposing (Seed)
import Scenario exposing (DoorData(..), Scenario)
import ScenarioSync exposing (loadScenarioById)
import String exposing (join, split)
import Task


port onPaste : (String -> msg) -> Sub msg


port getCellFromPoint : ( Float, Float, Bool ) -> Cmd msg


port onCellFromPoint : (( Int, Int, Bool ) -> msg) -> Sub msg


type alias Model =
    { game : Game
    , config : Config
    , currentLoadState : LoadingState
    , currentScenarioInput : Maybe String
    , currentClientSettings : Maybe TransientClientSettings
    , currentPlayerList : Maybe (List CharacterClass)
    , deadPlayerList : List CharacterClass
    , currentDraggable : Maybe MoveablePiece
    , connectionStatus : ConnectionStatus
    , undoStack : List GameState
    , menuOpen : Bool
    , sideMenuOpen : Bool
    , fullscreen : Bool
    , lockScenario : Bool
    , lockPlayers : Bool
    , lockRoomCode : Bool
    , roomCodeSeed : Maybe Int
    , keysDown : List String
    , roomCodePassesServerCheck : Bool
    , tooltipTarget : Maybe ( BrowserDom.Element, String )
    }


type alias NewPieceMenuModel =
    { gameMode : GameModeType
    , currentDraggable : Maybe MoveablePiece
    , bearSummoned : Bool
    , nextSummonsId : Int
    , availableMonsters : List String
    , deadPlayers : List CharacterClass
    }


type alias RowModel =
    { gameMode : GameModeType
    , overlays : List BoardOverlayModel
    , piece : Maybe PieceModel
    , currentDraggable : Maybe MoveablePiece
    , visibleRooms : List MapTileRef
    }


type alias CellModel =
    { gameMode : GameModeType
    , overlays : List BoardOverlayModel
    , piece : Maybe PieceModel
    , currentDraggable : Maybe MoveablePiece
    , passable : Bool
    , hidden : Bool
    , x : Int
    , y : Int
    }


type alias PieceModel =
    { gameMode : GameModeType
    , isDragging : Bool
    , coords : Maybe ( Int, Int )
    , piece : Piece
    }


type alias BoardOverlayModel =
    { gameMode : GameModeType
    , isDragging : Bool
    , coords : Maybe ( Int, Int )
    , overlay : BoardOverlay
    }


type alias TransientClientSettings =
    { roomCode : ( String, String )
    , showRoomCode : Bool
    , boardOnly : Bool
    , fullscreen : Bool
    }


type LoadingState
    = Loaded
    | Loading Int
    | Failed


type ConnectionStatus
    = Connected
    | Disconnected
    | Reconnecting


type Msg
    = LoadedScenario Seed (Maybe Game.GameState) Bool (Result Error Scenario)
    | ReloadScenario
    | MoveStarted MoveablePiece
    | MoveTargetChanged ( Int, Int )
    | MoveCanceled
    | MoveCompleted
    | TouchStart MoveablePiece
    | TouchMove ( Float, Float )
    | TouchCanceled
    | TouchEnd ( Float, Float )
    | CellFromPoint ( Int, Int, Bool )
    | GameStateUpdated Game.GameState
    | RemoveOverlay BoardOverlay
    | RemovePiece Piece
    | ChangeGameMode GameModeType
    | ChangeAppMode AppModeType
    | RevealRoomMsg (List MapTileRef) ( Int, Int )
    | ChangeScenario Int Bool
    | ToggleCharacter CharacterClass Bool
    | ToggleBoardOnly Bool
    | ToggleFullscreen Bool
    | ToggleMenu
    | ToggleSideMenu
    | ChangePlayerList
    | EnterScenarioNumber String
    | ChangeRoomCodeInputStart String
    | ChangeRoomCodeInputEnd String
    | ChangeShowRoomCode Bool
    | ChangeClientSettings (Maybe TransientClientSettings)
    | GameSyncMsg GameSync.Msg
    | PushToUndoStack GameState
    | Undo
    | KeyDown String
    | KeyUp String
    | Paste String
    | VisibilityChanged Visibility
    | PushGameState Bool
    | InitTooltip String String
    | SetTooltip String (Result BrowserDom.Error BrowserDom.Element)
    | ResetTooltip
    | ExitFullscreen ()
    | Reconnect
    | NoOp


version : String
version =
    "1.5.0"


undoLimit : Int
undoLimit =
    25


main : Program ( Maybe Decode.Value, Maybe Decode.Value, Int ) Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


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
                              }
                            )

                        Err _ ->
                            AppStorage.empty

                Nothing ->
                    AppStorage.empty

        forceScenarioRefresh =
            case overrides.initPlayers of
                Nothing ->
                    List.length gs.players == 0

                Just p ->
                    (List.length p > 0 && p /= gs.players)
                        || (List.length gs.players == 0)

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
    in
    ( Model
        { initGame | state = initGameState }
        initConfig
        (Loading initGameState.scenario)
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
    , Cmd.batch
        [ connectToServer
        , loadScenarioById
            (case overrides.initScenario of
                Just i ->
                    i

                Nothing ->
                    initGameState.scenario
            )
            (LoadedScenario
                (Random.initialSeed seed)
                (if forceScenarioRefresh then
                    Nothing

                 else
                    Just initGameState
                )
                False
            )
        ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        roomCode =
            Maybe.withDefault "" model.config.roomCode
    in
    case msg of
        LoadedScenario seed initGameState addToUndo result ->
            case result of
                Ok scenario ->
                    let
                        game =
                            generateGameMap scenario roomCode model.game.state.players seed
                                |> (let
                                        players =
                                            case initGameState of
                                                Just gs ->
                                                    gs.players

                                                Nothing ->
                                                    model.game.state.players
                                    in
                                    assignPlayers players
                                   )

                        gameState =
                            case initGameState of
                                Just gs ->
                                    if gs.scenario == scenario.id then
                                        gs

                                    else
                                        game.state

                                Nothing ->
                                    game.state

                        newModel =
                            { model
                                | game =
                                    { game
                                        | state =
                                            { gameState
                                                | roomCode = model.game.state.roomCode
                                                , updateCount = model.game.state.updateCount
                                            }
                                    }
                                , currentLoadState = Loaded
                            }
                    in
                    ( newModel, pushGameState model newModel.game.state addToUndo )

                Err _ ->
                    ( { model | currentLoadState = Failed }, Cmd.none )

        ReloadScenario ->
            update (ChangeScenario model.game.state.scenario True) model

        MoveStarted piece ->
            ( { model | currentDraggable = Just piece }, Cmd.none )

        MoveTargetChanged coords ->
            let
                newDraggable =
                    case model.currentDraggable of
                        Just m ->
                            case m.ref of
                                OverlayType o prevCoords ->
                                    let
                                        ( _, newOverlay, newCoords ) =
                                            moveOverlay o m.coords prevCoords coords model.game

                                        moveablePieceType =
                                            OverlayType newOverlay newCoords

                                        newTarget =
                                            if moveablePieceType == m.ref then
                                                m.target

                                            else
                                                Just coords
                                    in
                                    Just (MoveablePiece moveablePieceType m.coords newTarget)

                                PieceType p ->
                                    let
                                        newPiece =
                                            PieceType (Tuple.second (movePiece p m.coords coords model.game))

                                        newTarget =
                                            if newPiece == m.ref then
                                                m.target

                                            else
                                                Just coords
                                    in
                                    Just (MoveablePiece newPiece m.coords newTarget)

                        Nothing ->
                            model.currentDraggable
            in
            ( { model | currentDraggable = newDraggable }, Cmd.none )

        MoveCanceled ->
            ( { model | currentDraggable = Nothing }, Cmd.none )

        MoveCompleted ->
            let
                oldGame =
                    model.game

                game =
                    case model.currentDraggable of
                        Just m ->
                            case ( m.ref, m.target ) of
                                ( OverlayType o prevCoords, Just coords ) ->
                                    let
                                        ( g, _, _ ) =
                                            moveOverlay o m.coords prevCoords coords oldGame
                                    in
                                    g

                                ( PieceType p, Just coords ) ->
                                    case p.ref of
                                        AI (Enemy monster) ->
                                            (if monster.id == 0 then
                                                assignIdentifier oldGame.state.availableMonsters p

                                             else
                                                ( p, oldGame.state.availableMonsters )
                                            )
                                                |> (\( p2, d ) ->
                                                        let
                                                            newGame =
                                                                Tuple.first (movePiece p2 m.coords coords oldGame)

                                                            newState =
                                                                newGame.state
                                                        in
                                                        { newGame | state = { newState | availableMonsters = d } }
                                                   )

                                        _ ->
                                            Tuple.first (movePiece p m.coords coords oldGame)

                                _ ->
                                    oldGame

                        Nothing ->
                            oldGame
            in
            ( { model | game = game, deadPlayerList = getDeadPlayers game.state, currentDraggable = Nothing }, pushGameState model game.state True )

        TouchStart piece ->
            update (MoveStarted piece) model

        TouchCanceled ->
            update MoveCanceled model

        TouchMove ( x, y ) ->
            ( model, getCellFromPoint ( x, y, False ) )

        TouchEnd ( x, y ) ->
            ( model, getCellFromPoint ( x, y, True ) )

        CellFromPoint ( x, y, endTouch ) ->
            if endTouch then
                case model.currentDraggable of
                    Just d ->
                        update
                            MoveCompleted
                            model

                    Nothing ->
                        ( model, Cmd.none )

            else
                update (MoveTargetChanged ( x, y )) model

        RemoveOverlay overlay ->
            let
                game =
                    model.game

                gameState =
                    game.state

                newState =
                    { gameState | overlays = List.filter (\o -> o.cells /= overlay.cells || o.ref /= overlay.ref) gameState.overlays }
            in
            ( { model | game = { game | state = newState } }, pushGameState model newState True )

        RemovePiece piece ->
            let
                newGame =
                    removePieceFromBoard piece model.game
            in
            ( { model | game = newGame, deadPlayerList = getDeadPlayers newGame.state }, pushGameState model newGame.state True )

        ChangeGameMode mode ->
            let
                config =
                    model.config

                newModel =
                    { model | config = { config | gameMode = mode }, currentClientSettings = Nothing, currentPlayerList = Nothing, currentScenarioInput = Nothing }
            in
            ( newModel, saveToStorage newModel.game.state newModel.config )

        RevealRoomMsg rooms ( x, y ) ->
            let
                updatedGame =
                    revealRooms model.game rooms

                newState =
                    updatedGame.state

                doorToCorridor =
                    newState.overlays
                        |> map
                            (\o ->
                                case head o.cells of
                                    Just ( oX, oY ) ->
                                        if x == oX && y == oY then
                                            case o.ref of
                                                Door BreakableWall tiles ->
                                                    { o | ref = Door (Corridor NaturalStone BoardOverlay.One) tiles }

                                                _ ->
                                                    o

                                        else
                                            o

                                    Nothing ->
                                        o
                            )

                newGame =
                    { updatedGame | state = { newState | overlays = doorToCorridor } }
            in
            ( { model | game = newGame }, pushGameState model newGame.state True )

        ChangeAppMode mode ->
            let
                config =
                    model.config

                newModel =
                    { model
                        | config = { config | appMode = mode }
                        , currentClientSettings = Nothing
                        , currentPlayerList = Nothing
                        , currentScenarioInput = Nothing
                    }
            in
            ( newModel, saveToStorage newModel.game.state newModel.config )

        ChangeScenario newScenario forceReload ->
            let
                config =
                    model.config
            in
            if forceReload || newScenario /= model.game.state.scenario then
                ( { model | config = { config | appMode = AppStorage.Game }, currentLoadState = Loading newScenario, currentDraggable = Nothing, currentScenarioInput = Nothing }, loadScenarioById newScenario (LoadedScenario model.game.seed Nothing True) )

            else
                ( { model | config = { config | appMode = AppStorage.Game } }, Cmd.none )

        EnterScenarioNumber strId ->
            ( { model | currentScenarioInput = Just strId }, Cmd.none )

        ChangeRoomCodeInputStart startCode ->
            let
                settings =
                    getSplitRoomCodeSettings model

                ( _, roomCode2 ) =
                    settings.roomCode
            in
            ( { model
                | currentClientSettings = Just { settings | roomCode = ( startCode, roomCode2 ) }
                , roomCodePassesServerCheck = True
              }
            , Cmd.none
            )

        ChangeRoomCodeInputEnd endCode ->
            let
                settings =
                    getSplitRoomCodeSettings model

                ( roomCode1, _ ) =
                    settings.roomCode
            in
            ( { model
                | currentClientSettings = Just { settings | roomCode = ( roomCode1, endCode ) }
                , roomCodePassesServerCheck = True
              }
            , Cmd.none
            )

        ChangeShowRoomCode showRoomCode ->
            let
                settings =
                    getSplitRoomCodeSettings model
            in
            ( { model | currentClientSettings = Just { settings | showRoomCode = showRoomCode } }, Cmd.none )

        ChangeClientSettings maybeSettings ->
            case maybeSettings of
                Just settings ->
                    let
                        config =
                            model.config

                        newRoomCode =
                            let
                                ( one, two ) =
                                    settings.roomCode
                            in
                            one ++ "-" ++ two

                        ( m, c ) =
                            update
                                (GameSyncMsg (JoinRoom newRoomCode))
                                { model
                                    | config =
                                        { config
                                            | showRoomCode = settings.showRoomCode
                                            , boardOnly = settings.boardOnly
                                            , appMode = AppStorage.Game
                                        }
                                    , currentClientSettings = Nothing
                                    , fullscreen = settings.fullscreen
                                }
                    in
                    if model.fullscreen /= settings.fullscreen then
                        ( m, Cmd.batch [ c, Cmd.map (\s -> GameSyncMsg s) (GameSync.toggleFullscreen settings.fullscreen) ] )

                    else
                        ( m, c )

                Nothing ->
                    ( model, Cmd.none )

        ToggleCharacter character enabled ->
            let
                playerList =
                    getCharacterListSettings model
                        |> List.filter (\c -> c /= character)
                        |> (if enabled then
                                List.append [ character ]

                            else
                                List.append []
                           )
            in
            ( { model | currentPlayerList = Just playerList }, Cmd.none )

        ToggleBoardOnly boardOnly ->
            let
                transSettings =
                    getSplitRoomCodeSettings model
            in
            ( { model
                | currentClientSettings = Just { transSettings | boardOnly = boardOnly }
              }
            , Cmd.none
            )

        ToggleFullscreen fullscreen ->
            let
                transSettings =
                    getSplitRoomCodeSettings model
            in
            ( { model
                | currentClientSettings = Just { transSettings | fullscreen = fullscreen }
              }
            , Cmd.none
            )

        ToggleMenu ->
            ( { model | menuOpen = model.menuOpen == False }, Cmd.none )

        ToggleSideMenu ->
            ( { model | sideMenuOpen = model.sideMenuOpen == False }, Cmd.none )

        ChangePlayerList ->
            let
                playerList =
                    getCharacterListSettings model

                config =
                    model.config

                game =
                    model.game

                gameState =
                    model.game.state
            in
            if playerList == model.game.state.players then
                update (ChangeAppMode AppStorage.Game) model

            else
                let
                    newModel =
                        { model | config = { config | appMode = AppStorage.Game }, game = { game | state = { gameState | players = playerList } }, currentPlayerList = Nothing }
                in
                update ReloadScenario newModel

        GameSyncMsg gameSyncMsg ->
            let
                connectedState =
                    case gameSyncMsg of
                        GameSync.Connected _ ->
                            Connected

                        GameSync.Disconnected _ ->
                            Disconnected

                        GameSync.Reconnecting _ ->
                            Reconnecting

                        _ ->
                            model.connectionStatus

                config =
                    case gameSyncMsg of
                        GameSync.RoomCodeReceived r ->
                            let
                                c =
                                    model.config
                            in
                            { c | roomCode = Just r }

                        GameSync.JoinRoom r ->
                            let
                                c =
                                    model.config
                            in
                            { c | roomCode = Just r }

                        _ ->
                            model.config

                validRoomCode =
                    case gameSyncMsg of
                        GameSync.RoomCodeReceived _ ->
                            True

                        GameSync.RoomCodeInvalid _ ->
                            False

                        _ ->
                            model.roomCodePassesServerCheck

                updatedConfigModel =
                    { model
                        | config =
                            if validRoomCode then
                                config

                            else
                                { config | appMode = ConfigDialog }
                        , connectionStatus = connectedState
                        , roomCodePassesServerCheck = validRoomCode
                    }

                gameState =
                    model.game.state

                ( updateMsg, cmdMsg ) =
                    GameSync.update
                        gameSyncMsg
                        model.roomCodeSeed
                        (Just gameState)
                        GameStateUpdated
            in
            case updateMsg of
                Just u ->
                    let
                        ( newModel, msgs ) =
                            update u updatedConfigModel
                    in
                    ( newModel, Cmd.batch [ cmdMsg, msgs ] )

                Nothing ->
                    ( updatedConfigModel, cmdMsg )

        GameStateUpdated gameState ->
            let
                game =
                    model.game

                undoStack =
                    case model.undoStack of
                        head :: _ ->
                            if { head | updateCount = model.game.state.updateCount } == model.game.state then
                                model.undoStack

                            else
                                model.undoStack

                        _ ->
                            model.undoStack
            in
            if game.state.scenario == gameState.scenario then
                ( { model | game = { game | state = gameState }, undoStack = take undoLimit undoStack }
                , saveToStorage gameState model.config
                )

            else
                ( { model | currentLoadState = Loading gameState.scenario }
                , loadScenarioById gameState.scenario (LoadedScenario game.seed (Just gameState) True)
                )

        PushToUndoStack state ->
            let
                undoStack =
                    state :: model.undoStack
            in
            ( { model | undoStack = take undoLimit undoStack }, Cmd.none )

        Undo ->
            case model.undoStack of
                state :: rest ->
                    let
                        newModel =
                            { model | undoStack = rest }

                        newState =
                            { state | updateCount = model.game.state.updateCount }
                    in
                    if state.scenario == model.game.state.scenario then
                        ( newModel, pushGameState newModel newState False )

                    else
                        ( { newModel | currentLoadState = Loading state.scenario }
                        , loadScenarioById state.scenario (LoadedScenario model.game.seed (Just newState) False)
                        )

                _ ->
                    ( model, Cmd.none )

        PushGameState addToUndo ->
            case model.currentLoadState of
                Loaded ->
                    ( model, pushGameState model model.game.state addToUndo )

                _ ->
                    ( model, Cmd.none )

        KeyDown val ->
            if model.config.appMode == AppStorage.Game then
                let
                    newModel =
                        { model | keysDown = val :: model.keysDown }

                    ctrlChars =
                        [ "control"
                        , "meta"
                        , "alt"
                        , "shift"
                        ]

                    ctrlCombi =
                        [ ( [ "control", "z" ], Undo )
                        , ( [ "meta", "z" ], Undo )
                        , ( [ "shift", "c" ], ChangeAppMode ScenarioDialog )
                        , ( [ "shift", "r" ], ReloadScenario )
                        , ( [ "shift", "p" ], ChangeAppMode PlayerChoiceDialog )
                        , ( [ "shift", "s" ], ChangeAppMode ConfigDialog )
                        ]
                in
                if newModel.keysDown == [ "m" ] then
                    update ToggleMenu newModel

                else
                    case head (filter (\( keys, _ ) -> all (\k -> member k newModel.keysDown) keys) ctrlCombi) of
                        Just ( keys, cmd ) ->
                            update cmd
                                { newModel
                                    | keysDown =
                                        filter
                                            (\k ->
                                                member k ctrlChars || (member k keys == False)
                                            )
                                            model.keysDown
                                }

                        Nothing ->
                            ( newModel, Cmd.none )

            else if val == "escape" then
                update (ChangeAppMode AppStorage.Game) model

            else if val == "enter" then
                case model.config.appMode of
                    ScenarioDialog ->
                        let
                            scenarioId =
                                Maybe.withDefault (String.fromInt model.game.state.scenario) model.currentScenarioInput
                        in
                        if isValidScenario scenarioId then
                            case String.toInt scenarioId of
                                Just i ->
                                    update (ChangeScenario i False) model

                                Nothing ->
                                    ( model, Cmd.none )

                        else
                            ( model, Cmd.none )

                    PlayerChoiceDialog ->
                        update ChangePlayerList model

                    ConfigDialog ->
                        update (ChangeClientSettings model.currentClientSettings) model

                    _ ->
                        ( model, Cmd.none )

            else
                ( model, Cmd.none )

        KeyUp val ->
            ( { model | keysDown = filter (\k -> k /= String.toLower val) model.keysDown }, Cmd.none )

        Paste fullData ->
            let
                data =
                    String.trim fullData
            in
            case model.config.appMode of
                ConfigDialog ->
                    if isValidRoomCode data then
                        case split "-" data of
                            first :: rest ->
                                let
                                    settings =
                                        getSplitRoomCodeSettings model
                                in
                                ( { model
                                    | currentClientSettings =
                                        Just { settings | roomCode = ( first, join "" rest ) }
                                    , roomCodePassesServerCheck = True
                                  }
                                , Cmd.none
                                )

                            _ ->
                                ( model, Cmd.none )

                    else
                        ( model, Cmd.none )

                ScenarioDialog ->
                    if isValidScenario data then
                        ( { model | currentScenarioInput = Just data }, Cmd.none )

                    else
                        ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        VisibilityChanged visibility ->
            case visibility of
                Hidden ->
                    ( { model | keysDown = [] }, Cmd.none )

                Visible ->
                    ( model, Cmd.none )

        InitTooltip identifier text ->
            ( model, Task.attempt (SetTooltip text) (BrowserDom.getElement identifier) )

        SetTooltip text result ->
            case result of
                Ok element ->
                    ( { model | tooltipTarget = Just ( element, text ) }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        ResetTooltip ->
            ( { model | tooltipTarget = Nothing }, Cmd.none )

        ExitFullscreen _ ->
            ( { model | fullscreen = False, currentClientSettings = Nothing }, Cmd.none )

        Reconnect ->
            ( model, GameSync.connectToServer )

        NoOp ->
            ( model, Cmd.none )


view : Model -> Html.Html Msg
view model =
    let
        config =
            model.config
    in
    div
        [ class
            ("content"
                ++ (if config.boardOnly then
                        " board-only"

                    else
                        ""
                   )
            )
        , id "content"
        , Touch.onCancel (\_ -> TouchCanceled)
        ]
        ([ lazy7
            getHeaderHtml
            model.game.scenario.id
            model.game.scenario.title
            model.config.roomCode
            model.config.showRoomCode
            model.lockScenario
            model.lockPlayers
            model.menuOpen
         , div [ class "main" ]
            [ div
                [ class
                    ("action-list"
                        ++ (if model.sideMenuOpen then
                                " show"

                            else
                                ""
                           )
                    )
                ]
                [ lazy getNavHtml model.config.gameMode
                , let
                    bearSummoned =
                        (List.member BeastTyrant model.game.state.players == False)
                            || List.any (\p -> p.ref == AI (Summons BearSummons)) model.game.state.pieces

                    maxSummons =
                        filterMap
                            (\p ->
                                case p.ref of
                                    AI (Summons (NormalSummons i)) ->
                                        Just i

                                    _ ->
                                        Nothing
                            )
                            model.game.state.pieces
                            |> sort
                            |> reverse
                            |> head

                    nextId =
                        case maxSummons of
                            Just i ->
                                i + 1

                            Nothing ->
                                1
                  in
                  lazy6 getNewPieceHtml
                    model.config.gameMode
                    (case model.currentDraggable of
                        Just m ->
                            case m.coords of
                                Nothing ->
                                    case m.ref of
                                        PieceType p ->
                                            getLabelForPiece p

                                        OverlayType o _ ->
                                            getLabelForOverlay o Nothing

                                Just _ ->
                                    ""

                        Nothing ->
                            ""
                    )
                    bearSummoned
                    nextId
                    model.game.state.availableMonsters
                    model.deadPlayerList
                , div [ class "side-toggle", onClick ToggleSideMenu ] []
                ]
            , div [ class "board-wrapper" ]
                [ div [ class "map-bg" ] []
                , lazy2 getAllMapTileHtml model.game.state.visibleRooms model.game.roomData
                , div [ class "board" ]
                    (let
                        encodedDraggable =
                            case model.currentDraggable of
                                Just c ->
                                    Encode.encode 0 (encodeMoveablePiece c)

                                Nothing ->
                                    ""
                     in
                     toList (Array.indexedMap (getBoardHtml model model.game encodedDraggable) model.game.staticBoard)
                    )
                ]
            , lazy getConnectionStatusHtml model.connectionStatus
            ]
         , lazy getFooterHtml version
         ]
            ++ (case config.appMode of
                    AppStorage.Game ->
                        []

                    _ ->
                        [ getDialogForAppMode model ]
               )
            ++ (case model.tooltipTarget of
                    Nothing ->
                        []

                    Just ( e, t ) ->
                        let
                            x =
                                (e.element.x
                                    + e.element.width
                                    |> String.fromFloat
                                )
                                    ++ "px"

                            y =
                                (e.element.y
                                    + (e.element.height / 4)
                                    |> String.fromFloat
                                )
                                    ++ "px"
                        in
                        [ div [ class "tooltip-wrapper", attribute "aria-hidden" "true", style "left" x, style "top" y ]
                            [ div [ class "tooltip-text" ]
                                [ text t ]
                            ]
                        ]
               )
        )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Sub.map (\s -> GameSyncMsg s) GameSync.subscriptions
        , GameSync.exitFullscreen ExitFullscreen
        , onKeyDown (Decode.map KeyDown keyDecoder)
        , onKeyUp (Decode.map KeyUp keyDecoder)
        , onPaste Paste
        , onVisibilityChange VisibilityChanged
        , onCellFromPoint CellFromPoint
        ]


getHeaderHtml : Int -> String -> Maybe String -> Bool -> Bool -> Bool -> Bool -> Html.Html Msg
getHeaderHtml scenarioId scenarioTitle roomCode showRoomCode lockScenario lockPlayers menuOpen =
    div
        [ class "header" ]
        [ div
            [ class
                ("menu"
                    ++ (if menuOpen then
                            " show"

                        else
                            ""
                       )
                )
            , onClick ToggleMenu
            , tabindex 0
            , attribute "aria-label" "Toggle Menu"
            , attribute "aria-keyshortcuts" "m"
            , attribute "role" "button"
            , attribute "aria-pressed"
                (if menuOpen then
                    " true"

                 else
                    "false"
                )
            ]
            [ lazy3 getMenuHtml lockScenario lockPlayers menuOpen ]
        , header [ attribute "aria-label" "Scenario" ]
            (if scenarioId /= 0 then
                [ span [ class "number" ] [ text (String.fromInt scenarioId) ]
                , span [ class "title" ] [ text scenarioTitle ]
                ]

             else
                []
            )
        , div
            [ class
                "roomCode"
            ]
            (case roomCode of
                Nothing ->
                    []

                Just c ->
                    if showRoomCode then
                        [ span [] [ text "Room Code" ]
                        , span [] [ text c ]
                        ]

                    else
                        []
            )
        ]


getConnectionStatusHtml : ConnectionStatus -> Html.Html Msg
getConnectionStatusHtml connectionStatus =
    div
        [ class
            ("connectionStatus"
                ++ (if connectionStatus == Disconnected || connectionStatus == Reconnecting then
                        " show"

                    else
                        ""
                   )
            )
        , attribute "aria-hidden"
            (if connectionStatus == Disconnected || connectionStatus == Reconnecting then
                "false"

             else
                "true"
            )
        ]
        [ span [] [ text "You are currently offline" ]
        , a [ onClick Reconnect ] [ text "Reconnect" ]
        ]


getFooterHtml : String -> Html.Html Msg
getFooterHtml v =
    footer []
        [ div [ class "credits" ]
            [ span [ class "gloomCopy" ]
                [ text "Gloomhaven and all related properties and images are owned by "
                , a [ href "http://www.cephalofair.com/" ] [ text "Cephalofair Games" ]
                ]
            , span [ class "any2CardCopy" ]
                [ text "Additional card scans courtesy of "
                , a [ href "https://github.com/any2cards/gloomhaven" ] [ text "Any2Cards" ]
                ]
            ]
        , div [ class "pkg" ]
            [ div
                [ class "copy-wrapper" ]
                [ span [ class "pkgCopy" ]
                    [ text "Developed by "
                    , a [ href "https://purplekingdomgames.com/" ] [ text "Purple Kingdom Games" ]
                    ]
                , div
                    [ class "sponsor" ]
                    [ iframe
                        [ class "sponsor-button"
                        , src "https://github.com/sponsors/PurpleKingdomGames/button"
                        , title "Sponsor PurpleKingdomGames"
                        , attribute "aria-hidden" "true"
                        ]
                        []
                    ]
                ]
            , div
                [ class "version" ]
                [ a [ target "_new", href "https://github.com/PurpleKingdomGames/virtual-gloomhaven-board/issues/new/choose" ] [ text "Report a bug" ]
                , span [] [ text ("Version " ++ v) ]
                ]
            ]
        ]


getNewPieceHtml : GameModeType -> String -> Bool -> Int -> Dict String (Array Int) -> List CharacterClass -> Html.Html Msg
getNewPieceHtml gameMode currentDraggable bearSummoned nextSummonsId availableMonsters deadPlayers =
    Dom.element "div"
        |> Dom.addClassConditional "show" (gameMode == AddPiece)
        |> Dom.addClass "new-piece-wrapper"
        |> Dom.appendChild
            (Dom.element "div"
                |> Dom.addClass "new-piece-list"
                |> Dom.appendChild
                    (Dom.element "ul"
                        |> Dom.appendChildConditional
                            (Dom.element "li"
                                |> Dom.appendChild
                                    (Tuple.second
                                        (pieceToHtml
                                            (PieceModel
                                                gameMode
                                                (getLabelForPiece (Piece (AI (Summons BearSummons)) 0 0) == currentDraggable)
                                                Nothing
                                                (Piece (AI (Summons BearSummons)) 0 0)
                                            )
                                        )
                                    )
                            )
                            (bearSummoned == False)
                        |> Dom.appendChild
                            (Dom.element "li"
                                |> Dom.appendChild
                                    (Tuple.second
                                        (pieceToHtml
                                            (PieceModel
                                                gameMode
                                                (getLabelForPiece (Piece (AI (Summons (NormalSummons nextSummonsId))) 0 0) == currentDraggable)
                                                Nothing
                                                (Piece (AI (Summons (NormalSummons nextSummonsId))) 0 0)
                                            )
                                        )
                                    )
                            )
                        |> Dom.appendChild
                            (Dom.element "li"
                                |> Dom.appendChild
                                    (Tuple.second
                                        (overlayToHtml
                                            (BoardOverlayModel
                                                gameMode
                                                (getLabelForOverlay (BoardOverlay (Trap BearTrap) Default [ ( 0, 0 ) ]) Nothing == currentDraggable)
                                                Nothing
                                                (BoardOverlay (Trap BearTrap) Default [ ( 0, 0 ) ])
                                            )
                                        )
                                    )
                            )
                        |> Dom.appendChild
                            (Dom.element "li"
                                |> Dom.setChildListWithKeys
                                    [ overlayToHtml
                                        (BoardOverlayModel
                                            gameMode
                                            (getLabelForOverlay (BoardOverlay (Obstacle Boulder1) Default [ ( 0, 0 ) ]) Nothing == currentDraggable)
                                            Nothing
                                            (BoardOverlay (Obstacle Boulder1) Default [ ( 0, 0 ) ])
                                        )
                                    ]
                            )
                        |> Dom.appendChildList
                            (deadPlayers
                                |> List.map
                                    (\p ->
                                        Dom.element "li"
                                            |> Dom.setChildListWithKeys
                                                [ pieceToHtml
                                                    (PieceModel
                                                        gameMode
                                                        (getLabelForPiece (Piece (Player p) 0 0) == currentDraggable)
                                                        Nothing
                                                        (Piece (Player p) 0 0)
                                                    )
                                                ]
                                    )
                            )
                        |> Dom.appendChildList
                            (Dict.toList availableMonsters
                                |> List.filter (\( _, v ) -> length v > 0)
                                |> List.map (\( k, _ ) -> k)
                                |> List.sort
                                |> List.reverse
                                |> filterMap (\k -> stringToMonsterType k)
                                |> List.map
                                    (\k ->
                                        (Dom.element "li"
                                            |> Dom.setChildListWithKeys
                                                [ pieceToHtml
                                                    (PieceModel
                                                        gameMode
                                                        (getLabelForPiece (Piece (AI (Enemy (Monster k 0 Normal True))) 0 0) == currentDraggable)
                                                        Nothing
                                                        (Piece (AI (Enemy (Monster k 0 Normal True))) 0 0)
                                                    )
                                                ]
                                        )
                                            :: (case k of
                                                    NormalType _ ->
                                                        [ Dom.element "li"
                                                            |> Dom.setChildListWithKeys
                                                                [ pieceToHtml
                                                                    (PieceModel
                                                                        gameMode
                                                                        (getLabelForPiece (Piece (AI (Enemy (Monster k 0 Elite True))) 0 0) == currentDraggable)
                                                                        Nothing
                                                                        (Piece (AI (Enemy (Monster k 0 Elite True))) 0 0)
                                                                    )
                                                                ]
                                                        ]

                                                    _ ->
                                                        []
                                               )
                                    )
                                |> List.foldl (++) []
                            )
                    )
            )
        |> Dom.render


getMenuHtml : Bool -> Bool -> Bool -> Html.Html Msg
getMenuHtml lockScenario lockPlayers menuOpen =
    Dom.element "nav"
        |> Dom.addAttribute
            (attribute
                "aria-hidden"
                (if menuOpen then
                    "false"

                 else
                    "true"
                )
            )
        |> Dom.appendChild
            (Dom.element "ul"
                |> Dom.addAttribute (attribute "role" "menu")
                |> Dom.appendChildList
                    ([ Dom.element "li"
                        |> Dom.addAttribute (attribute "role" "menuitem")
                        |> Dom.addAttribute (tabindex 0)
                        |> Dom.addAction ( "click", Undo )
                        |> Dom.addClass "section-end"
                        |> Dom.appendText "Undo"
                        |> shortcutHtml [ "ctrl", "z" ]
                     ]
                        ++ (if lockScenario then
                                []

                            else
                                [ Dom.element "li"
                                    |> Dom.addAttribute (attribute "role" "menuitem")
                                    |> Dom.addAttribute (tabindex 0)
                                    |> Dom.addAction ( "click", ChangeAppMode ScenarioDialog )
                                    |> Dom.appendText "Change Scenario"
                                    |> shortcutHtml [ "⇧", "c" ]
                                ]
                           )
                        ++ [ Dom.element "li"
                                |> Dom.addAttribute (attribute "role" "menuitem")
                                |> Dom.addAttribute (tabindex 0)
                                |> Dom.addAction ( "click", ReloadScenario )
                                |> Dom.appendText "Reload Scenario"
                                |> shortcutHtml [ "⇧", "r" ]
                           ]
                        ++ (if lockPlayers then
                                []

                            else
                                [ Dom.element "li"
                                    |> Dom.addAttribute (attribute "role" "menuitem")
                                    |> Dom.addAttribute (tabindex 0)
                                    |> Dom.addAction ( "click", ChangeAppMode PlayerChoiceDialog )
                                    |> Dom.appendText "Change Players"
                                    |> shortcutHtml [ "⇧", "p" ]
                                ]
                           )
                        ++ [ Dom.element "li"
                                |> Dom.addAttribute (attribute "role" "menuitem")
                                |> Dom.addAttribute (tabindex 0)
                                |> Dom.addAction ( "click", ChangeAppMode ConfigDialog )
                                |> Dom.addClass "section-end"
                                |> Dom.appendText "Settings"
                                |> shortcutHtml [ "⇧", "s" ]
                           , Dom.element "li"
                                |> Dom.addAttribute (attribute "role" "menuitem")
                                |> Dom.addAttribute (tabindex 0)
                                |> Dom.appendChild
                                    (Dom.element "a"
                                        |> Dom.addAttribute (href "https://github.com/sponsors/PurpleKingdomGames?o=esb")
                                        |> Dom.addAttribute (target "_new")
                                        |> Dom.appendText "Donate"
                                    )
                           ]
                    )
            )
        |> Dom.render


getDialogForAppMode : Model -> Html.Html Msg
getDialogForAppMode model =
    Dom.element "div"
        |> Dom.addAttribute (tabindex 0)
        |> Dom.addAttribute (attribute "aria-keyshortcuts" "escape")
        |> Dom.addClass "overlay-dialog"
        |> Dom.appendChild
            (Dom.element "div"
                |> Dom.addAttribute (attribute "role" "dialog")
                |> Dom.addAttribute
                    (attribute "aria-label"
                        (case model.config.appMode of
                            ScenarioDialog ->
                                "Choose a new Scenario"

                            ConfigDialog ->
                                "Change configuration settings"

                            PlayerChoiceDialog ->
                                "Change character classes"

                            AppStorage.Game ->
                                ""
                        )
                    )
                |> Dom.addAttribute (tabindex 0)
                |> Dom.addAttribute (attribute "aria-keyshortcuts" "enter")
                |> Dom.addClass "dialog"
                |> (case model.config.appMode of
                        ScenarioDialog ->
                            Dom.appendChild (getScenarioDialog model)

                        ConfigDialog ->
                            Dom.appendChild (getClientSettingsDialog model)

                        PlayerChoiceDialog ->
                            Dom.appendChild (getPlayerChoiceDialog model)

                        AppStorage.Game ->
                            \e -> e
                   )
                |> Dom.addActionStopPropagation ( "click", NoOp )
            )
        |> Dom.addAction ( "click", ChangeAppMode AppStorage.Game )
        |> Dom.render


getScenarioDialog : Model -> Element Msg
getScenarioDialog model =
    let
        scenarioInput =
            Maybe.withDefault (String.fromInt model.game.state.scenario) model.currentScenarioInput

        validScenario =
            isValidScenario scenarioInput

        intScenarioInput =
            Maybe.withDefault 0 (String.toInt scenarioInput)
    in
    Dom.element "div"
        |> Dom.addClass "scenario-form"
        |> Dom.appendChildList
            [ Dom.element "div"
                |> Dom.addClass "input-wrapper"
                |> Dom.addClassConditional "error" (validScenario == False)
                |> Dom.appendChildList
                    ([ Dom.element "label"
                        |> Dom.addAttribute (attribute "for" "scenarioIdInput")
                        |> Dom.appendText "Scenario"
                     , Dom.element "input"
                        |> Dom.addActionStopPropagation ( "click", NoOp )
                        |> Dom.addAttribute (attribute "id" "scenarioIdInput")
                        |> Dom.addAttribute (attribute "type" "number")
                        |> Dom.addAttribute (attribute "min" "1")
                        |> Dom.addAttribute (attribute "max" "95")
                        |> Dom.addAttribute (attribute "value" scenarioInput)
                        |> Dom.addInputHandler EnterScenarioNumber
                     ]
                        ++ (if validScenario then
                                []

                            else
                                [ Dom.element "div"
                                    |> Dom.addClass "error-label"
                                    |> Dom.appendText "Invalid scenario number"
                                ]
                           )
                    )
            , Dom.element "div"
                |> Dom.addClass "button-wrapper"
                |> Dom.appendChildList
                    [ Dom.element "button"
                        |> Dom.appendText "OK"
                        |> Dom.addActionConditional ( "click", ChangeScenario intScenarioInput False ) validScenario
                    , Dom.element "button"
                        |> Dom.appendText "Cancel"
                        |> Dom.addAction ( "click", ChangeAppMode AppStorage.Game )
                    ]
            ]


getClientSettingsDialog : Model -> Element Msg
getClientSettingsDialog model =
    let
        settings =
            getSplitRoomCodeSettings model

        ( roomCode1, roomCode2 ) =
            settings.roomCode

        validRoomCode =
            isValidRoomCode (roomCode1 ++ "-" ++ roomCode2) && model.roomCodePassesServerCheck
    in
    Dom.element "div"
        |> Dom.addClass "client-form"
        |> Dom.appendChildList
            ((if model.lockRoomCode then
                []

              else
                [ Dom.element "div"
                    |> Dom.addClass "input-wrapper"
                    |> Dom.addClassConditional "error" (validRoomCode == False)
                    |> Dom.appendChildList
                        ([ Dom.element "label"
                            |> Dom.addAttribute (attribute "for" "roomCodeInput1")
                            |> Dom.appendText "Room Code"
                         , Dom.element "div"
                            |> Dom.addClass "split-input"
                            |> Dom.appendChildList
                                [ Dom.element "input"
                                    |> Dom.addActionStopPropagation ( "click", NoOp )
                                    |> Dom.addAttribute (attribute "id" "roomCodeInput1")
                                    |> Dom.addInputHandler ChangeRoomCodeInputStart
                                    |> Dom.addAttribute (minlength 5)
                                    |> Dom.addAttribute (maxlength 5)
                                    |> Dom.addAttribute (required True)
                                    |> Dom.addAttribute (value roomCode1)
                                , Dom.element "span"
                                    |> Dom.appendText "-"
                                , Dom.element "input"
                                    |> Dom.addActionStopPropagation ( "click", NoOp )
                                    |> Dom.addAttribute (attribute "id" "roomCodeInput2")
                                    |> Dom.addInputHandler ChangeRoomCodeInputEnd
                                    |> Dom.addAttribute (minlength 5)
                                    |> Dom.addAttribute (maxlength 5)
                                    |> Dom.addAttribute (required True)
                                    |> Dom.addAttribute (value roomCode2)
                                ]
                         ]
                            ++ (if validRoomCode == False then
                                    [ Dom.element "div"
                                        |> Dom.addClass "error-label"
                                        |> Dom.appendText "Invalid room code"
                                    ]

                                else
                                    []
                               )
                        )
                ]
             )
                ++ [ Dom.element "div"
                        |> Dom.addClass "input-wrapper"
                        |> Dom.appendChild
                            (Dom.element "label"
                                |> Dom.addClass "checkbox"
                                |> Dom.addClassConditional "checked" settings.showRoomCode
                                |> Dom.addAttribute (attribute "for" "showRoomCode")
                                |> Dom.appendText "Show Room Code"
                                |> Dom.appendChild
                                    (Dom.element "input"
                                        |> Dom.addAttribute (attribute "id" "showRoomCode")
                                        |> Dom.addAttribute (attribute "type" "checkbox")
                                        |> Dom.addAttribute (attribute "value" "1")
                                        |> Dom.addAttribute (checked settings.showRoomCode)
                                        |> Dom.addActionStopPropagation ( "click", ChangeShowRoomCode (settings.showRoomCode == False) )
                                    )
                            )
                   , Dom.element "div"
                        |> Dom.addClass "input-wrapper"
                        |> Dom.appendChild
                            (Dom.element "label"
                                |> Dom.addClass "checkbox"
                                |> Dom.addClassConditional "checked" settings.boardOnly
                                |> Dom.addAttribute (attribute "for" "showBoardOnly")
                                |> Dom.appendText "Hide UI"
                                |> Dom.appendChild
                                    (Dom.element "input"
                                        |> Dom.addAttribute (attribute "id" "showBoardOnly")
                                        |> Dom.addAttribute (attribute "type" "checkbox")
                                        |> Dom.addAttribute (attribute "value" "1")
                                        |> Dom.addAttribute (checked settings.boardOnly)
                                        |> Dom.addActionStopPropagation ( "click", ToggleBoardOnly (settings.boardOnly == False) )
                                    )
                            )
                   , Dom.element "div"
                        |> Dom.addClass "input-wrapper"
                        |> Dom.appendChild
                            (Dom.element "label"
                                |> Dom.addClass "checkbox"
                                |> Dom.addClassConditional "checked" settings.fullscreen
                                |> Dom.addAttribute (attribute "for" "toggleFullscreen")
                                |> Dom.appendText "Fullscreen Mode"
                                |> Dom.appendChild
                                    (Dom.element "input"
                                        |> Dom.addAttribute (attribute "id" "toggleFullscreen")
                                        |> Dom.addAttribute (attribute "type" "checkbox")
                                        |> Dom.addAttribute (attribute "value" "1")
                                        |> Dom.addAttribute (checked settings.boardOnly)
                                        |> Dom.addActionStopPropagation ( "click", ToggleFullscreen (settings.fullscreen == False) )
                                    )
                            )
                   , Dom.element "div"
                        |> Dom.addClass "button-wrapper"
                        |> Dom.appendChildList
                            [ Dom.element "button"
                                |> Dom.appendText "OK"
                                |> Dom.addAction ( "click", ChangeClientSettings model.currentClientSettings )
                            , Dom.element "button"
                                |> Dom.appendText "Cancel"
                                |> Dom.addAction ( "click", ChangeAppMode AppStorage.Game )
                            ]
                   ]
            )


getPlayerChoiceDialog : Model -> Element Msg
getPlayerChoiceDialog model =
    let
        playerList =
            getCharacterListSettings model

        checkboxes =
            Dict.toList Character.characterDictionary
                |> List.map
                    (\( k, v ) ->
                        getCharacterChoiceInput k v (List.member v playerList)
                    )
    in
    Dom.element "div"
        |> Dom.addClass "character-form"
        |> Dom.appendChildList
            checkboxes
        |> Dom.appendChild
            (Dom.element "div"
                |> Dom.addClass "button-wrapper"
                |> Dom.appendChildList
                    [ Dom.element "button"
                        |> Dom.appendText "OK"
                        |> Dom.addActionStopPropagation ( "click", ChangePlayerList )
                    , Dom.element "button"
                        |> Dom.appendText "Cancel"
                        |> Dom.addAction ( "click", ChangeAppMode AppStorage.Game )
                    ]
            )


getCharacterChoiceInput : String -> CharacterClass -> Bool -> Element Msg
getCharacterChoiceInput name class enabled =
    Dom.element "div"
        |> Dom.addClass "input-wrapper"
        |> Dom.appendChild
            (Dom.element "label"
                |> Dom.addAttribute (attribute "for" ("characterChoice_" ++ name))
                |> Dom.addClass name
                |> Dom.addClassConditional "selected" enabled
                |> Dom.appendText name
                |> Dom.appendChild
                    (Dom.element "input"
                        |> Dom.addAttribute (attribute "id" ("characterChoice_" ++ name))
                        |> Dom.addAttribute (attribute "type" "checkbox")
                        |> Dom.addAttribute (attribute "value" "1")
                        |> Dom.addAttribute (checked enabled)
                        |> Dom.addActionStopPropagation ( "click", ToggleCharacter class (enabled == False) )
                    )
            )


getNavHtml : GameModeType -> Html.Html Msg
getNavHtml gameMode =
    Dom.element "div"
        |> Dom.addClass "sidebar-wrapper"
        |> Dom.appendChild
            (Dom.element "nav"
                |> Dom.appendChild
                    (Dom.element "ul"
                        |> Dom.appendChildList
                            [ Dom.element "li"
                                |> Dom.addAttribute (attribute "role" "button")
                                |> Dom.addAttribute (tabindex 0)
                                |> Dom.addAttribute
                                    (attribute "aria-pressed"
                                        (if gameMode == MovePiece then
                                            " true"

                                         else
                                            "false"
                                        )
                                    )
                                |> Dom.addAction ( "click", ChangeGameMode MovePiece )
                                |> Dom.addClass "move-piece"
                                |> tooltipHtml "moveAction" "Move Monsters or Players"
                                |> Dom.addClassConditional "active" (gameMode == MovePiece)
                                |> Dom.appendText "Move Piece"
                            , Dom.element "li"
                                |> Dom.addAttribute (attribute "role" "button")
                                |> Dom.addAttribute (tabindex 0)
                                |> Dom.addAttribute
                                    (attribute "aria-pressed"
                                        (if gameMode == KillPiece then
                                            " true"

                                         else
                                            "false"
                                        )
                                    )
                                |> Dom.addAction ( "click", ChangeGameMode KillPiece )
                                |> tooltipHtml "removeAction" "Remove Monsters or Players"
                                |> Dom.addClass "kill-piece"
                                |> Dom.addClassConditional "active" (gameMode == KillPiece)
                                |> Dom.appendText "Kill Piece"
                            , Dom.element "li"
                                |> Dom.addAttribute (attribute "role" "button")
                                |> Dom.addAttribute (tabindex 0)
                                |> Dom.addAttribute
                                    (attribute "aria-pressed"
                                        (if gameMode == LootCell then
                                            " true"

                                         else
                                            "false"
                                        )
                                    )
                                |> Dom.addAction ( "click", ChangeGameMode LootCell )
                                |> tooltipHtml "lootAction" "Loot a tile"
                                |> Dom.addClass "loot"
                                |> Dom.addClassConditional "active" (gameMode == LootCell)
                                |> Dom.appendText "Loot"
                            , Dom.element "li"
                                |> Dom.addAttribute (attribute "role" "button")
                                |> Dom.addAttribute (tabindex 0)
                                |> Dom.addAttribute
                                    (attribute "aria-pressed"
                                        (if gameMode == MoveOverlay then
                                            " true"

                                         else
                                            "false"
                                        )
                                    )
                                |> Dom.addAction ( "click", ChangeGameMode MoveOverlay )
                                |> tooltipHtml "moveObstacleAction" "Move Obstacles or Traps"
                                |> Dom.addClass "move-overlay"
                                |> Dom.addClassConditional "active" (gameMode == MoveOverlay)
                                |> Dom.appendText "Move Overlay"
                            , Dom.element "li"
                                |> Dom.addAttribute (attribute "role" "button")
                                |> Dom.addAttribute (tabindex 0)
                                |> Dom.addAttribute
                                    (attribute "aria-pressed"
                                        (if gameMode == DestroyOverlay then
                                            " true"

                                         else
                                            "false"
                                        )
                                    )
                                |> Dom.addAction ( "click", ChangeGameMode DestroyOverlay )
                                |> tooltipHtml "removeObstacleAction" "Remove Obstacles or Traps"
                                |> Dom.addClass "destroy-overlay"
                                |> Dom.addClassConditional "active" (gameMode == DestroyOverlay)
                                |> Dom.appendText "Destroy Overlay"
                            , Dom.element "li"
                                |> Dom.addAttribute (attribute "role" "button")
                                |> Dom.addAttribute (tabindex 0)
                                |> Dom.addAttribute
                                    (attribute "aria-pressed"
                                        (if gameMode == RevealRoom then
                                            " true"

                                         else
                                            "false"
                                        )
                                    )
                                |> Dom.addAction ( "click", ChangeGameMode RevealRoom )
                                |> tooltipHtml "openDoorAction" "Open a door"
                                |> Dom.addClass "reveal-room"
                                |> Dom.addClassConditional "active" (gameMode == RevealRoom)
                                |> Dom.appendText "Reveal Room"
                            , Dom.element "li"
                                |> Dom.addAttribute (attribute "role" "button")
                                |> Dom.addAttribute (tabindex 0)
                                |> Dom.addAttribute
                                    (attribute "aria-pressed"
                                        (if gameMode == AddPiece then
                                            " true"

                                         else
                                            "false"
                                        )
                                    )
                                |> Dom.addAction ( "click", ChangeGameMode AddPiece )
                                |> tooltipHtml "summonAction" "Summon a piece to the board"
                                |> Dom.addClass "add-piece"
                                |> Dom.addClassConditional "active" (gameMode == AddPiece)
                                |> Dom.appendText "Add Piece"
                            ]
                    )
            )
        |> Dom.render


getAllMapTileHtml : List MapTileRef -> List RoomData -> Html.Html msg
getAllMapTileHtml visibleRooms roomData =
    div
        [ class "mapTiles" ]
        (map (getMapTileHtml visibleRooms) (uniqueBy (\d -> Maybe.withDefault "" (refToString d.ref)) roomData))


getMapTileHtml : List MapTileRef -> RoomData -> Html.Html msg
getMapTileHtml visibleRooms roomData =
    let
        ( x, y ) =
            roomData.origin

        ref =
            Maybe.withDefault "" (refToString roomData.ref)

        xPx =
            (x * 76)
                + (if Bitwise.and y 1 == 1 then
                    38

                   else
                    0
                  )

        yPx =
            y * 67
    in
    div
        []
        [ div
            [ class "mapTile"
            , class ("rotate-" ++ String.fromInt roomData.turns)
            , class
                (if any (\r -> r == roomData.ref) visibleRooms then
                    "visible"

                 else
                    "hidden"
                )
            , style "top" (String.fromInt yPx ++ "px")
            , style "left" (String.fromInt xPx ++ "px")
            ]
            (case roomData.ref of
                Empty ->
                    []

                _ ->
                    [ img
                        [ src ("/img/map-tiles/" ++ ref ++ ".png")
                        , class ("ref-" ++ ref)
                        , alt ("Map tile " ++ ref)
                        , attribute "aria-hidden"
                            (if any (\r -> r == roomData.ref) visibleRooms then
                                "false"

                             else
                                "true"
                            )
                        ]
                        []
                    ]
            )
        , div
            [ class "mapTile outline"
            , class ("rotate-" ++ String.fromInt roomData.turns)
            , class
                (if any (\r -> r == roomData.ref) visibleRooms then
                    "hidden"

                 else
                    "visible"
                )
            , style "top" (String.fromInt yPx ++ "px")
            , style "left" (String.fromInt xPx ++ "px")
            , attribute "aria-hidden"
                (if any (\r -> r == roomData.ref) visibleRooms then
                    "true"

                 else
                    "false"
                )
            ]
            (case roomData.ref of
                Empty ->
                    []

                r ->
                    let
                        overlayPrefix =
                            case r of
                                J1a ->
                                    "ja"

                                J2a ->
                                    "ja"

                                J1b ->
                                    "jb"

                                J2b ->
                                    "jb"

                                _ ->
                                    String.left 1 ref
                    in
                    [ img
                        [ src ("/img/map-tiles/" ++ overlayPrefix ++ "-outline.png")
                        , class ("ref-" ++ ref)
                        , alt ("The outline of map tile " ++ ref)
                        ]
                        []
                    ]
            )
        ]


getBoardHtml : Model -> Game -> String -> Int -> Array Cell -> Html.Html Msg
getBoardHtml model game encodedDraggable y row =
    div [ class "row" ]
        (toList
            (Array.indexedMap
                (\x cell ->
                    let
                        useDaggable =
                            case model.currentDraggable of
                                Just m ->
                                    case m.ref of
                                        PieceType p ->
                                            (p.x == x && p.y == y) || (m.coords == Just ( x, y ))

                                        OverlayType o _ ->
                                            let
                                                isInCoords =
                                                    case m.coords of
                                                        Just ( ox, oy ) ->
                                                            any (\c -> c == ( ox, oy )) o.cells

                                                        Nothing ->
                                                            False

                                                isInTarget =
                                                    case m.target of
                                                        Just ( ox, oy ) ->
                                                            any (\c -> c == ( ox, oy )) o.cells

                                                        Nothing ->
                                                            False
                                            in
                                            isInCoords || isInTarget

                                Nothing ->
                                    False

                        cellVisible =
                            any (\r -> any (\a -> a == r) game.state.visibleRooms) cell.rooms
                    in
                    lazy8 getCellHtml
                        model.config.gameMode
                        model.game.state.overlays
                        model.game.state.pieces
                        x
                        y
                        (if useDaggable then
                            encodedDraggable

                         else
                            ""
                        )
                        cell.passable
                        (cellVisible == False)
                )
                row
            )
        )


getCellHtml : GameModeType -> List BoardOverlay -> List Piece -> Int -> Int -> String -> Bool -> Bool -> Html.Html Msg
getCellHtml gameMode overlays pieces x y encodedDraggable passable hidden =
    let
        currentDraggable =
            case Decode.decodeString decodeMoveablePiece encodedDraggable of
                Ok d ->
                    Just d

                _ ->
                    Nothing

        overlaysForCell =
            List.filter (filterOverlaysForCoord x y) overlays
                |> map
                    (\o ->
                        BoardOverlayModel
                            gameMode
                            (case currentDraggable of
                                Just m ->
                                    case m.ref of
                                        OverlayType ot _ ->
                                            let
                                                isInCoords =
                                                    case m.coords of
                                                        Just ( ox, oy ) ->
                                                            any (\c -> c == ( ox, oy )) o.cells

                                                        Nothing ->
                                                            False

                                                isInTarget =
                                                    case m.target of
                                                        Just ( ox, oy ) ->
                                                            any (\c -> c == ( ox, oy )) o.cells

                                                        Nothing ->
                                                            False
                                            in
                                            ot.ref == o.ref && (isInCoords || isInTarget)

                                        _ ->
                                            False

                                Nothing ->
                                    False
                            )
                            (Just ( x, y ))
                            o
                    )

        piece =
            Maybe.map
                (\p ->
                    PieceModel
                        gameMode
                        (case currentDraggable of
                            Just m ->
                                case m.ref of
                                    PieceType pieceType ->
                                        pieceType.ref == p.ref

                                    _ ->
                                        False

                            Nothing ->
                                False
                        )
                        (Just ( x, y ))
                        p
                )
                (getPieceForCoord x y pieces)

        cellElement : Dom.Element Msg
        cellElement =
            Dom.element "div"
                |> Dom.addClass "hexagon"
                |> Dom.addAttribute (attribute "data-cell-x" (String.fromInt x))
                |> Dom.addAttribute (attribute "data-cell-y" (String.fromInt y))
                -- Everything except coins
                |> Dom.setChildListWithKeys
                    ((overlaysForCell
                        |> sortWith
                            (\a b ->
                                compare (getSortOrderForOverlay a.overlay.ref) (getSortOrderForOverlay b.overlay.ref)
                            )
                        |> filter
                            (\o ->
                                case o.overlay.ref of
                                    Treasure t ->
                                        case t of
                                            Chest _ ->
                                                True

                                            _ ->
                                                False

                                    _ ->
                                        True
                            )
                        |> List.map overlayToHtml
                     )
                        ++ -- Players / Monsters / Summons
                           (case piece of
                                Nothing ->
                                    []

                                Just p ->
                                    [ pieceToHtml p ]
                           )
                        ++ -- Coins
                           (overlaysForCell
                                |> List.filter
                                    (\o ->
                                        case o.overlay.ref of
                                            Treasure t ->
                                                case t of
                                                    Chest _ ->
                                                        False

                                                    _ ->
                                                        True

                                            _ ->
                                                False
                                    )
                                |> List.map overlayToHtml
                           )
                        ++ -- The current draggable piece
                           (case currentDraggable of
                                Just m ->
                                    case m.ref of
                                        PieceType p ->
                                            if m.target == Just ( x, y ) then
                                                [ pieceToHtml
                                                    (PieceModel
                                                        gameMode
                                                        False
                                                        (Just ( x, y ))
                                                        p
                                                    )
                                                ]

                                            else
                                                []

                                        OverlayType o _ ->
                                            if any (\c -> c == ( x, y )) o.cells then
                                                [ overlayToHtml
                                                    (BoardOverlayModel
                                                        gameMode
                                                        False
                                                        (Just ( x, y ))
                                                        o
                                                    )
                                                ]

                                            else
                                                []

                                Nothing ->
                                    []
                           )
                    )
                |> addActionsForCell gameMode ( x, y ) (List.map (\o -> o.overlay) overlaysForCell)
    in
    Dom.element "div"
        |> Dom.addClass "cell-wrapper"
        |> Dom.addClass (cellValueToString passable hidden)
        |> Dom.appendChild
            (Dom.element "div"
                |> Dom.addClass "cell"
                |> Dom.appendChild
                    (if passable == True && hidden == False then
                        makeDroppable ( x, y ) cellElement

                     else
                        cellElement
                    )
            )
        |> Dom.render


cellValueToString : Bool -> Bool -> String
cellValueToString passable hidden =
    if hidden then
        "hidden"

    else if passable then
        "passable"

    else
        "impassable"


filterOverlaysForCoord : Int -> Int -> BoardOverlay -> Bool
filterOverlaysForCoord x y overlay =
    case head (List.filter (\( oX, oY ) -> oX == x && oY == y) overlay.cells) of
        Just _ ->
            True

        Nothing ->
            False


getPieceForCoord : Int -> Int -> List Piece -> Maybe Piece
getPieceForCoord x y pieces =
    List.filter (\p -> p.x == x && p.y == y) pieces
        |> head


pieceToHtml : PieceModel -> ( String, Element Msg )
pieceToHtml model =
    let
        label =
            getLabelForPiece model.piece

        playerHtml : String -> String -> Element Msg -> Element Msg
        playerHtml l p e =
            Dom.addClass "hex-mask" e
                |> Dom.appendChild
                    (Dom.element "img"
                        |> Dom.addAttribute (alt l)
                        |> Dom.addAttribute (attribute "src" ("/img/characters/portraits/" ++ p ++ ".png"))
                    )
    in
    ( label
    , Dom.element "div"
        |> Dom.addAttribute
            (attribute "aria-label"
                (case model.coords of
                    Just ( x, y ) ->
                        label ++ " at " ++ String.fromInt x ++ ", " ++ String.fromInt y

                    Nothing ->
                        "Add New " ++ label
                )
            )
        |> Dom.addClass (getPieceType model.piece.ref)
        |> Dom.addClass (getPieceName model.piece.ref)
        |> Dom.addClassConditional "being-dragged" model.isDragging
        |> (case model.piece.ref of
                Player p ->
                    playerHtml label (Maybe.withDefault "" (characterToString p))

                AI t ->
                    case t of
                        Enemy m ->
                            enemyToHtml m label

                        Summons (NormalSummons i) ->
                            Dom.appendChildList
                                [ Dom.element "img"
                                    |> Dom.addAttribute (alt label)
                                    |> Dom.addAttribute (attribute "src" "/img/characters/summons.png")
                                    |> Dom.addAttribute (attribute "draggable" "false")
                                , Dom.element "span" |> Dom.appendText (String.fromInt i)
                                ]

                        Summons BearSummons ->
                            \e ->
                                Dom.addClass "bear" e
                                    |> playerHtml label "bear"

                Game.None ->
                    Dom.addClass "none"
           )
        |> (if (model.gameMode == MovePiece && model.coords /= Nothing) || (model.gameMode == AddPiece && model.coords == Nothing) then
                makeDraggable (PieceType model.piece) model.coords

            else
                Dom.addAttribute (attribute "draggable" "false")
           )
        |> (if model.gameMode == KillPiece then
                Dom.addAction ( "click", RemovePiece model.piece )

            else
                \e -> e
           )
    )


enemyToHtml : Monster -> String -> Element msg -> Element msg
enemyToHtml monster altText element =
    let
        class =
            case monster.monster of
                NormalType _ ->
                    case monster.level of
                        Elite ->
                            "elite"

                        Normal ->
                            "normal"

                        Monster.None ->
                            ""

                BossType _ ->
                    "boss"
    in
    element
        |> Dom.addClass class
        |> Dom.addClass "hex-mask"
        |> Dom.appendChildList
            [ Dom.element "img"
                |> Dom.addAttribute
                    (attribute "src"
                        ("/img/monsters/"
                            ++ Maybe.withDefault "" (monsterTypeToString monster.monster)
                            ++ ".png"
                        )
                    )
                |> Dom.addAttribute (alt altText)
            , Dom.element "span"
                |> Dom.appendText
                    (if monster.id == 0 then
                        ""

                     else
                        String.fromInt monster.id
                    )
            ]


overlayToHtml : BoardOverlayModel -> ( String, Element Msg )
overlayToHtml model =
    let
        label =
            getLabelForOverlay model.overlay model.coords
    in
    ( label
    , Dom.element "div"
        |> Dom.addAttribute
            (attribute "aria-label" label)
        |> Dom.addClass "overlay"
        |> Dom.addClassConditional "being-dragged" model.isDragging
        |> Dom.addClass
            (case model.overlay.ref of
                StartingLocation ->
                    "start-location"

                Treasure t ->
                    "treasure "
                        ++ (case t of
                                Coin _ ->
                                    "coin"

                                Chest _ ->
                                    "chest"
                           )

                Obstacle _ ->
                    "obstacle"

                Hazard _ ->
                    "hazard"

                DifficultTerrain _ ->
                    "difficult-terrain"

                Door c _ ->
                    "door"
                        ++ (case c of
                                Corridor _ _ ->
                                    " corridor"

                                _ ->
                                    ""
                           )

                Trap _ ->
                    "trap"
            )
        |> Dom.addClass
            (case model.overlay.direction of
                Default ->
                    ""

                Vertical ->
                    "vertical"

                Horizontal ->
                    "horizontal"

                DiagonalRight ->
                    "diagonal-right"

                DiagonalLeft ->
                    "diagonal-left"

                DiagonalRightReverse ->
                    "diagonal-right-reverse"

                DiagonalLeftReverse ->
                    "diagonal-left-reverse"
            )
        |> Dom.addAttribute
            (attribute "data-index"
                (case model.overlay.ref of
                    Treasure t ->
                        case t of
                            Chest c ->
                                case c of
                                    NormalChest i ->
                                        String.fromInt i

                                    Goal ->
                                        "Goal"

                            _ ->
                                ""

                    _ ->
                        ""
                )
            )
        |> Dom.appendChild
            (Dom.element "img"
                |> Dom.addAttribute (alt (getOverlayLabel model.overlay.ref))
                |> Dom.addAttribute (attribute "src" (getOverlayImageName model.overlay model.coords))
                |> Dom.addAttribute (attribute "draggable" "false")
            )
        |> (case model.overlay.ref of
                Treasure (Coin i) ->
                    Dom.appendChild
                        (Dom.element "span"
                            |> Dom.appendText (String.fromInt i)
                        )

                _ ->
                    \e -> e
           )
        |> (if (model.gameMode == MoveOverlay && model.coords /= Nothing) || (model.gameMode == AddPiece && model.coords == Nothing) then
                case model.overlay.ref of
                    Obstacle _ ->
                        makeDraggable (OverlayType model.overlay Nothing) model.coords

                    Trap _ ->
                        makeDraggable (OverlayType model.overlay Nothing) model.coords

                    _ ->
                        Dom.addAttribute (attribute "draggable" "false")

            else
                Dom.addAttribute (attribute "draggable" "false")
           )
    )


getOverlayImageName : BoardOverlay -> Maybe ( Int, Int ) -> String
getOverlayImageName overlay coords =
    let
        path =
            "/img/overlays/"

        overlayName =
            getBoardOverlayName overlay.ref

        extension =
            ".png"

        extendedOverlayName =
            case ( overlay.ref, overlay.direction ) of
                ( Door Stone _, Vertical ) ->
                    "-vert"

                ( Door BreakableWall _, Vertical ) ->
                    "-vert"

                ( Door Wooden _, Vertical ) ->
                    "-vert"

                ( Obstacle Altar, Vertical ) ->
                    "-vert"

                _ ->
                    ""

        segmentPart =
            case coords of
                Just ( x, y ) ->
                    case head (List.filter (\( _, ( oX, oY ) ) -> oX == x && oY == y) (toIndexedList (fromList overlay.cells))) of
                        Just ( segment, _ ) ->
                            if segment > 0 then
                                "-" ++ String.fromInt (segment + 1)

                            else
                                ""

                        Nothing ->
                            ""

                Nothing ->
                    ""
    in
    path ++ overlayName ++ extendedOverlayName ++ segmentPart ++ extension


addActionsForCell : GameModeType -> ( Int, Int ) -> List BoardOverlay -> Dom.Element Msg -> Dom.Element Msg
addActionsForCell currentMode coords overlays element =
    case overlays of
        overlay :: rest ->
            let
                e =
                    element
                        |> (case ( currentMode, overlay.ref ) of
                                ( DestroyOverlay, Obstacle _ ) ->
                                    Dom.addAction ( "click", RemoveOverlay overlay )

                                ( DestroyOverlay, Trap _ ) ->
                                    Dom.addAction ( "click", RemoveOverlay overlay )

                                ( LootCell, Treasure _ ) ->
                                    Dom.addAction ( "click", RemoveOverlay overlay )

                                ( RevealRoom, Door _ refs ) ->
                                    Dom.addAction ( "click", RevealRoomMsg refs coords )

                                _ ->
                                    \x -> x
                           )
            in
            addActionsForCell currentMode coords rest e

        _ ->
            element


getCharacterListSettings : Model -> List CharacterClass
getCharacterListSettings model =
    case model.currentPlayerList of
        Just c ->
            c

        Nothing ->
            model.game.state.players


getSplitRoomCodeSettings : Model -> TransientClientSettings
getSplitRoomCodeSettings model =
    case model.currentClientSettings of
        Just s ->
            s

        Nothing ->
            let
                splitCode =
                    case split "-" (Maybe.withDefault "" model.config.roomCode) of
                        head :: rest ->
                            ( head, join "" rest )

                        _ ->
                            ( "", "" )
            in
            TransientClientSettings
                splitCode
                model.config.showRoomCode
                model.config.boardOnly
                model.fullscreen


pushGameState : Model -> GameState -> Bool -> Cmd Msg
pushGameState model state addToUndo =
    Cmd.batch
        (saveToStorage state model.config
            :: (if model.connectionStatus /= Connected || model.config.roomCode == Nothing then
                    [ Process.sleep 500
                        |> Task.perform (\_ -> PushGameState addToUndo)
                    ]

                else
                    GameSync.pushGameState (Maybe.withDefault "" model.config.roomCode) state
                        :: (if addToUndo then
                                [ Process.sleep 100
                                    |> Task.perform (\_ -> PushToUndoStack model.game.state)
                                ]

                            else
                                []
                           )
               )
        )


getSortOrderForOverlay : BoardOverlayType -> Int
getSortOrderForOverlay overlay =
    case overlay of
        Door _ _ ->
            0

        Hazard _ ->
            1

        DifficultTerrain _ ->
            2

        StartingLocation ->
            3

        Treasure t ->
            case t of
                Chest _ ->
                    4

                Coin _ ->
                    5

        Obstacle _ ->
            6

        Trap _ ->
            7


shortcutHtml : List String -> Element msg -> Element msg
shortcutHtml keys element =
    element
        |> Dom.addAttribute
            (attribute "aria-keyshortcuts"
                (List.intersperse "+" keys
                    |> List.foldr (++) ""
                    |> String.replace "⇧" "shift"
                    |> String.toLower
                )
            )
        |> Dom.addAttribute (attribute "aria-hidden" "true")
        |> Dom.appendChild
            (Dom.element "span"
                |> Dom.addClass "shortcut"
                |> Dom.appendChildList
                    (map
                        (\k ->
                            Dom.element "span"
                                |> Dom.addClass "key"
                                |> Dom.appendText k
                        )
                        keys
                    )
            )


tooltipHtml : String -> String -> Element Msg -> Element Msg
tooltipHtml identifier tooltip element =
    element
        |> Dom.addAttribute (attribute "aria-label" tooltip)
        |> Dom.setId identifier
        |> Dom.addAction ( "pointerover", InitTooltip identifier tooltip )
        |> Dom.addAction ( "pointerout", ResetTooltip )


isValidScenario : String -> Bool
isValidScenario scenarioId =
    case String.toInt scenarioId of
        Just i ->
            i > 0 && i < 96

        Nothing ->
            False


isValidRoomCode : String -> Bool
isValidRoomCode roomCode =
    let
        splitCode =
            split "-" roomCode
    in
    case splitCode of
        code1 :: code2 :: rest ->
            (List.length rest == 0)
                && all (\c -> Char.isAlphaNum c) (String.toList code1)
                && all (\c -> Char.isAlphaNum c) (String.toList code2)
                && String.length code1
                == 5
                && String.length code2
                == 5

        _ ->
            False


keyDecoder : Decode.Decoder String
keyDecoder =
    Decode.field "key" Decode.string |> Decode.andThen (\s -> Decode.succeed (String.toLower s))


makeDraggable : MoveablePieceType -> Maybe ( Int, Int ) -> Element Msg -> Element Msg
makeDraggable piece coords element =
    let
        config =
            DragDrop.DraggedSourceConfig
                (DragDrop.EffectAllowed False False False)
                (\_ _ -> MoveStarted (MoveablePiece piece coords Nothing))
                (\_ -> MoveCompleted)
                Nothing
    in
    element
        |> Dom.addAttributeList (DragDrop.onSourceDrag config)
        |> Dom.addAttribute (Touch.onStart (\_ -> TouchStart (MoveablePiece piece coords Nothing)))
        |> Dom.addAttribute
            (Touch.onMove
                (\e ->
                    case head e.touches of
                        Just touch ->
                            TouchMove touch.clientPos

                        Nothing ->
                            NoOp
                )
            )
        |> Dom.addAttribute
            (Touch.onEnd
                (\e ->
                    case head e.changedTouches of
                        Just touch ->
                            TouchEnd touch.clientPos

                        Nothing ->
                            NoOp
                )
            )


makeDroppable : ( Int, Int ) -> Element Msg -> Element Msg
makeDroppable coords element =
    let
        config =
            DragDrop.DropTargetConfig
                DragDrop.NoDropEffect
                (\_ _ -> MoveTargetChanged coords)
                (\_ -> NoOp)
                Nothing
                Nothing
    in
    element
        |> Dom.addAttributeList (DragDrop.onDropTarget config)


getLabelForOverlay : BoardOverlay -> Maybe ( Int, Int ) -> String
getLabelForOverlay overlay coords =
    case coords of
        Just ( x, y ) ->
            getOverlayLabel overlay.ref ++ " at " ++ String.fromInt x ++ ", " ++ String.fromInt y

        Nothing ->
            "Add new " ++ getOverlayLabel overlay.ref


getLabelForPiece : Piece -> String
getLabelForPiece piece =
    case piece.ref of
        Player p ->
            Maybe.withDefault "" (characterToString p)
                |> String.replace "-" " "

        AI t ->
            case t of
                Enemy m ->
                    (case m.monster of
                        NormalType _ ->
                            case m.level of
                                Elite ->
                                    "Elite"

                                Normal ->
                                    "Normal"

                                Monster.None ->
                                    ""

                        BossType _ ->
                            "Boss"
                    )
                        ++ " "
                        ++ (Maybe.withDefault "" (monsterTypeToString m.monster)
                                |> String.replace "-" " "
                           )
                        ++ (if m.id > 0 then
                                " (" ++ String.fromInt m.id ++ ")"

                            else
                                ""
                           )

                Summons (NormalSummons i) ->
                    "Summons Number " ++ String.fromInt i

                Summons BearSummons ->
                    "Beast Tyrant Bear Summons"

        Game.None ->
            "None"


getDeadPlayers : GameState -> List CharacterClass
getDeadPlayers state =
    let
        playerPieces =
            state.pieces
                |> List.filterMap
                    (\p ->
                        case p.ref of
                            Player c ->
                                Just c

                            _ ->
                                Nothing
                    )
    in
    state.players
        |> List.filter (\p -> List.member p playerPieces == False)
