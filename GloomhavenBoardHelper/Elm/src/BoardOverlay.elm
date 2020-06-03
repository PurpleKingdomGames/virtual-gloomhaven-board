module BoardOverlay exposing (BoardOverlay, BoardOverlayDirectionType(..), BoardOverlayType(..), ChestType(..), DoorSubType(..), ObstacleSubType(..), TrapSubType(..), TreasureSubType(..), getBoardOverlayName)

import BoardMapTile exposing (MapTileRef)


type BoardOverlayType
    = StartingLocation
    | Door DoorSubType (List MapTileRef)
    | Trap TrapSubType
    | Obstacle ObstacleSubType
    | Treasure TreasureSubType



-- DifficultTerrain
-- Corridors


type DoorSubType
    = Stone


type TrapSubType
    = BearTrap


type ObstacleSubType
    = Sarcophagus
    | Boulder1


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

        Door d _ ->
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

                Boulder1 ->
                    "obstacle-boulder-1"

        Treasure t ->
            case t of
                Chest _ ->
                    "treasure-chest"

                Coin _ ->
                    "treasure-coin"
