module Scenario exposing (Scenario, mapTileDataToArray)

import Array exposing (indexedMap, toList)
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
            Array.indexedMap (indexedArrayXToMapTile data.ref) (getGridByRef data.ref)
                |> Array.toList
                |> List.concat

        doorTiles =
            List.map mapDoorDataToList data.doors
    in
    mapTiles ++ doorTiles


mapDoorDataToList : DoorData -> List MapTile
mapDoorDataToList ( _, refPoint, origin, angle, mapTileData ) =
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
            Point (mapTile.x - origin.x + refPoint.x) (mapTile.y - origin.y + refPoint.y)
                |> Point.rotate refPoint radians
    in
    { mapTile | x = newPoint.x, y = newPoint.y }


indexedArrayXToMapTile : MapTileRef -> Int -> Array Bool -> Array MapTile
indexedArrayXToMapTile ref x arr =
    Array.indexedMap (indexedArrayYToMapTile ref x) arr


indexedArrayYToMapTile : MapTileRef -> Int -> Int -> Bool -> MapTile
indexedArrayYToMapTile ref x y passable =
    MapTile ref x y passable True
