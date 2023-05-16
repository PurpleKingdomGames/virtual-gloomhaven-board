package vgb.game.models

import indigo.*
import vgb.common.RoomType

final case class Room(roomType: RoomType, origin: Point, numRotations: Byte) {
  private val maxPoint   = roomType.cells.foldLeft(Point.zero)((max, p) => max.max(p))
  private val minPoint   = roomType.cells.foldLeft(maxPoint)((min, p) => min.min(p))
  lazy val rotationPoint = Point((maxPoint.x * 0.5).toInt, (maxPoint.y * 0.5).toInt)

  val worldCells = {
    IndigoLogger.consoleLog(origin.toString())
    roomType.cells
      .map(p =>
        Hexagon
          .oddRowRotate(
            Vector2.fromPoint(p),
            Vector2.fromPoint(minPoint),
            numRotations
          )
          .toPoint
          + origin
          + (if (origin.y & 1) == 1 && (p.y & 1) == 1 then Point(-1, 0) else Point.zero)
      )
  }
}
