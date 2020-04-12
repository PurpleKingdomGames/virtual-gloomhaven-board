module Point exposing (Point, rotate, rotateArray, rotateArrayDegrees, rotateDegrees)

import Array exposing (Array, map)


type alias Point =
    { x : Float
    , y : Float
    }


rotateArrayDegrees : Point -> Float -> Array Point -> Array Point
rotateArrayDegrees origin degrees points =
    rotateArray origin (degrees * (pi / 180)) points


rotateArray : Point -> Float -> Array Point -> Array Point
rotateArray origin radians points =
    Array.map (rotate origin radians) points


rotateDegrees : Point -> Float -> Point -> Point
rotateDegrees origin degrees point =
    rotate origin (degrees * (pi / 180)) point


rotate : Point -> Float -> Point -> Point
rotate origin radians point =
    let
        s =
            sin radians

        c =
            cos radians

        -- Translate point back to origin
        newOrigin =
            Point (origin.x - point.x) (origin.y - point.y)

        -- Rotate point
        xnew =
            newOrigin.x * c - newOrigin.y * s

        ynew =
            newOrigin.x * s + newOrigin.y * c
    in
    -- Translate point back
    Point (xnew + point.x) (ynew + point.y)
