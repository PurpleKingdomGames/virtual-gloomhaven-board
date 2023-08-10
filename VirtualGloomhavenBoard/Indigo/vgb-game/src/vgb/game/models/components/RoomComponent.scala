package vgb.game.models.components

import indigo.*
import vgb.common.Hexagon
import indigo.shared.scenegraph.Shape.Circle
import indigo.shared.scenegraph.Shape.Box
import vgb.game.MoveStart
import vgb.game.models.LayerDepths
import vgb.game.models.Room
import indigo.shared.events.PointerEvent

object RoomComponent:
  def render(room: Room, camera: Camera, moveable: Boolean) =
    val offset =
      Hexagon.oddRowToScreenPos(HexComponent.height, Point.zero) +
        Point(HexComponent.width.toInt, (HexComponent.height * 0.5).toInt) -
        room.roomType.offset

    val origin =
      Hexagon.oddRowToScreenPos(HexComponent.height, room.origin)

    val rotationPoint =
      Hexagon.oddRowToScreenPos(HexComponent.height, room.rotationPoint)
    val newRotation =
      Hexagon.oddRowToScreenPos(
        HexComponent.height,
        Hexagon.oddRowRotate(Vector2.fromPoint(room.origin), Vector2.fromPoint(room.rotationPoint), 1).toPoint
      )

    Layer(
      Batch(
        Graphic(room.roomType.size, Material.Bitmap(room.roomType.assetName))
          .withRef(offset)
          .rotateTo(Radians.fromDegrees(60 * room.rotation.toByte()))
          .moveTo(origin)
      ) ++
        (if moveable then
           Batch(
             Graphic(Size(45, 45), Material.Bitmap(AssetName("move-icon")))
               .moveTo(origin - room.localToWorld(room.minPoint))
               .moveBy(Point(-(HexComponent.width * 0.5).toInt - 22, -(HexComponent.height * 0.5).toInt - 28))
               .enableEvents
               .withEventHandler((g, e) =>
                 e match {
                   case e: PointerEvent.PointerDown if g.bounds.contains(e.position + camera.position) =>
                     Some(MoveStart(room.origin, room))
                   case _ => None
                 }
               )
           )
         else Batch.empty)
    ).withDepth(LayerDepths.Room)
