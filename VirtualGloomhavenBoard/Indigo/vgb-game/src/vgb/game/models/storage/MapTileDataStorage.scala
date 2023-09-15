package vgb.game.models.storage

import indigo.*
import io.circe.*
import io.circe.generic.auto.*
import io.circe.parser.*
import io.circe.syntax.*
import vgb.game.models.Room
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

implicit val encodeMapTileDataStorage: Encoder[MapTileDataStorage] = new Encoder[MapTileDataStorage] {
  final def apply(a: MapTileDataStorage): Json = Json.obj(
    ("ref", Json.fromString(a.ref)),
    ("doors", Json.fromValues(a.doors.map(d => d.asJson))),
    ("overlays", Json.fromValues(a.overlays.map(o => o.asJson))),
    ("monsters", Json.fromValues(a.monsters.map(m => m.asJson))),
    ("turns", Json.fromInt(a.turns.toInt))
  )
}

implicit val decodeMapTileDataStorage: Decoder[MapTileDataStorage] = new Decoder[MapTileDataStorage] {
  final def apply(c: HCursor): Decoder.Result[MapTileDataStorage] =
    for {
      ref      <- c.downField("ref").as[String]
      doors    <- c.downField("doors").as[List[DoorStorage]]
      overlays <- c.downField("overlays").as[List[OverlayStorage]]
      monsters <- c.downField("monsters").as[List[ScenarioMonsterStorage]]
      turns    <- c.downField("turns").as[Byte]
    } yield new MapTileDataStorage(ref, doors, overlays, monsters, turns)
}

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
              case o: BoardOverlay             => (cols._1 :+ OverlayStorage.fromModel(o, room), cols._2)
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
      if roomNeedsOutput then getDoorsForRoom(room, overlays, remainingMonsters, allRooms, remainingRooms)
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

  private def getDoorsForRoom(
      room: Room,
      overlays: Batch[(RoomType, BoardOverlay)],
      remainingMonsters: Batch[(RoomType, ScenarioMonster)],
      allRooms: Batch[Room],
      remainingRooms: Batch[Room]
  ): (Batch[DoorStorage], Batch[Room]) =
    DoorStorage.fromRooms(room, overlays, remainingMonsters, allRooms, remainingRooms) match {
      case d if d._1.isEmpty =>
        // No doors can be found, so attempt to find doors that are linked, but not yet associated with this room
        DoorStorage.fromRooms(
          room,
          overlays
            .map(o =>
              o._2.linkedRooms match {
                // This door has this room as a match, so we can use it
                case Some(r) if r.contains(room.roomType) =>
                  // Get the original room the door was associated as
                  allRooms.find(r => r.roomType == o._1) match {
                    case Some(originalRoom) =>
                      (
                        // Change the associated room type to this room
                        room.roomType,
                        // Move the door to the new room origin
                        o._2.copy(origin = room.worldToLocal(originalRoom.localToWorld(o._2.origin)))
                      )
                    case None => o
                  }
                case _ => o
              }
            ),
          remainingMonsters,
          allRooms,
          remainingRooms
        )
      case d => d
    }
