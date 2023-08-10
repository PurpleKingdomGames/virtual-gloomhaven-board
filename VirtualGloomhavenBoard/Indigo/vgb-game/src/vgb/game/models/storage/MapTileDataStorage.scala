package vgb.game.models.storage

import vgb.game.models.Room
import indigo.shared.collections.Batch
import vgb.common.RoomType
import vgb.game.models.BoardOverlay
import vgb.game.models.ScenarioMonster

final case class MapTileDataStorage(
    ref: String,
    doors: List[DoorStorage],
    overlays: List[OverlayStorage],
    monsters: List[ScenarioMonsterStorage],
    turns: Byte
)

object MapTileDataStorage:
  def apply(
      room: Room,
      overlays: Batch[(RoomType, BoardOverlay)],
      monsters: Batch[(RoomType, ScenarioMonster)],
      allRooms: Batch[Room],
      remainingRooms: Batch[Room]
  ): (MapTileDataStorage, Batch[Room]) =
    val roomNeedsOutput = remainingRooms.contains(room)
    val (roomOverlays, remainingOverlays) =
      if roomNeedsOutput then
        overlays
          .map(o => if o._1 == room.roomType then o._2 else o)
          .foldLeft((Batch.empty[OverlayStorage], Batch.empty[(RoomType, BoardOverlay)]))((cols, o) =>
            o match {
              case o: BoardOverlay             => (cols._1 :+ OverlayStorage.fromModel(o), cols._2)
              case o: (RoomType, BoardOverlay) => (cols._1, cols._2 :+ o)
            }
          )
      else (Batch.empty, overlays)

    val (roomMonsters, remainingMonsters) =
      if roomNeedsOutput then
        monsters
          .map(o => if o._1 == room.roomType then o._2 else o)
          .foldLeft((Batch.empty[ScenarioMonsterStorage], Batch.empty[(RoomType, ScenarioMonster)]))((cols, o) =>
            o match {
              case o: ScenarioMonster             => (cols._1 :+ ScenarioMonsterStorage.fromModel(o), cols._2)
              case o: (RoomType, ScenarioMonster) => (cols._1, cols._2 :+ o)
            }
          )
      else (Batch.empty, monsters)

    val (doors, newRemainingRooms) =
      if roomNeedsOutput then
        DoorStorage.fromRooms(room, remainingOverlays, remainingMonsters, allRooms, remainingRooms)
      else (Batch.empty, remainingRooms)

    (
      MapTileDataStorage(
        room.roomType.mapRef,
        doors.toList,
        roomOverlays.toList,
        roomMonsters.toList,
        room.rotation.toByte()
      ),
      newRemainingRooms.filter(r => r != room)
    )
