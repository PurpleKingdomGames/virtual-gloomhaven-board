package vgb.game.models.storage

import indigo.*
import vgb.game.models.Room
import vgb.common.RoomType
import vgb.game.models.BoardOverlay
import vgb.game.models.ScenarioMonster
import vgb.common.Door
import vgb.common.Corridor
import vgb.common.BaseGame

final case class DoorStorage(
    subType: String,
    material: Option[String],
    size: Option[Byte],
    direction: String,
    room1X: Int,
    room1Y: Int,
    room2X: Int,
    room2Y: Int,
    mapTileData: MapTileDataStorage
):
  def toModel(baseGame: BaseGame) =
    OverlayStorage(
      this.toOverlayStorageRef(),
      0,
      this.direction,
      List(List(this.room1X, this.room1Y))
    ).toModel(baseGame)

  def toOverlayStorageRef() =
    OverlayStorageRef(
      "door",
      Some(subType),
      material,
      size,
      Some(List(mapTileData.ref)),
      None,
      None,
      None,
      None
    )

object DoorStorage:
  def fromRooms(
      room: Room,
      overlays: Batch[(RoomType, BoardOverlay)],
      monsters: Batch[(RoomType, ScenarioMonster)],
      allRooms: Batch[Room],
      remainingRooms: Batch[Room]
  ): (Batch[DoorStorage], Batch[Room]) =
    val (doorsForRoom, remainingOverlays) = overlays
      .map(o =>
        if o._1 == room.roomType then
          o._2.overlayType match {
            case _: Door | _: Corridor => o._2
            case _                     => o
          }
        else o
      )
      .foldLeft((Batch.empty[BoardOverlay], Batch.empty[(RoomType, BoardOverlay)]))((cols, o) =>
        o match {
          case o: BoardOverlay             => (cols._1 :+ o, cols._2)
          case o: (RoomType, BoardOverlay) => (cols._1, cols._2 :+ o)
        }
      )

    doorsForRoom
      .flatMap(d =>
        d.linkedRooms match {
          case Some(links) =>
            Batch.fromArray(
              links.toArray.flatMap(l => allRooms.find(r => r.roomType == l).map(r => (d, r)))
            )
          case None => Batch.empty
        }
      )
      .foldLeft((Batch.empty[DoorStorage], remainingRooms))((data, link) =>
        (data, link) match {
          case ((doorBatch, roomsLeft), (overlay, roomRef)) =>
            val overlayStorage = OverlayStorage.fromModel(overlay)
            val roomPos        = roomRef.worldToLocal(room.localToWorld(overlay.origin))
            val (mapTile, remainingRooms) =
              MapTileDataStorage(roomRef, remainingOverlays, monsters, allRooms, roomsLeft.filter(r => r != roomRef))
            (
              doorBatch :+ DoorStorage(
                overlayStorage.ref.subType.getOrElse(""),
                overlayStorage.ref.material,
                overlayStorage.ref.size,
                overlayStorage.direction,
                overlay.origin.x,
                overlay.origin.y,
                roomPos.x,
                roomPos.y,
                mapTile
              ),
              remainingRooms
            )
        }
      )
