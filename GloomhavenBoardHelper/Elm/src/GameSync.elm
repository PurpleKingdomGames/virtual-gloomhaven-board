port module GameSync exposing (decodeGameState, encodeGameState, pushGameState, pushInitGameState, receiveGameState)

import Array exposing (Array)
import BoardMapTile exposing (MapTileRef(..), refToString)
import BoardOverlay exposing (BoardOverlay, BoardOverlayDirectionType(..), BoardOverlayType(..), ChestType(..), CorridorMaterial(..), CorridorSize(..), DifficultTerrainSubType(..), DoorSubType(..), HazardSubType(..), ObstacleSubType(..), TrapSubType(..), TreasureSubType(..))
import Character exposing (CharacterClass, characterToString, stringToCharacter)
import Dict exposing (Dict)
import Game exposing (AIType(..), GameState, NumPlayers(..), Piece, PieceType(..))
import Json.Decode as Decode exposing (Decoder, andThen, fail, field, int, list, map3, map6, string, succeed)
import Json.Encode as Encode exposing (int, list, object, string)
import List exposing (map)
import Monster exposing (MonsterLevel(..), monsterTypeToString)
import SharedSync exposing (decodeBoardOverlay, decodeMapRefList, decodeMonster)


port pushGameStatePort : Encode.Value -> Cmd msg


port pushInitStatePort : Encode.Value -> Cmd msg


port receiveGameState : (Decode.Value -> msg) -> Sub msg


pushGameState : GameState -> Cmd msg
pushGameState gameState =
    pushGameStatePort (encodeGameState gameState)


pushInitGameState : GameState -> Cmd msg
pushInitGameState gameState =
    pushInitStatePort (encodeGameState gameState)


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
        , ( "availableMonsters", Encode.list Encode.object (encodeAvailableMonsters gameState.availableMonsters) )
        ]


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

        Obstacle o ->
            object
                [ ( "type", Encode.string "obstacle" )
                , ( "subType", Encode.string (encodeObstacle o) )
                ]

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


encodeDoor : DoorSubType -> String
encodeDoor door =
    case door of
        Stone ->
            "stone"

        Wooden ->
            "wooden"

        Corridor _ _ ->
            "corridor"

        DarkFog ->
            "dark-fog"


encodeMaterial : CorridorMaterial -> String
encodeMaterial m =
    case m of
        Earth ->
            "earth"

        ManmadeStone ->
            "manmade-stone"

        NaturalStone ->
            "natural-stone"

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


encodeDifficultTerrain : DifficultTerrainSubType -> String
encodeDifficultTerrain terrain =
    case terrain of
        Rubble ->
            "rubble"


encodeHazard : HazardSubType -> String
encodeHazard hazard =
    case hazard of
        Thorns ->
            "thorns"


encodeObstacle : ObstacleSubType -> String
encodeObstacle obstacle =
    case obstacle of
        Altar ->
            "altar"

        Sarcophagus ->
            "sarcophagus"

        Barrel ->
            "barrel"

        Boulder1 ->
            "boulder-1"

        Boulder2 ->
            "boulder-2"

        Bush ->
            "bush"

        Crate ->
            "crate"

        Nest ->
            "nest"

        Pillar ->
            "pillar"

        Table ->
            "table"

        Totem ->
            "totem"

        Tree3 ->
            "tree-3"


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


encodeAvailableMonsters : Dict String (Array Int) -> List (List ( String, Encode.Value ))
encodeAvailableMonsters availableMonsters =
    List.map
        (\( k, v ) ->
            [ ( "ref", Encode.string k )
            , ( "bucket", Encode.list Encode.int (Array.toList v) )
            ]
        )
        (Dict.toList availableMonsters)
