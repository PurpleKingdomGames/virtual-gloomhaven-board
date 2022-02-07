module SpecialRules exposing (scenario101DoorUpdate)

import BoardMapTile exposing (MapTileRef(..))
import BoardOverlay exposing (BoardOverlay, BoardOverlayType(..), CorridorMaterial(..), DoorSubType(..))
import Game exposing (GameState)
import List exposing (any, filterMap)


scenario101DoorUpdate : GameState -> GameState
scenario101DoorUpdate state =
    removeJ1bbFog state
        |> removeJ1bFog


removeJ1bbFog : GameState -> GameState
removeJ1bbFog state =
    let
        shouldRemove =
            any (\r -> r == J1ba) state.visibleRooms
                && any (\r -> r == J1bb) state.visibleRooms
    in
    if shouldRemove then
        { state | overlays = removeFog [ ( 9, 10 ), ( 8, 9 ), ( 8, 8 ) ] state.overlays }

    else
        state


removeJ1bFog : GameState -> GameState
removeJ1bFog state =
    let
        shouldRemove =
            any (\r -> r == J1ba) state.visibleRooms
                && any (\r -> r == J1b) state.visibleRooms
    in
    if shouldRemove then
        { state | overlays = removeFog [ ( 4, 11 ), ( 5, 10 ), ( 4, 9 ) ] state.overlays }

    else
        state


removeFog : List ( Int, Int ) -> List BoardOverlay -> List BoardOverlay
removeFog cells overlays =
    filterMap
        (\o ->
            if any (\c -> any (\c1 -> c1 == c) cells) o.cells then
                case o.ref of
                    Door DarkFog _ ->
                        Nothing

                    _ ->
                        Just o

            else
                Just o
        )
        overlays
