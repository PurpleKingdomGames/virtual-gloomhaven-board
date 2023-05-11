package vgb.game.models.components

import indigo.*
import indigo.shared.scenegraph.Shape.Line
import indigo.shared.scenegraph.Shape.Polygon
import indigo.shared.scenegraph.Shape.Circle
import indigo.shared.datatypes.Fill.Color
import vgb.game.models.Hexagon

object HexComponent:
  val height              = 90
  private val sqrtThree   = Math.sqrt(3)
  private val halfSize    = height * 0.5
  private val quarterSize = height * 0.25
  val width               = sqrtThree * halfSize
  private val halfWidth   = width * 0.5
  private val polygon = Polygon(
    Batch(
      Point(0, -Math.floor(halfSize).toInt),                              // Top tip
      Point(Math.floor(halfWidth).toInt, -Math.floor(quarterSize).toInt), // Right-top corner of rectangle
      Point(Math.floor(halfWidth).toInt, Math.ceil(quarterSize).toInt),   // Right-bottom corner of rectangle
      Point(0, Math.ceil(halfSize).toInt),                                // Bottom tip
      Point(-Math.ceil(halfWidth).toInt, Math.ceil(quarterSize).toInt),   // Left-bottom corner of rectangle,
      Point(-Math.ceil(halfWidth).toInt, -Math.floor(quarterSize).toInt)  // Left-top corner of rectangle
    ),
    Fill.Color(RGBA.None),
    Stroke.Black
  )

  def render(position: Point, fill: RGBA = RGBA(0, 0, 0, 0)): Group =
    Group(
      polygon
        .withFill(Fill.Color(fill))
        // 0,0 position is the top left
        .moveTo(Hexagon.oddRowToScreenPos(height, position))
        // For screen position to co-ordinates to work correctly, 0,0 needs to be centre
        .moveBy((polygon.size.width * -0.5).toInt, (polygon.size.height * -0.5).toInt)
    )
