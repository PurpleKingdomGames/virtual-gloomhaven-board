module HexagonTests exposing (suite)

import Expect exposing (equal)
import Hexagon exposing (rotate)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "The Hexagon module"
        [ describe "Hexagon.rotate"
            [ test "should rotate (0, 2) 0 turn around 0, 0" <|
                \_ ->
                    Expect.equal
                        ( 0, 2 )
                        (Hexagon.rotate ( 0, 2 ) ( 0, 0 ) 0)
            , test "should rotate (0, 2) 1 turn around 0, 0" <|
                \_ ->
                    Expect.equal
                        ( -2, 1 )
                        (Hexagon.rotate ( 0, 2 ) ( 0, 0 ) 1)
            , test "should rotate (0, 2) 1 turn around 0, 3" <|
                \_ ->
                    Expect.equal
                        ( 1, 2 )
                        (Hexagon.rotate ( 0, 2 ) ( 0, 3 ) 1)
            , test "should rotate (0, 2) 3 turns around 0, 3" <|
                \_ ->
                    Expect.equal
                        ( 1, 4 )
                        (Hexagon.rotate ( 0, 2 ) ( 0, 3 ) 3)
            , test "should rotate (-1, 6) 1 turn around 0, 6" <|
                \_ ->
                    Expect.equal
                        ( -1, 5 )
                        (Hexagon.rotate ( -1, 6 ) ( 0, 6 ) 1)
            ]
        ]
