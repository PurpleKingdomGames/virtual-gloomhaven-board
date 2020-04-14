module PointTests exposing (suite)

import Array exposing (fromList, toList)
import Expect exposing (FloatingPointTolerance(..), equalLists, within)
import Point exposing (Point, rotate, rotateArray, rotateArrayDegrees, rotateDegrees)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "The Point module"
        [ describe "Point.rotateDegrees"
            [ test "should rotate x 90 degrees around 0, 0" <|
                \_ ->
                    Expect.within
                        (Absolute 0.001)
                        0
                        (Point.rotateDegrees (Point 0 0) 90 (Point 1 0)).x
            , test "should rotate y 90 degrees around 0, 0" <|
                \_ ->
                    Expect.within
                        (Absolute 0.001)
                        1
                        (Point.rotateDegrees (Point 0 0) 90 (Point 1 0)).y
            , test "should rotate x 90 degrees around 1, 1" <|
                \_ ->
                    Expect.within
                        (Absolute 0.001)
                        2
                        (Point.rotateDegrees (Point 1 1) 90 (Point 1 0)).x
            , test "should rotate y 90 degrees around 1, 1" <|
                \_ ->
                    Expect.within
                        (Absolute 0.001)
                        0.999
                        (Point.rotateDegrees (Point 1 1) 90 (Point 1 0)).y
            ]
        , describe "Point.rotate"
            [ test "should rotate x 1.57 radians around 0, 0" <|
                \_ ->
                    Expect.within
                        (Absolute 0.001)
                        0
                        (Point.rotate (Point 0 0) 1.57 (Point 1 0)).x
            , test "should rotate y 1.57 radians around 0, 0" <|
                \_ ->
                    Expect.within
                        (Absolute 0.001)
                        1
                        (Point.rotate (Point 0 0) 1.57 (Point 1 0)).y
            ]
        , describe "Point.rotateArrayDegrees"
            [ test "should rotate an array 90 degrees around 0, 0" <|
                \_ ->
                    let
                        testArr =
                            Array.fromList [ Point 0 0, Point 1 0, Point 2 0, Point 0 1, Point 1 1, Point 2 1 ]

                        responseList =
                            [ ( 0, 0 )
                            , ( 0, 1 )
                            , ( 0, 2 )
                            , ( -1, 0 )
                            , ( -1, 1 )
                            , ( -1, 2 )
                            ]
                    in
                    Point.rotateArrayDegrees (Point 0 0) 90 testArr
                        |> Array.map (\p -> ( round p.x, round p.y ))
                        |> Array.toList
                        |> Expect.equalLists responseList
            ]
        , describe "Point.rotateArray"
            [ test "should rotate an array 1.57 radians around 0, 0" <|
                \_ ->
                    let
                        testArr =
                            Array.fromList [ Point 0 0, Point 1 0, Point 2 0, Point 0 1, Point 1 1, Point 2 1 ]

                        responseList =
                            [ ( 0, 0 )
                            , ( 0, 1 )
                            , ( 0, 2 )
                            , ( -1, 0 )
                            , ( -1, 1 )
                            , ( -1, 2 )
                            ]
                    in
                    Point.rotateArray (Point 0 0) 1.57 testArr
                        |> Array.map (\p -> ( round p.x, round p.y ))
                        |> Array.toList
                        |> Expect.equalLists responseList
            ]
        ]
