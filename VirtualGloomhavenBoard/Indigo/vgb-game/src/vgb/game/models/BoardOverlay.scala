package vgb.game.models

import indigo.*
import vgb.common.BoardOverlayType

final case class BoardOverlay(
    id: Int,
    overlayType: BoardOverlayType,
    origin: Point,
    numRotations: Byte
) extends Placeable {
  val maxPoint   = overlayType.cells.foldLeft(Point.zero)((max, p) => max.max(p))
  val minPoint   = overlayType.cells.foldLeft(maxPoint)((min, p) => min.min(p))
  val worldCells = overlayType.cells.map(localToWorld)

  def rotate() =
    val rotatedOrigin =
      Hexagon.evenRowRotate(Vector2.fromPoint(origin), Vector2.fromPoint(rotationPoint), 1)
    this.copy(
      origin = rotatedOrigin.toPoint,
      numRotations = if numRotations == 5 then 0 else (numRotations + 1).toByte
    )
}
