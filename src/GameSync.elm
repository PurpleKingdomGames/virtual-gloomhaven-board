port module GameSync exposing (decodeGameState)

import BoardMapTile exposing (MapTileRef(..), stringToRef)
import BoardOverlay exposing (BoardOverlay, BoardOverlayDirectionType(..), BoardOverlayType(..), ChestType(..), DoorSubType(..), ObstacleSubType(..), TrapSubType(..), TreasureSubType(..))
import Character exposing (CharacterClass, stringToCharacter)
import Game exposing (AIType(..), GameState, NumPlayers(..), Piece, PieceType(..))
import Json.Decode exposing (Decoder, andThen, fail, field, index, int, list, map2, map3, map5, string, succeed)
import Json.Encode
import List exposing (any, map)
import Monster exposing (Monster, MonsterLevel(..), MonsterType, stringToMonsterType)


port pushGameState : Json.Encode.Value -> Cmd msg


port receiveGameState : (Json.Decode.Value -> msg) -> Sub msg


decodeGameState : Decoder GameState
decodeGameState =
    map5 GameState
        (field "scenario" int)
        (field "numPlayers" int |> andThen decodeNumPlayers)
        (field "visibleRooms" (list string) |> andThen decodeMapRefList)
        (field "overlays" (list decodeBoardOverlay))
        (field "pieces" (list decodePiece))


decodeMapRefList : List String -> Decoder (List MapTileRef)
decodeMapRefList refs =
    let
        decodedRefs =
            map (\ref -> stringToRef ref) refs
    in
    if any (\s -> s == Nothing) decodedRefs then
        succeed (map (\r -> Maybe.withDefault A1a r) decodedRefs)

    else
        fail "Could not decode all maptile references"


decodeNumPlayers : Int -> Decoder NumPlayers
decodeNumPlayers numPlayers =
    case numPlayers of
        2 ->
            succeed TwoPlayer

        3 ->
            succeed ThreePlayer

        4 ->
            succeed FourPlayer

        p ->
            fail ("Cannot decode a " ++ String.fromInt p ++ " game")


decodePiece : Decoder Piece
decodePiece =
    map3 Piece
        (field "type" decodePieceType)
        (field "x" int)
        (field "y" int)


decodePieceType : Decoder PieceType
decodePieceType =
    let
        decodeType typeName =
            case String.toLower typeName of
                "player" ->
                    decodeCharacter
                        |> andThen (\c -> succeed (Player c))

                "monster" ->
                    decodeMonster
                        |> andThen (\m -> succeed (AI (Enemy m)))

                "summons" ->
                    decodeSummons
                        |> andThen (\c -> succeed (AI c))

                _ ->
                    fail ("Unknown overlay type: " ++ typeName)
    in
    field "type" string
        |> andThen decodeType


decodeSummons : Decoder AIType
decodeSummons =
    map2 Tuple.pair
        (field "id" int)
        (field "owner" string)
        |> andThen
            (\( i, o ) ->
                let
                    class =
                        stringToCharacter o
                in
                case class of
                    Just c ->
                        succeed (Summons i c)

                    Nothing ->
                        fail (o ++ " is not a valid character class owner for summons")
            )


decodeMonster : Decoder Monster
decodeMonster =
    map3 Monster
        (field "type" string |> andThen decodeMonsterType)
        (field "id" int)
        (field "level" string |> andThen decodeMonsterLevel)


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

        "" ->
            succeed Monster.None

        _ ->
            fail (l ++ " is not a valid monster level")


decodeBoardOverlay : Decoder BoardOverlay
decodeBoardOverlay =
    map3 BoardOverlay
        (field "ref" decodeBoardOverlayType)
        (field "direction" string |> andThen decodeBoardOverlayDirection)
        (field "cells" (list (map2 Tuple.pair (index 0 int) (index 1 int))))


decodeBoardOverlayType : Decoder BoardOverlayType
decodeBoardOverlayType =
    let
        decodeType typeName =
            case String.toLower typeName of
                "starting-location" ->
                    succeed StartingLocation

                "door" ->
                    decodeDoor

                "trap" ->
                    decodeTrap

                "obstacle" ->
                    decodeObstacle

                "treasure" ->
                    decodeTreasure

                _ ->
                    fail ("Unknown overlay type: " ++ typeName)
    in
    field "type" string
        |> andThen decodeType


decodeDoor : Decoder BoardOverlayType
decodeDoor =
    field "subType" string
        |> andThen
            (\s ->
                case String.toLower s of
                    "stone" ->
                        succeed (Door Stone)

                    _ ->
                        fail (s ++ " is not a door sub-type")
            )


decodeTrap : Decoder BoardOverlayType
decodeTrap =
    field "subType" string
        |> andThen
            (\s ->
                case String.toLower s of
                    "bear" ->
                        succeed (Trap BearTrap)

                    _ ->
                        fail (s ++ " is not a trap sub-type")
            )


decodeObstacle : Decoder BoardOverlayType
decodeObstacle =
    field "subType" string
        |> andThen
            (\s ->
                case String.toLower s of
                    "sarcophagus" ->
                        succeed (Obstacle Sarcophagus)

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
                    succeed (Treasure Coin)

                "loot" ->
                    decodeTreasureLoot

                _ ->
                    fail ("Unknown treasure type: " ++ typeName)
    in
    field "type" string
        |> andThen decodeType


decodeTreasureChest : Decoder BoardOverlayType
decodeTreasureChest =
    field "id" string
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


decodeTreasureLoot : Decoder BoardOverlayType
decodeTreasureLoot =
    field "amount" int
        |> andThen (\i -> succeed (Treasure (Loot i)))


decodeBoardOverlayDirection : String -> Decoder BoardOverlayDirectionType
decodeBoardOverlayDirection dir =
    case String.toLower dir of
        "default" ->
            succeed Default

        "horizontal" ->
            succeed Horizontal

        "vertical" ->
            succeed Vertical

        "diagonalleft" ->
            succeed DiagonalLeft

        "diagonalright" ->
            succeed DiagonalRight

        _ ->
            fail ("Could not decode overlay direction '" ++ dir ++ "'")


decodeCharacter : Decoder CharacterClass
decodeCharacter =
    field "class" string
        |> andThen
            (\c ->
                case stringToCharacter c of
                    Just class ->
                        succeed class

                    Nothing ->
                        fail (c ++ " is not a valid player class")
            )
