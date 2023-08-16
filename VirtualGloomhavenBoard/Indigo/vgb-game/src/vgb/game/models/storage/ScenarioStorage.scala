package vgb.game.models.storage

import indigo.*
import io.circe.*
import io.circe.generic.auto.*
import io.circe.parser.*
import io.circe.syntax.*
import vgb.common.RoomType
import vgb.game.models.ScenarioMonster
import vgb.game.models.BoardOverlay
import vgb.game.models.Room
import vgb.game.models.sceneModels.CreatorModel
import vgb.common.Corridor
import vgb.common.Hexagon
import vgb.common.Door
import vgb.common.StartingLocation

final case class ScenarioStorage(
    id: Int,
    title: String,
    mapTileData: Option[MapTileDataStorage],
    angle: Float,
    additionalMonsters: List[String]
) {
  override def toString(): String =
    this.asJson.deepDropNullValues.noSpaces
}

object ScenarioStorage:
  def fromModel(model: CreatorModel) =
    val roomCellMap = model.rooms
      .map(r => r.worldCells.map(c => (c, r)))
      .flatten
      .toMap

    val overlays = assignExtendedCorridors(assignOverlaysToRoom(model.overlays, roomCellMap))
    val startLocationRooms = overlays
      .filter(o =>
        o._2.overlayType match {
          case _: StartingLocation => true
          case _                   => false
        }
      )
      .map(o => o._1)
    val monsters = assignMonstersToRoom(model.monsters, roomCellMap)
    val orderedRooms = model.rooms
      .sortBy(r => startLocationRooms.contains(r.roomType))
      .toList

    orderedRooms match {
      case head :: tail =>
        ScenarioStorage(
          model.scenarioTitle,
          head,
          overlays,
          monsters,
          Batch.fromList(tail)
        )
      case _ =>
        ScenarioStorage(
          0,
          model.scenarioTitle,
          None,
          0,
          List.empty
        )
    }

  def apply(
      title: String,
      startingRoom: Room,
      overlays: Batch[(RoomType, BoardOverlay)],
      monsters: Batch[(RoomType, ScenarioMonster)],
      rooms: Batch[Room]
  ): ScenarioStorage =
    ScenarioStorage(
      0,
      title,
      Some(
        MapTileDataStorage(
          startingRoom,
          overlays,
          monsters,
          rooms :+ startingRoom,
          rooms :+ startingRoom
        )._1
      ),
      0,
      List.empty
    )

  private def assignOverlaysToRoom(
      overlays: Batch[BoardOverlay],
      roomCellMap: Map[Point, Room]
  ): Batch[(Room, BoardOverlay) | BoardOverlay] =
    overlays.map { o =>
      // Get the rooms at the origin, and in all hexes around the origin
      val connectedRooms =
        Batch.fromIndexedSeq(
          (IndexedSeq(o.origin) ++
            // Get all
            (0 until 6)
              .map(i => Hexagon.oddRowRotate(o.origin.toVector, o.origin.moveBy(0, 1).toVector, i.toByte).toPoint))
            .flatMap(cell => roomCellMap.get(cell))
            .distinct
        )

      // If even 1 room is found, we use the first room (closest to origin)
      connectedRooms.headOption
        .map { room =>
          (
            room,
            o.overlayType match {
              case _: Door | _: Corridor =>
                // Link the door or corridor to all surrounding rooms and update
                // the origin to the rooms local position
                o.copy(
                  linkedRooms = Some(
                    Batch.fromArray(
                      connectedRooms.map(r => r.roomType).toArray.distinct
                    )
                  ),
                  origin = room.worldToLocal(o.origin)
                )
              case _ =>
                // Update the overlays position so it is relative to the room's local position
                o.copy(origin = room.worldToLocal(o.origin))
            }
          )
        }
        .getOrElse(o)
    }

  private def assignMonstersToRoom(
      monsters: Batch[ScenarioMonster],
      roomCellMap: Map[Point, Room]
  ): Batch[(RoomType, ScenarioMonster)] =
    Batch.fromArray(monsters.toArray.flatMap { m =>
      // Get the rooms at the origin, and in all hexes around the origin
      val connectedRooms =
        Batch.fromIndexedSeq(
          (IndexedSeq(m.initialPosition) ++
            // Get all
            (0 until 6)
              .map(i =>
                Hexagon
                  .oddRowRotate(m.initialPosition.toVector, m.initialPosition.moveBy(0, 1).toVector, i.toByte)
                  .toPoint
              ))
            .flatMap(cell => roomCellMap.get(cell))
            .distinct
        )

      // If even 1 room is found, we use the first room (closest to origin)
      connectedRooms.headOption.map(room =>
        (room.roomType, m.copy(initialPosition = room.worldToLocal(m.initialPosition)))
      )
    })

  private def assignExtendedCorridors(
      initialOverlays: Batch[(Room, BoardOverlay) | BoardOverlay]
  ): Batch[(RoomType, BoardOverlay)] =
    val unassignedOverlays: Batch[BoardOverlay] = Batch.fromArray(
      initialOverlays.toArray.flatMap(o =>
        o match {
          case o: BoardOverlay =>
            o.overlayType match
              case _: Corridor => Some(o)
              case _           => None
          case _ => None
        }
      )
    )

    val overlays = Batch.fromArray(
      initialOverlays.toArray.flatMap(o =>
        o match {
          case o: (Room, BoardOverlay) => Some(o)
          case _                       => None
        }
      )
    )

    val corridors = overlays
      .filter(o =>
        o._2.overlayType match {
          case _: Corridor => true
          case _           => false
        }
      )
      .toList

    val nonCorridors = overlays.filter(o =>
      o._2.overlayType match {
        case _: Corridor => false
        case _           => true
      }
    )

    corridors match {
      case head :: tail =>
        assignCorridor(
          head._1,
          head._2,
          unassignedOverlays,
          Batch.fromList(tail),
          nonCorridors.map(o => (o._1.roomType, o._2))
        )
      case _ => overlays.map(o => (o._1.roomType, o._2))
    }

  private def assignCorridor(
      room: Room,
      corridor: BoardOverlay,
      unassignedCorridors: Batch[BoardOverlay],
      unchecked: Batch[(Room, BoardOverlay)],
      attributed: Batch[(RoomType, BoardOverlay)]
  ): Batch[(RoomType, BoardOverlay)] =
    val worldPositions = corridor.worldCells
      .map(p =>
        val w = room.localToWorld(p)
        Batch.fromIndexedSeq(
          (0 until 6)
            .map(i => Hexagon.oddRowRotate(w.toVector, w.moveBy(0, 1).toVector, i.toByte).toPoint)
        )
      )
      .flatten

    val newCorridors =
      unassignedCorridors
        .filter(c => c.worldCells.exists(p => worldPositions.contains(p)))

    val newUnchecked =
      (unchecked ++
        newCorridors
          .map(c => (room, c.copy(linkedRooms = corridor.linkedRooms, origin = room.worldToLocal(c.origin))))).toList

    newUnchecked match {
      case head :: tail =>
        head match {
          case (headRoom, headOverlay) =>
            assignCorridor(
              headRoom,
              headOverlay,
              unassignedCorridors.filter(c => newCorridors.contains(c) == false),
              Batch.fromList(tail),
              attributed :+ (room.roomType, corridor)
            )
        }
      case _ => attributed :+ (room.roomType, corridor)
    }
