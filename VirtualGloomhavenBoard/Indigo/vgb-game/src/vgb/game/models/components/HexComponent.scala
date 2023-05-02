package vgb.game.models.components

import indigo.*
import indigoextras.geometry.Vertex
import indigo.shared.scenegraph.Shape.Line
import indigo.shared.scenegraph.Shape.Polygon
import indigo.shared.scenegraph.Shape.Circle

object HexComponent:
  private val sqrtThree   = Math.sqrt(3)
  private val baseQ       = sqrtThree / 3
  private val oneOver3    = 1.0 / 3
  private val twoOver3    = 2.0 / 3
  private val threeOver2  = 3.0 / 2
  private val size        = 90
  private val halfSize    = size * 0.5
  private val quarterSize = size * 0.25
  private val rectWidth   = sqrtThree * halfSize
  private val halfWidth   = rectWidth * 0.5
  private val polygon = Polygon(
    Batch(
      Point(0, -Math.floor(halfSize).toInt),                              // Top tip
      Point(Math.floor(halfWidth).toInt, -Math.floor(quarterSize).toInt), // Right-top corner of rectangle
      Point(Math.floor(halfWidth).toInt, Math.ceil(quarterSize).toInt),   // Right-bottom corner of rectangle
      Point(0, Math.ceil(halfSize).toInt),                                // Bottom tip
      Point(-Math.ceil(halfWidth).toInt, Math.ceil(quarterSize).toInt),   // Left-bottom corner of rectangle,
      Point(-Math.ceil(halfWidth).toInt, -Math.floor(quarterSize).toInt)  // Left-top corner of rectangle
    ),
    Fill.Color(RGBA.Green),
    Stroke.Black
  )

  def render(position: Point): Group =
    Group(
      polygon
        // 0,0 position is the top left
        .moveTo(oddRowToScreenPos(position))
        // For screen position to co-ordinates to work correctly, 0,0 needs to be centre
        .moveBy((polygon.size.width * -0.5).toInt, (polygon.size.height * -0.5).toInt),
      Circle(oddRowToScreenPos(position), 2, Fill.Color(RGBA.Red))
    )

  def screenPosToCube(pos: Point) = {
    val q = (baseQ * pos.x.toDouble - (oneOver3 * pos.y.toDouble)) / halfSize.toDouble
    val r = (twoOver3 * pos.y.toDouble) / halfSize.toDouble
    cubeRound(axialToCube(Vector2(q, r)))
  }

  def screenPosToOddRow(pos: Point) =
    cubeToOddRow(screenPosToCube(pos))

  def axialToScreenPos(pos: Vector2) =
    Point(
      (halfSize * (sqrtThree * pos.x + (sqrtThree * 0.5) * pos.y)).toInt,
      (halfSize * threeOver2 * pos.y).toInt
    )

  def oddRowToScreenPos(pos: Point) =
    axialToScreenPos(oddRowToAxial(pos))

  def oddRowToAxial(pos: Point) =
    Vector2(
      pos.x - (pos.y - (pos.y.toInt & 1)) * 0.5,
      pos.y
    )

  def cubeToOddRow(pos: Vector3) =
    Vector2(pos.x + (pos.y - (pos.y.toInt & 1)) * 0.5, pos.y)

  def axialToCube(pos: Vector2) =
    Vector3(pos.x, pos.y, -pos.x - pos.y)

  def cubeRound(pos: Vector3) = pos match {
    case Vector3(fracQ, fracR, fracS) =>
      val q = Math.round(fracQ).toDouble
      val r = Math.round(fracR).toDouble
      val s = Math.round(fracS).toDouble

      val qDiff = Math.abs(q - fracQ)
      val rDiff = Math.abs(r - fracR)
      val sDiff = Math.abs(s - fracS)

      if qDiff > rDiff && qDiff > sDiff then Vector3(-r - s, r, s)
      else if rDiff > sDiff then Vector3(q, -q - s, s)
      else Vector3(q, r, -q - r)
  }
