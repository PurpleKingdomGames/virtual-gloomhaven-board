module Main exposing (main)

import Array exposing (..)
import BoardMapTile exposing (MapTile, MapTileRef(..), getGridByRef, refToString)
import BoardOverlay exposing (BoardOverlay, BoardOverlayDirectionType(..), BoardOverlayType(..), DoorSubType(..), ObstacleSubType(..), TrapSubType(..), TreasureSubType(..), getBoardOverlayName)
import Browser
import Dom exposing (Element)
import Dom.DragDrop as DragDrop
import Game exposing (AIType(..), Cell, NumPlayers(..), PieceType(..), generateGameMap, getPieceName, getPieceType)
import Html exposing (div)
import Html.Attributes exposing (attribute, class, src)
import List exposing (filter, head)
import Monster exposing (BossType(..), Monster, MonsterLevel(..), MonsterType(..), NormalMonsterType(..), getMonsterName)
import Scenario exposing (DoorData(..), MapTileData, Scenario, ScenarioMonster)


type alias Model =
    { board : Array (Array Cell)
    , dragDropState : DragDrop.State PieceType ( Int, Int )
    }


type Msg
    = MoveStarted PieceType
    | MoveTargetChanged ( Int, Int )
    | MoveCanceled
    | MoveCompleted PieceType ( Int, Int )


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
                            [ DoorLink Stone DiagonalRight ( 0, 0 ) ( 3, 0 ) (MapTileData A4b [] [ BoardOverlay (Treasure (Chest 67)) Default ( ( 0, 2 ), Nothing ) ] [] 5)
                            , DoorLink Stone DiagonalLeft ( 5, 0 ) ( 1, 0 ) (MapTileData A2a [] [] [] 1)
                            , DoorLink Stone Vertical ( -1, 3 ) ( 4, 1 ) (MapTileData A1a [] [] [] 3)
                            , DoorLink Stone Vertical ( 5, 3 ) ( -1, 1 ) (MapTileData A3b [] [] [] 3)
                            ]
                            [ BoardOverlay (Obstacle Sarcophagus) Default ( ( 3, 2 ), Just ( 2, 2 ) )
                            , BoardOverlay (Obstacle Sarcophagus) DiagonalLeft ( ( 1, 5 ), Just ( 1, 4 ) )
                            , BoardOverlay (Obstacle Sarcophagus) DiagonalRight ( ( 3, 5 ), Just ( 4, 4 ) )
                            ]
                            [ ScenarioMonster (Monster (NormalType BanditArcher) 0 Normal) 1 1 Elite Elite Elite
                            , ScenarioMonster (Monster (BossType BanditCommander) 0 Normal) 2 1 Normal Normal Normal
                            , ScenarioMonster (Monster (NormalType BanditArcher) 0 Normal) 3 1 Monster.None Normal Elite
                            ]
                            3
                        )
                    ]
                    [ BoardOverlay (Trap BearTrap) Default ( ( 0, 1 ), Nothing )
                    , BoardOverlay (Trap BearTrap) Default ( ( 2, 1 ), Nothing )
                    , BoardOverlay StartingLocation Default ( ( 0, 3 ), Nothing )
                    , BoardOverlay StartingLocation Default ( ( 1, 3 ), Nothing )
                    , BoardOverlay StartingLocation Default ( ( 2, 3 ), Nothing )
                    , BoardOverlay StartingLocation Default ( ( 1, 2 ), Nothing )
                    , BoardOverlay StartingLocation Default ( ( 2, 2 ), Nothing )
                    ]
                    [ ScenarioMonster (Monster (NormalType BanditArcher) 0 Monster.None) 0 0 Normal Normal Normal
                    , ScenarioMonster (Monster (NormalType BanditArcher) 0 Monster.None) 1 0 Monster.None Monster.None Normal
                    , ScenarioMonster (Monster (NormalType BanditArcher) 0 Monster.None) 2 0 Monster.None Normal Normal
                    , ScenarioMonster (Monster (NormalType BanditArcher) 0 Monster.None) 3 0 Normal Normal Normal
                    ]
                    3
                )
                0
    in
    ( Model (generateGameMap scenario ThreePlayer) DragDrop.initialState, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MoveStarted character ->
            ( { model | dragDropState = DragDrop.startDragging model.dragDropState character }, Cmd.none )

        MoveTargetChanged coords ->
            ( { model | dragDropState = DragDrop.updateDropTarget model.dragDropState coords }, Cmd.none )

        MoveCanceled ->
            ( { model | dragDropState = DragDrop.stopDragging model.dragDropState }, Cmd.none )

        MoveCompleted character ( x, y ) ->
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
            ( model, Cmd.none )


view : Model -> Html.Html Msg
view model =
    div [ class "board" ] (toList (Array.indexedMap (getBoardHtml model) model.board))


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


getBoardHtml : Model -> Int -> Array Cell -> Html.Html Msg
getBoardHtml model y row =
    div [ class "row" ] (toList (Array.indexedMap (getCellHtml model y) row))


getCellHtml : Model -> Int -> Int -> Cell -> Html.Html Msg
getCellHtml model y x cellValue =
    let
        dragDropMessages : DragDrop.Messages Msg PieceType ( Int, Int )
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
                    (List.map (overlayToHtml x y)
                        (List.filter
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
                            cellValue.overlays
                        )
                    )
                |> Dom.appendChildList
                    (case cellValue.piece of
                        Game.None ->
                            []

                        p ->
                            [ pieceToHtml p ]
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
                    [ attribute "data-board-ref" (refToString ref)
                    , class ("rotate-" ++ String.fromInt turns)
                    ]

                Nothing ->
                    []
            )
        |> Dom.appendChild
            (Dom.element "div"
                |> Dom.addClass "cell"
                |> Dom.appendChild
                    (if cellValue.passable && cellValue.hidden == False then
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
    if val.passable then
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


pieceToHtml : PieceType -> Element msg
pieceToHtml piece =
    Dom.element "div"
        |> Dom.addClass (getPieceType piece)
        |> Dom.addClass (getPieceName piece)
        |> (case piece of
                Player _ ->
                    Dom.appendChild (Dom.element "div")

                AI t ->
                    case t of
                        Enemy m ->
                            enemyToHtml m

                        Summons _ ->
                            Dom.appendChild (Dom.element "div")

                Game.None ->
                    Dom.addClass "none"
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
                            ++ getMonsterName monster.monster
                            ++ ".png"
                        )
                    )
            , Dom.element "span"
                |> Dom.appendText (String.fromInt monster.id)
            ]


overlayToHtml : Int -> Int -> BoardOverlay -> Element msg
overlayToHtml x y overlay =
    Dom.element "img"
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
        |> Dom.addAttribute (attribute "src" (getOverlayImageName overlay x y))


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
            case Tuple.second overlay.cells of
                Just ( overlayX, overlayY ) ->
                    if overlayX == x && overlayY == y then
                        "-2"

                    else
                        ""

                Nothing ->
                    ""
    in
    path ++ overlayName ++ extendedOverlayName ++ segmentPart ++ extension
