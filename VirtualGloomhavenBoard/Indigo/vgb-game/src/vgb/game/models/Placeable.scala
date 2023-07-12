package vgb.game.models

import indigo.*
import vgb.common.Hexagon

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
    val worldPoint = localPoint + origin
    val offset = Point(
      if (localPoint.y & 1) == 1 && (worldPoint.y & 1) == 0 then 1
      else 0,
      0
    )
    Hexagon
      .oddRowRotate(
        Vector2.fromPoint(worldPoint + offset),
        Vector2.fromPoint(origin),
        rotation.toByte()
      )
      .toPoint
