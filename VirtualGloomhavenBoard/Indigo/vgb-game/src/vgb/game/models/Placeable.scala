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

    if rotation.toByte() == 0 then worldPoint + offset
    else
      Hexagon
        .oddRowRotate(
          Vector2.fromPoint(worldPoint + offset),
          Vector2.fromPoint(origin),
          rotation.toByte()
        )
        .toPoint

  def worldToLocal(worldPoint: Point) =
    if rotation.toByte() == 0 then
      val localPoint = worldPoint - origin
      val offset = Point(
        if (localPoint.y & 1) == 1 && (worldPoint.y & 1) == 0 then 1
        else 0,
        0
      )
      localPoint - offset
    else
      var rotatedPoint = Hexagon
        .oddRowRotate(
          Vector2.fromPoint(worldPoint),
          Vector2.fromPoint(origin),
          (6 - rotation.toByte().toInt).toByte
        )
        .toPoint

      var localPoint = rotatedPoint - origin
      val offset = Point(
        if (localPoint.y & 1) == 1 && (rotatedPoint.y & 1) == 0 then 1
        else 0,
        0
      )

      localPoint - offset
