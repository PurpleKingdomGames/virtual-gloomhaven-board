module BoardOverlay exposing (BoardOverlay, BoardOverlayDirectionType(..), BoardOverlayType(..), ChestType(..), DoorSubType(..), ObstacleSubType(..), TrapSubType(..), TreasureSubType(..), getBoardOverlayName)


type BoardOverlayType
    = StartingLocation
    | Door DoorSubType
    | Trap TrapSubType
    | Obstacle ObstacleSubType
    | Treasure TreasureSubType


type DoorSubType
    = Stone


type TrapSubType
    = BearTrap


type ObstacleSubType
    = Sarcophagus


type TreasureSubType
    = Chest ChestType
    | Coin
    | Loot Int


type ChestType
    = NormalChest Int
    | Goal


type BoardOverlayDirectionType
    = Default
    | Horizontal
    | Vertical
    | DiagonalLeft
    | DiagonalRight


type alias BoardOverlay =
    { ref : BoardOverlayType
    , direction : BoardOverlayDirectionType
    , cells : List ( Int, Int )
    }


getBoardOverlayName : BoardOverlayType -> String
getBoardOverlayName overlay =
    case overlay of
        StartingLocation ->
            "starting-location"

        Door d ->
            case d of
                Stone ->
                    "door-stone"

        Trap t ->
            case t of
                BearTrap ->
                    "trap-bear"

        Obstacle o ->
            case o of
                Sarcophagus ->
                    "obstacle-sarcophagus"

        Treasure t ->
            case t of
                Chest _ ->
                    "treasure-chest"

                Coin ->
                    "treasure-coin"

                Loot _ ->
                    "treasure-loot"
