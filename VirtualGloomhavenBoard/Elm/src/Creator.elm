port module Creator exposing (main)

import AppStorage exposing (MoveablePiece, MoveablePieceType(..))
import BoardHtml exposing (getAllMapTileHtml)
import BoardMapTile exposing (getAllRefs, refToString)
import BoardOverlay exposing (BoardOverlay)
import Browser
import Char exposing (toLocaleUpper)
import Dom
import DragPorts
import Game exposing (AIType(..), Piece, PieceType(..), RoomData, assignIdentifier, moveOverlay, moveOverlayWithoutState, movePiece, movePieceWithoutState)
import Html exposing (Html, div, img, li, ul)
import Html.Attributes exposing (alt, attribute, class, coords, id, src)
import Html.Events.Extra.Drag as DragDrop
import Html.Events.Extra.Touch as Touch
import Html.Lazy exposing (lazy)
import Json.Decode as Decode exposing (Decoder)
import List
import Monster exposing (MonsterLevel(..))
import Scenario exposing (ScenarioMonster)


port getCellFromPoint : ( Float, Float, Bool ) -> Cmd msg


port onCellFromPoint : (( Int, Int, Bool ) -> msg) -> Sub msg


type alias Model =
    { roomData : List RoomData
    , overlays : List BoardOverlay
    , monsters : List ScenarioMonster
    , currentDraggable : Maybe MoveablePiece
    }


type Msg
    = MoveStarted MoveablePiece (Maybe ( DragDrop.EffectAllowed, Decode.Value ))
    | MoveTargetChanged ( Int, Int ) (Maybe ( DragDrop.DropEffect, Decode.Value ))
    | MoveCanceled
    | MoveCompleted
    | TouchStart MoveablePiece
    | TouchMove ( Float, Float )
    | TouchCanceled
    | TouchEnd ( Float, Float )
    | NoOp


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
    ( Model [] [] [] Nothing
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
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
            let
                newDraggable =
                    case model.currentDraggable of
                        Just m ->
                            case m.ref of
                                OverlayType o prevCoords ->
                                    let
                                        ( _, newOverlay, newCoords ) =
                                            moveOverlayWithoutState o m.coords prevCoords coords model.overlays

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
                                        pieces =
                                            model.monsters
                                                |> List.map (\m1 -> Piece (AI (Enemy m1.monster)) m1.initialX m1.initialY)

                                        newPiece =
                                            PieceType (Tuple.second (movePieceWithoutState p m.coords coords pieces))

                                        newTarget =
                                            if newPiece == m.ref then
                                                m.target

                                            else
                                                Just coords
                                    in
                                    Just (MoveablePiece newPiece m.coords newTarget)

                                RoomType r ->
                                    Just (MoveablePiece (RoomType r) m.coords m.target)

                        Nothing ->
                            model.currentDraggable

                cmd =
                    case maybeDragOver of
                        Just ( e, v ) ->
                            DragPorts.dragover (DragDrop.overPortData e v)

                        Nothing ->
                            Cmd.none
            in
            ( { model | currentDraggable = newDraggable }, cmd )

        MoveCanceled ->
            ( { model | currentDraggable = Nothing }, Cmd.none )

        MoveCompleted ->
            let
                ( overlays, monsters, rooms ) =
                    case model.currentDraggable of
                        Just m ->
                            case ( m.ref, m.target ) of
                                ( OverlayType o prevCoords, Just coords ) ->
                                    let
                                        ( g, _, _ ) =
                                            moveOverlayWithoutState o m.coords prevCoords coords model.overlays
                                    in
                                    ( g, model.monsters, model.roomData )

                                ( PieceType p, Just target ) ->
                                    case p.ref of
                                        AI (Enemy monster) ->
                                            let
                                                pieces =
                                                    model.monsters
                                                        |> List.map (\m1 -> Piece (AI (Enemy m1.monster)) m1.initialX m1.initialY)

                                                ( newPieces, newPiece ) =
                                                    movePieceWithoutState p m.coords target pieces

                                                m2 =
                                                    List.filterMap (mapPieceToScenarioMonster newPiece model.monsters m.coords target) newPieces
                                            in
                                            ( model.overlays, m2, model.roomData )

                                        _ ->
                                            ( model.overlays, model.monsters, model.roomData )

                                ( RoomType r, Just target ) ->
                                    let
                                        room =
                                            Maybe.withDefault
                                                (RoomData r.ref ( 0, 0 ) 0)
                                                (List.filter (\d -> d.ref == r.ref) model.roomData
                                                    |> List.head
                                                )

                                        roomData =
                                            room :: List.filter (\d -> d.ref /= r.ref) model.roomData
                                    in
                                    ( model.overlays, model.monsters, roomData )

                                ( _, Nothing ) ->
                                    ( model.overlays, model.monsters, model.roomData )

                        Nothing ->
                            ( model.overlays, model.monsters, model.roomData )
            in
            ( { model | currentDraggable = Nothing, overlays = overlays, monsters = monsters, roomData = rooms }, Cmd.none )

        TouchStart piece ->
            update (MoveStarted piece Nothing) model

        TouchCanceled ->
            update MoveCanceled model

        TouchMove ( x, y ) ->
            ( model, getCellFromPoint ( x, y, False ) )

        TouchEnd ( x, y ) ->
            ( model, getCellFromPoint ( x, y, True ) )

        NoOp ->
            ( model, Cmd.none )


view : Model -> Html.Html Msg
view model =
    div
        [ class "content"
        , id "content"
        , Touch.onCancel (\_ -> TouchCanceled)
        ]
        [ div [ class "main" ]
            [ div
                [ class
                    "action-list"
                ]
                [ lazy getMapTileListHtml model.roomData
                ]
            , div
                [ class "board-wrapper" ]
                [ div [ class "map-bg" ] []
                , div
                    [ class "mapTiles" ]
                    [ lazy getAllMapTileHtml model.roomData ]
                , div [ class "board" ]
                    (List.repeat 100 (List.repeat 100 0)
                        |> List.indexedMap
                            (\y val ->
                                div [ class "row" ]
                                    (List.indexedMap (\x _ -> getCellHtml x y) val)
                            )
                    )
                ]
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch []


getCellHtml : Int -> Int -> Html msg
getCellHtml x y =
    let
        cellElement : Dom.Element msg
        cellElement =
            Dom.element "div"
                |> Dom.addClass "hexagon"
                |> Dom.addAttribute (attribute "data-cell-x" (String.fromInt x))
                |> Dom.addAttribute (attribute "data-cell-y" (String.fromInt y))
    in
    Dom.element "div"
        |> Dom.addClass "cell-wrapper"
        |> Dom.appendChild
            (Dom.element "div"
                |> Dom.addClass "cell"
                |> Dom.appendChild cellElement
            )
        |> Dom.render


getMapTileListHtml : List RoomData -> Html msg
getMapTileListHtml mapTiles =
    let
        currentRefs =
            List.map (\r -> r.ref) mapTiles
    in
    ul
        [ class "map-tiles"
        ]
        (getAllRefs
            |> List.filter (\r -> List.member r currentRefs == False)
            |> List.map
                (\r ->
                    let
                        ref =
                            Maybe.withDefault "" (refToString r)
                    in
                    li [ class ("ref-" ++ ref) ]
                        [ img
                            [ src ("/img/map-tiles/" ++ ref ++ ".png")
                            , alt ("Map tile " ++ ref)
                            ]
                            []
                        ]
                )
        )


mapPieceToScenarioMonster : Piece -> List ScenarioMonster -> Maybe ( Int, Int ) -> ( Int, Int ) -> Piece -> Maybe ScenarioMonster
mapPieceToScenarioMonster newPiece monsterList origin ( targetX, targetY ) piece =
    case ( piece.ref, piece.x, piece.y ) of
        ( AI (Enemy monster), x, y ) ->
            if piece == newPiece then
                let
                    existingMonster =
                        Maybe.withDefault
                            (ScenarioMonster monster 0 0 Normal Normal Normal)
                            (List.filter (\m -> Just ( m.initialX, m.initialY ) == origin) monsterList
                                |> List.head
                            )
                in
                Just { existingMonster | initialX = targetX, initialY = targetY }

            else
                List.filter (\m -> m.initialX == x && m.initialY == y) monsterList
                    |> List.head

        _ ->
            Nothing
