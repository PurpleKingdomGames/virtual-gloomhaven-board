module Main exposing (main)

import Array exposing (..)
import BoardMapTile exposing (MapTile, MapTileRef(..), getGridByRef, refToString)
import BoardOverlay exposing (BoardOverlay, BoardOverlayDirectionType(..), BoardOverlayType(..), ChestType(..), DoorSubType(..), ObstacleSubType(..), TrapSubType(..), TreasureSubType(..), getBoardOverlayName)
import Browser
import Dict
import Dom exposing (Element)
import Dom.DragDrop as DragDrop
import Game exposing (AIType(..), Cell, Game, NumPlayers(..), Piece, PieceType(..), assignIdentifier, generateGameMap, getPieceName, getPieceType, moveOverlay, movePiece, removePieceFromBoard, revealRooms)
import GameSync exposing (pushGameState, receiveGameState)
import Html exposing (div, li, nav, text, ul)
import Html.Attributes exposing (attribute, class, src)
import Html.Events exposing (onClick)
import Json.Decode exposing (decodeValue, errorToString)
import List exposing (any, filter, filterMap, head, tail, take)
import List.Extra exposing (uniqueBy)
import Monster exposing (BossType(..), Monster, MonsterLevel(..), MonsterType(..), NormalMonsterType(..), monsterTypeToString, stringToMonsterType)
import Random
import Scenario exposing (DoorData(..), MapTileData, Scenario, ScenarioMonster)


type alias Model =
    { game : Game
    , dragDropState : DragDrop.State MoveablePiece ( Int, Int )
    , currentDraggable : Maybe MoveablePiece
    , currentMode : GameModeType
    }


type MoveablePieceType
    = OverlayType BoardOverlay
    | PieceType Piece


type GameModeType
    = MovePiece
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
    = MoveStarted MoveablePiece
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
    let
        scenario =
            Scenario
                2
                "Barrow Lair"
                (MapTileData B3b
                    [ DoorLink Stone
                        Default
                        ( 1, -1 )
                        ( 2, 7 )
                        (MapTileData M1a
                            [ DoorLink Stone
                                DiagonalRight
                                ( 0, 0 )
                                ( 3, 0 )
                                (MapTileData A4b
                                    []
                                    [ BoardOverlay (Treasure (Chest (NormalChest 67))) Default [ ( 0, 2 ) ]
                                    ]
                                    [ ScenarioMonster (Monster (NormalType LivingCorpse) 0 Normal) 0 1 Monster.None Normal Elite
                                    , ScenarioMonster (Monster (NormalType LivingCorpse) 0 Normal) 1 2 Elite Elite Elite
                                    ]
                                    5
                                )
                            , DoorLink Stone
                                DiagonalLeft
                                ( 5, 0 )
                                ( 1, 0 )
                                (MapTileData A2a
                                    []
                                    []
                                    [ ScenarioMonster (Monster (NormalType LivingCorpse) 0 Normal) 3 1 Monster.None Normal Elite
                                    , ScenarioMonster (Monster (NormalType LivingCorpse) 0 Normal) 3 2 Elite Elite Elite
                                    ]
                                    1
                                )
                            , DoorLink Stone
                                Vertical
                                ( -1, 3 )
                                ( 4, 1 )
                                (MapTileData A1a
                                    []
                                    []
                                    [ ScenarioMonster (Monster (NormalType LivingCorpse) 0 Normal) 1 1 Monster.None Normal Elite
                                    , ScenarioMonster (Monster (NormalType LivingCorpse) 0 Normal) 1 2 Normal Normal Normal
                                    , ScenarioMonster (Monster (NormalType LivingCorpse) 0 Normal) 2 2 Normal Normal Normal
                                    ]
                                    3
                                )
                            , DoorLink Stone
                                Vertical
                                ( 5, 3 )
                                ( -1, 1 )
                                (MapTileData A3b
                                    []
                                    []
                                    [ ScenarioMonster (Monster (NormalType LivingCorpse) 0 Normal) 2 1 Monster.None Normal Elite
                                    , ScenarioMonster (Monster (NormalType LivingCorpse) 0 Normal) 2 2 Normal Normal Normal
                                    , ScenarioMonster (Monster (NormalType LivingCorpse) 0 Normal) 3 2 Normal Normal Normal
                                    ]
                                    3
                                )
                            ]
                            [ BoardOverlay (Obstacle Sarcophagus) Default [ ( 3, 2 ), ( 2, 2 ) ]
                            , BoardOverlay (Obstacle Sarcophagus) DiagonalLeft [ ( 1, 5 ), ( 1, 4 ) ]
                            , BoardOverlay (Obstacle Sarcophagus) DiagonalRight [ ( 3, 5 ), ( 4, 4 ) ]
                            ]
                            [ ScenarioMonster (Monster (NormalType BanditArcher) 0 Normal) 1 1 Elite Elite Elite
                            , ScenarioMonster (Monster (BossType BanditCommander) 1 Normal) 2 1 Normal Normal Normal
                            , ScenarioMonster (Monster (NormalType BanditArcher) 0 Normal) 3 1 Monster.None Normal Elite
                            ]
                            3
                        )
                    ]
                    [ BoardOverlay (Trap BearTrap) Default [ ( 0, 1 ) ]
                    , BoardOverlay (Trap BearTrap) Default [ ( 2, 1 ) ]
                    , BoardOverlay StartingLocation Default [ ( 0, 3 ) ]
                    , BoardOverlay StartingLocation Default [ ( 1, 3 ) ]
                    , BoardOverlay StartingLocation Default [ ( 2, 3 ) ]
                    , BoardOverlay StartingLocation Default [ ( 1, 2 ) ]
                    , BoardOverlay StartingLocation Default [ ( 2, 2 ) ]
                    ]
                    [ ScenarioMonster (Monster (NormalType BanditArcher) 5 Monster.None) 0 0 Normal Normal Normal
                    , ScenarioMonster (Monster (NormalType BanditArcher) 2 Monster.None) 1 0 Monster.None Monster.None Normal
                    , ScenarioMonster (Monster (NormalType BanditArcher) 3 Monster.None) 2 0 Monster.None Normal Normal
                    , ScenarioMonster (Monster (NormalType BanditArcher) 1 Monster.None) 3 0 Normal Normal Normal
                    ]
                    3
                )
                0
                []
    in
    ( Model (generateGameMap scenario ThreePlayer (Random.initialSeed seed)) DragDrop.initialState Nothing MovePiece, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MoveStarted piece ->
            ( { model | dragDropState = DragDrop.startDragging model.dragDropState piece, currentDraggable = Just piece }, Cmd.none )

        MoveTargetChanged coords ->
            let
                newDraggable =
                    case model.currentDraggable of
                        Just m ->
                            case m.ref of
                                OverlayType o ->
                                    let
                                        newOverlay =
                                            Tuple.second (moveOverlay o m.coords coords model.game)
                                    in
                                    Just (MoveablePiece (OverlayType newOverlay) m.coords)

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
                game =
                    case model.currentDraggable of
                        Just m ->
                            case m.ref of
                                OverlayType o ->
                                    Tuple.first (moveOverlay o m.coords coords model.game)

                                PieceType p ->
                                    case p.ref of
                                        AI (Enemy monster) ->
                                            (if monster.id == 0 then
                                                assignIdentifier model.game.state.availableMonsters p

                                             else
                                                ( p, model.game.state.availableMonsters )
                                            )
                                                |> (\( p2, d ) ->
                                                        let
                                                            newGame =
                                                                Tuple.first (movePiece p2 m.coords coords model.game)

                                                            newState =
                                                                newGame.state
                                                        in
                                                        { newGame | state = { newState | availableMonsters = d } }
                                                   )

                                        _ ->
                                            Tuple.first (movePiece p m.coords coords model.game)

                        Nothing ->
                            model.game
            in
            ( { model | dragDropState = DragDrop.stopDragging model.dragDropState, game = game, currentDraggable = Nothing }, pushGameState game.state )

        GameStatePushed val ->
            let
                gameState =
                    case decodeValue GameSync.decodeGameState val of
                        Ok s ->
                            if s.scenario == model.game.state.scenario && s.numPlayers == model.game.state.numPlayers then
                                s

                            else
                                model.game.state

                        Err _ ->
                            model.game.state

                game =
                    model.game
            in
            ( { model | game = { game | state = gameState } }, Cmd.none )

        RemoveOverlay overlay ->
            let
                gameState =
                    model.game.state

                game =
                    model.game

                newState =
                    { gameState | overlays = List.filter (\o -> o.cells /= overlay.cells || o.ref /= overlay.ref) gameState.overlays }
            in
            ( { model | game = { game | state = newState } }, pushGameState newState )

        RemovePiece piece ->
            let
                game =
                    removePieceFromBoard piece model.game
            in
            ( { model | game = game }, pushGameState game.state )

        ChangeMode mode ->
            ( { model | currentMode = mode }, Cmd.none )

        RevealRoomMsg rooms ->
            let
                game =
                    revealRooms model.game rooms
            in
            ( { model | game = game }, pushGameState game.state )


view : Model -> Html.Html Msg
view model =
    div [ class "content" ]
        [ div [ class "action-list" ] [ getNewPieceHtml model, getNavHtml model ]
        , div [ class "board" ] (toList (Array.indexedMap (getBoardHtml model) model.game.staticBoard))
        ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    receiveGameState GameStatePushed


getNewPieceHtml : Model -> Html.Html Msg
getNewPieceHtml model =
    Dom.element "div"
        |> Dom.addClass "new-piece-list"
        |> Dom.appendChild
            (Dom.element "ul"
                |> Dom.appendChildList
                    (Dict.toList model.game.state.availableMonsters
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


getBoardHtml : Model -> Int -> Array Cell -> Html.Html Msg
getBoardHtml model y row =
    div [ class "row" ] (toList (Array.indexedMap (getCellHtml model y) row))


getCellHtml : Model -> Int -> Int -> Cell -> Html.Html Msg
getCellHtml model y x cellValue =
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
                -- Treasure chests, obstacles, doors, traps etc.
                |> Dom.appendChildList
                    (List.filter (filterOverlaysForCoord x y) model.game.state.overlays
                        |> List.filter
                            (\o ->
                                case o.ref of
                                    Treasure t ->
                                        case t of
                                            Chest _ ->
                                                True

                                            _ ->
                                                False

                                    _ ->
                                        True
                            )
                        |> List.map (overlayToHtml model (Just ( x, y )))
                    )
                -- Players / Monsters / Summons
                |> Dom.appendChildList
                    (case getPieceForCoord x y model.game.state.pieces of
                        Nothing ->
                            []

                        Just p ->
                            [ pieceToHtml model (Just ( x, y )) p ]
                    )
                -- Loot / Coins
                |> Dom.appendChildList
                    (List.filter (filterOverlaysForCoord x y) model.game.state.overlays
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
        |> Dom.addClass (cellValueToString model cellValue)
        |> (case
                Dict.toList model.game.roomOrigins
                    |> List.filter (\( _, ( tx, ty ) ) -> tx == x && ty == y)
                    |> head
            of
                Just ( ref, _ ) ->
                    Dom.addAttributeList
                        [ attribute "data-board-ref" ref
                        , class ("rotate-" ++ String.fromInt (Maybe.withDefault 0 (Dict.get ref model.game.roomTurns)))
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


cellValueToString : Model -> Cell -> String
cellValueToString model val =
    if any (\r -> any (\x -> x == r) model.game.state.visibleRooms) val.rooms then
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
                Player _ ->
                    Dom.appendChild (Dom.element "div")

                AI t ->
                    case t of
                        Enemy m ->
                            enemyToHtml m

                        Summons i ->
                            Dom.appendChild
                                (Dom.element "img"
                                    |> Dom.addAttribute (attribute "src" ("/img/summons-" ++ String.fromInt (modBy i 3) ++ ".png"))
                                )

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
                |> Dom.appendText (String.fromInt monster.id)
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
        |> (case coords of
                Just ( x, y ) ->
                    if model.currentMode == MoveOverlay then
                        case overlay.ref of
                            Obstacle _ ->
                                DragDrop.makeDraggable model.dragDropState (MoveablePiece (OverlayType overlay) coords) dragDropMessages

                            Trap _ ->
                                DragDrop.makeDraggable model.dragDropState (MoveablePiece (OverlayType overlay) coords) dragDropMessages

                            _ ->
                                Dom.addAttribute (attribute "draggable" "false")

                    else
                        Dom.addAttribute (attribute "draggable" "false")

                Nothing ->
                    if model.currentMode == MoveOverlay then
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
            case overlay.ref of
                Door d _ ->
                    case d of
                        Stone ->
                            if overlay.direction == Vertical then
                                "-vert"

                            else
                                ""

                Obstacle o ->
                    case o of
                        Sarcophagus ->
                            ""

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
