package vgb

import tyrian.Html
import tyrian.Html.*

object BoardHtml {

  // def getMapTileHtml(
  //     visibleRooms: List[MapTileRef],
  //     roomData: List[RoomData],
  //     currentDraggable: String,
  //     draggableX: Int,
  //     draggableY: Int
  // ): Html[Msg] =
  //   div(`class` := "mapTiles")(
  //     roomData
  //       .distinctBy(d => BoardMapTile.refToString(d.ref).getOrElse(""))
  //       .map { r =>
  //         val isVisible = visibleRooms.contains(r.ref)
  //         val ref       = BoardMapTile.refToString(r.ref).getOrElse("")
  //         val (x, y) =
  //           if ref == currentDraggable then (draggableX, draggableY)
  //           else r.origin

  //         getSingleMapTileHtml(isVisible, ref, r.turns, x, y)
  //       }
  //   )

  // def getAllMapTileHtml(roomData: List[RoomData], currentDraggable: String, draggableX: Int, draggableY: Int): Html[Msg] = {
  //   val allRooms = if (roomData.exists(r => BoardMapTile.refToString(r.ref).contains(currentDraggable))) {
  //     roomData
  //   } else {
  //     BoardMapTile.stringToRef(currentDraggable) match {
  //       case Some(r) => RoomData(r, (draggableX, draggableY), 0) :: roomData
  //       case None => roomData
  //     }
  //   }
  //   getMapTileHtml(allRooms.map(_.ref), allRooms, currentDraggable, draggableX, draggableY)
  // }

  // getAllMapTileHtml : List RoomData -> String -> Int -> Int -> Html.Html Msg
  // getAllMapTileHtml roomData currentDraggable draggableX draggableY =
  //     let
  //         allRooms =
  //             if List.member currentDraggable (List.map (\r -> Maybe.withDefault "" (refToString r.ref)) roomData) then
  //                 roomData

  //             else
  //                 case stringToRef currentDraggable of
  //                     Just r ->
  //                         RoomData r ( draggableX, draggableY ) 0 :: roomData

  //                     Nothing ->
  //                         roomData
  //     in
  //     getMapTileHtml (map (\d -> d.ref) allRooms) allRooms currentDraggable draggableX draggableY

  // def getSingleMapTileHtml(isVisible: Boolean, ref: String, turns: Int, x: Int, y: Int): Html[Msg] = {
  //   val xPx = x * 76 + (if (y & 1) == 1 then 38 else 0)
  //   val yPx = y * 67

  //   <div>
  //     <div class="mapTile { s"rotate-$turns" } { if (isVisible) "visible" else "hidden" }" style={ s"top: ${yPx}px; left: ${xPx}px;" }>
  //       <img src={ s"/img/map-tiles/$ref.png" } class={ s"ref-$ref" } alt={ s"Map tile $ref" } aria-hidden={ if (isVisible) "false" else "true" }/>
  //     </div>
  //     <div class={ s"mapTile outline { s"rotate-$turns" } { if (isVisible) "hidden" else "visible" }" } style={ s"top: ${yPx}px; left: ${xPx}px;" } aria-hidden={ if (isVisible) "true" else "false" }>
  //       { stringToRef(ref) match {
  //           case Some(Empty) => Nil
  //           case Some(r) =>
  //             val overlayPrefix = r match {
  //               case J1a => "ja"
  //               case J2a => "ja"
  //               case J1b => "jb"
  //               case J1ba => "jb"
  //               case J1bb => "jb"
  //               case J2b => "jb"
  //               case _ => ref.take(1)
  //             }
  //             <img src={ s"/img/map-tiles/$overlayPrefix-outline.png" } class={ s"ref-$ref" } alt={ s"The outline of map tile $ref" }/>
  //           case None => Nil
  //         }
  //       }
  //     </div>
  //   </div>
  // }

// getSingleMapTileHtml : Bool -> String -> Int -> Int -> Int -> Html.Html Msg
// getSingleMapTileHtml isVisible ref turns x y =
//     let
//         xPx =
//             (x * 76)
//                 + (if Bitwise.and y 1 == 1 then
//                     38

//                    else
//                     0
//                   )

//         yPx =
//             y * 67
//     in
//     div
//         []
//         [ div
//             [ class "mapTile"
//             , class ("rotate-" ++ String.fromInt turns)
//             , class
//                 (if isVisible then
//                     "visible"

//                  else
//                     "hidden"
//                 )
//             , style "top" (String.fromInt yPx ++ "px")
//             , style "left" (String.fromInt xPx ++ "px")
//             ]
//             [ img
//                 [ src ("/img/map-tiles/" ++ ref ++ ".png")
//                 , class ("ref-" ++ ref)
//                 , alt ("Map tile " ++ ref)
//                 , attribute "aria-hidden"
//                     (if isVisible then
//                         "false"

//                      else
//                         "true"
//                     )
//                 ]
//                 []
//             ]
//         , div
//             [ class "mapTile outline"
//             , class ("rotate-" ++ String.fromInt turns)
//             , class
//                 (if isVisible then
//                     "hidden"

//                  else
//                     "visible"
//                 )
//             , style "top" (String.fromInt yPx ++ "px")
//             , style "left" (String.fromInt xPx ++ "px")
//             , attribute "aria-hidden"
//                 (if isVisible then
//                     "true"

//                  else
//                     "false"
//                 )
//             ]
//             (case stringToRef ref of
//                 Nothing ->
//                     []

//                 Just Empty ->
//                     []

//                 Just r ->
//                     let
//                         overlayPrefix =
//                             case r of
//                                 J1a ->
//                                     "ja"

//                                 J2a ->
//                                     "ja"

//                                 J1b ->
//                                     "jb"

//                                 J1ba ->
//                                     "jb"

//                                 J1bb ->
//                                     "jb"

//                                 J2b ->
//                                     "jb"

//                                 _ ->
//                                     String.left 1 ref
//                     in
//                     [ img
//                         [ src ("/img/map-tiles/" ++ overlayPrefix ++ "-outline.png")
//                         , class ("ref-" ++ ref)
//                         , alt ("The outline of map tile " ++ ref)
//                         ]
//                         []
//                     ]
//             )
//         ]

// getCellHtml : CellModel Msg -> Dom.Element Msg
// getCellHtml model =
//     let
//         ( x, y ) =
//             model.coords

//         currentDraggable =
//             model.currentDraggable

//         overlaysForCell =
//             List.filter (filterOverlaysForCoord x y) model.overlays
//                 |> map
//                     (\o ->
//                         BoardOverlayModel
//                             (case currentDraggable of
//                                 Just m ->
//                                     case m.ref of
//                                         OverlayType ot _ ->
//                                             let
//                                                 isInCoords =
//                                                     case m.coords of
//                                                         Just ( ox, oy ) ->
//                                                             any (\c -> c == ( ox, oy )) o.cells

//                                                         Nothing ->
//                                                             False

//                                                 isInTarget =
//                                                     case m.target of
//                                                         Just ( ox, oy ) ->
//                                                             any (\c -> c == ( ox, oy )) o.cells

//                                                         Nothing ->
//                                                             False
//                                             in
//                                             ot.ref == o.ref && (isInCoords || isInTarget)

//                                         _ ->
//                                             False

//                                 Nothing ->
//                                     False
//                             )
//                             (Just ( x, y ))
//                             o
//                             model.dragEvents
//                     )

//         piece =
//             Maybe.map
//                 (\p ->
//                     PieceModel
//                         (case currentDraggable of
//                             Just m ->
//                                 case m.ref of
//                                     PieceType pieceType ->
//                                         pieceType.ref == p.ref

//                                     _ ->
//                                         False

//                             Nothing ->
//                                 False
//                         )
//                         (Just ( x, y ))
//                         p
//                         model.dragEvents
//                 )
//                 (getPieceForCoord x y model.pieces)

//         monster =
//             Maybe.map
//                 (\m ->
//                     ScenarioMonsterModel
//                         (case currentDraggable of
//                             Just c ->
//                                 case c.ref of
//                                     PieceType p ->
//                                         case p.ref of
//                                             AI (Enemy e) ->
//                                                 e == m.monster

//                                             _ ->
//                                                 False

//                                     _ ->
//                                         False

//                             Nothing ->
//                                 False
//                         )
//                         (Just ( x, y ))
//                         m
//                         model.dragEvents
//                 )
//                 (getScenarioMonsterForCoord x y model.scenarioMonsters)

//         cellElement : Dom.Element Msg
//         cellElement =
//             Dom.element "div"
//                 |> Dom.addClass "hexagon"
//                 |> Dom.addAttribute (attribute "data-cell-x" (String.fromInt x))
//                 |> Dom.addAttribute (attribute "data-cell-y" (String.fromInt y))
//                 -- Everything except coins and tokens
//                 |> Dom.setChildListWithKeys
//                     ((overlaysForCell
//                         |> List.sortWith
//                             (\a b ->
//                                 compare (getSortOrderForOverlay a.overlay.ref) (getSortOrderForOverlay b.overlay.ref)
//                             )
//                         |> List.filter
//                             (\o ->
//                                 case o.overlay.ref of
//                                     Treasure t ->
//                                         case t of
//                                             Chest _ ->
//                                                 True

//                                             _ ->
//                                                 False

//                                     Token _ ->
//                                         False

//                                     _ ->
//                                         True
//                             )
//                         |> List.map (overlayToHtml model.dragOverlays model.dragDoors)
//                      )
//                         ++ -- Players / Monsters / Summons
//                            (case piece of
//                                 Nothing ->
//                                     []

//                                 Just p ->
//                                     [ pieceToHtml model.dragPieces p ]
//                            )
//                         ++ (case monster of
//                                 Nothing ->
//                                     []

//                                 Just m ->
//                                     [ scenarioMonsterToHtml model.dragPieces m ]
//                            )
//                         ++ -- Coins
//                            (overlaysForCell
//                                 |> List.filter
//                                     (\o ->
//                                         case o.overlay.ref of
//                                             Treasure t ->
//                                                 case t of
//                                                     Chest _ ->
//                                                         False

//                                                     _ ->
//                                                         True

//                                             Token _ ->
//                                                 True

//                                             _ ->
//                                                 False
//                                     )
//                                 |> List.map (overlayToHtml model.dragOverlays model.dragDoors)
//                            )
//                         ++ -- The current draggable piece
//                            (case currentDraggable of
//                                 Just m ->
//                                     case m.ref of
//                                         PieceType p ->
//                                             if m.target == Just ( x, y ) then
//                                                 [ pieceToHtml
//                                                     model.dragPieces
//                                                     (PieceModel
//                                                         False
//                                                         (Just ( x, y ))
//                                                         p
//                                                         model.dragEvents
//                                                     )
//                                                 ]

//                                             else
//                                                 []

//                                         OverlayType o _ ->
//                                             if any (\c -> c == ( x, y )) o.cells then
//                                                 [ overlayToHtml
//                                                     model.dragOverlays
//                                                     model.dragDoors
//                                                     (BoardOverlayModel
//                                                         False
//                                                         (Just ( x, y ))
//                                                         o
//                                                         model.dragEvents
//                                                     )
//                                                 ]

//                                             else
//                                                 []

//                                         RoomType _ ->
//                                             []

//                                 Nothing ->
//                                     []
//                            )
//                     )
//     in
//     Dom.element "div"
//         |> Dom.addClass "cell-wrapper"
//         |> Dom.addClass (cellValueToString model.passable model.hidden)
//         |> Dom.appendChild
//             (Dom.element "div"
//                 |> Dom.addClass "cell"
//                 |> Dom.appendChild cellElement
//             )
//         |> (\e ->
//                 if model.passable == True && model.hidden == False then
//                     makeDroppable ( x, y ) model.dropEvents e

//                 else
//                     e
//            )

  def getPieceForCoord(x: Int, y: Int, pieces: List[Piece]): Option[Piece] =
    pieces.filter(p => p.x == x && p.y == y).headOption

// getPieceForCoord : Int -> Int -> List Piece -> Maybe Piece
// getPieceForCoord x y pieces =
//     List.filter (\p -> p.x == x && p.y == y) pieces
//         |> List.head
  def getScenarioMonsterForCoord(x: Int, y: Int, monsters: List[ScenarioMonster]): Option[ScenarioMonster] =
    monsters.filter(m => m.initialX == x && m.initialY == y).headOption

// getScenarioMonsterForCoord : Int -> Int -> List ScenarioMonster -> Maybe ScenarioMonster
// getScenarioMonsterForCoord x y monsters =
//     List.filter (\m -> m.initialX == x && m.initialY == y) monsters
//         |> List.head

  def filterOverlaysForCoord(x: Int, y: Int, overlay: BoardOverlay): Boolean =
    overlay.cells.exists { case (oX, oY) => oX == x && oY == y }

// filterOverlaysForCoord : Int -> Int -> BoardOverlay -> Bool
// filterOverlaysForCoord x y overlay =
//     case List.head (List.filter (\( oX, oY ) -> oX == x && oY == y) overlay.cells) of
//         Just _ ->
//             True

//         Nothing ->
//             False

  // def getSortOrderForOverlay(overlay: BoardOverlayType): Int =
  //   overlay match {
  //     case Token(_) => 0
  //     case Door(_, _) => 1
  //     case Hazard(_) => 2
  //     case DifficultTerrain(_) => 3
  //     case StartingLocation => 4
  //     case Rift => 5
  //     case Treasure(t) => t match {
  //       case Chest(_) => 6
  //       case Coin(_) => 7
  //     }
  //     case Obstacle(_) => 8
  //     case Trap(_) => 9
  //     case Wall(_) => 10
  //     case Highlight(_) => 11
  //   }

// getSortOrderForOverlay : BoardOverlayType -> Int
// getSortOrderForOverlay overlay =
//     case overlay of
//         Token _ ->
//             0

//         Door _ _ ->
//             1

//         Hazard _ ->
//             2

//         DifficultTerrain _ ->
//             3

//         StartingLocation ->
//             4

//         Rift ->
//             5

//         Treasure t ->
//             case t of
//                 Chest _ ->
//                     6

//                 Coin _ ->
//                     7

//         Obstacle _ ->
//             8

//         Trap _ ->
//             9

//         Wall _ ->
//             10

//         Highlight _ ->
//             11

// def overlayToHtml(dragOverlays: Boolean, dragDoors: Boolean, model: BoardOverlayModel[Msg]): (String, Dom.Element[Msg]) = {
//   val label = getLabelForOverlay(model.overlay, model.coords)
//   (
//     label,
//     Dom.element("div")
//       .addAttribute(attribute("aria-label", label))
//       .addClass("overlay")
//       .addClassConditional("being-dragged", model.isDragging)
//       .addClass(
//         model.overlay.ref match {
//           case StartingLocation => "start-location"
//           case Rift => "rift"
//           case Treasure(t) =>
//             "treasure " + (t match {
//               case Coin(_) => "coin"
//               case Chest(_) => "chest"
//             })
//           case Obstacle(_) => "obstacle"
//           case Hazard(_) => "hazard"
//           case Highlight(_) => "highlight"
//           case DifficultTerrain(_) => "difficult-terrain"
//           case Door(c, _) =>
//             "door" + (c match {
//               case Corridor(_, _) => " corridor"
//               case _ => ""
//             })
//           case Trap(_) => "trap"
//           case Token(_) => "token"
//           case Wall(_) => "wall"
//         }
//       )
//       .addClass(
//         model.overlay.direction match {
//           case Default => ""
//           case Vertical => "vertical"
//           case VerticalReverse => "vertical-reverse"
//           case Horizontal => "horizontal"
//           case DiagonalRight => "diagonal-right"
//           case DiagonalLeft => "diagonal-left"
//           case DiagonalRightReverse => "diagonal-right-reverse"
//           case DiagonalLeftReverse => "diagonal-left-reverse"
//         }
//       )
//       .addAttributeConditional(
//         attribute(
//           "data-index",
//           model.overlay.ref match {
//             case Treasure(t) => t match {
//               case Chest(NormalChest(i)) => String.valueOf(i)
//               case Goal => "Goal"
//               case Locked => "???"
//               case _ => ""
//             }
//             case _ => ""
//           }
//         )
//       )(
//         model.overlay.ref match {
//           case Treasure(_) => true
//           case _ => false
//         }
//       )
//       .appendChild(
//         model.overlay.ref match {
//           case Token(value) =>
//             Dom.element("span").appendText(value)
//           case Highlight(c) =>
//             Dom.element("div").addStyle("background-color", Colour.toHexString(c))
//           case _ =>
//             Dom.element("img")
//               .addAttribute(alt(getOverlayLabel(model.overlay.ref)))
//               .addAttribute(attribute("src", getOverlayImageName(model.overlay, model.coords)))
//               .addAttribute(attribute("draggable", "false"))
//         }
//       )
//       .map(
//         model.overlay.ref match {
//           case Treasure(Coin(i)) =>
//             _.appendChild(
//               Dom.element("span").appendText(String.valueOf(i))
//             )
//           case _ => identity
//         }
//       )
//       .map(
//         if (dragOverlays) {
//           model.overlay.ref match {
//             case Treasure(Coin(_)) =>
//               if (model.coords.isEmpty) {
//                 makeDraggable(OverlayType(model.overlay, None), model.coords, model.dragEvents)
//               } else {
//                 _.addAttribute(attribute("draggable", "false"))
//               }
//             case Treasure(Chest(_)) =>
//               _.addAttribute(attribute("draggable", "false"))
//             case Highlight(_) =>
//               _.addAttribute(attribute("draggable", "false"))
//             case Door(_, _) =>
//               if (dragDoors) {
//                 identity
//               } else {
//                 _.addAttribute(attribute("draggable", "false"))
//               }
//             case _ =>
//               makeDraggable(OverlayType(model.overlay, None), model.coords, model

// overlayToHtml : Bool -> Bool -> BoardOverlayModel Msg -> ( String, Dom.Element Msg )
// overlayToHtml dragOverlays dragDoors model =
//     let
//         label =
//             getLabelForOverlay model.overlay model.coords
//     in
//     ( label
//     , Dom.element "div"
//         |> Dom.addAttribute
//             (attribute "aria-label" label)
//         |> Dom.addClass "overlay"
//         |> Dom.addClassConditional "being-dragged" model.isDragging
//         |> Dom.addClass
//             (case model.overlay.ref of
//                 StartingLocation ->
//                     "start-location"

//                 Rift ->
//                     "rift"

//                 Treasure t ->
//                     "treasure "
//                         ++ (case t of
//                                 Coin _ ->
//                                     "coin"

//                                 Chest _ ->
//                                     "chest"
//                            )

//                 Obstacle _ ->
//                     "obstacle"

//                 Hazard _ ->
//                     "hazard"

//                 Highlight _ ->
//                     "highlight"

//                 DifficultTerrain _ ->
//                     "difficult-terrain"

//                 Door c _ ->
//                     "door"
//                         ++ (case c of
//                                 Corridor _ _ ->
//                                     " corridor"

//                                 _ ->
//                                     ""
//                            )

//                 Trap _ ->
//                     "trap"

//                 Token _ ->
//                     "token"

//                 Wall _ ->
//                     "wall"
//             )
//         |> Dom.addClass
//             (case model.overlay.direction of
//                 Default ->
//                     ""

//                 Vertical ->
//                     "vertical"

//                 VerticalReverse ->
//                     "vertical-reverse"

//                 Horizontal ->
//                     "horizontal"

//                 DiagonalRight ->
//                     "diagonal-right"

//                 DiagonalLeft ->
//                     "diagonal-left"

//                 DiagonalRightReverse ->
//                     "diagonal-right-reverse"

//                 DiagonalLeftReverse ->
//                     "diagonal-left-reverse"
//             )
//         |> Dom.addAttributeConditional
//             (attribute "data-index"
//                 (case model.overlay.ref of
//                     Treasure t ->
//                         case t of
//                             Chest c ->
//                                 case c of
//                                     NormalChest i ->
//                                         String.fromInt i

//                                     Goal ->
//                                         "Goal"

//                                     Locked ->
//                                         "???"

//                             _ ->
//                                 ""

//                     _ ->
//                         ""
//                 )
//             )
//             (case model.overlay.ref of
//                 Treasure _ ->
//                     True

//                 _ ->
//                     False
//             )
//         |> Dom.appendChild
//             (case model.overlay.ref of
//                 Token val ->
//                     Dom.element "span"
//                         |> Dom.appendText val

//                 Highlight c ->
//                     Dom.element "div"
//                         |> Dom.addStyle ( "background-color", Colour.toHexString c )

//                 _ ->
//                     Dom.element "img"
//                         |> Dom.addAttribute (alt (getOverlayLabel model.overlay.ref))
//                         |> Dom.addAttribute (attribute "src" (getOverlayImageName model.overlay model.coords))
//                         |> Dom.addAttribute (attribute "draggable" "false")
//             )
//         |> (case model.overlay.ref of
//                 Treasure (Coin i) ->
//                     Dom.appendChild
//                         (Dom.element "span"
//                             |> Dom.appendText (String.fromInt i)
//                         )

//                 _ ->
//                     \e -> e
//            )
//         |> (if dragOverlays then
//                 case model.overlay.ref of
//                     Treasure (Coin _) ->
//                         if model.coords == Nothing then
//                             makeDraggable (OverlayType model.overlay Nothing) model.coords model.dragEvents

//                         else
//                             Dom.addAttribute (attribute "draggable" "false")

//                     Treasure (Chest _) ->
//                         Dom.addAttribute (attribute "draggable" "false")

//                     Highlight _ ->
//                         Dom.addAttribute (attribute "draggable" "false")

//                     Door _ _ ->
//                         if dragDoors then
//                             \e -> e

//                         else
//                             Dom.addAttribute (attribute "draggable" "false")

//                     _ ->
//                         makeDraggable (OverlayType model.overlay Nothing) model.coords model.dragEvents

//             else
//                 \e -> e
//            )
//         |> (if dragDoors then
//                 case model.overlay.ref of
//                     Door _ _ ->
//                         makeDraggable (OverlayType model.overlay Nothing) model.coords model.dragEvents

//                     _ ->
//                         if dragOverlays then
//                             \e -> e

//                         else
//                             Dom.addAttribute (attribute "draggable" "false")

//             else
//                 \e -> e
//            )
//     )

  // def pieceToHtml(dragPiece: Boolean, model: PieceModel[Msg]): (String, dom.Element[Msg]) = {
  //   def playerHtml(l: String, p: String, e: dom.Element[Msg]): dom.Element[Msg] = {
  //     e.addClass("hex-mask").appendChild(
  //       dom.html("img")
  //         .setAttribute("alt", l)
  //         .setAttribute("src", s"/img/characters/portraits/$p.png")
  //     )
  //   }

  //   val label = getLabelForPiece(model.piece)
  //   val element = dom.html("div")
  //     .setAttribute("aria-label", model.coords match {
  //       case Some((x, y)) => s"$label at $x, $y"
  //       case None => s"Add New $label"
  //     })
  //     .addClass(getPieceType(model.piece.ref))
  //     .addClass(getPieceName(model.piece.ref))
  //     .addClassConditional("being-dragged", model.isDragging)
  //     .appendChild(model.piece.ref match {
  //       case Player(p) =>
  //         playerHtml(label, characterToString.getOrElse(p, ""), dom.html("div"))
  //       case AI(Enemy(m)) =>
  //         enemyToHtml(m, label)
  //       case AI(Summons(NormalSummons(i, colour))) =>
  //         dom.html("div")
  //           .appendChildList(Seq(
  //             dom.html("img")
  //               .setAttribute("alt", label)
  //               .setAttribute("src", "/img/characters/summons.png")
  //               .setAttribute("draggable", "false"),
  //             dom.html("span").setTextContent(i.toString)
  //           ))
  //       case AI(Summons(BearSummons)) =>
  //         playerHtml(label, "bear", dom.html("div").addClass("bear"))
  //       case Game.None =>
  //         dom.html("div").addClass("none")
  //     })

  //   if (dragPiece) {
  //     makeDraggable(PieceType(model.piece), model.coords, model.dragEvents)(element)
  //   } else {
  //     element
  //   }

  //   (label, element)
  // }

// pieceToHtml : Bool -> PieceModel Msg -> ( String, Dom.Element Msg )
// pieceToHtml dragPiece model =
//     let
//         label =
//             getLabelForPiece model.piece

//         playerHtml : String -> String -> Element Msg -> Element Msg
//         playerHtml l p e =
//             Dom.addClass "hex-mask" e
//                 |> Dom.appendChild
//                     (Dom.element "img"
//                         |> Dom.addAttribute (alt l)
//                         |> Dom.addAttribute (attribute "src" ("/img/characters/portraits/" ++ p ++ ".png"))
//                     )
//     in
//     ( label
//     , Dom.element "div"
//         |> Dom.addAttribute
//             (attribute "aria-label"
//                 (case model.coords of
//                     Just ( x, y ) ->
//                         label ++ " at " ++ String.fromInt x ++ ", " ++ String.fromInt y

//                     Nothing ->
//                         "Add New " ++ label
//                 )
//             )
//         |> Dom.addClass (getPieceType model.piece.ref)
//         |> Dom.addClass (getPieceName model.piece.ref)
//         |> Dom.addClassConditional "being-dragged" model.isDragging
//         |> (case model.piece.ref of
//                 Player p ->
//                     playerHtml label (Maybe.withDefault "" (characterToString p))

//                 AI t ->
//                     case t of
//                         Enemy m ->
//                             enemyToHtml m label

//                         Summons (NormalSummons i colour) ->
//                             Dom.appendChildList
//                                 [ Dom.element "img"
//                                     |> Dom.addAttribute (alt label)
//                                     |> Dom.addAttribute (attribute "src" "/img/characters/summons.png")
//                                     |> Dom.addAttribute (attribute "draggable" "false")
//                                 , Dom.element "span" |> Dom.appendText (String.fromInt i)
//                                 ]

//                         Summons BearSummons ->
//                             \e ->
//                                 Dom.addClass "bear" e
//                                     |> playerHtml label "bear"

//                 Game.None ->
//                     Dom.addClass "none"
//            )
//         |> (if dragPiece then
//                 makeDraggable (PieceType model.piece) model.coords model.dragEvents

//             else
//                 \e -> e
//            )
//     )

  // def scenarioMonsterToHtml(dragPiece: Boolean, model: ScenarioMonsterModel[Msg]): (String, Dom.Element[Msg]) = {
  //   val monster = model.monster
  //   val label = monster.monster.monster.map(monsterTypeToString).getOrElse("").replace("-", " ")
  //   val pieceModel = PieceModel(ref = AI(Enemy(monster.monster)), x = monster.initialX, y = monster.initialY)
  //   val ariaLabel = model.coords match {
  //     case Some((x, y)) => s"$label at $x, $y"
  //     case None => s"Add New $label"
  //   }

  //   (label,
  //     Dom
  //       .element("div")
  //       .addAttribute(attribute("aria-label", ariaLabel))
  //       .addClass("monster")
  //       .addClass(monster.monster.monster.map(monsterTypeToString).getOrElse(""))
  //       .addClassConditional("being-dragged", model.isDragging)
  //       .appendChild(enemyToHtml(monster.monster, label))
  //       .appendChild(scenarioMonsterVisibilityToHtml(monster.twoPlayer).addClass("two-player"))
  //       .appendChild(scenarioMonsterVisibilityToHtml(monster.threePlayer).addClass("three-player"))
  //       .appendChild(scenarioMonsterVisibilityToHtml(monster.fourPlayer).addClass("four-player"))
  //       .map(if (dragPiece) makeDraggable(PieceType(pieceModel), model.coords, model.dragEvents) else identity)
  //   )
  // }

// scenarioMonsterToHtml : Bool -> ScenarioMonsterModel Msg -> ( String, Dom.Element Msg )
// scenarioMonsterToHtml dragPiece model =
//     let
//         monster =
//             model.monster

//         label =
//             Maybe.withDefault "" (monsterTypeToString monster.monster.monster)
//                 |> String.replace "-" " "

//         pieceModel =
//             { ref = AI (Enemy monster.monster)
//             , x = monster.initialX
//             , y = monster.initialY
//             }
//     in
//     ( label
//     , Dom.element "div"
//         |> Dom.addAttribute
//             (attribute "aria-label"
//                 (case model.coords of
//                     Just ( x, y ) ->
//                         label ++ " at " ++ String.fromInt x ++ ", " ++ String.fromInt y

//                     Nothing ->
//                         "Add New " ++ label
//                 )
//             )
//         |> Dom.addClass "monster"
//         |> Dom.addClass (Maybe.withDefault "" (monsterTypeToString model.monster.monster.monster))
//         |> Dom.addClassConditional "being-dragged" model.isDragging
//         |> enemyToHtml monster.monster label
//         |> Dom.appendChild
//             (scenarioMonsterVisibilityToHtml monster.twoPlayer
//                 |> Dom.addClass "two-player"
//             )
//         |> Dom.appendChild
//             (scenarioMonsterVisibilityToHtml monster.threePlayer
//                 |> Dom.addClass "three-player"
//             )
//         |> Dom.appendChild
//             (scenarioMonsterVisibilityToHtml monster.fourPlayer
//                 |> Dom.addClass "four-player"
//             )
//         |> (if dragPiece then
//                 makeDraggable (PieceType pieceModel) model.coords model.dragEvents

//             else
//                 \e -> e
//            )
//     )

  def cellValueToString(passable: Boolean, hidden: Boolean): String =
    if (hidden) {
      "hidden"
    } else if (passable) {
      "passable"
    } else {
      "impassable"
    }

// cellValueToString : Bool -> Bool -> String
// cellValueToString passable hidden =
//     if hidden then
//         "hidden"

//     else if passable then
//         "passable"

//     else
//         "impassable"

  // def getLabelForOverlay(overlay: BoardOverlay, coords: Option[(Int, Int)]): String = coords match {
  //   case Some((x, y)) => s"${getOverlayLabel(overlay.ref)} at $x, $y"
  //   case None => s"Add new ${getOverlayLabel(overlay.ref)}"
  // }

// getLabelForOverlay : BoardOverlay -> Maybe ( Int, Int ) -> String
// getLabelForOverlay overlay coords =
//     case coords of
//         Just ( x, y ) ->
//             getOverlayLabel overlay.ref ++ " at " ++ String.fromInt x ++ ", " ++ String.fromInt y

//         Nothing ->
//             "Add new " ++ getOverlayLabel overlay.ref

  // def getLabelForPiece(piece: Piece): String = {
  //   piece.ref match {
  //     case Player(p) =>
  //       characterToString(p)
  //         .getOrElse("")
  //         .replace("-", " ")

  //     case AI(t) =>
  //       t match {
  //         case Enemy(m) =>
  //           (m.monster match {
  //             case NormalType(_) =>
  //               m.level match {
  //                 case Elite => "Elite"
  //                 case Normal => "Normal"
  //                 case _ => ""
  //               }
  //             case BossType(_) => "Boss"
  //           }) + " " +
  //             monsterTypeToString(m.monster)
  //               .getOrElse("")
  //               .replace("-", " ") +
  //             (if (m.id > 0) " (" + m.id.toString + ")" else "")

  //         case Summons(NormalSummons(i, _)) =>
  //           "Summons Number " + i.toString

  //         case Summons(BearSummons) =>
  //           "Beast Tyrant Bear Summons"
  //       }

  //     case Game.None => "None"
  //   }
  // }

// getLabelForPiece : Piece -> String
// getLabelForPiece piece =
//     case piece.ref of
//         Player p ->
//             Maybe.withDefault "" (characterToString p)
//                 |> String.replace "-" " "

//         AI t ->
//             case t of
//                 Enemy m ->
//                     (case m.monster of
//                         NormalType _ ->
//                             case m.level of
//                                 Elite ->
//                                     "Elite"

//                                 Normal ->
//                                     "Normal"

//                                 Monster.None ->
//                                     ""

//                         BossType _ ->
//                             "Boss"
//                     )
//                         ++ " "
//                         ++ (Maybe.withDefault "" (monsterTypeToString m.monster)
//                                 |> String.replace "-" " "
//                            )
//                         ++ (if m.id > 0 then
//                                 " (" ++ String.fromInt m.id ++ ")"

//                             else
//                                 ""
//                            )

//                 Summons (NormalSummons i _) ->
//                     "Summons Number " ++ String.fromInt i

//                 Summons BearSummons ->
//                     "Beast Tyrant Bear Summons"

//         Game.None ->
//             "None"

  // def getOverlayImageName(overlay: BoardOverlay, coords: Option[(Int, Int)]): String = {
  //   val path = "/img/overlays/"
  //   val overlayName = getBoardOverlayName(overlay.ref).getOrElse("")
  //   val extension = ".png"
  //   val extendedOverlayName = overlay.direction match {
  //     case Vertical | VerticalReverse =>
  //       overlay.ref match {
  //         case Door(Stone, _) => "-vert"
  //         case Door(BreakableWall, _) => "-vert"
  //         case Door(Wooden, _) => "-vert"
  //         case Obstacle(Altar) => "-vert"
  //         case _ => ""
  //       }
  //     case _ => ""
  //   }
  //   val segmentPart = coords match {
  //     case Some((x, y)) =>
  //       toIndexedList(overlay.cells)
  //         .collectFirst { case (segment, (oX, oY)) if oX == x && oY == y => segment }
  //         .map(segment => if (segment > 0) s"-${segment + 1}" else "")
  //         .getOrElse("")
  //     case None => ""
  //   }
  //   path + overlayName + extendedOverlayName + segmentPart + extension
  // }

// getOverlayImageName : BoardOverlay -> Maybe ( Int, Int ) -> String
// getOverlayImageName overlay coords =
//     let
//         path =
//             "/img/overlays/"

//         overlayName =
//             Maybe.withDefault "" (getBoardOverlayName overlay.ref)

//         extension =
//             ".png"

//         extendedOverlayName =
//             if overlay.direction == Vertical || overlay.direction == VerticalReverse then
//                 case overlay.ref of
//                     Door Stone _ ->
//                         "-vert"

//                     Door BreakableWall _ ->
//                         "-vert"

//                     Door Wooden _ ->
//                         "-vert"

//                     Obstacle Altar ->
//                         "-vert"

//                     _ ->
//                         ""

//             else
//                 ""

//         segmentPart =
//             case coords of
//                 Just ( x, y ) ->
//                     case List.head (List.filter (\( _, ( oX, oY ) ) -> oX == x && oY == y) (toIndexedList (fromList overlay.cells))) of
//                         Just ( segment, _ ) ->
//                             if segment > 0 then
//                                 "-" ++ String.fromInt (segment + 1)

//                             else
//                                 ""

//                         Nothing ->
//                             ""

//                 Nothing ->
//                     ""
//     in
//     path ++ overlayName ++ extendedOverlayName ++ segmentPart ++ extension

  // def enemyToHtml(monster: Monster, altText: String, element: dom.Element): dom.Element = {
  //   val cssClass: String = monster.monster match {
  //     case NormalType(_) => monster.level match {
  //       case Elite => "elite"
  //       case Normal => "normal"
  //       case Monster.None => ""
  //     }
  //     case BossType(_) => "boss"
  //   }

  //   element
  //     .classList.add(cssClass)
  //     .classList.add("hex-mask")
  //     .appendChild(
  //       List(
  //         dom.document.createElement("img")
  //           .setAttribute("src", s"/img/monsters/${monsterTypeToString(monster.monster).getOrElse("")}.png")
  //           .setAttribute("alt", altText),
  //         dom.document.createElement("span")
  //           .appendChild(dom.document.createTextNode(
  //             if (monster.id == 0) "" else monster.id.toString
  //           ))
  //       ): _*
  //     )
  // }

// enemyToHtml : Monster -> String -> Element Msg -> Element Msg
// enemyToHtml monster altText element =
//     let
//         class =
//             case monster.monster of
//                 NormalType _ ->
//                     case monster.level of
//                         Elite ->
//                             "elite"

//                         Normal ->
//                             "normal"

//                         Monster.None ->
//                             ""

//                 BossType _ ->
//                     "boss"
//     in
//     element
//         |> Dom.addClass class
//         |> Dom.addClass "hex-mask"
//         |> Dom.appendChildList
//             [ Dom.element "img"
//                 |> Dom.addAttribute
//                     (attribute "src"
//                         ("/img/monsters/"
//                             ++ Maybe.withDefault "" (monsterTypeToString monster.monster)
//                             ++ ".png"
//                         )
//                     )
//                 |> Dom.addAttribute (alt altText)
//             , Dom.element "span"
//                 |> Dom.appendText
//                     (if monster.id == 0 then
//                         ""

//                      else
//                         String.fromInt monster.id
//                     )
//             ]

// def scenarioMonsterVisibilityToHtml(level: MonsterLevel): Element[Msg] =
//   Dom.element("div")
//     .addClass("monster-visibility")
//     .addClass(level match {
//       case Normal => "normal"
//       case Elite => "elite"
//       case Monster.None => "none"
//     })

// scenarioMonsterVisibilityToHtml : MonsterLevel -> Element Msg
// scenarioMonsterVisibilityToHtml level =
//     Dom.element "div"
//         |> Dom.addClass "monster-visibility"
//         |> Dom.addClass
//             (case level of
//                 Normal ->
//                     "normal"

//                 Elite ->
//                     "elite"

//                 Monster.None ->
//                     "none"
//             )

// makeDraggable : MoveablePieceType -> Maybe ( Int, Int ) -> DragEvents Msg -> Element Msg -> Element Msg
// makeDraggable piece coords dragEvents element =
//     let
//         config =
//             DragDrop.DraggedSourceConfig
//                 (DragDrop.EffectAllowed True False False)
//                 (\e v -> dragEvents.moveStart (MoveablePiece piece coords Nothing) (Just ( e, v )))
//                 (always dragEvents.moveCancel)
//                 Nothing
//     in
//     element
//         |> Dom.addAttributeList (DragDrop.onSourceDrag config)
//         |> Dom.addAttribute (Touch.onStart (\_ -> dragEvents.touchStart (MoveablePiece piece coords Nothing)))
//         |> Dom.addAttribute
//             (Touch.onMove
//                 (\e ->
//                     case List.head e.touches of
//                         Just touch ->
//                             dragEvents.touchMove touch.clientPos

//                         Nothing ->
//                             dragEvents.noOp
//                 )
//             )
//         |> Dom.addAttribute
//             (Touch.onEnd
//                 (\e ->
//                     case List.head e.changedTouches of
//                         Just touch ->
//                             dragEvents.touchEnd touch.clientPos

//                         Nothing ->
//                             dragEvents.noOp
//                 )
//             )

// makeDroppable : ( Int, Int ) -> DropEvents Msg -> Element Msg -> Element Msg
// makeDroppable coords dropEvents element =
//     let
//         config =
//             DragDrop.DropTargetConfig
//                 DragDrop.MoveOnDrop
//                 (\e v -> dropEvents.moveTargetChanged coords (Just ( e, v )))
//                 (always dropEvents.moveCompleted)
//                 Nothing
//                 Nothing
//     in
//     element
//         |> Dom.addAttributeList (DragDrop.onDropTarget config)

// getFooterHtml : String -> Html.Html Msg
// getFooterHtml v =
//     footer []
//         [ div [ class "credits" ]
//             [ span [ class "gloomCopy" ]
//                 [ text "Gloomhaven and all related properties and images are owned by "
//                 , a [ href "http://www.cephalofair.com/" ] [ text "Cephalofair Games" ]
//                 ]
//             , span [ class "any2CardCopy" ]
//                 [ text "Additional card scans courtesy of "
//                 , a [ href "https://github.com/any2cards/gloomhaven" ] [ text "Any2Cards" ]
//                 ]
//             ]
//         , div [ class "pkg" ]
//             [ div
//                 [ class "copy-wrapper" ]
//                 [ span [ class "pkgCopy" ]
//                     [ text "Developed by "
//                     , a [ href "https://purplekingdomgames.com/" ] [ text "Purple Kingdom Games" ]
//                     ]
//                 , div
//                     [ class "sponsor" ]
//                     [ iframe
//                         [ class "sponsor-button"
//                         , src "https://github.com/sponsors/PurpleKingdomGames/button"
//                         , title "Sponsor PurpleKingdomGames"
//                         , attribute "aria-hidden" "true"
//                         ]
//                         []
//                     ]
//                 ]
//             , div
//                 [ class "version" ]
//                 [ a [ target "_new", href "https://github.com/PurpleKingdomGames/virtual-gloomhaven-board/issues/new/choose" ] [ text "Report a bug" ]
//                 , span [] [ text ("Version " ++ v) ]
//                 ]
//             ]
//         ]

  // def formatNameString(name: String): String = {
  //   name
  //     .split("-")
  //     .map(s => s.slice(0, 1).toUpperCase + s.slice(1))
  //     .mkString(" ")
  // }

// formatNameString : String -> String
// formatNameString name =
//     name
//         |> String.split "-"
//         |> List.map
//             (\s ->
//                 String.toUpper (String.slice 0 1 s)
//                     ++ String.slice 1 (String.length s) s
//             )
//         |> String.join " "

  // def getTutorialHtml(tutorialText: String, stepNo: Int)(msg: Msg): (String, Html[Msg]) = {
  //   ("tutorial",
  //     Dom
  //       .element("div")
  //       .addClass("tutorial")
  //       .addClass(s"step-$stepNo")
  //       .appendChild(
  //         Dom
  //           .element("div")
  //           .addClass("body")
  //           .appendText(tutorialText)
  //       )
  //       .appendChild(
  //         Dom
  //           .element("div")
  //           .addClass("footer")
  //           .addClass("button-wrapper")
  //           .appendChild(
  //             Dom
  //               .element("button")
  //               .appendText("Got it!")
  //               .addActionStopPropagation("click", msg)
  //           )
  //       )
  //       .render
  //   )
  // }

// getTutorialHtml : String -> Int -> Msg -> ( String, Html.Html Msg )
// getTutorialHtml tutorialText stepNo[Msg] =
//     ( "tutorial"
//     , Dom.element "div"
//         |> Dom.addClass "tutorial"
//         |> Dom.addClass ("step-" ++ String.fromInt stepNo)
//         |> Dom.appendChild
//             (Dom.element "div"
//                 |> Dom.addClass "body"
//                 |> Dom.appendText tutorialText
//             )
//         |> Dom.appendChild
//             (Dom.element "div"
//                 |> Dom.addClass "footer"
//                 |> Dom.addClass "button-wrapper"
//                 |> Dom.appendChild
//                     (Dom.element "button"
//                         |> Dom.appendText "Got it!"
//                         |> Dom.addActionStopPropagation ( "click", Msg )
//                     )
//             )
//         |> Dom.render
//     )

}

enum ContextMenu:
  case Open
  case Closed
  case TwoPlayerSubMenu
  case ThreePlayerSubMenu
  case FourPlayerSubMenu
  case SpawnSubMenu
  case SummonSubMenu
  case PlaceOverlayMenu
  case PlaceTokenMenu
  case PlaceHighlightMenu
  case AddObstacleSubMenu
  case AddTrapSubMenu

final case class CellModel[Msg](
    overlays: List[BoardOverlay],
    pieces: List[Piece],
    scenarioMonsters: List[ScenarioMonster],
    coords: (Int, Int),
    currentDraggable: Option[MoveablePiece],
    dragOverlays: Boolean,
    dragPieces: Boolean,
    dragDoors: Boolean,
    dragEvents: DragEvents[Msg],
    dropEvents: DropEvents[Msg],
    passable: Boolean,
    hidden: Boolean
)

final case class BoardOverlayModel[Msg](
    isDragging: Boolean,
    coords: Option[(Int, Int)],
    overlay: BoardOverlay,
    dragEvents: DragEvents[Msg]
)

final case class PieceModel[Msg](
    isDragging: Boolean,
    coords: Option[(Int, Int)],
    piece: Piece,
    dragEvents: DragEvents[Msg]
)

final case class ScenarioMonsterModel[Msg](
    isDragging: Boolean,
    coords: Option[(Int, Int)],
    monster: ScenarioMonster,
    dragEvents: DragEvents[Msg]
)

final case class DragEvents[Msg](
    moveStart: String, // MoveablePiece => Option[(DragDrop.EffectAllowed, Decode.Value)] => Msg,
    moveCancel: Msg,
    touchStart: MoveablePiece => Msg,
    touchMove: (Float, Float) => Msg,
    touchEnd: (Float, Float) => Msg,
    noOp: Msg
)

final case class DropEvents[Msg](
    moveTargetChanged: (Int, Int), // => Option[(DragDrop.DropEffect, Decode.Value)] => Msg,
    moveCompleted: Msg
)
