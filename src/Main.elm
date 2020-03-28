module Main exposing (main)

import Array exposing (..)
import Browser
import Dom
import Dom.DragDrop as DragDrop
import Html exposing (div)
import Html.Attributes exposing (class)


type alias Model =
    { board : Array (Array Bool)
    , players : List Player
    , dragDropState : DragDrop.State MoveableCharacter ( Int, Int )
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
    = MoveStarted MoveableCharacter
    | MoveTargetChanged ( Int, Int )
    | MoveCanceled
    | MoveCompleted MoveableCharacter ( Int, Int )


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
    ( Model (initialize 10 (always (initialize 10 (always True)))) [ Player Brute 0 0, Player Spellweaver 0 0, Player Cragheart 0 0 ] DragDrop.initialState, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MoveStarted character ->
            ( { model | dragDropState = DragDrop.startDragging model.dragDropState character }, Cmd.none )

        MoveTargetChanged coords ->
            ( { model | dragDropState = DragDrop.updateDropTarget model.dragDropState coords }, Cmd.none )

        MoveCanceled ->
            ( { model | dragDropState = DragDrop.stopDragging model.dragDropState }, Cmd.none )

        MoveCompleted character ( x, y ) ->
            let
                playerList =
                    model.players

                charModel =
                    case character of
                        MoveablePlayer p ->
                            { model
                                | players =
                                    List.map
                                        (\o ->
                                            if o.class == p.class then
                                                { o | x = x, y = y }

                                            else
                                                o
                                        )
                                        playerList
                            }

                        MoveableEnemy e ->
                            model

                newModel =
                    { charModel | dragDropState = DragDrop.initialState }
            in
            ( newModel, Cmd.none )


view : Model -> Html.Html Msg
view model =
    div [ class "board" ] (toList (Array.indexedMap (getBoardHtml model) model.board))


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


getBoardHtml : Model -> Int -> Array Bool -> Html.Html Msg
getBoardHtml model y row =
    div [ class "row" ] (toList (Array.indexedMap (getCellHtml model y) row))


getCellHtml : Model -> Int -> Int -> Bool -> Html.Html Msg
getCellHtml model y x cellValue =
    let
        dragDropMessages : DragDrop.Messages Msg MoveableCharacter ( Int, Int )
        dragDropMessages =
            { dragStarted = MoveStarted
            , dropTargetChanged = MoveTargetChanged
            , dragEnded = MoveCanceled
            , dropped = MoveCompleted
            }

        cellElement : Dom.Element Msg
        cellElement =
            Dom.element "div"
                |> Dom.addClass ("cell " ++ cellValueToString cellValue)
                |> Dom.appendChildList
                    (case findPlayerByCell x y model.players of
                        Just p ->
                            [ Dom.element "div"
                                |> Dom.addClass ("player " ++ String.toLower (playerToString p))
                                |> DragDrop.makeDraggable model.dragDropState (MoveablePlayer p) dragDropMessages
                            ]

                        Nothing ->
                            []
                    )
    in
    (if cellValue then
        DragDrop.makeDroppable model.dragDropState ( x, y ) dragDropMessages cellElement

     else
        cellElement
    )
        |> Dom.render


cellValueToString : Bool -> String
cellValueToString val =
    if val then
        "passable"

    else
        "impassable"


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
