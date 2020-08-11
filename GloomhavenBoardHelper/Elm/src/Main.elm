module Main exposing (main)

import Array exposing (Array, fromList, length, toIndexedList, toList)
import Bitwise
import BoardMapTile exposing (MapTileRef(..), refToString)
import BoardOverlay exposing (BoardOverlay, BoardOverlayDirectionType(..), BoardOverlayType(..), ChestType(..), CorridorMaterial(..), DifficultTerrainSubType(..), DoorSubType(..), ObstacleSubType(..), TrapSubType(..), TreasureSubType(..), getBoardOverlayName)
import Browser
import Character exposing (CharacterClass(..), characterToString)
import Dict
import Dom exposing (Element)
import Dom.DragDrop as DragDrop
import Game exposing (AIType(..), Cell, Game, NumPlayers(..), Piece, PieceType(..), RoomData, assignIdentifier, assignPlayers, generateGameMap, getPieceName, getPieceType, moveOverlay, movePiece, removePieceFromBoard, revealRooms)
import GameSync exposing (ClientOrServer(..), Msg, pushGameState, pushInitGameState, pushUpdatedGameState, receiveGameState)
import Html exposing (div, img)
import Html.Attributes exposing (attribute, class, hidden, src, style)
import Http exposing (Error)
import Json.Decode exposing (decodeValue)
import List exposing (any, filter, filterMap, head, map, reverse, sort)
import Monster exposing (BossType(..), Monster, MonsterLevel(..), MonsterType(..), NormalMonsterType(..), monsterTypeToString, stringToMonsterType)
import Random exposing (Seed)
import Scenario exposing (DoorData(..), Scenario)
import ScenarioSync exposing (loadScenarioById)


type alias Model =
    { game : Maybe Game
    , config : Config
    , currentMode : GameModeType
    , clientsConnected : List String
    , currentScenarioInput : Int
    , currentPlayers : List CharacterClass
    , currentServerSettings : Maybe ( ClientOrServer, String )
    , dragDropState : DragDrop.State MoveablePiece ( Int, Int )
    , currentDraggable : Maybe MoveablePiece
    }


type alias Config =
    { appMode : AppModeType
    , clientOrServer : ClientOrServer
    , joinCode : String
    }


type MoveablePieceType
    = OverlayType BoardOverlay (Maybe ( Int, Int ))
    | PieceType Piece


type GameModeType
    = Loading Int
    | LoadFailed
    | MovePiece
    | KillPiece
    | MoveOverlay
    | DestroyOverlay
    | LootCell
    | RevealRoom
    | AddPiece


type AppModeType
    = Game
    | ScenarioDialog
    | ServerConfigDialog


type alias MoveablePiece =
    { ref : MoveablePieceType
    , coords : Maybe ( Int, Int )
    }


type Msg
    = Loaded Seed (Maybe Game.GameState) (Result Error Scenario)
    | MoveStarted MoveablePiece
    | MoveTargetChanged ( Int, Int )
    | MoveCanceled
    | MoveCompleted MoveablePiece ( Int, Int )
      -- LEGACY
    | GameStatePushed Json.Decode.Value
      -- END LEGACY
    | GameStateUpdated Game.GameState
    | ClientListUpdated (List String)
    | RemoveOverlay BoardOverlay
    | RemovePiece Piece
    | ChangeGameMode GameModeType
    | ChangeAppMode AppModeType
    | RevealRoomMsg (List MapTileRef) ( Int, Int )
    | ChangeScenario Int
    | EnterScenarioNumber String
    | ChangeClientServerType String
    | ChangeJoinCode String
    | GameSyncMsg GameSync.Msg


main : Program Int Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- PLACEHOLDER


initScenario =
    50


init : Int -> ( Model, Cmd Msg )
init seed =
    ( Model Nothing (Config Game Client "join-1") (Loading initScenario) [] 0 [ Berserker, Quartermaster, Tinkerer ] Nothing DragDrop.initialState Nothing, loadScenarioById initScenario (Loaded (Random.initialSeed seed) Nothing) )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Loaded seed initGameState result ->
            case result of
                Ok scenario ->
                    if List.length model.currentPlayers > 4 || List.length model.currentPlayers < 2 then
                        ( { model | currentMode = LoadFailed }, Cmd.none )

                    else
                        let
                            game =
                                generateGameMap scenario ThreePlayer seed
                                    |> assignPlayers model.currentPlayers

                            gameState =
                                case initGameState of
                                    Just gs ->
                                        gs

                                    Nothing ->
                                        game.state
                        in
                        ( { model | game = Just { game | state = gameState }, currentMode = MovePiece, currentScenarioInput = scenario.id }, pushInitGameState game.state )

                Err _ ->
                    ( { model | currentMode = LoadFailed }, Cmd.none )

        MoveStarted piece ->
            ( { model | dragDropState = DragDrop.startDragging model.dragDropState piece, currentDraggable = Just piece }, Cmd.none )

        MoveTargetChanged coords ->
            case model.game of
                Nothing ->
                    ( model, Cmd.none )

                Just game ->
                    let
                        newDraggable =
                            case model.currentDraggable of
                                Just m ->
                                    case m.ref of
                                        OverlayType o prevCoords ->
                                            let
                                                ( _, newOverlay, newCoords ) =
                                                    moveOverlay o m.coords prevCoords coords game
                                            in
                                            Just (MoveablePiece (OverlayType newOverlay newCoords) m.coords)

                                        PieceType p ->
                                            let
                                                newPiece =
                                                    Tuple.second (movePiece p m.coords coords game)
                                            in
                                            Just (MoveablePiece (PieceType newPiece) m.coords)

                                Nothing ->
                                    model.currentDraggable
                    in
                    ( { model | dragDropState = DragDrop.updateDropTarget model.dragDropState coords, currentDraggable = newDraggable }, Cmd.none )

        MoveCanceled ->
            ( { model | dragDropState = DragDrop.stopDragging model.dragDropState, currentDraggable = Nothing }, Cmd.none )

        MoveCompleted _ coords ->
            case model.game of
                Nothing ->
                    ( model, Cmd.none )

                Just oldGame ->
                    let
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
                    ( { model | dragDropState = DragDrop.stopDragging model.dragDropState, game = Just game, currentDraggable = Nothing }, pushGameState game.state )

        GameStatePushed val ->
            case model.game of
                Nothing ->
                    ( model, Cmd.none )

                Just game ->
                    let
                        gameState =
                            case decodeValue GameSync.decodeGameState val of
                                Ok s ->
                                    if s.scenario == game.state.scenario && s.numPlayers == game.state.numPlayers && s.updateCount > game.state.updateCount then
                                        s

                                    else
                                        game.state

                                Err _ ->
                                    game.state
                    in
                    ( { model | game = Just { game | state = gameState } }, pushUpdatedGameState gameState )

        RemoveOverlay overlay ->
            case model.game of
                Nothing ->
                    ( model, Cmd.none )

                Just game ->
                    let
                        gameState =
                            game.state

                        newState =
                            { gameState | overlays = List.filter (\o -> o.cells /= overlay.cells || o.ref /= overlay.ref) gameState.overlays }
                    in
                    ( { model | game = Just { game | state = newState } }, pushGameState newState )

        RemovePiece piece ->
            case model.game of
                Nothing ->
                    ( model, Cmd.none )

                Just game ->
                    let
                        newGame =
                            removePieceFromBoard piece game
                    in
                    ( { model | game = Just newGame }, pushGameState newGame.state )

        ChangeGameMode mode ->
            ( { model | currentMode = mode }, Cmd.none )

        RevealRoomMsg rooms ( x, y ) ->
            case model.game of
                Nothing ->
                    ( model, Cmd.none )

                Just game ->
                    let
                        updatedGame =
                            revealRooms game rooms

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
                    ( { model | game = Just newGame }, pushGameState newGame.state )

        ChangeAppMode mode ->
            let
                config =
                    model.config
            in
            ( { model | config = { config | appMode = mode } }, Cmd.none )

        ChangeScenario newScenario ->
            let
                seed =
                    case model.game of
                        Just game ->
                            game.seed

                        Nothing ->
                            Random.initialSeed 0

                config =
                    model.config
            in
            ( { model | config = { config | appMode = Game }, currentMode = Loading newScenario, currentDraggable = Nothing, game = Nothing }, loadScenarioById newScenario (Loaded seed Nothing) )

        EnterScenarioNumber strId ->
            case String.toInt strId of
                Just scenarioId ->
                    if scenarioId > 0 && scenarioId < 94 then
                        ( { model | currentScenarioInput = scenarioId }, Cmd.none )

                    else
                        ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        ChangeClientServerType typeStr ->
            let
                currentJoinCode =
                    case model.currentServerSettings of
                        Just ( _, j ) ->
                            j

                        Nothing ->
                            model.config.joinCode
            in
            case String.toLower typeStr of
                "client" ->
                    ( { model | currentServerSettings = Just ( Client, currentJoinCode ) }, Cmd.none )

                "server" ->
                    ( { model | currentServerSettings = Just ( Server, currentJoinCode ) }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ChangeJoinCode newCode ->
            let
                clientOrServer =
                    case model.currentServerSettings of
                        Just ( s, _ ) ->
                            s

                        Nothing ->
                            model.config.clientOrServer
            in
            ( { model | currentServerSettings = Just ( clientOrServer, newCode ) }, Cmd.none )

        GameSyncMsg gameSyncMsg ->
            let
                gameState =
                    Maybe.map (\g -> g.state) model.game

                ( updateMsg, cmdMsg ) =
                    GameSync.update
                        gameSyncMsg
                        gameState
                        model.config.clientOrServer
                        model.clientsConnected
                        GameStateUpdated
                        ClientListUpdated
            in
            case updateMsg of
                Just u ->
                    let
                        ( newModel, msgs ) =
                            update u model
                    in
                    ( newModel, Cmd.batch [ cmdMsg, msgs ] )

                Nothing ->
                    ( model, cmdMsg )

        GameStateUpdated gameState ->
            case model.game of
                Just game ->
                    if game.state.scenario == gameState.scenario then
                        ( { model | game = Just { game | state = gameState } }, Cmd.none )

                    else
                        ( { model | currentMode = Loading gameState.scenario }, loadScenarioById gameState.scenario (Loaded (Random.initialSeed gameState.scenario) (Just gameState)) )

                Nothing ->
                    ( { model | currentMode = Loading gameState.scenario }, loadScenarioById gameState.scenario (Loaded (Random.initialSeed gameState.scenario) (Just gameState)) )

        ClientListUpdated clientList ->
            ( { model | clientsConnected = clientList }, Cmd.none )


view : Model -> Html.Html Msg
view model =
    let
        config =
            model.config
    in
    div [ class "content" ]
        (case model.game of
            Nothing ->
                []

            Just game ->
                [ div [ class "menu" ] [ getMenuHtml ]
                , div [ class "action-list" ] [ getNavHtml model, getNewPieceHtml model game ]
                , div [ class "board-wrapper" ]
                    [ div [ class "mapTiles" ] (map (getMapTileHtml game.state.visibleRooms) game.roomData)
                    , div [ class "board" ] (toList (Array.indexedMap (getBoardHtml model game) game.staticBoard))
                    ]
                ]
                    ++ (case config.appMode of
                            Game ->
                                []

                            _ ->
                                [ getDialogForAppMode model ]
                       )
        )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ receiveGameState GameStatePushed
        , Sub.map (\s -> GameSyncMsg s) GameSync.subscriptions
        ]


getNewPieceHtml : Model -> Game -> Html.Html Msg
getNewPieceHtml model game =
    Dom.element "div"
        |> Dom.addAttributeConditional (hidden True) (model.currentMode /= AddPiece)
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
                    (Dict.toList game.state.availableMonsters
                        |> List.filter (\( _, v ) -> length v > 0)
                        |> List.map (\( k, _ ) -> k)
                        |> List.sort
                        |> List.reverse
                        |> filterMap (\k -> stringToMonsterType k)
                        |> List.map
                            (\k ->
                                (Dom.element "li"
                                    |> Dom.appendChild (pieceToHtml model Nothing (Piece (AI (Enemy (Monster k 0 Normal))) 0 0))
                                )
                                    :: (case k of
                                            NormalType _ ->
                                                [ Dom.element "li"
                                                    |> Dom.appendChild (pieceToHtml model Nothing (Piece (AI (Enemy (Monster k 0 Elite))) 0 0))
                                                ]

                                            _ ->
                                                []
                                       )
                            )
                        |> List.foldl (++) []
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
                        |> Dom.addAction ( "click", ChangeAppMode ServerConfigDialog )
                        |> Dom.appendText "Connection Settings"
                    ]
            )
        |> Dom.render


getDialogForAppMode : Model -> Html.Html Msg
getDialogForAppMode model =
    Dom.element "div"
        |> Dom.addClass "overlay"
        |> Dom.appendChild
            (Dom.element "div"
                |> Dom.addClass "dialog"
                |> (case model.config.appMode of
                        ScenarioDialog ->
                            Dom.appendChild (getScenarioDialog model)

                        ServerConfigDialog ->
                            Dom.appendChild (getServerSettingsDialog model)

                        Game ->
                            \e -> e
                   )
            )
        |> Dom.render


getScenarioDialog : Model -> Element Msg
getScenarioDialog model =
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
                        |> Dom.addAttribute (attribute "value" (String.fromInt model.currentScenarioInput))
                        |> Dom.addChangeHandler EnterScenarioNumber
                    ]
            , Dom.element "div"
                |> Dom.addClass "button-wrapper"
                |> Dom.appendChildList
                    [ Dom.element "button"
                        |> Dom.appendText "OK"
                        |> Dom.addAction ( "click", ChangeScenario model.currentScenarioInput )
                    , Dom.element "button"
                        |> Dom.appendText "Cancel"
                        |> Dom.addAction ( "click", ChangeAppMode Game )
                    ]
            ]


getServerSettingsDialog : Model -> Element Msg
getServerSettingsDialog model =
    let
        ( clientOrServer, joinCode ) =
            case model.currentServerSettings of
                Just s ->
                    s

                Nothing ->
                    ( model.config.clientOrServer, model.config.joinCode )
    in
    Dom.element "div"
        |> Dom.addClass "scenario-form"
        |> Dom.appendChildList
            [ Dom.element "div"
                |> Dom.addClass "input-wrapper"
                |> Dom.appendChildList
                    [ Dom.element "label"
                        |> Dom.addAttribute (attribute "for" "clientServerType")
                        |> Dom.appendText "Type"
                    , Dom.element "select"
                        |> Dom.addAttribute (attribute "id" "clientServerType")
                        |> Dom.addChangeHandler ChangeClientServerType
                        |> Dom.appendChildList
                            [ Dom.element "option"
                                |> Dom.addAttribute (attribute "value" "client")
                                |> Dom.addAttributeConditional (attribute "selected" "selected") (clientOrServer == Client)
                                |> Dom.appendText "Client"
                            , Dom.element "option"
                                |> Dom.addAttribute (attribute "value" "server")
                                |> Dom.addAttributeConditional (attribute "selected" "selected") (clientOrServer == Server)
                                |> Dom.appendText "Server"
                            ]
                    ]
            , Dom.element "div"
                |> Dom.addClass "input-wrapper"
                |> Dom.addAttributeConditional (attribute "hidden" "hidden") (clientOrServer == Server)
                |> Dom.appendChildList
                    [ Dom.element "label"
                        |> Dom.addAttribute (attribute "for" "clientServerJoinCode")
                        |> Dom.appendText "Join Code"
                    , Dom.element "input"
                        |> Dom.addAttribute (attribute "id" "clientServerJoinCode")
                        |> Dom.addAttribute (attribute "value" joinCode)
                        |> Dom.addAttribute (attribute "type" "text")
                        |> Dom.addChangeHandler ChangeJoinCode
                    ]
            , Dom.element "div"
                |> Dom.addClass "button-wrapper"
                |> Dom.appendChildList
                    [ Dom.element "button"
                        |> Dom.appendText "OK"
                        |> Dom.addAction ( "click", ChangeScenario model.currentScenarioInput )
                    , Dom.element "button"
                        |> Dom.appendText "Cancel"
                        |> Dom.addAction ( "click", ChangeAppMode Game )
                    ]
            ]


getNavHtml : Model -> Html.Html Msg
getNavHtml model =
    Dom.element "nav"
        |> Dom.appendChild
            (Dom.element "ul"
                |> Dom.appendChildList
                    [ Dom.element "li"
                        |> Dom.addAction ( "click", ChangeGameMode MovePiece )
                        |> Dom.addClass "move-piece"
                        |> Dom.addClassConditional "active" (model.currentMode == MovePiece)
                        |> Dom.appendText "Move Piece"
                    , Dom.element "li"
                        |> Dom.addAction ( "click", ChangeGameMode KillPiece )
                        |> Dom.addClass "kill-piece"
                        |> Dom.addClassConditional "active" (model.currentMode == KillPiece)
                        |> Dom.appendText "Kill Piece"
                    , Dom.element "li"
                        |> Dom.addAction ( "click", ChangeGameMode LootCell )
                        |> Dom.addClass "loot"
                        |> Dom.addClassConditional "active" (model.currentMode == LootCell)
                        |> Dom.appendText "Loot"
                    , Dom.element "li"
                        |> Dom.addAction ( "click", ChangeGameMode MoveOverlay )
                        |> Dom.addClass "move-overlay"
                        |> Dom.addClassConditional "active" (model.currentMode == MoveOverlay)
                        |> Dom.appendText "Move Overlay"
                    , Dom.element "li"
                        |> Dom.addAction ( "click", ChangeGameMode DestroyOverlay )
                        |> Dom.addClass "destroy-overlay"
                        |> Dom.addClassConditional "active" (model.currentMode == DestroyOverlay)
                        |> Dom.appendText "Destroy Overlay"
                    , Dom.element "li"
                        |> Dom.addAction ( "click", ChangeGameMode RevealRoom )
                        |> Dom.addClass "reveal-room"
                        |> Dom.addClassConditional "active" (model.currentMode == RevealRoom)
                        |> Dom.appendText "Reveal Room"
                    , Dom.element "li"
                        |> Dom.addAction ( "click", ChangeGameMode AddPiece )
                        |> Dom.addClass "add-piece"
                        |> Dom.addClassConditional "active" (model.currentMode == AddPiece)
                        |> Dom.appendText "Add Piece"
                    ]
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
        [ img
            [ src ("/img/map-tiles/" ++ ref ++ ".png")
            , class ("ref-" ++ ref)
            ]
            []
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
                |> addActionsForCell model.currentMode ( x, y ) overlaysForCell
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
        |> (if (model.currentMode == MovePiece && coords /= Nothing) || (model.currentMode == AddPiece && coords == Nothing) then
                DragDrop.makeDraggable model.dragDropState (MoveablePiece (PieceType piece) coords) dragDropMessages

            else
                Dom.addAttribute (attribute "draggable" "false")
           )
        |> (if model.currentMode == KillPiece then
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

                Treasure _ ->
                    "treasure"

                Obstacle _ ->
                    "obstacle"

                Hazard _ ->
                    "hazard"

                DifficultTerrain _ ->
                    "difficult-terrain"

                Door _ _ ->
                    "door"

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
        |> (if (model.currentMode == MoveOverlay && coords /= Nothing) || (model.currentMode == AddPiece && coords == Nothing) then
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
