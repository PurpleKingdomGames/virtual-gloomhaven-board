module Game exposing (AIType(..), Cell, NumPlayers(..), PieceType(..), generateGameMap)

import Array exposing (Array, get, initialize, set)
import BoardMapTiles exposing (MapTile, refToString)
import BoardOverlays exposing (BoardOverlay)
import Characters exposing (CharacterClass)
import Dict exposing (Dict, get)
import List exposing (filter, head)
import Monsters exposing (Monster, MonsterLevel(..))
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
    { hidden : Bool
    , passable : Bool
    , piece : PieceType
    , overlays : List BoardOverlay
    }


generateGameMap : Scenario -> NumPlayers -> Array (Array Cell)
generateGameMap scenario numPlayers =
    let
        ( mapTiles, bounds ) =
            mapTileDataToList scenario.mapTilesData

        overlays =
            mapTileDataToOverlayList scenario.mapTilesData

        arrSize =
            max (bounds.maxX - bounds.minX) (bounds.maxY - bounds.minY)

        initMap =
            initialize arrSize (always (initialize arrSize (always (Cell True False None []))))
    in
    setCellsFromMapTiles mapTiles numPlayers overlays bounds.minX bounds.minY initMap


setCellsFromMapTiles : List MapTile -> NumPlayers -> Dict String ( List BoardOverlay, List ScenarioMonster ) -> Int -> Int -> Array (Array Cell) -> Array (Array Cell)
setCellsFromMapTiles mapTileList numPlayers overlays offsetX offsetY cellArr =
    case mapTileList of
        head :: rest ->
            setCellFromMapTile cellArr numPlayers overlays offsetX offsetY head
                |> setCellsFromMapTiles rest numPlayers overlays offsetX offsetY

        _ ->
            cellArr


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
            Array.get x initialArr
    in
    case rowArr of
        Just yRow ->
            let
                cell =
                    Array.get y yRow
            in
            case cell of
                Just foundCell ->
                    let
                        newCell =
                            { foundCell
                                | hidden =
                                    if foundCell.hidden then
                                        tile.hidden

                                    else
                                        False
                                , passable =
                                    if foundCell.passable == False then
                                        tile.passable

                                    else
                                        True
                                , overlays = foundCell.overlays ++ boardOverlays
                                , piece =
                                    if foundCell.piece == None then
                                        piece

                                    else
                                        foundCell.piece
                            }
                    in
                    set x (set y newCell yRow) initialArr

                Nothing ->
                    initialArr

        Nothing ->
            initialArr


filterMonsterLevel : NumPlayers -> ScenarioMonster -> Bool
filterMonsterLevel numPlayers monster =
    case numPlayers of
        TwoPlayer ->
            monster.twoPlayer /= Monsters.None

        ThreePlayer ->
            monster.threePlayer /= Monsters.None

        FourPlayer ->
            monster.fourPlayer /= Monsters.None


getLevelForMonster : NumPlayers -> ScenarioMonster -> MonsterLevel
getLevelForMonster numPlayers monster =
    case numPlayers of
        TwoPlayer ->
            monster.twoPlayer

        ThreePlayer ->
            monster.threePlayer

        FourPlayer ->
            monster.fourPlayer
