port module GameSync exposing (decodeGameState, encodeGameState, pushGameState, receiveGameState)

import Array exposing (Array)
import BoardMapTile exposing (MapTileRef(..), refToString, stringToRef)
import BoardOverlay exposing (BoardOverlay, BoardOverlayDirectionType(..), BoardOverlayType(..), ChestType(..), DoorSubType(..), ObstacleSubType(..), TrapSubType(..), TreasureSubType(..))
import Character exposing (CharacterClass, characterToString, stringToCharacter)
import Dict
import Game exposing (AIType(..), GameState, NumPlayers(..), Piece, PieceType(..))
import Json.Decode as Decode exposing (Decoder, andThen, fail, field, index, int, list, map2, map3, map5, map6, string, succeed)
import Json.Encode as Encode exposing (int, list, object, string)
import List exposing (all, map)
import Monster exposing (Monster, MonsterLevel(..), MonsterType, monsterTypeToString, stringToMonsterType)


port pushGameStatePort : Encode.Value -> Cmd msg


port receiveGameState : (Decode.Value -> msg) -> Sub msg


pushGameState : GameState -> Cmd msg
pushGameState gameState =
    pushGameStatePort (encodeGameState gameState)


decodeGameState : Decoder GameState
decodeGameState =
    map6 GameState
        (field "scenario" Decode.int)
        (field "numPlayers" Decode.int |> andThen decodeNumPlayers)
        (field "visibleRooms" (Decode.list Decode.string) |> andThen decodeMapRefList)
        (field "overlays" (Decode.list decodeBoardOverlay))
        (field "pieces" (Decode.list decodePiece))
        (field "availableMonsters" (Decode.list decodeAvailableMonsters) |> andThen (\a -> succeed (Dict.fromList a)))


encodeGameState : GameState -> Encode.Value
encodeGameState gameState =
    object
        [ ( "scenario", Encode.int gameState.scenario )
        , ( "numPlayers", Encode.int (encodeNumPlayers gameState.numPlayers) )
        , ( "visibleRooms", Encode.list Encode.string (encodeMapTileRefList gameState.visibleRooms) )
        , ( "overlays", Encode.list Encode.object (encodeOverlays gameState.overlays) )
        , ( "pieces", Encode.list Encode.object (encodePieces gameState.pieces) )
        ]


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
        (field "ref" decodePieceType)
        (field "x" Decode.int)
        (field "y" Decode.int)


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
    field "type" Decode.string
        |> andThen decodeType


decodeSummons : Decoder AIType
decodeSummons =
    field "id" Decode.int
        |> andThen
            (\i ->
                succeed (Summons i)
            )


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

        "" ->
            succeed Monster.None

        _ ->
            fail (l ++ " is not a valid monster level")


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
                "starting-location" ->
                    succeed StartingLocation

                "door" ->
                    decodeDoor
                        |> andThen decodeDoorRefs

                "trap" ->
                    decodeTrap

                "obstacle" ->
                    decodeObstacle

                "treasure" ->
                    decodeTreasure

                _ ->
                    fail ("Unknown overlay type: " ++ typeName)
    in
    field "type" Decode.string
        |> andThen decodeType


decodeDoor : Decoder DoorSubType
decodeDoor =
    field "subType" Decode.string
        |> andThen
            (\s ->
                case String.toLower s of
                    "stone" ->
                        succeed Stone

                    _ ->
                        fail (s ++ " is not a door sub-type")
            )


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

                    _ ->
                        fail (s ++ " is not a trap sub-type")
            )


decodeObstacle : Decoder BoardOverlayType
decodeObstacle =
    field "subType" Decode.string
        |> andThen
            (\s ->
                case String.toLower s of
                    "sarcophagus" ->
                        succeed (Obstacle Sarcophagus)

                    "boulder-1" ->
                        succeed (Obstacle Boulder1)

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


decodeCharacter : Decoder CharacterClass
decodeCharacter =
    field "class" Decode.string
        |> andThen
            (\c ->
                case stringToCharacter c of
                    Just class ->
                        succeed class

                    Nothing ->
                        fail (c ++ " is not a valid player class")
            )


decodeAvailableMonsters : Decoder ( String, Array Int )
decodeAvailableMonsters =
    field "ref" Decode.string
        |> andThen
            (\m ->
                field "bucket" (Decode.array Decode.int)
                    |> andThen
                        (\b ->
                            succeed ( m, b )
                        )
            )


encodeNumPlayers : NumPlayers -> Int
encodeNumPlayers numPlayers =
    case numPlayers of
        TwoPlayer ->
            2

        ThreePlayer ->
            3

        FourPlayer ->
            4


encodeMapTileRefList : List MapTileRef -> List String
encodeMapTileRefList refs =
    List.map (\r -> refToString r) refs
        |> List.filter (\r -> r /= Nothing)
        |> List.map (\r -> Maybe.withDefault "" r)


encodeOverlays : List BoardOverlay -> List (List ( String, Encode.Value ))
encodeOverlays overlays =
    List.map
        (\o ->
            [ ( "ref", encodeOverlayType o.ref )
            , ( "direction", Encode.string (encodeOverlayDirection o.direction) )
            , ( "cells", Encode.list (Encode.list Encode.int) (encodeOverlayCells o.cells) )
            ]
        )
        overlays


encodeOverlayDirection : BoardOverlayDirectionType -> String
encodeOverlayDirection dir =
    case dir of
        Default ->
            "default"

        DiagonalLeft ->
            "diagonal-left"

        DiagonalRight ->
            "diagonal-right"

        Horizontal ->
            "horizontal"

        Vertical ->
            "vertical"


encodeOverlayCells : List ( Int, Int ) -> List (List Int)
encodeOverlayCells cells =
    List.map (\( a, b ) -> [ a, b ]) cells


encodeOverlayType : BoardOverlayType -> Encode.Value
encodeOverlayType overlay =
    case overlay of
        StartingLocation ->
            object [ ( "type", Encode.string "starting-location" ) ]

        Door s refs ->
            object
                [ ( "type", Encode.string "door" )
                , ( "subType", Encode.string (encodeDoor s) )
                , ( "links", Encode.list Encode.string (encodeMapTileRefList refs) )
                ]

        Trap t ->
            object
                [ ( "type", Encode.string "trap" )
                , ( "subType", Encode.string (encodeTrap t) )
                ]

        Obstacle o ->
            object
                [ ( "type", Encode.string "obstacle" )
                , ( "subType", Encode.string (encodeObstacle o) )
                ]

        Treasure t ->
            object
                (( "type", Encode.string "treasure" )
                    :: encodeTreasure t
                )


encodeDoor : DoorSubType -> String
encodeDoor door =
    case door of
        Stone ->
            "stone"


encodeTrap : TrapSubType -> String
encodeTrap trap =
    case trap of
        BearTrap ->
            "bear"


encodeObstacle : ObstacleSubType -> String
encodeObstacle obstacle =
    case obstacle of
        Sarcophagus ->
            "sarcophagus"

        Boulder1 ->
            "boulder-1"


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


encodeTreasureChest : ChestType -> String
encodeTreasureChest chest =
    case chest of
        NormalChest i ->
            String.fromInt i

        Goal ->
            "goal"


encodePieces : List Piece -> List (List ( String, Encode.Value ))
encodePieces pieces =
    List.map
        (\p ->
            [ ( "ref", object (encodePieceType p.ref) )
            , ( "x", Encode.int p.x )
            , ( "y", Encode.int p.y )
            ]
        )
        pieces


encodePieceType : PieceType -> List ( String, Encode.Value )
encodePieceType pieceType =
    case pieceType of
        Game.None ->
            []

        Player p ->
            [ ( "type", Encode.string "player" )
            , ( "class", Encode.string (Maybe.withDefault "" (characterToString p)) )
            ]

        AI (Summons id) ->
            [ ( "type", Encode.string "summons" )
            , ( "id", Encode.int id )
            ]

        AI (Enemy monster) ->
            [ ( "type", Encode.string "monster" )
            , ( "class", Encode.string (Maybe.withDefault "" (monsterTypeToString monster.monster)) )
            , ( "id", Encode.int monster.id )
            , ( "level", Encode.string (encodeMonsterLevel monster.level) )
            ]


encodeMonsterLevel : MonsterLevel -> String
encodeMonsterLevel level =
    case level of
        Normal ->
            "normal"

        Elite ->
            "elite"

        Monster.None ->
            ""
