module GameSyncTests exposing (suite)

import Array exposing (fromList, toList)
import BoardMapTile exposing (MapTileRef(..))
import BoardOverlay exposing (BoardOverlay, BoardOverlayDirectionType(..), BoardOverlayType(..), ChestType(..), DoorSubType(..), ObstacleSubType(..), TrapSubType(..), TreasureSubType(..))
import Character exposing (CharacterClass(..))
import Expect exposing (equalLists)
import Game exposing (AIType(..), Cell, GameState, NumPlayers(..), Piece, PieceType(..), generateGameMap)
import GameSync exposing (decodeGameState)
import Json.Decode exposing (decodeString)
import Monster exposing (BossType(..), Monster, MonsterType(..), NormalMonsterType(..))
import Scenario exposing (MapTileData, Scenario)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "The Game Sync module"
        [ describe "GameSync.decodeGameState"
            [ test "should output a game state from JSON" <|
                \_ ->
                    let
                        json =
                            """
                        {
                            "scenario": 2,
                            "numPlayers": 3,
                            "visibleRooms": ["a1b", "A2a"],
                            "overlays":[
                                {
                                    "ref": {
                                        "type": "starting-location"
                                    },
                                    "direction": "default",
                                    "cells": [ [0, 1] ]
                                },
                                {
                                    "ref": {
                                        "type": "treasure",
                                        "subType": "chest",
                                        "id": "goal"
                                    },
                                    "direction": "diagonal-right",
                                    "cells": [ [1, 2] ]
                                },
                                {

                                    "ref": {
                                        "type": "treasure",
                                        "subType": "chest",
                                        "id": "1"
                                    },
                                    "direction": "diagonal-right",
                                    "cells": [ [2, 2] ]

                                },
                                {

                                    "ref": {
                                        "type": "treasure",
                                        "subType": "loot",
                                        "amount": 2
                                    },
                                    "direction": "diagonal-left",
                                    "cells": [ [2, 3] ]

                                },
                                {

                                    "ref": {
                                        "type": "treasure",
                                        "subType": "coin"
                                    },
                                    "direction": "diagonal-left",
                                    "cells": [ [2, 4] ]

                                },
                                {

                                    "ref": {
                                        "type": "door",
                                        "subType": "stone"
                                    },
                                    "direction": "horizontal",
                                    "cells": [ [6, 5] ]

                                },
                                {

                                    "ref": {
                                        "type": "trap",
                                        "subType": "bear"
                                    },
                                    "direction": "vertical",
                                    "cells": [ [7, 5] ]

                                },
                                {

                                    "ref": {
                                        "type": "obstacle",
                                        "subType": "sarcophagus"
                                    },
                                    "direction": "horizontal",
                                    "cells": [ [6, 5], [7, 5] ]

                                }
                            ],
                            "pieces":[
                                {
                                    "ref": {
                                        "type": "player",
                                        "class": "cragheart"
                                    },
                                    "x": 1,
                                    "y": 2
                                },
                                {
                                    "ref": {
                                        "type": "monster",
                                        "class": "cultist",
                                        "id": 3,
                                        "level": "normal"
                                    },
                                    "x": 3,
                                    "y": 5
                                },
                                {
                                    "ref": {
                                        "type": "monster",
                                        "class": "Inox-shaman",
                                        "id": 1,
                                        "level": "elite"
                                    },
                                    "x": 4,
                                    "y": 5
                                },
                                {
                                    "ref": {
                                        "type": "monster",
                                        "class": "jekserah",
                                        "id": 1,
                                        "level": "normal"
                                    },
                                    "x": 4,
                                    "y": 6
                                },
                                {
                                    "ref": {
                                        "type": "summons",
                                        "owner": "Brute",
                                        "id": 1
                                    },
                                    "x": 2,
                                    "y": 2
                                }
                            ]
                        }
                    """

                        expectedState =
                            GameState
                                2
                                ThreePlayer
                                [ A1b, A2a ]
                                [ BoardOverlay StartingLocation Default [ ( 0, 1 ) ]
                                , BoardOverlay (Treasure (Chest Goal)) DiagonalRight [ ( 1, 2 ) ]
                                , BoardOverlay (Treasure (Chest (NormalChest 1))) DiagonalRight [ ( 2, 2 ) ]
                                , BoardOverlay (Treasure (Loot 2)) DiagonalLeft [ ( 2, 3 ) ]
                                , BoardOverlay (Treasure Coin) DiagonalLeft [ ( 2, 4 ) ]
                                , BoardOverlay (Door Stone) Horizontal [ ( 6, 5 ) ]
                                , BoardOverlay (Trap BearTrap) Vertical [ ( 7, 5 ) ]
                                , BoardOverlay (Obstacle Sarcophagus) Horizontal [ ( 6, 5 ), ( 7, 5 ) ]
                                ]
                                [ Piece (Player Cragheart) 1 2
                                , Piece (AI (Enemy (Monster (NormalType Cultist) 3 Monster.Normal))) 3 5
                                , Piece (AI (Enemy (Monster (NormalType InoxShaman) 1 Monster.Elite))) 4 5
                                , Piece (AI (Enemy (Monster (BossType Jekserah) 1 Monster.Normal))) 4 6
                                , Piece (AI (Summons 1 Brute)) 2 2
                                ]
                    in
                    decodeString decodeGameState json
                        |> Expect.equal (Ok expectedState)
            ]
        ]
