port module AppStorage exposing (AppModeType(..), AppOverrides, Config, GameModeType(..), empty, emptyOverrides, loadFromStorage, loadOverrides, saveToStorage)

import Character exposing (CharacterClass, stringToCharacter)
import Game exposing (GameState)
import GameSync exposing (decodeGameState, encodeGameState)
import Html exposing (s)
import Json.Decode as Decode exposing (Decoder, andThen, decodeValue, fail, field, map2, map4, map6, maybe, string, succeed)
import Json.Encode as Encode exposing (object, string)
import List exposing (filterMap)


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
    | ServerConfigDialog
    | PlayerChoiceDialog


emptyConfig : Config
emptyConfig =
    Config Game MovePiece Nothing True


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
        ]


encodeAppMode : AppModeType -> String
encodeAppMode appMode =
    case appMode of
        Game ->
            "game"

        ScenarioDialog ->
            "scenarioDialog"

        ServerConfigDialog ->
            "serverConfigDialog"

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
    map4 Config
        (field "appMode" (Decode.string |> Decode.andThen decodeAppMode))
        (field "gameMode" (Decode.string |> Decode.andThen decodeGameMode))
        (field "roomCode" (Decode.nullable Decode.string))
        (field "showRoomCode" Decode.bool)


decodeAppMode : String -> Decoder AppModeType
decodeAppMode val =
    case String.toLower val of
        "game" ->
            succeed Game

        "scenariodialog" ->
            succeed ScenarioDialog

        "serverconfigdialog" ->
            succeed ServerConfigDialog

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
