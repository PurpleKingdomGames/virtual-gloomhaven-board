module GameTests exposing (suite)

import Array exposing (Array, fromList, toList)
import BoardMapTile exposing (MapTile, MapTileRef(..), refToString)
import BoardOverlay exposing (BoardOverlay, BoardOverlayType(..), TrapSubType(..))
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
                            Scenario 0 "Test" (MapTileData B3b [] [ BoardOverlay (Trap BearTrap) ( ( 0, 3 ), Nothing ), BoardOverlay (Trap BearTrap) ( ( 2, 3 ), Nothing ) ] []) 0

                        expectedBoard =
                            [ fromList
                                [ Cell [ ( B3b, True ) ] True True None []
                                , Cell [ ( B3b, False ) ] True True None []
                                , Cell [ ( B3b, False ) ] True True None []
                                , Cell [ ( B3b, False ) ] True True None []
                                ]
                            , fromList
                                [ Cell [ ( B3b, False ) ] True True None []
                                , Cell [ ( B3b, False ) ] True True None []
                                , Cell [ ( B3b, False ) ] True True None []
                                , Cell [ ( B3b, False ) ] True False None []
                                ]
                            , fromList
                                [ Cell [ ( B3b, False ) ] True True None []
                                , Cell [ ( B3b, False ) ] True True None []
                                , Cell [ ( B3b, False ) ] True True None []
                                , Cell [ ( B3b, False ) ] True True None []
                                ]
                            , fromList
                                [ Cell [ ( B3b, False ) ] True True None [ BoardOverlay (Trap BearTrap) ( ( 0, 3 ), Nothing ) ]
                                , Cell [ ( B3b, False ) ] True True None []
                                , Cell [ ( B3b, False ) ] True True None [ BoardOverlay (Trap BearTrap) ( ( 2, 3 ), Nothing ) ]
                                , Cell [ ( B3b, False ) ] True False None []
                                ]
                            ]
                    in
                    toList (Game.generateGameMap scenario ThreePlayer)
                        |> Expect.equalLists expectedBoard
            ]
        ]
