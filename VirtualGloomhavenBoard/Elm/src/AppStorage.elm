port module AppStorage exposing (AppModeType(..), AppOverrides, Config, GameModeType(..), MoveablePiece, MoveablePieceType(..), decodeMoveablePiece, empty, emptyOverrides, encodeMoveablePiece, loadFromStorage, loadOverrides, saveToStorage)

import BoardOverlay exposing (BoardOverlay)
import Character exposing (CharacterClass, stringToCharacter)
import Game exposing (GameState, Piece)
import GameSync exposing (decodeGameState, decodePiece, encodeGameState, encodeOverlay, encodePiece)
import Html exposing (s)
import Json.Decode as Decode exposing (Decoder, andThen, decodeValue, fail, field, map2, map4, map5, map6, maybe, string, succeed)
import Json.Encode as Encode exposing (object, string)
import List exposing (filterMap)
import SharedSync exposing (decodeBoardOverlay)


port saveData : Encode.Value -> Cmd msg


type alias StoredData =
    { config : Config
    , gameState : GameState
    }


type alias Config =
    { appMode : AppModeType
    , gameMode : GameModeType
    , roomCode : Maybe String
    , showRoomCode : Bool
    , boardOnly : Bool
    }


type alias AppOverrides =
    { initScenario : Maybe Int
    , initPlayers : Maybe (List CharacterClass)
    , initRoomCodeSeed : Maybe Int
    , lockScenario : Bool
    , lockPlayers : Bool
    , lockRoomCode : Bool
    }


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


emptyConfig : Config
emptyConfig =
    Config Game MovePiece Nothing True False


empty : ( GameState, Config )
empty =
    ( Game.emptyState, emptyConfig )


emptyOverrides : AppOverrides
emptyOverrides =
    AppOverrides Nothing Nothing Nothing False False False


saveToStorage : GameState -> Config -> Cmd msg
saveToStorage gameState config =
    saveData (encodeStoredData (StoredData config gameState))


loadFromStorage : Decode.Value -> Result Decode.Error ( GameState, Config )
loadFromStorage value =
    decodeStoredData value


loadOverrides : Decode.Value -> Result Decode.Error AppOverrides
loadOverrides value =
    decodeValue appOverridesDecoder value


encodeStoredData : StoredData -> Encode.Value
encodeStoredData data =
    object
        [ ( "config", encodeConfig data.config )
        , ( "gameState", encodeGameState data.gameState )
        ]


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
        , ( "gameMode", Encode.string (encodeGameMode config.gameMode) )
        , ( "roomCode"
          , case config.roomCode of
                Just r ->
                    Encode.string r

                Nothing ->
                    Encode.null
          )
        , ( "showRoomCode", Encode.bool config.showRoomCode )
        , ( "boardOnly", Encode.bool config.boardOnly )
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


appOverridesDecoder : Decoder AppOverrides
appOverridesDecoder =
    map6 AppOverrides
        (field "initScenario" (maybe Decode.int))
        (field "initPlayers"
            (maybe (Decode.list Decode.string)
                |> andThen
                    (\s ->
                        Maybe.map (\a -> filterMap (\c -> stringToCharacter c) a) s
                            |> succeed
                    )
            )
        )
        (field "initRoomCodeSeed" (maybe Decode.int))
        (field "lockScenario" Decode.bool)
        (field "lockPlayers" Decode.bool)
        (field "lockRoomCode" Decode.bool)


decodeConfig : Decoder Config
decodeConfig =
    map5 Config
        (field "appMode" (Decode.string |> Decode.andThen decodeAppMode))
        (field "gameMode" (Decode.string |> Decode.andThen decodeGameMode))
        (field "roomCode" (Decode.nullable Decode.string))
        (field "showRoomCode" Decode.bool)
        (maybe (field "boardOnly" Decode.bool) |> andThen (\b -> succeed (Maybe.withDefault False b)))


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

                    _ ->
                        fail ("Cannot decode " ++ s ++ " as moveable piece")
            )


decodeCoords : Decoder ( Int, Int )
decodeCoords =
    field "x" Decode.int
        |> andThen
            (\x ->
                field "y" Decode.int
                    |> andThen (\y -> Decode.succeed ( x, y ))
            )


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
            )
      )
    , ( "data"
      , Encode.object
            (case pieceType of
                OverlayType o _ ->
                    encodeOverlay o

                PieceType p ->
                    encodePiece p
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
           )


encodeCoords : ( Int, Int ) -> List ( String, Encode.Value )
encodeCoords ( x, y ) =
    [ ( "x", Encode.int x )
    , ( "y", Encode.int y )
    ]
