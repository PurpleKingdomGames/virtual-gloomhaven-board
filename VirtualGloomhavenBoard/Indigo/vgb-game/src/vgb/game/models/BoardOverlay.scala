package vgb.game.models

import indigo.*
import vgb.common.BoardOverlayType

final case class BoardOverlay(id: Int, overlayType: BoardOverlayType, origin: Point, numRotations: Byte) {
  private val maxPoint   = overlayType.cells.foldLeft(Point.zero)((max, p) => max.max(p))
  private val minPoint   = overlayType.cells.foldLeft(maxPoint)((min, p) => min.min(p))
  lazy val rotationPoint = Point((maxPoint.x * 0.5).toInt, (maxPoint.y * 0.5).toInt)

  val worldCells =
    overlayType.cells
      .map(p =>
        Hexagon
          .evenRowRotate(
            Vector2.fromPoint(p),
            Vector2.fromPoint(minPoint),
            numRotations
          )
          .toPoint
          + origin
          + (if (origin.y & 1) == 1 && (p.y & 1) == 1 then Point(-1, 0) else Point.zero)
      )
}
