package vgb.game.models

import indigo.*
import vgb.common.BoardOverlayType
import vgb.common.Hexagon
import vgb.common.RoomType

final case class BoardOverlay(
    id: Int,
    overlayType: BoardOverlayType,
    origin: Point,
    rotation: TileRotation,
    linkedRooms: Option[Batch[RoomType]]
) extends Placeable {
  val maxPoint   = overlayType.cells.foldLeft(Point.zero)((max, p) => max.max(p))
  val minPoint   = overlayType.cells.foldLeft(maxPoint)((min, p) => min.min(p))
  val worldCells = overlayType.cells.map(localToWorld)

  def rotate() =
    IndigoLogger.consoleLog(Vector2.fromPoint(rotationPoint).toString())

    val rotatedOrigin =
      Hexagon.oddRowRotate(Vector2.fromPoint(origin), Vector2.fromPoint(rotationPoint), 1)

    IndigoLogger.consoleLog(rotatedOrigin.toString())
    this.copy(
      origin = rotatedOrigin.toPoint,
      rotation = rotation.nextRotation(overlayType.verticalAssetName != None)
    )
}

object BoardOverlay:
  def apply(
      id: Int,
      overlayType: BoardOverlayType,
      origin: Point,
      rotation: TileRotation
  ): BoardOverlay =
    BoardOverlay(id, overlayType, origin, rotation, None)
