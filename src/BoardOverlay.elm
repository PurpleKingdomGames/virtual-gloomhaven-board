module BoardOverlay exposing (BoardOverlay, BoardOverlayDirectionType(..), BoardOverlayType(..), DoorSubType(..), ObstacleSubType(..), TrapSubType(..), TreasureSubType(..), getBoardOverlayName)


type BoardOverlayType
    = Door DoorSubType
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
    = Chest Int
    | Coin
    | Loot Int


type BoardOverlayDirectionType
    = Default
    | Horizontal
    | Vertical
    | DiagonalLeft
    | DiagonalRight


type alias BoardOverlay =
    { ref : BoardOverlayType
    , direction : BoardOverlayDirectionType
    , cells : ( ( Int, Int ), Maybe ( Int, Int ) )
    }


getBoardOverlayName : BoardOverlayType -> String
getBoardOverlayName overlay =
    case overlay of
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
