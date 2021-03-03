module HtmlEvents exposing (onClickPreventDefault)

import Html exposing (Attribute)
import Html.Events exposing (custom)
import Json.Decode as Decode


onClickPreventDefault : msg -> Attribute msg
onClickPreventDefault msg =
    custom "click" (Decode.succeed { message = msg, stopPropagation = True, preventDefault = True })
