package vgb.common

import indigo.*

enum TreasureChestType:
  override def toString(): String = this match {
    case Goal      => "goal"
    case Locked    => "locked"
    case Normal(i) => i.toString()
  }

  case Normal(val number: Byte) extends TreasureChestType
  case Goal, Locked

object TreasureChestType:
  def fromString(str: String) =
    str.toLowerCase() match {
      case "goal"   => Goal
      case "locked" => Locked
      case _ =>
        str.toByteOption match {
          case Some(b) => Normal(b)
          case None    => Normal(0)
        }
    }

trait BoardOverlayType:
  val baseGame: BaseGame
  val cells: Batch[Point]
  val flag: Flag
  val verticalAssetName: Option[AssetName]
  val name: String = this
    .toString()
    .toCharArray()
    .foldLeft("")((s, c) => if c >= '0' && c <= 'Z' then s + " " + c else s + c)
    .trim()
  val codedName            = name.toLowerCase().replace(" ", "-")
  val assetName: AssetName = AssetName(s"""${baseGame.shortName}-${codedName}""")

enum DifficultTerrain(
    val baseGame: BaseGame,
    val cells: Batch[Point]
) extends BoardOverlayType:
  val flag: Flag        = Flag.DifficultTerrain
  val verticalAssetName = None
  case Rubble extends DifficultTerrain(BaseGame.Gloomhaven, Batch(Point(0, 0)))

enum Corridor(
    val baseGame: BaseGame,
    val cells: Batch[Point]
) extends BoardOverlayType:
  val flag: Flag        = Flag.Corridor
  val verticalAssetName = None
  case Altar extends Corridor(BaseGame.Gloomhaven, Batch(Point(0, 0)))

enum Door(
    val baseGame: BaseGame,
    val cells: Batch[Point],
    val verticalAssetName: Option[AssetName]
) extends BoardOverlayType:
  val flag: Flag = Flag.Door
  case Altar extends Door(BaseGame.Gloomhaven, Batch(Point(0, 0)), None)

enum Hazard(val baseGame: BaseGame, val cells: Batch[Point]) extends BoardOverlayType:
  val flag: Flag        = Flag.Hazard
  val verticalAssetName = None
  case HotCoals extends Hazard(BaseGame.Gloomhaven, Batch(Point(0, 0)))
  case Thorns   extends Hazard(BaseGame.Gloomhaven, Batch(Point(0, 0)))

final case class Highlight(val baseGame: BaseGame, val colour: RGB) extends BoardOverlayType:
  val cells: Batch[Point] = Batch(Point(0, 0))
  val flag: Flag          = Flag.Highlight
  val verticalAssetName   = None

object Highlight:
  val Red    = Highlight(BaseGame.Gloomhaven, RGB.Red)
  val Orange = Highlight(BaseGame.Gloomhaven, RGB.Orange)
  val Yellow = Highlight(BaseGame.Gloomhaven, RGB.Yellow)
  val Green  = Highlight(BaseGame.Gloomhaven, RGB.Green)
  val Blue   = Highlight(BaseGame.Gloomhaven, RGB.Blue)
  val Indigo = Highlight(BaseGame.Gloomhaven, RGB.Indigo)

enum Obstacle(val baseGame: BaseGame, val cells: Batch[Point]) extends BoardOverlayType:
  val flag: Flag        = Flag.Obstacle
  val verticalAssetName = None
  case Boulder2 extends Obstacle(BaseGame.Gloomhaven, Batch(Point(0, 0), Point(1, 0)))

final case class Rift(val baseGame: BaseGame) extends BoardOverlayType {
  val cells: Batch[Point] = Batch(Point(0, 0))
  val flag: Flag          = Flag.Rift
  val verticalAssetName   = None
}

enum StartingLocation(val baseGame: BaseGame) extends BoardOverlayType:
  val cells: Batch[Point] = Batch(Point(0, 0))
  val flag: Flag          = Flag.StartingLocation
  val verticalAssetName   = None
  case Gloomhaven extends StartingLocation(BaseGame.Gloomhaven)

enum Trap(val baseGame: BaseGame, val cells: Batch[Point]) extends BoardOverlayType:
  val flag: Flag        = Flag.Trap
  val verticalAssetName = None
  case BearTrap extends Trap(BaseGame.Gloomhaven, Batch(Point(0, 0)))

enum Treasure(val flag: Flag) extends BoardOverlayType:
  val cells: Batch[Point] = Batch(Point(0, 0))
  val verticalAssetName   = None

  override def toString(): String = this match
    case Chest(_, _) => "Chest"
    case Coin(_, _)  => "Coin"

  case Chest(val baseGame: BaseGame, val treasureType: TreasureChestType) extends Treasure(Flag.TreasureChest)
  case Coin(val baseGame: BaseGame, val amount: Byte)                     extends Treasure(Flag.Coin)

final case class Token(val baseGame: BaseGame, val letter: Char) extends BoardOverlayType:
  val cells: Batch[Point]         = Batch(Point(0, 0))
  val flag: Flag                  = Flag.Token
  val verticalAssetName           = None
  override def toString(): String = s"""Token (${letter})"""

enum Wall(val baseGame: BaseGame, val cells: Batch[Point]) extends BoardOverlayType:
  val flag: Flag        = Flag.Wall
  val verticalAssetName = None
  case Rock extends Wall(BaseGame.Gloomhaven, Batch(Point(0, 0)))
