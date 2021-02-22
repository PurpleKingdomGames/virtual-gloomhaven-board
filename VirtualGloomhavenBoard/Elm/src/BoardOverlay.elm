module BoardOverlay exposing (BoardOverlay, BoardOverlayDirectionType(..), BoardOverlayType(..), ChestType(..), CorridorMaterial(..), CorridorSize(..), DifficultTerrainSubType(..), DoorSubType(..), HazardSubType(..), ObstacleSubType(..), TrapSubType(..), TreasureSubType(..), WallSubType(..), getAllOverlayTypes, getBoardOverlayName, getBoardOverlayType, getOverlayLabel, getOverlayTypesWithLabel)

import BoardMapTile exposing (MapTileRef)
import Dict exposing (Dict)


type BoardOverlayType
    = DifficultTerrain DifficultTerrainSubType
    | Door DoorSubType (List MapTileRef)
    | Hazard HazardSubType
    | Obstacle ObstacleSubType
    | Rift
    | StartingLocation
    | Trap TrapSubType
    | Treasure TreasureSubType
    | Wall WallSubType


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
    | Mirror
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
    | Locked


type WallSubType
    = HugeRock
    | Iron
    | LargeRock
    | ObsidianGlass
    | Rock


type BoardOverlayDirectionType
    = Default
    | Horizontal
    | Vertical
    | VerticalReverse
    | DiagonalLeft
    | DiagonalRight
    | DiagonalLeftReverse
    | DiagonalRightReverse


type alias BoardOverlay =
    { ref : BoardOverlayType
    , id : Int
    , direction : BoardOverlayDirectionType
    , cells : List ( Int, Int )
    }


overlayDictionary : Dict.Dict String BoardOverlayType
overlayDictionary =
    Dict.fromList
        [ ( "door-altar", Door AltarDoor [] )
        , ( "door-stone", Door Stone [] )
        , ( "door-wooden", Door Wooden [] )
        , ( "door-dark-fog", Door DarkFog [] )
        , ( "door-light-fog", Door LightFog [] )
        , ( "door-breakable-wall", Door BreakableWall [] )
        , ( "corridor-dark-1", Door (Corridor Dark One) [] )
        , ( "corridor-earth-1", Door (Corridor Earth One) [] )
        , ( "corridor-manmade-stone-1", Door (Corridor ManmadeStone One) [] )
        , ( "corridor-natural-stone-1", Door (Corridor NaturalStone One) [] )
        , ( "corridor-pressure-plate-1", Door (Corridor PressurePlate One) [] )
        , ( "corridor-wood-1", Door (Corridor Wood One) [] )
        , ( "corridor-dark-2", Door (Corridor Dark Two) [] )
        , ( "corridor-earth-2", Door (Corridor Earth Two) [] )
        , ( "corridor-manmade-stone-2", Door (Corridor ManmadeStone Two) [] )
        , ( "corridor-natural-stone-2", Door (Corridor NaturalStone Two) [] )
        , ( "corridor-wood-2", Door (Corridor Wood Two) [] )
        , ( "difficult-terrain-log", DifficultTerrain Log )
        , ( "difficult-terrain-rubble", DifficultTerrain Rubble )
        , ( "difficult-terrain-stairs", DifficultTerrain Stairs )
        , ( "difficult-terrain-stairs-vert", DifficultTerrain VerticalStairs )
        , ( "difficult-terrain-water", DifficultTerrain Water )
        , ( "hazard-hot-coals", Hazard HotCoals )
        , ( "hazard-thorns", Hazard Thorns )
        , ( "obstacle-altar", Obstacle Altar )
        , ( "obstacle-barrel", Obstacle Barrel )
        , ( "obstacle-bookcase", Obstacle Bookcase )
        , ( "obstacle-boulder-1", Obstacle Boulder1 )
        , ( "obstacle-boulder-2", Obstacle Boulder2 )
        , ( "obstacle-boulder-3", Obstacle Boulder3 )
        , ( "obstacle-bush", Obstacle Bush )
        , ( "obstacle-cabinet", Obstacle Cabinet )
        , ( "obstacle-crate", Obstacle Crate )
        , ( "obstacle-crystal", Obstacle Crystal )
        , ( "obstacle-dark-pit", Obstacle DarkPit )
        , ( "obstacle-fountain", Obstacle Fountain )
        , ( "obstacle-mirror", Obstacle Mirror )
        , ( "obstacle-nest", Obstacle Nest )
        , ( "obstacle-pillar", Obstacle Pillar )
        , ( "obstacle-rock-column", Obstacle RockColumn )
        , ( "obstacle-sarcophagus", Obstacle Sarcophagus )
        , ( "obstacle-shelf", Obstacle Shelf )
        , ( "obstacle-stalagmites", Obstacle Stalagmites )
        , ( "obstacle-stump", Obstacle Stump )
        , ( "obstacle-table", Obstacle Table )
        , ( "obstacle-totem", Obstacle Totem )
        , ( "obstacle-tree-3", Obstacle Tree3 )
        , ( "obstacle-wall-section", Obstacle WallSection )
        , ( "rift", Rift )
        , ( "starting-location", StartingLocation )
        , ( "trap-bear", Trap BearTrap )
        , ( "trap-spike", Trap Spike )
        , ( "trap-poison", Trap Poison )
        , ( "treasure-chest", Treasure (Chest Locked) )
        , ( "treasure-coin", Treasure (Coin 0) )
        , ( "wall-huge-rock", Wall HugeRock )
        , ( "wall-iron", Wall Iron )
        , ( "wall-large-rock", Wall LargeRock )
        , ( "wall-obsidian-glass", Wall ObsidianGlass )
        , ( "wall-rock", Wall Rock )
        ]


getBoardOverlayName : BoardOverlayType -> Maybe String
getBoardOverlayName overlay =
    let
        compare =
            case overlay of
                Door d _ ->
                    Door d []

                Treasure t ->
                    case t of
                        Chest _ ->
                            Treasure (Chest Locked)

                        Coin _ ->
                            Treasure (Coin 0)

                _ ->
                    overlay
    in
    overlayDictionary
        |> Dict.filter (\_ v -> v == compare)
        |> Dict.keys
        |> List.head


getBoardOverlayType : String -> Maybe BoardOverlayType
getBoardOverlayType overlayName =
    Dict.get overlayName overlayDictionary


getAllOverlayTypes : List BoardOverlayType
getAllOverlayTypes =
    Dict.values overlayDictionary


getOverlayTypesWithLabel : Dict String BoardOverlayType
getOverlayTypesWithLabel =
    overlayDictionary


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

                Mirror ->
                    "Mirror"

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

                                Locked ->
                                    "(locked)"

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

        Wall w ->
            case w of
                HugeRock ->
                    "Huge Rock Wall"

                Iron ->
                    "Iron Wall"

                LargeRock ->
                    "Large Rock Wall"

                ObsidianGlass ->
                    "Obsidian Glass Wall"

                Rock ->
                    "Rock Wall"
