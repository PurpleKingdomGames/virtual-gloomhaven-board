port module Creator exposing (main)

import AppStorage exposing (MoveablePiece, MoveablePieceType(..), decodeMoveablePiece, encodeMoveablePiece)
import Array exposing (Array)
import BoardHtml exposing (CellModel, DragEvents, DropEvents, getAllMapTileHtml, getFooterHtml, getOverlayImageName, makeDraggable, scenarioMonsterToHtml)
import BoardMapTile exposing (MapTile, MapTileRef(..), getAllRefs, getGridByRef, getMapTileListByRef, refToString, stringToRef)
import BoardOverlay exposing (BoardOverlay, BoardOverlayDirectionType(..), BoardOverlayType(..), CorridorSize(..), DifficultTerrainSubType(..), DoorSubType(..), ObstacleSubType(..), TreasureSubType(..), WallSubType(..), getAllOverlayTypes, getBoardOverlayName, getBoardOverlayType, getOverlayLabel, getOverlayTypesWithLabel)
import Browser
import Char exposing (toLocaleUpper)
import Dict
import Dom
import DragPorts
import Game exposing (AIType(..), Piece, PieceType(..), RoomData, assignIdentifier, moveOverlay, moveOverlayWithoutState, movePiece, movePieceWithoutState)
import Hexagon exposing (rotate)
import Html exposing (Html, div, header, img, input, li, nav, section, span, text, ul)
import Html.Attributes exposing (alt, attribute, class, coords, href, id, src, tabindex, target, type_)
import Html.Events exposing (onClick)
import Html.Events.Extra.Drag as DragDrop
import Html.Events.Extra.Touch as Touch
import Html.Keyed as Keyed
import Html.Lazy exposing (lazy, lazy2, lazy3, lazy4, lazy5, lazy6, lazy7)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import List
import Maybe
import Monster exposing (MonsterLevel(..), MonsterType(..), NormalMonsterType, getAllBosses, getAllMonsters, monsterTypeToString)
import Scenario exposing (ScenarioMonster, normaliseAndRotateMapTile)
import Version


port getCellFromPoint : ( Float, Float, Bool ) -> Cmd msg


port onCellFromPoint : (( Int, Int, Bool ) -> msg) -> Sub msg


type alias Model =
    { scenarioTitle : String
    , roomData : List RoomData
    , overlays : List BoardOverlay
    , monsters : List ScenarioMonster
    , currentDraggable : Maybe MoveablePiece
    , menuOpen : Bool
    , sideMenu : SideMenu
    , contextMenuState : ContextMenu
    , contextMenuPosition : ( Int, Int )
    , cachedDoors : List String
    , cachedObstacles : List String
    , cachedMisc : List String
    , cachedRoomCells : List ( MapTileRef, List MapTile )
    }


type SideMenu
    = MapTileMenu
    | DoorMenu
    | ObstacleMenu
    | MiscMenu
    | MonsterMenu
    | BossMenu


type ContextMenu
    = Open
    | Closed
    | TwoPlayerSubMenu
    | ThreePlayerSubMenu
    | FourPlayerSubMenu


type Msg
    = MoveStarted MoveablePiece (Maybe ( DragDrop.EffectAllowed, Decode.Value ))
    | MoveTargetChanged ( Int, Int ) (Maybe ( DragDrop.DropEffect, Decode.Value ))
    | MoveCanceled
    | MoveCompleted
    | TouchStart MoveablePiece
    | TouchMove ( Float, Float )
    | TouchCanceled
    | TouchEnd ( Float, Float )
    | ChangeSideMenu SideMenu
    | OpenContextMenu ( Int, Int )
    | ChangeContextMenuState ContextMenu
    | ChangeMonsterState Int Int MonsterLevel
    | RemoveMonster Int
    | RotateOverlay Int
    | RemoveOverlay Int
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


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : () -> ( Model, Cmd Msg )
init _ =
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
    in
    ( Model "" [] [] [] Nothing False MapTileMenu Closed ( 0, 0 ) doors obstacles misc []
    , Cmd.none
    )


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
            ( { model | currentDraggable = Just piece }, cmd )

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
                                                moveOverlayWithoutState o m.coords prevCoords coords model.overlays

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
                                                model.monsters
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
                ( overlays, monsters, rooms ) =
                    case model.currentDraggable of
                        Just m ->
                            case ( m.ref, m.target ) of
                                ( OverlayType o prevCoords, Just coords ) ->
                                    let
                                        ( g, newOverlay, _ ) =
                                            moveOverlayWithoutState o m.coords prevCoords coords model.overlays
                                    in
                                    ( newOverlay :: g, model.monsters, model.roomData )

                                ( PieceType p, Just target ) ->
                                    case p.ref of
                                        AI (Enemy _) ->
                                            let
                                                pieces =
                                                    model.monsters
                                                        |> List.map (\m1 -> Piece (AI (Enemy m1.monster)) m1.initialX m1.initialY)

                                                ( newPieces, newPiece ) =
                                                    movePieceWithoutState p m.coords target pieces

                                                m2 =
                                                    List.filterMap (mapPieceToScenarioMonster newPiece model.monsters m.coords target) newPieces
                                            in
                                            ( model.overlays, m2, model.roomData )

                                        _ ->
                                            ( model.overlays, model.monsters, model.roomData )

                                ( RoomType r, Just target ) ->
                                    let
                                        room =
                                            Maybe.withDefault
                                                (RoomData r.ref ( 0, 0 ) 0)
                                                (List.filter (\d -> d.ref == r.ref) model.roomData
                                                    |> List.head
                                                )

                                        roomData =
                                            { room | origin = target } :: List.filter (\d -> d.ref /= r.ref) model.roomData
                                    in
                                    ( model.overlays, model.monsters, roomData )

                                ( _, Nothing ) ->
                                    ( model.overlays, model.monsters, model.roomData )

                        Nothing ->
                            ( model.overlays, model.monsters, model.roomData )
            in
            ( { model | currentDraggable = Nothing, overlays = overlays, monsters = monsters, roomData = rooms, cachedRoomCells = calculateRoomCells rooms }, Cmd.none )

        TouchStart piece ->
            update (MoveStarted piece Nothing) model

        TouchCanceled ->
            update MoveCanceled model

        TouchMove ( x, y ) ->
            ( model, getCellFromPoint ( x, y, False ) )

        TouchEnd ( x, y ) ->
            ( model, getCellFromPoint ( x, y, True ) )

        ChangeSideMenu menu ->
            ( { model | sideMenu = menu }, Cmd.none )

        OpenContextMenu pos ->
            ( { model | contextMenuState = Open, contextMenuPosition = pos }, Cmd.none )

        ChangeContextMenuState state ->
            ( { model | contextMenuState = state }, Cmd.none )

        ChangeMonsterState id playerSize level ->
            let
                monster =
                    List.filter (\m1 -> m1.monster.id == id) model.monsters
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
                                :: List.filter (\m1 -> m1.monster.id /= id) model.monsters
                    in
                    ( { model | monsters = newMonsterList, contextMenuState = Open }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        RemoveMonster id ->
            ( { model | monsters = List.filter (\m -> m.monster.id /= id) model.monsters }, Cmd.none )

        RotateOverlay id ->
            let
                o1 =
                    List.filter (\o -> o.id == id) model.overlays
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
                                :: List.filter (\o2 -> o2.id /= id) model.overlays
                    in
                    ( { model | overlays = overlayList }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        RemoveOverlay id ->
            ( { model | overlays = List.filter (\o -> o.id /= id) model.overlays }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


view : Model -> Html.Html Msg
view model =
    div
        [ class "content scenario-creator"
        , id "content"
        , Touch.onCancel (\_ -> TouchCanceled)
        ]
        [ getHeaderHtml model
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
                            + (List.map (\m -> m.monster.id) model.monsters
                                |> List.maximum
                                |> Maybe.withDefault 0
                              )

                    overlayId =
                        1
                            + (List.map (\o -> o.id) model.overlays
                                |> List.maximum
                                |> Maybe.withDefault 0
                              )
                 in
                 [ ( "map-tile-list", lazy3 getMapTileListHtml model.roomData roomDragabble model.sideMenu )
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
                , div
                    [ class "mapTiles" ]
                    [ let
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
                      lazy4 getAllMapTileHtml model.roomData c x y
                    ]
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
                                                            model.overlays
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
                ]
            ]
        , lazy getFooterHtml Version.get
        , lazy5 getContextMenu model.contextMenuState model.contextMenuPosition model.cachedRoomCells model.overlays model.monsters
        ]


getHeaderHtml : Model -> Html.Html Msg
getHeaderHtml model =
    div
        [ class "header" ]
        [ getMenuToggleHtml model
        , lazy getScenarioTitleHtml model.scenarioTitle
        ]


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

        -- , onClick ToggleMenu
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
            [ input [ type_ "text" ] []
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
                in
                ( id, lazy6 getCellHtml model.overlays emptyList model.monsters currentDraggable x y )
            )
            row
        )
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch []


getCellHtml : List BoardOverlay -> List Piece -> List ScenarioMonster -> String -> Int -> Int -> Html Msg
getCellHtml overlays pieces monsters encodedDraggable x y =
    let
        currentDraggable =
            case Decode.decodeString decodeMoveablePiece encodedDraggable of
                Ok d ->
                    Just d

                _ ->
                    Nothing
    in
    BoardHtml.getCellHtml
        (CellModel overlays pieces monsters ( x, y ) currentDraggable True True True dragEvents dropEvents True False)
        |> Dom.addActionStopAndPrevent ( "click", OpenContextMenu ( x, y ) )
        |> Dom.render


getMapTileListHtml : List RoomData -> String -> SideMenu -> Html Msg
getMapTileListHtml mapTiles currentDraggable sideMenu =
    let
        currentRefs =
            List.map (\r -> r.ref) mapTiles

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


getContextMenu : ContextMenu -> ( Int, Int ) -> List ( MapTileRef, List MapTile ) -> List BoardOverlay -> List ScenarioMonster -> Html Msg
getContextMenu state ( x, y ) rooms overlays monsters =
    let
        filteredOverlays =
            List.filter (\o -> List.any (\c -> c == ( x, y )) o.cells) overlays

        filteredRoom =
            List.filter
                (\( _, cells ) -> List.any (\c -> c.x == x && c.y == y) cells)
                rooms

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
                                        , onClick (RotateOverlay o.id)
                                        ]
                                        [ text ("Rotate " ++ getOverlayLabel o.ref)
                                        ]
                                )
                       )
                    ++ (filteredRoom
                            |> List.map
                                (\( room, _ ) ->
                                    let
                                        refStr =
                                            Maybe.withDefault "" (refToString room)

                                        firstChar =
                                            String.slice 0 1 refStr
                                                |> String.toUpper

                                        restChars =
                                            String.slice 1 (String.length refStr) refStr
                                    in
                                    li [ class "rotate-map-tile" ]
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
                                    , onClick (RemoveMonster m.monster.id)
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
                                , onClick (RemoveOverlay o.id)
                                ]
                                [ text ("Remove " ++ getOverlayLabel o.ref)
                                ]
                        )
                        filteredOverlays
                    ++ (filteredRoom
                            |> List.map
                                (\( room, _ ) ->
                                    let
                                        refStr =
                                            Maybe.withDefault "" (refToString room)

                                        firstChar =
                                            String.slice 0 1 refStr
                                                |> String.toUpper

                                        restChars =
                                            String.slice 1 (String.length refStr) refStr
                                    in
                                    li [ class "remove-map-tile" ]
                                        [ text ("Remove " ++ firstChar ++ restChars)
                                        ]
                                )
                       )
                    ++ [ li
                            [ class "cancel-menu"
                            , onClick (ChangeContextMenuState Closed)
                            ]
                            [ text "Cancel"
                            ]
                       ]

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
        ]
        [ nav []
            [ ul []
                menuList
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
getMonsterLevelHtml stateChange active selectedLevel playerSize id =
    li
        [ class "edit-monster"
        , class
            (if active then
                "active"

             else
                ""
            )
        , onClick (ChangeContextMenuState stateChange)
        ]
        [ span [] [ text (String.fromInt playerSize ++ " Player State") ]
        , ul []
            [ li
                [ class "monster-none"
                , class
                    (if selectedLevel == Monster.None then
                        "selected"

                     else
                        ""
                    )
                , onClick (ChangeMonsterState id playerSize Monster.None)
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
                , onClick (ChangeMonsterState id playerSize Monster.Normal)
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
                , onClick (ChangeMonsterState id playerSize Monster.Elite)
                ]
                [ text "Elite" ]
            , li
                [ class "monster-cancel"
                , onClick (ChangeContextMenuState Open)
                ]
                [ text "Cancel" ]
            ]
        ]


calculateRoomCells : List RoomData -> List ( MapTileRef, List MapTile )
calculateRoomCells rooms =
    rooms
        |> List.map
            (\r ->
                let
                    cells =
                        getMapTileListByRef r.ref

                    refPoint =
                        ( 0, 0 )
                in
                ( r.ref
                , List.map
                    (\c ->
                        normaliseAndRotateMapTile r.turns refPoint ( c.x, c.y ) c
                    )
                    cells
                )
            )
