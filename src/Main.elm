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
    , players : List PlayerClass
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


type EnemyIdentity
    = Enemy Int


type PlayerClass
    = Brute
    | Cragheart
    | Mindthief
    | Scoundrel
    | Spellweaver
    | Tinkerer


type MoveableCharacter
    = PlayerClass
    | EnemyIdentity


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
    ( Model (initialize 10 (always (initialize 10 (always 0)))) [ Brute, Spellweaver, Cragheart ] DragDrop.initialState, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update _ model =
    ( model, Cmd.none )


view : Model -> Html.Html Msg
view model =
    div [ class "board" ] (toList (Array.indexedMap getBoardHtml model.board))


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


getBoardHtml : Int -> Array Int -> Html.Html Msg
getBoardHtml y row =
    div [ class "row" ] (toList (Array.indexedMap (\x _ -> div [ class "col" ] []) row))
