port module Creator exposing (main)

import AppStorage exposing (MoveablePiece, MoveablePieceType(..), decodeMoveablePiece, encodeMoveablePiece)
import BoardHtml exposing (CellModel, DragEvents, DropEvents, getAllMapTileHtml, getFooterHtml, getOverlayImageName, makeDraggable)
import BoardMapTile exposing (MapTileRef(..), getAllRefs, refToString, stringToRef)
import BoardOverlay exposing (BoardOverlay, BoardOverlayDirectionType(..), BoardOverlayType(..), CorridorSize(..), DifficultTerrainSubType(..), DoorSubType(..), ObstacleSubType(..), TreasureSubType(..), WallSubType(..), getAllOverlayTypes, getBoardOverlayName, getBoardOverlayType, getOverlayLabel, getOverlayTypesWithLabel)
import Browser
import Char exposing (toLocaleUpper)
import Dict
import Dom
import DragPorts
import Game exposing (AIType(..), Piece, PieceType(..), RoomData, assignIdentifier, moveOverlay, moveOverlayWithoutState, movePiece, movePieceWithoutState)
import Html exposing (Html, div, header, img, input, li, section, span, text, ul)
import Html.Attributes exposing (alt, attribute, class, coords, href, id, src, tabindex, target, type_)
import Html.Events exposing (onClick)
import Html.Events.Extra.Drag as DragDrop
import Html.Events.Extra.Touch as Touch
import Html.Keyed as Keyed
import Html.Lazy exposing (lazy, lazy2, lazy3, lazy4, lazy6)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import List
import Maybe
import Monster exposing (MonsterLevel(..))
import Scenario exposing (ScenarioMonster)
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
    , cachedDoors : List String
    , cachedObstacles : List String
    , cachedMisc : List String
    }


type SideMenu
    = MapTileMenu
    | DoorMenu
    | ObstacleMenu
    | MiscMenu
    | ScenarioMenu


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
    ( Model "" [] [] [] Nothing False MapTileMenu doors obstacles misc
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
            let
                newDraggable =
                    case model.currentDraggable of
                        Just m ->
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

                        Nothing ->
                            model.currentDraggable

                cmd =
                    case maybeDragOver of
                        Just ( e, v ) ->
                            DragPorts.dragover (DragDrop.overPortData e v)

                        Nothing ->
                            Cmd.none
            in
            ( { model | currentDraggable = newDraggable }, cmd )

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
                                        AI (Enemy monster) ->
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
            ( { model | currentDraggable = Nothing, overlays = overlays, monsters = monsters, roomData = rooms }, Cmd.none )

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
                 in
                 [ ( "map-tile-list", lazy3 getMapTileListHtml model.roomData roomDragabble model.sideMenu )
                 , ( "board-door-list", lazy4 getOverlayListHtml model.cachedDoors "Doors" overlayDragabble (model.sideMenu == DoorMenu) )
                 , ( "board-obstacle-list", lazy4 getOverlayListHtml model.cachedObstacles "Obstacles" overlayDragabble (model.sideMenu == ObstacleMenu) )
                 , ( "board-misc-list", lazy4 getOverlayListHtml model.cachedMisc "Misc." overlayDragabble (model.sideMenu == MiscMenu) )
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
                     in
                     List.repeat gridSize (List.repeat gridSize 0)
                        |> List.indexedMap
                            (getBoardRowHtml model encodedDraggable)
                    )
                ]
            ]
        , lazy getFooterHtml Version.get
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


getBoardRowHtml : Model -> String -> Int -> List Int -> ( String, Html Msg )
getBoardRowHtml model encodedDraggable y row =
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
                        case model.currentDraggable of
                            Just m ->
                                case m.ref of
                                    PieceType p ->
                                        (p.x == x && p.y == y) || (m.coords == Just ( x, y ))

                                    OverlayType o _ ->
                                        case m.target of
                                            Just _ ->
                                                List.any (\c -> c == ( x, y )) o.cells

                                            Nothing ->
                                                False

                                    RoomType r ->
                                        r.origin == ( x, y ) || (m.coords == Just ( x, y ))

                            Nothing ->
                                False

                    currentDraggable =
                        if useDraggable then
                            encodedDraggable

                        else
                            ""
                in
                ( id, lazy6 getCellHtml model.roomData model.overlays model.monsters currentDraggable x y )
            )
            row
        )
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch []


getCellHtml : List RoomData -> List BoardOverlay -> List ScenarioMonster -> String -> Int -> Int -> Html Msg
getCellHtml rooms overlays monsters encodedDraggable x y =
    let
        currentDraggable =
            case Decode.decodeString decodeMoveablePiece encodedDraggable of
                Ok d ->
                    Just d

                _ ->
                    Nothing
    in
    BoardHtml.getCellHtml
        (CellModel overlays [] monsters ( x, y ) currentDraggable True False dragEvents dropEvents True False)
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


getOverlayListHtml : List String -> String -> String -> Bool -> Html Msg
getOverlayListHtml overlays label currentDraggable active =
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
                        ( "new-overlay-" ++ k, lazy2 lazyBoardOverlayListHtml k isDragging )
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


lazyBoardOverlayListHtml : String -> Bool -> Html Msg
lazyBoardOverlayListHtml overlayStr isDragging =
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
                    , id = 0
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
