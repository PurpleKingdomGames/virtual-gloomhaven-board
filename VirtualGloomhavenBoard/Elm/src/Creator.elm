module Creator exposing (main)

import Browser
import Html exposing (div)


type alias Model =
    {}


type Msg
    = NoOp


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
    ( {}
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )


view : Model -> Html.Html Msg
view model =
    div
        []
        []


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch []
