module Main exposing (main)

import AppStorage exposing (AppModeType(..), Config, GameModeType(..), loadFromStorage, saveToStorage)
import Array exposing (Array, fromList, length, toIndexedList, toList)
import Bitwise
import BoardMapTile exposing (MapTileRef(..), refToString)
import BoardOverlay exposing (BoardOverlay, BoardOverlayDirectionType(..), BoardOverlayType(..), ChestType(..), CorridorMaterial(..), DifficultTerrainSubType(..), DoorSubType(..), ObstacleSubType(..), TrapSubType(..), TreasureSubType(..), getBoardOverlayName)
import Browser
import Character exposing (CharacterClass(..), characterToString)
import Dict
import Dom exposing (Element)
import Dom.DragDrop as DragDrop
import Game exposing (AIType(..), Cell, Game, GameState, Piece, PieceType(..), RoomData, assignIdentifier, assignPlayers, generateGameMap, getPieceName, getPieceType, moveOverlay, movePiece, removePieceFromBoard, revealRooms)
import GameSync exposing (Msg(..), connectToServer, update)
import Html exposing (a, div, footer, header, iframe, img, span, text)
import Html.Attributes exposing (attribute, checked, class, href, maxlength, minlength, required, src, style, title, value)
import Html.Events exposing (onClick)
import Http exposing (Error)
import Json.Decode as Decode
import List exposing (any, filter, filterMap, head, map, reverse, sort)
import List.Extra exposing (uniqueBy)
import Monster exposing (BossType(..), Monster, MonsterLevel(..), MonsterType(..), NormalMonsterType(..), monsterTypeToString, stringToMonsterType)
import Process
import Random exposing (Seed)
import Scenario exposing (DoorData(..), Scenario)
import ScenarioSync exposing (loadScenarioById)
import String exposing (join, split)
import Task


type alias Model =
    { game : Game
    , config : Config
    , currentLoadState : LoadingState
    , currentScenarioInput : Maybe Int
    , currentClientSettings : Maybe ( String, Bool )
    , currentPlayerList : Maybe (List CharacterClass)
    , dragDropState : DragDrop.State MoveablePiece ( Int, Int )
    , currentDraggable : Maybe MoveablePiece
    , connectionStatus : ConnectionStatus
    , menuOpen : Bool
    }


type MoveablePieceType
    = OverlayType BoardOverlay (Maybe ( Int, Int ))
    | PieceType Piece


type LoadingState
    = Loaded
    | Loading Int
    | Failed


type ConnectionStatus
    = Connected
    | Disconnected
    | Reconnecting


type alias MoveablePiece =
    { ref : MoveablePieceType
    , coords : Maybe ( Int, Int )
    }


type Msg
    = LoadedScenario Seed (Maybe Game.GameState) (Result Error Scenario)
    | ReloadScenario
    | MoveStarted MoveablePiece
    | MoveTargetChanged ( Int, Int )
    | MoveCanceled
    | MoveCompleted MoveablePiece ( Int, Int )
    | GameStateUpdated Game.GameState
    | RemoveOverlay BoardOverlay
    | RemovePiece Piece
    | ChangeGameMode GameModeType
    | ChangeAppMode AppModeType
    | RevealRoomMsg (List MapTileRef) ( Int, Int )
    | ChangeScenario Int Bool
    | ToggleCharacter CharacterClass Bool
    | ChangePlayerList
    | EnterScenarioNumber String
    | ChangeRoomCodeInputStart String
    | ChangeRoomCodeInputEnd String
    | ChangeShowRoomCode Bool
    | ChangeClientSettings (Maybe ( String, Bool ))
    | GameSyncMsg GameSync.Msg
    | PushGameState
    | NoOp
    | ToggleMenu


version : String
version =
    "1.0.0"


main : Program ( Maybe Decode.Value, Int ) Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : ( Maybe Decode.Value, Int ) -> ( Model, Cmd Msg )
init ( oldState, seed ) =
    let
        ( gs, initConfig ) =
            case oldState of
                Just s ->
                    case loadFromStorage s of
                        Ok val ->
                            val

                        Err _ ->
                            AppStorage.empty

                Nothing ->
                    AppStorage.empty

        initGameState =
            { gs | updateCount = 0 }

        initGame =
            Game.empty
    in
    ( Model { initGame | state = initGameState } initConfig (Loading initGameState.scenario) Nothing Nothing Nothing DragDrop.initialState Nothing Disconnected False
    , Cmd.batch
        [ connectToServer
        , loadScenarioById initGameState.scenario (LoadedScenario (Random.initialSeed seed) (Just initGameState))
        ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        roomCode =
            Maybe.withDefault "" model.config.roomCode
    in
    case msg of
        LoadedScenario seed initGameState result ->
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
                                        let
                                            state =
                                                game.state
                                        in
                                        { state | roomCode = gs.roomCode, updateCount = gs.updateCount }

                                Nothing ->
                                    game.state

                        newModel =
                            { model | game = { game | state = gameState }, currentLoadState = Loaded }
                    in
                    ( newModel, pushGameState newModel newModel.game.state )

                Err _ ->
                    ( { model | currentLoadState = Failed }, Cmd.none )

        ReloadScenario ->
            update (ChangeScenario model.game.state.scenario True) model

        MoveStarted piece ->
            ( { model | dragDropState = DragDrop.startDragging model.dragDropState piece, currentDraggable = Just piece }, Cmd.none )

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
                                    in
                                    Just (MoveablePiece (OverlayType newOverlay newCoords) m.coords)

                                PieceType p ->
                                    let
                                        newPiece =
                                            Tuple.second (movePiece p m.coords coords model.game)
                                    in
                                    Just (MoveablePiece (PieceType newPiece) m.coords)

                        Nothing ->
                            model.currentDraggable
            in
            ( { model | dragDropState = DragDrop.updateDropTarget model.dragDropState coords, currentDraggable = newDraggable }, Cmd.none )

        MoveCanceled ->
            ( { model | dragDropState = DragDrop.stopDragging model.dragDropState, currentDraggable = Nothing }, Cmd.none )

        MoveCompleted _ coords ->
            let
                oldGame =
                    model.game

                game =
                    case model.currentDraggable of
                        Just m ->
                            case m.ref of
                                OverlayType o prevCoords ->
                                    let
                                        ( g, _, _ ) =
                                            moveOverlay o m.coords prevCoords coords oldGame
                                    in
                                    g

                                PieceType p ->
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

                        Nothing ->
                            oldGame
            in
            ( { model | dragDropState = DragDrop.stopDragging model.dragDropState, game = game, currentDraggable = Nothing }, pushGameState model game.state )

        RemoveOverlay overlay ->
            let
                game =
                    model.game

                gameState =
                    game.state

                newState =
                    { gameState | overlays = List.filter (\o -> o.cells /= overlay.cells || o.ref /= overlay.ref) gameState.overlays }
            in
            ( { model | game = { game | state = newState } }, pushGameState model newState )

        RemovePiece piece ->
            let
                newGame =
                    removePieceFromBoard piece model.game
            in
            ( { model | game = newGame }, pushGameState model newGame.state )

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
            ( { model | game = newGame }, pushGameState model newGame.state )

        ChangeAppMode mode ->
            let
                config =
                    model.config

                newModel =
                    { model | config = { config | appMode = mode } }
            in
            ( newModel, saveToStorage newModel.game.state newModel.config )

        ChangeScenario newScenario forceReload ->
            let
                config =
                    model.config
            in
            if forceReload || newScenario /= model.game.state.scenario then
                ( { model | config = { config | appMode = AppStorage.Game }, currentLoadState = Loading newScenario, currentDraggable = Nothing, currentScenarioInput = Nothing }, loadScenarioById newScenario (LoadedScenario model.game.seed Nothing) )

            else
                ( { model | config = { config | appMode = AppStorage.Game } }, Cmd.none )

        EnterScenarioNumber strId ->
            case String.toInt strId of
                Just scenarioId ->
                    if scenarioId > 0 && scenarioId < 94 then
                        ( { model | currentScenarioInput = Just scenarioId }, Cmd.none )

                    else
                        ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        ChangeRoomCodeInputStart startCode ->
            let
                ( ( _, roomCode2 ), showRoomCode ) =
                    getSplitRoomCodeSettings model
            in
            ( { model | currentClientSettings = Just ( startCode ++ "-" ++ roomCode2, showRoomCode ) }, Cmd.none )

        ChangeRoomCodeInputEnd endCode ->
            let
                ( ( roomCode1, _ ), showRoomCode ) =
                    getSplitRoomCodeSettings model
            in
            ( { model | currentClientSettings = Just ( roomCode1 ++ "-" ++ endCode, showRoomCode ) }, Cmd.none )

        ChangeShowRoomCode showRoomCode ->
            let
                ( ( roomCode1, roomCode2 ), _ ) =
                    getSplitRoomCodeSettings model
            in
            ( { model | currentClientSettings = Just ( roomCode1 ++ "-" ++ roomCode2, showRoomCode ) }, Cmd.none )

        ChangeClientSettings maybeSettings ->
            case maybeSettings of
                Just ( newRoomCode, showRoomCode ) ->
                    let
                        config =
                            model.config
                    in
                    update (GameSyncMsg (JoinRoom newRoomCode)) { model | config = { config | showRoomCode = showRoomCode, appMode = AppStorage.Game } }

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

                updatedConfigModel =
                    { model | config = config, connectionStatus = connectedState }

                gameState =
                    model.game.state

                ( updateMsg, cmdMsg ) =
                    GameSync.update
                        gameSyncMsg
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
            in
            if game.state.scenario == gameState.scenario then
                ( { model | game = { game | state = gameState } }, saveToStorage gameState model.config )

            else
                ( { model | currentLoadState = Loading gameState.scenario }
                , loadScenarioById gameState.scenario (LoadedScenario game.seed (Just gameState))
                )

        PushGameState ->
            case model.currentLoadState of
                Loaded ->
                    ( model, pushGameState model model.game.state )

                _ ->
                    ( model, Cmd.none )

        ToggleMenu ->
            ( { model | menuOpen = model.menuOpen == False }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


view : Model -> Html.Html Msg
view model =
    let
        config =
            model.config
    in
    div [ class "content" ]
        (let
            game =
                model.game
         in
         [ div [ class "header" ]
            [ div
                [ class
                    ("menu"
                        ++ (if model.menuOpen then
                                " show"

                            else
                                ""
                           )
                    )
                , onClick ToggleMenu
                ]
                [ getMenuHtml ]
            , header []
                (if game.scenario.id /= 0 then
                    [ span [ class "number" ] [ text (String.fromInt game.scenario.id) ]
                    , span [ class "title" ] [ text game.scenario.title ]
                    ]

                 else
                    []
                )
            , div
                [ class
                    "roomCode"
                ]
                (case model.config.roomCode of
                    Nothing ->
                        []

                    Just c ->
                        if model.config.showRoomCode then
                            [ span [] [ text "Room Code" ]
                            , span [] [ text c ]
                            ]

                        else
                            []
                )
            ]
         , div [ class "main" ]
            [ div [ class "action-list" ] [ getNavHtml model, getNewPieceHtml model game ]
            , div [ class "board-wrapper" ]
                [ div [ class "mapTiles" ] (map (getMapTileHtml game.state.visibleRooms) (uniqueBy (\d -> Maybe.withDefault "" (refToString d.ref)) game.roomData))
                , div [ class "board" ] (toList (Array.indexedMap (getBoardHtml model game) game.staticBoard))
                ]
            ]
         , footer []
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
                [ span [ class "pkgCopy" ]
                    [ text "Developed by "
                    , a [ href "https://purplekingdomgames.com/" ] [ text "Purple Kingdom Games" ]
                    ]
                , div
                    [ class "sponsor" ]
                    [ iframe [ class "sponsor-button", src "https://github.com/sponsors/PurpleKingdomGames/button", title "Sponsor PurpleKingdomGames" ] []
                    ]
                , div [ class "version" ] [ text ("Version " ++ version) ]
                ]
            ]
         ]
            ++ (case config.appMode of
                    AppStorage.Game ->
                        []

                    _ ->
                        [ getDialogForAppMode model ]
               )
        )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Sub.map (\s -> GameSyncMsg s) GameSync.subscriptions
        ]


getNewPieceHtml : Model -> Game -> Html.Html Msg
getNewPieceHtml model game =
    Dom.element "div"
        |> Dom.addClassConditional "show" (model.config.gameMode == AddPiece)
        |> Dom.addClass "new-piece-wrapper"
        |> Dom.appendChild
            (Dom.element "div"
                |> Dom.addClass "new-piece-list"
                |> Dom.appendChild
                    (Dom.element "ul"
                        |> Dom.appendChild
                            (Dom.element "li"
                                |> Dom.appendChild
                                    (let
                                        maxSummons =
                                            filterMap
                                                (\p ->
                                                    case p.ref of
                                                        AI (Summons i) ->
                                                            Just i

                                                        _ ->
                                                            Nothing
                                                )
                                                game.state.pieces
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
                                     pieceToHtml model Nothing (Piece (AI (Summons nextId)) 0 0)
                                    )
                            )
                        |> Dom.appendChild
                            (Dom.element "li"
                                |> Dom.appendChild
                                    (overlayToHtml model Nothing (BoardOverlay (Trap BearTrap) Default [ ( 0, 0 ) ]))
                            )
                        |> Dom.appendChild
                            (Dom.element "li"
                                |> Dom.appendChild
                                    (overlayToHtml model Nothing (BoardOverlay (Obstacle Boulder1) Default [ ( 0, 0 ) ]))
                            )
                        |> Dom.appendChildList
                            (let
                                playerPieces =
                                    game.state.pieces
                                        |> List.filterMap
                                            (\p ->
                                                case p.ref of
                                                    Player c ->
                                                        Just c

                                                    _ ->
                                                        Nothing
                                            )
                             in
                             game.state.players
                                |> List.filter (\p -> List.member p playerPieces == False)
                                |> List.map
                                    (\p ->
                                        Dom.element "li"
                                            |> Dom.appendChild (pieceToHtml model Nothing (Piece (Player p) 0 0))
                                    )
                            )
                        |> Dom.appendChildList
                            (Dict.toList game.state.availableMonsters
                                |> List.filter (\( _, v ) -> length v > 0)
                                |> List.map (\( k, _ ) -> k)
                                |> List.sort
                                |> List.reverse
                                |> filterMap (\k -> stringToMonsterType k)
                                |> List.map
                                    (\k ->
                                        (Dom.element "li"
                                            |> Dom.appendChild (pieceToHtml model Nothing (Piece (AI (Enemy (Monster k 0 Normal True))) 0 0))
                                        )
                                            :: (case k of
                                                    NormalType _ ->
                                                        [ Dom.element "li"
                                                            |> Dom.appendChild (pieceToHtml model Nothing (Piece (AI (Enemy (Monster k 0 Elite True))) 0 0))
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


getMenuHtml : Html.Html Msg
getMenuHtml =
    Dom.element "nav"
        |> Dom.appendChild
            (Dom.element "ul"
                |> Dom.appendChildList
                    [ Dom.element "li"
                        |> Dom.addAction ( "click", ChangeAppMode ScenarioDialog )
                        |> Dom.appendText "Change Scenario"
                    , Dom.element "li"
                        |> Dom.addAction ( "click", ReloadScenario )
                        |> Dom.appendText "Reload Scenario"
                    , Dom.element "li"
                        |> Dom.addAction ( "click", ChangeAppMode PlayerChoiceDialog )
                        |> Dom.appendText "Change Players"
                    , Dom.element "li"
                        |> Dom.addAction ( "click", ChangeAppMode ServerConfigDialog )
                        |> Dom.appendText "Connection Settings"
                    ]
            )
        |> Dom.render


getDialogForAppMode : Model -> Html.Html Msg
getDialogForAppMode model =
    Dom.element "div"
        |> Dom.addClass "overlay-dialog"
        |> Dom.appendChild
            (Dom.element "div"
                |> Dom.addClass "dialog"
                |> (case model.config.appMode of
                        ScenarioDialog ->
                            Dom.appendChild (getScenarioDialog model)

                        ServerConfigDialog ->
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
            Maybe.withDefault model.game.state.scenario model.currentScenarioInput
    in
    Dom.element "div"
        |> Dom.addClass "scenario-form"
        |> Dom.appendChildList
            [ Dom.element "div"
                |> Dom.addClass "input-wrapper"
                |> Dom.appendChildList
                    [ Dom.element "label"
                        |> Dom.addAttribute (attribute "for" "scenarioIdInput")
                        |> Dom.appendText "Scenario"
                    , Dom.element "input"
                        |> Dom.addAttribute (attribute "id" "scenarioIdInput")
                        |> Dom.addAttribute (attribute "type" "number")
                        |> Dom.addAttribute (attribute "min" "1")
                        |> Dom.addAttribute (attribute "max" "93")
                        |> Dom.addAttribute (attribute "value" (String.fromInt scenarioInput))
                        |> Dom.addChangeHandler EnterScenarioNumber
                    ]
            , Dom.element "div"
                |> Dom.addClass "button-wrapper"
                |> Dom.appendChildList
                    [ Dom.element "button"
                        |> Dom.appendText "OK"
                        |> Dom.addAction ( "click", ChangeScenario scenarioInput False )
                    , Dom.element "button"
                        |> Dom.appendText "Cancel"
                        |> Dom.addAction ( "click", ChangeAppMode AppStorage.Game )
                    ]
            ]


getClientSettingsDialog : Model -> Element Msg
getClientSettingsDialog model =
    let
        ( ( roomCode1, roomCode2 ), showRoomCode ) =
            getSplitRoomCodeSettings model
    in
    Dom.element "div"
        |> Dom.addClass "client-form"
        |> Dom.appendChildList
            [ Dom.element "div"
                |> Dom.addClass "input-wrapper"
                |> Dom.appendChildList
                    [ Dom.element "label"
                        |> Dom.addAttribute (attribute "for" "roomCodeInput1")
                        |> Dom.appendText "Room Code"
                    , Dom.element "div"
                        |> Dom.addClass "split-input"
                        |> Dom.appendChildList
                            [ Dom.element "input"
                                |> Dom.addAttribute (attribute "id" "roomCodeInput1")
                                |> Dom.addChangeHandler ChangeRoomCodeInputStart
                                |> Dom.addAttribute (minlength 5)
                                |> Dom.addAttribute (maxlength 5)
                                |> Dom.addAttribute (required True)
                                |> Dom.addAttribute (value roomCode1)
                            , Dom.element "span"
                                |> Dom.appendText "-"
                            , Dom.element "input"
                                |> Dom.addAttribute (attribute "id" "roomCodeInput2")
                                |> Dom.addChangeHandler ChangeRoomCodeInputEnd
                                |> Dom.addAttribute (minlength 5)
                                |> Dom.addAttribute (maxlength 5)
                                |> Dom.addAttribute (required True)
                                |> Dom.addAttribute (value roomCode2)
                            ]
                    ]
            , Dom.element "div"
                |> Dom.addClass "input-wrapper"
                |> Dom.appendChild
                    (Dom.element "label"
                        |> Dom.addClass "checkbox"
                        |> Dom.addClassConditional "checked" showRoomCode
                        |> Dom.addAttribute (attribute "for" "showRoomCode")
                        |> Dom.appendText "Show Room Code"
                        |> Dom.appendChild
                            (Dom.element "input"
                                |> Dom.addAttribute (attribute "id" "showRoomCode")
                                |> Dom.addAttribute (attribute "type" "checkbox")
                                |> Dom.addAttribute (attribute "value" "1")
                                |> Dom.addAttribute (checked showRoomCode)
                                |> Dom.addActionStopPropagation ( "click", ChangeShowRoomCode (showRoomCode == False) )
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
                        |> Dom.addAction ( "click", ChangePlayerList )
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


getNavHtml : Model -> Html.Html Msg
getNavHtml model =
    Dom.element "div"
        |> Dom.addClass "sidebar-wrapper"
        |> Dom.appendChild
            (Dom.element "nav"
                |> Dom.appendChild
                    (Dom.element "ul"
                        |> Dom.appendChildList
                            [ Dom.element "li"
                                |> Dom.addAction ( "click", ChangeGameMode MovePiece )
                                |> Dom.addClass "move-piece"
                                |> Dom.addAttribute (title "Move Monsters or Players")
                                |> Dom.addClassConditional "active" (model.config.gameMode == MovePiece)
                                |> Dom.appendText "Move Piece"
                            , Dom.element "li"
                                |> Dom.addAction ( "click", ChangeGameMode KillPiece )
                                |> Dom.addAttribute (title "Remove Monsters or Players")
                                |> Dom.addClass "kill-piece"
                                |> Dom.addClassConditional "active" (model.config.gameMode == KillPiece)
                                |> Dom.appendText "Kill Piece"
                            , Dom.element "li"
                                |> Dom.addAction ( "click", ChangeGameMode LootCell )
                                |> Dom.addAttribute (title "Loot a tile")
                                |> Dom.addClass "loot"
                                |> Dom.addClassConditional "active" (model.config.gameMode == LootCell)
                                |> Dom.appendText "Loot"
                            , Dom.element "li"
                                |> Dom.addAction ( "click", ChangeGameMode MoveOverlay )
                                |> Dom.addAttribute (title "Move Obstacles or Traps")
                                |> Dom.addClass "move-overlay"
                                |> Dom.addClassConditional "active" (model.config.gameMode == MoveOverlay)
                                |> Dom.appendText "Move Overlay"
                            , Dom.element "li"
                                |> Dom.addAction ( "click", ChangeGameMode DestroyOverlay )
                                |> Dom.addAttribute (title "Remove Obstacles or Traps")
                                |> Dom.addClass "destroy-overlay"
                                |> Dom.addClassConditional "active" (model.config.gameMode == DestroyOverlay)
                                |> Dom.appendText "Destroy Overlay"
                            , Dom.element "li"
                                |> Dom.addAction ( "click", ChangeGameMode RevealRoom )
                                |> Dom.addAttribute (title "Open a door")
                                |> Dom.addClass "reveal-room"
                                |> Dom.addClassConditional "active" (model.config.gameMode == RevealRoom)
                                |> Dom.appendText "Reveal Room"
                            , Dom.element "li"
                                |> Dom.addAction ( "click", ChangeGameMode AddPiece )
                                |> Dom.addAttribute (title "Add a piece to the board")
                                |> Dom.addClass "add-piece"
                                |> Dom.addClassConditional "active" (model.config.gameMode == AddPiece)
                                |> Dom.appendText "Add Piece"
                            ]
                    )
            )
        |> Dom.render


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
                        ]
                        []
                    ]
            )
        ]


getBoardHtml : Model -> Game -> Int -> Array Cell -> Html.Html Msg
getBoardHtml model game y row =
    div [ class "row" ] (toList (Array.indexedMap (getCellHtml model game y) row))


getCellHtml : Model -> Game -> Int -> Int -> Cell -> Html.Html Msg
getCellHtml model game y x cellValue =
    let
        dragDropMessages : DragDrop.Messages Msg MoveablePiece ( Int, Int )
        dragDropMessages =
            { dragStarted = MoveStarted
            , dropTargetChanged = MoveTargetChanged
            , dragEnded = MoveCanceled
            , dropped = MoveCompleted
            }

        overlaysForCell =
            List.filter (filterOverlaysForCoord x y) game.state.overlays

        cellElement : Dom.Element Msg
        cellElement =
            Dom.element "div"
                |> Dom.addClass "hexagon"
                -- Doors
                |> Dom.appendChildList
                    (overlaysForCell
                        |> List.filter
                            (\o ->
                                case o.ref of
                                    Door _ _ ->
                                        True

                                    _ ->
                                        False
                            )
                        |> List.map (overlayToHtml model (Just ( x, y )))
                    )
                -- Treasure chests, obstacles, traps etc.
                |> Dom.appendChildList
                    (overlaysForCell
                        |> List.filter
                            (\o ->
                                case o.ref of
                                    Treasure t ->
                                        case t of
                                            Chest _ ->
                                                True

                                            _ ->
                                                False

                                    Door _ _ ->
                                        False

                                    StartingLocation ->
                                        False

                                    _ ->
                                        True
                            )
                        |> List.map (overlayToHtml model (Just ( x, y )))
                    )
                -- Starting locations
                |> Dom.appendChildList
                    (overlaysForCell
                        |> List.filter
                            (\o ->
                                case o.ref of
                                    StartingLocation ->
                                        True

                                    _ ->
                                        False
                            )
                        |> List.map (overlayToHtml model (Just ( x, y )))
                    )
                -- Players / Monsters / Summons
                |> Dom.appendChildList
                    (case getPieceForCoord x y game.state.pieces of
                        Nothing ->
                            []

                        Just p ->
                            [ pieceToHtml model (Just ( x, y )) p ]
                    )
                -- Coins
                |> Dom.appendChildList
                    (overlaysForCell
                        |> List.filter
                            (\o ->
                                case o.ref of
                                    Treasure t ->
                                        case t of
                                            Chest _ ->
                                                False

                                            _ ->
                                                True

                                    _ ->
                                        False
                            )
                        |> List.map (overlayToHtml model (Just ( x, y )))
                    )
                -- The current draggable piece
                |> (case model.currentDraggable of
                        Just m ->
                            case m.ref of
                                PieceType p ->
                                    if p.x == x && p.y == y then
                                        Dom.appendChild (pieceToHtml model (Just ( x, y )) p)

                                    else
                                        \e -> e

                                OverlayType o _ ->
                                    if any (\c -> c == ( x, y )) o.cells then
                                        Dom.appendChild (overlayToHtml model (Just ( x, y )) o)

                                    else
                                        \e -> e

                        Nothing ->
                            \e -> e
                   )
                |> addActionsForCell model.config.gameMode ( x, y ) overlaysForCell
    in
    Dom.element "div"
        |> Dom.addClass "cell-wrapper"
        |> Dom.addClass (cellValueToString game cellValue)
        |> Dom.appendChild
            (Dom.element "div"
                |> Dom.addClass "cell"
                |> Dom.appendChild
                    (if cellValue.passable == True then
                        DragDrop.makeDroppable model.dragDropState ( x, y ) dragDropMessages cellElement

                     else
                        cellElement
                    )
            )
        |> Dom.render


cellValueToString : Game -> Cell -> String
cellValueToString game val =
    if any (\r -> any (\x -> x == r) game.state.visibleRooms) val.rooms then
        if val.passable == True then
            "passable"

        else
            "impassable"

    else
        "hidden"


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


pieceToHtml : Model -> Maybe ( Int, Int ) -> Piece -> Element Msg
pieceToHtml model coords piece =
    let
        dragDropMessages : DragDrop.Messages Msg MoveablePiece ( Int, Int )
        dragDropMessages =
            { dragStarted = MoveStarted
            , dropTargetChanged = MoveTargetChanged
            , dragEnded = MoveCanceled
            , dropped = MoveCompleted
            }
    in
    Dom.element "div"
        |> Dom.addClass (getPieceType piece.ref)
        |> Dom.addClass (getPieceName piece.ref)
        |> (case piece.ref of
                Player p ->
                    let
                        player =
                            Maybe.withDefault "" (characterToString p)
                    in
                    Dom.appendChild
                        (Dom.element "img"
                            |> Dom.addAttribute (attribute "src" ("/img/characters/portraits/" ++ player ++ ".png"))
                            |> Dom.addAttribute (attribute "draggable" "false")
                        )

                AI t ->
                    case t of
                        Enemy m ->
                            enemyToHtml m

                        Summons i ->
                            Dom.appendChildList
                                [ Dom.element "img"
                                    |> Dom.addAttribute (attribute "src" "/img/characters/summons.png")
                                    |> Dom.addAttribute (attribute "draggable" "false")
                                , Dom.element "span" |> Dom.appendText (String.fromInt i)
                                ]

                Game.None ->
                    Dom.addClass "none"
           )
        |> (if (model.config.gameMode == MovePiece && coords /= Nothing) || (model.config.gameMode == AddPiece && coords == Nothing) then
                DragDrop.makeDraggable model.dragDropState (MoveablePiece (PieceType piece) coords) dragDropMessages

            else
                Dom.addAttribute (attribute "draggable" "false")
           )
        |> (if model.config.gameMode == KillPiece then
                Dom.addAction ( "click", RemovePiece piece )

            else
                \e -> e
           )


enemyToHtml : Monster -> Element msg -> Element msg
enemyToHtml monster element =
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
        |> Dom.appendChildList
            [ Dom.element "img"
                |> Dom.addAttribute
                    (attribute "src"
                        ("/img/monsters/"
                            ++ Maybe.withDefault "" (monsterTypeToString monster.monster)
                            ++ ".png"
                        )
                    )
            , Dom.element "span"
                |> Dom.appendText
                    (if monster.id == 0 then
                        ""

                     else
                        String.fromInt monster.id
                    )
            ]


overlayToHtml : Model -> Maybe ( Int, Int ) -> BoardOverlay -> Element Msg
overlayToHtml model coords overlay =
    let
        dragDropMessages : DragDrop.Messages Msg MoveablePiece ( Int, Int )
        dragDropMessages =
            { dragStarted = MoveStarted
            , dropTargetChanged = MoveTargetChanged
            , dragEnded = MoveCanceled
            , dropped = MoveCompleted
            }
    in
    Dom.element "div"
        |> Dom.addClass "overlay"
        |> Dom.addClass
            (case overlay.ref of
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
            (case overlay.direction of
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
                (case overlay.ref of
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
                |> Dom.addAttribute (attribute "src" (getOverlayImageName overlay coords))
                |> Dom.addAttribute (attribute "draggable" "false")
            )
        |> (case overlay.ref of
                Treasure (Coin i) ->
                    Dom.appendChild
                        (Dom.element "span"
                            |> Dom.appendText (String.fromInt i)
                        )

                _ ->
                    \e -> e
           )
        |> (if (model.config.gameMode == MoveOverlay && coords /= Nothing) || (model.config.gameMode == AddPiece && coords == Nothing) then
                case overlay.ref of
                    Obstacle _ ->
                        DragDrop.makeDraggable model.dragDropState (MoveablePiece (OverlayType overlay Nothing) coords) dragDropMessages

                    Trap _ ->
                        DragDrop.makeDraggable model.dragDropState (MoveablePiece (OverlayType overlay Nothing) coords) dragDropMessages

                    _ ->
                        Dom.addAttribute (attribute "draggable" "false")

            else
                Dom.addAttribute (attribute "draggable" "false")
           )
        |> (case model.currentDraggable of
                Just piece ->
                    case ( piece.ref, piece.coords ) of
                        ( OverlayType o _, Just cell ) ->
                            Dom.addClassConditional "being-dragged" (o.ref == overlay.ref && any (\c -> cell == c) overlay.cells)

                        _ ->
                            \e -> e

                _ ->
                    \e -> e
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


getSplitRoomCodeSettings : Model -> ( ( String, String ), Bool )
getSplitRoomCodeSettings model =
    let
        ( fullCode, b ) =
            case model.currentClientSettings of
                Just s ->
                    s

                Nothing ->
                    ( Maybe.withDefault "" model.config.roomCode, model.config.showRoomCode )
    in
    case split "-" fullCode of
        head :: rest ->
            ( ( head, join "" rest ), b )

        _ ->
            ( ( "", "" ), b )


pushGameState : Model -> GameState -> Cmd Msg
pushGameState model state =
    Cmd.batch
        [ if model.connectionStatus /= Connected || model.config.roomCode == Nothing then
            Process.sleep 500
                |> Task.perform (\_ -> PushGameState)

          else
            GameSync.pushGameState (Maybe.withDefault "" model.config.roomCode) state
        , saveToStorage state model.config
        ]