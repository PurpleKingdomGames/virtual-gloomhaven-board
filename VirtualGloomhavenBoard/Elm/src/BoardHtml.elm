module BoardHtml exposing (CellModel, ContextMenu, DragEvents, DropEvents, getAllMapTileHtml, getCellHtml, getFooterHtml, getMapTileHtml, getOverlayImageName, makeDraggable, makeDroppable, scenarioMonsterToHtml)

import AppStorage exposing (GameModeType(..), MoveablePiece, MoveablePieceType(..))
import Array exposing (fromList, toIndexedList)
import Bitwise
import BoardMapTile exposing (MapTileRef(..), refToString, stringToRef)
import BoardOverlay exposing (BoardOverlay, BoardOverlayDirectionType(..), BoardOverlayType(..), ChestType(..), DoorSubType(..), ObstacleSubType(..), TreasureSubType(..), getBoardOverlayName, getOverlayLabel)
import Character exposing (characterToString)
import Dom exposing (Element)
import Game exposing (AIType(..), Piece, PieceType(..), RoomData, SummonsType(..), getPieceName, getPieceType)
import Html exposing (a, div, footer, iframe, img, span, text)
import Html.Attributes exposing (alt, attribute, class, href, src, style, target, title)
import Html.Events.Extra.Drag as DragDrop
import Html.Events.Extra.Touch as Touch
import Html.Keyed as Keyed
import Html.Lazy exposing (lazy5)
import Json.Decode as Decode
import List exposing (any, map)
import List.Extra exposing (uniqueBy)
import Monster exposing (Monster, MonsterLevel(..), MonsterType(..), monsterTypeToString)
import Scenario exposing (ScenarioMonster)


type ContextMenu
    = Open
    | Closed
    | TwoPlayerSubMenu
    | ThreePlayerSubMenu
    | FourPlayerSubMenu


type alias CellModel msg =
    { overlays : List BoardOverlay
    , pieces : List Piece
    , scenarioMonsters : List ScenarioMonster
    , coords : ( Int, Int )
    , currentDraggable : Maybe MoveablePiece
    , dragOverlays : Bool
    , dragPieces : Bool
    , dragDoors : Bool
    , dragEvents : DragEvents msg
    , dropEvents : DropEvents msg
    , passable : Bool
    , hidden : Bool
    }


type alias BoardOverlayModel msg =
    { isDragging : Bool
    , coords : Maybe ( Int, Int )
    , overlay : BoardOverlay
    , dragEvents : DragEvents msg
    }


type alias PieceModel msg =
    { isDragging : Bool
    , coords : Maybe ( Int, Int )
    , piece : Piece
    , dragEvents : DragEvents msg
    }


type alias ScenarioMonsterModel msg =
    { isDragging : Bool
    , coords : Maybe ( Int, Int )
    , monster : ScenarioMonster
    , dragEvents : DragEvents msg
    }


type alias DragEvents msg =
    { moveStart : MoveablePiece -> Maybe ( DragDrop.EffectAllowed, Decode.Value ) -> msg
    , moveCancel : msg
    , touchStart : MoveablePiece -> msg
    , touchMove : ( Float, Float ) -> msg
    , touchEnd : ( Float, Float ) -> msg
    , noOp : msg
    }


type alias DropEvents msg =
    { moveTargetChanged : ( Int, Int ) -> Maybe ( DragDrop.DropEffect, Decode.Value ) -> msg
    , moveCompleted : msg
    }


getMapTileHtml : List MapTileRef -> List RoomData -> String -> Int -> Int -> Html.Html msg
getMapTileHtml visibleRooms roomData currentDraggable draggableX draggableY =
    Keyed.node "div"
        [ class "mapTiles" ]
        (map
            (\r ->
                let
                    isVisible =
                        List.member r.ref visibleRooms

                    ref =
                        Maybe.withDefault "" (refToString r.ref)

                    ( x, y ) =
                        if ref == currentDraggable then
                            ( draggableX, draggableY )

                        else
                            r.origin
                in
                ( ref, lazy5 getSingleMapTileHtml isVisible ref r.turns x y )
            )
            (uniqueBy (\d -> Maybe.withDefault "" (refToString d.ref)) roomData)
        )


getAllMapTileHtml : List RoomData -> String -> Int -> Int -> Html.Html msg
getAllMapTileHtml roomData currentDraggable draggableX draggableY =
    let
        allRooms =
            if List.member currentDraggable (List.map (\r -> Maybe.withDefault "" (refToString r.ref)) roomData) then
                roomData

            else
                case stringToRef currentDraggable of
                    Just r ->
                        RoomData r ( draggableX, draggableY ) 0 :: roomData

                    Nothing ->
                        roomData
    in
    getMapTileHtml (map (\d -> d.ref) allRooms) allRooms currentDraggable draggableX draggableY


getSingleMapTileHtml : Bool -> String -> Int -> Int -> Int -> Html.Html msg
getSingleMapTileHtml isVisible ref turns x y =
    let
        xPx =
            (x * 76)
                + (if Bitwise.and y 1 == 1 then
                    38

                   else
                    0
                  )

        yPx =
            y * 67
    in
    div
        []
        [ div
            [ class "mapTile"
            , class ("rotate-" ++ String.fromInt turns)
            , class
                (if isVisible then
                    "visible"

                 else
                    "hidden"
                )
            , style "top" (String.fromInt yPx ++ "px")
            , style "left" (String.fromInt xPx ++ "px")
            ]
            [ img
                [ src ("/img/map-tiles/" ++ ref ++ ".png")
                , class ("ref-" ++ ref)
                , alt ("Map tile " ++ ref)
                , attribute "aria-hidden"
                    (if isVisible then
                        "false"

                     else
                        "true"
                    )
                ]
                []
            ]
        , div
            [ class "mapTile outline"
            , class ("rotate-" ++ String.fromInt turns)
            , class
                (if isVisible then
                    "hidden"

                 else
                    "visible"
                )
            , style "top" (String.fromInt yPx ++ "px")
            , style "left" (String.fromInt xPx ++ "px")
            , attribute "aria-hidden"
                (if isVisible then
                    "true"

                 else
                    "false"
                )
            ]
            (case stringToRef ref of
                Nothing ->
                    []

                Just Empty ->
                    []

                Just r ->
                    let
                        overlayPrefix =
                            case r of
                                J1a ->
                                    "ja"

                                J2a ->
                                    "ja"

                                J1b ->
                                    "jb"

                                J1ba ->
                                    "jb"

                                J1bb ->
                                    "jb"

                                J2b ->
                                    "jb"

                                _ ->
                                    String.left 1 ref
                    in
                    [ img
                        [ src ("/img/map-tiles/" ++ overlayPrefix ++ "-outline.png")
                        , class ("ref-" ++ ref)
                        , alt ("The outline of map tile " ++ ref)
                        ]
                        []
                    ]
            )
        ]


getCellHtml : CellModel msg -> Dom.Element msg
getCellHtml model =
    let
        ( x, y ) =
            model.coords

        currentDraggable =
            model.currentDraggable

        overlaysForCell =
            List.filter (filterOverlaysForCoord x y) model.overlays
                |> map
                    (\o ->
                        BoardOverlayModel
                            (case currentDraggable of
                                Just m ->
                                    case m.ref of
                                        OverlayType ot _ ->
                                            let
                                                isInCoords =
                                                    case m.coords of
                                                        Just ( ox, oy ) ->
                                                            any (\c -> c == ( ox, oy )) o.cells

                                                        Nothing ->
                                                            False

                                                isInTarget =
                                                    case m.target of
                                                        Just ( ox, oy ) ->
                                                            any (\c -> c == ( ox, oy )) o.cells

                                                        Nothing ->
                                                            False
                                            in
                                            ot.ref == o.ref && (isInCoords || isInTarget)

                                        _ ->
                                            False

                                Nothing ->
                                    False
                            )
                            (Just ( x, y ))
                            o
                            model.dragEvents
                    )

        piece =
            Maybe.map
                (\p ->
                    PieceModel
                        (case currentDraggable of
                            Just m ->
                                case m.ref of
                                    PieceType pieceType ->
                                        pieceType.ref == p.ref

                                    _ ->
                                        False

                            Nothing ->
                                False
                        )
                        (Just ( x, y ))
                        p
                        model.dragEvents
                )
                (getPieceForCoord x y model.pieces)

        monster =
            Maybe.map
                (\m ->
                    ScenarioMonsterModel
                        (case currentDraggable of
                            Just c ->
                                case c.ref of
                                    PieceType p ->
                                        case p.ref of
                                            AI (Enemy e) ->
                                                e == m.monster

                                            _ ->
                                                False

                                    _ ->
                                        False

                            Nothing ->
                                False
                        )
                        (Just ( x, y ))
                        m
                        model.dragEvents
                )
                (getScenarioMonsterForCoord x y model.scenarioMonsters)

        cellElement : Dom.Element msg
        cellElement =
            Dom.element "div"
                |> Dom.addClass "hexagon"
                |> Dom.addAttribute (attribute "data-cell-x" (String.fromInt x))
                |> Dom.addAttribute (attribute "data-cell-y" (String.fromInt y))
                -- Everything except coins
                |> Dom.setChildListWithKeys
                    ((overlaysForCell
                        |> List.sortWith
                            (\a b ->
                                compare (getSortOrderForOverlay a.overlay.ref) (getSortOrderForOverlay b.overlay.ref)
                            )
                        |> List.filter
                            (\o ->
                                case o.overlay.ref of
                                    Treasure t ->
                                        case t of
                                            Chest _ ->
                                                True

                                            _ ->
                                                False

                                    _ ->
                                        True
                            )
                        |> List.map (overlayToHtml model.dragOverlays model.dragDoors)
                     )
                        ++ -- Players / Monsters / Summons
                           (case piece of
                                Nothing ->
                                    []

                                Just p ->
                                    [ pieceToHtml model.dragPieces p ]
                           )
                        ++ (case monster of
                                Nothing ->
                                    []

                                Just m ->
                                    [ scenarioMonsterToHtml model.dragPieces m ]
                           )
                        ++ -- Coins
                           (overlaysForCell
                                |> List.filter
                                    (\o ->
                                        case o.overlay.ref of
                                            Treasure t ->
                                                case t of
                                                    Chest _ ->
                                                        False

                                                    _ ->
                                                        True

                                            _ ->
                                                False
                                    )
                                |> List.map (overlayToHtml model.dragOverlays model.dragDoors)
                           )
                        ++ -- The current draggable piece
                           (case currentDraggable of
                                Just m ->
                                    case m.ref of
                                        PieceType p ->
                                            if m.target == Just ( x, y ) then
                                                [ pieceToHtml
                                                    model.dragPieces
                                                    (PieceModel
                                                        False
                                                        (Just ( x, y ))
                                                        p
                                                        model.dragEvents
                                                    )
                                                ]

                                            else
                                                []

                                        OverlayType o _ ->
                                            if any (\c -> c == ( x, y )) o.cells then
                                                [ overlayToHtml
                                                    model.dragOverlays
                                                    model.dragDoors
                                                    (BoardOverlayModel
                                                        False
                                                        (Just ( x, y ))
                                                        o
                                                        model.dragEvents
                                                    )
                                                ]

                                            else
                                                []

                                        RoomType _ ->
                                            []

                                Nothing ->
                                    []
                           )
                    )
    in
    Dom.element "div"
        |> Dom.addClass "cell-wrapper"
        |> Dom.addClass (cellValueToString model.passable model.hidden)
        |> Dom.appendChild
            (Dom.element "div"
                |> Dom.addClass "cell"
                |> Dom.appendChild cellElement
            )
        |> (\e ->
                if model.passable == True && model.hidden == False then
                    makeDroppable ( x, y ) model.dropEvents e

                else
                    e
           )


getPieceForCoord : Int -> Int -> List Piece -> Maybe Piece
getPieceForCoord x y pieces =
    List.filter (\p -> p.x == x && p.y == y) pieces
        |> List.head


getScenarioMonsterForCoord : Int -> Int -> List ScenarioMonster -> Maybe ScenarioMonster
getScenarioMonsterForCoord x y monsters =
    List.filter (\m -> m.initialX == x && m.initialY == y) monsters
        |> List.head


filterOverlaysForCoord : Int -> Int -> BoardOverlay -> Bool
filterOverlaysForCoord x y overlay =
    case List.head (List.filter (\( oX, oY ) -> oX == x && oY == y) overlay.cells) of
        Just _ ->
            True

        Nothing ->
            False


getSortOrderForOverlay : BoardOverlayType -> Int
getSortOrderForOverlay overlay =
    case overlay of
        Door _ _ ->
            0

        Hazard _ ->
            1

        DifficultTerrain _ ->
            2

        StartingLocation ->
            3

        Rift ->
            4

        Treasure t ->
            case t of
                Chest _ ->
                    5

                Coin _ ->
                    6

        Obstacle _ ->
            7

        Trap _ ->
            8

        Wall _ ->
            9


overlayToHtml : Bool -> Bool -> BoardOverlayModel msg -> ( String, Dom.Element msg )
overlayToHtml dragOverlays dragDoors model =
    let
        label =
            getLabelForOverlay model.overlay model.coords
    in
    ( label
    , Dom.element "div"
        |> Dom.addAttribute
            (attribute "aria-label" label)
        |> Dom.addClass "overlay"
        |> Dom.addClassConditional "being-dragged" model.isDragging
        |> Dom.addClass
            (case model.overlay.ref of
                StartingLocation ->
                    "start-location"

                Rift ->
                    "rift"

                Treasure t ->
                    "treasure "
                        ++ (case t of
                                Coin _ ->
                                    "coin"

                                Chest _ ->
                                    "chest"
                           )

                Obstacle _ ->
                    "obstacle"

                Hazard _ ->
                    "hazard"

                DifficultTerrain _ ->
                    "difficult-terrain"

                Door c _ ->
                    "door"
                        ++ (case c of
                                Corridor _ _ ->
                                    " corridor"

                                _ ->
                                    ""
                           )

                Trap _ ->
                    "trap"

                Wall _ ->
                    "wall"
            )
        |> Dom.addClass
            (case model.overlay.direction of
                Default ->
                    ""

                Vertical ->
                    "vertical"

                VerticalReverse ->
                    "vertical-reverse"

                Horizontal ->
                    "horizontal"

                DiagonalRight ->
                    "diagonal-right"

                DiagonalLeft ->
                    "diagonal-left"

                DiagonalRightReverse ->
                    "diagonal-right-reverse"

                DiagonalLeftReverse ->
                    "diagonal-left-reverse"
            )
        |> Dom.addAttributeConditional
            (attribute "data-index"
                (case model.overlay.ref of
                    Treasure t ->
                        case t of
                            Chest c ->
                                case c of
                                    NormalChest i ->
                                        String.fromInt i

                                    Goal ->
                                        "Goal"

                                    Locked ->
                                        "???"

                            _ ->
                                ""

                    _ ->
                        ""
                )
            )
            (case model.overlay.ref of
                Treasure _ ->
                    True

                _ ->
                    False
            )
        |> Dom.appendChild
            (Dom.element "img"
                |> Dom.addAttribute (alt (getOverlayLabel model.overlay.ref))
                |> Dom.addAttribute (attribute "src" (getOverlayImageName model.overlay model.coords))
                |> Dom.addAttribute (attribute "draggable" "false")
            )
        |> (case model.overlay.ref of
                Treasure (Coin i) ->
                    Dom.appendChild
                        (Dom.element "span"
                            |> Dom.appendText (String.fromInt i)
                        )

                _ ->
                    \e -> e
           )
        |> (if dragOverlays then
                case model.overlay.ref of
                    Treasure (Coin _) ->
                        if model.coords == Nothing then
                            makeDraggable (OverlayType model.overlay Nothing) model.coords model.dragEvents

                        else
                            Dom.addAttribute (attribute "draggable" "false")

                    Treasure (Chest _) ->
                        Dom.addAttribute (attribute "draggable" "false")

                    Door _ _ ->
                        if dragDoors then
                            \e -> e

                        else
                            Dom.addAttribute (attribute "draggable" "false")

                    _ ->
                        makeDraggable (OverlayType model.overlay Nothing) model.coords model.dragEvents

            else
                \e -> e
           )
        |> (if dragDoors then
                case model.overlay.ref of
                    Door _ _ ->
                        makeDraggable (OverlayType model.overlay Nothing) model.coords model.dragEvents

                    _ ->
                        if dragOverlays then
                            \e -> e

                        else
                            Dom.addAttribute (attribute "draggable" "false")

            else
                \e -> e
           )
    )


pieceToHtml : Bool -> PieceModel msg -> ( String, Dom.Element msg )
pieceToHtml dragPiece model =
    let
        label =
            getLabelForPiece model.piece

        playerHtml : String -> String -> Element msg -> Element msg
        playerHtml l p e =
            Dom.addClass "hex-mask" e
                |> Dom.appendChild
                    (Dom.element "img"
                        |> Dom.addAttribute (alt l)
                        |> Dom.addAttribute (attribute "src" ("/img/characters/portraits/" ++ p ++ ".png"))
                    )
    in
    ( label
    , Dom.element "div"
        |> Dom.addAttribute
            (attribute "aria-label"
                (case model.coords of
                    Just ( x, y ) ->
                        label ++ " at " ++ String.fromInt x ++ ", " ++ String.fromInt y

                    Nothing ->
                        "Add New " ++ label
                )
            )
        |> Dom.addClass (getPieceType model.piece.ref)
        |> Dom.addClass (getPieceName model.piece.ref)
        |> Dom.addClassConditional "being-dragged" model.isDragging
        |> (case model.piece.ref of
                Player p ->
                    playerHtml label (Maybe.withDefault "" (characterToString p))

                AI t ->
                    case t of
                        Enemy m ->
                            enemyToHtml m label

                        Summons (NormalSummons i) ->
                            Dom.appendChildList
                                [ Dom.element "img"
                                    |> Dom.addAttribute (alt label)
                                    |> Dom.addAttribute (attribute "src" "/img/characters/summons.png")
                                    |> Dom.addAttribute (attribute "draggable" "false")
                                , Dom.element "span" |> Dom.appendText (String.fromInt i)
                                ]

                        Summons BearSummons ->
                            \e ->
                                Dom.addClass "bear" e
                                    |> playerHtml label "bear"

                Game.None ->
                    Dom.addClass "none"
           )
        |> (if dragPiece then
                makeDraggable (PieceType model.piece) model.coords model.dragEvents

            else
                \e -> e
           )
    )


scenarioMonsterToHtml : Bool -> ScenarioMonsterModel msg -> ( String, Dom.Element msg )
scenarioMonsterToHtml dragPiece model =
    let
        monster =
            model.monster

        label =
            Maybe.withDefault "" (monsterTypeToString monster.monster.monster)
                |> String.replace "-" " "

        pieceModel =
            { ref = AI (Enemy monster.monster)
            , x = monster.initialX
            , y = monster.initialY
            }
    in
    ( label
    , Dom.element "div"
        |> Dom.addAttribute
            (attribute "aria-label"
                (case model.coords of
                    Just ( x, y ) ->
                        label ++ " at " ++ String.fromInt x ++ ", " ++ String.fromInt y

                    Nothing ->
                        "Add New " ++ label
                )
            )
        |> Dom.addClass "monster"
        |> Dom.addClass (Maybe.withDefault "" (monsterTypeToString model.monster.monster.monster))
        |> Dom.addClassConditional "being-dragged" model.isDragging
        |> enemyToHtml monster.monster label
        |> Dom.appendChild
            (scenarioMonsterVisibilityToHtml monster.twoPlayer
                |> Dom.addClass "two-player"
            )
        |> Dom.appendChild
            (scenarioMonsterVisibilityToHtml monster.threePlayer
                |> Dom.addClass "three-player"
            )
        |> Dom.appendChild
            (scenarioMonsterVisibilityToHtml monster.fourPlayer
                |> Dom.addClass "four-player"
            )
        |> (if dragPiece then
                makeDraggable (PieceType pieceModel) model.coords model.dragEvents

            else
                \e -> e
           )
    )


cellValueToString : Bool -> Bool -> String
cellValueToString passable hidden =
    if hidden then
        "hidden"

    else if passable then
        "passable"

    else
        "impassable"


getLabelForOverlay : BoardOverlay -> Maybe ( Int, Int ) -> String
getLabelForOverlay overlay coords =
    case coords of
        Just ( x, y ) ->
            getOverlayLabel overlay.ref ++ " at " ++ String.fromInt x ++ ", " ++ String.fromInt y

        Nothing ->
            "Add new " ++ getOverlayLabel overlay.ref


getLabelForPiece : Piece -> String
getLabelForPiece piece =
    case piece.ref of
        Player p ->
            Maybe.withDefault "" (characterToString p)
                |> String.replace "-" " "

        AI t ->
            case t of
                Enemy m ->
                    (case m.monster of
                        NormalType _ ->
                            case m.level of
                                Elite ->
                                    "Elite"

                                Normal ->
                                    "Normal"

                                Monster.None ->
                                    ""

                        BossType _ ->
                            "Boss"
                    )
                        ++ " "
                        ++ (Maybe.withDefault "" (monsterTypeToString m.monster)
                                |> String.replace "-" " "
                           )
                        ++ (if m.id > 0 then
                                " (" ++ String.fromInt m.id ++ ")"

                            else
                                ""
                           )

                Summons (NormalSummons i) ->
                    "Summons Number " ++ String.fromInt i

                Summons BearSummons ->
                    "Beast Tyrant Bear Summons"

        Game.None ->
            "None"


getOverlayImageName : BoardOverlay -> Maybe ( Int, Int ) -> String
getOverlayImageName overlay coords =
    let
        path =
            "/img/overlays/"

        overlayName =
            Maybe.withDefault "" (getBoardOverlayName overlay.ref)

        extension =
            ".png"

        extendedOverlayName =
            if overlay.direction == Vertical || overlay.direction == VerticalReverse then
                case overlay.ref of
                    Door Stone _ ->
                        "-vert"

                    Door BreakableWall _ ->
                        "-vert"

                    Door Wooden _ ->
                        "-vert"

                    Obstacle Altar ->
                        "-vert"

                    _ ->
                        ""

            else
                ""

        segmentPart =
            case coords of
                Just ( x, y ) ->
                    case List.head (List.filter (\( _, ( oX, oY ) ) -> oX == x && oY == y) (toIndexedList (fromList overlay.cells))) of
                        Just ( segment, _ ) ->
                            if segment > 0 then
                                "-" ++ String.fromInt (segment + 1)

                            else
                                ""

                        Nothing ->
                            ""

                Nothing ->
                    ""
    in
    path ++ overlayName ++ extendedOverlayName ++ segmentPart ++ extension


enemyToHtml : Monster -> String -> Element msg -> Element msg
enemyToHtml monster altText element =
    let
        class =
            case monster.monster of
                NormalType _ ->
                    case monster.level of
                        Elite ->
                            "elite"

                        Normal ->
                            "normal"

                        Monster.None ->
                            ""

                BossType _ ->
                    "boss"
    in
    element
        |> Dom.addClass class
        |> Dom.addClass "hex-mask"
        |> Dom.appendChildList
            [ Dom.element "img"
                |> Dom.addAttribute
                    (attribute "src"
                        ("/img/monsters/"
                            ++ Maybe.withDefault "" (monsterTypeToString monster.monster)
                            ++ ".png"
                        )
                    )
                |> Dom.addAttribute (alt altText)
            , Dom.element "span"
                |> Dom.appendText
                    (if monster.id == 0 then
                        ""

                     else
                        String.fromInt monster.id
                    )
            ]


scenarioMonsterVisibilityToHtml : MonsterLevel -> Element msg
scenarioMonsterVisibilityToHtml level =
    Dom.element "div"
        |> Dom.addClass "monster-visibility"
        |> Dom.addClass
            (case level of
                Normal ->
                    "normal"

                Elite ->
                    "elite"

                Monster.None ->
                    "none"
            )


makeDraggable : MoveablePieceType -> Maybe ( Int, Int ) -> DragEvents msg -> Element msg -> Element msg
makeDraggable piece coords dragEvents element =
    let
        config =
            DragDrop.DraggedSourceConfig
                (DragDrop.EffectAllowed True False False)
                (\e v -> dragEvents.moveStart (MoveablePiece piece coords Nothing) (Just ( e, v )))
                (always dragEvents.moveCancel)
                Nothing
    in
    element
        |> Dom.addAttributeList (DragDrop.onSourceDrag config)
        |> Dom.addAttribute (Touch.onStart (\_ -> dragEvents.touchStart (MoveablePiece piece coords Nothing)))
        |> Dom.addAttribute
            (Touch.onMove
                (\e ->
                    case List.head e.touches of
                        Just touch ->
                            dragEvents.touchMove touch.clientPos

                        Nothing ->
                            dragEvents.noOp
                )
            )
        |> Dom.addAttribute
            (Touch.onEnd
                (\e ->
                    case List.head e.changedTouches of
                        Just touch ->
                            dragEvents.touchEnd touch.clientPos

                        Nothing ->
                            dragEvents.noOp
                )
            )


makeDroppable : ( Int, Int ) -> DropEvents msg -> Element msg -> Element msg
makeDroppable coords dropEvents element =
    let
        config =
            DragDrop.DropTargetConfig
                DragDrop.MoveOnDrop
                (\e v -> dropEvents.moveTargetChanged coords (Just ( e, v )))
                (always dropEvents.moveCompleted)
                Nothing
                Nothing
    in
    element
        |> Dom.addAttributeList (DragDrop.onDropTarget config)


getFooterHtml : String -> Html.Html msg
getFooterHtml v =
    footer []
        [ div [ class "credits" ]
            [ span [ class "gloomCopy" ]
                [ text "Gloomhaven and all related properties and images are owned by "
                , a [ href "http://www.cephalofair.com/" ] [ text "Cephalofair Games" ]
                ]
            , span [ class "any2CardCopy" ]
                [ text "Additional card scans courtesy of "
                , a [ href "https://github.com/any2cards/gloomhaven" ] [ text "Any2Cards" ]
                ]
            ]
        , div [ class "pkg" ]
            [ div
                [ class "copy-wrapper" ]
                [ span [ class "pkgCopy" ]
                    [ text "Developed by "
                    , a [ href "https://purplekingdomgames.com/" ] [ text "Purple Kingdom Games" ]
                    ]
                , div
                    [ class "sponsor" ]
                    [ iframe
                        [ class "sponsor-button"
                        , src "https://github.com/sponsors/PurpleKingdomGames/button"
                        , title "Sponsor PurpleKingdomGames"
                        , attribute "aria-hidden" "true"
                        ]
                        []
                    ]
                ]
            , div
                [ class "version" ]
                [ a [ target "_new", href "https://github.com/PurpleKingdomGames/virtual-gloomhaven-board/issues/new/choose" ] [ text "Report a bug" ]
                , span [] [ text ("Version " ++ v) ]
                ]
            ]
        ]
