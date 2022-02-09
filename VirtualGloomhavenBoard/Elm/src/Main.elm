port module Main exposing (main)

import AppStorage exposing (AppModeType(..), CampaignTrackerUrl(..), Config, GameModeType(..), MoveablePiece, MoveablePieceType(..), decodeMoveablePiece, emptyOverrides, encodeMoveablePiece, loadFromStorage, loadOverrides, saveToStorage)
import Array exposing (Array, fromList, length, toIndexedList, toList)
import BoardHtml exposing (ContextMenu(..), formatNameString, getMapTileHtml, getTutorialHtml)
import BoardMapTile exposing (MapTileRef(..))
import BoardOverlay exposing (BoardOverlay, BoardOverlayDirectionType(..), BoardOverlayType(..), ChestType(..), CorridorMaterial(..), DifficultTerrainSubType(..), DoorSubType(..), HazardSubType(..), ObstacleSubType(..), TrapSubType(..), TreasureSubType(..), getBoardOverlayName, getOverlayLabel)
import Browser
import Browser.Dom as BrowserDom
import Browser.Events exposing (Visibility(..), onKeyDown, onKeyUp, onVisibilityChange)
import Character exposing (CharacterClass(..), characterToString, getSoloScenarios)
import Colour
import Dict exposing (Dict)
import Dom exposing (Element)
import DragPorts
import File exposing (File)
import File.Select as Select
import Game exposing (AIType(..), Cell, Expansion(..), Game, GameState, GameStateScenario(..), Piece, PieceType(..), SummonsType(..), assignIdentifier, assignPlayers, generateGameMap, getPieceName, getPieceType, moveOverlay, movePiece, removePieceFromBoard, revealRooms)
import GameSync exposing (Msg(..), connectToServer, ensureOverlayIds, update)
import Hexagon exposing (rotate)
import Html exposing (Html, a, div, footer, header, iframe, li, nav, span, text, ul)
import Html.Attributes exposing (alt, attribute, checked, class, href, id, maxlength, minlength, required, selected, src, style, tabindex, target, title, value)
import Html.Events exposing (on, onClick, targetValue)
import Html.Events.Extra.Drag as DragDrop
import Html.Events.Extra.Touch as Touch
import Html.Keyed as Keyed
import Html.Lazy exposing (lazy, lazy3, lazy5, lazy6, lazy8)
import HtmlEvents exposing (onClickPreventDefault)
import Http
import Json.Decode as Decode exposing (decodeString)
import Json.Encode as Encode
import List exposing (all, any, filter, filterMap, head, map, member, reverse, sort, sortWith, take)
import List.Extra
import Monster exposing (BossType(..), Monster, MonsterLevel(..), MonsterType(..), NormalMonsterType(..), monsterTypeToString, stringToMonsterType)
import Process
import Random exposing (Seed)
import Scenario exposing (DoorData(..), Scenario)
import ScenarioSync exposing (decodeScenario, loadScenarioById)
import SpecialRules
import String exposing (join, split)
import Task
import Version


port onPaste : (String -> msg) -> Sub msg


port getCellFromPoint : ( Float, Float, Bool ) -> Cmd msg


port onCellFromPoint : (( Int, Int, Bool ) -> msg) -> Sub msg


port getContextPosition : ( Int, Int ) -> Cmd msg


port onContextPosition : (( Int, Int ) -> msg) -> Sub msg


port scrollToFirtVisibleCell : () -> Cmd msg


type alias Model =
    { game : Game
    , config : Config
    , currentLoadState : LoadingState
    , currentScenarioType : Maybe GameStateScenario
    , currentScenarioInput : Maybe String
    , currentClientSettings : Maybe TransientClientSettings
    , currentPlayerList : Maybe (List CharacterClass)
    , currentSelectedFile : Maybe ( String, Maybe (Result Decode.Error Scenario) )
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
    , contextMenuState : ContextMenu
    , contextMenuPosition : ( Int, Int )
    , contextMenuAbsPosition : ( Int, Int )
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
    , summonsColour : String
    , showRoomCode : Bool
    , boardOnly : Bool
    , fullscreen : Bool
    , envelopeX : Bool
    }


type LoadingState
    = Loaded
    | Loading GameStateScenario
    | Failed


type ConnectionStatus
    = Connected
    | Disconnected
    | Reconnecting


type Msg
    = LoadedScenarioHttp Seed GameStateScenario (Maybe Game.GameState) Bool (Result Http.Error Scenario)
    | LoadedScenarioJson Seed GameStateScenario (Maybe Game.GameState) Bool (Result Decode.Error Scenario)
    | ReloadScenario
    | ChooseScenarioFile
    | ExtractScenarioFile File
    | LoadScenarioFile String
    | MoveStarted MoveablePiece (Maybe ( DragDrop.EffectAllowed, Decode.Value ))
    | MoveTargetChanged ( Int, Int ) (Maybe ( DragDrop.DropEffect, Decode.Value ))
    | MoveCanceled
    | MoveCompleted
    | TouchStart MoveablePiece
    | TouchMove ( Float, Float )
    | TouchCanceled
    | TouchEnd ( Float, Float )
    | CellFromPoint ( Int, Int, Bool )
    | GameStateUpdated Game.GameState
    | AddOverlay BoardOverlay
    | AddToken BoardOverlay
    | AddHighlight BoardOverlay
    | AddPiece Piece
    | RotateOverlay Int
    | RemoveOverlay BoardOverlay
    | RemovePiece Piece
    | PhasePiece Piece
    | ChangeGameMode GameModeType
    | ChangeAppMode AppModeType
    | RevealRoomMsg (List MapTileRef) ( Int, Int )
    | ChangeScenario GameStateScenario Bool
    | OpenContextMenu ( Int, Int )
    | ChangeContextMenuState ContextMenu
    | ChangeContextMenuAbsposition ( Int, Int )
    | ToggleCharacter CharacterClass Bool
    | ToggleBoardOnly Bool
    | ToggleFullscreen Bool
    | ToggleEnvelopeX Bool
    | ToggleMenu
    | ChangePlayerList
    | EnterScenarioType GameStateScenario
    | EnterScenarioNumber String
    | UpdateTutorialStep Int
    | ChangeRoomCodeInputStart String
    | ChangeRoomCodeInputEnd String
    | ChangeShowRoomCode Bool
    | ChangeSummonsColour String
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


undoLimit : Int
undoLimit =
    25


boardTutorialStep : Int
boardTutorialStep =
    0


roomCodeTutorialStep : Int
roomCodeTutorialStep =
    1


menuTutorialStep : Int
menuTutorialStep =
    2


lastTutorialStep : Int
lastTutorialStep =
    3


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


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        roomCode =
            Maybe.withDefault "" model.config.roomCode
    in
    case msg of
        LoadedScenarioHttp seed gameStateScenario initGameState addToUndo result ->
            case result of
                Ok scenario ->
                    loadScenario model roomCode seed gameStateScenario initGameState addToUndo scenario

                Err _ ->
                    ( { model | currentLoadState = Failed }, Cmd.none )

        LoadedScenarioJson seed gameStateScenario initGameState addToUndo result ->
            case result of
                Ok scenario ->
                    loadScenario model roomCode seed gameStateScenario initGameState addToUndo scenario

                Err _ ->
                    ( { model | currentLoadState = Failed }, Cmd.none )

        ReloadScenario ->
            update (ChangeScenario model.game.state.scenario True) model

        ChooseScenarioFile ->
            ( model, Select.file [ "application/json" ] ExtractScenarioFile )

        ExtractScenarioFile file ->
            ( { model | currentSelectedFile = Just ( File.name file, Nothing ) }
            , Task.perform LoadScenarioFile (File.toString file)
            )

        LoadScenarioFile str ->
            case ( getCurrentScenarioInput model, model.currentSelectedFile ) of
                ( CustomScenario _, Just ( filename, _ ) ) ->
                    ( { model
                        | currentScenarioType = Just (CustomScenario str)
                        , currentSelectedFile = Just ( filename, Just (decodeString decodeScenario str) )
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        MoveStarted piece maybeDragData ->
            let
                cmd =
                    case maybeDragData of
                        Just ( e, v ) ->
                            DragPorts.dragstart (DragDrop.startPortData e v)

                        Nothing ->
                            Cmd.none
            in
            ( { model | currentDraggable = Just piece }, cmd )

        MoveTargetChanged coords maybeDragOver ->
            case model.currentDraggable of
                Just m ->
                    if m.target == Just coords then
                        ( model, Cmd.none )

                    else
                        let
                            cmd =
                                case maybeDragOver of
                                    Just ( e, v ) ->
                                        DragPorts.dragover (DragDrop.overPortData e v)

                                    Nothing ->
                                        Cmd.none

                            newDraggable =
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

                                    RoomType _ ->
                                        -- We don't support moving rooms in the main game
                                        Nothing
                        in
                        ( { model | currentDraggable = newDraggable }, cmd )

                Nothing ->
                    ( model, Cmd.none )

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
            update (MoveStarted piece Nothing) model

        TouchCanceled ->
            update MoveCanceled model

        TouchMove ( x, y ) ->
            ( model, getCellFromPoint ( x, y, False ) )

        TouchEnd ( x, y ) ->
            ( model, getCellFromPoint ( x, y, True ) )

        CellFromPoint ( x, y, endTouch ) ->
            if endTouch then
                case model.currentDraggable of
                    Just c ->
                        if Just ( x, y ) == c.coords then
                            update (OpenContextMenu ( x, y )) { model | currentDraggable = Nothing }

                        else
                            update MoveCompleted model

                    Nothing ->
                        ( model, Cmd.none )

            else
                update (MoveTargetChanged ( x, y ) Nothing) model

        AddOverlay overlay ->
            if List.any (\b -> b.id == overlay.id) model.game.state.overlays then
                ( model, Cmd.none )

            else
                let
                    oldState =
                        model.game.state

                    newOverlays =
                        case overlay.ref of
                            Treasure (Coin i) ->
                                let
                                    newCoin =
                                        List.filter
                                            (\c ->
                                                case c.ref of
                                                    Treasure (Coin _) ->
                                                        if c.cells == overlay.cells then
                                                            True

                                                        else
                                                            False

                                                    _ ->
                                                        False
                                            )
                                            oldState.overlays
                                            |> List.map
                                                (\c ->
                                                    case c.ref of
                                                        Treasure (Coin i2) ->
                                                            { c | ref = Treasure (Coin (i2 + i)) }

                                                        _ ->
                                                            c
                                                )
                                            |> List.head
                                            |> Maybe.withDefault
                                                { overlay | ref = Treasure (Coin i) }
                                in
                                newCoin
                                    :: List.filter
                                        (\c ->
                                            case c.ref of
                                                Treasure (Coin _) ->
                                                    if c.cells == overlay.cells then
                                                        False

                                                    else
                                                        True

                                                _ ->
                                                    True
                                        )
                                        oldState.overlays

                            _ ->
                                overlay :: oldState.overlays

                    newState =
                        { oldState | overlays = newOverlays }

                    oldGame =
                        model.game

                    newGame =
                        { oldGame | state = newState }
                in
                ( { model | game = newGame, contextMenuState = Closed }, pushGameState model newState True )

        AddToken token ->
            if List.any (\b -> b.id == token.id) model.game.state.overlays then
                ( model, Cmd.none )

            else
                let
                    oldState =
                        model.game.state

                    newState =
                        { oldState | overlays = token :: oldState.overlays }

                    oldGame =
                        model.game

                    newGame =
                        { oldGame | state = newState }
                in
                ( { model | game = newGame, contextMenuState = Closed }, pushGameState model newState True )

        AddHighlight highlight ->
            if List.any (\b -> b.id == highlight.id) model.game.state.overlays then
                ( model, Cmd.none )

            else
                let
                    oldState =
                        model.game.state

                    newState =
                        { oldState
                            | overlays =
                                highlight
                                    :: filter
                                        (\o ->
                                            if o.cells /= highlight.cells then
                                                True

                                            else
                                                case o.ref of
                                                    Highlight _ ->
                                                        False

                                                    _ ->
                                                        True
                                        )
                                        oldState.overlays
                        }

                    oldGame =
                        model.game

                    newGame =
                        { oldGame | state = newState }
                in
                ( { model | game = newGame, contextMenuState = Closed }, pushGameState model newState True )

        AddPiece piece ->
            let
                oldGame =
                    model.game

                game =
                    case piece.ref of
                        AI (Enemy monster) ->
                            (if monster.id == 0 then
                                assignIdentifier oldGame.state.availableMonsters piece

                             else
                                ( piece, oldGame.state.availableMonsters )
                            )
                                |> (\( p2, d ) ->
                                        let
                                            newGame =
                                                Tuple.first (movePiece p2 Nothing ( piece.x, piece.y ) oldGame)

                                            newState =
                                                newGame.state
                                        in
                                        { newGame | state = { newState | availableMonsters = d } }
                                   )

                        _ ->
                            Tuple.first (movePiece piece Nothing ( piece.x, piece.y ) oldGame)
            in
            ( { model | game = game, deadPlayerList = getDeadPlayers game.state, contextMenuState = Closed, currentDraggable = Nothing }, pushGameState model game.state True )

        RotateOverlay id ->
            let
                o1 =
                    List.filter (\o -> o.id == id) model.game.state.overlays
                        |> List.head
            in
            case o1 of
                Just overlay ->
                    let
                        refPoint =
                            Maybe.withDefault ( 0, 0 ) (List.head overlay.cells)

                        cells =
                            List.map (\c -> rotate c refPoint 1) overlay.cells

                        direction =
                            case overlay.direction of
                                Default ->
                                    DiagonalLeft

                                DiagonalLeft ->
                                    if List.length cells == 1 then
                                        Vertical

                                    else
                                        DiagonalRight

                                Vertical ->
                                    DiagonalRight

                                DiagonalRight ->
                                    Horizontal

                                Horizontal ->
                                    DiagonalLeftReverse

                                DiagonalLeftReverse ->
                                    if List.length cells == 1 then
                                        VerticalReverse

                                    else
                                        DiagonalRightReverse

                                VerticalReverse ->
                                    DiagonalRightReverse

                                DiagonalRightReverse ->
                                    Default

                        newOverlay =
                            { overlay | cells = cells, direction = direction }

                        overlayList =
                            newOverlay
                                :: List.filter (\o2 -> o2.id /= id) model.game.state.overlays

                        game =
                            model.game

                        state =
                            model.game.state

                        newState =
                            { state | overlays = overlayList }
                    in
                    ( { model | game = { game | state = newState } }, pushGameState model newState True )

                Nothing ->
                    ( model, Cmd.none )

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

        PhasePiece piece ->
            case piece.ref of
                AI (Enemy monster) ->
                    let
                        game =
                            model.game

                        gameState =
                            model.game.state

                        mappedPieces =
                            map
                                (\p ->
                                    if p == piece then
                                        { p
                                            | ref =
                                                AI (Enemy { monster | outOfPhase = monster.outOfPhase == False })
                                        }

                                    else
                                        p
                                )
                                gameState.pieces

                        newState =
                            { gameState | pieces = mappedPieces }
                    in
                    ( { model | game = { game | state = newState } }, pushGameState model newState True )

                _ ->
                    ( model, Cmd.none )

        ChangeGameMode mode ->
            let
                config =
                    model.config

                newModel =
                    { model | config = { config | gameMode = mode }, currentClientSettings = Nothing, currentPlayerList = Nothing, currentScenarioInput = Nothing, currentSelectedFile = Nothing }
            in
            ( newModel, saveToStorage newModel.game.state newModel.config )

        RevealRoomMsg rooms ( x, y ) ->
            let
                updatedGame =
                    revealRooms model.game rooms

                -- Make sure we remove any fog as a special rule for 101 (see issue #75)
                newState =
                    if model.game.state.scenario == InbuiltScenario Gloomhaven 101 then
                        SpecialRules.scenario101DoorUpdate updatedGame.state

                    else
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
                        , currentScenarioType = Nothing
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
                let
                    newModel =
                        { model | config = { config | appMode = AppStorage.Game }, currentLoadState = Loading newScenario, currentDraggable = Nothing, currentScenarioType = Nothing, currentScenarioInput = Nothing }
                in
                case newScenario of
                    InbuiltScenario _ _ ->
                        ( newModel
                        , loadScenarioById newScenario (LoadedScenarioHttp model.game.seed newScenario Nothing True)
                        )

                    CustomScenario str ->
                        update
                            (LoadedScenarioJson model.game.seed newScenario Nothing True (decodeString decodeScenario str))
                            newModel

            else
                ( { model | config = { config | appMode = AppStorage.Game } }, Cmd.none )

        EnterScenarioType gameStateType ->
            ( { model | currentScenarioType = Just gameStateType, currentScenarioInput = Just "1", currentSelectedFile = Nothing }, Cmd.none )

        EnterScenarioNumber strId ->
            ( { model | currentScenarioInput = Just strId }, Cmd.none )

        UpdateTutorialStep step ->
            let
                config =
                    model.config

                newStep =
                    if step == roomCodeTutorialStep && model.config.showRoomCode == False then
                        menuTutorialStep

                    else
                        step

                newConfig =
                    { config | tutorialStep = newStep }
            in
            ( { model | config = newConfig }, saveToStorage model.game.state newConfig )

        ChangeSummonsColour colour ->
            let
                settings =
                    getSplitRoomCodeSettings model
            in
            ( { model
                | currentClientSettings = Just { settings | summonsColour = colour }
              }
            , Cmd.none
            )

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
                                            , summonsColour = settings.summonsColour
                                            , boardOnly = settings.boardOnly
                                            , envelopeX = settings.envelopeX
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

        ChangeContextMenuState menuState ->
            ( { model | contextMenuState = menuState }, Cmd.none )

        OpenContextMenu pos ->
            ( { model | contextMenuState = Open, contextMenuPosition = pos }, getContextPosition pos )

        ChangeContextMenuAbsposition pos ->
            ( { model | contextMenuAbsPosition = pos }, Cmd.none )

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

        ToggleEnvelopeX envelopeX ->
            let
                transSettings =
                    getSplitRoomCodeSettings model
            in
            ( { model
                | currentClientSettings = Just { transSettings | envelopeX = envelopeX }
              }
            , Cmd.none
            )

        ToggleMenu ->
            ( { model | menuOpen = model.menuOpen == False }, Cmd.none )

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
                case gameState.scenario of
                    InbuiltScenario _ _ ->
                        ( { model | currentLoadState = Loading gameState.scenario }
                        , loadScenarioById gameState.scenario (LoadedScenarioHttp game.seed gameState.scenario (Just gameState) True)
                        )

                    CustomScenario s ->
                        update
                            (LoadedScenarioJson game.seed gameState.scenario (Just gameState) True (decodeString decodeScenario s))
                            { model | currentLoadState = Loading gameState.scenario }

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
                        case state.scenario of
                            InbuiltScenario _ _ ->
                                ( { newModel | currentLoadState = Loading state.scenario }
                                , loadScenarioById state.scenario (LoadedScenarioHttp model.game.seed state.scenario (Just newState) False)
                                )

                            CustomScenario str ->
                                update
                                    (LoadedScenarioJson model.game.seed state.scenario (Just newState) False (decodeString decodeScenario str))
                                    { newModel | currentLoadState = Loading state.scenario }

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
                            scenario =
                                getCurrentScenarioInput model
                        in
                        if isValidScenario scenario then
                            update (ChangeScenario scenario False) model

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
                    case String.toInt data of
                        Just i ->
                            let
                                scenario =
                                    case getCurrentScenarioInput model of
                                        InbuiltScenario e _ ->
                                            InbuiltScenario e i

                                        s ->
                                            s
                            in
                            if isValidScenario scenario then
                                ( { model | currentScenarioInput = Just data }, Cmd.none )

                            else
                                ( model, Cmd.none )

                        Nothing ->
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
        , onClick (ChangeContextMenuState Closed)
        ]
        ([ getHeaderHtml model
         , div [ class "main" ]
            [ Keyed.node
                "div"
                [ class "board-wrapper", id "board" ]
                ([ ( "mapBg", div [ class "map-bg" ] [] )
                 , ( "mapTiles", lazy5 getMapTileHtml model.game.state.visibleRooms model.game.roomData "" 0 0 )
                 , ( "mainBoard"
                   , Html.main_ [ class "board" ]
                        (let
                            encodedDraggable =
                                case model.currentDraggable of
                                    Just c ->
                                        Encode.encode 0 (encodeMoveablePiece c)

                                    Nothing ->
                                        ""

                            draggableCoords =
                                case model.currentDraggable of
                                    Just m ->
                                        case m.ref of
                                            OverlayType o _ ->
                                                let
                                                    coordList =
                                                        case m.coords of
                                                            Just initCoords ->
                                                                model.game.state.overlays
                                                                    |> map (\o1 -> o1.cells)
                                                                    |> filter (\c1 -> any (\c -> c == initCoords) c1)
                                                                    |> List.foldl (++) []

                                                            Nothing ->
                                                                []

                                                    targetCoords =
                                                        case m.target of
                                                            Just _ ->
                                                                o.cells

                                                            Nothing ->
                                                                []
                                                in
                                                coordList ++ targetCoords

                                            _ ->
                                                (case m.coords of
                                                    Just initCoords ->
                                                        [ initCoords ]

                                                    Nothing ->
                                                        []
                                                )
                                                    ++ (case m.target of
                                                            Just targetCoords ->
                                                                [ targetCoords ]

                                                            Nothing ->
                                                                []
                                                       )

                                    Nothing ->
                                        []
                         in
                         toList (Array.indexedMap (getBoardHtml model model.game encodedDraggable draggableCoords) model.game.staticBoard)
                        )
                   )
                 ]
                    ++ (if model.config.tutorialStep == boardTutorialStep then
                            [ getTutorialHtml "This is your board. You can move pieces by dragging and dropping them in place. You can rotate, remove or add pieces by clicking on any space." model.config.tutorialStep (UpdateTutorialStep roomCodeTutorialStep) ]

                        else
                            []
                       )
                )
            , lazy getConnectionStatusHtml model.connectionStatus
            , getContextMenu model.game.scenario.id model.contextMenuState model.contextMenuPosition model.contextMenuAbsPosition model.config.summonsColour model.game.state.pieces model.game.state.overlays model.game.state.players model.game.state.availableMonsters
            ]
         , lazy getFooterHtml Version.get
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
        , onContextPosition ChangeContextMenuAbsposition
        ]


getHeaderHtml : Model -> Html.Html Msg
getHeaderHtml model =
    let
        isSoloScenario =
            case model.game.state.scenario of
                InbuiltScenario Solo _ ->
                    True

                _ ->
                    False
    in
    div
        [ class "header" ]
        [ getMenuToggleHtml model
        , lazy3 getScenarioTitleHtml model.game.scenario.id model.game.scenario.title isSoloScenario
        , lazy3 getRoomCodeHtml model.config.roomCode model.config.showRoomCode (model.config.tutorialStep == roomCodeTutorialStep)
        ]


getMenuToggleHtml : Model -> Html.Html Msg
getMenuToggleHtml model =
    Keyed.node
        "div"
        [ class
            ("menu"
                ++ (if model.menuOpen then
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
            (if model.menuOpen then
                "true"

             else
                "false"
            )
        ]
        ((let
            ( campaignTrackerName, campaignTrackerUrl ) =
                case model.config.campaignTracker of
                    Just (CampaignTrackerUrl name url) ->
                        ( Just name, Just url )

                    Nothing ->
                        ( Nothing, Nothing )
          in
          ( "menuHtml", lazy6 getMenuHtml model.lockScenario model.lockPlayers model.game.scenario.id campaignTrackerName campaignTrackerUrl model.menuOpen )
         )
            :: (if model.config.tutorialStep == menuTutorialStep then
                    [ getTutorialHtml "If you need to change a setting, add players, or undo a turn you've made - you can do it all by clicking the menu icon above." menuTutorialStep (UpdateTutorialStep lastTutorialStep) ]

                else
                    []
               )
        )


getScenarioTitleHtml : Int -> String -> Bool -> Html.Html Msg
getScenarioTitleHtml id titleTxt isSolo =
    header [ attribute "aria-label" "Scenario" ]
        (if titleTxt /= "" then
            [ if isSolo then
                let
                    icon =
                        getSoloScenarios
                            |> Dict.filter (\_ ( i, _ ) -> i == id)
                            |> Dict.keys
                            |> List.map (\c -> getCharacterClassIconHtml c |> Dom.render)
                            |> List.head
                in
                case icon of
                    Just i ->
                        i

                    Nothing ->
                        span [ class "number" ] []

              else if id /= 0 then
                span [ class "number" ] [ text (String.fromInt id) ]

              else
                span [ class "number" ] []
            , span [ class "title" ] [ text titleTxt ]
            ]

         else
            []
        )


getContextMenu : Int -> ContextMenu -> ( Int, Int ) -> ( Int, Int ) -> String -> List Piece -> List BoardOverlay -> List CharacterClass -> Dict String (Array Int) -> Html Msg
getContextMenu scenarioNumber state ( x, y ) ( absX, absY ) summonsColour pieces overlays players availableMonsters =
    let
        bearSummoned =
            (List.member BeastTyrant players == False)
                || List.any (\p -> p.ref == AI (Summons BearSummons)) pieces

        hasDiviner =
            List.member Diviner players

        maxSummons =
            filterMap
                (\p ->
                    case p.ref of
                        AI (Summons (NormalSummons i _)) ->
                            Just i

                        _ ->
                            Nothing
                )
                pieces
                |> sort
                |> reverse
                |> head

        nextId =
            case maxSummons of
                Just i ->
                    i + 1

                Nothing ->
                    1

        nextOverlayId =
            case
                List.map (\o -> o.id) overlays
                    |> List.maximum
            of
                Just i ->
                    i + 1

                Nothing ->
                    1

        piece =
            List.filter (\p -> p.x == x && p.y == y) pieces
                |> List.head

        rooms =
            List.filter (\o -> List.any (\c -> c == ( x, y )) o.cells) overlays
                |> List.filterMap
                    (\o ->
                        case o.ref of
                            Door _ refs ->
                                Just refs

                            _ ->
                                Nothing
                    )
                |> List.foldl (++) []

        filteredOverlays =
            List.filter
                (\o ->
                    case o.ref of
                        StartingLocation ->
                            False

                        Door _ _ ->
                            False

                        _ ->
                            True
                )
                overlays
                |> List.filter (\o -> List.any (\c -> c == ( x, y )) o.cells)

        hasObstacle =
            List.any
                (\o ->
                    case o.ref of
                        Obstacle _ ->
                            True

                        _ ->
                            False
                )
                filteredOverlays

        hasDifficultTerrain =
            List.any
                (\o ->
                    case o.ref of
                        DifficultTerrain _ ->
                            True

                        _ ->
                            False
                )
                filteredOverlays

        hasTrap =
            List.any
                (\o ->
                    case o.ref of
                        Trap _ ->
                            True

                        _ ->
                            False
                )
                filteredOverlays

        hasHazard =
            List.any
                (\o ->
                    case o.ref of
                        Hazard _ ->
                            True

                        _ ->
                            False
                )
                filteredOverlays

        menuList =
            if state /= Closed then
                (if List.length rooms > 0 then
                    [ li
                        [ class "open-door"
                        , onClickPreventDefault (RevealRoomMsg rooms ( x, y ))
                        ]
                        [ text "Open Door"
                        ]
                    ]

                 else
                    []
                )
                    ++ List.map
                        (\o ->
                            li
                                [ class "rotate-overlay"
                                , onClickPreventDefault (RotateOverlay o.id)
                                ]
                                [ text ("Rotate " ++ getOverlayLabel o.ref)
                                ]
                        )
                        filteredOverlays
                    ++ [ li
                            [ class "place-overlay has-sub-menu"
                            , onClickPreventDefault (ChangeContextMenuState PlaceOverlayMenu)
                            ]
                            [ text "Place Piece"
                            , lazy8 getPlacePieceMenuHtml ( x, y ) (state == PlaceOverlayMenu) hasDiviner hasObstacle hasTrap hasDifficultTerrain hasHazard nextOverlayId
                            ]
                       , li
                            [ class "place-token has-sub-menu"
                            , onClickPreventDefault (ChangeContextMenuState PlaceTokenMenu)
                            ]
                            [ text "Place Token"
                            , lazy3 getPlaceTokenMenuHtml ( x, y ) (state == PlaceTokenMenu) nextOverlayId
                            ]
                       , li
                            [ class "place-highlight has-sub-menu"
                            , onClickPreventDefault (ChangeContextMenuState PlaceHighlightMenu)
                            ]
                            [ text "Highlight"
                            , lazy3 getPlaceHighlightMenuHtml ( x, y ) (state == PlaceHighlightMenu) nextOverlayId
                            ]
                       ]
                    ++ (case piece of
                            Just p ->
                                let
                                    pieceName =
                                        (case p.ref of
                                            Player character ->
                                                Maybe.withDefault "" (characterToString character)

                                            AI (Enemy monster) ->
                                                Maybe.withDefault "" (monsterTypeToString monster.monster)

                                            AI (Summons summons) ->
                                                case summons of
                                                    NormalSummons i _ ->
                                                        "Summons " ++ String.fromInt i

                                                    BearSummons ->
                                                        "Bear"

                                            Game.None ->
                                                ""
                                        )
                                            |> formatNameString
                                in
                                li
                                    [ class "remove-piece"
                                    , onClickPreventDefault (RemovePiece p)
                                    ]
                                    [ text ("Remove " ++ pieceName)
                                    ]
                                    :: -- Special Rule for Scenario 61
                                       (case ( scenarioNumber, p.ref ) of
                                            ( 61, AI (Enemy _) ) ->
                                                [ li
                                                    [ class "phase-piece"
                                                    , onClickPreventDefault (PhasePiece p)
                                                    ]
                                                    [ text ("Phase Shift " ++ pieceName)
                                                    ]
                                                ]

                                            _ ->
                                                []
                                       )

                            Nothing ->
                                [ li
                                    [ class "summon-piece has-sub-menu"
                                    , onClickPreventDefault (ChangeContextMenuState SummonSubMenu)
                                    ]
                                    [ text "Summon"
                                    , lazy6 getSummonMenuHtml ( x, y ) (state == SummonSubMenu) (bearSummoned == False) nextId summonsColour availableMonsters
                                    ]
                                , li
                                    [ class "spawn-piece has-sub-menu"
                                    , onClickPreventDefault (ChangeContextMenuState SpawnSubMenu)
                                    ]
                                    [ text "Spawn"
                                    , lazy3 getSpawnMenuHtml ( x, y ) (state == SpawnSubMenu) availableMonsters
                                    ]
                                ]
                       )
                    ++ List.map
                        (\o ->
                            li
                                [ class "remove-overlay"
                                , onClickPreventDefault (RemoveOverlay o)
                                ]
                                [ text ("Remove " ++ getOverlayLabel o.ref)
                                ]
                        )
                        filteredOverlays

            else
                []

        isOpen =
            state /= Closed && List.length menuList > 0
    in
    div
        [ class "context-menu"
        , class
            (if isOpen then
                "open"

             else
                ""
            )
        , class
            (if state /= Open then
                "sub-menu-open"

             else
                ""
            )
        , style "top" (String.fromInt absY ++ "px")
        , style "left" (String.fromInt absX ++ "px")
        ]
        [ nav []
            [ ul []
                (if isOpen then
                    menuList
                        ++ [ li
                                [ class "cancel-menu cancel"
                                , onClickPreventDefault (ChangeContextMenuState Closed)
                                ]
                                [ text "Cancel"
                                ]
                           ]

                 else
                    []
                )
            ]
        ]


getRoomCodeHtml : Maybe String -> Bool -> Bool -> Html.Html Msg
getRoomCodeHtml roomCode showRoomCode showTutorial =
    Keyed.node
        "div"
        [ class
            "roomCode"
        ]
        (case roomCode of
            Nothing ->
                []

            Just c ->
                if showRoomCode then
                    [ ( "roomCodeLabel", span [] [ text "Room Code" ] )
                    , ( "roomCodeText", span [] [ text c ] )
                    ]
                        ++ (if showTutorial then
                                [ getTutorialHtml "This is your room code. You can change this in the settings in order to join other people's games. Or you can give this code to your friends so that they can join your game." roomCodeTutorialStep (UpdateTutorialStep menuTutorialStep) ]

                            else
                                []
                           )

                else
                    []
        )


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


getMenuHtml : Bool -> Bool -> Int -> Maybe String -> Maybe String -> Bool -> Html.Html Msg
getMenuHtml lockScenario lockPlayers scenarioId campaignTrackerName campaignTrackerUrl menuOpen =
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
                |> Dom.appendChild
                    (Dom.element "li"
                        |> Dom.addAttribute (attribute "role" "menuitem")
                        |> Dom.addAttribute (tabindex 0)
                        |> Dom.addAction ( "click", Undo )
                        |> Dom.addClass "section-end"
                        |> Dom.appendText "Undo"
                        |> shortcutHtml [ "ctrl", "z" ]
                    )
                |> Dom.appendChildConditional
                    (Dom.element "li"
                        |> Dom.addAttribute (attribute "role" "menuitem")
                        |> Dom.addAttribute (tabindex 0)
                        |> Dom.addAction ( "click", ChangeAppMode ScenarioDialog )
                        |> Dom.appendText "Change Scenario"
                        |> shortcutHtml [ "⇧", "c" ]
                    )
                    (lockScenario == False)
                |> Dom.appendChild
                    (Dom.element "li"
                        |> Dom.addAttribute (attribute "role" "menuitem")
                        |> Dom.addAttribute (tabindex 0)
                        |> Dom.addAction ( "click", ReloadScenario )
                        |> Dom.appendText "Reload Scenario"
                        |> shortcutHtml [ "⇧", "r" ]
                    )
                |> Dom.appendChildConditional
                    (Dom.element "li"
                        |> Dom.addAttribute (attribute "role" "menuitem")
                        |> Dom.addAttribute (tabindex 0)
                        |> Dom.addAction ( "click", ChangeAppMode PlayerChoiceDialog )
                        |> Dom.appendText "Change Players"
                        |> shortcutHtml [ "⇧", "p" ]
                    )
                    (lockPlayers == False)
                |> Dom.appendChild
                    (Dom.element "li"
                        |> Dom.addAttribute (attribute "role" "menuitem")
                        |> Dom.addAttribute (tabindex 0)
                        |> Dom.addAction ( "click", ChangeAppMode ConfigDialog )
                        |> Dom.addClass "section-end"
                        |> Dom.appendText "Settings"
                        |> shortcutHtml [ "⇧", "s" ]
                    )
                |> Dom.appendChildConditional
                    (let
                        ( name, url ) =
                            case ( campaignTrackerName, campaignTrackerUrl ) of
                                ( Just n, Just u ) ->
                                    ( n, u )

                                _ ->
                                    ( "", "" )
                     in
                     Dom.element "li"
                        |> Dom.addAttribute (attribute "role" "menuitem")
                        |> Dom.addAttribute (tabindex 0)
                        |> Dom.appendChild
                            (Dom.element "a"
                                |> Dom.addAttribute (href (String.replace "{scenarioId}" (String.fromInt scenarioId) url))
                                |> Dom.addAttribute (target "_new")
                                |> Dom.appendText name
                            )
                    )
                    (case ( campaignTrackerName, campaignTrackerUrl ) of
                        ( Just _, Just _ ) ->
                            True

                        _ ->
                            False
                    )
                |> Dom.appendChild
                    (Dom.element "li"
                        |> Dom.addAttribute (attribute "role" "menuitem")
                        |> Dom.addAttribute (tabindex 0)
                        |> Dom.addAction ( "click", UpdateTutorialStep boardTutorialStep )
                        |> Dom.addClass "section-end"
                        |> Dom.appendText "Reset Tutorial"
                    )
                |> Dom.appendChild
                    (Dom.element "li"
                        |> Dom.addAttribute (attribute "role" "menuitem")
                        |> Dom.addAttribute (tabindex 0)
                        |> Dom.addClass "section-end"
                        |> Dom.appendChild
                            (Dom.element "a"
                                |> Dom.addAttribute (href "/Creator")
                                |> Dom.addAttribute (target "creator_window")
                                |> Dom.appendText "Scenario Creator"
                            )
                    )
                |> Dom.appendChild
                    (Dom.element "li"
                        |> Dom.addAttribute (attribute "role" "menuitem")
                        |> Dom.addAttribute (tabindex 0)
                        |> Dom.appendChild
                            (Dom.element "a"
                                |> Dom.addAttribute (href "https://github.com/sponsors/PurpleKingdomGames?o=esb")
                                |> Dom.addAttribute (target "_new")
                                |> Dom.appendText "Donate"
                            )
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
            getCurrentScenarioInput model

        scenarioErr =
            case scenarioInput of
                CustomScenario _ ->
                    case model.currentSelectedFile of
                        Just ( _, Just (Ok _) ) ->
                            Nothing

                        Just ( _, Just (Err e) ) ->
                            let
                                errStr =
                                    Decode.errorToString e
                            in
                            Just ("Cannot decode file: '" ++ errStr ++ "'")

                        _ ->
                            Nothing

                _ ->
                    if isValidScenario scenarioInput then
                        Nothing

                    else
                        Just "Invalid scenario number"

        validScenario =
            scenarioErr == Nothing

        expansion =
            case scenarioInput of
                InbuiltScenario e _ ->
                    Just e

                _ ->
                    Nothing

        filename =
            case model.currentSelectedFile of
                Just ( f, _ ) ->
                    f

                Nothing ->
                    ""

        isCustom =
            case scenarioInput of
                CustomScenario _ ->
                    True

                _ ->
                    False

        decodeScenarioType =
            targetValue
                |> Decode.andThen
                    (\s ->
                        case String.split "|" s of
                            [ t, e ] ->
                                case t of
                                    "inbuilt" ->
                                        case e of
                                            "gloomhaven" ->
                                                Decode.succeed (InbuiltScenario Gloomhaven 1)

                                            "solo" ->
                                                Decode.succeed (InbuiltScenario Solo 1)

                                            _ ->
                                                Decode.fail "Incorrect expansion"

                                    _ ->
                                        Decode.fail "Incorrect type"

                            [ t ] ->
                                if t == "custom" then
                                    Decode.succeed (CustomScenario "")

                                else
                                    Decode.fail "Incorrect type"

                            _ ->
                                Decode.fail "String in wrong format"
                    )
                |> Decode.map (\t -> EnterScenarioType t)
    in
    Dom.element "div"
        |> Dom.addClass "scenario-form"
        |> Dom.appendChildList
            [ Dom.element "div"
                |> Dom.addClass "select-wrapper"
                |> Dom.appendChildList
                    [ Dom.element "label"
                        |> Dom.addAttribute (attribute "for" "scenarioTypeInput")
                        |> Dom.appendText "Type"
                    , Dom.element "select"
                        |> Dom.addActionStopPropagation ( "click", NoOp )
                        |> Dom.addAttribute (on "change" decodeScenarioType)
                        |> Dom.addAttribute (attribute "id" "scenarioTypeInput")
                        |> Dom.appendChildList
                            [ Dom.element "option"
                                |> Dom.addAttribute (attribute "value" "inbuilt|gloomhaven")
                                |> Dom.addAttribute (selected (expansion == Just Gloomhaven))
                                |> Dom.appendText "Gloomhaven + FC"
                            , Dom.element "option"
                                |> Dom.addAttribute (attribute "value" "inbuilt|solo")
                                |> Dom.addAttribute (selected (expansion == Just Solo))
                                |> Dom.appendText "Solo"
                            , Dom.element "option"
                                |> Dom.addAttribute (attribute "value" "custom")
                                |> Dom.addAttribute (selected isCustom)
                                |> Dom.appendText "Custom"
                            ]
                    ]
            , getScenarioSelectHtml scenarioInput filename scenarioErr
            , Dom.element "div"
                |> Dom.addClass "button-wrapper"
                |> Dom.appendChildList
                    [ Dom.element "button"
                        |> Dom.appendText "OK"
                        |> Dom.addActionConditional ( "click", ChangeScenario scenarioInput False ) validScenario
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
                                |> Dom.addAttribute (attribute "for" "summonsColour")
                                |> Dom.appendText "Summons Colour"
                                |> Dom.appendChild
                                    (Dom.element "input"
                                        |> Dom.addAttribute (attribute "id" "summonsColour")
                                        |> Dom.addAttribute (attribute "type" "color")
                                        |> Dom.addAttribute (attribute "value" settings.summonsColour)
                                        |> Dom.addInputHandler ChangeSummonsColour
                                    )
                            )
                   , Dom.element "div"
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
                        |> Dom.addClass "input-wrapper"
                        |> Dom.appendChild
                            (Dom.element "label"
                                |> Dom.addClass "checkbox"
                                |> Dom.addClassConditional "checked" settings.envelopeX
                                |> Dom.addAttribute (attribute "for" "toggleEnvelopeX")
                                |> Dom.appendText "Envelope X"
                                |> Dom.appendChild
                                    (Dom.element "input"
                                        |> Dom.addAttribute (attribute "id" "toggleEnvelopeX")
                                        |> Dom.addAttribute (attribute "type" "checkbox")
                                        |> Dom.addAttribute (attribute "value" "1")
                                        |> Dom.addAttribute (checked settings.boardOnly)
                                        |> Dom.addActionStopPropagation ( "click", ToggleEnvelopeX (settings.envelopeX == False) )
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
                |> List.filter
                    (\( _, v ) ->
                        (model.config.envelopeX == True)
                            || (v /= Bladeswarm)
                    )
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


getBoardHtml : Model -> Game -> String -> List ( Int, Int ) -> Int -> Array Cell -> Html.Html Msg
getBoardHtml model game encodedDraggable cellsForDraggable y row =
    Keyed.node
        "div"
        [ class "row" ]
        (toList
            (Array.indexedMap
                (\x cell ->
                    let
                        coords =
                            ( x, y )

                        useDraggable =
                            any (\c -> c == coords) cellsForDraggable

                        cellVisible =
                            any (\r -> any (\a -> a == r) game.state.visibleRooms) cell.rooms
                    in
                    ( "board-cell-" ++ String.fromInt x ++ "-" ++ String.fromInt y
                    , lazy8 getCellHtml
                        model.config.gameMode
                        model.game.state.overlays
                        model.game.state.pieces
                        x
                        y
                        (if useDraggable then
                            encodedDraggable

                         else
                            ""
                        )
                        cell.passable
                        (cellVisible == False)
                    )
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
                                            ot.ref == o.ref && ot.id == o.id

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
                -- Everything except coins and tokens
                |> Dom.setChildListWithKeys
                    ((overlaysForCell
                        |> sortWith
                            (\a b ->
                                compare (BoardHtml.getSortOrderForOverlay a.overlay.ref) (BoardHtml.getSortOrderForOverlay b.overlay.ref)
                            )
                        |> filter
                            (\o ->
                                case o.overlay.ref of
                                    Token _ ->
                                        False

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
                        ++ -- Coins and Tokens
                           (overlaysForCell
                                |> List.filter
                                    (\o ->
                                        case o.overlay.ref of
                                            Token _ ->
                                                True

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

                                        RoomType _ ->
                                            []

                                Nothing ->
                                    []
                           )
                    )
    in
    Dom.element "div"
        |> Dom.addClass "cell-wrapper"
        |> Dom.addClass (cellValueToString passable hidden)
        |> Dom.appendChild
            (Dom.element "div"
                |> Dom.addClass "cell"
                |> Dom.appendChild cellElement
            )
        |> (\e ->
                if passable == True && hidden == False then
                    makeDroppable ( x, y ) e

                else
                    e
           )
        |> Dom.addActionStopAndPrevent ( "click", OpenContextMenu ( x, y ) )
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

                        Summons (NormalSummons i colour) ->
                            Dom.appendChildList
                                [ Dom.element "div"
                                    |> Dom.addAttribute (class "background")
                                    |> Dom.addAttribute (attribute "style" ("background-color: " ++ Colour.toHexString colour ++ ";"))
                                , Dom.element "img"
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
        |> makeDraggable (PieceType model.piece) model.coords
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
        |> Dom.addClassConditional "out-of-phase" monster.outOfPhase
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

                Rift ->
                    "rift"

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

                Highlight _ ->
                    "highlight"

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

                Token _ ->
                    "token"

                Wall _ ->
                    "wall"
            )
        |> Dom.addClassConditional
            (case model.overlay.direction of
                Default ->
                    ""

                Vertical ->
                    "vertical"

                VerticalReverse ->
                    "vertical-reverse"

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
            (model.overlay.direction /= Default)
        |> Dom.addAttributeConditional
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

                                    Locked ->
                                        "???"

                            _ ->
                                ""

                    _ ->
                        ""
                )
            )
            (case model.overlay.ref of
                Treasure _ ->
                    True

                _ ->
                    False
            )
        |> Dom.appendChild
            (case model.overlay.ref of
                Token val ->
                    Dom.element "span"
                        |> Dom.appendText val

                Highlight c ->
                    Dom.element "div"
                        |> Dom.addStyle ( "background-color", Colour.toHexString c )

                _ ->
                    Dom.element "img"
                        |> Dom.addAttribute (alt (getOverlayLabel model.overlay.ref))
                        |> Dom.addAttribute (attribute "src" (getOverlayImageName model.overlay model.coords))
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
        |> (case model.overlay.ref of
                Door _ _ ->
                    Dom.addAttribute (attribute "draggable" "false")

                StartingLocation ->
                    Dom.addAttribute (attribute "draggable" "false")

                Highlight _ ->
                    Dom.addAttribute (attribute "draggable" "false")

                Treasure (Coin _) ->
                    Dom.addAttribute (attribute "draggable" "false")

                _ ->
                    makeDraggable (OverlayType model.overlay Nothing) model.coords
           )
    )


getOverlayImageName : BoardOverlay -> Maybe ( Int, Int ) -> String
getOverlayImageName overlay coords =
    let
        path =
            "/img/overlays/"

        overlayName =
            Maybe.withDefault "" (getBoardOverlayName overlay.ref)

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


getPlacePieceMenuHtml : ( Int, Int ) -> Bool -> Bool -> Bool -> Bool -> Bool -> Bool -> Int -> Html Msg
getPlacePieceMenuHtml ( x, y ) isVisible hasDiviner hasObstacle hasTrap hasDifficultTerrain hasHazard nextOverlayId =
    let
        overlayList =
            (Treasure (Coin 1)
                :: (if hasDiviner then
                        [ Rift ]

                    else
                        []
                   )
                ++ (if hasObstacle == False then
                        [ Obstacle Barrel, Obstacle Boulder1, Obstacle Crate ]

                    else
                        []
                   )
                ++ (if hasTrap == False then
                        [ Trap BearTrap, Trap Poison, Trap Spike ]

                    else
                        []
                   )
                ++ (if hasDifficultTerrain == False then
                        [ DifficultTerrain Water ]

                    else
                        []
                   )
                ++ (if hasHazard == False then
                        [ Hazard HotCoals, Hazard Thorns ]

                    else
                        []
                   )
            )
                |> List.map (\o -> BoardOverlay o nextOverlayId Default [ ( x, y ) ])
                |> List.map (\o -> ( getOverlayLabel o.ref, o ))
                |> List.sortBy (\( label, _ ) -> label)
    in
    Dom.element "div"
        |> Dom.appendChild
            (Dom.element "ul"
                |> Dom.addClassConditional "open" isVisible
                |> Dom.appendChildList
                    (List.map
                        (\( label, o ) ->
                            Dom.element "li"
                                |> Dom.appendText label
                                |> Dom.addActionStopAndPrevent ( "click", AddOverlay o )
                        )
                        overlayList
                    )
                |> Dom.appendChild
                    (Dom.element "li"
                        |> Dom.addClass "cancel-menu cancel"
                        |> Dom.addActionStopAndPrevent ( "click", ChangeContextMenuState Open )
                        |> Dom.appendText "Cancel"
                    )
            )
        |> Dom.render


getPlaceTokenMenuHtml : ( Int, Int ) -> Bool -> Int -> Html Msg
getPlaceTokenMenuHtml ( x, y ) isVisible nextOverlayId =
    let
        values =
            [ "a"
            , "b"
            , "c"
            , "d"
            , "e"
            , "f"
            , "1"
            , "2"
            , "3"
            , "4"
            , "5"
            , "6"
            , "7"
            , "8"
            , "9"
            ]

        tokens =
            values
                |> map (\v -> ( v, BoardOverlay (Token v) nextOverlayId Default [ ( x, y ) ] ))
    in
    Dom.element "div"
        |> Dom.appendChild
            (Dom.element "ul"
                |> Dom.addClassConditional "open" isVisible
                |> Dom.appendChildList
                    (List.map
                        (\( val, token ) ->
                            Dom.element "li"
                                |> Dom.appendText val
                                |> Dom.addActionStopAndPrevent ( "click", AddToken token )
                        )
                        tokens
                    )
                |> Dom.appendChild
                    (Dom.element "li"
                        |> Dom.addClass "cancel-menu cancel"
                        |> Dom.addActionStopAndPrevent ( "click", ChangeContextMenuState Open )
                        |> Dom.appendText "Cancel"
                    )
            )
        |> Dom.render


getPlaceHighlightMenuHtml : ( Int, Int ) -> Bool -> Int -> Html Msg
getPlaceHighlightMenuHtml ( x, y ) isVisible nextOverlayId =
    let
        values =
            [ Colour.red
            , Colour.orange
            , Colour.yellow
            , Colour.green
            , Colour.blue
            , Colour.indigo
            ]
    in
    Dom.element "div"
        |> Dom.appendChild
            (Dom.element "ul"
                |> Dom.addClassConditional "open" isVisible
                |> Dom.appendChildList
                    (List.map
                        (\c ->
                            Dom.element "li"
                                |> Dom.appendText (Colour.toString c)
                                |> Dom.addActionStopAndPrevent ( "click", AddHighlight (BoardOverlay (Highlight c) nextOverlayId Default [ ( x, y ) ]) )
                        )
                        values
                    )
                |> Dom.appendChild
                    (Dom.element "li"
                        |> Dom.addClass "cancel-menu cancel"
                        |> Dom.addActionStopAndPrevent ( "click", ChangeContextMenuState Open )
                        |> Dom.appendText "Cancel"
                    )
            )
        |> Dom.render


getSummonMenuHtml : ( Int, Int ) -> Bool -> Bool -> Int -> String -> Dict String (Array Int) -> Html Msg
getSummonMenuHtml ( x, y ) isOpen canSummonBear nextSummonId summonsColour availableMonsters =
    Dom.element "div"
        |> Dom.appendChild
            (Dom.element "ul"
                |> Dom.addClassConditional "open" isOpen
                |> Dom.appendChildConditional
                    (Dom.element "li"
                        |> Dom.appendText "Bear"
                        |> Dom.addActionStopAndPrevent ( "click", AddPiece (Piece (AI (Summons BearSummons)) x y) )
                    )
                    canSummonBear
                |> Dom.appendChild
                    (Dom.element "li"
                        |> Dom.appendText "Summons"
                        |> Dom.addActionStopAndPrevent ( "click", AddPiece (Piece (AI (Summons (NormalSummons nextSummonId (Colour.fromHexString summonsColour)))) x y) )
                    )
                |> Dom.appendChildList
                    (getAvailableMonsterContextList ( x, y ) availableMonsters True)
                |> Dom.appendChild
                    (Dom.element "li"
                        |> Dom.addClass "cancel-menu cancel"
                        |> Dom.addActionStopAndPrevent ( "click", ChangeContextMenuState Open )
                        |> Dom.appendText "Cancel"
                    )
            )
        |> Dom.render


getSpawnMenuHtml : ( Int, Int ) -> Bool -> Dict String (Array Int) -> Html Msg
getSpawnMenuHtml coords isOpen availableMonsters =
    Dom.element "div"
        |> Dom.appendChild
            (Dom.element "ul"
                |> Dom.addClassConditional "open" isOpen
                |> Dom.appendChildList
                    (getAvailableMonsterContextList coords availableMonsters False)
                |> Dom.appendChild
                    (Dom.element "li"
                        |> Dom.addClass "cancel-menu cancel"
                        |> Dom.addActionStopAndPrevent ( "click", ChangeContextMenuState Open )
                        |> Dom.appendText "Cancel"
                    )
            )
        |> Dom.render


getAvailableMonsterContextList : ( Int, Int ) -> Dict String (Array Int) -> Bool -> List (Element Msg)
getAvailableMonsterContextList coords availableMonsters isSummons =
    Dict.toList availableMonsters
        |> List.filter (\( _, v ) -> length v > 0)
        |> List.map (\( k, _ ) -> k)
        |> List.sort
        |> List.reverse
        |> filterMap
            (\k ->
                stringToMonsterType k
                    |> Maybe.map (\monsterType -> ( formatNameString k, monsterType ))
            )
        |> List.map
            (\( monsterName, monsterType ) ->
                getMonsterLiForType coords monsterName monsterType Normal isSummons
                    :: (case monsterType of
                            NormalType _ ->
                                [ getMonsterLiForType coords ("Elite " ++ monsterName) monsterType Elite isSummons
                                ]

                            BossType _ ->
                                []
                       )
            )
        |> List.foldl (++) []


getMonsterLiForType : ( Int, Int ) -> String -> MonsterType -> MonsterLevel -> Bool -> Element Msg
getMonsterLiForType ( x, y ) name monsterType monsterLevel isSummons =
    let
        piece =
            Piece (AI (Enemy (Monster monsterType 0 monsterLevel isSummons False))) x y
    in
    Dom.element "li"
        |> Dom.appendText name
        |> Dom.addActionStopAndPrevent ( "click", AddPiece piece )


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
                model.config.summonsColour
                model.config.showRoomCode
                model.config.boardOnly
                model.fullscreen
                model.config.envelopeX


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


isValidScenario : GameStateScenario -> Bool
isValidScenario scenario =
    case scenario of
        InbuiltScenario e i ->
            let
                ( min, max ) =
                    getValidScenarioRange e
            in
            i >= min && i <= max

        _ ->
            False


getValidScenarioRange : Expansion -> ( Int, Int )
getValidScenarioRange expansion =
    case expansion of
        Gloomhaven ->
            ( 1, 115 )

        Solo ->
            getSoloScenarios
                |> Dict.values
                |> List.map (\v -> Tuple.first v)
                |> List.foldl (\val minMax -> ( min val (Tuple.first minMax), max val (Tuple.second minMax) )) ( 10000, 0 )


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


getLabelForOverlay : BoardOverlay -> Maybe ( Int, Int ) -> String
getLabelForOverlay overlay coords =
    case coords of
        Just _ ->
            getOverlayLabel overlay.ref ++ " " ++ String.fromInt overlay.id

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

                Summons (NormalSummons i _) ->
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


getCurrentScenarioInput : Model -> GameStateScenario
getCurrentScenarioInput model =
    case model.currentScenarioType of
        Just (InbuiltScenario e _) ->
            case model.currentScenarioInput of
                Just str ->
                    case String.toInt str of
                        Just i ->
                            InbuiltScenario e i

                        Nothing ->
                            case model.game.state.scenario of
                                InbuiltScenario _ i1 ->
                                    InbuiltScenario e i1

                                _ ->
                                    InbuiltScenario e 1

                Nothing ->
                    case model.game.state.scenario of
                        InbuiltScenario _ i ->
                            InbuiltScenario e i

                        _ ->
                            InbuiltScenario e 1

        Just (CustomScenario f) ->
            CustomScenario f

        Nothing ->
            case model.game.state.scenario of
                InbuiltScenario e _ ->
                    case model.currentScenarioInput of
                        Just str ->
                            case String.toInt str of
                                Just i ->
                                    InbuiltScenario e i

                                Nothing ->
                                    model.game.state.scenario

                        Nothing ->
                            model.game.state.scenario

                _ ->
                    model.game.state.scenario


getScenarioSelectHtml : GameStateScenario -> String -> Maybe String -> Element Msg
getScenarioSelectHtml scenario filename errStr =
    let
        wrapperClass =
            case scenario of
                InbuiltScenario Solo _ ->
                    "select-wrapper"

                _ ->
                    "input-wrapper"

        scenarioSelectInput =
            case scenario of
                InbuiltScenario e i ->
                    let
                        ( min, max ) =
                            getValidScenarioRange e
                    in
                    case e of
                        Gloomhaven ->
                            Dom.element "input"
                                |> Dom.addActionStopPropagation ( "click", NoOp )
                                |> Dom.addAttribute (attribute "id" "scenarioIdInput")
                                |> Dom.addAttribute (attribute "type" "number")
                                |> Dom.addAttribute (attribute "min" (String.fromInt min))
                                |> Dom.addAttribute (attribute "max" (String.fromInt max))
                                |> Dom.addAttribute (attribute "value" (String.fromInt i))
                                |> Dom.addInputHandler EnterScenarioNumber

                        Solo ->
                            Dom.element "select"
                                |> Dom.addActionStopPropagation ( "click", NoOp )
                                |> Dom.addChangeHandler EnterScenarioNumber
                                |> Dom.addAttribute (attribute "id" "scenarioTypeInput")
                                |> Dom.appendChildList
                                    (getSoloScenarios
                                        |> Dict.map
                                            (\k ( id, txt ) ->
                                                ( id
                                                , Dom.element "option"
                                                    |> Dom.addAttribute (attribute "value" (String.fromInt id))
                                                    |> Dom.addAttribute (selected (i == id))
                                                    |> Dom.appendChild (getCharacterClassIconHtml k)
                                                    |> Dom.appendChild
                                                        (Dom.element "span"
                                                            |> Dom.appendText (" - " ++ txt)
                                                        )
                                                )
                                            )
                                        |> Dict.values
                                        |> List.sortBy (\( k, _ ) -> k)
                                        |> List.map (\( _, v ) -> v)
                                    )

                CustomScenario _ ->
                    Dom.element "div"
                        |> Dom.addClass "button-wrapper"
                        |> Dom.addClass "file-choose"
                        |> Dom.addActionStopPropagation ( "click", ChooseScenarioFile )
                        |> Dom.appendChild
                            (Dom.element "button"
                                |> Dom.addAttribute (attribute "id" "scenarioIdInput")
                                |> Dom.appendText "Choose file"
                            )
                        |> Dom.appendChild
                            (Dom.element "span"
                                |> Dom.appendText filename
                            )
    in
    Dom.element "div"
        |> Dom.addClass wrapperClass
        |> Dom.addClassConditional "error" (errStr /= Nothing)
        |> Dom.appendChildList
            ([ Dom.element "label"
                |> Dom.addAttribute (attribute "for" "scenarioIdInput")
                |> Dom.appendText "Scenario"
             , scenarioSelectInput
             ]
                ++ (case errStr of
                        Nothing ->
                            []

                        Just e ->
                            [ Dom.element "div"
                                |> Dom.addClass "error-label"
                                |> Dom.appendText e
                            ]
                   )
            )


getCharacterClassIconHtml : String -> Element Msg
getCharacterClassIconHtml characterClassStr =
    Dom.element "i"
        |> Dom.addClass "icon"
        |> Dom.addClass characterClassStr
        |> Dom.appendText
            (characterClassStr
                |> String.toList
                |> List.foldl
                    (\c lst ->
                        let
                            newC =
                                if c == '-' then
                                    ' '

                                else
                                    case List.Extra.last lst of
                                        Just ' ' ->
                                            Char.toLocaleUpper c

                                        Nothing ->
                                            Char.toLocaleUpper c

                                        _ ->
                                            c
                        in
                        List.append lst [ newC ]
                    )
                    []
                |> String.fromList
            )


makeDraggable : MoveablePieceType -> Maybe ( Int, Int ) -> Element Msg -> Element Msg
makeDraggable piece coords element =
    let
        config =
            DragDrop.DraggedSourceConfig
                (DragDrop.EffectAllowed True False False)
                (\e v -> MoveStarted (MoveablePiece piece coords Nothing) (Just ( e, v )))
                (always MoveCanceled)
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
                DragDrop.MoveOnDrop
                (\e v -> MoveTargetChanged coords (Just ( e, v )))
                (always MoveCompleted)
                Nothing
                Nothing
    in
    element
        |> Dom.addAttributeList (DragDrop.onDropTarget config)


loadScenario : Model -> String -> Seed -> GameStateScenario -> Maybe Game.GameState -> Bool -> Scenario -> ( Model, Cmd Msg )
loadScenario model roomCode seed gameStateScenario initGameState addToUndo scenario =
    let
        game =
            generateGameMap gameStateScenario scenario roomCode model.game.state.players seed
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
            (case initGameState of
                Just gs ->
                    if gs.scenario == gameStateScenario then
                        gs

                    else
                        game.state

                Nothing ->
                    game.state
            )
                |> ensureOverlayIds

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
    ( newModel
    , Cmd.batch
        [ pushGameState model newModel.game.state addToUndo
        , scrollToFirtVisibleCell ()
        ]
    )
