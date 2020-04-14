module ScenarioTests exposing (suite)

import BoardMapTiles exposing (MapTile, MapTileRef(..))
import BoardOverlays exposing (DoorSubType(..))
import Expect exposing (equalLists)
import Point exposing (Point)
import Scenario exposing (DoorData(..), MapTileData, Scenario, mapTileDataToList)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "The Scenario module"
        [ describe "Scenario.mapTileDataToList"
            [ test "should output a converted grid for M1a" <|
                \_ ->
                    let
                        tileData =
                            MapTileData M1a [] []

                        expectedResult =
                            [ MapTile M1a 0 0 False True
                            , MapTile M1a 1 0 True True
                            , MapTile M1a 2 0 True True
                            , MapTile M1a 3 0 True True
                            , MapTile M1a 4 0 True True
                            , MapTile M1a 5 0 False True
                            , MapTile M1a 0 1 True True
                            , MapTile M1a 1 1 True True
                            , MapTile M1a 2 1 True True
                            , MapTile M1a 3 1 True True
                            , MapTile M1a 4 1 True True
                            , MapTile M1a 5 1 False True
                            , MapTile M1a 0 2 True True
                            , MapTile M1a 1 2 True True
                            , MapTile M1a 2 2 True True
                            , MapTile M1a 3 2 True True
                            , MapTile M1a 4 2 True True
                            , MapTile M1a 5 2 True True
                            , MapTile M1a 0 3 True True
                            , MapTile M1a 1 3 True True
                            , MapTile M1a 2 3 True True
                            , MapTile M1a 3 3 True True
                            , MapTile M1a 4 3 True True
                            , MapTile M1a 5 3 False True
                            , MapTile M1a 0 4 True True
                            , MapTile M1a 1 4 True True
                            , MapTile M1a 2 4 True True
                            , MapTile M1a 3 4 True True
                            , MapTile M1a 4 4 True True
                            , MapTile M1a 5 4 True True
                            , MapTile M1a 0 5 True True
                            , MapTile M1a 1 5 True True
                            , MapTile M1a 2 5 True True
                            , MapTile M1a 3 5 True True
                            , MapTile M1a 4 5 True True
                            , MapTile M1a 5 5 False True
                            , MapTile M1a 0 6 False True
                            , MapTile M1a 1 6 True True
                            , MapTile M1a 2 6 True True
                            , MapTile M1a 3 6 True True
                            , MapTile M1a 4 6 True True
                            , MapTile M1a 5 6 False True
                            ]
                    in
                    Scenario.mapTileDataToList tileData
                        |> Expect.equalLists expectedResult
            , test "should output a converted grid for M1a with A1a underneath" <|
                \_ ->
                    let
                        a1aData =
                            MapTileData A1a [] []

                        tileData =
                            MapTileData M1a [ DoorLink Stone (Point 2 7) (Point 1 0) 0 a1aData ] []

                        expectedResult =
                            [ MapTile M1a 0 0 False True
                            , MapTile M1a 1 0 True True
                            , MapTile M1a 2 0 True True
                            , MapTile M1a 3 0 True True
                            , MapTile M1a 4 0 True True
                            , MapTile M1a 5 0 False True
                            , MapTile M1a 0 1 True True
                            , MapTile M1a 1 1 True True
                            , MapTile M1a 2 1 True True
                            , MapTile M1a 3 1 True True
                            , MapTile M1a 4 1 True True
                            , MapTile M1a 5 1 False True
                            , MapTile M1a 0 2 True True
                            , MapTile M1a 1 2 True True
                            , MapTile M1a 2 2 True True
                            , MapTile M1a 3 2 True True
                            , MapTile M1a 4 2 True True
                            , MapTile M1a 5 2 True True
                            , MapTile M1a 0 3 True True
                            , MapTile M1a 1 3 True True
                            , MapTile M1a 2 3 True True
                            , MapTile M1a 3 3 True True
                            , MapTile M1a 4 3 True True
                            , MapTile M1a 5 3 False True
                            , MapTile M1a 0 4 True True
                            , MapTile M1a 1 4 True True
                            , MapTile M1a 2 4 True True
                            , MapTile M1a 3 4 True True
                            , MapTile M1a 4 4 True True
                            , MapTile M1a 5 4 True True
                            , MapTile M1a 0 5 True True
                            , MapTile M1a 1 5 True True
                            , MapTile M1a 2 5 True True
                            , MapTile M1a 3 5 True True
                            , MapTile M1a 4 5 True True
                            , MapTile M1a 5 5 False True
                            , MapTile M1a 0 6 False True
                            , MapTile M1a 1 6 True True
                            , MapTile M1a 2 6 True True
                            , MapTile M1a 3 6 True True
                            , MapTile M1a 4 6 True True
                            , MapTile M1a 5 6 False True
                            , MapTile A1a 1 7 False True
                            , MapTile A1a 2 7 False True
                            , MapTile A1a 3 7 False True
                            , MapTile A1a 4 7 False True
                            , MapTile A1a 5 7 False True
                            , MapTile A1a 1 8 True True
                            , MapTile A1a 2 8 True True
                            , MapTile A1a 3 8 True True
                            , MapTile A1a 4 8 True True
                            , MapTile A1a 5 8 False True
                            , MapTile A1a 1 9 True True
                            , MapTile A1a 2 9 True True
                            , MapTile A1a 3 9 True True
                            , MapTile A1a 4 9 True True
                            , MapTile A1a 5 9 True True
                            , MapTile A1a 1 10 False True
                            , MapTile A1a 2 10 False True
                            , MapTile A1a 3 10 False True
                            , MapTile A1a 4 10 False True
                            , MapTile A1a 5 10 False True
                            ]
                    in
                    Scenario.mapTileDataToList tileData
                        |> Expect.equalLists expectedResult
            ]
        ]
