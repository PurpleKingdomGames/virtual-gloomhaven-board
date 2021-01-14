module Game exposing (AIType(..), Cell, Expansion(..), Game, GameState, GameStateScenario(..), Piece, PieceType(..), RoomData, SummonsType(..), assignIdentifier, assignPlayers, empty, emptyState, generateGameMap, getPieceName, getPieceType, moveOverlay, moveOverlayWithoutState, movePiece, movePieceWithoutState, removePieceFromBoard, revealRooms)

import Array exposing (Array, fromList, get, indexedMap, initialize, length, push, set, slice, toList)
import Bitwise exposing (and)
import BoardMapTile exposing (MapTile, MapTileRef, refToString)
import BoardOverlay exposing (BoardOverlay, BoardOverlayDirectionType(..), BoardOverlayType(..), CorridorMaterial(..), DoorSubType(..), TreasureSubType(..), getBoardOverlayName)
import Character exposing (CharacterClass, characterToString)
import Dict exposing (Dict, get, insert)
import Hexagon exposing (cubeToOddRow, oddRowToCube)
import List exposing (all, any, filter, filterMap, foldl, head, map, member)
import List.Extra exposing (uniqueBy)
import Monster exposing (Monster, MonsterLevel(..), getMonsterBucketSize, monsterTypeToString)
import Random exposing (Seed)
import Scenario exposing (Scenario, ScenarioMonster, mapTileDataToList, mapTileDataToOverlayList)


empty : Game
empty =
    Game emptyState Scenario.empty (Random.initialSeed 0) [] Array.empty


emptyState : GameState
emptyState =
    GameState (InbuiltScenario Gloomhaven 1) [] 0 [] [] [] Dict.empty ""


type AIType
    = Enemy Monster
    | Summons SummonsType


type SummonsType
    = NormalSummons Int
    | BearSummons


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
    , scenario : Scenario
    , seed : Random.Seed
    , roomData : List RoomData
    , staticBoard : Array (Array Cell)
    }


type alias GameState =
    { scenario : GameStateScenario
    , players : List CharacterClass
    , updateCount : Int
    , visibleRooms : List MapTileRef
    , overlays : List BoardOverlay
    , pieces : List Piece
    , availableMonsters : Dict String (Array Int)
    , roomCode : String
    }


type GameStateScenario
    = InbuiltScenario Expansion Int


type Expansion
    = Gloomhaven
    | Solo


type alias RoomData =
    { ref : MapTileRef
    , origin : ( Int, Int )
    , turns : Int
    }


getPieceType : PieceType -> String
getPieceType piece =
    case piece of
        Player _ ->
            "player"

        AI t ->
            case t of
                Summons _ ->
                    "player"

                Enemy _ ->
                    "monster"

        None ->
            ""


getPieceName : PieceType -> String
getPieceName piece =
    case piece of
        Player p ->
            Maybe.withDefault "" (characterToString p)

        AI t ->
            case t of
                Summons _ ->
                    "summons"

                Enemy e ->
                    Maybe.withDefault "" (monsterTypeToString e.monster)

        None ->
            ""


generateGameMap : GameStateScenario -> Scenario -> String -> List CharacterClass -> Seed -> Game
generateGameMap gameStateScenario scenario roomCode players seed =
    let
        ( mapTiles, bounds ) =
            mapTileDataToList scenario.mapTilesData Nothing

        availableMonsters =
            map (\m -> ( Maybe.withDefault "" (monsterTypeToString m), initialize (getMonsterBucketSize m) identity )) scenario.additionalMonsters
                |> filter (\( k, _ ) -> k /= "")
                |> map (\( k, v ) -> ( k, Tuple.first (orderRandomArrElement Array.empty seed v) ))
                |> Dict.fromList

        initGameState =
            GameState gameStateScenario
                players
                0
                []
                []
                []
                availableMonsters
                roomCode

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

        initGame =
            setCellsFromMapTiles mapTiles initOverlays bounds.minX offsetY seed (Game initGameState scenario seed [] initMap)
                |> ensureUniqueOverlays

        startRooms =
            filterMap
                (\o ->
                    case o.ref of
                        StartingLocation ->
                            Just o.cells

                        _ ->
                            Nothing
                )
                initGame.state.overlays
                |> List.foldl (++) []
                |> filterMap (getRoomsByCoord initGame.staticBoard)
                |> List.foldl (++) []
                |> uniqueBy (\ref -> Maybe.withDefault "" (refToString ref))
    in
    revealRooms initGame startRooms


setCellsFromMapTiles : List MapTile -> Dict String ( List BoardOverlay, List ScenarioMonster ) -> Int -> Int -> Seed -> Game -> Game
setCellsFromMapTiles mapTileList overlays offsetX offsetY seed game =
    case mapTileList of
        head :: rest ->
            let
                ( newGame, newSeed ) =
                    setCellFromMapTile game overlays offsetX offsetY head seed
            in
            setCellsFromMapTiles rest overlays offsetX offsetY newSeed newGame

        _ ->
            game


setCellFromMapTile : Game -> Dict String ( List BoardOverlay, List ScenarioMonster ) -> Int -> Int -> MapTile -> Seed -> ( Game, Seed )
setCellFromMapTile game overlays offsetX offsetY tile seed =
    let
        x =
            tile.x - offsetX

        y =
            tile.y - offsetY

        refString =
            Maybe.withDefault "" (refToString tile.ref)

        ( isOrigin, newOrigins ) =
            if tile.originalX == 0 && tile.originalY == 0 then
                ( True, RoomData tile.ref ( x, y ) tile.turns :: game.roomData )

            else
                ( False, game.roomData )

        state =
            game.state

        ( boardOverlays, piece ) =
            case Dict.get refString overlays of
                Just ( o, m ) ->
                    ( filter (filterByCoord tile.originalX tile.originalY) o
                        |> map (mapOverlayCoord tile.originalX tile.originalY x y tile.turns)
                    , filter (filterMonsterLevel (List.length game.state.players)) m
                        |> filter (\f -> f.initialX == tile.originalX && f.initialY == tile.originalY)
                        |> head
                        |> getPieceFromMonster (List.length game.state.players)
                        |> mapPieceCoord tile.originalX tile.originalY x y
                    )

                Nothing ->
                    ( [], Piece None 0 0 )

        doorRefs =
            boardOverlays
                |> filterMap
                    (\o ->
                        case o.ref of
                            Door _ refs ->
                                Just refs

                            _ ->
                                Nothing
                    )
                |> foldl (++) []

        ( monsterBucket, newSeed ) =
            case piece.ref of
                AI (Enemy m) ->
                    initialize (getMonsterBucketSize m.monster) identity
                        |> orderRandomArrElement Array.empty seed
                        |> (\( a, s ) -> ( Just ( Maybe.withDefault "" (monsterTypeToString m.monster), a ), s ))

                _ ->
                    ( Nothing, seed )

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
                , availableMonsters =
                    case monsterBucket of
                        Just b ->
                            b
                                :: Dict.toList game.state.availableMonsters
                                |> filter (\( k, _ ) -> k /= "")
                                |> Dict.fromList

                        _ ->
                            game.state.availableMonsters
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
                                        , rooms =
                                            tile.ref
                                                :: (doorRefs ++ foundCell.rooms)
                                                |> uniqueBy (\r -> Maybe.withDefault "" (refToString r))
                                    }
                            in
                            set y (set x newCell yRow) game.staticBoard

                        Nothing ->
                            game.staticBoard

                Nothing ->
                    game.staticBoard
    in
    if tile.passable || (List.length doorRefs > 0) || isOrigin then
        ( { game | state = newGameState, staticBoard = newBoard, roomData = newOrigins }
        , newSeed
        )

    else
        ( { game | seed = newSeed }, newSeed )


filterMonsterLevel : Int -> ScenarioMonster -> Bool
filterMonsterLevel numPlayers monster =
    if numPlayers < 3 then
        monster.twoPlayer /= Monster.None

    else if numPlayers < 4 then
        monster.threePlayer /= Monster.None

    else
        monster.fourPlayer /= Monster.None


getLevelForMonster : Int -> ScenarioMonster -> MonsterLevel
getLevelForMonster numPlayers monster =
    if numPlayers < 3 then
        monster.twoPlayer

    else if numPlayers < 4 then
        monster.threePlayer

    else
        monster.fourPlayer


getPieceFromMonster : Int -> Maybe ScenarioMonster -> Piece
getPieceFromMonster numPlayers monster =
    case monster of
        Just p ->
            let
                m =
                    p.monster

                level =
                    getLevelForMonster numPlayers p
            in
            if level == Monster.None then
                Piece None 0 0

            else
                Piece (AI (Enemy { m | level = level })) p.initialX p.initialY

        Nothing ->
            Piece None 0 0


getRoomsByCoord : Array (Array Cell) -> ( Int, Int ) -> Maybe (List MapTileRef)
getRoomsByCoord cells ( x, y ) =
    Array.get y cells
        |> Maybe.andThen
            (\colCell ->
                Array.get x colCell
                    |> Maybe.map (\cell -> cell.rooms)
            )


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


movePiece : Piece -> Maybe ( Int, Int ) -> ( Int, Int ) -> Game -> ( Game, Piece )
movePiece piece fromCoords ( toX, toY ) game =
    let
        gamestate =
            game.state

        ( newPieces, newPiece ) =
            movePieceWithoutState piece fromCoords ( toX, toY ) game.state.pieces

        newGamestate =
            case fromCoords of
                Just ( fromX, fromY ) ->
                    { gamestate | pieces = newPieces |> filter (\p -> p /= newPiece) }

                Nothing ->
                    gamestate
    in
    if canMoveTo ( toX, toY ) { game | state = newGamestate } True then
        ( { game | state = { newGamestate | pieces = newPiece :: newGamestate.pieces } }
        , newPiece
        )

    else
        ( game, piece )


movePieceWithoutState : Piece -> Maybe ( Int, Int ) -> ( Int, Int ) -> List Piece -> ( List Piece, Piece )
movePieceWithoutState piece fromCoords ( toX, toY ) pieces =
    let
        newPiece =
            { piece | x = toX, y = toY }

        newPieces =
            case fromCoords of
                Just ( fromX, fromY ) ->
                    filter (removePiece { piece | x = fromX, y = fromY }) pieces

                Nothing ->
                    pieces
    in
    if List.any (\p -> p.x == toX && p.y == toY) newPieces then
        ( pieces, piece )

    else
        ( newPiece :: newPieces, newPiece )


moveOverlay : BoardOverlay -> Maybe ( Int, Int ) -> Maybe ( Int, Int ) -> ( Int, Int ) -> Game -> ( Game, BoardOverlay, Maybe ( Int, Int ) )
moveOverlay overlay fromCoords prevCoords ( toX, toY ) game =
    let
        gamestate =
            game.state

        ( newOverlays, newOverlay, newCoords ) =
            moveOverlayWithoutState overlay fromCoords prevCoords ( toX, toY ) game.state.overlays

        newGamestate =
            case fromCoords of
                Just justFrom ->
                    { gamestate
                        | overlays =
                            newOverlays
                                |> filter (\o -> o /= newOverlay)
                    }

                Nothing ->
                    gamestate

        newGame =
            { game | state = newGamestate }
    in
    if all (\c -> canMoveTo c newGame True) newOverlay.cells then
        ( { game | state = { newGamestate | overlays = newOverlay :: newGamestate.overlays } }
        , newOverlay
        , Just ( toX, toY )
        )

    else
        ( game, overlay, prevCoords )


moveOverlayWithoutState : BoardOverlay -> Maybe ( Int, Int ) -> Maybe ( Int, Int ) -> ( Int, Int ) -> List BoardOverlay -> ( List BoardOverlay, BoardOverlay, Maybe ( Int, Int ) )
moveOverlayWithoutState overlay fromCoords prevCoords ( toX, toY ) overlays =
    let
        ( fromX, fromY, fromZ ) =
            case fromCoords of
                Just ( oX, oY ) ->
                    oddRowToCube ( oX, oY )

                Nothing ->
                    ( 0, 0, 0 )

        ( prevDiffX, prevDiffY, prevDiffZ ) =
            case prevCoords of
                Just p ->
                    let
                        ( pX, pY, pZ ) =
                            oddRowToCube p
                    in
                    ( fromX - pX, fromY - pY, fromZ - pZ )

                Nothing ->
                    ( 0, 0, 0 )

        ( diffX, diffY, diffZ ) =
            let
                ( dX, dY, dZ ) =
                    case fromCoords of
                        Just _ ->
                            let
                                ( newX, newY, newZ ) =
                                    oddRowToCube ( toX, toY )
                            in
                            ( newX - fromX, newY - fromY, newZ - fromZ )

                        Nothing ->
                            oddRowToCube ( toX, toY )
            in
            ( dX + prevDiffX, dY + prevDiffY, dZ + prevDiffZ )

        moveCells c =
            let
                ( cX, cY, cZ ) =
                    oddRowToCube c
            in
            cubeToOddRow ( cX + diffX, cY + diffY, cZ + diffZ )

        newOverlay =
            { overlay | cells = map moveCells overlay.cells }

        newOverlays =
            case fromCoords of
                Just justFrom ->
                    filter
                        (\o -> o.ref /= overlay.ref || List.all (\c -> c /= justFrom) o.cells)
                        overlays

                Nothing ->
                    overlays
    in
    ( newOverlays
    , newOverlay
    , Just ( toX, toY )
    )


revealRooms : Game -> List MapTileRef -> Game
revealRooms game rooms =
    case rooms of
        room :: rest ->
            revealRooms (revealRoom room game) rest

        _ ->
            game


revealRoom : MapTileRef -> Game -> Game
revealRoom room game =
    if member room game.state.visibleRooms then
        game

    else
        let
            roomCells =
                indexedMap (\y arr -> indexedMap (\x cell -> ( cell, ( x, y ) )) arr) game.staticBoard
                    |> Array.foldl (\a b -> fromList (toList a ++ toList b)) Array.empty
                    |> toList
                    |> filter (\( cell, _ ) -> cell.passable && member room cell.rooms)
                    |> map (\( _, c ) -> c)

            ( assignedMonsters, availableMonsters ) =
                filterMap
                    (\p ->
                        case p.ref of
                            AI (Enemy e) ->
                                if member ( p.x, p.y ) roomCells && e.id == 0 then
                                    Just p

                                else
                                    Nothing

                            _ ->
                                Nothing
                    )
                    game.state.pieces
                    |> assignIdentifiers game.state.availableMonsters []
                    |> (\( m, a ) ->
                            ( filterMap
                                (\p ->
                                    case p.ref of
                                        AI (Enemy e) ->
                                            if e.id /= 0 then
                                                Just p

                                            else
                                                Nothing

                                        _ ->
                                            Nothing
                                )
                                m
                            , a
                            )
                       )

            ignoredPieces =
                filterMap
                    (\p ->
                        case p.ref of
                            AI (Enemy e) ->
                                if member ( p.x, p.y ) roomCells && e.id == 0 then
                                    Nothing

                                else
                                    Just p

                            _ ->
                                Just p
                    )
                    game.state.pieces

            state =
                game.state

            newGame =
                { game | state = { state | visibleRooms = room :: state.visibleRooms, availableMonsters = availableMonsters, pieces = ignoredPieces ++ assignedMonsters } }

            corridors =
                game.state.overlays
                    |> filter
                        (\o ->
                            case o.ref of
                                Door (Corridor m _) refs ->
                                    case m of
                                        Dark ->
                                            False

                                        _ ->
                                            member room refs

                                _ ->
                                    False
                        )
                    |> filterMap
                        (\o ->
                            case o.ref of
                                Door (Corridor _ _) refs ->
                                    Just refs

                                _ ->
                                    Nothing
                        )
                    |> foldl (++) []
                    |> filter (\r -> r /= room)
        in
        revealRooms newGame corridors


removePieceFromBoard : Piece -> Game -> Game
removePieceFromBoard piece game =
    let
        gameState =
            game.state

        filteredPieces =
            filter (removePiece piece) gameState.pieces

        newAvailableMonsters =
            case piece.ref of
                AI (Enemy m) ->
                    let
                        ref =
                            Maybe.withDefault "" (monsterTypeToString m.monster)
                    in
                    case Dict.get ref gameState.availableMonsters of
                        Just v ->
                            insert ref (push (m.id - 1) v) gameState.availableMonsters

                        Nothing ->
                            insert ref (fromList [ m.id - 1 ]) gameState.availableMonsters

                _ ->
                    gameState.availableMonsters

        newOverlays =
            case piece.ref of
                AI (Enemy m) ->
                    if m.wasSummoned then
                        gameState.overlays

                    else if
                        any
                            (\o ->
                                case o.ref of
                                    Treasure (Coin _) ->
                                        member ( piece.x, piece.y ) o.cells

                                    _ ->
                                        False
                            )
                            gameState.overlays
                    then
                        map
                            (\o ->
                                case o.ref of
                                    Treasure (Coin i) ->
                                        if member ( piece.x, piece.y ) o.cells then
                                            { o | ref = Treasure (Coin (i + 1)) }

                                        else
                                            o

                                    _ ->
                                        o
                            )
                            gameState.overlays

                    else
                        BoardOverlay (Treasure (Coin 1)) Default [ ( piece.x, piece.y ) ]
                            :: gameState.overlays

                _ ->
                    gameState.overlays
    in
    { game | state = { gameState | pieces = filteredPieces, overlays = newOverlays, availableMonsters = newAvailableMonsters } }


assignIdentifiers : Dict String (Array Int) -> List Piece -> List Piece -> ( List Piece, Dict String (Array Int) )
assignIdentifiers availableMonsters processed monsters =
    case monsters of
        m :: rest ->
            let
                ( newM, newBucket ) =
                    assignIdentifier availableMonsters m
            in
            assignIdentifiers newBucket (newM :: processed) rest

        _ ->
            ( processed, availableMonsters )


assignIdentifier : Dict String (Array Int) -> Piece -> ( Piece, Dict String (Array Int) )
assignIdentifier availableMonsters p =
    case p.ref of
        AI (Enemy monster) ->
            case monsterTypeToString monster.monster of
                Just key ->
                    case Dict.get key availableMonsters of
                        Just bucket ->
                            case Array.get 0 bucket of
                                Just id ->
                                    ( { p | ref = AI (Enemy { monster | id = id + 1 }) }, insert key (slice 1 (length bucket) bucket) availableMonsters )

                                Nothing ->
                                    ( { p | ref = AI (Enemy { monster | id = 0 }) }, availableMonsters )

                        Nothing ->
                            ( { p | ref = AI (Enemy { monster | id = 0 }) }, availableMonsters )

                Nothing ->
                    ( { p | ref = AI (Enemy { monster | id = 0 }) }, availableMonsters )

        _ ->
            ( p, availableMonsters )


removePiece : Piece -> Piece -> Bool
removePiece pieceToRemove comparePiece =
    pieceToRemove.ref
        /= comparePiece.ref
        || pieceToRemove.x
        /= comparePiece.x
        || pieceToRemove.y
        /= comparePiece.y


canMoveTo : ( Int, Int ) -> Game -> Bool -> Bool
canMoveTo ( toX, toY ) game ignoreObstacles =
    let
        obstacleList =
            if ignoreObstacles then
                []

            else
                game.state.overlays
                    |> filter
                        (\o ->
                            case o.ref of
                                Obstacle _ ->
                                    True

                                Trap _ ->
                                    True

                                Door (Corridor _ _) _ ->
                                    False

                                Door _ _ ->
                                    True

                                _ ->
                                    False
                        )
    in
    case Array.get toY game.staticBoard of
        Just row ->
            case Array.get toX row of
                Just cell ->
                    any (\c -> List.member c cell.rooms) game.state.visibleRooms
                        && cell.passable
                        && all (\p -> p.x /= toX || p.y /= toY) game.state.pieces
                        && (ignoreObstacles
                                || all (\o -> List.all (\c -> c /= ( toX, toY )) o.cells) obstacleList
                           )

                Nothing ->
                    False

        Nothing ->
            False


orderRandomArrElement : Array a -> Seed -> Array a -> ( Array a, Seed )
orderRandomArrElement bucket seed original =
    if length original == 0 then
        ( bucket, seed )

    else
        let
            ( index, newSeed ) =
                Random.step (Random.int 0 (length original - 1)) seed

            slice1 =
                toList (slice 0 index original)

            slice2 =
                toList (slice (index + 1) (length original) original)
        in
        case Array.get index original of
            Just o ->
                orderRandomArrElement (push o bucket) newSeed (fromList (slice1 ++ slice2))

            Nothing ->
                ( bucket, seed )


assignPlayers : List CharacterClass -> Game -> Game
assignPlayers players game =
    let
        state =
            game.state

        filteredPieces =
            filter
                (\p ->
                    case p.ref of
                        AI (Enemy _) ->
                            True

                        _ ->
                            False
                )
                state.pieces

        statingLocations =
            filter
                (\o ->
                    case o.ref of
                        StartingLocation ->
                            True

                        _ ->
                            False
                )
                state.overlays
    in
    { game | state = { state | players = players, pieces = assignPlayersToPiece players filteredPieces statingLocations } }


assignPlayersToPiece : List CharacterClass -> List Piece -> List BoardOverlay -> List Piece
assignPlayersToPiece players pieces startingLocations =
    let
        filteredLocations =
            filter
                (\o ->
                    case o.ref of
                        StartingLocation ->
                            True

                        _ ->
                            False
                )
                startingLocations
    in
    case players of
        player :: rest ->
            case filteredLocations of
                location :: otherLocations ->
                    case head location.cells of
                        Just ( x, y ) ->
                            assignPlayersToPiece rest (Piece (Player player) x y :: pieces) otherLocations

                        Nothing ->
                            pieces

                _ ->
                    pieces

        _ ->
            pieces


ensureUniqueOverlays : Game -> Game
ensureUniqueOverlays game =
    let
        state =
            game.state

        overlays =
            state.overlays
                |> uniqueBy
                    (\o ->
                        cellsToString o.cells ++ getBoardOverlayName o.ref
                    )

        pieces =
            state.pieces
                |> uniqueBy
                    (\p ->
                        String.fromInt p.x ++ "x" ++ String.fromInt p.y
                    )
    in
    { game | state = { state | overlays = overlays, pieces = pieces } }


cellsToString : List ( Int, Int ) -> String
cellsToString cells =
    cells
        |> map (\( x, y ) -> String.fromInt x ++ "x" ++ String.fromInt y)
        |> foldl (\s b -> s ++ "|" ++ b) ""
