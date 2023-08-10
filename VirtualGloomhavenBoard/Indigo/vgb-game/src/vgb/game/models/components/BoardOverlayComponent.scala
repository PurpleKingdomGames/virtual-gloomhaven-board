package vgb.game.models.components

import indigo.*
import vgb.game.models.BoardOverlay
import vgb.common.Hexagon
import vgb.game.models.TileRotation
import indigo.shared.scenegraph.Shape.Circle
import vgb.game.models.LayerDepths
import vgb.common.Treasure
import vgb.common.Door
import vgb.common.Token
import vgb.common.Flag

object BoardOverlayComponent:
  def render(boardOverlay: BoardOverlay, cellMap: Map[Point, Int]): Layer =
    val offset =
      Hexagon.oddRowToScreenPos(HexComponent.height, Point.zero) +
        Point((HexComponent.width * 0.5).toInt, (HexComponent.height * 0.5).toInt)

    val origin =
      Hexagon.oddRowToScreenPos(HexComponent.height, boardOverlay.origin)

    val rotationPoint =
      Hexagon.oddRowToScreenPos(HexComponent.height, boardOverlay.rotationPoint)
    val newRotation =
      Hexagon.oddRowToScreenPos(
        HexComponent.height,
        Hexagon
          .oddRowRotate(Vector2.fromPoint(boardOverlay.origin), Vector2.fromPoint(boardOverlay.rotationPoint), 1)
          .toPoint
      )

    (boardOverlay.overlayType match {
      case Token(_, char) =>
        val minimise = cellMap.get(boardOverlay.origin) match {
          case Some(v) if (v & Flag.MinimiseToken) != 0 =>
            true
          case _ => false
        }
        val graphicGroup = Group(
          Circle(Point(0, 0), (HexComponent.halfWidth * 0.75).toInt, Fill.Color(RGBA.White)),
          Circle(Point(0, 0), (HexComponent.halfWidth * 0.75 * 0.9).toInt, Fill.Color(RGBA.fromHexString("#913a3d")))
        )
        val token = renderToken(
          graphicGroup,
          offset,
          char.toString(),
          RGBA.White,
          false,
          minimise
        ).moveTo(origin)
        Layer(
          if minimise then
            token
              .moveBy(Point(HexComponent.quarterSize.toInt, -HexComponent.quarterSize.toInt))
          else token
        )
      case _ =>
        val graphicGroup =
          Graphic(
            boardOverlay.overlayType match {
              case _: Treasure.Coin => Size(90, 90)
              case _: Door          => Size(79, 90)
              case _                => Size(156, 90)
            },
            Material.Bitmap(
              (boardOverlay.rotation, boardOverlay.overlayType.verticalAssetName) match {
                case (TileRotation.Vertical, Some(verticalAsset))        => verticalAsset
                case (TileRotation.VerticalReverse, Some(verticalAsset)) => verticalAsset
                case _                                                   => boardOverlay.overlayType.assetName
              }
            )
          )
            .withRef(offset)
            .rotateTo(Radians.fromDegrees(60 * boardOverlay.rotation.toByte()))
        Layer(
          boardOverlay.overlayType match {
            case t: Treasure.Coin =>
              val minimise = cellMap.get(boardOverlay.origin) match {
                case Some(v) if (v & Flag.MinimiseCoin) != 0 =>
                  true
                case _ => false
              }
              val token = renderToken(
                graphicGroup,
                offset,
                t.amount.toString(),
                RGBA.fromHexString("#353535"),
                true,
                minimise
              ).moveTo(origin)

              if minimise then
                token
                  .moveBy(Point(HexComponent.quarterSize.toInt, HexComponent.quarterSize.toInt))
              else token
            case _ => graphicGroup.moveTo(origin)
          }
        )
    }).withDepth(boardOverlay.overlayType match {
      case t: Treasure =>
        t match {
          case _: Treasure.Coin => LayerDepths.CoinOrToken
          case _                => LayerDepths.Overlay
        }
      case t: Token => LayerDepths.CoinOrToken
      case _        => LayerDepths.Overlay
    })

  private def renderToken(
      graphic: Group | Graphic[Material.Bitmap],
      hexOffset: Point,
      text: String,
      colour: RGBA,
      addOutline: Boolean,
      minimise: Boolean
  ) =
    val textSize = 33
    var tokenText =
      TextBox(text, HexComponent.width.toInt, HexComponent.height)
        .withFontFamily(FontFamily("PirateOne"))
        .withFontSize(Pixels(textSize))
        .withColor(colour)
        .withStroke(TextStroke(if addOutline then RGBA.White else RGBA.Zero, Pixels(2)))
        .alignCenter
        .withPosition(Point(-hexOffset.x, -HexComponent.quarterSize.toInt))
    if minimise then
      Group(
        graphic
          .withScale(Vector2(0.5)),
        tokenText
          .withFontSize(Pixels((textSize * 0.5).toInt))
          .moveBy(0, (HexComponent.quarterSize * 0.5).toInt)
      )
    else Group(graphic, tokenText)
