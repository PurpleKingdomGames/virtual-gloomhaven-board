port module AppStorage exposing (AppModeType(..), AppOverrides, CampaignTrackerUrl(..), Config, ExtendedRoomData, GameModeType(..), MapData, MoveablePiece, MoveablePieceType(..), decodeMoveablePiece, empty, emptyOverrides, encodeMapData, encodeMoveablePiece, loadFromStorage, loadMapFromStorage, loadOverrides, saveMapToStorage, saveToStorage)

import BoardOverlay exposing (BoardOverlay)
import Character exposing (CharacterClass, stringToCharacter)
import Game exposing (GameState, Piece, RoomData)
import GameSync exposing (decodeGameState, decodePiece, decodeRoom, encodeGameState, encodePiece, encodeRoom)
import Html exposing (s)
import Json.Decode as Decode exposing (Decoder, andThen, decodeValue, fail, field, map2, map4, map7, map8, maybe, succeed)
import Json.Decode.Pipeline exposing (..)
import Json.Encode as Encode exposing (object)
import List exposing (filterMap)
import Scenario exposing (ScenarioMonster)
import SharedSync exposing (decodeBoardOverlay, decodeCoords, decodeScenarioMonster, encodeCoords, encodeMonsters, encodeOverlay, encodeOverlays)


port saveData : Encode.Value -> Cmd msg


port saveMapData : Encode.Value -> Cmd msg


defaultSummonsColour : String
defaultSummonsColour =
    "#963f9d"


type alias StoredData =
    { config : Config
    , gameState : GameState
    }


type alias Config =
    { appMode : AppModeType
    , gameMode : GameModeType
    , roomCode : Maybe String
    , summonsColour : String
    , showRoomCode : Bool
    , envelopeX : Bool
    , boardOnly : Bool
    , campaignTracker : Maybe CampaignTrackerUrl
    , tutorialStep : Int
    }


type alias MapData =
    { scenarioTitle : String
    , roomData : List ExtendedRoomData
    , overlays : List BoardOverlay
    , monsters : List ScenarioMonster
    }


type alias ExtendedRoomData =
    { data : RoomData
    , rotationPoint : ( Int, Int )
    }


type alias AppOverrides =
    { initScenario : Maybe Int
    , initPlayers : Maybe (List CharacterClass)
    , initRoomCodeSeed : Maybe Int
    , lockScenario : Bool
    , lockPlayers : Bool
    , lockRoomCode : Bool
    , campaignTracker : Maybe CampaignTrackerUrl
    }


type CampaignTrackerUrl
    = CampaignTrackerUrl String String


type GameModeType
    = MovePiece
    | KillPiece
    | MoveOverlay
    | DestroyOverlay
    | LootCell
    | RevealRoom
    | AddPiece


type AppModeType
    = Game
    | ScenarioDialog
    | ConfigDialog
    | PlayerChoiceDialog


type alias MoveablePiece =
    { ref : MoveablePieceType
    , coords : Maybe ( Int, Int )
    , target : Maybe ( Int, Int )
    }


type MoveablePieceType
    = OverlayType BoardOverlay (Maybe ( Int, Int ))
    | PieceType Piece
    | RoomType RoomData


emptyConfig : Config
emptyConfig =
    Config Game MovePiece Nothing defaultSummonsColour True False False Nothing 0


empty : ( GameState, Config )
empty =
    ( Game.emptyState, emptyConfig )


emptyOverrides : AppOverrides
emptyOverrides =
    AppOverrides Nothing Nothing Nothing False False False Nothing


saveToStorage : GameState -> Config -> Cmd msg
saveToStorage gameState config =
    saveData (encodeStoredData (StoredData config gameState))


loadFromStorage : Decode.Value -> Result Decode.Error ( GameState, Config )
loadFromStorage value =
    decodeStoredData value


saveMapToStorage : MapData -> Cmd msg
saveMapToStorage map =
    saveMapData (encodeMapData map)


loadMapFromStorage : Decode.Value -> Result Decode.Error MapData
loadMapFromStorage value =
    decodeValue mapDataDecoder value


loadOverrides : Decode.Value -> Result Decode.Error AppOverrides
loadOverrides value =
    decodeValue appOverridesDecoder value


encodeStoredData : StoredData -> Encode.Value
encodeStoredData data =
    object
        [ ( "config", encodeConfig data.config )
        , ( "gameState", encodeGameState data.gameState )
        ]


encodeMapData : MapData -> Encode.Value
encodeMapData data =
    object
        [ ( "scenarioTitle", Encode.string data.scenarioTitle )
        , ( "roomData", Encode.list Encode.object (encodeExtendedRoomData data.roomData) )
        , ( "overlays", Encode.list Encode.object (encodeOverlays data.overlays) )
        , ( "monsters", Encode.list Encode.object (encodeMonsters data.monsters) )
        ]


encodeExtendedRoomData : List ExtendedRoomData -> List (List ( String, Encode.Value ))
encodeExtendedRoomData roomData =
    List.map
        (\r ->
            [ ( "data", Encode.object (encodeRoom r.data) )
            , ( "rotationPoint", Encode.object (encodeCoords r.rotationPoint) )
            ]
        )
        roomData


decodeStoredData : Decode.Value -> Result Decode.Error ( GameState, Config )
decodeStoredData value =
    case decodeValue storedDataDecoder value of
        Ok data ->
            Ok ( data.gameState, data.config )

        Err e ->
            Err e


encodeConfig : Config -> Encode.Value
encodeConfig config =
    object
        [ ( "appMode", Encode.string (encodeAppMode config.appMode) )
        , ( "roomCode"
          , case config.roomCode of
                Just r ->
                    Encode.string r

                Nothing ->
                    Encode.null
          )
        , ( "summonsColour", Encode.string config.summonsColour )
        , ( "showRoomCode", Encode.bool config.showRoomCode )
        , ( "envelopeX", Encode.bool config.envelopeX )
        , ( "boardOnly", Encode.bool config.boardOnly )
        , ( "campaignTracker"
          , case config.campaignTracker of
                Just t ->
                    Encode.object (encodeCampaignTrackerUrl t)

                Nothing ->
                    Encode.null
          )
        , ( "tutorialStep", Encode.int config.tutorialStep )
        ]


encodeAppMode : AppModeType -> String
encodeAppMode appMode =
    case appMode of
        Game ->
            "game"

        ScenarioDialog ->
            "scenarioDialog"

        ConfigDialog ->
            "ConfigDialog"

        PlayerChoiceDialog ->
            "playerChoiceDialog"


encodeGameMode : GameModeType -> String
encodeGameMode gameMode =
    case gameMode of
        MovePiece ->
            "movePiece"

        KillPiece ->
            "killPiece"

        MoveOverlay ->
            "moveOverlay"

        DestroyOverlay ->
            "destroyOverlay"

        LootCell ->
            "lootCell"

        RevealRoom ->
            "revealRoom"

        AddPiece ->
            "addPiece"


storedDataDecoder : Decoder StoredData
storedDataDecoder =
    map2 StoredData
        (field "config" decodeConfig)
        (field "gameState" decodeGameState)


mapDataDecoder : Decoder MapData
mapDataDecoder =
    map4 MapData
        (field "scenarioTitle" Decode.string)
        (field "roomData" (Decode.list decodeExtendedRoomData))
        (field "overlays" (Decode.list decodeBoardOverlay))
        (field "monsters" (Decode.list decodeScenarioMonster))


appOverridesDecoder : Decoder AppOverrides
appOverridesDecoder =
    Decode.succeed AppOverrides
        |> required "initScenario" (maybe Decode.int)
        |> required "initPlayers"
            (maybe (Decode.list Decode.string)
                |> andThen
                    (\s ->
                        Maybe.map (\a -> filterMap (\c -> stringToCharacter c) a) s
                            |> succeed
                    )
            )
        |> required "initRoomCodeSeed" (maybe Decode.int)
        |> required "lockScenario" Decode.bool
        |> required "lockPlayers" Decode.bool
        |> required "lockRoomCode" Decode.bool
        |> optional "campaignTracker" decodeCampaignTrackerUrl Nothing


decodeConfig : Decoder Config
decodeConfig =
    Decode.succeed Config
        |> required "appMode" (Decode.string |> Decode.andThen decodeAppMode)
        |> optional "gameMode" (Decode.string |> Decode.andThen decodeGameMode) MovePiece
        |> required "roomCode" (Decode.nullable Decode.string)
        |> optional "summonsColour" Decode.string defaultSummonsColour
        |> required "showRoomCode" Decode.bool
        |> optional "envelopeX" Decode.bool False
        |> optional "boardOnly" Decode.bool False
        |> optional "campaignTracker" decodeCampaignTrackerUrl Nothing
        |> optional "tutorialStep" Decode.int 0


decodeAppMode : String -> Decoder AppModeType
decodeAppMode val =
    case String.toLower val of
        "game" ->
            succeed Game

        "scenariodialog" ->
            succeed ScenarioDialog

        -- Legacy
        "serverconfigdialog" ->
            succeed ConfigDialog

        "configdialog" ->
            succeed ConfigDialog

        "playerchoicedialog" ->
            succeed PlayerChoiceDialog

        _ ->
            fail ("`" ++ val ++ "` is not a valid app mode")


decodeGameMode : String -> Decoder GameModeType
decodeGameMode val =
    case String.toLower val of
        "movepiece" ->
            succeed MovePiece

        "killpiece" ->
            succeed KillPiece

        "moveoverlay" ->
            succeed MoveOverlay

        "destroyoverlay" ->
            succeed DestroyOverlay

        "lootcell" ->
            succeed LootCell

        "revealroom" ->
            succeed RevealRoom

        "addpiece" ->
            succeed AddPiece

        _ ->
            fail ("`" ++ val ++ "` is not a valid game mode")


decodeMoveablePiece : Decoder MoveablePiece
decodeMoveablePiece =
    Decode.map3
        MoveablePiece
        (field "ref" decodeMoveablePieceType)
        (field "coords" (Decode.nullable decodeCoords))
        (field "target" (Decode.nullable decodeCoords))


decodeMoveablePieceType : Decoder MoveablePieceType
decodeMoveablePieceType =
    field "type" Decode.string
        |> andThen
            (\s ->
                case String.toLower s of
                    "overlay" ->
                        field "data" decodeBoardOverlay
                            |> andThen
                                (\o ->
                                    field "ref" (Decode.nullable decodeCoords)
                                        |> andThen
                                            (\c ->
                                                Decode.succeed (OverlayType o c)
                                            )
                                )

                    "piece" ->
                        field "data" decodePiece
                            |> andThen
                                (\p ->
                                    Decode.succeed (PieceType p)
                                )

                    "room" ->
                        field "data" decodeRoom
                            |> andThen
                                (\r ->
                                    Decode.succeed (RoomType r)
                                )

                    _ ->
                        fail ("Cannot decode " ++ s ++ " as moveable piece")
            )


decodeCampaignTrackerUrl : Decoder (Maybe CampaignTrackerUrl)
decodeCampaignTrackerUrl =
    field "name" Decode.string
        |> andThen
            (\name ->
                field "url" Decode.string
                    |> andThen (\url -> Decode.succeed (Just (CampaignTrackerUrl name url)))
            )


decodeExtendedRoomData : Decoder ExtendedRoomData
decodeExtendedRoomData =
    map2
        ExtendedRoomData
        (field "data" decodeRoom)
        (field "rotationPoint" decodeCoords)


encodeMoveablePiece : MoveablePiece -> Encode.Value
encodeMoveablePiece piece =
    Encode.object
        [ ( "ref", Encode.object (encodeMoveablePieceType piece.ref) )
        , ( "coords"
          , case piece.coords of
                Just c ->
                    Encode.object (encodeCoords c)

                Nothing ->
                    Encode.null
          )
        , ( "target"
          , case piece.target of
                Just c ->
                    Encode.object (encodeCoords c)

                Nothing ->
                    Encode.null
          )
        ]


encodeMoveablePieceType : MoveablePieceType -> List ( String, Encode.Value )
encodeMoveablePieceType pieceType =
    [ ( "type"
      , Encode.string
            (case pieceType of
                OverlayType _ _ ->
                    "overlay"

                PieceType _ ->
                    "piece"

                RoomType _ ->
                    "room"
            )
      )
    , ( "data"
      , Encode.object
            (case pieceType of
                OverlayType o _ ->
                    encodeOverlay o

                PieceType p ->
                    encodePiece p

                RoomType r ->
                    encodeRoom r
            )
      )
    ]
        ++ (case pieceType of
                OverlayType _ c ->
                    [ ( "ref"
                      , case c of
                            Just v ->
                                Encode.object (encodeCoords v)

                            Nothing ->
                                Encode.null
                      )
                    ]

                PieceType _ ->
                    []

                RoomType _ ->
                    []
           )


encodeCampaignTrackerUrl : CampaignTrackerUrl -> List ( String, Encode.Value )
encodeCampaignTrackerUrl tracker =
    case tracker of
        CampaignTrackerUrl name url ->
            [ ( "name", Encode.string name ), ( "url", Encode.string url ) ]
