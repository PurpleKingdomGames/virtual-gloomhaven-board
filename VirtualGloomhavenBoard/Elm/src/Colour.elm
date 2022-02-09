module Colour exposing (Colour, fromHexString, toHexString, toRGBAString)

import Hex exposing (fromString, toString)
import String exposing (dropLeft, fromInt, left, length, padLeft, replace)


type alias Colour =
    { red : Int
    , green : Int
    , blue : Int
    , alpha : Int
    }


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
