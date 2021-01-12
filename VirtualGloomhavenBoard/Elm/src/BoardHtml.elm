module BoardHtml exposing (getAllMapTileHtml, getMapTileHtml)

import Bitwise
import BoardMapTile exposing (MapTileRef(..), refToString)
import Game exposing (RoomData)
import Html exposing (div, img)
import Html.Attributes exposing (alt, attribute, class, src, style)
import List exposing (any, map)
import List.Extra exposing (uniqueBy)


getMapTileHtml : List MapTileRef -> List RoomData -> Html.Html msg
getMapTileHtml visibleRooms roomData =
    div
        [ class "mapTiles" ]
        (map (getSingleMapTileHtml visibleRooms) (uniqueBy (\d -> Maybe.withDefault "" (refToString d.ref)) roomData))


getAllMapTileHtml : List RoomData -> Html.Html msg
getAllMapTileHtml roomData =
    getMapTileHtml (map (\d -> d.ref) roomData) roomData


getSingleMapTileHtml : List MapTileRef -> RoomData -> Html.Html msg
getSingleMapTileHtml visibleRooms roomData =
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

                                J1ba ->
                                    "jb"

                                J1bb ->
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
