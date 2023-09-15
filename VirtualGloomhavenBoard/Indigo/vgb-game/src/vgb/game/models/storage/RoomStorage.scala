package vgb.game.models.storage

import indigo.*

import vgb.game.models.Room
import vgb.common.BaseGame
import vgb.common.RoomType
import indigo.shared.datatypes.Point
import vgb.game.models.TileRotation

final case class RoomStorage(
    data: RoomDataStorage,
    rotationPoint: CellStorage
) {
  def toModel(baseGame: BaseGame): Either[String, Room] =
    RoomType.fromRef(baseGame, data.ref) match {
      case Some(roomType) =>
        Right(
          Room(roomType, Point(data.origin.x, data.origin.y), TileRotation.fromByte(data.turns))
        )
      case None => Left(s"""Map tile ${data.ref} does not exist for ${baseGame}""")
    }
}

final case class RoomDataStorage(
    ref: String,
    origin: CellStorage,
    turns: Byte
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
