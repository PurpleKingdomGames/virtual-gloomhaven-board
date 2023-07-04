package vgb.game.models.storage

import vgb.game.models.Room

final case class RoomStorage(
    data: RoomDataStorage,
    rotationPoint: CellStorage
)

final case class RoomDataStorage(
    ref: String,
    origin: CellStorage,
    turns: Int
)

object RoomStorage:
  def fromModel(room: Room) =
    RoomStorage(
      RoomDataStorage(
        room.roomType.mapRef,
        CellStorage.fromPoint(room.origin),
        room.rotation.toByte()
      ),
      CellStorage.fromPoint(room.rotationPoint)
    )
