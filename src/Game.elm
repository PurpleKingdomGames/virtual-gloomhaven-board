module Game exposing (AIType(..), Cell, NumPlayers(..), PieceType(..), generateGameMap)

import Array exposing (Array, get, initialize, set)
import Bitwise exposing (and)
import BoardMapTile exposing (MapTile, MapTileRef, refToString)
import BoardOverlay exposing (BoardOverlay)
import Character exposing (CharacterClass)
import Dict exposing (Dict, get)
import List exposing (filter, head, map)
import Monster exposing (Monster, MonsterLevel(..))
import Scenario exposing (Scenario, ScenarioMonster, mapTileDataToList, mapTileDataToOverlayList)


type NumPlayers
    = TwoPlayer
    | ThreePlayer
    | FourPlayer


type AIType
    = Enemy Monster
    | Summons CharacterClass


type PieceType
    = None
    | Player CharacterClass
    | AI AIType


type alias Cell =
    { rooms : List ( MapTileRef, Bool, Int )
    , hidden : Bool
    , passable : Bool
    , piece : PieceType
    , overlays : List BoardOverlay
    }


generateGameMap : Scenario -> NumPlayers -> Array (Array Cell)
generateGameMap scenario numPlayers =
    let
        ( mapTiles, bounds ) =
            mapTileDataToList scenario.mapTilesData Nothing

        overlays =
            mapTileDataToOverlayList scenario.mapTilesData

        -- Build a square array capable of holding the whole map
        -- We add 2 to account for the zero index, and also row drift if the original started on a non-even row
        arrSize =
            max (abs (bounds.maxX - bounds.minX)) (abs (bounds.maxY - bounds.minY))
                + 1
                + (if Bitwise.and bounds.minY 1 == 1 then
                    1

                   else
                    0
                  )

        -- The Y offset needs adjusting if the start of the original array was an odd row
        offsetY =
            if Bitwise.and bounds.minY 1 == 1 then
                bounds.minY - 1

            else
                bounds.minY

        initMap =
            initialize arrSize (always (initialize arrSize (always (Cell [] True False None []))))
    in
    setCellsFromMapTiles mapTiles numPlayers overlays bounds.minX offsetY initMap


setCellsFromMapTiles : List MapTile -> NumPlayers -> Dict String ( List BoardOverlay, List ScenarioMonster ) -> Int -> Int -> Array (Array Cell) -> Array (Array Cell)
setCellsFromMapTiles mapTileList numPlayers overlays offsetX offsetY cellArr =
    case mapTileList of
        [] ->
            cellArr

        [ last ] ->
            setCellFromMapTile cellArr numPlayers overlays offsetX offsetY last

        head :: rest ->
            setCellFromMapTile cellArr numPlayers overlays offsetX offsetY head
                |> setCellsFromMapTiles rest numPlayers overlays offsetX offsetY


setCellFromMapTile : Array (Array Cell) -> NumPlayers -> Dict String ( List BoardOverlay, List ScenarioMonster ) -> Int -> Int -> MapTile -> Array (Array Cell)
setCellFromMapTile initialArr numPlayers overlays offsetX offsetY tile =
    let
        x =
            tile.x - offsetX

        y =
            tile.y - offsetY

        ( boardOverlays, monsters ) =
            case Dict.get (refToString tile.ref) overlays of
                Just v ->
                    v

                Nothing ->
                    ( [], [] )

        filteredOverlays =
            filter (filterByCoord tile.originalX tile.originalY) boardOverlays
                |> map (mapOverlayCoord tile.originalX tile.originalY x y)

        piece =
            let
                maybePiece =
                    filter (filterMonsterLevel numPlayers) monsters
                        |> filter (\m -> m.initialX == tile.originalX && m.initialY == tile.originalY)
                        |> head
            in
            case maybePiece of
                Just p ->
                    let
                        m =
                            p.monster
                    in
                    AI (Enemy { m | level = getLevelForMonster numPlayers p })

                Nothing ->
                    None

        rowArr =
            Array.get y initialArr
    in
    case rowArr of
        Just yRow ->
            let
                cell =
                    Array.get x yRow
            in
            case cell of
                Just foundCell ->
                    let
                        newCell =
                            { foundCell
                                | rooms = ( tile.ref, tile.originalX == 0 && tile.originalY == 0, tile.turns ) :: foundCell.rooms
                                , hidden =
                                    if foundCell.hidden then
                                        tile.hidden

                                    else
                                        False
                                , passable =
                                    if foundCell.passable == False then
                                        tile.passable

                                    else
                                        True
                                , overlays =
                                    foundCell.overlays ++ filteredOverlays
                                , piece =
                                    if foundCell.piece == None then
                                        piece

                                    else
                                        foundCell.piece
                            }
                    in
                    set y (set x newCell yRow) initialArr

                Nothing ->
                    initialArr

        Nothing ->
            initialArr


filterMonsterLevel : NumPlayers -> ScenarioMonster -> Bool
filterMonsterLevel numPlayers monster =
    case numPlayers of
        TwoPlayer ->
            monster.twoPlayer /= Monster.None

        ThreePlayer ->
            monster.threePlayer /= Monster.None

        FourPlayer ->
            monster.fourPlayer /= Monster.None


getLevelForMonster : NumPlayers -> ScenarioMonster -> MonsterLevel
getLevelForMonster numPlayers monster =
    case numPlayers of
        TwoPlayer ->
            monster.twoPlayer

        ThreePlayer ->
            monster.threePlayer

        FourPlayer ->
            monster.fourPlayer


filterByCoord : Int -> Int -> BoardOverlay -> Bool
filterByCoord x y overlay =
    let
        ( ( overlayX, overlayY ), maybeSecondCoords ) =
            overlay.cells
    in
    if overlayX == x && overlayY == y then
        True

    else
        case maybeSecondCoords of
            Just ( otherX, otherY ) ->
                otherX == x && otherY == y

            Nothing ->
                False


mapOverlayCoord : Int -> Int -> Int -> Int -> BoardOverlay -> BoardOverlay
mapOverlayCoord originalX originalY newX newY overlay =
    let
        ( firstX, firstY ) =
            Tuple.first overlay.cells
    in
    if originalX == firstX && originalY == firstY then
        { overlay | cells = ( ( newX, newY ), Tuple.second overlay.cells ) }

    else
        case Tuple.second overlay.cells of
            Just ( secondX, secondY ) ->
                if originalX == secondX && originalY == secondY then
                    { overlay | cells = ( Tuple.first overlay.cells, Just ( newX, newY ) ) }

                else
                    overlay

            Nothing ->
                overlay
