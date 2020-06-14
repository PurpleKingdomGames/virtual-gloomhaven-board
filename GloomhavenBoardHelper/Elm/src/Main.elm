module Main exposing (main)

import Array exposing (Array, fromList, length, toIndexedList, toList)
import BoardMapTile exposing (MapTileRef(..))
import BoardOverlay exposing (BoardOverlay, BoardOverlayDirectionType(..), BoardOverlayType(..), ChestType(..), DoorSubType(..), ObstacleSubType(..), TrapSubType(..), TreasureSubType(..), getBoardOverlayName)
import Browser
import Character exposing (CharacterClass(..), characterToString)
import Dict
import Dom exposing (Element)
import Dom.DragDrop as DragDrop
import Game exposing (AIType(..), Cell, Game, NumPlayers(..), Piece, PieceType(..), assignIdentifier, assignPlayers, generateGameMap, getPieceName, getPieceType, moveOverlay, movePiece, removePieceFromBoard, revealRooms)
import GameSync exposing (pushGameState, receiveGameState)
import Html exposing (div)
import Html.Attributes exposing (attribute, class, hidden)
import Http exposing (Error)
import Json.Decode exposing (decodeValue)
import List exposing (any, filter, filterMap, head, reverse, sort)
import Monster exposing (BossType(..), Monster, MonsterLevel(..), MonsterType(..), NormalMonsterType(..), monsterTypeToString, stringToMonsterType)
import Random exposing (Seed)
import Scenario exposing (DoorData(..), Scenario)
import ScenarioSync exposing (loadScenarioById)


type alias Model =
    { game : Maybe Game
    , currentPlayers : List CharacterClass
    , dragDropState : DragDrop.State MoveablePiece ( Int, Int )
    , currentDraggable : Maybe MoveablePiece
    , currentMode : GameModeType
    }


type MoveablePieceType
    = OverlayType BoardOverlay
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


type alias MoveablePiece =
    { ref : MoveablePieceType
    , coords : Maybe ( Int, Int )
    }


type Msg
    = Loaded Seed (Result Error Scenario)
    | MoveStarted MoveablePiece
    | MoveTargetChanged ( Int, Int )
    | MoveCanceled
    | MoveCompleted MoveablePiece ( Int, Int )
    | GameStatePushed Json.Decode.Value
    | RemoveOverlay BoardOverlay
    | RemovePiece Piece
    | ChangeMode GameModeType
    | RevealRoomMsg (List MapTileRef)


main : Program Int Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : Int -> ( Model, Cmd Msg )
init seed =
    ( Model Nothing [ Brute, Mindthief, Tinkerer ] DragDrop.initialState Nothing (Loading 16), loadScenarioById 16 (Loaded (Random.initialSeed seed)) )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Loaded seed result ->
            case result of
                Ok scenario ->
                    if List.length model.currentPlayers > 4 || List.length model.currentPlayers < 2 then
                        ( { model | currentMode = LoadFailed }, Cmd.none )

                    else
                        let
                            game =
                                generateGameMap scenario ThreePlayer seed
                        in
                        ( { model | game = Just (assignPlayers model.currentPlayers game), currentMode = MovePiece }, Cmd.none )

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
                                        OverlayType o ->
                                            let
                                                newOverlay =
                                                    Tuple.second (moveOverlay o m.coords coords game)
                                            in
                                            Just (MoveablePiece (OverlayType newOverlay) m.coords)

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
                                        OverlayType o ->
                                            Tuple.first (moveOverlay o m.coords coords oldGame)

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
                                    if s.scenario == game.state.scenario && s.numPlayers == game.state.numPlayers then
                                        s

                                    else
                                        game.state

                                Err _ ->
                                    game.state
                    in
                    ( { model | game = Just { game | state = gameState } }, Cmd.none )

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

        ChangeMode mode ->
            ( { model | currentMode = mode }, Cmd.none )

        RevealRoomMsg rooms ->
            case model.game of
                Nothing ->
                    ( model, Cmd.none )

                Just game ->
                    let
                        newGame =
                            revealRooms game rooms
                    in
                    ( { model | game = Just newGame }, pushGameState newGame.state )


view : Model -> Html.Html Msg
view model =
    div [ class "content" ]
        (case model.game of
            Nothing ->
                []

            Just game ->
                [ div [ class "action-list" ] [ getNavHtml model, getNewPieceHtml model game ]
                , div [ class "board" ] (toList (Array.indexedMap (getBoardHtml model game) game.staticBoard))
                ]
        )


subscriptions : Model -> Sub Msg
subscriptions _ =
    receiveGameState GameStatePushed


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


getNavHtml : Model -> Html.Html Msg
getNavHtml model =
    Dom.element "nav"
        |> Dom.appendChild
            (Dom.element "ul"
                |> Dom.appendChildList
                    [ Dom.element "li"
                        |> Dom.addAction ( "click", ChangeMode MovePiece )
                        |> Dom.addClass "move-piece"
                        |> Dom.addClassConditional "active" (model.currentMode == MovePiece)
                        |> Dom.appendText "Move Piece"
                    , Dom.element "li"
                        |> Dom.addAction ( "click", ChangeMode KillPiece )
                        |> Dom.addClass "kill-piece"
                        |> Dom.addClassConditional "active" (model.currentMode == KillPiece)
                        |> Dom.appendText "Kill Piece"
                    , Dom.element "li"
                        |> Dom.addAction ( "click", ChangeMode LootCell )
                        |> Dom.addClass "loot"
                        |> Dom.addClassConditional "active" (model.currentMode == LootCell)
                        |> Dom.appendText "Loot"
                    , Dom.element "li"
                        |> Dom.addAction ( "click", ChangeMode MoveOverlay )
                        |> Dom.addClass "move-overlay"
                        |> Dom.addClassConditional "active" (model.currentMode == MoveOverlay)
                        |> Dom.appendText "Move Overlay"
                    , Dom.element "li"
                        |> Dom.addAction ( "click", ChangeMode DestroyOverlay )
                        |> Dom.addClass "destroy-overlay"
                        |> Dom.addClassConditional "active" (model.currentMode == DestroyOverlay)
                        |> Dom.appendText "Destroy Overlay"
                    , Dom.element "li"
                        |> Dom.addAction ( "click", ChangeMode RevealRoom )
                        |> Dom.addClass "reveal-room"
                        |> Dom.addClassConditional "active" (model.currentMode == RevealRoom)
                        |> Dom.appendText "Reveal Room"
                    , Dom.element "li"
                        |> Dom.addAction ( "click", ChangeMode AddPiece )
                        |> Dom.addClass "add-piece"
                        |> Dom.addClassConditional "active" (model.currentMode == AddPiece)
                        |> Dom.appendText "Add Piece"
                    ]
            )
        |> Dom.render


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

        cellElement : Dom.Element Msg
        cellElement =
            Dom.element "div"
                |> Dom.addClass "hexagon"
                -- Doors
                |> Dom.appendChildList
                    (List.filter (filterOverlaysForCoord x y) game.state.overlays
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
                    (List.filter (filterOverlaysForCoord x y) game.state.overlays
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

                                    _ ->
                                        True
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
                    (List.filter (filterOverlaysForCoord x y) game.state.overlays
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

                                OverlayType o ->
                                    Dom.appendChild (overlayToHtml model (Just ( x, y )) o)

                        Nothing ->
                            \e -> e
                   )
    in
    Dom.element "div"
        |> Dom.addClass "cell-wrapper"
        |> Dom.addClass (cellValueToString game cellValue)
        |> (case
                Dict.toList game.roomOrigins
                    |> List.filter (\( _, ( tx, ty ) ) -> tx == x && ty == y)
                    |> head
            of
                Just ( ref, _ ) ->
                    Dom.addAttributeList
                        [ attribute "data-board-ref" ref
                        , class ("rotate-" ++ String.fromInt (Maybe.withDefault 0 (Dict.get ref game.roomTurns)))
                        ]

                Nothing ->
                    \e -> e
           )
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
                        (Dom.element "img" |> Dom.addAttribute (attribute "src" ("/img/characters/portraits/" ++ player ++ ".png")))

                AI t ->
                    case t of
                        Enemy m ->
                            enemyToHtml m

                        Summons i ->
                            Dom.appendChildList
                                [ Dom.element "img" |> Dom.addAttribute (attribute "src" "/img/characters/summons.png")
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
                        DragDrop.makeDraggable model.dragDropState (MoveablePiece (OverlayType overlay) coords) dragDropMessages

                    Trap _ ->
                        DragDrop.makeDraggable model.dragDropState (MoveablePiece (OverlayType overlay) coords) dragDropMessages

                    _ ->
                        Dom.addAttribute (attribute "draggable" "false")

            else
                Dom.addAttribute (attribute "draggable" "false")
           )
        |> (case ( model.currentMode, overlay.ref ) of
                ( DestroyOverlay, Obstacle _ ) ->
                    Dom.addAction ( "click", RemoveOverlay overlay )

                ( DestroyOverlay, Trap _ ) ->
                    Dom.addAction ( "click", RemoveOverlay overlay )

                ( LootCell, Treasure _ ) ->
                    Dom.addAction ( "click", RemoveOverlay overlay )

                ( RevealRoom, Door _ refs ) ->
                    Dom.addAction ( "click", RevealRoomMsg refs )

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
