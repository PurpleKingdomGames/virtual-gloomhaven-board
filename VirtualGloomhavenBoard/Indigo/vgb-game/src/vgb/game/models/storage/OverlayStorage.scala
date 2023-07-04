package vgb.game.models.storage

import vgb.common.*
import vgb.game.models.BoardOverlay
import indigo.shared.collections.Batch
import indigo.shared.datatypes.RGB

final case class OverlayStorage(
    ref: OverlayStorageRef,
    id: Int,
    direction: String,
    cells: List[List[Int]]
)

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

  private def getRefForType(overlay: BoardOverlay) =
    overlay.overlayType match {
      case c: Corridor =>
        OverlayStorageRef(
          "door",
          "corridor",
          c.name,
          c.cells.length.toByte,
          overlay.linkedRooms.getOrElse(Batch.empty).toList.map(r => r.toString())
        )
      case o: DifficultTerrain => OverlayStorageRef("difficult-terrain", o.name)
      case d: Door =>
        OverlayStorageRef(
          "door",
          d.name,
          overlay.linkedRooms.getOrElse(Batch.empty).toList.map(r => r.toString())
        )
      case h: Hazard           => OverlayStorageRef("hazard", h.name)
      case h: Highlight        => OverlayStorageRef("highlight", h.colour)
      case o: Obstacle         => OverlayStorageRef("obstacle", o.name)
      case r: Rift             => OverlayStorageRef("rift")
      case s: StartingLocation => OverlayStorageRef("starting-location")
      case t: Trap             => OverlayStorageRef("trap", t.name)
      case t: Treasure =>
        t match {
          case t: Treasure.Chest => OverlayStorageRef("treasure", "chest", t.treasureType)
          case t: Treasure.Coin  => OverlayStorageRef("treasure", "coin", t.amount)
        }
      case Token(_, value) => OverlayStorageRef("token", value)
      case w: Wall         => OverlayStorageRef("wall", w.name)
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
      Some(subType.toLowerCase().replace(" ", "-")),
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
      Some(subType.toLowerCase().replace(" ", "-")),
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
      Some(subType.toLowerCase().replace(" ", "-")),
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
      Some(subType.toLowerCase().replace(" ", "-")),
      None,
      None,
      None,
      None,
      None,
      Some(treasureType match {
        case TreasureChestType.Goal      => "goal"
        case TreasureChestType.Locked    => "locked"
        case TreasureChestType.Normal(i) => i.toString()
      }),
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
      Some(subType.toLowerCase().replace(" ", "-")),
      Some(material.toLowerCase().replace(" ", "-")),
      Some(size),
      Some(mapRefs),
      None,
      None,
      None,
      None
    )
