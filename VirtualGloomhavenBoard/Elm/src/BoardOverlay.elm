module BoardOverlay exposing (BoardOverlay, BoardOverlayDirectionType(..), BoardOverlayType(..), ChestType(..), CorridorMaterial(..), CorridorSize(..), DifficultTerrainSubType(..), DoorSubType(..), HazardSubType(..), ObstacleSubType(..), TrapSubType(..), TreasureSubType(..), getBoardOverlayName, getOverlayLabel)

import BoardMapTile exposing (MapTileRef)


type BoardOverlayType
    = DifficultTerrain DifficultTerrainSubType
    | Door DoorSubType (List MapTileRef)
    | Hazard HazardSubType
    | Obstacle ObstacleSubType
    | Rift
    | StartingLocation
    | Trap TrapSubType
    | Treasure TreasureSubType


type DoorSubType
    = AltarDoor
    | BreakableWall
    | Corridor CorridorMaterial CorridorSize
    | DarkFog
    | LightFog
    | Stone
    | Wooden


type CorridorMaterial
    = Dark
    | Earth
    | ManmadeStone
    | NaturalStone
    | PressurePlate
    | Wood


type CorridorSize
    = One
    | Two


type TrapSubType
    = BearTrap
    | Poison
    | Spike


type HazardSubType
    = HotCoals
    | Thorns


type DifficultTerrainSubType
    = Log
    | Rubble
    | Stairs
    | VerticalStairs
    | Water


type ObstacleSubType
    = Altar
    | Barrel
    | Bookcase
    | Boulder1
    | Boulder2
    | Boulder3
    | Bush
    | Cabinet
    | Crate
    | Crystal
    | DarkPit
    | Fountain
    | Nest
    | Pillar
    | RockColumn
    | Sarcophagus
    | Shelf
    | Stalagmites
    | Stump
    | Table
    | Totem
    | Tree3
    | WallSection


type TreasureSubType
    = Chest ChestType
    | Coin Int


type ChestType
    = NormalChest Int
    | Goal


type BoardOverlayDirectionType
    = Default
    | Horizontal
    | Vertical
    | DiagonalLeft
    | DiagonalRight
    | DiagonalLeftReverse
    | DiagonalRightReverse


type alias BoardOverlay =
    { ref : BoardOverlayType
    , direction : BoardOverlayDirectionType
    , cells : List ( Int, Int )
    }


getBoardOverlayName : BoardOverlayType -> String
getBoardOverlayName overlay =
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


getOverlayLabel : BoardOverlayType -> String
getOverlayLabel overlay =
    case overlay of
        Door d _ ->
            case d of
                AltarDoor ->
                    "Altar"

                Stone ->
                    "Stone Door"

                Wooden ->
                    "Wooden Door"

                BreakableWall ->
                    "Breakable Wall"

                Corridor c _ ->
                    case c of
                        Dark ->
                            "Dark Corridor"

                        Earth ->
                            "Earth Corridor"

                        ManmadeStone ->
                            "Manmade Stone Corridor"

                        NaturalStone ->
                            "Natural Stone Corridor"

                        PressurePlate ->
                            "Pressure Plate"

                        Wood ->
                            "Wooden Corridor"

                DarkFog ->
                    "Dark Fog"

                LightFog ->
                    "Light Fog"

        DifficultTerrain d ->
            case d of
                Log ->
                    "Fallen Log"

                Rubble ->
                    "Rubble"

                Stairs ->
                    "Stairs"

                VerticalStairs ->
                    "Stairs"

                Water ->
                    "Water"

        Hazard h ->
            case h of
                HotCoals ->
                    "Hot Coals"

                Thorns ->
                    "Thorns"

        Obstacle o ->
            case o of
                Altar ->
                    "Altar"

                Barrel ->
                    "Barrel"

                Bookcase ->
                    "Bookcase"

                Boulder1 ->
                    "Boulder"

                Boulder2 ->
                    "Boulder"

                Boulder3 ->
                    "Boulder"

                Bush ->
                    "Bush"

                Cabinet ->
                    "Cabinet"

                Crate ->
                    "Crate"

                Crystal ->
                    "Crystal"

                DarkPit ->
                    "Dark Pit"

                Fountain ->
                    "Fountain"

                Nest ->
                    "Nest"

                Pillar ->
                    "Pillar"

                RockColumn ->
                    "Rock Column"

                Sarcophagus ->
                    "Sarcophagus"

                Shelf ->
                    "Sheelves"

                Stalagmites ->
                    "Stalagmites"

                Stump ->
                    "Tree Stump"

                Table ->
                    "Table"

                Totem ->
                    "Totem"

                Tree3 ->
                    "Tree"

                WallSection ->
                    "Wall"

        Rift ->
            "Rift"

        StartingLocation ->
            "Starting Location"

        Trap t ->
            case t of
                BearTrap ->
                    "Bear Trap"

                Spike ->
                    "Spike Trap"

                Poison ->
                    "Poison Trap"

        Treasure t ->
            case t of
                Chest c ->
                    "Treasure Chest "
                        ++ (case c of
                                Goal ->
                                    "Goal"

                                NormalChest i ->
                                    String.fromInt i
                           )

                Coin i ->
                    String.fromInt i
                        ++ (case i of
                                1 ->
                                    " Coin"

                                _ ->
                                    " Coins"
                           )
