module SharedSync exposing (decodeBoardOverlay, decodeBoardOverlayDirection, decodeDoor, decodeMapRefList, decodeMonster, decodeMonsterLevel)

import BoardMapTile exposing (MapTileRef(..), stringToRef)
import BoardOverlay exposing (BoardOverlay, BoardOverlayDirectionType(..), BoardOverlayType(..), ChestType(..), CorridorMaterial(..), CorridorSize(..), DoorSubType(..), HazardSubType(..), ObstacleSubType(..), TrapSubType(..), TreasureSubType(..))
import Json.Decode as Decode exposing (Decoder, andThen, fail, field, index, map2, map3, string, succeed)
import List exposing (all, map)
import Monster exposing (Monster, MonsterLevel(..), MonsterType, stringToMonsterType)


decodeDoor : Decoder DoorSubType
decodeDoor =
    field "subType" Decode.string
        |> andThen
            (\s ->
                case String.toLower s of
                    "stone" ->
                        succeed Stone

                    "wooden" ->
                        succeed Wooden

                    "corridor" ->
                        decodeCorridor

                    "dark-fog" ->
                        succeed DarkFog

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
                            "earth" ->
                                Just Earth

                            "manmade-stone" ->
                                Just ManmadeStone

                            "natural-stone" ->
                                Just NaturalStone

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
    map3 BoardOverlay
        (field "ref" decodeBoardOverlayType)
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

                "hazard" ->
                    decodeHazard

                "obstacle" ->
                    decodeObstacle

                "starting-location" ->
                    succeed StartingLocation

                "trap" ->
                    decodeTrap

                "treasure" ->
                    decodeTreasure

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

                    _ ->
                        fail (s ++ " is not a trap sub-type")
            )


decodeHazard : Decoder BoardOverlayType
decodeHazard =
    field "subType" Decode.string
        |> andThen
            (\s ->
                case String.toLower s of
                    "thorns" ->
                        succeed (Hazard Thorns)

                    _ ->
                        fail (s ++ " is not an hazard sub-type")
            )


decodeObstacle : Decoder BoardOverlayType
decodeObstacle =
    field "subType" Decode.string
        |> andThen
            (\s ->
                case String.toLower s of
                    "sarcophagus" ->
                        succeed (Obstacle Sarcophagus)

                    "barrel" ->
                        succeed (Obstacle Barrel)

                    "boulder-1" ->
                        succeed (Obstacle Boulder1)

                    "boulder-2" ->
                        succeed (Obstacle Boulder2)

                    "bush" ->
                        succeed (Obstacle Bush)

                    "crate" ->
                        succeed (Obstacle Crate)

                    "nest" ->
                        succeed (Obstacle Nest)

                    "table" ->
                        succeed (Obstacle Table)

                    "totem" ->
                        succeed (Obstacle Totem)

                    "tree-3" ->
                        succeed (Obstacle Tree3)

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


decodeBoardOverlayDirection : String -> Decoder BoardOverlayDirectionType
decodeBoardOverlayDirection dir =
    case String.toLower dir of
        "default" ->
            succeed Default

        "horizontal" ->
            succeed Horizontal

        "vertical" ->
            succeed Vertical

        "diagonal-left" ->
            succeed DiagonalLeft

        "diagonal-right" ->
            succeed DiagonalRight

        _ ->
            fail ("Could not decode overlay direction '" ++ dir ++ "'")


decodeMonster : Decoder Monster
decodeMonster =
    map3 Monster
        (field "class" Decode.string |> andThen decodeMonsterType)
        (field "id" Decode.int)
        (field "level" Decode.string |> andThen decodeMonsterLevel)


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
