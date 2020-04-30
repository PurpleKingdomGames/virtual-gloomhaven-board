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
                            Scenario 0 "Test" (MapTileData B3b [] [ BoardOverlay (Trap BearTrap) Default ( ( 0, 3 ), Nothing ), BoardOverlay (Trap BearTrap) Default ( ( 2, 3 ), Nothing ) ] [] 0) 0

                        expectedBoard =
                            [ fromList
                                [ Cell [ ( B3b, True, 0 ) ] True True None []
                                , Cell [ ( B3b, False, 0 ) ] True True None []
                                , Cell [ ( B3b, False, 0 ) ] True True None []
                                , Cell [ ( B3b, False, 0 ) ] True True None []
                                ]
                            , fromList
                                [ Cell [ ( B3b, False, 0 ) ] True True None []
                                , Cell [ ( B3b, False, 0 ) ] True True None []
                                , Cell [ ( B3b, False, 0 ) ] True True None []
                                , Cell [ ( B3b, False, 0 ) ] True False None []
                                ]
                            , fromList
                                [ Cell [ ( B3b, False, 0 ) ] True True None []
                                , Cell [ ( B3b, False, 0 ) ] True True None []
                                , Cell [ ( B3b, False, 0 ) ] True True None []
                                , Cell [ ( B3b, False, 0 ) ] True True None []
                                ]
                            , fromList
                                [ Cell [ ( B3b, False, 0 ) ] True True None [ BoardOverlay (Trap BearTrap) Default ( ( 0, 3 ), Nothing ) ]
                                , Cell [ ( B3b, False, 0 ) ] True True None []
                                , Cell [ ( B3b, False, 0 ) ] True True None [ BoardOverlay (Trap BearTrap) Default ( ( 2, 3 ), Nothing ) ]
                                , Cell [ ( B3b, False, 0 ) ] True False None []
                                ]
                            ]
                    in
                    toList (Game.generateGameMap scenario ThreePlayer)
                        |> Expect.equalLists expectedBoard
            , test "should output a rotated single board" <|
                \_ ->
                    let
                        scenario =
                            Scenario 0 "Test" (MapTileData B3b [] [ BoardOverlay (Trap BearTrap) Default ( ( 0, 3 ), Just ( 1, 3 ) ), BoardOverlay (Trap BearTrap) Default ( ( 2, 3 ), Nothing ) ] [] 3) 0

                        expectedBoard =
                            [ fromList
                                [ Cell [ ( B3b, False, 0 ) ] True False None []
                                , Cell [ ( B3b, False, 0 ) ] True True None [ BoardOverlay (Trap BearTrap) Default ( ( 2, 3 ), Nothing ) ]
                                , Cell [ ( B3b, False, 0 ) ] True True None []
                                , Cell [ ( B3b, False, 0 ) ] True True None [ BoardOverlay (Trap BearTrap) Default ( ( 0, 3 ), Nothing ) ]
                                ]
                            , fromList
                                [ Cell [ ( B3b, True, 0 ) ] True True None []
                                , Cell [ ( B3b, False, 0 ) ] True True None []
                                , Cell [ ( B3b, False, 0 ) ] True True None []
                                , Cell [ ( B3b, False, 0 ) ] True True None []
                                ]
                            , fromList
                                [ Cell [ ( B3b, False, 0 ) ] True True None []
                                , Cell [ ( B3b, False, 0 ) ] True True None []
                                , Cell [ ( B3b, False, 0 ) ] True True None []
                                , Cell [ ( B3b, False, 0 ) ] True False None []
                                ]
                            , fromList
                                [ Cell [ ( B3b, False, 0 ) ] True True None []
                                , Cell [ ( B3b, False, 0 ) ] True True None []
                                , Cell [ ( B3b, False, 0 ) ] True True None []
                                , Cell [ ( B3b, False, 0 ) ] True True None []
                                ]
                            ]
                    in
                    toList (Game.generateGameMap scenario ThreePlayer)
                        |> Expect.equalLists expectedBoard
            ]
        ]
