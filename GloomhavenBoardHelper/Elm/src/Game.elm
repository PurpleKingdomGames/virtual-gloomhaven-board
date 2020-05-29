module Game exposing (AIType(..), Cell, Game, GameState, NumPlayers(..), Piece, PieceType(..), generateGameMap, getPieceName, getPieceType, moveOverlay, movePiece)

import Array exposing (Array, get, initialize, set)
import Bitwise exposing (and)
import BoardMapTile exposing (MapTile, MapTileRef, refToString)
import BoardOverlay exposing (BoardOverlay, BoardOverlayType(..))
import Character exposing (CharacterClass)
import Dict exposing (Dict, get)
import Hexagon exposing (cubeToOddRow, oddRowToCube)
import List exposing (any, filter, head, map)
import Monster exposing (Monster, MonsterLevel(..), monsterTypeToString)
import Scenario exposing (Scenario, ScenarioMonster, mapTileDataToList, mapTileDataToOverlayList)


type NumPlayers
    = TwoPlayer
    | ThreePlayer
    | FourPlayer


type AIType
    = Enemy Monster
    | Summons Int CharacterClass


type PieceType
    = None
    | Player CharacterClass
    | AI AIType


type alias Piece =
    { ref : PieceType
    , x : Int
    , y : Int
    }


type alias Cell =
    { rooms : List MapTileRef
    , passable : Bool
    }


type alias Game =
    { state : GameState
    , roomOrigins : Dict String ( Int, Int )
    , roomTurns : Dict String Int
    , staticBoard : Array (Array Cell)
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
                Summons _ _ ->
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
                Summons _ _ ->
                    ""

                Enemy e ->
                    case monsterTypeToString e.monster of
                        Just m ->
                            m

                        Nothing ->
                            ""

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
            initialize arrSize (always (initialize arrSize (always (Cell [] False))))
    in
    setCellsFromMapTiles mapTiles initOverlays bounds.minX offsetY (Game initGameState Dict.empty Dict.empty initMap)


setCellsFromMapTiles : List MapTile -> Dict String ( List BoardOverlay, List ScenarioMonster ) -> Int -> Int -> Game -> Game
setCellsFromMapTiles mapTileList overlays offsetX offsetY game =
    case mapTileList of
        [] ->
            game

        [ last ] ->
            setCellFromMapTile game overlays offsetX offsetY last
                |> setCellsFromMapTiles [] overlays offsetX offsetY

        head :: rest ->
            setCellFromMapTile game overlays offsetX offsetY head
                |> setCellsFromMapTiles rest overlays offsetX offsetY


setCellFromMapTile : Game -> Dict String ( List BoardOverlay, List ScenarioMonster ) -> Int -> Int -> MapTile -> Game
setCellFromMapTile game overlays offsetX offsetY tile =
    let
        x =
            tile.x - offsetX

        y =
            tile.y - offsetY

        refString =
            case refToString tile.ref of
                Just s ->
                    s

                Nothing ->
                    ""

        newOrigins =
            if tile.originalX == 0 && tile.originalY == 0 then
                Dict.insert refString ( x, y ) game.roomOrigins

            else
                game.roomOrigins

        state =
            game.state

        ( boardOverlays, piece ) =
            case Dict.get refString overlays of
                Just ( o, m ) ->
                    ( filter (filterByCoord tile.originalX tile.originalY) o
                        |> map (mapOverlayCoord tile.originalX tile.originalY x y tile.turns)
                    , filter (filterMonsterLevel game.state.numPlayers) m
                        |> filter (\f -> f.initialX == tile.originalX && f.initialY == tile.originalY)
                        |> head
                        |> getPieceFromMonster game.state.numPlayers
                        |> mapPieceCoord tile.originalX tile.originalY x y
                    )

                Nothing ->
                    ( [], Piece None 0 0 )

        newGameState =
            { state
                | overlays = game.state.overlays ++ boardOverlays
                , pieces =
                    game.state.pieces
                        ++ (case piece.ref of
                                None ->
                                    []

                                _ ->
                                    [ piece ]
                           )
                , visibleRooms =
                    if any (\r -> r.ref == StartingLocation) boardOverlays then
                        tile.ref :: game.state.visibleRooms

                    else
                        game.state.visibleRooms
            }

        rowArr =
            Array.get y game.staticBoard

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
                                    { foundCell
                                        | passable =
                                            if foundCell.passable == False then
                                                tile.passable

                                            else
                                                True
                                        , rooms = tile.ref :: foundCell.rooms
                                    }
                            in
                            set y (set x newCell yRow) game.staticBoard

                        Nothing ->
                            game.staticBoard

                Nothing ->
                    game.staticBoard
    in
    { game | state = newGameState, staticBoard = newBoard, roomOrigins = newOrigins, roomTurns = Dict.insert refString tile.turns game.roomTurns }


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
            Piece None 0 0


filterByCoord : Int -> Int -> BoardOverlay -> Bool
filterByCoord x y overlay =
    case overlay.cells of
        ( overlayX, overlayY ) :: _ ->
            overlayX == x && overlayY == y

        [] ->
            False


mapPieceCoord : Int -> Int -> Int -> Int -> Piece -> Piece
mapPieceCoord _ _ newX newY piece =
    { piece | x = newX, y = newY }


mapOverlayCoord : Int -> Int -> Int -> Int -> Int -> BoardOverlay -> BoardOverlay
mapOverlayCoord originalX originalY newX newY turns overlay =
    let
        ( oX, oY, oZ ) =
            oddRowToCube ( originalX, originalY )

        ( nX, nY, nZ ) =
            oddRowToCube ( newX, newY )

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
                            Hexagon.rotate c ( originalX, originalY ) turns
                                |> oddRowToCube
                    in
                    cubeToOddRow ( diffX + x1, diffY + y1, diffZ + z1 )
                )
                overlay.cells
    }


movePiece : Piece -> ( Int, Int ) -> ( Int, Int ) -> Game -> ( Game, Piece )
movePiece piece ( fromX, fromY ) ( toX, toY ) game =
    let
        newPiece =
            { piece | x = toX, y = toY }

        gamestate =
            game.state

        newGamestate =
            { gamestate | pieces = filter (removePiece { piece | x = fromX, y = fromY }) gamestate.pieces }
    in
    if canMoveTo ( toX, toY ) { game | state = newGamestate } then
        ( { game | state = { newGamestate | pieces = newPiece :: newGamestate.pieces } }
        , newPiece
        )

    else
        ( game, piece )


moveOverlay : BoardOverlay -> ( Int, Int ) -> ( Int, Int ) -> Game -> ( Game, BoardOverlay )
moveOverlay overlay ( fromX, fromY ) ( toX, toY ) game =
    ( game, overlay )


removePiece : Piece -> Piece -> Bool
removePiece pieceToRemove comparePiece =
    pieceToRemove.ref
        /= comparePiece.ref
        || pieceToRemove.x
        /= comparePiece.x
        || pieceToRemove.y
        /= comparePiece.y


canMoveTo : ( Int, Int ) -> Game -> Bool
canMoveTo ( toX, toY ) game =
    case Array.get toY game.staticBoard of
        Just row ->
            case Array.get toX row of
                Just cell ->
                    if cell.passable then
                        -- TODO : Account for obstacles, account for hidden rooms
                        if any (\p -> p.x == toX && p.y == toY) game.state.pieces then
                            False

                        else
                            True

                    else
                        False

                Nothing ->
                    False

        Nothing ->
            False
