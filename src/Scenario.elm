module Scenario exposing (DoorData(..), MapTileData, Scenario, mapTileDataToList)

import Array exposing (Array, indexedMap, toList)
import BoardMapTiles exposing (MapTile, MapTileRef, getGridByRef)
import BoardOverlays exposing (BoardOverlay, DoorSubType)
import Hexagon exposing (rotate)


type alias MapTileData =
    { ref : MapTileRef
    , doors : List DoorData
    , overlays : List BoardOverlay
    }


type DoorData
    = DoorLink DoorSubType ( Int, Int ) ( Int, Int ) Int MapTileData


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
        DoorLink _ refPoint origin turns mapTileData ->
            let
                mapTiles =
                    mapTileDataToList mapTileData
            in
            List.map (normaliseAndRotateMapTile turns refPoint origin) mapTiles


normaliseAndRotateMapTile : Int -> ( Int, Int ) -> ( Int, Int ) -> MapTile -> MapTile
normaliseAndRotateMapTile turns ( refPointX, refPointY ) ( originX, originY ) mapTile =
    let
        initX =
            mapTile.x - originX + refPointX

        initY =
            mapTile.y - originY + refPointY

        ( rotatedX, rotatedY ) =
            Hexagon.rotate ( initX, initY ) ( refPointX, refPointY ) turns
    in
    { mapTile | x = rotatedX, y = rotatedY }


indexedArrayYToMapTile : MapTileRef -> Int -> Array Bool -> List MapTile
indexedArrayYToMapTile ref y arr =
    Array.indexedMap (indexedArrayXToMapTile ref y) arr
        |> Array.toList


indexedArrayXToMapTile : MapTileRef -> Int -> Int -> Bool -> MapTile
indexedArrayXToMapTile ref y x passable =
    MapTile ref x y passable True
