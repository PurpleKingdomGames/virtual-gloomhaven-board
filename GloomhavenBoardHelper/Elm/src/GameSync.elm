port module GameSync exposing (ClientOrServer(..), Msg, decodeGameState, encodeGameState, ping, pushGameState, pushInitGameState, pushUpdatedGameState, receiveGameState, subscriptions, update)

import Array exposing (Array)
import BoardMapTile exposing (MapTileRef(..), refToString)
import BoardOverlay exposing (BoardOverlay, BoardOverlayDirectionType(..), BoardOverlayType(..), ChestType(..), CorridorMaterial(..), CorridorSize(..), DifficultTerrainSubType(..), DoorSubType(..), HazardSubType(..), ObstacleSubType(..), TrapSubType(..), TreasureSubType(..))
import Character exposing (CharacterClass, characterToString, stringToCharacter)
import Dict exposing (Dict)
import Game exposing (AIType(..), GameState, NumPlayers(..), Piece, PieceType(..))
import Json.Decode as Decode exposing (Decoder, andThen, decodeValue, fail, field, int, list, map3, map7, string, succeed)
import Json.Encode as Encode exposing (int, list, object, string)
import List exposing (map)
import Monster exposing (MonsterLevel(..), monsterTypeToString)
import SharedSync exposing (decodeBoardOverlay, decodeMapRefList, decodeMonster)



-- PING (client/server)


port ping : () -> Cmd msg



-- RECEIVE_OFFER (server)


port receiveOffer : (String -> msg) -> Sub msg



-- SEND_OFFER (client)


port sendOffer : String -> Cmd msg



-- SEND_ANSWER (server)


port sendAnswer : ( String, Maybe Encode.Value ) -> Cmd msg



-- RECEIVE_ANSWER (client)


port receiveAnswer : (Decode.Value -> msg) -> Sub msg



-- CLIENT_DISCONNECT (server)


port clientDisconnected : (String -> msg) -> Sub msg



-- RECEIVE_UPDATE (client/server)


port receiveUpdate : (Decode.Value -> msg) -> Sub msg



-- SEND_UPDATE (client/server)


port sendUpdate : ( String, Maybe Encode.Value ) -> Cmd msg



-- DISCONNECTED (client/server)


port disconnected : (() -> msg) -> Sub msg



-- CONNECTED (client/server)


port connected : (() -> msg) -> Sub msg



-- REGISTER_SERVER (server)


port registerServer : String -> Cmd msg



-- RECEIVE_JOIN_CODE (server)


port receiveJoinCode : (String -> msg) -> Sub msg



-- INVALID_JOIN_CODE (client)


port invalidJoinCode : (() -> msg) -> Sub msg



-- START LEGACY PORTS --


port pushGameStatePort : Encode.Value -> Cmd msg


port pushInitStatePort : Encode.Value -> Cmd msg


port updateStatePort : Encode.Value -> Cmd msg


port receiveGameState : (Decode.Value -> msg) -> Sub msg



-- END LEGACY PORTS --


type ClientOrServer
    = Client
    | Server


type Msg
    = OfferSent String
    | OfferReceived String
    | AnswerReceived Decode.Value
    | ClientDisconnected String
    | UpdateReceived Decode.Value
    | Disconnected ()
    | Connected ()
    | RegisterServer String
    | JoinCodeReceived String
    | JoinCodeInvalid ()


pushGameState : GameState -> Cmd msg
pushGameState gameState =
    pushGameStatePort (encodeGameState { gameState | updateCount = gameState.updateCount + 1 })


pushUpdatedGameState : GameState -> Cmd msg
pushUpdatedGameState gameState =
    updateStatePort (encodeGameState gameState)


pushInitGameState : GameState -> Cmd msg
pushInitGameState gameState =
    pushInitStatePort (encodeGameState gameState)


update : Msg -> Maybe GameState -> ClientOrServer -> List String -> (GameState -> msg) -> (List String -> msg) -> ( Maybe msg, Cmd msg )
update msg gameState clientOrServer connectedClients gameStateUpdateMsg clientIpMsg =
    case msg of
        OfferSent joinCode ->
            ( Nothing, sendOffer joinCode )

        OfferReceived ip ->
            ( Just (clientIpMsg (ip :: connectedClients)), sendAnswer ( ip, Maybe.map (\s -> encodeGameState s) gameState ) )

        AnswerReceived val ->
            let
                newGameState =
                    decodeAndUpdateGameState gameState val
            in
            ( Maybe.map (\s -> gameStateUpdateMsg s) newGameState, Cmd.none )

        UpdateReceived val ->
            let
                newGameState =
                    decodeAndUpdateGameState gameState val
            in
            case ( clientOrServer, newGameState ) of
                ( Server, Just _ ) ->
                    ( Maybe.map (\g -> gameStateUpdateMsg g) newGameState
                    , List.map
                        (\ip ->
                            sendUpdate ( ip, Maybe.map (\g -> encodeGameState g) newGameState )
                        )
                        connectedClients
                        |> Cmd.batch
                    )

                ( Client, Just _ ) ->
                    ( Maybe.map (\s -> gameStateUpdateMsg s) newGameState, Cmd.none )

                _ ->
                    ( Nothing, Cmd.none )

        ClientDisconnected ip ->
            ( Just (clientIpMsg (List.filter (\i -> i /= ip) connectedClients)), Cmd.none )

        RegisterServer prefferedJoinCode ->
            ( Nothing, registerServer prefferedJoinCode )

        _ ->
            ( Nothing, Cmd.none )


decodeAndUpdateGameState : Maybe GameState -> Decode.Value -> Maybe GameState
decodeAndUpdateGameState gameState val =
    case decodeValue decodeGameState val of
        Ok s ->
            case gameState of
                Just g ->
                    if s.updateCount > g.updateCount then
                        Just s

                    else
                        Nothing

                Nothing ->
                    Just s

        Err _ ->
            Nothing


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ receiveOffer OfferReceived
        , receiveAnswer AnswerReceived
        , clientDisconnected ClientDisconnected
        , receiveUpdate UpdateReceived
        , disconnected Disconnected
        , connected Connected
        , receiveJoinCode JoinCodeReceived
        , invalidJoinCode JoinCodeInvalid
        ]


decodeGameState : Decoder GameState
decodeGameState =
    map7 GameState
        (field "scenario" Decode.int)
        (field "numPlayers" Decode.int |> andThen decodeNumPlayers)
        (field "updateCount" Decode.int)
        (field "visibleRooms" (Decode.list Decode.string) |> andThen decodeMapRefList)
        (field "overlays" (Decode.list decodeBoardOverlay))
        (field "pieces" (Decode.list decodePiece))
        (field "availableMonsters" (Decode.list decodeAvailableMonsters) |> andThen (\a -> succeed (Dict.fromList a)))


encodeGameState : GameState -> Encode.Value
encodeGameState gameState =
    object
        [ ( "scenario", Encode.int gameState.scenario )
        , ( "numPlayers", Encode.int (encodeNumPlayers gameState.numPlayers) )
        , ( "updateCount", Encode.int gameState.updateCount )
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

        DiagonalLeftReverse ->
            "diagonal-left-reverse"

        DiagonalRightReverse ->
            "diagonal-right-reverse"

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
