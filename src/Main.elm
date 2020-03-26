module Main exposing (main)

import Array exposing (..)
import Browser
import Dom.DragDrop as DragDrop
import Html exposing (div)
import Html.Attributes exposing (class)


type Id
    = Id Int


type alias Model =
    { board : Array (Array Int)
    , players : List Player
    , dragDropState : DragDrop.State Id MoveableCharacter
    }


type Enemy
    = BanditGuard
    | BanditArcher
    | CityGuard
    | CityArcher
    | InoxGuard
    | InoxArcher
    | InoxShaman
    | VermlingScout
    | VermlingShaman
    | LivingBones
    | LivingCorpse
    | LivingSpirit
    | Cultist
    | FlameDemon
    | FrostDemon
    | EarthDemon
    | WindDemon
    | NightDemon
    | SunDemon
    | Ooze
    | GiantViper
    | ForestImp
    | Hound
    | CaveBear
    | StoneGolem
    | AncientArtillery
    | ViciousDrake
    | SpittingDrake
    | Lurker
    | SavvasIcestorm
    | SavvaLavaflow
    | HarrowerInfester
    | DeepTerror
    | BlackImp
    | BanditCommander
    | MercilessOverseer
    | InoxBodyguard
    | CaptainOfTheGuard
    | Jekserah
    | PrimeDemon
    | ElderDrake
    | TheBetrayer
    | TheColorless
    | TheSightlessEye
    | DarkRider
    | WingedHorror
    | TheGoom


type alias EnemyIdentity =
    { enemy : Enemy
    , id : Int
    , x : Int
    , y : Int
    }


type PlayerClass
    = Brute
    | Cragheart
    | Mindthief
    | Scoundrel
    | Spellweaver
    | Tinkerer


type alias Player =
    { class : PlayerClass
    , x : Int
    , y : Int
    }


type MoveableCharacter
    = MoveablePlayer Player
    | MoveableEnemy EnemyIdentity


type Msg
    = NoCommand


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : () -> ( Model, Cmd Msg )
init _ =
    ( Model (initialize 10 (always (initialize 10 (always 0)))) [ Player Brute 0 0, Player Spellweaver 0 0, Player Cragheart 0 0 ] DragDrop.initialState, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update _ model =
    ( model, Cmd.none )


view : Model -> Html.Html Msg
view model =
    div [ class "board" ] (toList (Array.indexedMap (getBoardHtml model.players) model.board))


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


getBoardHtml : List Player -> Int -> Array Int -> Html.Html Msg
getBoardHtml players y row =
    div [ class "row" ] (toList (Array.indexedMap (getCellHtml players y) row))


getCellHtml : List Player -> Int -> Int -> Int -> Html.Html Msg
getCellHtml players y x cellValue =
    div [ class ("cell-" ++ cellValueToString cellValue) ]
        (case findPlayerByCell x y players of
            Just p ->
                [ div [ class ("player-" ++ String.toLower (playerToString p)) ] [] ]

            Nothing ->
                []
        )


cellValueToString : Int -> String
cellValueToString val =
    case val of
        0 ->
            "impassable"

        _ ->
            "passable"


findPlayerByCell : Int -> Int -> List Player -> Maybe Player
findPlayerByCell x y players =
    List.head (List.filter (\p -> p.x == x && p.y == y) players)


playerToString : Player -> String
playerToString player =
    case player.class of
        Brute ->
            "Brute"

        Cragheart ->
            "Cragheart"

        Mindthief ->
            "Mindthief"

        Scoundrel ->
            "Scoundrel"

        Spellweaver ->
            "Spellweaver"

        Tinkerer ->
            "Tinkerer"
