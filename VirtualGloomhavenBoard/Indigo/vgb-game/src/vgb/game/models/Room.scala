package vgb.game.models

import indigo.*
import vgb.common.Hexagon
import vgb.common.RoomType

final case class Room(
    roomType: RoomType,
    origin: Point,
    rotation: TileRotation
) extends Placeable {
  val maxPoint   = roomType.cells.foldLeft(Point.zero)((max, p) => max.max(p))
  val minPoint   = roomType.cells.foldLeft(maxPoint)((min, p) => min.min(p))
  val worldCells = roomType.cells.map(localToWorld)

  def rotate() =
    val rotatedOrigin =
      Hexagon.oddRowRotate(Vector2.fromPoint(origin), Vector2.fromPoint(rotationPoint), 1)
    this.copy(
      origin = rotatedOrigin.toPoint,
      rotation = rotation.nextRotation(false)
    )
}
