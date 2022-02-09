module Colour exposing (Colour, blue, fromHexString, green, indigo, orange, red, toHexString, toRGBAString, toString, yellow)

import Hex exposing (fromString)
import String exposing (dropLeft, fromInt, left, length, padLeft, replace)


type alias Colour =
    { red : Int
    , green : Int
    , blue : Int
    , alpha : Int
    }


red : Colour
red =
    Colour 255 0 0 1


green : Colour
green =
    Colour 0 128 0 1


blue : Colour
blue =
    Colour 0 0 255 1


yellow : Colour
yellow =
    Colour 255 255 0 1


orange : Colour
orange =
    Colour 255 165 0 1


indigo : Colour
indigo =
    Colour 75 0 130 1


toString : Colour -> String
toString colour =
    if colour == red then
        "Red"

    else if colour == blue then
        "Blue"

    else if colour == green then
        "Green"

    else if colour == yellow then
        "Yellow"

    else if colour == orange then
        "Orange"

    else if colour == indigo then
        "Indigo"

    else
        toHexString colour


toHexString : Colour -> String
toHexString colour =
    "#"
        ++ (Hex.toString colour.red |> padLeft 2 '0')
        ++ (Hex.toString colour.green |> padLeft 2 '0')
        ++ (Hex.toString colour.blue |> padLeft 2 '0')


toRGBAString : Colour -> String
toRGBAString colour =
    "rgba("
        ++ fromInt colour.red
        ++ ","
        ++ fromInt colour.green
        ++ ","
        ++ fromInt colour.blue
        ++ ","
        ++ fromInt colour.alpha
        ++ ")"


fromHexString : String -> Colour
fromHexString str =
    let
        strNoHash =
            replace "#" "" str
    in
    Colour
        (left 2 strNoHash |> hexToInt)
        (dropLeft 2 strNoHash |> left 2 |> hexToInt)
        (dropLeft 4 strNoHash |> left 2 |> hexToInt)
        (if length strNoHash > 6 then
            dropLeft 6 strNoHash |> left 2 |> hexToInt

         else
            1
        )


hexToInt : String -> Int
hexToInt hex =
    case fromString hex of
        Ok i ->
            i

        Err _ ->
            0
