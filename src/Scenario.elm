module Scenario exposing (BoardBounds, DoorData(..), MapTileData, Scenario, mapTileDataToList, mapTileDataToOverlayList)

import BoardMapTiles exposing (MapTile, MapTileRef, getMapTileListByRef)
import BoardOverlays exposing (BoardOverlay, BoardOverlayType(..), DoorSubType)
import Hexagon exposing (rotate)
import Monster exposing (Monster)


type alias BoardBounds =
    { minX : Int
    , maxX : Int
    , minY : Int
    , maxY : Int
    }


type alias MapTileData =
    { ref : MapTileRef
    , doors : List DoorData
    , overlays : List BoardOverlay
    , monsters : List Monster
    }


type DoorData
    = DoorLink DoorSubType ( Int, Int ) ( Int, Int ) Int MapTileData


type alias Scenario =
    { id : Int
    , title : String
    , mapTilesData : MapTileData
    , angle : Float
    }


mapTileDataToOverlayList : MapTileData -> List ( MapTileRef, List BoardOverlay, List Monster )
mapTileDataToOverlayList data =
    let
        initData =
            ( data.ref
            , data.overlays
                ++ List.map
                    (\d ->
                        case d of
                            DoorLink subType ( x, y ) _ _ _ ->
                                BoardOverlay (Door subType) [ ( x, y ) ]
                    )
                    data.doors
            , data.monsters
            )

        doorData =
            List.map
                (\d ->
                    case d of
                        DoorLink _ _ _ _ map ->
                            mapTileDataToOverlayList map
                )
                data.doors
                |> List.concat
    in
    initData :: doorData


mapTileDataToList : MapTileData -> ( List MapTile, BoardBounds )
mapTileDataToList data =
    let
        mapTiles =
            getMapTileListByRef data.ref

        doorTiles =
            List.map mapDoorDataToList data.doors
                |> List.concat

        allTiles =
            mapTiles ++ doorTiles

        boundingBox =
            List.map (\m -> BoardBounds m.x m.x m.y m.y) allTiles
                |> List.foldl
                    (\a b -> BoardBounds (min a.minX b.minX) (max a.maxX b.maxX) (min a.minY b.minY) (max a.maxY b.maxY))
                    (BoardBounds 0 0 0 0)
    in
    ( allTiles, boundingBox )


mapDoorDataToList : DoorData -> List MapTile
mapDoorDataToList doorData =
    case doorData of
        DoorLink _ refPoint origin turns mapTileData ->
            let
                ( mapTiles, _ ) =
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
