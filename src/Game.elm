module Game exposing (AIType(..), Game, GameState, NumPlayers(..), PieceType(..), generateGameMap, getPieceName, getPieceType)

import Array exposing (Array, get, initialize, set)
import Bitwise exposing (and)
import BoardMapTile exposing (MapTile, MapTileRef, refToString)
import BoardOverlay exposing (BoardOverlay)
import Character exposing (CharacterClass)
import Dict exposing (Dict, get)
import Hexagon exposing (cubeToOddRow, oddRowToCube)
import List exposing (filter, head, map)
import Monster exposing (Monster, MonsterLevel(..), getMonsterName)
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


type alias Piece =
    { ref : PieceType
    , x : Int
    , y : Int
    }


type alias Game =
    { state : GameState
    , staticBoard : Array (Array Bool)
    }


type alias GameState =
    { scenario : Int
    , numPlayers : NumPlayers
    , visibleRooms : List MapTileRef
    , overlays : List BoardOverlay
    , pieces : List Piece
    }


getPieceType : PieceType -> String
getPieceType piece =
    case piece of
        Player _ ->
            "player"

        AI t ->
            case t of
                Summons _ ->
                    "summons"

                Enemy _ ->
                    "monster"

        None ->
            ""


getPieceName : PieceType -> String
getPieceName piece =
    case piece of
        Player p ->
            ""

        AI t ->
            case t of
                Summons p ->
                    ""

                Enemy e ->
                    getMonsterName e.monster

        None ->
            ""


generateGameMap : Scenario -> NumPlayers -> Game
generateGameMap scenario numPlayers =
    let
        ( mapTiles, bounds ) =
            mapTileDataToList scenario.mapTilesData Nothing

        initGameState =
            GameState scenario.id
                numPlayers
                []
                []
                []

        initOverlays =
            mapTileDataToOverlayList scenario.mapTilesData

        {- Build a square array capable of holding the whole map
           We add 2 to account for the zero index, and also row drift if the original started on a non-even row
        -}
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
            initialize arrSize (always (initialize arrSize (always False)))
    in
    setCellsFromMapTiles mapTiles initOverlays bounds.minX offsetY ( initGameState, initMap )


setCellsFromMapTiles : List MapTile -> Dict String ( List BoardOverlay, List ScenarioMonster ) -> Int -> Int -> ( GameState, Array (Array Bool) ) -> Game
setCellsFromMapTiles mapTileList overlays offsetX offsetY ( gamestate, cellArr ) =
    case mapTileList of
        [] ->
            Game gamestate cellArr

        [ last ] ->
            setCellFromMapTile cellArr gamestate overlays offsetX offsetY last
                |> setCellsFromMapTiles [] overlays offsetX offsetY

        head :: rest ->
            setCellFromMapTile cellArr gamestate overlays offsetX offsetY head
                |> setCellsFromMapTiles rest overlays offsetX offsetY


setCellFromMapTile : Array (Array Bool) -> GameState -> Dict String ( List BoardOverlay, List ScenarioMonster ) -> Int -> Int -> MapTile -> ( GameState, Array (Array Bool) )
setCellFromMapTile initialArr gamestate overlays offsetX offsetY tile =
    let
        x =
            tile.x - offsetX

        y =
            tile.y - offsetY

        ( boardOverlays, piece ) =
            case Dict.get (refToString tile.ref) overlays of
                Just ( o, m ) ->
                    ( filter (filterByCoord tile.originalX tile.originalY) o
                        |> map (mapOverlayCoord tile.originalX tile.originalY x y)
                    , filter (filterMonsterLevel gamestate.numPlayers) m
                        |> filter (\f -> f.initialX == tile.originalX && f.initialY == tile.originalY)
                        |> head
                        |> getPieceFromMonster gamestate.numPlayers
                        |> map (mapPieceCoord tile.originalX tile.originalY x y)
                    )

                Nothing ->
                    ( [], [] )

        newGameState =
            { gamestate
                | overlays = gamestate.overlays ++ boardOverlays
                , pieces =
                    gamestate.pieces
                        ++ (case piece of
                                None ->
                                    []

                                p ->
                                    [ p ]
                           )
            }

        rowArr =
            Array.get y initialArr

        newBoard =
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
                                    if foundCell == False then
                                        tile.passable

                                    else
                                        True
                            in
                            set y (set x newCell yRow) initialArr

                        Nothing ->
                            initialArr

                Nothing ->
                    initialArr
    in
    ( newGameState, newBoard )


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


getPieceFromMonster : NumPlayers -> Maybe ScenarioMonster -> Piece
getPieceFromMonster numPlayers monster =
    case monster of
        Just p ->
            let
                m =
                    p.monster
            in
            Piece (AI (Enemy { m | level = getLevelForMonster numPlayers p })) p.initialX p.initialY

        Nothing ->
            None


filterByCoord : Int -> Int -> BoardOverlay -> Bool
filterByCoord x y overlay =
    let
        ( ( overlayX, overlayY ), _ ) =
            overlay.cells
    in
    overlayX == x && overlayY == y


mapPieceCoord : Int -> Int -> Int -> Int -> Piece -> Piece
mapPieceCoord originalX originalY newX newY piece =
    piece


mapOverlayCoord : Int -> Int -> Int -> Int -> BoardOverlay -> BoardOverlay
mapOverlayCoord originalX originalY newX newY overlay =
    let
        ( oX, oY, oZ ) =
            oddRowToCube ( originalX, originalY )

        ( nX, nY, nZ ) =
            cubeToOddRow ( newX, newY )

        diffX =
            nX - oX

        diffY =
            nY - oY

        diffZ =
            nZ - oZ
    in
    { overlay
        | cells =
            map
                (\c ->
                    let
                        ( x1, y1, z1 ) =
                            oddRowToCube c
                    in
                    cubeToOddRow ( diffX + x1, diffY + y1, diffZ + z1 )
                )
    }
