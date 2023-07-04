package vgb.game.models

import indigo.*

trait Placeable:
  val rotation: TileRotation
  val origin: Point
  val minPoint: Point
  val maxPoint: Point
  val worldCells: Batch[Point]
  lazy val rotationPoint = localToWorld(
    Point((maxPoint.x * 0.5).toInt, (maxPoint.y * 0.5).toInt)
  )

  def localToWorld(localPoint: Point) =
    val rotatedPoint = Hexagon
      .evenRowRotate(
        Vector2.fromPoint(localPoint),
        Vector2.fromPoint(minPoint),
        rotation.toByte()
      )
      .toPoint

    rotatedPoint
      + origin
      + (if (origin.y & 1) == 1 && (rotatedPoint.y & 1) == 1 then Point(-1, 0) else Point.zero)
