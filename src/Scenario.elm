module Scenario exposing (DoorData(..), MapTileData, Scenario, mapTileDataToList)

import Array exposing (Array, indexedMap, toList)
import BoardMapTiles exposing (MapTile, MapTileRef, getGridByRef)
import BoardOverlays exposing (BoardOverlay, DoorSubType)
import Point exposing (Point, rotate)


type alias MapTileData =
    { ref : MapTileRef
    , doors : List DoorData
    , overlays : List BoardOverlay
    }


type DoorData
    = DoorLink DoorSubType Point Point Float MapTileData


type alias Scenario =
    { id : Int
    , title : String
    , mapTilesData : MapTileData
    , angle : Float
    }


mapTileDataToList : MapTileData -> List MapTile
mapTileDataToList data =
    let
        mapTiles =
            Array.indexedMap (indexedArrayYToMapTile data.ref) (getGridByRef data.ref)
                |> Array.toList
                |> List.concat

        doorTiles =
            List.map mapDoorDataToList data.doors
                |> List.concat
    in
    mapTiles ++ doorTiles


mapDoorDataToList : DoorData -> List MapTile
mapDoorDataToList doorData =
    case doorData of
        DoorLink _ refPoint origin angle mapTileData ->
            let
                mapTiles =
                    mapTileDataToList mapTileData

                radians =
                    angle * (pi / 2)
            in
            List.map (normaliseAndRotateMapTile radians refPoint origin) mapTiles


normaliseAndRotateMapTile : Float -> Point -> Point -> MapTile -> MapTile
normaliseAndRotateMapTile radians refPoint origin mapTile =
    let
        newPoint =
            Point (toFloat mapTile.x - origin.x + refPoint.x) (toFloat mapTile.y - origin.y + refPoint.y)
                |> Point.rotate refPoint radians
    in
    { mapTile | x = round newPoint.x, y = round newPoint.y }


indexedArrayYToMapTile : MapTileRef -> Int -> Array Bool -> List MapTile
indexedArrayYToMapTile ref y arr =
    Array.indexedMap (indexedArrayXToMapTile ref y) arr
        |> Array.toList


indexedArrayXToMapTile : MapTileRef -> Int -> Int -> Bool -> MapTile
indexedArrayXToMapTile ref y x passable =
    MapTile ref x y passable True
