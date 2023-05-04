package vgb.game.models.components

import indigo.*
import vgb.game.models.Room

object RoomComponent:
  def render(room: Room, moveable: Boolean) =
    val origin =
      HexComponent.oddRowToScreenPos(room.origin) +
        Point(-HexComponent.width.toInt, -(HexComponent.height * 0.5).toInt) +
        room.roomType.offset
    Layer(
      Batch(
        Graphic(room.roomType.size, Material.Bitmap(AssetName(room.roomType.mapRef)))
          .moveTo(origin)
      ) ++
        (if moveable then
           Batch(
             Graphic(Size(45, 45), Material.Bitmap(AssetName("move-icon")))
               .moveTo(origin)
               .moveBy(Point(16, -28))
           )
         else Batch.empty)
    )
