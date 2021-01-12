module Creator exposing (main)

import AppStorage exposing (MoveablePiece)
import BoardHtml exposing (getAllMapTileHtml)
import BoardMapTile exposing (getAllRefs, refToString)
import Browser
import Dom
import DragPorts
import Game exposing (RoomData)
import Html exposing (Html, div, img, li, ul)
import Html.Attributes exposing (alt, attribute, class, id, src)
import Html.Events.Extra.Drag as DragDrop
import Html.Events.Extra.Touch as Touch
import Html.Lazy exposing (lazy)
import List


type alias Model =
    { roomData : List RoomData
    , currentDraggable : Maybe MoveablePiece
    }


type Msg
    = TouchCanceled
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
    ( Model [] Nothing
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TouchCanceled ->
            ( model, Cmd.none )

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
