package vgb.game.models.components

import indigo.*
import vgb.game.models.BoardOverlay
import vgb.game.models.Hexagon
import indigo.shared.scenegraph.Shape.Circle
import vgb.game.models.LayerDepths
import vgb.common.Treasure
import vgb.common.Token

object BoardOverlayComponent:
  def render(boardOverlay: BoardOverlay): Layer =
    val offset =
      Hexagon.evenRowToScreenPos(HexComponent.height, Point.zero) +
        Point((HexComponent.width * 0.5).toInt, (HexComponent.height * 0.5).toInt)

    val origin =
      Hexagon.evenRowToScreenPos(HexComponent.height, boardOverlay.origin)

    val rotationPoint =
      Hexagon.evenRowToScreenPos(HexComponent.height, boardOverlay.rotationPoint)
    val newRotation =
      Hexagon.evenRowToScreenPos(
        HexComponent.height,
        Hexagon
          .evenRowRotate(Vector2.fromPoint(boardOverlay.origin), Vector2.fromPoint(boardOverlay.rotationPoint), 1)
          .toPoint
      )
    Layer(
      Batch(
        Graphic(Size(156, 90), Material.Bitmap(boardOverlay.overlayType.assetName))
          .withRef(offset)
          .rotateTo(Radians.fromDegrees(60 * boardOverlay.numRotations))
          .moveTo(origin)
      )
    ).withDepth(boardOverlay.overlayType match {
      case t: Treasure =>
        t match {
          case _: Treasure.Coin => LayerDepths.CoinOrToken
          case _                => LayerDepths.Overlay
        }
      case t: Token => LayerDepths.CoinOrToken
      case _        => LayerDepths.Overlay
    })
