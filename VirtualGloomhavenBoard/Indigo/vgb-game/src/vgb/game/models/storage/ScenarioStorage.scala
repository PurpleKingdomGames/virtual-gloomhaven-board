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
import vgb.common.BaseGame
import vgb.game.models.TileRotation

final case class ScenarioStorage(
    id: Int,
    title: String,
    baseGame: Option[String],
    mapTileData: Option[MapTileDataStorage],
    angle: Float,
    additionalMonsters: List[String]
) {
  override def toString(): String =
    this.asJson.deepDropNullValues.noSpaces

  def toCreatorModel(): Either[String, CreatorModel] =
    val baseGame = this.baseGame match {
      case Some(value) =>
        BaseGame.values.find(g => g.toString().toLowerCase() == value) match {
          case Some(bg) => bg
          case None     => BaseGame.Gloomhaven
        }
      case None => BaseGame.Gloomhaven
    }

    val model = CreatorModel(this.title, baseGame)

    this.mapTileData match {
      case Some(data) => decodeMapTileData(Point.zero, Point.zero, data, model)
      case None       => Right(model)
    }

  private def decodeMapTileData(
      origin: Point,
      localOffset: Point,
      data: MapTileDataStorage,
      model: CreatorModel
  ): Either[String, CreatorModel] =
    RoomType.fromRef(model.baseGame, data.ref) match {
      case Some(roomType) =>
        val room     = Room(roomType, origin.moveBy(localOffset), TileRotation.fromByte(data.turns))
        val overlays = data.overlays.map(o => o.toModel(model.baseGame).map(o => o.copy(origin = room.localToWorld(o.origin))))
        val monsters = data.monsters.map(m => m.toModel(model.baseGame).map(m => m.copy(initialPosition = room.localToWorld(m.initialPosition))))

        val errors =
          overlays.collect { case Left(e) => e } ++
            monsters.collect { case Left(e) => e }

        errors.headOption match {
          case Some(value) => Left(value)
          case _ =>
            val newModel = model.copy(
              rooms =
                if model.rooms.exists(r => r.roomType == roomType) then model.rooms
                else model.rooms :+ room,
              overlays = model.overlays ++ Batch.fromList(overlays.collect { case Right(o) => o }),
              monsters = model.monsters ++ Batch.fromList(monsters.collect { case Right(m) => m })
            )

            decodeDoorData(room, data.doors, newModel)
        }

      case None => Left(s"""Map tile ${data.ref} does not exist for ${baseGame}""")
    }

  private def decodeDoorData(room: Room, doors: List[DoorStorage], model: CreatorModel): Either[String, CreatorModel] =
    doors
      .foldLeft(Right(model).asInstanceOf[Either[String, CreatorModel]])((m, d) =>
        m match {
          case Right(newModel) =>
            val door = d
              .toModel(model.baseGame)
              .map(d1 => d1.copy(origin = room.localToWorld(Point(d.room1X, d.room1Y))))

            door match {
              case Right(d2) =>
                decodeMapTileData(
                  d2.origin,
                  Point(d.room2X, d.room2Y),
                  d.mapTileData,
                  newModel.copy(overlays = newModel.overlays :+ d2)
                )
              case Left(d2) => Left(d2)
            }
          case Left(_) => m
        }
      )
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
          model.baseGame,
          head,
          overlays,
          monsters,
          Batch.fromList(tail)
        )
      case _ =>
        ScenarioStorage(
          0,
          model.scenarioTitle,
          model.baseGame match {
            case BaseGame.Gloomhaven => None
            case _                   => Some(model.baseGame.toString().toLowerCase())
          },
          None,
          0,
          List.empty
        )
    }

  def apply(
      title: String,
      baseGame: BaseGame,
      startingRoom: Room,
      overlays: Batch[(RoomType, BoardOverlay)],
      monsters: Batch[(RoomType, ScenarioMonster)],
      rooms: Batch[Room]
  ): ScenarioStorage =
    ScenarioStorage(
      0,
      title,
      baseGame match {
        case BaseGame.Gloomhaven => None
        case _                   => Some(baseGame.toString().toLowerCase())
      },
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

  def fromJson(json: String): Either[String, ScenarioStorage] =
    decode[ScenarioStorage](json) match {
      case Right(value) => Right(value)
      case Left(err)    => Left(err.getMessage())
    }

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
