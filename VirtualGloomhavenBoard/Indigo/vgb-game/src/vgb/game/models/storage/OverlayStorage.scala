package vgb.game.models.storage

import indigo.*

import vgb.common.*
import vgb.game.models.BoardOverlay
import indigo.shared.collections.Batch
import indigo.shared.datatypes.RGB
import vgb.game.models.TileRotation
import indigo.shared.datatypes.Point
import vgb.game.models.GameRules.rotateOverlay
import vgb.game.models.Room

final case class OverlayStorage(
    ref: OverlayStorageRef,
    id: Int,
    direction: String,
    cells: List[List[Int]]
) {
  def toModel(baseGame: BaseGame): Either[String, BoardOverlay] =
    decodeOverlay(baseGame).map { overlay =>
      val minCell = cells
        .foldLeft(Option.empty[Point])((p, c) =>
          val cp = Point(
            c.lift(0).getOrElse(0),
            c.lift(1).getOrElse(0)
          )

          p.map(cp.min).orElse(Some(cp))
        )
        .getOrElse(Point.zero)

      val minPoint = overlay.worldCells
        .foldLeft(Option.empty[Point])((p, c) => p.map(c.min).orElse(Some(c)))
        .getOrElse(Point.zero)

      overlay.copy(origin = minCell - minPoint)
    }

  private def decodeOverlay(baseGame: BaseGame) =
    (ref.`type`.toLowerCase(), ref.subType.map(st => st.toLowerCase())) match {
      case ("door", Some("corridor")) => decodeCorridor(baseGame)
      case ("difficult-terrain", _) =>
        decodeFromSubtype(
          baseGame,
          DifficultTerrain.values.asInstanceOf[Array[BoardOverlayType]]
        )
      case ("door", _) => decodeDoor(baseGame)
      case ("hazard", _) =>
        decodeFromSubtype(
          baseGame,
          Hazard.values.asInstanceOf[Array[BoardOverlayType]]
        )
      case ("highlight", _) => decodeHighlight(baseGame)
      case ("obstacle", _) =>
        decodeFromSubtype(
          baseGame,
          Obstacle.values.asInstanceOf[Array[BoardOverlayType]]
        )
      case ("rift", _)              => decodeRift(baseGame)
      case ("starting-location", _) => decodeStartingLocation(baseGame)
      case ("trap", _) =>
        decodeFromSubtype(
          baseGame,
          Trap.values.asInstanceOf[Array[BoardOverlayType]]
        )
      case ("treasure", Some("chest")) => decodeTreasureChest(baseGame)
      case ("treasure", Some("coin"))  => decodeTreasureCoin(baseGame)
      case ("token", _)                => decodeToken(baseGame)
      case ("wall", _) =>
        decodeFromSubtype(
          baseGame,
          Wall.values.asInstanceOf[Array[BoardOverlayType]]
        )
      case _ => Left(s"""Overlay type ${ref.`type`} does not exist for ${baseGame}""")
    }
    // TODO: We need to move the overlay once it's been created

  private def decodeCorridor(baseGame: BaseGame) =
    ref.material match {
      case Some(material) =>
        val overlayType = Corridor.values.find(c => c.baseGame == baseGame && c.codedName == material)
        overlayType match {
          case Some(o) =>
            Right(
              BoardOverlay(id, o, Point.zero, TileRotation.fromString(direction))
            )
          case None => Left(s"""Could not find corridor ${ref.material} for ${baseGame}""")
        }
      case None => Left("Material is missing for corridor")
    }

  private def decodeFromSubtype(baseGame: BaseGame, values: Array[BoardOverlayType]) =
    ref.subType match {
      case Some(subType) =>
        val overlayType = values.find(c => c.baseGame == baseGame && c.codedName == subType)
        overlayType match {
          case Some(o) =>
            Right(
              BoardOverlay(id, o, Point.zero, TileRotation.fromString(direction))
            )
          case None => Left(s"""Could not find ${ref.`type`} ${ref.subType} for ${baseGame}""")
        }
      case None => Left(s"""SubType is missing for ${ref.`type`}""")
    }

  private def decodeDoor(baseGame: BaseGame) =
    ref.subType match {
      case Some(subType) =>
        val links       = ref.links.getOrElse(List.empty)
        val overlayType = Door.values.find(c => c.baseGame == baseGame && c.codedName == subType)
        overlayType match {
          case Some(o) =>
            Right(
              BoardOverlay(
                id,
                o,
                Point.zero,
                TileRotation.fromString(direction),
                Some(
                  Batch.fromArray(
                    RoomType.values
                      .filter(r =>
                        r.baseGame == baseGame &&
                          links.exists(l => l == r.mapRef)
                      )
                  )
                )
              )
            )
          case None => Left(s"""Could not find door ${ref.subType} for ${baseGame}""")
        }
      case None => Left(s"""SubType is missing for door""")
    }

  private def decodeHighlight(baseGame: BaseGame) =
    ref.colour match {
      case Some(colour) =>
        Right(
          BoardOverlay(
            id,
            Highlight(baseGame, RGB.fromHexString(colour)),
            Point.zero,
            TileRotation.fromString(direction)
          )
        )
      case None => Left("Colour is missing for highlight")
    }

  private def decodeRift(baseGame: BaseGame) =
    Right(BoardOverlay(id, Rift(baseGame), Point.zero, TileRotation.fromString(direction)))

  private def decodeStartingLocation(baseGame: BaseGame) =
    StartingLocation.values.find(s => s.baseGame == baseGame) match {
      case Some(startingLocation) =>
        Right(BoardOverlay(id, startingLocation, Point.zero, TileRotation.fromString(direction)))
      case None => Left(s"""Cannot find starting location for ${baseGame}""")
    }

  def decodeTreasureChest(baseGame: BaseGame) =
    ref.id match {
      case Some(i) =>
        Right(
          BoardOverlay(
            id,
            Treasure.Chest(baseGame, TreasureChestType.fromString(i)),
            Point.zero,
            TileRotation.fromString(direction)
          )
        )
      case None => Left("Id not found for treasure chest")
    }

  def decodeTreasureCoin(baseGame: BaseGame) =
    ref.amount match {
      case Some(amount) =>
        Right(
          BoardOverlay(
            id,
            Treasure.Coin(baseGame, amount),
            Point.zero,
            TileRotation.fromString(direction)
          )
        )
      case None => Left("Amount not found for coin")
    }

  def decodeToken(baseGame: BaseGame) =
    ref.value match {
      case Some(c) =>
        Right(
          BoardOverlay(
            id,
            Token(baseGame, c),
            Point.zero,
            TileRotation.fromString(direction)
          )
        )
      case None => Left("Value not found for token")
    }
}

final case class OverlayStorageRef(
    `type`: String,
    subType: Option[String],
    material: Option[String],
    size: Option[Byte],
    links: Option[List[String]],
    colour: Option[String],
    value: Option[Char],
    id: Option[String],
    amount: Option[Byte]
)

object OverlayStorage:
  def fromModel(overlay: BoardOverlay) =
    OverlayStorage(
      getRefForType(overlay),
      overlay.id,
      overlay.rotation.toString(),
      overlay.worldCells.map(c => CellStorage.fromPoint(c).toList).toList
    )

  def fromModel(overlay: BoardOverlay, room: Room) =
    val newRotation =
      Math.max(overlay.rotation.toByte(), room.rotation.toByte()) -
        Math.min(overlay.rotation.toByte(), room.rotation.toByte())

    OverlayStorage(
      getRefForType(overlay),
      overlay.id,
      overlay.rotation.toString(),
      overlay
        .copy(rotation = TileRotation.fromByte(newRotation.toByte))
        .worldCells
        .map(c => CellStorage.fromPoint(c).toList)
        .toList
    )

  private def getRefForType(overlay: BoardOverlay) =
    overlay.overlayType match {
      case c: Corridor =>
        OverlayStorageRef(
          "door",
          "corridor",
          c.codedName,
          c.cells.length.toByte,
          overlay.linkedRooms.getOrElse(Batch.empty).toList.map(r => r.mapRef)
        )
      case o: DifficultTerrain => OverlayStorageRef("difficult-terrain", o.codedName)
      case d: Door =>
        OverlayStorageRef(
          "door",
          d.codedName,
          overlay.linkedRooms.getOrElse(Batch.empty).toList.map(r => r.toString())
        )
      case h: Hazard           => OverlayStorageRef("hazard", h.codedName)
      case h: Highlight        => OverlayStorageRef("highlight", h.colour)
      case o: Obstacle         => OverlayStorageRef("obstacle", o.codedName)
      case r: Rift             => OverlayStorageRef("rift")
      case s: StartingLocation => OverlayStorageRef("starting-location")
      case t: Trap             => OverlayStorageRef("trap", t.codedName)
      case t: Treasure =>
        t match {
          case t: Treasure.Chest => OverlayStorageRef("treasure", "chest", t.treasureType)
          case t: Treasure.Coin  => OverlayStorageRef("treasure", "coin", t.amount)
        }
      case Token(_, value) => OverlayStorageRef("token", value)
      case w: Wall         => OverlayStorageRef("wall", w.codedName)
    }

object OverlayStorageRef:
  def apply(overlayType: String): OverlayStorageRef =
    OverlayStorageRef(
      overlayType,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None
    )

  def apply(overlayType: String, subType: String): OverlayStorageRef =
    OverlayStorageRef(
      overlayType,
      Some(subType),
      None,
      None,
      None,
      None,
      None,
      None,
      None
    )

  def apply(overlayType: String, colour: RGB): OverlayStorageRef =
    OverlayStorageRef(
      overlayType,
      None,
      None,
      None,
      None,
      Some(colour.toHexString),
      None,
      None,
      None
    )

  def apply(overlayType: String, value: Char): OverlayStorageRef =
    OverlayStorageRef(
      overlayType,
      None,
      None,
      None,
      None,
      None,
      Some(value),
      None,
      None
    )

  def apply(overlayType: String, subType: String, mapRefs: List[String]): OverlayStorageRef =
    OverlayStorageRef(
      overlayType,
      Some(subType),
      None,
      None,
      Some(mapRefs),
      None,
      None,
      None,
      None
    )

  def apply(overlayType: String, subType: String, amount: Byte): OverlayStorageRef =
    OverlayStorageRef(
      overlayType,
      Some(subType),
      None,
      None,
      None,
      None,
      None,
      None,
      Some(amount)
    )

  def apply(overlayType: String, subType: String, treasureType: TreasureChestType): OverlayStorageRef =
    OverlayStorageRef(
      overlayType,
      Some(subType),
      None,
      None,
      None,
      None,
      None,
      Some(treasureType.toString()),
      None
    )

  def apply(
      overlayType: String,
      subType: String,
      material: String,
      size: Byte,
      mapRefs: List[String]
  ): OverlayStorageRef =
    OverlayStorageRef(
      overlayType,
      Some(subType),
      Some(material),
      Some(size),
      Some(mapRefs),
      None,
      None,
      None,
      None
    )
