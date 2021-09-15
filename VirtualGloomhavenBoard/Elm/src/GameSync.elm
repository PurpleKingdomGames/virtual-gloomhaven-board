port module GameSync exposing (Msg(..), connectToServer, decodeGameState, decodePiece, decodeRoom, encodeGameState, encodePiece, encodeRoom, ensureOverlayIds, exitFullscreen, pushGameState, subscriptions, toggleFullscreen, update)

import Array exposing (Array)
import BoardMapTile exposing (MapTileRef(..), refToString, stringToRef)
import BoardOverlay exposing (BoardOverlay, BoardOverlayDirectionType(..), BoardOverlayType(..), ChestType(..), CorridorMaterial(..), CorridorSize(..), DifficultTerrainSubType(..), DoorSubType(..), HazardSubType(..), ObstacleSubType(..), TrapSubType(..), TreasureSubType(..), WallSubType(..))
import Character exposing (CharacterClass, characterToString, stringToCharacter)
import Dict exposing (Dict)
import Game exposing (AIType(..), Expansion(..), GameState, GameStateScenario(..), Piece, PieceType(..), RoomData, SummonsType(..))
import Json.Decode as Decode exposing (Decoder, andThen, decodeValue, fail, field, map3, map8, succeed)
import Json.Encode as Encode exposing (object)
import List
import Monster exposing (MonsterLevel(..), monsterTypeToString)
import SharedSync exposing (decodeBoardOverlay, decodeCoords, decodeMapRefList, decodeMonster, encodeCoords, encodeMapTileRefList, encodeOverlays)
import String exposing (String)


port connect : () -> Cmd msg


port createRoom : Maybe Int -> Cmd msg


port sendUpdate : ( String, Encode.Value ) -> Cmd msg


port joinRoom : ( Maybe String, String ) -> Cmd msg


port clientDisconnected : (() -> msg) -> Sub msg


port clientConnected : (() -> msg) -> Sub msg


port receiveUpdate : (Decode.Value -> msg) -> Sub msg


port disconnected : (() -> msg) -> Sub msg


port connected : (() -> msg) -> Sub msg


port reconnecting : (() -> msg) -> Sub msg


port receiveRoomCode : (String -> msg) -> Sub msg


port invalidRoomCode : (() -> msg) -> Sub msg


port toggleFullscreenPort : Bool -> Cmd msg


port exitFullscreen : (() -> msg) -> Sub msg


type Msg
    = ClientDisconnected ()
    | ClientConnected ()
    | UpdateReceived Decode.Value
    | Disconnected ()
    | Connected ()
    | Reconnecting ()
    | JoinRoom String
    | RoomCodeReceived String
    | RoomCodeInvalid ()


toggleFullscreen : Bool -> Cmd Msg
toggleFullscreen fullscreenEnabled =
    toggleFullscreenPort fullscreenEnabled


connectToServer : Cmd msg
connectToServer =
    connect ()


pushGameState : String -> GameState -> Cmd msg
pushGameState roomCode gameState =
    sendUpdate ( roomCode, encodeGameState { gameState | updateCount = gameState.updateCount + 1, roomCode = roomCode } )


update : Msg -> Maybe Int -> Maybe GameState -> (GameState -> msg) -> ( Maybe msg, Cmd msg )
update msg seed gameState gameStateUpdateMsg =
    case msg of
        Connected _ ->
            case gameState of
                Just g ->
                    if g.roomCode == "" then
                        ( Nothing, createRoom seed )

                    else
                        ( Nothing, joinRoom ( Nothing, g.roomCode ) )

                Nothing ->
                    ( Nothing, createRoom seed )

        UpdateReceived val ->
            let
                newGameState =
                    decodeAndUpdateGameState gameState val
            in
            ( Maybe.map (\s -> gameStateUpdateMsg s) newGameState, Cmd.none )

        RoomCodeReceived roomCode ->
            ( Maybe.map (\g -> gameStateUpdateMsg { g | updateCount = 0, roomCode = roomCode }) gameState, Cmd.none )

        JoinRoom roomCode ->
            let
                oldRoomCode =
                    Maybe.map (\s -> s.roomCode) gameState
            in
            ( Maybe.map (\g -> gameStateUpdateMsg { g | updateCount = 0, roomCode = roomCode }) gameState, joinRoom ( oldRoomCode, roomCode ) )

        _ ->
            ( Nothing, Cmd.none )


decodeAndUpdateGameState : Maybe GameState -> Decode.Value -> Maybe GameState
decodeAndUpdateGameState gameState val =
    case decodeValue decodeGameState val of
        Ok s ->
            case gameState of
                Just g ->
                    if s.updateCount > g.updateCount && s.roomCode == g.roomCode then
                        Just (ensureOverlayIds s)

                    else
                        Nothing

                Nothing ->
                    Just (ensureOverlayIds s)

        Err _ ->
            Nothing


ensureOverlayIds : GameState -> GameState
ensureOverlayIds state =
    if List.any (\o -> o.id == 0) state.overlays then
        { state | overlays = addOverlayIds state.overlays }

    else
        state


addOverlayIds : List BoardOverlay -> List BoardOverlay
addOverlayIds overlays =
    let
        maxId =
            case
                List.map (\o -> o.id) overlays
                    |> List.maximum
            of
                Just i ->
                    i

                Nothing ->
                    0

        ( _, newOverlays ) =
            addOverlayId overlays maxId []
    in
    newOverlays


addOverlayId : List BoardOverlay -> Int -> List BoardOverlay -> ( Int, List BoardOverlay )
addOverlayId overlays maxId completeOverlays =
    case overlays of
        overlay :: rest ->
            if overlay.id == 0 then
                let
                    newId =
                        maxId + 1
                in
                addOverlayId rest newId ({ overlay | id = newId } :: completeOverlays)

            else
                addOverlayId rest maxId (overlay :: completeOverlays)

        _ ->
            ( maxId, completeOverlays )


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ clientDisconnected ClientDisconnected
        , clientConnected ClientConnected
        , receiveUpdate UpdateReceived
        , disconnected Disconnected
        , connected Connected
        , reconnecting Reconnecting
        , receiveRoomCode RoomCodeReceived
        , invalidRoomCode RoomCodeInvalid
        ]


decodeGameState : Decoder GameState
decodeGameState =
    map8 GameState
        (field "scenario" (Decode.oneOf [ decodeScenarioInt, decodeInbuiltScenario, decodeCustomScenario ]))
        (field "players" (Decode.list decodeCharacter))
        (field "updateCount" Decode.int)
        (field "visibleRooms" (Decode.list Decode.string) |> andThen decodeMapRefList)
        (field "overlays" (Decode.list decodeBoardOverlay))
        (field "pieces" (Decode.list decodePiece))
        (field "availableMonsters" (Decode.list decodeAvailableMonsters) |> andThen (\a -> succeed (Dict.fromList a)))
        (field "roomCode" Decode.string)


encodeGameState : GameState -> Encode.Value
encodeGameState gameState =
    object
        [ ( "scenario", Encode.object (encodeGameStateScenario gameState.scenario) )
        , ( "players", Encode.list Encode.object (encodeCharacters gameState.players) )
        , ( "updateCount", Encode.int gameState.updateCount )
        , ( "visibleRooms", Encode.list Encode.string (encodeMapTileRefList gameState.visibleRooms) )
        , ( "overlays", Encode.list Encode.object (encodeOverlays gameState.overlays) )
        , ( "pieces", Encode.list Encode.object (encodePieces gameState.pieces) )
        , ( "availableMonsters", Encode.list Encode.object (encodeAvailableMonsters gameState.availableMonsters) )
        , ( "roomCode", Encode.string gameState.roomCode )
        ]


decodeScenarioInt : Decoder GameStateScenario
decodeScenarioInt =
    Decode.int |> andThen (\i -> succeed (InbuiltScenario Gloomhaven i))


decodeInbuiltScenario : Decoder GameStateScenario
decodeInbuiltScenario =
    field "expansion" Decode.string
        |> andThen
            (\s ->
                let
                    strExp =
                        String.toLower s

                    e =
                        if strExp == "gloomhaven" then
                            Just Gloomhaven

                        else if strExp == "solo" then
                            Just Solo

                        else
                            Nothing
                in
                case e of
                    Just exp ->
                        field "id" Decode.int
                            |> andThen (\i -> succeed (InbuiltScenario exp i))

                    Nothing ->
                        fail ("Could not find expansion " ++ strExp)
            )


decodeCustomScenario : Decoder GameStateScenario
decodeCustomScenario =
    field "custom" Decode.string
        |> andThen (\s -> succeed (CustomScenario s))


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


decodeRoom : Decoder RoomData
decodeRoom =
    map3 RoomData
        (field "ref" Decode.string
            |> andThen
                (\s ->
                    case stringToRef s of
                        Just r ->
                            succeed r

                        Nothing ->
                            fail ("Cannot decode room ref " ++ s)
                )
        )
        (field "origin" decodeCoords)
        (field "turns" Decode.int)


decodeSummons : Decoder AIType
decodeSummons =
    Decode.oneOf
        [ field "id" Decode.int |> andThen (\i -> succeed (Summons (NormalSummons i)))
        , field "id" Decode.string
            |> andThen
                (\s ->
                    case String.toLower s of
                        "bear" ->
                            succeed (Summons BearSummons)

                        _ ->
                            fail ("Cannot convert " ++ s ++ " to summons type")
                )
        ]


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


encodeGameStateScenario : GameStateScenario -> List ( String, Encode.Value )
encodeGameStateScenario scenario =
    case scenario of
        InbuiltScenario e i ->
            [ ( "expansion"
              , Encode.string
                    (case e of
                        Gloomhaven ->
                            "gloomhaven"

                        Solo ->
                            "solo"
                    )
              )
            , ( "id", Encode.int i )
            ]

        CustomScenario s ->
            [ ( "custom", Encode.string s ) ]


encodePieces : List Piece -> List (List ( String, Encode.Value ))
encodePieces pieces =
    List.map encodePiece pieces


encodePiece : Piece -> List ( String, Encode.Value )
encodePiece p =
    [ ( "ref", Encode.object (encodePieceType p.ref) )
    , ( "x", Encode.int p.x )
    , ( "y", Encode.int p.y )
    ]


encodeRoom : RoomData -> List ( String, Encode.Value )
encodeRoom r =
    [ ( "ref", Encode.string (Maybe.withDefault "" (refToString r.ref)) )
    , ( "origin", Encode.object (encodeCoords r.origin) )
    , ( "turns", Encode.int r.turns )
    ]


encodeCharacters : List CharacterClass -> List (List ( String, Encode.Value ))
encodeCharacters characters =
    List.filterMap (\c -> characterToString c) characters
        |> List.map
            (\c ->
                [ ( "class", Encode.string c )
                ]
            )


encodePieceType : PieceType -> List ( String, Encode.Value )
encodePieceType pieceType =
    case pieceType of
        Game.None ->
            []

        Player p ->
            [ ( "type", Encode.string "player" )
            , ( "class", Encode.string (Maybe.withDefault "" (characterToString p)) )
            ]

        AI (Summons t) ->
            [ ( "type", Encode.string "summons" )
            , ( "id"
              , case t of
                    NormalSummons i ->
                        Encode.int i

                    BearSummons ->
                        Encode.string "bear"
              )
            ]

        AI (Enemy monster) ->
            [ ( "type", Encode.string "monster" )
            , ( "class", Encode.string (Maybe.withDefault "" (monsterTypeToString monster.monster)) )
            , ( "id", Encode.int monster.id )
            , ( "level", Encode.string (encodeMonsterLevel monster.level) )
            , ( "wasSummoned", Encode.bool monster.wasSummoned )
            , ( "outOfPhase", Encode.bool monster.outOfPhase )
            ]


encodeMonsterLevel : MonsterLevel -> String
encodeMonsterLevel level =
    case level of
        Normal ->
            "normal"

        Elite ->
            "elite"

        Monster.None ->
            "none"


encodeAvailableMonsters : Dict String (Array Int) -> List (List ( String, Encode.Value ))
encodeAvailableMonsters availableMonsters =
    List.map
        (\( k, v ) ->
            [ ( "ref", Encode.string k )
            , ( "bucket", Encode.list Encode.int (Array.toList v) )
            ]
        )
        (Dict.toList availableMonsters)
