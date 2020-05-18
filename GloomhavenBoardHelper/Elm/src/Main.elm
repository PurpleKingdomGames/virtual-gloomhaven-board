module Main exposing (main)

import Array exposing (..)
import BoardMapTile exposing (MapTile, MapTileRef(..), getGridByRef, refToString)
import BoardOverlay exposing (BoardOverlay, BoardOverlayDirectionType(..), BoardOverlayType(..), ChestType(..), DoorSubType(..), ObstacleSubType(..), TrapSubType(..), TreasureSubType(..), getBoardOverlayName)
import Browser
import Dom exposing (Element)
import Dom.DragDrop as DragDrop
import Game exposing (AIType(..), Cell, Game, NumPlayers(..), Piece, PieceType(..), generateGameMap, getPieceName, getPieceType, moveOverlay, movePiece)
import GameSync exposing (pushGameState, receiveGameState)
import Html exposing (div)
import Html.Attributes exposing (attribute, class, src)
import Json.Decode exposing (decodeValue, errorToString)
import List exposing (filter, head, tail, take)
import Monster exposing (BossType(..), Monster, MonsterLevel(..), MonsterType(..), NormalMonsterType(..), monsterTypeToString)
import Scenario exposing (DoorData(..), MapTileData, Scenario, ScenarioMonster)


type alias Model =
    { game : Game
    , dragDropState : DragDrop.State MoveablePiece ( Int, Int )
    , currentDraggable : Maybe MoveablePiece
    }


type MoveablePieceType
    = OverlayType BoardOverlay
    | PieceType Piece


type alias MoveablePiece =
    { ref : MoveablePieceType
    , x : Int
    , y : Int
    }


type Msg
    = MoveStarted MoveablePiece
    | MoveTargetChanged ( Int, Int )
    | MoveCanceled
    | MoveCompleted MoveablePiece ( Int, Int )
    | GameStatePushed Json.Decode.Value


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : () -> ( Model, Cmd Msg )
init _ =
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
                                    [ ScenarioMonster (Monster (NormalType LivingCorpse) 3 Normal) 0 1 Monster.None Normal Elite
                                    , ScenarioMonster (Monster (NormalType LivingCorpse) 1 Normal) 1 2 Elite Elite Elite
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
                                    [ ScenarioMonster (Monster (NormalType LivingCorpse) 6 Normal) 3 1 Monster.None Normal Elite
                                    , ScenarioMonster (Monster (NormalType LivingCorpse) 2 Normal) 3 2 Elite Elite Elite
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
                                    [ ScenarioMonster (Monster (NormalType LivingCorpse) 1 Normal) 1 1 Monster.None Normal Elite
                                    , ScenarioMonster (Monster (NormalType LivingCorpse) 3 Normal) 1 2 Normal Normal Normal
                                    , ScenarioMonster (Monster (NormalType LivingCorpse) 6 Normal) 2 2 Normal Normal Normal
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
                                    [ ScenarioMonster (Monster (NormalType LivingCorpse) 3 Normal) 2 1 Monster.None Normal Elite
                                    , ScenarioMonster (Monster (NormalType LivingCorpse) 2 Normal) 2 2 Normal Normal Normal
                                    , ScenarioMonster (Monster (NormalType LivingCorpse) 5 Normal) 3 2 Normal Normal Normal
                                    ]
                                    3
                                )
                            ]
                            [ BoardOverlay (Obstacle Sarcophagus) Default [ ( 3, 2 ), ( 2, 2 ) ]
                            , BoardOverlay (Obstacle Sarcophagus) DiagonalLeft [ ( 1, 5 ), ( 1, 4 ) ]
                            , BoardOverlay (Obstacle Sarcophagus) DiagonalRight [ ( 3, 5 ), ( 4, 4 ) ]
                            ]
                            [ ScenarioMonster (Monster (NormalType BanditArcher) 6 Normal) 1 1 Elite Elite Elite
                            , ScenarioMonster (Monster (BossType BanditCommander) 1 Normal) 2 1 Normal Normal Normal
                            , ScenarioMonster (Monster (NormalType BanditArcher) 4 Normal) 3 1 Monster.None Normal Elite
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
    in
    ( Model (generateGameMap scenario ThreePlayer) DragDrop.initialState Nothing, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MoveStarted piece ->
            ( { model | dragDropState = DragDrop.startDragging model.dragDropState piece, currentDraggable = Just piece }, Cmd.none )

        MoveTargetChanged coords ->
            let
                ( game, newDraggable ) =
                    case model.currentDraggable of
                        Just m ->
                            case m.ref of
                                OverlayType o ->
                                    let
                                        ( newGame, newOverlay ) =
                                            moveOverlay o ( m.x, m.y ) coords model.game
                                    in
                                    ( newGame, Just (MoveablePiece (OverlayType newOverlay) m.x m.y) )

                                PieceType p ->
                                    let
                                        ( newGame, newPiece ) =
                                            movePiece p coords model.game
                                    in
                                    ( newGame, Just (MoveablePiece (PieceType newPiece) m.x m.y) )

                        Nothing ->
                            ( model.game, model.currentDraggable )
            in
            ( { model | dragDropState = DragDrop.updateDropTarget model.dragDropState coords, game = game, currentDraggable = newDraggable }, pushGameState game.state )

        MoveCanceled ->
            ( { model | dragDropState = DragDrop.stopDragging model.dragDropState, currentDraggable = Nothing }, Cmd.none )

        MoveCompleted character ( x, y ) ->
            ( { model | dragDropState = DragDrop.stopDragging model.dragDropState, currentDraggable = Nothing }, Cmd.none )

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



{-
   let
       playerList =
           model.players

       charModel =
           case character of
               MoveablePlayer p ->
                   { model
                       | players =
                           List.map
                               (\o ->
                                   if o.class == p.class then
                                       { o | x = x, y = y }

                                   else
                                       o
                               )
                               playerList
                   }

               MoveableEnemy e ->
                   model

       newModel =
           { charModel | dragDropState = DragDrop.initialState }
   in
   ( newModel, Cmd.none )
-}


view : Model -> Html.Html Msg
view model =
    div [ class "board" ] (toList (Array.indexedMap (getBoardHtml model) model.game.staticBoard))


subscriptions : Model -> Sub Msg
subscriptions _ =
    receiveGameState GameStatePushed


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
                |> Dom.addClass ("hexagon " ++ cellValueToString cellValue)
                |> Dom.appendChildList
                    (case getPieceForCoord x y model.game.state.pieces of
                        Nothing ->
                            []

                        Just p ->
                            [ pieceToHtml model x y p ]
                    )
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
                        |> List.map (overlayToHtml x y)
                    )

        {-
           |> Dom.appendChildList
               (case findPlayerByCell x y model.players of
                   Just p ->
                       [ Dom.element "img"
                           |> Dom.addClass ("player " ++ String.toLower (playerToString p))
                           |> Dom.addAttribute (src ("/img/characters/portraits/" ++ String.toLower (playerToString p) ++ ".png"))
                           |> DragDrop.makeDraggable model.dragDropState (MoveablePlayer p) dragDropMessages
                       ]

                   Nothing ->
                       []
               )
        -}
    in
    Dom.element "div"
        |> Dom.addClass "cell-wrapper"
        |> Dom.addAttributeList
            (case head (List.filter (\( _, o, _ ) -> o) cellValue.rooms) of
                Just ( ref, _, turns ) ->
                    [ attribute "data-board-ref" (Maybe.withDefault "" (refToString ref))
                    , class ("rotate-" ++ String.fromInt turns)
                    ]

                Nothing ->
                    []
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


cellValueToString : Cell -> String
cellValueToString val =
    {- if val.hidden then
           "hidden"

       else
    -}
    if val.passable == True then
        "passable"

    else
        "impassable"



{-
   findPlayerByCell : Int -> Int -> List Player -> Maybe Player
   findPlayerByCell x y players =
       List.head (List.filter (\p -> p.x == x && p.y == y) players)


   findBoardPieceByCell : Int -> Int -> List MapTile -> Maybe MapTile
   findBoardPieceByCell x y pieces =
       List.head (List.filter (\p -> p.x == x && p.y == y) pieces)


   playerToString : Player -> String
   playerToString player =
       case player.class of
           Brute ->
               "Brute"

           Cragheart ->
               "Cragheart"

           Mindthief ->
               "Mindthief"

           Scoundrel ->
               "Scoundrel"

           Spellweaver ->
               "Spellweaver"

           Tinkerer ->
               "Tinkerer"

-}


filterOverlaysForCoord : Int -> Int -> BoardOverlay -> Bool
filterOverlaysForCoord x y overlay =
    case head overlay.cells of
        Just ( oX, oY ) ->
            oX == x && oY == y

        Nothing ->
            False


getPieceForCoord : Int -> Int -> List Piece -> Maybe Piece
getPieceForCoord x y pieces =
    List.filter (\p -> p.x == x && p.y == y) pieces
        |> head


pieceToHtml : Model -> Int -> Int -> Piece -> Element Msg
pieceToHtml model x y piece =
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

                        Summons _ _ ->
                            Dom.appendChild (Dom.element "div")

                Game.None ->
                    Dom.addClass "none"
           )
        |> DragDrop.makeDraggable model.dragDropState (MoveablePiece (PieceType piece) x y) dragDropMessages


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


overlayToHtml : Int -> Int -> BoardOverlay -> Element msg
overlayToHtml x y overlay =
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

                Door _ ->
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
                |> Dom.addAttribute (attribute "src" (getOverlayImageName overlay x y))
            )


getOverlayImageName : BoardOverlay -> Int -> Int -> String
getOverlayImageName overlay x y =
    let
        path =
            "/img/overlays/"

        overlayName =
            getBoardOverlayName overlay.ref

        extension =
            ".png"

        extendedOverlayName =
            case overlay.ref of
                Door d ->
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
            case overlay.cells of
                _ :: ( overlayX, overlayY ) :: _ ->
                    if overlayX == x && overlayY == y then
                        "-2"

                    else
                        ""

                _ ->
                    ""
    in
    path ++ overlayName ++ extendedOverlayName ++ segmentPart ++ extension
