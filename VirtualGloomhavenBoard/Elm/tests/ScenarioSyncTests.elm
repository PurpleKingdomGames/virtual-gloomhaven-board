module ScenarioSyncTests exposing (suite)

import BoardMapTile exposing (MapTileRef(..))
import BoardOverlay exposing (BoardOverlay, BoardOverlayDirectionType(..), BoardOverlayType(..), ChestType(..), DoorSubType(..), ObstacleSubType(..), TrapSubType(..), TreasureSubType(..))
import Character exposing (CharacterClass(..))
import Expect exposing (equal)
import Game exposing (AIType(..), PieceType(..))
import Json.Decode exposing (decodeString)
import Monster exposing (BossType(..), Monster, MonsterLevel(..), MonsterType(..), NormalMonsterType(..))
import Scenario exposing (DoorData(..), MapTileData, Scenario, ScenarioMonster)
import ScenarioSync exposing (decodeScenario)
import Test exposing (Test, describe, test)


encodedJson : String
encodedJson =
    """{
    "id": 2,
    "title": "Barrow Lair",
    "mapTileData": {
        "ref": "b3b",
        "doors": [
            {
                "subType": "stone",
                "direction": "default",
                "room1X": 1,
                "room1Y": -1,
                "room2X": 2,
                "room2Y": 7,
                "mapTileData": {
                    "ref": "m1a",
                    "doors": [
                        {
                            "subType": "stone",
                            "direction": "diagonal-right",
                            "room1X": 0,
                            "room1Y": 0,
                            "room2X": 3,
                            "room2Y": 0,
                            "mapTileData": {
                                "ref": "a4b",
                                "doors": [],
                                "overlays": [
                                    {
                                        "ref": {
                                            "type": "treasure",
                                            "subType": "chest",
                                            "id": "67"
                                        },
                                        "direction": "default",
                                        "cells": [
                                            [0, 2]
                                        ]
                                    }
                                ],
                                "monsters": [
                                    {
                                        "monster":  "living-corpse",
                                        "initialX": 0,
                                        "initialY": 1,
                                        "twoPlayer": "none",
                                        "threePlayer": "normal",
                                        "fourPlayer": "elite"
                                    },
                                    {
                                        "monster":  "living-corpse",
                                        "initialX": 1,
                                        "initialY": 2,
                                        "twoPlayer": "elite",
                                        "threePlayer": "elite",
                                        "fourPlayer": "elite"
                                    }
                                ],
                                "turns": 5
                            }
                        },
                        {
                            "subType": "stone",
                            "direction": "diagonal-left",
                            "room1X": 5,
                            "room1Y": 0,
                            "room2X": 1,
                            "room2Y": 0,
                            "mapTileData": {
                                "ref": "a2a",
                                "doors": [],
                                "overlays": [],
                                "monsters": [
                                    {
                                        "monster":  "living-corpse",
                                        "initialX": 3,
                                        "initialY": 1,
                                        "twoPlayer": "none",
                                        "threePlayer": "normal",
                                        "fourPlayer": "elite"
                                    },
                                    {
                                        "monster":  "living-corpse",
                                        "initialX": 3,
                                        "initialY": 2,
                                        "twoPlayer": "elite",
                                        "threePlayer": "elite",
                                        "fourPlayer": "elite"
                                    }
                                ],
                                "turns": 1
                            }
                        },
                        {
                            "subType": "stone",
                            "direction": "vertical",
                            "room1X": -1,
                            "room1Y": 3,
                            "room2X": 4,
                            "room2Y": 1,
                            "mapTileData": {
                                "ref": "a1a",
                                "doors": [],
                                "overlays": [],
                                "monsters": [
                                    {
                                        "monster":  "living-corpse",
                                        "initialX": 1,
                                        "initialY": 1,
                                        "twoPlayer": "none",
                                        "threePlayer": "normal",
                                        "fourPlayer": "elite"
                                    },
                                    {
                                        "monster":  "living-corpse",
                                        "initialX": 1,
                                        "initialY": 2,
                                        "twoPlayer": "normal",
                                        "threePlayer": "normal",
                                        "fourPlayer": "normal"
                                    },
                                    {
                                        "monster":  "living-corpse",
                                        "initialX": 2,
                                        "initialY": 2,
                                        "twoPlayer": "normal",
                                        "threePlayer": "normal",
                                        "fourPlayer": "normal"
                                    }
                                ],
                                "turns": 3
                            }
                        },
                        {
                            "subType": "stone",
                            "direction": "vertical",
                            "room1X": 5,
                            "room1Y": 3,
                            "room2X": -1,
                            "room2Y": 1,
                            "mapTileData": {
                                "ref": "a3b",
                                "doors": [],
                                "overlays": [],
                                "monsters": [
                                    {
                                        "monster":  "living-corpse",
                                        "initialX": 2,
                                        "initialY": 1,
                                        "twoPlayer": "none",
                                        "threePlayer": "normal",
                                        "fourPlayer": "elite"
                                    },
                                    {
                                        "monster":  "living-corpse",
                                        "initialX": 2,
                                        "initialY": 2,
                                        "twoPlayer": "normal",
                                        "threePlayer": "normal",
                                        "fourPlayer": "normal"
                                    },
                                    {
                                        "monster":  "living-corpse",
                                        "initialX": 3,
                                        "initialY": 2,
                                        "twoPlayer": "normal",
                                        "threePlayer": "normal",
                                        "fourPlayer": "normal"
                                    }
                                ],
                                "turns": 3
                            }
                        }
                    ],
                    "overlays":[
                        {
                            "ref": {
                                "type": "obstacle",
                                "subType": "sarcophagus"
                            },
                            "direction": "default",
                            "cells": [
                                [3, 2],
                                [2, 2]
                            ]
                        },
                        {
                            "ref": {
                                "type": "obstacle",
                                "subType": "sarcophagus"
                            },
                            "direction": "diagonal-left",
                            "cells": [
                                [1, 5],
                                [1, 4]
                            ]
                        },
                        {
                            "ref": {
                                "type": "obstacle",
                                "subType": "sarcophagus"
                            },
                            "direction": "diagonal-right",
                            "cells": [
                                [3, 5],
                                [4, 4]
                            ]
                        }
                    ],
                    "monsters": [
                        {
                            "monster": "bandit-archer",
                            "initialX": 1,
                            "initialY": 1,
                            "twoPlayer": "elite",
                            "threePlayer": "elite",
                            "fourPlayer": "elite"
                        },
                        {
                            "monster": "bandit-commander",
                            "initialX": 2,
                            "initialY": 1,
                            "twoPlayer": "normal",
                            "threePlayer": "normal",
                            "fourPlayer": "normal"
                        },
                        {
                            "monster": "bandit-archer",
                            "initialX": 3,
                            "initialY": 1,
                            "twoPlayer": "none",
                            "threePlayer": "normal",
                            "fourPlayer": "elite"
                        }
                    ],
                    "turns": 3
                }
            }
        ],
        "overlays": [
            {
                "ref": {
                    "type": "trap",
                    "subType": "bear"
                },
                "direction": "default",
                "cells": [
                    [0, 1]
                ]
            },
            {
                "ref": {
                    "type": "trap",
                    "subType": "bear"
                },
                "direction": "default",
                "cells": [
                    [2, 1]
                ]
            },
            {
                "ref": {
                    "type": "starting-location"
                },
                "direction": "default",
                "cells": [
                    [0, 3]
                ]
            },
            {
                "ref": {
                    "type": "starting-location"
                },
                "direction": "default",
                "cells": [
                    [1, 3]
                ]
            },
            {
                "ref": {
                    "type": "starting-location"
                },
                "direction": "default",
                "cells": [
                    [2, 3]
                ]
            },
            {
                "ref": {
                    "type": "starting-location"
                },
                "direction": "default",
                "cells": [
                    [1, 2]
                ]
            },
            {
                "ref": {
                    "type": "starting-location"
                },
                "direction": "default",
                "cells": [
                    [2, 2]
                ]
            }
        ],
        "monsters": [
            {
                "monster": "bandit-archer",
                "initialX": 0,
                "initialY": 0,
                "twoPlayer": "normal",
                "threePlayer": "normal",
                "fourPlayer": "normal"
            },
            {
                "monster": "bandit-archer",
                "initialX": 1,
                "initialY": 0,
                "twoPlayer": "none",
                "threePlayer": "none",
                "fourPlayer": "normal"
            },
            {
                "monster": "bandit-archer",
                "initialX": 2,
                "initialY": 0,
                "twoPlayer": "none",
                "threePlayer": "normal",
                "fourPlayer": "normal"
            },
            {
                "monster": "bandit-archer",
                "initialX": 3,
                "initialY": 0,
                "twoPlayer": "normal",
                "threePlayer": "normal",
                "fourPlayer": "normal"
            }
        ],
        "turns": 3
    },
    "angle": 0,
    "additionalMonsters": [
        "living-bones"
    ]
}"""


decodedScenario : Scenario
decodedScenario =
    Scenario
        2
        "Barrow Lair"
        (MapTileData B3b
            [ DoorLink Stone
                Default
                ( 1, -1 )
                ( 2, 7 )
                (MapTileData M1a
                    [ DoorLink Stone
                        DiagonalRight
                        ( 0, 0 )
                        ( 3, 0 )
                        (MapTileData A4b
                            []
                            [ BoardOverlay (Treasure (Chest (NormalChest 67))) Default [ ( 0, 2 ) ]
                            ]
                            [ ScenarioMonster (Monster (NormalType LivingCorpse) 0 Monster.None False) 0 1 Monster.None Normal Elite
                            , ScenarioMonster (Monster (NormalType LivingCorpse) 0 Monster.None False) 1 2 Elite Elite Elite
                            ]
                            5
                        )
                    , DoorLink Stone
                        DiagonalLeft
                        ( 5, 0 )
                        ( 1, 0 )
                        (MapTileData A2a
                            []
                            []
                            [ ScenarioMonster (Monster (NormalType LivingCorpse) 0 Monster.None False) 3 1 Monster.None Normal Elite
                            , ScenarioMonster (Monster (NormalType LivingCorpse) 0 Monster.None False) 3 2 Elite Elite Elite
                            ]
                            1
                        )
                    , DoorLink Stone
                        Vertical
                        ( -1, 3 )
                        ( 4, 1 )
                        (MapTileData A1a
                            []
                            []
                            [ ScenarioMonster (Monster (NormalType LivingCorpse) 0 Monster.None False) 1 1 Monster.None Normal Elite
                            , ScenarioMonster (Monster (NormalType LivingCorpse) 0 Monster.None False) 1 2 Normal Normal Normal
                            , ScenarioMonster (Monster (NormalType LivingCorpse) 0 Monster.None False) 2 2 Normal Normal Normal
                            ]
                            3
                        )
                    , DoorLink Stone
                        Vertical
                        ( 5, 3 )
                        ( -1, 1 )
                        (MapTileData A3b
                            []
                            []
                            [ ScenarioMonster (Monster (NormalType LivingCorpse) 0 Monster.None False) 2 1 Monster.None Normal Elite
                            , ScenarioMonster (Monster (NormalType LivingCorpse) 0 Monster.None False) 2 2 Normal Normal Normal
                            , ScenarioMonster (Monster (NormalType LivingCorpse) 0 Monster.None False) 3 2 Normal Normal Normal
                            ]
                            3
                        )
                    ]
                    [ BoardOverlay (Obstacle Sarcophagus) Default [ ( 3, 2 ), ( 2, 2 ) ]
                    , BoardOverlay (Obstacle Sarcophagus) DiagonalLeft [ ( 1, 5 ), ( 1, 4 ) ]
                    , BoardOverlay (Obstacle Sarcophagus) DiagonalRight [ ( 3, 5 ), ( 4, 4 ) ]
                    ]
                    [ ScenarioMonster (Monster (NormalType BanditArcher) 0 Monster.None False) 1 1 Elite Elite Elite
                    , ScenarioMonster (Monster (BossType BanditCommander) 0 Monster.None False) 2 1 Normal Normal Normal
                    , ScenarioMonster (Monster (NormalType BanditArcher) 0 Monster.None False) 3 1 Monster.None Normal Elite
                    ]
                    3
                )
            ]
            [ BoardOverlay (Trap BearTrap) Default [ ( 0, 1 ) ]
            , BoardOverlay (Trap BearTrap) Default [ ( 2, 1 ) ]
            , BoardOverlay StartingLocation Default [ ( 0, 3 ) ]
            , BoardOverlay StartingLocation Default [ ( 1, 3 ) ]
            , BoardOverlay StartingLocation Default [ ( 2, 3 ) ]
            , BoardOverlay StartingLocation Default [ ( 1, 2 ) ]
            , BoardOverlay StartingLocation Default [ ( 2, 2 ) ]
            ]
            [ ScenarioMonster (Monster (NormalType BanditArcher) 0 Monster.None False) 0 0 Normal Normal Normal
            , ScenarioMonster (Monster (NormalType BanditArcher) 0 Monster.None False) 1 0 Monster.None Monster.None Normal
            , ScenarioMonster (Monster (NormalType BanditArcher) 0 Monster.None False) 2 0 Monster.None Normal Normal
            , ScenarioMonster (Monster (NormalType BanditArcher) 0 Monster.None False) 3 0 Normal Normal Normal
            ]
            3
        )
        0
        [ NormalType LivingBones
        ]


suite : Test
suite =
    describe "The Scenario Sync module"
        [ describe "ScenarioSync.decodeScenario"
            [ test "should output a scenario from JSON" <|
                \_ ->
                    decodeString decodeScenario encodedJson
                        |> Expect.equal (Ok decodedScenario)
            ]
        ]
