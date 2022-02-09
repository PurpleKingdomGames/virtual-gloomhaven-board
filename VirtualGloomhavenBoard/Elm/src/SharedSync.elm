module SharedSync exposing (decodeBoardOverlay, decodeBoardOverlayDirection, decodeCoords, decodeDoor, decodeMapRefList, decodeMonster, decodeMonsterLevel, decodeScenarioMonster, encodeCoords, encodeMapTileRefList, encodeMonsters, encodeOverlay, encodeOverlayDirection, encodeOverlays)

import BoardMapTile exposing (MapTileRef(..), refToString, stringToRef)
import BoardOverlay exposing (BoardOverlay, BoardOverlayDirectionType(..), BoardOverlayType(..), ChestType(..), CorridorMaterial(..), CorridorSize(..), DifficultTerrainSubType(..), DoorSubType(..), HazardSubType(..), ObstacleSubType(..), TrapSubType(..), TreasureSubType(..), WallSubType(..))
import Colour
import Html.Attributes exposing (id)
import Json.Decode as Decode exposing (Decoder, andThen, fail, field, index, map2, map4, map5, map6, maybe, succeed)
import Json.Encode as Encode exposing (object)
import List exposing (all, map)
import Monster exposing (Monster, MonsterLevel(..), MonsterType, monsterTypeToString, stringToMonsterType)
import Scenario exposing (ScenarioMonster)


encodeOverlays : List BoardOverlay -> List (List ( String, Encode.Value ))
encodeOverlays overlays =
    List.map encodeOverlay overlays


encodeOverlay : BoardOverlay -> List ( String, Encode.Value )
encodeOverlay o =
    [ ( "ref", encodeOverlayType o.ref )
    , ( "id", Encode.int o.id )
    , ( "direction", Encode.string (encodeOverlayDirection o.direction) )
    , ( "cells", Encode.list (Encode.list Encode.int) (encodeOverlayCells o.cells) )
    ]


encodeOverlayDirection : BoardOverlayDirectionType -> String
encodeOverlayDirection dir =
    case dir of
        Default ->
            "default"

        DiagonalLeft ->
            "diagonal-left"

        DiagonalRight ->
            "diagonal-right"

        DiagonalLeftReverse ->
            "diagonal-left-reverse"

        DiagonalRightReverse ->
            "diagonal-right-reverse"

        Horizontal ->
            "horizontal"

        Vertical ->
            "vertical"

        VerticalReverse ->
            "vertical-reverse"


encodeOverlayCells : List ( Int, Int ) -> List (List Int)
encodeOverlayCells cells =
    List.map (\( a, b ) -> [ a, b ]) cells


encodeOverlayType : BoardOverlayType -> Encode.Value
encodeOverlayType overlay =
    case overlay of
        DifficultTerrain d ->
            object
                [ ( "type", Encode.string "difficult-terrain" )
                , ( "subType", Encode.string (encodeDifficultTerrain d) )
                ]

        Door (Corridor m i) refs ->
            object
                [ ( "type", Encode.string "door" )
                , ( "subType", Encode.string "corridor" )
                , ( "material", Encode.string (encodeMaterial m) )
                , ( "size", Encode.int (encodeSize i) )
                , ( "links", Encode.list Encode.string (encodeMapTileRefList refs) )
                ]

        Door s refs ->
            object
                [ ( "type", Encode.string "door" )
                , ( "subType", Encode.string (encodeDoor s) )
                , ( "links", Encode.list Encode.string (encodeMapTileRefList refs) )
                ]

        Hazard h ->
            object
                [ ( "type", Encode.string "hazard" )
                , ( "subType", Encode.string (encodeHazard h) )
                ]

        Highlight c ->
            object
                [ ( "type", Encode.string "highlight" )
                , ( "colour", Encode.string (Colour.toHexString c) )
                ]

        Obstacle o ->
            object
                [ ( "type", Encode.string "obstacle" )
                , ( "subType", Encode.string (encodeObstacle o) )
                ]

        Rift ->
            object [ ( "type", Encode.string "rift" ) ]

        StartingLocation ->
            object [ ( "type", Encode.string "starting-location" ) ]

        Trap t ->
            object
                [ ( "type", Encode.string "trap" )
                , ( "subType", Encode.string (encodeTrap t) )
                ]

        Treasure t ->
            object
                (( "type", Encode.string "treasure" )
                    :: encodeTreasure t
                )

        Token t ->
            object
                [ ( "type", Encode.string "token" )
                , ( "value", Encode.string t )
                ]

        Wall w ->
            object
                [ ( "type", Encode.string "wall" )
                , ( "subType", Encode.string (encodeWall w) )
                ]


encodeDoor : DoorSubType -> String
encodeDoor door =
    case door of
        AltarDoor ->
            "altar"

        Stone ->
            "stone"

        Wooden ->
            "wooden"

        BreakableWall ->
            "breakable-wall"

        Corridor _ _ ->
            "corridor"

        DarkFog ->
            "dark-fog"

        LightFog ->
            "light-fog"


encodeMaterial : CorridorMaterial -> String
encodeMaterial m =
    case m of
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


encodeSize : CorridorSize -> Int
encodeSize i =
    case i of
        One ->
            1

        Two ->
            2


encodeTrap : TrapSubType -> String
encodeTrap trap =
    case trap of
        BearTrap ->
            "bear"

        Spike ->
            "spike"

        Poison ->
            "poison"


encodeDifficultTerrain : DifficultTerrainSubType -> String
encodeDifficultTerrain terrain =
    case terrain of
        Log ->
            "log"

        Rubble ->
            "rubble"

        Stairs ->
            "stairs"

        VerticalStairs ->
            "stairs-vert"

        Water ->
            "water"


encodeHazard : HazardSubType -> String
encodeHazard hazard =
    case hazard of
        HotCoals ->
            "hot-coals"

        Thorns ->
            "thorns"


encodeObstacle : ObstacleSubType -> String
encodeObstacle obstacle =
    case obstacle of
        Altar ->
            "altar"

        Barrel ->
            "barrel"

        Bookcase ->
            "bookcase"

        Boulder1 ->
            "boulder-1"

        Boulder2 ->
            "boulder-2"

        Boulder3 ->
            "boulder-3"

        Bush ->
            "bush"

        Cabinet ->
            "cabinet"

        Crate ->
            "crate"

        Crystal ->
            "crystal"

        DarkPit ->
            "dark-pit"

        Fountain ->
            "fountain"

        Mirror ->
            "mirror"

        Nest ->
            "nest"

        Pillar ->
            "pillar"

        RockColumn ->
            "rock-column"

        Sarcophagus ->
            "sarcophagus"

        Shelf ->
            "shelf"

        Stalagmites ->
            "stalagmites"

        Stump ->
            "stump"

        Table ->
            "table"

        Totem ->
            "totem"

        Tree3 ->
            "tree-3"

        WallSection ->
            "wall-section"


encodeTreasure : TreasureSubType -> List ( String, Encode.Value )
encodeTreasure treasure =
    case treasure of
        Chest c ->
            [ ( "subType", Encode.string "chest" )
            , ( "id", Encode.string (encodeTreasureChest c) )
            ]

        Coin i ->
            [ ( "subType", Encode.string "coin" )
            , ( "amount", Encode.int i )
            ]


encodeWall : WallSubType -> String
encodeWall wallType =
    case wallType of
        HugeRock ->
            "huge-rock"

        Iron ->
            "iron"

        LargeRock ->
            "large-rock"

        ObsidianGlass ->
            "obsidian-glass"

        Rock ->
            "rock"


encodeTreasureChest : ChestType -> String
encodeTreasureChest chest =
    case chest of
        NormalChest i ->
            String.fromInt i

        Goal ->
            "goal"

        Locked ->
            "locked"


encodeMonsters : List ScenarioMonster -> List (List ( String, Encode.Value ))
encodeMonsters monsters =
    List.filterMap
        (\m ->
            Maybe.map
                (\t ->
                    [ ( "monster", Encode.string t )
                    , ( "initialX", Encode.int m.initialX )
                    , ( "initialY", Encode.int m.initialY )
                    , ( "twoPlayer", Encode.string (encodeMonsterLevel m.twoPlayer) )
                    , ( "threePlayer", Encode.string (encodeMonsterLevel m.threePlayer) )
                    , ( "fourPlayer", Encode.string (encodeMonsterLevel m.fourPlayer) )
                    ]
                )
                (monsterTypeToString m.monster.monster)
        )
        monsters


encodeMonsterLevel : MonsterLevel -> String
encodeMonsterLevel monsterLevel =
    case monsterLevel of
        None ->
            "none"

        Normal ->
            "normal"

        Elite ->
            "elite"


encodeMapTileRefList : List MapTileRef -> List String
encodeMapTileRefList refs =
    List.map (\r -> refToString r) refs
        |> List.filter (\r -> r /= Nothing)
        |> List.map (\r -> Maybe.withDefault "" r)


decodeDoor : Decoder DoorSubType
decodeDoor =
    field "subType" Decode.string
        |> andThen
            (\s ->
                case String.toLower s of
                    "altar" ->
                        succeed AltarDoor

                    "stone" ->
                        succeed Stone

                    "wooden" ->
                        succeed Wooden

                    "breakable-wall" ->
                        succeed BreakableWall

                    "corridor" ->
                        decodeCorridor

                    "dark-fog" ->
                        succeed DarkFog

                    "light-fog" ->
                        succeed LightFog

                    _ ->
                        fail (s ++ " is not a door sub-type")
            )


decodeCorridor : Decoder DoorSubType
decodeCorridor =
    field "material" Decode.string
        |> andThen
            (\m ->
                let
                    material =
                        case String.toLower m of
                            "dark" ->
                                Just Dark

                            "earth" ->
                                Just Earth

                            "manmade-stone" ->
                                Just ManmadeStone

                            "natural-stone" ->
                                Just NaturalStone

                            "pressure-plate" ->
                                Just PressurePlate

                            "wood" ->
                                Just Wood

                            _ ->
                                Nothing
                in
                case material of
                    Just mm ->
                        decodeCorridorSize mm

                    Nothing ->
                        fail ("Could not decode material '" ++ m ++ "'")
            )


decodeCorridorSize : CorridorMaterial -> Decoder DoorSubType
decodeCorridorSize material =
    field "size" Decode.int
        |> andThen
            (\s ->
                case s of
                    1 ->
                        succeed (Corridor material One)

                    2 ->
                        succeed (Corridor material Two)

                    _ ->
                        fail (String.fromInt s ++ " is not a valid corridor size")
            )


decodeMapRefList : List String -> Decoder (List MapTileRef)
decodeMapRefList refs =
    let
        decodedRefs =
            map (\ref -> stringToRef ref) refs
    in
    if all (\s -> s /= Nothing) decodedRefs then
        succeed (map (\r -> Maybe.withDefault A1a r) decodedRefs)

    else
        fail "Could not decode all map tile references"


decodeBoardOverlay : Decoder BoardOverlay
decodeBoardOverlay =
    map4 BoardOverlay
        (field "ref" decodeBoardOverlayType)
        (maybe (field "id" Decode.int)
            |> andThen
                (\id ->
                    case id of
                        Just i ->
                            succeed i

                        Nothing ->
                            succeed 0
                )
        )
        (field "direction" Decode.string |> andThen decodeBoardOverlayDirection)
        (field "cells" (Decode.list (map2 Tuple.pair (index 0 Decode.int) (index 1 Decode.int))))


decodeBoardOverlayType : Decoder BoardOverlayType
decodeBoardOverlayType =
    let
        decodeType typeName =
            case String.toLower typeName of
                "door" ->
                    decodeDoor
                        |> andThen decodeDoorRefs

                "difficult-terrain" ->
                    decodeDifficultTerrain

                "hazard" ->
                    decodeHazard

                "highlight" ->
                    field "colour" Decode.string
                        |> andThen (\c -> succeed (Highlight (Colour.fromHexString c)))

                "obstacle" ->
                    decodeObstacle

                "rift" ->
                    succeed Rift

                "starting-location" ->
                    succeed StartingLocation

                "trap" ->
                    decodeTrap

                "treasure" ->
                    decodeTreasure

                "token" ->
                    decodeToken

                "wall" ->
                    decodeWall

                _ ->
                    fail ("Unknown overlay type: " ++ typeName)
    in
    field "type" Decode.string
        |> andThen decodeType


decodeDoorRefs : DoorSubType -> Decoder BoardOverlayType
decodeDoorRefs subType =
    field "links" (Decode.list Decode.string)
        |> andThen decodeMapRefList
        |> andThen (\refs -> succeed (Door subType refs))


decodeTrap : Decoder BoardOverlayType
decodeTrap =
    field "subType" Decode.string
        |> andThen
            (\s ->
                case String.toLower s of
                    "bear" ->
                        succeed (Trap BearTrap)

                    "spike" ->
                        succeed (Trap Spike)

                    "poison" ->
                        succeed (Trap Poison)

                    _ ->
                        fail (s ++ " is not a trap sub-type")
            )


decodeHazard : Decoder BoardOverlayType
decodeHazard =
    field "subType" Decode.string
        |> andThen
            (\s ->
                case String.toLower s of
                    "hot-coals" ->
                        succeed (Hazard HotCoals)

                    "thorns" ->
                        succeed (Hazard Thorns)

                    _ ->
                        fail (s ++ " is not an hazard sub-type")
            )


decodeDifficultTerrain : Decoder BoardOverlayType
decodeDifficultTerrain =
    field "subType" Decode.string
        |> andThen
            (\s ->
                case String.toLower s of
                    "log" ->
                        succeed (DifficultTerrain Log)

                    "rubble" ->
                        succeed (DifficultTerrain Rubble)

                    "stairs" ->
                        succeed (DifficultTerrain Stairs)

                    "stairs-vert" ->
                        succeed (DifficultTerrain VerticalStairs)

                    "water" ->
                        succeed (DifficultTerrain Water)

                    _ ->
                        fail (s ++ " is not a difficult terrain sub-type")
            )


decodeObstacle : Decoder BoardOverlayType
decodeObstacle =
    field "subType" Decode.string
        |> andThen
            (\s ->
                case String.toLower s of
                    "altar" ->
                        succeed (Obstacle Altar)

                    "barrel" ->
                        succeed (Obstacle Barrel)

                    "boulder-1" ->
                        succeed (Obstacle Boulder1)

                    "boulder-2" ->
                        succeed (Obstacle Boulder2)

                    "boulder-3" ->
                        succeed (Obstacle Boulder3)

                    "bush" ->
                        succeed (Obstacle Bush)

                    "bookcase" ->
                        succeed (Obstacle Bookcase)

                    "crate" ->
                        succeed (Obstacle Crate)

                    "cabinet" ->
                        succeed (Obstacle Cabinet)

                    "crystal" ->
                        succeed (Obstacle Crystal)

                    "dark-pit" ->
                        succeed (Obstacle DarkPit)

                    "fountain" ->
                        succeed (Obstacle Fountain)

                    "mirror" ->
                        succeed (Obstacle Mirror)

                    "nest" ->
                        succeed (Obstacle Nest)

                    "pillar" ->
                        succeed (Obstacle Pillar)

                    "rock-column" ->
                        succeed (Obstacle RockColumn)

                    "sarcophagus" ->
                        succeed (Obstacle Sarcophagus)

                    "shelf" ->
                        succeed (Obstacle Shelf)

                    "stalagmites" ->
                        succeed (Obstacle Stalagmites)

                    "stump" ->
                        succeed (Obstacle Stump)

                    "table" ->
                        succeed (Obstacle Table)

                    "totem" ->
                        succeed (Obstacle Totem)

                    "tree-3" ->
                        succeed (Obstacle Tree3)

                    "wall-section" ->
                        succeed (Obstacle WallSection)

                    _ ->
                        fail (s ++ " is not an obstacle sub-type")
            )


decodeTreasure : Decoder BoardOverlayType
decodeTreasure =
    let
        decodeType typeName =
            case String.toLower typeName of
                "chest" ->
                    decodeTreasureChest

                "coin" ->
                    decodeTreasureCoin

                _ ->
                    fail ("Unknown treasure type: " ++ typeName)
    in
    field "subType" Decode.string
        |> andThen decodeType


decodeTreasureChest : Decoder BoardOverlayType
decodeTreasureChest =
    field "id" Decode.string
        |> andThen
            (\s ->
                case String.toLower s of
                    "goal" ->
                        succeed (Treasure (Chest Goal))

                    "locked" ->
                        succeed (Treasure (Chest Locked))

                    _ ->
                        case String.toInt s of
                            Just i ->
                                succeed (Treasure (Chest (NormalChest i)))

                            Nothing ->
                                fail ("Unknown treasure id '" ++ s ++ "'. Valid types are 'goal' or an Int")
            )


decodeTreasureCoin : Decoder BoardOverlayType
decodeTreasureCoin =
    field "amount" Decode.int
        |> andThen (\i -> succeed (Treasure (Coin i)))


decodeToken : Decoder BoardOverlayType
decodeToken =
    field "value" Decode.string
        |> andThen (\s -> succeed (Token s))


decodeWall : Decoder BoardOverlayType
decodeWall =
    field "subType" Decode.string
        |> andThen
            (\s ->
                case String.toLower s of
                    "huge-rock" ->
                        succeed (Wall HugeRock)

                    "iron" ->
                        succeed (Wall Iron)

                    "large-rock" ->
                        succeed (Wall LargeRock)

                    "obsidian-glass" ->
                        succeed (Wall ObsidianGlass)

                    "rock" ->
                        succeed (Wall Rock)

                    _ ->
                        fail (s ++ " is not a wall sub-type")
            )


decodeBoardOverlayDirection : String -> Decoder BoardOverlayDirectionType
decodeBoardOverlayDirection dir =
    case String.toLower dir of
        "default" ->
            succeed Default

        "horizontal" ->
            succeed Horizontal

        "vertical" ->
            succeed Vertical

        "vertical-reverse" ->
            succeed VerticalReverse

        "diagonal-left" ->
            succeed DiagonalLeft

        "diagonal-right" ->
            succeed DiagonalRight

        "diagonal-left-reverse" ->
            succeed DiagonalLeftReverse

        "diagonal-right-reverse" ->
            succeed DiagonalRightReverse

        _ ->
            fail ("Could not decode overlay direction '" ++ dir ++ "'")


decodeScenarioMonster : Decoder ScenarioMonster
decodeScenarioMonster =
    map6 ScenarioMonster
        (field "monster" Decode.string
            |> andThen
                (\m ->
                    case stringToMonsterType m of
                        Just monster ->
                            succeed (Monster monster 0 Monster.None False False)

                        Nothing ->
                            fail ("Could not decode monster " ++ m)
                )
        )
        (field "initialX" Decode.int)
        (field "initialY" Decode.int)
        (field "twoPlayer" Decode.string |> andThen decodeMonsterLevel)
        (field "threePlayer" Decode.string |> andThen decodeMonsterLevel)
        (field "fourPlayer" Decode.string |> andThen decodeMonsterLevel)


decodeMonster : Decoder Monster
decodeMonster =
    map5 Monster
        (field "class" Decode.string |> andThen decodeMonsterType)
        (field "id" Decode.int)
        (field "level" Decode.string |> andThen decodeMonsterLevel)
        (maybe (field "wasSummoned" Decode.bool) |> andThen (\s -> succeed (Maybe.withDefault False s)))
        (maybe (field "outOfPhase" Decode.bool) |> andThen (\s -> succeed (Maybe.withDefault False s)))


decodeMonsterType : String -> Decoder MonsterType
decodeMonsterType m =
    case stringToMonsterType m of
        Just mt ->
            succeed mt

        Nothing ->
            fail (m ++ " is not a valid monster type")


decodeMonsterLevel : String -> Decoder MonsterLevel
decodeMonsterLevel l =
    case String.toLower l of
        "normal" ->
            succeed Normal

        "elite" ->
            succeed Elite

        "none" ->
            succeed Monster.None

        _ ->
            fail (l ++ " is not a valid monster level")


encodeCoords : ( Int, Int ) -> List ( String, Encode.Value )
encodeCoords ( x, y ) =
    [ ( "x", Encode.int x )
    , ( "y", Encode.int y )
    ]


decodeCoords : Decoder ( Int, Int )
decodeCoords =
    field "x" Decode.int
        |> andThen
            (\x ->
                field "y" Decode.int
                    |> andThen (\y -> Decode.succeed ( x, y ))
            )
