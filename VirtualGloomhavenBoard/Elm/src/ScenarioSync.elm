module ScenarioSync exposing (decodeScenario, loadScenarioById)

import BoardMapTile exposing (stringToRef)
import BoardOverlay exposing (BoardOverlayDirectionType, DoorSubType)
import Game exposing (Expansion(..), GameStateScenario(..))
import Http exposing (Error, expectJson, get)
import Json.Decode exposing (Decoder, andThen, fail, field, float, int, lazy, list, map5, map6, map7, string, succeed)
import List exposing (all, filterMap, map)
import Monster exposing (Monster, MonsterType, stringToMonsterType)
import Scenario exposing (DoorData(..), MapTileData, Scenario, ScenarioMonster)
import SharedSync exposing (decodeBoardOverlay, decodeBoardOverlayDirection, decodeDoor, decodeMonsterLevel)


type alias DoorDataObj =
    { subType : DoorSubType
    , dir : BoardOverlayDirectionType
    , room1X : Int
    , room1Y : Int
    , room2X : Int
    , room2Y : Int
    , mapTilesData : MapTileData
    }


decodeScenario : Decoder Scenario
decodeScenario =
    map5 Scenario
        (field "id" int)
        (field "title" string)
        (field "mapTileData" decodeMapTileData)
        (field "angle" float)
        (field "additionalMonsters" (list string) |> andThen decodeMonsterList)


loadScenarioById : GameStateScenario -> (Result Error Scenario -> msg) -> Cmd msg
loadScenarioById scenario msg =
    let
        path =
            "/data/scenarios/"
                ++ (case scenario of
                        InbuiltScenario Solo _ ->
                            "solo/"

                        _ ->
                            ""
                   )

        id =
            case scenario of
                InbuiltScenario _ i ->
                    i
    in
    Http.get
        { url = path ++ String.fromInt id ++ ".json"
        , expect = expectJson msg decodeScenario
        }


decodeMonsterList : List String -> Decoder (List MonsterType)
decodeMonsterList monsters =
    let
        decodedRefs =
            map (\ref -> stringToMonsterType ref) monsters
    in
    if all (\s -> s /= Nothing) decodedRefs then
        succeed (filterMap (\m -> m) decodedRefs)

    else
        fail "Could not decode all monster references"


decodeMapTileData : Decoder MapTileData
decodeMapTileData =
    map5 MapTileData
        (field "ref" string
            |> andThen
                (\r ->
                    case stringToRef r of
                        Just ref ->
                            succeed ref

                        Nothing ->
                            fail ("Could not find tile reference " ++ r)
                )
        )
        (field "doors" (list decodeDoors))
        (field "overlays" (list decodeBoardOverlay))
        (field "monsters" (list decodeScenarioMonster))
        (field "turns" int)


decodeDoors : Decoder DoorData
decodeDoors =
    map7 DoorDataObj
        decodeDoor
        (field "direction" string |> andThen decodeBoardOverlayDirection)
        (field "room1X" int)
        (field "room1Y" int)
        (field "room2X" int)
        (field "room2Y" int)
        (field "mapTileData" (lazy (\_ -> decodeMapTileData)))
        |> andThen
            (\d ->
                succeed (DoorLink d.subType d.dir ( d.room1X, d.room1Y ) ( d.room2X, d.room2Y ) d.mapTilesData)
            )


decodeScenarioMonster : Decoder ScenarioMonster
decodeScenarioMonster =
    map6 ScenarioMonster
        (field "monster" string
            |> andThen
                (\m ->
                    case stringToMonsterType m of
                        Just monster ->
                            succeed (Monster monster 0 Monster.None False)

                        Nothing ->
                            fail ("Could not decode monster " ++ m)
                )
        )
        (field "initialX" int)
        (field "initialY" int)
        (field "twoPlayer" string |> andThen decodeMonsterLevel)
        (field "threePlayer" string |> andThen decodeMonsterLevel)
        (field "fourPlayer" string |> andThen decodeMonsterLevel)
