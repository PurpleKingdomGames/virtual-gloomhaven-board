module BoardOverlay exposing (BoardOverlay, BoardOverlayType(..), DoorSubType(..), ObstacleSubType(..), TrapSubType(..), TreasureSubType(..))


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


type alias BoardOverlay =
    { ref : BoardOverlayType
    , cells : ( ( Int, Int ), Maybe ( Int, Int ) )
    }
