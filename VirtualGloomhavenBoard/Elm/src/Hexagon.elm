module Hexagon exposing (cubeToOddRow, oddRowToCube, rotate)

import Bitwise


rotate : ( Int, Int ) -> ( Int, Int ) -> Int -> ( Int, Int )
rotate origin rotationPoint numTurns =
    let
        rotateResult =
            singleRotate origin rotationPoint
    in
    case numTurns of
        0 ->
            origin

        1 ->
            rotateResult

        other ->
            if other < 0 then
                rotate rotateResult rotationPoint (other + 1)

            else
                rotate rotateResult rotationPoint (other - 1)


singleRotate : ( Int, Int ) -> ( Int, Int ) -> ( Int, Int )
singleRotate origin rotationPoint =
    let
        ( originX, originY, originZ ) =
            oddRowToCube origin

        ( rotateX, rotateY, rotateZ ) =
            oddRowToCube rotationPoint

        ( rX, rY, rZ ) =
            ( -(originZ - rotateZ), -(originX - rotateX), -(originY - rotateY) )
    in
    cubeToOddRow
        ( rX + rotateX, rY + rotateY, rZ + rotateZ )


cubeToOddRow : ( Int, Int, Int ) -> ( Int, Int )
cubeToOddRow ( x, _, z ) =
    ( x + (z - Bitwise.and z 1) // 2
    , z
    )


oddRowToCube : ( Int, Int ) -> ( Int, Int, Int )
oddRowToCube ( x, y ) =
    let
        newX =
            x - (y - Bitwise.and y 1) // 2
    in
    ( newX
    , -newX - y
    , y
    )
