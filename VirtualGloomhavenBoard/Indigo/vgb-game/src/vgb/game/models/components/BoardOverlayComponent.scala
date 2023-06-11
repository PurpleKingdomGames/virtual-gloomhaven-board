package vgb.game.models.components

import indigo.*
import vgb.game.models.BoardOverlay
import vgb.game.models.Hexagon
import indigo.shared.scenegraph.Shape.Circle
import vgb.game.models.LayerDepths
import vgb.common.Treasure
import vgb.common.Token
import vgb.common.Flag

object BoardOverlayComponent:
  def render(boardOverlay: BoardOverlay, cellMap: Map[Point, Int]): Layer =
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

    val graphicGroup = Group(
      Graphic(
        boardOverlay.overlayType match {
          case t: Treasure.Coin => Size(90, 90)
          case _                => Size(156, 90)
        },
        Material.Bitmap(boardOverlay.overlayType.assetName)
      )
    )
      .withRef(offset)
      .rotateTo(Radians.fromDegrees(60 * boardOverlay.numRotations))
      .moveTo(origin)
    Layer(
      boardOverlay.overlayType match {
        case t: Treasure.Coin =>
          val textSize    = 33
          val textPadding = 5
          var coinGraphic = graphicGroup
            .addChild(
              TextBox(t.amount.toString(), HexComponent.width.toInt, HexComponent.height)
                .withFontFamily(FontFamily("PirateOne"))
                .withFontSize(Pixels(textSize))
                .withColor(RGBA.fromHexString("#353535"))
                .withStroke(TextStroke(RGBA.White, Pixels(2)))
                .alignCenter
                .moveBy(0, (HexComponent.halfSize - ((textSize * 0.75) - textPadding)).toInt)
            )

          cellMap.get(boardOverlay.origin) match {
            case Some(v)
                if (v & (Flag.All - Flag.Coin.value - Flag.Room.value - Flag.Hidden.value - Flag.Highlight.value)) != 0 =>
              coinGraphic
                .withScale(Vector2(0.5))
                .moveBy(Point(HexComponent.quarterSize.toInt, HexComponent.quarterSize.toInt))
            case _ => coinGraphic
          }
        case _ => graphicGroup
      }
    ).withDepth(boardOverlay.overlayType match {
      case t: Treasure =>
        t match {
          case _: Treasure.Coin => LayerDepths.CoinOrToken
          case _                => LayerDepths.Overlay
        }
      case t: Token => LayerDepths.CoinOrToken
      case _        => LayerDepths.Overlay
    })
