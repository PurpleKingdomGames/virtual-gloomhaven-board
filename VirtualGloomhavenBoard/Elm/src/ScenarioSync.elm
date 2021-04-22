module ScenarioSync exposing (decodeScenario, encodeScenario, loadScenarioById)

import BoardMapTile exposing (refToString, stringToRef)
import BoardOverlay exposing (BoardOverlayDirectionType, CorridorMaterial(..), CorridorSize(..), DoorSubType(..))
import Game exposing (Expansion(..), GameStateScenario(..))
import Http exposing (Error, expectJson)
import Json.Decode exposing (Decoder, andThen, fail, field, float, int, lazy, list, map5, map6, map7, string, succeed)
import Json.Encode as Encode exposing (object)
import List exposing (all, filterMap, map)
import Monster exposing (Monster, MonsterLevel(..), MonsterType, monsterTypeToString, stringToMonsterType)
import Scenario exposing (DoorData(..), MapTileData, Scenario, ScenarioMonster)
import SharedSync exposing (decodeBoardOverlay, decodeBoardOverlayDirection, decodeDoor, decodeMonsterLevel, decodeScenarioMonster, encodeMonsters, encodeOverlayDirection, encodeOverlays)


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


encodeScenario : Scenario -> Encode.Value
encodeScenario scenario =
    object
        [ ( "id", Encode.int scenario.id )
        , ( "title", Encode.string scenario.title )
        , ( "mapTileData", Encode.object (encodeMapTileData scenario.mapTilesData) )
        , ( "angle", Encode.float scenario.angle )
        , ( "additionalMonsters", Encode.list Encode.string (encodeAdditionalMonsters scenario.additionalMonsters) )
        ]


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

                _ ->
                    0
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


encodeAdditionalMonsters : List MonsterType -> List String
encodeAdditionalMonsters monsters =
    List.filterMap
        (\m -> monsterTypeToString m)
        monsters


encodeMapTileData : MapTileData -> List ( String, Encode.Value )
encodeMapTileData mapTileData =
    [ ( "ref"
      , case refToString mapTileData.ref of
            Just s ->
                Encode.string s

            Nothing ->
                Encode.null
      )
    , ( "doors", Encode.list Encode.object (encodeDoors mapTileData.doors) )
    , ( "overlays", Encode.list Encode.object (encodeOverlays mapTileData.overlays) )
    , ( "monsters", Encode.list Encode.object (encodeMonsters mapTileData.monsters) )
    , ( "turns", Encode.int mapTileData.turns )
    ]


encodeDoors : List DoorData -> List (List ( String, Encode.Value ))
encodeDoors doors =
    List.map
        (\d ->
            case d of
                DoorLink subType direction ( room1X, room1Y ) ( room2X, room2Y ) mapTileData ->
                    encodeDoor subType
                        ++ [ ( "direction", Encode.string (encodeOverlayDirection direction) )
                           , ( "room1X", Encode.int room1X )
                           , ( "room1Y", Encode.int room1Y )
                           , ( "room2X", Encode.int room2X )
                           , ( "room2Y", Encode.int room2Y )
                           , ( "mapTileData", Encode.object (encodeMapTileData mapTileData) )
                           ]
        )
        doors


encodeDoor : DoorSubType -> List ( String, Encode.Value )
encodeDoor doorType =
    case doorType of
        Corridor material size ->
            [ ( "subType", Encode.string "corridor" )
            , ( "material"
              , Encode.string
                    (case material of
                        Dark ->
                            "dark"

                        Earth ->
                            "earth"

                        ManmadeStone ->
                            "manmade-stone"

                        NaturalStone ->
                            "natural-stone"

                        PressurePlate ->
                            "pressure-plate"

                        Wood ->
                            "wood"
                    )
              )
            , ( "size"
              , Encode.int
                    (case size of
                        One ->
                            1

                        Two ->
                            2
                    )
              )
            ]

        AltarDoor ->
            [ ( "subType", Encode.string "altar" ) ]

        BreakableWall ->
            [ ( "subType", Encode.string "breakable-wall" ) ]

        DarkFog ->
            [ ( "subType", Encode.string "dark-fog" ) ]

        LightFog ->
            [ ( "subType", Encode.string "light-fog" ) ]

        Stone ->
            [ ( "subType", Encode.string "stone" ) ]

        Wooden ->
            [ ( "subType", Encode.string "wooden" ) ]
