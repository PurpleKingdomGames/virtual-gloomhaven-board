module GameTests exposing (suite)

import Array exposing (fromList, toList)
import BoardMapTile exposing (MapTileRef(..))
import BoardOverlay exposing (BoardOverlay, BoardOverlayDirectionType(..), BoardOverlayType(..), TrapSubType(..))
import Expect exposing (equalLists)
import Game exposing (Cell, NumPlayers(..), PieceType(..), generateGameMap)
import Scenario exposing (MapTileData, Scenario)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "The Game module"
        [ describe "Game.generateGameMap"
            [ test "should output a single board" <|
                \_ ->
                    let
                        scenario =
                            Scenario 0 "Test" (MapTileData B3b [] [ BoardOverlay (Trap BearTrap) Default [ ( 0, 3 ) ], BoardOverlay (Trap BearTrap) Default [ ( 2, 3 ) ] ] [] 0) 0

                        expectedBoard =
                            [ fromList
                                [ Cell [ ( B3b, True, 0 ) ] True
                                , Cell [ ( B3b, False, 0 ) ] True
                                , Cell [ ( B3b, False, 0 ) ] True
                                , Cell [ ( B3b, False, 0 ) ] True
                                ]
                            , fromList
                                [ Cell [ ( B3b, False, 0 ) ] True
                                , Cell [ ( B3b, False, 0 ) ] True
                                , Cell [ ( B3b, False, 0 ) ] True
                                , Cell [ ( B3b, False, 0 ) ] False
                                ]
                            , fromList
                                [ Cell [ ( B3b, False, 0 ) ] True
                                , Cell [ ( B3b, False, 0 ) ] True
                                , Cell [ ( B3b, False, 0 ) ] True
                                , Cell [ ( B3b, False, 0 ) ] True
                                ]
                            , fromList
                                [ Cell [ ( B3b, False, 0 ) ] True
                                , Cell [ ( B3b, False, 0 ) ] True
                                , Cell [ ( B3b, False, 0 ) ] True
                                , Cell [ ( B3b, False, 0 ) ] False
                                ]
                            ]
                    in
                    toList (Game.generateGameMap scenario ThreePlayer).staticBoard
                        |> Expect.equalLists expectedBoard
            , test "should output a rotated single board" <|
                \_ ->
                    let
                        scenario =
                            Scenario 0 "Test" (MapTileData B3b [] [ BoardOverlay (Trap BearTrap) Default [ ( 0, 3 ), ( 1, 3 ) ], BoardOverlay (Trap BearTrap) Default [ ( 2, 3 ) ] ] [] 3) 0

                        expectedBoard =
                            [ fromList
                                [ Cell [] False
                                , Cell [] False
                                , Cell [] False
                                , Cell [] False
                                , Cell [] False
                                , Cell [] False
                                ]
                            , fromList
                                [ Cell [ ( B3b, False, 3 ) ] False
                                , Cell [ ( B3b, False, 3 ) ] True
                                , Cell [ ( B3b, False, 3 ) ] True
                                , Cell [ ( B3b, False, 3 ) ] True
                                , Cell [] False
                                , Cell [] False
                                ]
                            , fromList
                                [ Cell [] False
                                , Cell [ ( B3b, False, 3 ) ] True
                                , Cell [ ( B3b, False, 3 ) ] True
                                , Cell [ ( B3b, False, 3 ) ] True
                                , Cell [ ( B3b, False, 3 ) ] True
                                , Cell [] False
                                ]
                            , fromList
                                [ Cell [ ( B3b, False, 3 ) ] False
                                , Cell [ ( B3b, False, 3 ) ] True
                                , Cell [ ( B3b, False, 3 ) ] True
                                , Cell [ ( B3b, False, 3 ) ] True
                                , Cell [] False
                                , Cell [] False
                                ]
                            , fromList
                                [ Cell [] False
                                , Cell [ ( B3b, False, 3 ) ] True
                                , Cell [ ( B3b, False, 3 ) ] True
                                , Cell [ ( B3b, False, 3 ) ] True
                                , Cell [ ( B3b, True, 3 ) ] True
                                , Cell [] False
                                ]
                            , fromList
                                [ Cell [] False
                                , Cell [] False
                                , Cell [] False
                                , Cell [] False
                                , Cell [] False
                                , Cell [] False
                                ]
                            ]
                    in
                    toList (Game.generateGameMap scenario ThreePlayer).staticBoard
                        |> Expect.equalLists expectedBoard
            ]
        ]
