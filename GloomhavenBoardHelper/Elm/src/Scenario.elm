module Scenario exposing (BoardBounds, DoorData(..), MapTileData, Scenario, ScenarioMonster, mapTileDataToList, mapTileDataToOverlayList)

import BoardMapTile exposing (MapTile, MapTileRef, getMapTileListByRef, refToString)
import BoardOverlay exposing (BoardOverlay, BoardOverlayDirectionType(..), BoardOverlayType(..), CorridorSize(..), DoorSubType(..))
import Dict exposing (Dict, empty, singleton, union)
import Hexagon exposing (rotate)
import Monster exposing (Monster, MonsterLevel, MonsterType)


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
    , monsters : List ScenarioMonster
    , turns : Int
    }


type DoorData
    = DoorLink DoorSubType BoardOverlayDirectionType ( Int, Int ) ( Int, Int ) MapTileData


type alias ScenarioMonster =
    { monster : Monster
    , initialX : Int
    , initialY : Int
    , twoPlayer : MonsterLevel
    , threePlayer : MonsterLevel
    , fourPlayer : MonsterLevel
    }


type alias Scenario =
    { id : Int
    , title : String
    , mapTilesData : MapTileData
    , angle : Float
    , additionalMonsters : List MonsterType
    }


mapTileDataToOverlayList : MapTileData -> Dict String ( List BoardOverlay, List ScenarioMonster )
mapTileDataToOverlayList data =
    let
        initData =
            case refToString data.ref of
                Just ref ->
                    ( data.overlays
                        ++ List.map
                            (\d ->
                                case d of
                                    DoorLink subType dir ( x, y ) _ l ->
                                        case subType of
                                            Corridor _ Two ->
                                                let
                                                    turns =
                                                        case dir of
                                                            DiagonalLeft ->
                                                                1

                                                            DiagonalRight ->
                                                                2

                                                            _ ->
                                                                0

                                                    coords2 =
                                                        rotate ( x, y ) ( x + 1, y ) turns
                                                in
                                                BoardOverlay (Door subType [ data.ref, l.ref ]) dir [ ( x, y ), coords2 ]

                                            _ ->
                                                BoardOverlay (Door subType [ data.ref, l.ref ]) dir [ ( x, y ) ]
                            )
                            data.doors
                    , data.monsters
                    )
                        |> singleton ref

                Nothing ->
                    empty

        doorData =
            List.map
                (\d ->
                    case d of
                        DoorLink _ _ _ _ map ->
                            mapTileDataToOverlayList map
                )
                data.doors
                |> List.foldl (\a b -> union a b) empty
    in
    union initData doorData


mapTileDataToList : MapTileData -> Maybe ( ( Int, Int ), ( Int, Int ) ) -> ( List MapTile, BoardBounds )
mapTileDataToList data maybeTurnAxis =
    let
        ( refPoint, origin ) =
            case maybeTurnAxis of
                Just ( r, o ) ->
                    ( r, o )

                Nothing ->
                    ( ( 0, 0 ), ( 0, 0 ) )

        mapTiles =
            getMapTileListByRef data.ref
                |> List.map (normaliseAndRotateMapTile data.turns refPoint origin)

        doorTiles =
            List.map (mapDoorDataToList data.ref refPoint origin data.turns) data.doors
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


mapDoorDataToList : MapTileRef -> ( Int, Int ) -> ( Int, Int ) -> Int -> DoorData -> List MapTile
mapDoorDataToList prevRef initRefPoint initOrigin initTurns doorData =
    case doorData of
        DoorLink _ _ r origin mapTileData ->
            let
                refPoint =
                    normaliseAndRotatePoint initTurns initRefPoint initOrigin r

                doorTile =
                    MapTile prevRef (Tuple.first refPoint) (Tuple.second refPoint) initTurns (Tuple.first r) (Tuple.second r) True True
            in
            Tuple.first (mapTileDataToList mapTileData (Just ( refPoint, origin )))
                |> List.append [ doorTile ]


normaliseAndRotateMapTile : Int -> ( Int, Int ) -> ( Int, Int ) -> MapTile -> MapTile
normaliseAndRotateMapTile turns refPoint origin mapTile =
    let
        ( rotatedX, rotatedY ) =
            normaliseAndRotatePoint turns refPoint origin ( mapTile.x, mapTile.y )
    in
    { mapTile | x = rotatedX, y = rotatedY, turns = turns }


normaliseAndRotatePoint : Int -> ( Int, Int ) -> ( Int, Int ) -> ( Int, Int ) -> ( Int, Int )
normaliseAndRotatePoint turns ( refPointX, refPointY ) ( originX, originY ) ( x, y ) =
    let
        initX =
            x - originX + refPointX

        initY =
            y - originY + refPointY
    in
    Hexagon.rotate ( initX, initY ) ( refPointX, refPointY ) turns
