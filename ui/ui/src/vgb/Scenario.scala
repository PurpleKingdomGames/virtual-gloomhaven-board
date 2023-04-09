package vgb

object Scenario:

  val empty: Scenario =
    Scenario(0, "", MapTileData(MapTileRef.A1a, Nil, Nil, Nil, 0), 0, Nil)

// mapTileDataToOverlayList : MapTileData -> Dict String ( List BoardOverlay, List ScenarioMonster )
// mapTileDataToOverlayList data =
//     let
//         maxId =
//             case
//                 List.map (\o -> o.id) data.overlays
//                     |> List.maximum
//             of
//                 Just i ->
//                     i + 1

//                 Nothing ->
//                     1

//         initData =
//             case refToString data.ref of
//                 Just ref ->
//                     ( data.overlays
//                         ++ List.indexedMap
//                             (\i d ->
//                                 case d of
//                                     DoorLink subType dir ( x, y ) _ l ->
//                                         case subType of
//                                             Corridor _ Two ->
//                                                 let
//                                                     turns =
//                                                         case dir of
//                                                             DiagonalLeft ->
//                                                                 1

//                                                             DiagonalRight ->
//                                                                 2

//                                                             _ ->
//                                                                 0

//                                                     coords2 =
//                                                         rotate ( x + 1, y ) ( x, y ) turns
//                                                 in
//                                                 BoardOverlay (Door subType [ data.ref, l.ref ]) (maxId + i) dir [ ( x, y ), coords2 ]

//                                             _ ->
//                                                 BoardOverlay (Door subType [ data.ref, l.ref ]) (maxId + i) dir [ ( x, y ) ]
//                             )
//                             data.doors
//                     , data.monsters
//                     )
//                         |> singleton ref

//                 Nothing ->
//                     Dict.empty

//         doorData =
//             List.map
//                 (\d ->
//                     case d of
//                         DoorLink _ _ _ _ map ->
//                             mapTileDataToOverlayList map
//                 )
//                 data.doors
//                 |> List.foldl (\a b -> union a b) Dict.empty
//     in
//     union initData doorData

// mapTileDataToList : MapTileData -> Maybe ( ( Int, Int ), ( Int, Int ) ) -> ( List MapTile, BoardBounds )
// mapTileDataToList data maybeTurnAxis =
//     let
//         ( refPoint, origin ) =
//             case maybeTurnAxis of
//                 Just ( r, o ) ->
//                     ( r, o )

//                 Nothing ->
//                     ( ( 0, 0 ), ( 0, 0 ) )

//         mapTiles =
//             (getMapTileListByRef data.ref
//                 ++ getMapTileListByObstacle data data.overlays
//             )
//                 |> List.map (normaliseAndRotateMapTile data.turns refPoint origin)

//         doorTiles =
//             List.map (mapDoorDataToList data.ref refPoint origin data.turns) data.doors
//                 |> List.concat

//         allTiles =
//             mapTiles ++ doorTiles

//         boundingBox =
//             List.map (\m -> BoardBounds m.x m.x m.y m.y) allTiles
//                 |> List.foldl
//                     (\a b -> BoardBounds (min a.minX b.minX) (max a.maxX b.maxX) (min a.minY b.minY) (max a.maxY b.maxY))
//                     (BoardBounds 0 0 0 0)
//     in
//     ( allTiles, boundingBox )

  def getMapTileListByObstacle(mapTileData: MapTileData, boardOverlays: List[BoardOverlay]): List[MapTile] =
    boardOverlays
      .map(_.cells)
      .foldLeft(List.empty[(Int, Int)])(_ ++ _)
      .map { case (x, y) => MapTile(mapTileData.ref, x, y, mapTileData.turns, x, y, true, true) }

  def mapDoorDataToList(
      prevRef: MapTileRef,
      initRefPoint: (Int, Int),
      initOrigin: (Int, Int),
      initTurns: Int,
      doorData: DoorData
  ): List[MapTile] =
    doorData match
      case DoorData.DoorLink(_, _, r, origin, mapTileData) =>
        val refPoint =
          normaliseAndRotatePoint(initTurns, initRefPoint, initOrigin, r)

        val doorTile =
          MapTile(prevRef, refPoint._1, refPoint._2, initTurns, r._1, r._2, true, true)

        List(mapTileDataToList(mapTileData, (Option(refPoint, origin)))._1)
          ++ List(doorTile)

  def normaliseAndRotateMapTile(turns: Int, refPoint: (Int, Int), origin: (Int, Int), mapTile: MapTile): MapTile =
    val (rotatedX, rotatedY) =
      normaliseAndRotatePoint(turns, refPoint, origin, (mapTile.x, mapTile.y))

    mapTile.copy(x = rotatedX, y = rotatedY, turns = turns)

  def normaliseAndRotatePoint(turns: Int, refPoint: (Int, Int), origin: (Int, Int), tileCoord: (Int, Int)): (Int, Int) =
    val (refPointX, refPointY, refPointZ) =
      Hexagon.oddRowToCube(refPoint._1, refPoint._2)

    val (originX, originY, originZ) =
      Hexagon.oddRowToCube(origin._1, origin._2)

    val (tileCoordX, tileCoordY, tileCoordZ) =
      Hexagon.oddRowToCube(tileCoord._1, tileCoord._2)

    val initCoords =
      Hexagon.cubeToOddRow(
        tileCoordX - originX + refPointX,
        tileCoordY - originY + refPointY,
        tileCoordZ - originZ + refPointZ
      )

    Hexagon.rotate(initCoords, refPoint, turns)

final case class BoardBounds(minX: Int, maxX: Int, minY: Int, maxY: Int)

final case class MapTileData(
    ref: MapTileRef,
    doors: List[DoorData],
    overlays: List[BoardOverlay],
    monsters: List[ScenarioMonster],
    turns: Int
)

enum DoorData:
  case DoorLink(
      doorType: DoorSubType,
      directionType: BoardOverlayDirectionType,
      from: (Int, Int),
      to: (Int, Int),
      tileData: MapTileData
  )

final case class ScenarioMonster(
    monster: Monster,
    initialX: Int,
    initialY: Int,
    twoPlayer: MonsterLevel,
    threePlayer: MonsterLevel,
    fourPlayer: MonsterLevel
)

final case class Scenario(
    id: Int,
    title: String,
    mapTilesData: MapTileData,
    angle: Float,
    additionalMonsters: List[MonsterType]
)
