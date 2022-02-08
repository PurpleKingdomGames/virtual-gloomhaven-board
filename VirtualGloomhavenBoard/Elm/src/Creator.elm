port module Creator exposing (main)

import AppStorage exposing (ExtendedRoomData, MapData, MoveablePiece, MoveablePieceType(..), decodeMoveablePiece, encodeMoveablePiece, loadMapFromStorage, saveMapToStorage)
import Array
import Bitwise
import BoardHtml exposing (CellModel, ContextMenu(..), DragEvents, DropEvents, getAllMapTileHtml, getFooterHtml, getOverlayImageName, makeDraggable, scenarioMonsterToHtml)
import BoardMapTile exposing (MapTileRef(..), getAllRefs, getGridByRef, refToString, stringToRef)
import BoardOverlay exposing (BoardOverlay, BoardOverlayDirectionType(..), BoardOverlayType(..), CorridorSize(..), DifficultTerrainSubType(..), DoorSubType(..), ObstacleSubType(..), TreasureSubType(..), WallSubType(..), getBoardOverlayName, getBoardOverlayType, getOverlayLabel, getOverlayTypesWithLabel)
import Browser
import Character exposing (CharacterClass(..))
import Dict exposing (Dict)
import Dom
import DragPorts
import File exposing (File)
import File.Download as Download
import File.Select as Select
import Game exposing (AIType(..), GameStateScenario(..), Piece, PieceType(..), RoomData, generateGameMap, moveOverlayWithoutState, movePieceWithoutState)
import Hexagon exposing (rotate)
import Html exposing (Html, a, div, header, input, li, nav, section, span, text, ul)
import Html.Attributes exposing (alt, attribute, class, coords, href, id, maxlength, placeholder, src, style, tabindex, target, type_, value)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra.Drag as DragDrop
import Html.Events.Extra.Touch as Touch
import Html.Keyed as Keyed
import Html.Lazy exposing (lazy, lazy2, lazy3, lazy4, lazy5, lazy6, lazy8)
import HtmlEvents exposing (onClickPreventDefault)
import Json.Decode as Decode
import Json.Encode as Encode
import List
import Maybe
import Monster exposing (MonsterLevel(..), MonsterType(..), getAllBosses, getAllMonsters, monsterTypeToString)
import Random
import Scenario exposing (DoorData(..), MapTileData, Scenario, ScenarioMonster, normaliseAndRotatePoint)
import ScenarioSync exposing (decodeScenario, encodeScenario)
import Task
import Tuple
import Version


port getCellFromPoint : ( Float, Float, Bool ) -> Cmd msg


port onCellFromPoint : (( Int, Int, Bool ) -> msg) -> Sub msg


port getContextPosition : ( Int, Int ) -> Cmd msg


port onContextPosition : (( Int, Int ) -> msg) -> Sub msg


port getConfirmCreateNew : () -> Cmd msg


port onConfirmCreateNew : (() -> msg) -> Sub msg


type alias Model =
    { map : MapData
    , currentDraggable : Maybe MoveablePiece
    , menuOpen : Bool
    , sideMenu : SideMenu
    , contextMenuState : ContextMenu
    , contextMenuPosition : ( Int, Int )
    , contextMenuAbsPosition : ( Int, Int )
    , cachedDoors : List String
    , cachedObstacles : List String
    , cachedMisc : List String
    , cachedRoomCells : List ( MapTileRef, Dict ( Int, Int ) ( ( Int, Int ), Bool ) )
    , errorString : String
    , showError : Bool
    }


type SideMenu
    = MapTileMenu
    | DoorMenu
    | ObstacleMenu
    | MiscMenu
    | MonsterMenu
    | BossMenu


type Msg
    = MoveStarted MoveablePiece (Maybe ( DragDrop.EffectAllowed, Decode.Value ))
    | MoveTargetChanged ( Int, Int ) (Maybe ( DragDrop.DropEffect, Decode.Value ))
    | MoveCanceled
    | MoveCompleted
    | TouchStart MoveablePiece
    | TouchMove ( Float, Float )
    | TouchCanceled
    | TouchEnd ( Float, Float )
    | CellFromPoint ( Int, Int, Bool )
    | ToggleMenu
    | ChangeSideMenu SideMenu
    | OpenContextMenu ( Int, Int )
    | ChangeContextMenuState ContextMenu
    | ChangeMonsterState Int Int MonsterLevel
    | ChangeContextMenuAbsposition ( Int, Int )
    | RemoveMonster Int
    | RotateOverlay Int
    | RemoveOverlay Int
    | RotateRoom MapTileRef
    | RemoveRoom MapTileRef
    | ConfirmCreateNew
    | CreateNew ()
    | ExportFile
    | LoadFile
    | ExtractFileString File
    | LoadScenario String
    | ChangeScenarioTitle String
    | HideError
    | NoOp


dragEvents : DragEvents Msg
dragEvents =
    DragEvents MoveStarted MoveCanceled TouchStart TouchMove TouchEnd NoOp


dropEvents : DropEvents Msg
dropEvents =
    DropEvents MoveTargetChanged MoveCompleted


gridSize : Int
gridSize =
    40


emptyList : List Piece
emptyList =
    []


main : Program (Maybe Decode.Value) Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : Maybe Decode.Value -> ( Model, Cmd Msg )
init initMap =
    let
        mapData =
            case initMap of
                Just m ->
                    case loadMapFromStorage m of
                        Ok map ->
                            map

                        Err _ ->
                            MapData "" [] [] []

                Nothing ->
                    MapData "" [] [] []
    in
    ( initModel mapData, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MoveStarted piece maybeDragData ->
            let
                cmd =
                    case maybeDragData of
                        Just ( e, v ) ->
                            DragPorts.dragstart (DragDrop.startPortData e v)

                        Nothing ->
                            Cmd.none
            in
            ( { model | currentDraggable = Just piece, contextMenuState = Closed }, cmd )

        MoveTargetChanged coords maybeDragOver ->
            case model.currentDraggable of
                Just m ->
                    if m.target == Just coords then
                        ( model, Cmd.none )

                    else
                        let
                            cmd =
                                case maybeDragOver of
                                    Just ( e, v ) ->
                                        DragPorts.dragover (DragDrop.overPortData e v)

                                    Nothing ->
                                        Cmd.none

                            newDraggable =
                                case m.ref of
                                    OverlayType o prevCoords ->
                                        let
                                            ( _, newOverlay, newCoords ) =
                                                moveOverlayWithoutState o m.coords prevCoords coords model.map.overlays

                                            moveablePieceType =
                                                OverlayType newOverlay newCoords

                                            newTarget =
                                                if moveablePieceType == m.ref then
                                                    m.target

                                                else
                                                    Just coords
                                        in
                                        Just (MoveablePiece moveablePieceType m.coords newTarget)

                                    PieceType p ->
                                        let
                                            pieces =
                                                model.map.monsters
                                                    |> List.map (\m1 -> Piece (AI (Enemy m1.monster)) m1.initialX m1.initialY)

                                            newPiece =
                                                PieceType (Tuple.second (movePieceWithoutState p m.coords coords pieces))

                                            newTarget =
                                                if newPiece == m.ref then
                                                    m.target

                                                else
                                                    Just coords
                                        in
                                        Just (MoveablePiece newPiece m.coords newTarget)

                                    RoomType r ->
                                        Just (MoveablePiece (RoomType r) m.coords (Just coords))
                        in
                        ( { model | currentDraggable = newDraggable }, cmd )

                Nothing ->
                    ( model, Cmd.none )

        MoveCanceled ->
            ( { model | currentDraggable = Nothing }, Cmd.none )

        MoveCompleted ->
            let
                moveData =
                    case model.currentDraggable of
                        Just m ->
                            case ( m.ref, m.target ) of
                                ( OverlayType o prevCoords, Just coords ) ->
                                    let
                                        ( g, newOverlay, _ ) =
                                            moveOverlayWithoutState o m.coords prevCoords coords model.map.overlays
                                    in
                                    { overlays = newOverlay :: g
                                    , monsters = model.map.monsters
                                    , roomData = model.map.roomData
                                    , cachedRoomCells = model.cachedRoomCells
                                    }

                                ( PieceType p, Just target ) ->
                                    case p.ref of
                                        AI (Enemy _) ->
                                            let
                                                pieces =
                                                    model.map.monsters
                                                        |> List.map (\m1 -> Piece (AI (Enemy m1.monster)) m1.initialX m1.initialY)

                                                ( newPieces, newPiece ) =
                                                    movePieceWithoutState p m.coords target pieces

                                                m2 =
                                                    List.filterMap (mapPieceToScenarioMonster newPiece model.map.monsters m.coords target) newPieces
                                            in
                                            { overlays = model.map.overlays
                                            , monsters = m2
                                            , roomData = model.map.roomData
                                            , cachedRoomCells = model.cachedRoomCells
                                            }

                                        _ ->
                                            { overlays = model.map.overlays
                                            , monsters = model.map.monsters
                                            , roomData = model.map.roomData
                                            , cachedRoomCells = model.cachedRoomCells
                                            }

                                ( RoomType r, Just target ) ->
                                    let
                                        room =
                                            Maybe.withDefault
                                                (defaultExtendedRoomData r.ref)
                                                (List.filter (\d -> d.data.ref == r.ref) model.map.roomData
                                                    |> List.head
                                                )

                                        ( cells, newRoom ) =
                                            moveRoom target room

                                        roomList =
                                            newRoom :: List.filter (\d -> d.data.ref /= r.ref) model.map.roomData
                                    in
                                    { overlays = model.map.overlays
                                    , monsters = model.map.monsters
                                    , roomData = roomList
                                    , cachedRoomCells =
                                        cells
                                            :: List.filter (\( ref, _ ) -> ref /= r.ref) model.cachedRoomCells
                                    }

                                ( _, Nothing ) ->
                                    { overlays = model.map.overlays
                                    , monsters = model.map.monsters
                                    , roomData = model.map.roomData
                                    , cachedRoomCells = model.cachedRoomCells
                                    }

                        Nothing ->
                            { overlays = model.map.overlays
                            , monsters = model.map.monsters
                            , roomData = model.map.roomData
                            , cachedRoomCells = model.cachedRoomCells
                            }

                map =
                    model.map

                newMap =
                    { map | overlays = moveData.overlays, monsters = moveData.monsters, roomData = moveData.roomData }
            in
            ( { model | currentDraggable = Nothing, map = newMap, cachedRoomCells = moveData.cachedRoomCells }, saveMapToStorage newMap )

        TouchStart piece ->
            update (MoveStarted piece Nothing) model

        TouchCanceled ->
            update MoveCanceled model

        TouchMove ( x, y ) ->
            ( model, getCellFromPoint ( x, y, False ) )

        TouchEnd ( x, y ) ->
            ( model, getCellFromPoint ( x, y, True ) )

        CellFromPoint ( x, y, endTouch ) ->
            if endTouch then
                case model.currentDraggable of
                    Just c ->
                        if Just ( x, y ) == c.coords then
                            update (OpenContextMenu ( x, y )) { model | currentDraggable = Nothing }

                        else
                            update MoveCompleted model

                    Nothing ->
                        ( model, Cmd.none )

            else
                update (MoveTargetChanged ( x, y ) Nothing) model

        ToggleMenu ->
            ( { model | menuOpen = model.menuOpen == False }, Cmd.none )

        ChangeSideMenu menu ->
            ( { model | sideMenu = menu }, Cmd.none )

        OpenContextMenu pos ->
            ( { model | contextMenuState = Open, contextMenuPosition = pos }, getContextPosition pos )

        ChangeContextMenuState state ->
            ( { model | contextMenuState = state }, Cmd.none )

        ChangeContextMenuAbsposition pos ->
            ( { model | contextMenuAbsPosition = pos }, Cmd.none )

        ChangeMonsterState id playerSize level ->
            let
                monster =
                    List.filter (\m1 -> m1.monster.id == id) model.map.monsters
                        |> List.head
            in
            case monster of
                Just m ->
                    let
                        newMonster =
                            if playerSize == 2 then
                                { m | twoPlayer = level }

                            else if playerSize == 3 then
                                { m | threePlayer = level }

                            else if playerSize == 4 then
                                { m | fourPlayer = level }

                            else
                                m

                        newMonsterList =
                            newMonster
                                :: List.filter (\m1 -> m1.monster.id /= id) model.map.monsters

                        map =
                            model.map

                        newMap =
                            { map | monsters = newMonsterList }
                    in
                    ( { model | map = newMap, contextMenuState = Open }, saveMapToStorage newMap )

                Nothing ->
                    ( model, Cmd.none )

        RemoveMonster id ->
            let
                map =
                    model.map

                newMap =
                    { map | monsters = List.filter (\m -> m.monster.id /= id) model.map.monsters }
            in
            ( { model | map = newMap }, saveMapToStorage newMap )

        RotateOverlay id ->
            let
                o1 =
                    List.filter (\o -> o.id == id) model.map.overlays
                        |> List.head
            in
            case o1 of
                Just overlay ->
                    let
                        refPoint =
                            Maybe.withDefault ( 0, 0 ) (List.head overlay.cells)

                        cells =
                            List.map (\c -> rotate c refPoint 1) overlay.cells

                        direction =
                            case overlay.direction of
                                Default ->
                                    DiagonalLeft

                                DiagonalLeft ->
                                    if List.length cells == 1 then
                                        Vertical

                                    else
                                        DiagonalRight

                                Vertical ->
                                    DiagonalRight

                                DiagonalRight ->
                                    Horizontal

                                Horizontal ->
                                    DiagonalLeftReverse

                                DiagonalLeftReverse ->
                                    if List.length cells == 1 then
                                        VerticalReverse

                                    else
                                        DiagonalRightReverse

                                VerticalReverse ->
                                    DiagonalRightReverse

                                DiagonalRightReverse ->
                                    Default

                        newOverlay =
                            { overlay | cells = cells, direction = direction }

                        overlayList =
                            newOverlay
                                :: List.filter (\o2 -> o2.id /= id) model.map.overlays

                        map =
                            model.map

                        newMap =
                            { map | overlays = overlayList }
                    in
                    ( { model | map = newMap }, saveMapToStorage newMap )

                Nothing ->
                    ( model, Cmd.none )

        RemoveOverlay id ->
            let
                map =
                    model.map

                newMap =
                    { map | overlays = List.filter (\o -> o.id /= id) model.map.overlays }
            in
            ( { model | map = newMap }, saveMapToStorage newMap )

        RotateRoom ref ->
            let
                r =
                    List.filter (\r1 -> r1.data.ref == ref) model.map.roomData
                        |> List.head
            in
            case r of
                Just room ->
                    let
                        ( cells, newRoom ) =
                            rotateRoom 1 room

                        newRooms =
                            newRoom
                                :: List.filter (\r2 -> ref /= r2.data.ref) model.map.roomData

                        cachedRoomCells =
                            cells
                                :: List.filter (\( r3, _ ) -> ref /= r3) model.cachedRoomCells

                        map =
                            model.map

                        newMap =
                            { map | roomData = newRooms }
                    in
                    ( { model | map = newMap, cachedRoomCells = cachedRoomCells }, saveMapToStorage newMap )

                Nothing ->
                    ( model, Cmd.none )

        RemoveRoom ref ->
            let
                map =
                    model.map

                newMap =
                    { map | roomData = List.filter (\r -> r.data.ref /= ref) model.map.roomData }
            in
            ( { model
                | map = newMap
                , cachedRoomCells = List.filter (\( r, _ ) -> r /= ref) model.cachedRoomCells
              }
            , saveMapToStorage newMap
            )

        ConfirmCreateNew ->
            ( model, getConfirmCreateNew () )

        CreateNew _ ->
            let
                mapData =
                    MapData "" [] [] []
            in
            ( initModel mapData, saveMapToStorage mapData )

        ExportFile ->
            let
                overlays =
                    List.filterMap
                        (\o ->
                            Maybe.map
                                (\origin ->
                                    let
                                        ( x, y ) =
                                            origin

                                        startY =
                                            y + 1

                                        cells =
                                            origin
                                                :: (List.range 1 6
                                                        |> List.map
                                                            (\i ->
                                                                Hexagon.rotate ( x, startY ) origin i
                                                            )
                                                   )

                                        rooms =
                                            List.filterMap
                                                (\c ->
                                                    List.filterMap
                                                        (\r ->
                                                            if Dict.member c (Tuple.second r) then
                                                                Just (Tuple.first r)

                                                            else
                                                                Nothing
                                                        )
                                                        model.cachedRoomCells
                                                        |> List.head
                                                )
                                                cells
                                    in
                                    case List.head rooms of
                                        Just c ->
                                            case o.ref of
                                                Door d _ ->
                                                    let
                                                        distinctRoom =
                                                            List.foldr
                                                                (\a b ->
                                                                    if List.member a b then
                                                                        b

                                                                    else
                                                                        a :: b
                                                                )
                                                                []
                                                                rooms
                                                    in
                                                    Just ( c, { o | ref = Door d distinctRoom } )

                                                _ ->
                                                    List.filter (\m -> m.data.ref == c) model.map.roomData
                                                        |> List.head
                                                        |> Maybe.map
                                                            (\m ->
                                                                let
                                                                    newCells =
                                                                        List.filterMap
                                                                            (\cell -> mapCoordsToRoom m.data.ref m.data.turns cell model.cachedRoomCells)
                                                                            o.cells
                                                                in
                                                                ( c, { o | cells = newCells } )
                                                            )

                                        _ ->
                                            Nothing
                                )
                                (List.head o.cells)
                                |> (\e ->
                                        case e of
                                            Just (Just a) ->
                                                Just a

                                            _ ->
                                                Nothing
                                   )
                        )
                        model.map.overlays

                monsters =
                    List.filterMap
                        (\m ->
                            let
                                origin =
                                    ( m.initialX, m.initialY )

                                startY =
                                    m.initialY + 1

                                cells =
                                    origin
                                        :: (List.range 1 6
                                                |> List.map
                                                    (\i ->
                                                        Hexagon.rotate ( m.initialX, startY ) origin i
                                                    )
                                           )

                                room =
                                    List.filterMap
                                        (\c ->
                                            List.filterMap
                                                (\r ->
                                                    if Dict.member c (Tuple.second r) then
                                                        Just (Tuple.first r)

                                                    else
                                                        Nothing
                                                )
                                                model.cachedRoomCells
                                                |> List.head
                                        )
                                        cells
                                        |> List.head
                            in
                            Maybe.map (\r -> ( r, m )) room
                                |> Maybe.andThen
                                    (\( r, _ ) ->
                                        List.filter (\m2 -> m2.data.ref == r) model.map.roomData
                                            |> List.head
                                            |> Maybe.andThen
                                                (\m2 ->
                                                    mapCoordsToRoom m2.data.ref m2.data.turns ( m.initialX, m.initialY ) model.cachedRoomCells
                                                )
                                            |> Maybe.map
                                                (\( newX, newY ) ->
                                                    ( r, { m | initialX = newX, initialY = newY } )
                                                )
                                    )
                        )
                        model.map.monsters

                roomData =
                    List.map (\r -> r.data) model.map.roomData

                scenario =
                    generateScenario model.map.scenarioTitle roomData overlays monsters model.cachedRoomCells
            in
            case scenario of
                Ok s ->
                    ( model
                    , Download.string (model.map.scenarioTitle ++ ".json") "application/json" (Encode.encode 4 (encodeScenario s))
                    )

                Err e ->
                    ( { model | errorString = e, showError = True }, Cmd.none )

        LoadFile ->
            ( model, Select.file [ "application/json" ] ExtractFileString )

        ExtractFileString file ->
            ( model, Task.perform LoadScenario (File.toString file) )

        LoadScenario str ->
            case Decode.decodeString decodeScenario str of
                Ok scenario ->
                    let
                        ( rooms, initOverlays, twoPlayerMonsters ) =
                            generateGameMap (CustomScenario str) scenario "" [ Brute, Cragheart ] (Random.initialSeed 0)
                                |> (\g ->
                                        ( g.roomData
                                        , g.state.overlays
                                        , g.state.pieces
                                            |> List.filterMap
                                                (\m ->
                                                    case m.ref of
                                                        AI (Enemy monster) ->
                                                            Just
                                                                (ScenarioMonster
                                                                    monster
                                                                    m.x
                                                                    m.y
                                                                    monster.level
                                                                    Monster.None
                                                                    Monster.None
                                                                )

                                                        _ ->
                                                            Nothing
                                                )
                                        )
                                   )

                        threePlayerMonsters =
                            generateGameMap (CustomScenario str) scenario "" [ Brute, Cragheart, Spellweaver ] (Random.initialSeed 0)
                                |> (\g ->
                                        g.state.pieces
                                            |> List.filterMap
                                                (\m ->
                                                    case m.ref of
                                                        AI (Enemy monster) ->
                                                            Just
                                                                (ScenarioMonster
                                                                    monster
                                                                    m.x
                                                                    m.y
                                                                    Monster.None
                                                                    monster.level
                                                                    Monster.None
                                                                )

                                                        _ ->
                                                            Nothing
                                                )
                                   )
                                |> List.foldr
                                    (\monster currentMonsters ->
                                        let
                                            m =
                                                List.filter (\m3 -> m3.initialX == monster.initialX && m3.initialY == monster.initialY) currentMonsters
                                                    |> List.head
                                        in
                                        case m of
                                            Just m1 ->
                                                { m1 | threePlayer = monster.threePlayer }
                                                    :: List.filter (\m2 -> m2 /= m1) currentMonsters

                                            Nothing ->
                                                monster :: currentMonsters
                                    )
                                    twoPlayerMonsters

                        ( _, monsters ) =
                            generateGameMap (CustomScenario str) scenario "" [ Brute, Cragheart, Spellweaver, Tinkerer ] (Random.initialSeed 0)
                                |> (\g ->
                                        g.state.pieces
                                            |> List.filterMap
                                                (\m ->
                                                    case m.ref of
                                                        AI (Enemy monster) ->
                                                            Just
                                                                (ScenarioMonster
                                                                    monster
                                                                    m.x
                                                                    m.y
                                                                    Monster.None
                                                                    Monster.None
                                                                    monster.level
                                                                )

                                                        _ ->
                                                            Nothing
                                                )
                                   )
                                |> List.foldr
                                    (\monster currentMonsters ->
                                        let
                                            m =
                                                List.filter (\m3 -> m3.initialX == monster.initialX && m3.initialY == monster.initialY) currentMonsters
                                                    |> List.head
                                        in
                                        case m of
                                            Just m1 ->
                                                { m1 | fourPlayer = monster.fourPlayer }
                                                    :: List.filter (\m2 -> m2 /= m1) currentMonsters

                                            Nothing ->
                                                monster :: currentMonsters
                                    )
                                    threePlayerMonsters
                                |> List.foldr
                                    (\a ( i, b ) ->
                                        let
                                            m =
                                                a.monster
                                        in
                                        ( i + 1, { a | monster = { m | id = i } } :: b )
                                    )
                                    ( 1, [] )

                        ( _, overlays ) =
                            List.foldr
                                (\a ( i, b ) ->
                                    ( i + 1, { a | id = i } :: b )
                                )
                                ( 1, [] )
                                initOverlays

                        ( cells, roomData ) =
                            rooms
                                |> List.map
                                    (\r ->
                                        defaultExtendedRoomData r.ref
                                            |> rotateRoom r.turns
                                            |> (\( _, r1 ) -> moveRoom r.origin r1)
                                    )
                                |> List.foldr
                                    (\( c, r ) ( cells1, rooms1 ) -> ( c :: cells1, r :: rooms1 ))
                                    ( [], [] )

                        map =
                            model.map

                        newMap =
                            { map
                                | scenarioTitle = scenario.title
                                , overlays = overlays
                                , monsters = monsters
                                , roomData = roomData
                            }
                    in
                    ( { model
                        | map = newMap
                        , cachedRoomCells = cells
                      }
                    , saveMapToStorage newMap
                    )

                Err e ->
                    ( { model | errorString = Decode.errorToString e, showError = True }, Cmd.none )

        ChangeScenarioTitle title ->
            let
                map =
                    model.map

                newMap =
                    { map | scenarioTitle = title }
            in
            ( { model | map = newMap }, saveMapToStorage newMap )

        HideError ->
            ( { model | showError = False }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


view : Model -> Html.Html Msg
view model =
    Keyed.node
        "div"
        [ class "content scenario-creator"
        , id "content"
        , Touch.onCancel (\_ -> TouchCanceled)
        , onClick (ChangeContextMenuState Closed)
        ]
        [ ( "head", getHeaderHtml model )
        , ( "main"
          , div [ class "main" ]
                [ div [ class "page-shadow" ] []
                , Keyed.node
                    "div"
                    [ class
                        "action-list"
                    ]
                    (let
                        roomDragabble =
                            case model.currentDraggable of
                                Just m ->
                                    case m.ref of
                                        RoomType r ->
                                            case m.coords of
                                                Just _ ->
                                                    ""

                                                Nothing ->
                                                    Maybe.withDefault "" (refToString r.ref)

                                        _ ->
                                            ""

                                Nothing ->
                                    ""

                        overlayDragabble =
                            case model.currentDraggable of
                                Just m ->
                                    case m.ref of
                                        OverlayType o _ ->
                                            case m.coords of
                                                Just _ ->
                                                    ""

                                                Nothing ->
                                                    Maybe.withDefault "" (getBoardOverlayName o.ref)

                                        _ ->
                                            ""

                                Nothing ->
                                    ""

                        monsterDraggable =
                            case model.currentDraggable of
                                Just m ->
                                    case m.ref of
                                        PieceType p ->
                                            case p.ref of
                                                AI (Enemy monster) ->
                                                    case m.coords of
                                                        Just _ ->
                                                            ""

                                                        Nothing ->
                                                            Maybe.withDefault "" (monsterTypeToString monster.monster)

                                                _ ->
                                                    ""

                                        _ ->
                                            ""

                                Nothing ->
                                    ""

                        monsterId =
                            1
                                + (List.map (\m -> m.monster.id) model.map.monsters
                                    |> List.maximum
                                    |> Maybe.withDefault 0
                                  )

                        overlayId =
                            1
                                + (List.map (\o -> o.id) model.map.overlays
                                    |> List.maximum
                                    |> Maybe.withDefault 0
                                  )
                     in
                     [ ( "map-tile-list", lazy3 getMapTileListHtml model.map.roomData roomDragabble model.sideMenu )
                     , ( "board-door-list", lazy5 getOverlayListHtml overlayId model.cachedDoors "Doors" overlayDragabble (model.sideMenu == DoorMenu) )
                     , ( "board-obstacle-list", lazy5 getOverlayListHtml overlayId model.cachedObstacles "Obstacles" overlayDragabble (model.sideMenu == ObstacleMenu) )
                     , ( "board-misc-list", lazy5 getOverlayListHtml overlayId model.cachedMisc "Misc." overlayDragabble (model.sideMenu == MiscMenu) )
                     , ( "board-monster-list", lazy3 getScenarioMonsterListHtml monsterId monsterDraggable (model.sideMenu == MonsterMenu) )
                     , ( "board-boss-list", lazy3 getScenarioBossListHtml monsterId monsterDraggable (model.sideMenu == BossMenu) )
                     ]
                    )
                , div
                    [ class "board-wrapper" ]
                    [ div [ class "map-bg" ] []
                    , let
                        ( c, x, y ) =
                            case model.currentDraggable of
                                Just m ->
                                    case m.ref of
                                        RoomType r ->
                                            let
                                                ref =
                                                    Maybe.withDefault "" (refToString r.ref)
                                            in
                                            case m.target of
                                                Just ( x1, y1 ) ->
                                                    ( ref, x1, y1 )

                                                Nothing ->
                                                    ( "", 0, 0 )

                                        _ ->
                                            ( "", 0, 0 )

                                Nothing ->
                                    ( "", 0, 0 )
                      in
                      lazy4 getLazyMapTileHtml model.map.roomData c x y
                    , Keyed.node
                        "div"
                        [ class "board" ]
                        (let
                            encodedDraggable =
                                case model.currentDraggable of
                                    Just c ->
                                        Encode.encode 0 (encodeMoveablePiece c)

                                    Nothing ->
                                        ""

                            draggableCoords =
                                case model.currentDraggable of
                                    Just m ->
                                        case m.ref of
                                            OverlayType o _ ->
                                                let
                                                    coordList =
                                                        case m.coords of
                                                            Just initCoords ->
                                                                model.map.overlays
                                                                    |> List.map (\o1 -> o1.cells)
                                                                    |> List.filter (\c1 -> List.any (\c -> c == initCoords) c1)
                                                                    |> List.foldl (++) []

                                                            Nothing ->
                                                                []

                                                    targetCoords =
                                                        case m.target of
                                                            Just _ ->
                                                                o.cells

                                                            Nothing ->
                                                                []
                                                in
                                                coordList ++ targetCoords

                                            _ ->
                                                (case m.coords of
                                                    Just initCoords ->
                                                        [ initCoords ]

                                                    Nothing ->
                                                        []
                                                )
                                                    ++ (case m.target of
                                                            Just targetCoords ->
                                                                [ targetCoords ]

                                                            Nothing ->
                                                                []
                                                       )

                                    Nothing ->
                                        []
                         in
                         List.repeat gridSize (List.repeat gridSize 0)
                            |> List.indexedMap
                                (getBoardRowHtml model encodedDraggable draggableCoords)
                        )
                    , lazy6 getContextMenu model.contextMenuState model.contextMenuPosition model.contextMenuAbsPosition model.cachedRoomCells model.map.overlays model.map.monsters
                    ]
                , lazy2 getErrorStatusHtml model.errorString model.showError
                ]
          )
        , ( "foot", lazy getFooterHtml Version.get )
        ]


getHeaderHtml : Model -> Html.Html Msg
getHeaderHtml model =
    div
        [ class "header" ]
        [ getMenuToggleHtml model
        , lazy getScenarioTitleHtml model.map.scenarioTitle
        ]


getErrorStatusHtml : String -> Bool -> Html.Html Msg
getErrorStatusHtml message showMessage =
    div
        [ class
            ("errorStatus"
                ++ (if showMessage then
                        " show"

                    else
                        ""
                   )
            )
        , attribute "aria-hidden"
            (if showMessage then
                "false"

             else
                "true"
            )
        ]
        [ span [] [ text message ]
        , a [ onClick HideError ] [ text "Close" ]
        ]


getLazyMapTileHtml : List ExtendedRoomData -> String -> Int -> Int -> Html msg
getLazyMapTileHtml r c x y =
    let
        roomData =
            List.map (\m -> m.data) r
    in
    getAllMapTileHtml roomData c x y


getMenuToggleHtml : Model -> Html.Html Msg
getMenuToggleHtml model =
    div
        [ class
            ("menu"
                ++ (if model.menuOpen then
                        " show"

                    else
                        ""
                   )
            )
        , onClick ToggleMenu
        , tabindex 0
        , attribute "aria-label" "Toggle Menu"
        , attribute "aria-keyshortcuts" "m"
        , attribute "role" "button"
        , attribute "aria-pressed"
            (if model.menuOpen then
                "true"

             else
                "false"
            )
        ]
        [ lazy getMenuHtml model.menuOpen
        ]


getScenarioTitleHtml : String -> Html.Html Msg
getScenarioTitleHtml scenarioTitle =
    header [ attribute "aria-label" "Scenario Title" ]
        [ span [ class "title" ]
            [ input
                [ type_ "text"
                , value scenarioTitle
                , onInput ChangeScenarioTitle
                , placeholder "Enter Scenario Title"
                , maxlength 30
                ]
                []
            ]
        ]


getMenuHtml : Bool -> Html.Html Msg
getMenuHtml menuOpen =
    Dom.element "nav"
        |> Dom.addAttribute
            (attribute
                "aria-hidden"
                (if menuOpen then
                    "false"

                 else
                    "true"
                )
            )
        |> Dom.appendChild
            (Dom.element "ul"
                |> Dom.addAttribute (attribute "role" "menu")
                |> Dom.appendChild
                    (Dom.element "li"
                        |> Dom.addAttribute (attribute "role" "menuitem")
                        |> Dom.addAttribute (tabindex 0)
                        |> Dom.addAction ( "click", ConfirmCreateNew )
                        |> Dom.addClass "section-end"
                        |> Dom.appendText "Create New"
                    )
                |> Dom.appendChild
                    (Dom.element "li"
                        |> Dom.addAttribute (attribute "role" "menuitem")
                        |> Dom.addAttribute (tabindex 0)
                        |> Dom.addAction ( "click", ExportFile )
                        |> Dom.appendText "Export"
                    )
                |> Dom.appendChild
                    (Dom.element "li"
                        |> Dom.addAttribute (attribute "role" "menuitem")
                        |> Dom.addAttribute (tabindex 0)
                        |> Dom.addAction ( "click", LoadFile )
                        |> Dom.addClass "section-end"
                        |> Dom.appendText "Import"
                    )
                |> Dom.appendChild
                    (Dom.element "li"
                        |> Dom.addAttribute (attribute "role" "menuitem")
                        |> Dom.addAttribute (tabindex 0)
                        |> Dom.appendChild
                            (Dom.element "a"
                                |> Dom.addAttribute (href "https://github.com/sponsors/PurpleKingdomGames?o=esb")
                                |> Dom.addAttribute (target "_new")
                                |> Dom.appendText "Donate"
                            )
                    )
            )
        |> Dom.render


getBoardRowHtml : Model -> String -> List ( Int, Int ) -> Int -> List Int -> ( String, Html Msg )
getBoardRowHtml model encodedDraggable cellsForDraggable y row =
    ( "board-row-" ++ String.fromInt y
    , Keyed.node
        "div"
        [ class "row" ]
        (List.indexedMap
            (\x _ ->
                let
                    id =
                        "board-cell-" ++ String.fromInt x ++ "-" ++ String.fromInt y

                    useDraggable =
                        List.any (\c -> c == ( x, y )) cellsForDraggable

                    currentDraggable =
                        if useDraggable then
                            encodedDraggable

                        else
                            ""

                    ( roomRef, turns ) =
                        List.filterMap
                            (\r ->
                                if r.data.origin == ( x, y ) then
                                    Maybe.map (\s -> ( s, r.data.turns )) (refToString r.data.ref)

                                else
                                    Nothing
                            )
                            model.map.roomData
                            |> List.head
                            |> Maybe.withDefault ( "", 0 )
                in
                ( id, lazy8 getCellHtml model.map.overlays emptyList model.map.monsters roomRef turns currentDraggable x y )
            )
            row
        )
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ onContextPosition ChangeContextMenuAbsposition
        , onCellFromPoint CellFromPoint
        , onConfirmCreateNew CreateNew
        ]


getCellHtml : List BoardOverlay -> List Piece -> List ScenarioMonster -> String -> Int -> String -> Int -> Int -> Html Msg
getCellHtml overlays pieces monsters roomOrigin turns encodedDraggable x y =
    let
        currentDraggable =
            case Decode.decodeString decodeMoveablePiece encodedDraggable of
                Ok d ->
                    Just d

                _ ->
                    Nothing

        ref =
            case stringToRef roomOrigin of
                Just r ->
                    r

                Nothing ->
                    Empty

        isDraggingRoom =
            case currentDraggable of
                Just c ->
                    case c.ref of
                        RoomType r ->
                            r.ref == ref

                        _ ->
                            False

                Nothing ->
                    False
    in
    BoardHtml.getCellHtml
        (CellModel overlays pieces monsters ( x, y ) currentDraggable True True True dragEvents dropEvents True False)
        |> Dom.appendChildConditional
            (Dom.element "div"
                |> Dom.addClass "room-origin"
                |> Dom.addClassConditional "dragging" isDraggingRoom
                |> makeDraggable
                    (RoomType { ref = ref, origin = ( x, y ), turns = turns })
                    (Just ( x, y ))
                    dragEvents
            )
            (ref /= Empty)
        |> Dom.addActionStopAndPrevent ( "click", OpenContextMenu ( x, y ) )
        |> Dom.render


getMapTileListHtml : List ExtendedRoomData -> String -> SideMenu -> Html Msg
getMapTileListHtml mapTiles currentDraggable sideMenu =
    let
        currentRefs =
            List.map (\r -> r.data.ref) mapTiles

        htmlClass =
            if sideMenu == MapTileMenu then
                "active"

            else
                ""
    in
    section [ class htmlClass, onClick (ChangeSideMenu MapTileMenu) ]
        [ header [] [ text "Tiles" ]
        , Keyed.node
            "ul"
            [ class "map-tiles"
            ]
            (getAllRefs
                |> List.filter
                    (\r ->
                        r /= J1ba && r /= J1bb && List.member r currentRefs == False
                    )
                |> List.map
                    (\r ->
                        let
                            ref =
                                Maybe.withDefault "" (refToString r)
                        in
                        ( "new-tile-" ++ ref, lazy2 lazyMapTileListHtml ref currentDraggable )
                    )
            )
        ]


getOverlayListHtml : Int -> List String -> String -> String -> Bool -> Html Msg
getOverlayListHtml id overlays label currentDraggable active =
    let
        htmlClass =
            if active then
                "active"

            else
                ""

        menuType =
            case String.toLower label of
                "doors" ->
                    DoorMenu

                "obstacles" ->
                    ObstacleMenu

                _ ->
                    MiscMenu
    in
    section [ class htmlClass, onClick (ChangeSideMenu menuType) ]
        [ header [] [ text label ]
        , Keyed.node "ul"
            [ class "board-overlays"
            ]
            (overlays
                |> List.map
                    (\k ->
                        let
                            isDragging =
                                currentDraggable == k
                        in
                        ( "new-overlay-" ++ k, lazy3 lazyBoardOverlayListHtml id k isDragging )
                    )
            )
        ]


getScenarioMonsterListHtml : Int -> String -> Bool -> Html Msg
getScenarioMonsterListHtml maxId currentDraggable active =
    let
        htmlClass =
            if active then
                "active"

            else
                ""
    in
    section [ class htmlClass, onClick (ChangeSideMenu MonsterMenu) ]
        [ header [] [ text "Monsters" ]
        , Keyed.node "ul"
            [ class "monsters"
            ]
            (getAllMonsters
                |> Dict.toList
                |> List.map
                    (\( k, v ) ->
                        let
                            monster =
                                { isDragging = currentDraggable == k
                                , coords = Nothing
                                , monster =
                                    ScenarioMonster
                                        { monster = NormalType v
                                        , id = maxId
                                        , level = Monster.None
                                        , wasSummoned = False
                                        , outOfPhase = False
                                        }
                                        0
                                        0
                                        Normal
                                        Normal
                                        Normal
                                , dragEvents = dragEvents
                                }

                            ( _, node ) =
                                scenarioMonsterToHtml True monster
                        in
                        ( "new-monster-" ++ k
                        , li []
                            [ node |> Dom.render ]
                        )
                    )
            )
        ]


getScenarioBossListHtml : Int -> String -> Bool -> Html Msg
getScenarioBossListHtml maxId currentDraggable active =
    let
        htmlClass =
            if active then
                "active"

            else
                ""
    in
    section [ class htmlClass, onClick (ChangeSideMenu BossMenu) ]
        [ header [] [ text "Bosses" ]
        , Keyed.node "ul"
            [ class "monsters"
            ]
            (getAllBosses
                |> Dict.toList
                |> List.map
                    (\( k, v ) ->
                        let
                            monster =
                                { isDragging = currentDraggable == k
                                , coords = Nothing
                                , monster =
                                    ScenarioMonster
                                        { monster = BossType v
                                        , id = maxId
                                        , level = Monster.None
                                        , wasSummoned = False
                                        , outOfPhase = False
                                        }
                                        0
                                        0
                                        Normal
                                        Normal
                                        Normal
                                , dragEvents = dragEvents
                                }

                            ( _, node ) =
                                scenarioMonsterToHtml True monster
                        in
                        ( "new-monster-" ++ k
                        , li []
                            [ node |> Dom.render ]
                        )
                    )
            )
        ]


lazyMapTileListHtml : String -> String -> Html Msg
lazyMapTileListHtml ref currentDraggable =
    let
        r =
            Maybe.withDefault Empty (stringToRef ref)
    in
    Dom.element "li"
        |> Dom.addClass ("ref-" ++ ref)
        |> Dom.addClassConditional "dragging" (ref == currentDraggable)
        |> Dom.appendChild
            (Dom.element "img"
                |> Dom.addAttributeList
                    [ src ("/img/map-tiles/" ++ ref ++ ".png")
                    , alt ("Map tile " ++ ref)
                    ]
                |> makeDraggable (RoomType (RoomData r ( 0, 0 ) 0)) Nothing dragEvents
            )
        |> Dom.render


lazyBoardOverlayListHtml : Int -> String -> Bool -> Html Msg
lazyBoardOverlayListHtml id overlayStr isDragging =
    case getBoardOverlayType overlayStr of
        Just overlay ->
            let
                twoCells =
                    [ ( 0, 0 ), ( 1, 0 ) ]

                threeCells =
                    [ ( 0, 0 ), ( 1, 0 ), ( 0, -1 ) ]

                cells =
                    case overlay of
                        DifficultTerrain Log ->
                            twoCells

                        Obstacle Bookcase ->
                            twoCells

                        Obstacle Boulder2 ->
                            twoCells

                        Obstacle Boulder3 ->
                            threeCells

                        Obstacle DarkPit ->
                            twoCells

                        Obstacle Sarcophagus ->
                            twoCells

                        Obstacle Shelf ->
                            twoCells

                        Obstacle Table ->
                            twoCells

                        Obstacle Tree3 ->
                            threeCells

                        Obstacle WallSection ->
                            twoCells

                        Wall HugeRock ->
                            threeCells

                        Wall Iron ->
                            twoCells

                        Wall LargeRock ->
                            twoCells

                        Wall ObsidianGlass ->
                            twoCells

                        _ ->
                            [ ( 0, 0 ) ]

                boardOverlayModel =
                    { ref = overlay
                    , id = id
                    , direction = Default
                    , cells = cells
                    }
            in
            Dom.element "li"
                |> Dom.addClass ("size-" ++ String.fromInt (List.length cells))
                |> Dom.addClassConditional "dragging" isDragging
                |> Dom.appendChildList
                    (List.map
                        (\c ->
                            case overlay of
                                Token val ->
                                    Dom.element "div"
                                        |> Dom.addClass "overlay"
                                        |> Dom.addClass "token"
                                        |> Dom.appendChild
                                            (Dom.element "span"
                                                |> Dom.appendText val
                                            )

                                _ ->
                                    Dom.element "img"
                                        |> Dom.addAttribute (alt (getOverlayLabel overlay))
                                        |> Dom.addAttribute (attribute "src" (getOverlayImageName boardOverlayModel (Just c)))
                                        |> Dom.addAttribute (attribute "draggable" "false")
                        )
                        cells
                    )
                |> makeDraggable (OverlayType boardOverlayModel Nothing) Nothing dragEvents
                |> Dom.render

        Nothing ->
            li [] []


getContextMenu : ContextMenu -> ( Int, Int ) -> ( Int, Int ) -> List ( MapTileRef, Dict ( Int, Int ) ( ( Int, Int ), Bool ) ) -> List BoardOverlay -> List ScenarioMonster -> Html Msg
getContextMenu state ( x, y ) ( absX, absY ) rooms overlays monsters =
    let
        filteredOverlays =
            List.filter (\o -> List.any (\c -> c == ( x, y )) o.cells) overlays

        filteredRoom =
            List.filter
                (\( _, cells ) ->
                    case Dict.get ( x, y ) cells of
                        Just ( _, p ) ->
                            p

                        Nothing ->
                            False
                )
                rooms
                |> List.map (\( r, _ ) -> r)

        monster =
            List.filter (\m -> m.initialX == x && m.initialY == y) monsters
                |> List.head

        menuList =
            if state /= Closed then
                (case monster of
                    Just m ->
                        case m.monster.monster of
                            NormalType _ ->
                                [ getMonsterLevelHtml TwoPlayerSubMenu (state == TwoPlayerSubMenu) m.twoPlayer 2 m.monster.id
                                , getMonsterLevelHtml ThreePlayerSubMenu (state == ThreePlayerSubMenu) m.threePlayer 3 m.monster.id
                                , getMonsterLevelHtml FourPlayerSubMenu (state == FourPlayerSubMenu) m.fourPlayer 4 m.monster.id
                                ]

                            _ ->
                                []

                    Nothing ->
                        []
                )
                    ++ (List.filter
                            (\o ->
                                case o.ref of
                                    StartingLocation ->
                                        False

                                    Rift ->
                                        False

                                    _ ->
                                        True
                            )
                            filteredOverlays
                            |> List.map
                                (\o ->
                                    li
                                        [ class "rotate-overlay"
                                        , onClickPreventDefault (RotateOverlay o.id)
                                        ]
                                        [ text ("Rotate " ++ getOverlayLabel o.ref)
                                        ]
                                )
                       )
                    ++ (filteredRoom
                            |> List.map
                                (\room ->
                                    let
                                        refStr =
                                            Maybe.withDefault "" (refToString room)

                                        firstChar =
                                            String.slice 0 1 refStr
                                                |> String.toUpper

                                        restChars =
                                            String.slice 1 (String.length refStr) refStr
                                    in
                                    li
                                        [ class "rotate-map-tile"
                                        , onClickPreventDefault (RotateRoom room)
                                        ]
                                        [ text ("Rotate " ++ firstChar ++ restChars)
                                        ]
                                )
                       )
                    ++ (case monster of
                            Just m ->
                                let
                                    monsterName =
                                        Maybe.withDefault "" (monsterTypeToString m.monster.monster)
                                            |> String.split "-"
                                            |> List.map
                                                (\s ->
                                                    String.toUpper (String.slice 0 1 s)
                                                        ++ String.slice 1 (String.length s) s
                                                )
                                            |> String.join " "
                                in
                                [ li
                                    [ class "remove-monster"
                                    , onClickPreventDefault (RemoveMonster m.monster.id)
                                    ]
                                    [ text ("Remove " ++ monsterName)
                                    ]
                                ]

                            Nothing ->
                                []
                       )
                    ++ List.map
                        (\o ->
                            li
                                [ class "remove-overlay"
                                , onClickPreventDefault (RemoveOverlay o.id)
                                ]
                                [ text ("Remove " ++ getOverlayLabel o.ref)
                                ]
                        )
                        filteredOverlays
                    ++ (filteredRoom
                            |> List.map
                                (\room ->
                                    let
                                        refStr =
                                            Maybe.withDefault "" (refToString room)

                                        firstChar =
                                            String.slice 0 1 refStr
                                                |> String.toUpper

                                        restChars =
                                            String.slice 1 (String.length refStr) refStr
                                    in
                                    li
                                        [ class "remove-map-tile"
                                        , onClickPreventDefault (RemoveRoom room)
                                        ]
                                        [ text ("Remove " ++ firstChar ++ restChars)
                                        ]
                                )
                       )

            else
                []

        isOpen =
            state /= Closed && List.length menuList > 0
    in
    div
        [ class "context-menu"
        , class
            (if isOpen then
                "open"

             else
                ""
            )
        , class
            (if state /= Open then
                "sub-menu-open"

             else
                ""
            )
        , style "top" (String.fromInt absY ++ "px")
        , style "left" (String.fromInt absX ++ "px")
        ]
        [ nav []
            [ ul []
                (if isOpen then
                    menuList
                        ++ [ li
                                [ class "cancel-menu cancel"
                                , onClickPreventDefault (ChangeContextMenuState Closed)
                                ]
                                [ text "Cancel"
                                ]
                           ]

                 else
                    []
                )
            ]
        ]


mapPieceToScenarioMonster : Piece -> List ScenarioMonster -> Maybe ( Int, Int ) -> ( Int, Int ) -> Piece -> Maybe ScenarioMonster
mapPieceToScenarioMonster newPiece monsterList origin ( targetX, targetY ) piece =
    case ( piece.ref, piece.x, piece.y ) of
        ( AI (Enemy monster), x, y ) ->
            if piece == newPiece then
                let
                    existingMonster =
                        Maybe.withDefault
                            (ScenarioMonster monster 0 0 Normal Normal Normal)
                            (List.filter (\m -> Just ( m.initialX, m.initialY ) == origin) monsterList
                                |> List.head
                            )
                in
                Just { existingMonster | initialX = targetX, initialY = targetY }

            else
                List.filter (\m -> m.initialX == x && m.initialY == y) monsterList
                    |> List.head

        _ ->
            Nothing


getMonsterLevelHtml : ContextMenu -> Bool -> MonsterLevel -> Int -> Int -> Html Msg
getMonsterLevelHtml stateChange isOpen selectedLevel playerSize id =
    li
        [ class "edit-monster has-sub-menu"
        , onClickPreventDefault (ChangeContextMenuState stateChange)
        ]
        [ span [] [ text (String.fromInt playerSize ++ " Player State") ]
        , ul
            [ class
                (if isOpen then
                    "open"

                 else
                    ""
                )
            ]
            [ li
                [ class "monster-none"
                , class
                    (if selectedLevel == Monster.None then
                        "selected"

                     else
                        ""
                    )
                , onClickPreventDefault (ChangeMonsterState id playerSize Monster.None)
                ]
                [ text "None" ]
            , li
                [ class "monster-normal"
                , class
                    (if selectedLevel == Monster.Normal then
                        "selected"

                     else
                        ""
                    )
                , onClickPreventDefault (ChangeMonsterState id playerSize Monster.Normal)
                ]
                [ text "Normal" ]
            , li
                [ class "monster-elite"
                , class
                    (if selectedLevel == Monster.Elite then
                        "selected"

                     else
                        ""
                    )
                , onClickPreventDefault (ChangeMonsterState id playerSize Monster.Elite)
                ]
                [ text "Elite" ]
            , li
                [ class "cancel cancel-menu"
                , onClickPreventDefault (ChangeContextMenuState Open)
                ]
                [ text "Cancel" ]
            ]
        ]


calculateRoomCells : RoomData -> ( ( MapTileRef, Dict ( Int, Int ) ( ( Int, Int ), Bool ) ), ( Int, Int ) )
calculateRoomCells room =
    let
        cells =
            getGridByRef room.ref
                |> Array.indexedMap
                    (\y c ->
                        Array.indexedMap
                            (\x p ->
                                let
                                    cellLoc =
                                        case room.origin of
                                            ( originX, originY ) ->
                                                let
                                                    newX =
                                                        if modBy 2 originY == 1 && modBy 2 y == 1 then
                                                            x + 1

                                                        else
                                                            x
                                                in
                                                normaliseAndRotatePoint room.turns room.origin room.origin ( newX + originX, y + originY )
                                in
                                ( cellLoc, ( ( x, y ), p ) )
                            )
                            c
                    )
                |> Array.foldr (\a b -> Array.toList a ++ b) []
                |> Dict.fromList

        ( deltaX, deltaY ) =
            Dict.keys cells
                |> List.foldr
                    (\( x, y ) ( ( minX, maxX ), ( minY, maxY ) ) ->
                        ( ( min x minX, max x maxX ), ( min y minY, max y maxY ) )
                    )
                    ( ( 0, 0 ), ( 0, 0 ) )
                |> (\( ( minX, maxX ), ( minY, maxY ) ) ->
                        let
                            newX =
                                if minX < 0 then
                                    -minX

                                else if maxX >= gridSize then
                                    (gridSize - 1) - maxX

                                else
                                    0

                            newY =
                                if minY < 0 then
                                    -minY

                                else if maxY >= gridSize then
                                    (gridSize - 1) - maxY

                                else
                                    0
                        in
                        ( newX, newY )
                   )

        newCells =
            if deltaX == 0 && deltaY == 0 then
                cells

            else
                Dict.toList cells
                    |> List.map
                        (\( ( x, y ), v ) ->
                            let
                                x1 =
                                    if modBy 2 y == 0 && modBy 2 (y + deltaY) == 1 then
                                        x - 1

                                    else
                                        x
                            in
                            ( ( x1 + deltaX, y + deltaY ), v )
                        )
                    |> Dict.fromList
    in
    ( ( room.ref, newCells )
    , case room.origin of
        ( x, y ) ->
            ( x + deltaX, y + deltaY )
    )


defaultExtendedRoomData : MapTileRef -> ExtendedRoomData
defaultExtendedRoomData ref =
    let
        rotationPoint =
            getGridByRef ref
                |> Array.map (\row -> Array.length row)
                |> (\arr -> ( Array.length arr, Array.foldr (\a b -> max a b) 0 arr ))
                |> (\( y, x ) ->
                        ( x // 2, y // 2 )
                   )
    in
    { data = RoomData ref ( 0, 0 ) 0
    , rotationPoint = rotationPoint
    }


moveRoom : ( Int, Int ) -> ExtendedRoomData -> ( ( MapTileRef, Dict ( Int, Int ) ( ( Int, Int ), Bool ) ), ExtendedRoomData )
moveRoom target room =
    let
        roomData =
            room.data

        ( cells, newOrigin ) =
            calculateRoomCells { roomData | origin = target }

        ( deltaX, deltaY ) =
            case ( newOrigin, target ) of
                ( ( oX, oY ), ( tX, tY ) ) ->
                    let
                        ( dX, dY ) =
                            ( tX - oX, tY - oY )
                    in
                    ( Tuple.first target - Tuple.first room.data.origin - dX
                    , Tuple.second target - Tuple.second room.data.origin - dY
                    )
    in
    ( cells
    , { room
        | data = { roomData | origin = newOrigin }
        , rotationPoint = ( Tuple.first room.rotationPoint + deltaX, Tuple.second room.rotationPoint + deltaY )
      }
    )


rotateRoom : Int -> ExtendedRoomData -> ( ( MapTileRef, Dict ( Int, Int ) ( ( Int, Int ), Bool ) ), ExtendedRoomData )
rotateRoom i extRoom =
    List.range 1 i
        |> List.foldr
            (\_ ( _, room ) ->
                let
                    turns =
                        if room.data.turns == 5 then
                            0

                        else
                            room.data.turns + 1

                    origin =
                        rotate room.data.origin room.rotationPoint 1

                    tmpRoom =
                        room.data

                    newRoom =
                        { tmpRoom | turns = turns, origin = origin }

                    ( cells, newOrigin ) =
                        calculateRoomCells { tmpRoom | turns = turns, origin = origin }

                    newRotationPoint =
                        case ( origin, newOrigin ) of
                            ( ( oX, oY ), ( tX, tY ) ) ->
                                let
                                    ( dX, dY ) =
                                        ( tX - oX, tY - oY )
                                in
                                ( Tuple.first room.rotationPoint + dX, Tuple.second room.rotationPoint + dY )
                in
                ( cells
                , { room
                    | data = { newRoom | origin = newOrigin }
                    , rotationPoint = newRotationPoint
                  }
                )
            )
            ( ( Empty, Dict.empty ), extRoom )


generateScenario : String -> List RoomData -> List ( MapTileRef, BoardOverlay ) -> List ( MapTileRef, ScenarioMonster ) -> List ( MapTileRef, Dict ( Int, Int ) ( ( Int, Int ), Bool ) ) -> Result String Scenario
generateScenario title rooms overlays monsters roomCellMap =
    case List.head rooms of
        Just _ ->
            let
                doors =
                    List.filterMap
                        (\( _, o ) ->
                            case o.ref of
                                Door _ _ ->
                                    Just o

                                _ ->
                                    Nothing
                        )
                        overlays

                overlaysWithoutDoors =
                    List.filter
                        (\( _, o ) ->
                            case o.ref of
                                Door _ _ ->
                                    False

                                _ ->
                                    True
                        )
                        overlays

                mapTileModel =
                    generateMapTileData rooms doors overlaysWithoutDoors monsters roomCellMap
            in
            case mapTileModel of
                Ok exportableMap ->
                    Ok (Scenario 0 title exportableMap 0 [])

                Err e ->
                    Err e

        Nothing ->
            Err "No map tile data could be found"


generateMapTileData : List RoomData -> List BoardOverlay -> List ( MapTileRef, BoardOverlay ) -> List ( MapTileRef, ScenarioMonster ) -> List ( MapTileRef, Dict ( Int, Int ) ( ( Int, Int ), Bool ) ) -> Result String MapTileData
generateMapTileData roomDataList doors overlays monsters roomCellMap =
    let
        rooms =
            List.map (assignMapTileData overlays monsters) roomDataList
                |> List.sortBy
                    (\m ->
                        let
                            numDoors =
                                doors
                                    |> List.filter
                                        (\d ->
                                            case d.ref of
                                                Door _ connections ->
                                                    List.any (\c -> c == m.ref) connections

                                                _ ->
                                                    False
                                        )
                                    |> List.length

                            startingLocations =
                                List.filter (\o -> o.ref == StartingLocation) m.overlays
                                    |> List.length
                        in
                        numDoors + startingLocations
                    )
                |> List.reverse
    in
    case rooms of
        firstRoom :: rest ->
            let
                doorsForThisTile =
                    List.filter
                        (\o ->
                            case o.ref of
                                Door _ connections ->
                                    List.any (\c -> c == firstRoom.ref) connections

                                _ ->
                                    False
                        )
                        doors

                remainingDoors =
                    List.filter
                        (\o ->
                            case o.ref of
                                Door _ connections ->
                                    not (List.any (\c -> c == firstRoom.ref) connections)

                                _ ->
                                    False
                        )
                        doors

                ( mapTileData, _, _ ) =
                    assignDoorData firstRoom rest rooms doorsForThisTile remainingDoors roomCellMap
            in
            Ok mapTileData

        _ ->
            Err "No rooms have been added"


assignMapTileData : List ( MapTileRef, BoardOverlay ) -> List ( MapTileRef, ScenarioMonster ) -> RoomData -> MapTileData
assignMapTileData overlays monsters roomData =
    let
        monsterData =
            List.filter (\( ref, _ ) -> ref == roomData.ref) monsters
                |> List.map (\( _, m ) -> m)

        overlayData =
            List.filter (\( ref, _ ) -> ref == roomData.ref) overlays
                |> List.map (\( _, o ) -> o)
    in
    MapTileData
        roomData.ref
        []
        overlayData
        monsterData
        roomData.turns


assignDoorData : MapTileData -> List MapTileData -> List MapTileData -> List BoardOverlay -> List BoardOverlay -> List ( MapTileRef, Dict ( Int, Int ) ( ( Int, Int ), Bool ) ) -> ( MapTileData, List MapTileData, List BoardOverlay )
assignDoorData mapTile otherMapTiles allMapTiles doorsForThisTile doorsForOtherTiles roomCellMap =
    let
        ( remainingDoors, _, doorData ) =
            List.foldl
                (\door ( od, om, dd ) ->
                    case ( List.head door.cells, door.ref ) of
                        ( Just cell, Door subType connections ) ->
                            let
                                maybeConnectingRoom =
                                    List.filter (\r -> r /= mapTile.ref) connections
                                        |> List.head
                                        |> Maybe.andThen
                                            (\r ->
                                                List.filter (\m -> m.ref == r) allMapTiles
                                                    |> List.head
                                            )
                            in
                            case maybeConnectingRoom of
                                Just connectingRoom ->
                                    let
                                        roomCoords =
                                            mapCoordsToRoom mapTile.ref mapTile.turns cell roomCellMap

                                        connectingCoords =
                                            mapCoordsToRoom connectingRoom.ref connectingRoom.turns cell roomCellMap

                                        ( connectingMapTile, om2, od2 ) =
                                            case
                                                List.filter (\m -> m.ref == connectingRoom.ref) om
                                                    |> List.head
                                            of
                                                Just m ->
                                                    let
                                                        connectingDoors =
                                                            List.filter
                                                                (\o ->
                                                                    case o.ref of
                                                                        Door _ c ->
                                                                            List.any (\c1 -> c1 == m.ref) c

                                                                        _ ->
                                                                            False
                                                                )
                                                                od

                                                        nonConnectingDoors =
                                                            List.filter
                                                                (\o ->
                                                                    case o.ref of
                                                                        Door _ c ->
                                                                            not (List.any (\c1 -> c1 == m.ref) c)

                                                                        _ ->
                                                                            False
                                                                )
                                                                od
                                                    in
                                                    assignDoorData m om allMapTiles connectingDoors nonConnectingDoors roomCellMap

                                                Nothing ->
                                                    ( MapTileData connectingRoom.ref [] [] [] connectingRoom.turns, om, od )
                                    in
                                    case ( roomCoords, connectingCoords ) of
                                        ( Just r1, Just r2 ) ->
                                            let
                                                newDoorData =
                                                    DoorLink subType door.direction r1 r2 connectingMapTile
                                            in
                                            ( od2, om2, newDoorData :: dd )

                                        _ ->
                                            ( od, om, dd )

                                Nothing ->
                                    ( od, om, dd )

                        _ ->
                            ( od, om, dd )
                )
                ( doorsForOtherTiles, otherMapTiles, [] )
                doorsForThisTile
    in
    ( { mapTile | doors = doorData }, otherMapTiles, remainingDoors )


mapCoordsToRoom : MapTileRef -> Int -> ( Int, Int ) -> List ( MapTileRef, Dict ( Int, Int ) ( ( Int, Int ), Bool ) ) -> Maybe ( Int, Int )
mapCoordsToRoom ref turns origin roomCellData =
    let
        roomOrigin =
            roomCellData
                |> List.filter (\( r, _ ) -> r == ref)
                |> List.head
                |> Maybe.map
                    (\( _, d ) ->
                        Dict.toList d
                            |> List.filter (\( _, ( o, _ ) ) -> o == ( 0, 0 ))
                    )
                |> Maybe.andThen (\l -> List.head l)
                |> Maybe.andThen (\( k, _ ) -> Just k)
    in
    Maybe.map
        (\o ->
            let
                -- Rotate the cell around the origin
                rotatedCell =
                    rotate origin o (6 - turns)

                y =
                    Tuple.second rotatedCell - Tuple.second o

                x =
                    (Tuple.first rotatedCell - Tuple.first o)
                        |> (+)
                            (if Bitwise.and y 1 == 1 && (Bitwise.and (Tuple.second rotatedCell) 1 == 0) then
                                -1

                             else
                                0
                            )
            in
            -- Get the delta
            ( x, y )
        )
        roomOrigin


initModel : MapData -> Model
initModel mapData =
    let
        ( doors, obstacles, misc ) =
            getOverlayTypesWithLabel
                |> Dict.filter
                    (\_ v ->
                        case v of
                            Door (Corridor _ Two) _ ->
                                False

                            Door AltarDoor _ ->
                                False

                            Door BreakableWall _ ->
                                False

                            Rift ->
                                False

                            Treasure (Coin _) ->
                                False

                            _ ->
                                True
                    )
                |> Dict.toList
                |> List.sortBy
                    (\( _, v ) ->
                        case v of
                            StartingLocation ->
                                0

                            Token _ ->
                                2

                            _ ->
                                1
                    )
                |> List.foldr
                    (\( k, v ) ( d, o, m ) ->
                        case v of
                            Door _ _ ->
                                ( k :: d, o, m )

                            Obstacle _ ->
                                ( d, k :: o, m )

                            _ ->
                                ( d, o, k :: m )
                    )
                    ( [], [], [] )

        cachedRoomData =
            List.map
                (\r ->
                    case calculateRoomCells r.data of
                        ( d, _ ) ->
                            d
                )
                mapData.roomData
    in
    Model
        mapData
        Nothing
        False
        MapTileMenu
        Closed
        ( 0, 0 )
        ( 0, 0 )
        doors
        obstacles
        misc
        cachedRoomData
        ""
        False
