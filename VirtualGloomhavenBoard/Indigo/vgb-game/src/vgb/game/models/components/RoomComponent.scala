package vgb.game.models.components

import indigo.*
import vgb.game.models.Room
import indigo.shared.scenegraph.Shape.Circle
import indigo.shared.scenegraph.Shape.Box
import org.scalajs.dom.PointerEvent
import vgb.game.MoveRoomStart
import vgb.game.models.Hexagon

object RoomComponent:
  def render(room: Room, camera: Camera, moveable: Boolean) =
    val offset =
      Hexagon.oddRowToScreenPos(HexComponent.height, Point.zero) -
        room.roomType.offset +
        Point(HexComponent.width.toInt, (HexComponent.height * 0.5).toInt)

    val origin =
      Hexagon.oddRowToScreenPos(HexComponent.height, room.origin)

    val rotationPoint =
      Hexagon.oddRowToScreenPos(HexComponent.height, room.rotationPoint)

    Layer(
      Batch(
        Graphic(room.roomType.size, Material.Bitmap(AssetName(room.roomType.mapRef)))
          .withRef(offset)
          .rotateTo(Radians.fromDegrees(60 * room.numRotations))
          .moveTo(origin),
        Circle(origin, 2, Fill.Color(RGBA.Red)),
        Circle(rotationPoint, 2, Fill.Color(RGBA.Blue))
      ) ++
        (if moveable then
           Batch(
             Graphic(Size(45, 45), Material.Bitmap(AssetName("move-icon")))
               .moveTo(origin)
               .moveBy(Point(-(HexComponent.width * 0.5).toInt - 22, -(HexComponent.height * 0.5).toInt - 28))
               .enableEvents
               .withEventHandler((g, e) =>
                 e match {
                   case MouseEvent.MouseDown(p, _) if g.bounds.contains(p + camera.position) =>
                     Some(MoveRoomStart(room.origin, room.roomType))
                   case _ => None
                 }
               )
           )
         else Batch.empty)
    )
