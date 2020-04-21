module ScenarioTests exposing (suite)

import BoardMapTile exposing (MapTile, MapTileRef(..))
import BoardOverlay exposing (DoorSubType(..))
import Expect exposing (equal, equalLists)
import Scenario exposing (BoardBounds, DoorData(..), MapTileData, mapTileDataToList)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "The Scenario module"
        [ describe "Scenario.mapTileDataToList"
            [ test "should output a converted grid for M1a" <|
                \_ ->
                    let
                        tileData =
                            MapTileData M1a [] [] []

                        expectedResult =
                            [ MapTile M1a 0 0 0 0 False True
                            , MapTile M1a 1 0 1 0 True True
                            , MapTile M1a 2 0 2 0 True True
                            , MapTile M1a 3 0 3 0 True True
                            , MapTile M1a 4 0 4 0 True True
                            , MapTile M1a 5 0 5 0 False True
                            , MapTile M1a 0 1 0 1 True True
                            , MapTile M1a 1 1 1 1 True True
                            , MapTile M1a 2 1 2 1 True True
                            , MapTile M1a 3 1 3 1 True True
                            , MapTile M1a 4 1 4 1 True True
                            , MapTile M1a 5 1 5 1 False True
                            , MapTile M1a 0 2 0 2 True True
                            , MapTile M1a 1 2 1 2 True True
                            , MapTile M1a 2 2 2 2 True True
                            , MapTile M1a 3 2 3 2 True True
                            , MapTile M1a 4 2 4 2 True True
                            , MapTile M1a 5 2 5 2 True True
                            , MapTile M1a 0 3 0 3 True True
                            , MapTile M1a 1 3 1 3 True True
                            , MapTile M1a 2 3 2 3 True True
                            , MapTile M1a 3 3 3 3 True True
                            , MapTile M1a 4 3 4 3 True True
                            , MapTile M1a 5 3 5 3 False True
                            , MapTile M1a 0 4 0 4 True True
                            , MapTile M1a 1 4 1 4 True True
                            , MapTile M1a 2 4 2 4 True True
                            , MapTile M1a 3 4 3 4 True True
                            , MapTile M1a 4 4 4 4 True True
                            , MapTile M1a 5 4 5 4 True True
                            , MapTile M1a 0 5 0 5 True True
                            , MapTile M1a 1 5 1 5 True True
                            , MapTile M1a 2 5 2 5 True True
                            , MapTile M1a 3 5 3 5 True True
                            , MapTile M1a 4 5 4 5 True True
                            , MapTile M1a 5 5 5 5 False True
                            , MapTile M1a 0 6 0 6 False True
                            , MapTile M1a 1 6 1 6 True True
                            , MapTile M1a 2 6 2 6 True True
                            , MapTile M1a 3 6 3 6 True True
                            , MapTile M1a 4 6 4 6 True True
                            , MapTile M1a 5 6 5 6 False True
                            ]
                    in
                    Scenario.mapTileDataToList tileData
                        |> Tuple.first
                        |> Expect.equalLists expectedResult
            , test "should output a converted grid for M1a with A1a underneath" <|
                \_ ->
                    let
                        a1aData =
                            MapTileData A1a [] [] []

                        tileData =
                            MapTileData M1a [ DoorLink Stone ( 2, 7 ) ( 1, 0 ) 0 a1aData ] [] []

                        expectedResult =
                            [ MapTile M1a 0 0 0 0 False True
                            , MapTile M1a 1 0 1 0 True True
                            , MapTile M1a 2 0 2 0 True True
                            , MapTile M1a 3 0 3 0 True True
                            , MapTile M1a 4 0 4 0 True True
                            , MapTile M1a 5 0 5 0 False True
                            , MapTile M1a 0 1 0 1 True True
                            , MapTile M1a 1 1 1 1 True True
                            , MapTile M1a 2 1 2 1 True True
                            , MapTile M1a 3 1 3 1 True True
                            , MapTile M1a 4 1 4 1 True True
                            , MapTile M1a 5 1 5 1 False True
                            , MapTile M1a 0 2 0 2 True True
                            , MapTile M1a 1 2 1 2 True True
                            , MapTile M1a 2 2 2 2 True True
                            , MapTile M1a 3 2 3 2 True True
                            , MapTile M1a 4 2 4 2 True True
                            , MapTile M1a 5 2 5 2 True True
                            , MapTile M1a 0 3 0 3 True True
                            , MapTile M1a 1 3 1 3 True True
                            , MapTile M1a 2 3 2 3 True True
                            , MapTile M1a 3 3 3 3 True True
                            , MapTile M1a 4 3 4 3 True True
                            , MapTile M1a 5 3 5 3 False True
                            , MapTile M1a 0 4 0 4 True True
                            , MapTile M1a 1 4 1 4 True True
                            , MapTile M1a 2 4 2 4 True True
                            , MapTile M1a 3 4 3 4 True True
                            , MapTile M1a 4 4 4 4 True True
                            , MapTile M1a 5 4 5 4 True True
                            , MapTile M1a 0 5 0 5 True True
                            , MapTile M1a 1 5 1 5 True True
                            , MapTile M1a 2 5 2 5 True True
                            , MapTile M1a 3 5 3 5 True True
                            , MapTile M1a 4 5 4 5 True True
                            , MapTile M1a 5 5 5 5 False True
                            , MapTile M1a 0 6 0 6 False True
                            , MapTile M1a 1 6 1 6 True True
                            , MapTile M1a 2 6 2 6 True True
                            , MapTile M1a 3 6 3 6 True True
                            , MapTile M1a 4 6 4 6 True True
                            , MapTile M1a 5 6 5 6 False True
                            , MapTile A1a 1 7 0 0 False True
                            , MapTile A1a 2 7 1 0 False True
                            , MapTile A1a 3 7 2 0 False True
                            , MapTile A1a 4 7 3 0 False True
                            , MapTile A1a 5 7 4 0 False True
                            , MapTile A1a 1 8 0 1 True True
                            , MapTile A1a 2 8 1 1 True True
                            , MapTile A1a 3 8 2 1 True True
                            , MapTile A1a 4 8 3 1 True True
                            , MapTile A1a 5 8 4 1 False True
                            , MapTile A1a 1 9 0 2 True True
                            , MapTile A1a 2 9 1 2 True True
                            , MapTile A1a 3 9 2 2 True True
                            , MapTile A1a 4 9 3 2 True True
                            , MapTile A1a 5 9 4 2 True True
                            , MapTile A1a 1 10 0 3 False True
                            , MapTile A1a 2 10 1 3 False True
                            , MapTile A1a 3 10 2 3 False True
                            , MapTile A1a 4 10 3 3 False True
                            , MapTile A1a 5 10 4 3 False True
                            ]
                    in
                    Scenario.mapTileDataToList tileData
                        |> Tuple.first
                        |> Expect.equalLists expectedResult
            , test "should output a converted grid for M1a with A1a to the left (see scenario #2 for example)" <|
                \_ ->
                    let
                        a1aData =
                            MapTileData A1a [] [] []

                        tileData =
                            MapTileData M1a [ DoorLink Stone ( 0, 6 ) ( 1, 0 ) 1 a1aData ] [] []

                        expectedResult =
                            [ MapTile M1a 0 0 0 0 False True
                            , MapTile M1a 1 0 1 0 True True
                            , MapTile M1a 2 0 2 0 True True
                            , MapTile M1a 3 0 3 0 True True
                            , MapTile M1a 4 0 4 0 True True
                            , MapTile M1a 5 0 5 0 False True
                            , MapTile M1a 0 1 0 1 True True
                            , MapTile M1a 1 1 1 1 True True
                            , MapTile M1a 2 1 2 1 True True
                            , MapTile M1a 3 1 3 1 True True
                            , MapTile M1a 4 1 4 1 True True
                            , MapTile M1a 5 1 5 1 False True
                            , MapTile M1a 0 2 0 2 True True
                            , MapTile M1a 1 2 1 2 True True
                            , MapTile M1a 2 2 2 2 True True
                            , MapTile M1a 3 2 3 2 True True
                            , MapTile M1a 4 2 4 2 True True
                            , MapTile M1a 5 2 5 2 True True
                            , MapTile M1a 0 3 0 3 True True
                            , MapTile M1a 1 3 1 3 True True
                            , MapTile M1a 2 3 2 3 True True
                            , MapTile M1a 3 3 3 3 True True
                            , MapTile M1a 4 3 4 3 True True
                            , MapTile M1a 5 3 5 3 False True
                            , MapTile M1a 0 4 0 4 True True
                            , MapTile M1a 1 4 1 4 True True
                            , MapTile M1a 2 4 2 4 True True
                            , MapTile M1a 3 4 3 4 True True
                            , MapTile M1a 4 4 4 4 True True
                            , MapTile M1a 5 4 5 4 True True
                            , MapTile M1a 0 5 0 5 True True
                            , MapTile M1a 1 5 1 5 True True
                            , MapTile M1a 2 5 2 5 True True
                            , MapTile M1a 3 5 3 5 True True
                            , MapTile M1a 4 5 4 5 True True
                            , MapTile M1a 5 5 5 5 False True
                            , MapTile M1a 0 6 0 6 False True
                            , MapTile M1a 1 6 1 6 True True
                            , MapTile M1a 2 6 2 6 True True
                            , MapTile M1a 3 6 3 6 True True
                            , MapTile M1a 4 6 4 6 True True
                            , MapTile M1a 5 6 5 6 False True
                            , MapTile A1a -1 5 0 0 False True
                            , MapTile A1a 0 6 1 0 False True
                            , MapTile A1a 0 7 2 0 False True
                            , MapTile A1a 1 8 3 0 False True
                            , MapTile A1a 1 9 4 0 False True
                            , MapTile A1a -1 6 0 1 True True
                            , MapTile A1a -1 7 1 1 True True
                            , MapTile A1a 0 8 2 1 True True
                            , MapTile A1a 0 9 3 1 True True
                            , MapTile A1a 1 10 4 1 False True
                            , MapTile A1a -2 6 0 2 True True
                            , MapTile A1a -2 7 1 2 True True
                            , MapTile A1a -1 8 2 2 True True
                            , MapTile A1a -1 9 3 2 True True
                            , MapTile A1a 0 10 4 2 True True
                            , MapTile A1a -3 7 0 3 False True
                            , MapTile A1a -2 8 1 3 False True
                            , MapTile A1a -2 9 2 3 False True
                            , MapTile A1a -1 10 3 3 False True
                            , MapTile A1a -1 11 4 3 False True
                            ]
                    in
                    Scenario.mapTileDataToList tileData
                        |> Tuple.first
                        |> Expect.equalLists expectedResult
            , test "should output a the correct bounding box for complicated boards" <|
                \_ ->
                    let
                        a1aData =
                            MapTileData A1a [] [] []

                        tileData =
                            MapTileData M1a [ DoorLink Stone ( 0, 6 ) ( 1, 0 ) 1 a1aData ] [] []

                        expectedResult =
                            BoardBounds -3 5 0 11
                    in
                    Scenario.mapTileDataToList tileData
                        |> Tuple.second
                        |> Expect.equal expectedResult
            ]
        ]
