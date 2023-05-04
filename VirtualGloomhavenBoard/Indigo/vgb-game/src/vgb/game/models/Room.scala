package vgb.game.models

import indigo.*

final case class Room(roomType: RoomType, origin: Point, numRotations: Byte) {
  private val maxPoint = roomType.cells.foldLeft(Point.zero)((max, p) => max.max(p))
  private val minPoint = roomType.cells.foldLeft(maxPoint)((min, p) => min.min(p))
  lazy val rotationPoint = {
    val midPoint = (maxPoint - minPoint).abs;

    Point((midPoint.x * 0.5).toInt, (midPoint.y * 0.5).toInt)
  }

  def toWorldPos(localPos: Point) =
    // Later we need to rotate this about the origin, then move it
    localPos + origin
}
