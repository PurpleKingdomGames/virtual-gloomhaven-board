module BoardOverlayTests exposing (suite)

import BoardMapTile exposing (MapTileRef(..))
import BoardOverlay exposing (BoardOverlayType(..), ChestType(..), CorridorMaterial(..), CorridorSize(..), DifficultTerrainSubType(..), DoorSubType(..), HazardSubType(..), ObstacleSubType(..), TrapSubType(..), TreasureSubType(..), WallSubType(..), getBoardOverlayName)
import Expect exposing (equal)
import Test exposing (Test, describe, test)


testData : List BoardOverlayType
testData =
    [ Door AltarDoor [ A1a ]
    , Door Stone [ A1b ]
    , Door Wooden [ A1b ]
    , Door BreakableWall [ J1b, H2a ]
    , Door DarkFog [ J1b ]
    , Door LightFog [ L2a, A2b ]
    , Door (Corridor Dark One) [ L2a ]
    , Door (Corridor Dark Two) [ I1a ]
    , Door (Corridor Earth One) [ B2b ]
    , Door (Corridor Earth Two) [ B2b, A1a ]
    , Door (Corridor ManmadeStone One) [ A1a ]
    , Door (Corridor ManmadeStone Two) [ M1a, J1b ]
    , Door (Corridor NaturalStone One) [ J1b, L1b ]
    , Door (Corridor NaturalStone Two) [ J1b, L1b ]
    , Door (Corridor PressurePlate One) [ J1b, D1b ]
    , Door (Corridor Wood One) [ D1b ]
    , Door (Corridor Wood Two) [ J1b, D1b ]
    , DifficultTerrain Log
    , DifficultTerrain Rubble
    , DifficultTerrain Stairs
    , DifficultTerrain VerticalStairs
    , DifficultTerrain Water
    , Hazard HotCoals
    , Hazard Thorns
    , Obstacle Altar
    , Obstacle Barrel
    , Obstacle Bookcase
    , Obstacle Boulder1
    , Obstacle Boulder2
    , Obstacle Boulder3
    , Obstacle Bush
    , Obstacle Cabinet
    , Obstacle Crate
    , Obstacle Crystal
    , Obstacle DarkPit
    , Obstacle Fountain
    , Obstacle Mirror
    , Obstacle Nest
    , Obstacle Pillar
    , Obstacle RockColumn
    , Obstacle Sarcophagus
    , Obstacle Shelf
    , Obstacle Stalagmites
    , Obstacle Stump
    , Obstacle Table
    , Obstacle Totem
    , Obstacle Tree3
    , Obstacle WallSection
    , Rift
    , StartingLocation
    , Trap BearTrap
    , Trap Spike
    , Trap Poison
    , Treasure (Chest (NormalChest 1))
    , Treasure (Chest (NormalChest 100))
    , Treasure (Chest Goal)
    , Treasure (Chest Locked)
    , Treasure (Coin 1)
    , Treasure (Coin 50)
    , Wall HugeRock
    , Wall Iron
    , Wall LargeRock
    , Wall ObsidianGlass
    , Wall Rock
    ]


suite : Test
suite =
    describe "The Board Overlay module"
        [ describe "BoardOverlay.getBoardOverlayName"
            [ test "should output a Maybe String that is equal to the old implementation" <|
                \_ ->
                    let
                        expectedStrings =
                            List.map oldOverlayToString testData
                    in
                    List.filterMap getBoardOverlayName testData
                        |> Expect.equalLists expectedStrings
            ]
        ]


oldOverlayToString : BoardOverlayType -> String
oldOverlayToString overlay =
    case overlay of
        Door d _ ->
            case d of
                AltarDoor ->
                    "door-altar"

                Stone ->
                    "door-stone"

                Wooden ->
                    "door-wooden"

                BreakableWall ->
                    "door-breakable-wall"

                Corridor c num ->
                    (case c of
                        Dark ->
                            "corridor-dark"

                        Earth ->
                            "corridor-earth"

                        ManmadeStone ->
                            "corridor-manmade-stone"

                        NaturalStone ->
                            "corridor-natural-stone"

                        PressurePlate ->
                            "corridor-pressure-plate"

                        Wood ->
                            "corridor-wood"
                    )
                        ++ (case num of
                                One ->
                                    "-1"

                                Two ->
                                    "-2"
                           )

                DarkFog ->
                    "door-dark-fog"

                LightFog ->
                    "door-light-fog"

        DifficultTerrain d ->
            case d of
                Log ->
                    "difficult-terrain-log"

                Rubble ->
                    "difficult-terrain-rubble"

                Stairs ->
                    "difficult-terrain-stairs"

                VerticalStairs ->
                    "difficult-terrain-stairs-vert"

                Water ->
                    "difficult-terrain-water"

        Hazard h ->
            case h of
                HotCoals ->
                    "hazard-hot-coals"

                Thorns ->
                    "hazard-thorns"

        Obstacle o ->
            case o of
                Altar ->
                    "obstacle-altar"

                Barrel ->
                    "obstacle-barrel"

                Bookcase ->
                    "obstacle-bookcase"

                Boulder1 ->
                    "obstacle-boulder-1"

                Boulder2 ->
                    "obstacle-boulder-2"

                Boulder3 ->
                    "obstacle-boulder-3"

                Bush ->
                    "obstacle-bush"

                Cabinet ->
                    "obstacle-cabinet"

                Crate ->
                    "obstacle-crate"

                Crystal ->
                    "obstacle-crystal"

                DarkPit ->
                    "obstacle-dark-pit"

                Fountain ->
                    "obstacle-fountain"

                Mirror ->
                    "obstacle-mirror"

                Nest ->
                    "obstacle-nest"

                Pillar ->
                    "obstacle-pillar"

                RockColumn ->
                    "obstacle-rock-column"

                Sarcophagus ->
                    "obstacle-sarcophagus"

                Shelf ->
                    "obstacle-shelf"

                Stalagmites ->
                    "obstacle-stalagmites"

                Stump ->
                    "obstacle-stump"

                Table ->
                    "obstacle-table"

                Totem ->
                    "obstacle-totem"

                Tree3 ->
                    "obstacle-tree-3"

                WallSection ->
                    "obstacle-wall-section"

        Rift ->
            "rift"

        StartingLocation ->
            "starting-location"

        Trap t ->
            case t of
                BearTrap ->
                    "trap-bear"

                Spike ->
                    "trap-spike"

                Poison ->
                    "trap-poison"

        Treasure t ->
            case t of
                Chest _ ->
                    "treasure-chest"

                Coin _ ->
                    "treasure-coin"

        Wall w ->
            case w of
                HugeRock ->
                    "wall-huge-rock"

                Iron ->
                    "wall-iron"

                LargeRock ->
                    "wall-large-rock"

                ObsidianGlass ->
                    "wall-obsidian-glass"

                Rock ->
                    "wall-rock"
