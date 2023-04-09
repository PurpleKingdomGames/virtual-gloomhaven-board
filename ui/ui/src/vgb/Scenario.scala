package vgb

object Scenario:

  val empty: Scenario =
    Scenario(0, "", MapTileData(MapTileRef.A1a, Nil, Nil, Nil, 0), 0, Nil)

  def mapTileDataToOverlayList(data: MapTileData): Map[String, (List[BoardOverlay], List[ScenarioMonster])] =
    val maxId =
      data.overlays.map(_.id).maxOption match
        case Some(i) =>
          i + 1

        case None =>
          1

    val initData: Map[String, (List[BoardOverlay], List[ScenarioMonster])] =
      BoardMapTile.refToString(data.ref) match
        case Some(ref) =>
          val t =
            (
              data.overlays ++
                data.doors.zipWithIndex.map { case (d, i) =>
                  d match {
                    case DoorData.DoorLink(subType, dir, (x, y), _, l) =>
                      subType match {
                        case DoorSubType.Corridor(_, CorridorSize.Two) =>
                          val turns =
                            dir match {
                              case BoardOverlayDirectionType.DiagonalLeft =>
                                1

                              case BoardOverlayDirectionType.DiagonalRight =>
                                2

                              case _ =>
                                0
                            }

                          val coords2 =
                            Hexagon.rotate((x + 1, y), (x, y), turns)

                          BoardOverlay(
                            BoardOverlayType.Door(subType, List(data.ref, l.ref)),
                            (maxId + i),
                            dir,
                            List((x, y), coords2)
                          )

                        case _ =>
                          BoardOverlay(
                            BoardOverlayType.Door(subType, List(data.ref, l.ref)),
                            (maxId + i),
                            dir,
                            List((x, y))
                          )
                      }
                  }
                },
              data.monsters
            )

          Map(ref -> t)

        case None =>
          Map.empty

    val doorData =
      data.doors
        .map { case DoorData.DoorLink(_, _, _, _, map) =>
          mapTileDataToOverlayList(map)
        }
        .foldLeft(Map.empty[String, (List[BoardOverlay], List[ScenarioMonster])]) { case (a, b) => a ++ b }

    initData ++ doorData

  def mapTileDataToList(
      data: MapTileData,
      maybeTurnAxis: Option[((Int, Int), (Int, Int))]
  ): (List[MapTile], BoardBounds) =
    val (refPoint, origin) =
      maybeTurnAxis match
        case Some(r, o) =>
          (r, o)

        case None =>
          ((0, 0), (0, 0))

    val mapTiles =
      (BoardMapTile.getMapTileListByRef(data.ref)
        ++ getMapTileListByObstacle(data, data.overlays)).map(mapTile =>
        normaliseAndRotateMapTile(data.turns, refPoint, origin, mapTile)
      )

    val doorTiles =
      data.doors.flatMap(door => mapDoorDataToList(data.ref, refPoint, origin, data.turns, door))

    val allTiles =
      mapTiles ++ doorTiles

    val boundingBox =
      allTiles
        .map(m => BoardBounds(m.x, m.x, m.y, m.y))
        .foldLeft(BoardBounds(0, 0, 0, 0)) { case (a, b) =>
          BoardBounds(
            Math.min(a.minX, b.minX),
            Math.max(a.maxX, b.maxX),
            Math.min(a.minY, b.minY),
            Math.max(a.maxY, b.maxY)
          )
        }

    (allTiles, boundingBox)

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

        mapTileDataToList(mapTileData, (Option(refPoint, origin)))._1
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
