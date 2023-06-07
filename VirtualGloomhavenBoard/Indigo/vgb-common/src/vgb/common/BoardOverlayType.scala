package vgb.common

import indigo.*

enum TreasureChestType:
  case Normal(val number: Byte) extends TreasureChestType
  case Goal, Locked

trait BoardOverlayType:
  val baseGame: BaseGame
  val cells: Batch[Point]
  val flag: Flag
  val name: String         = s"""${baseGame.shortName}-${this}"""
  val assetName: AssetName = AssetName(name)

enum DifficultTerrain(
    val baseGame: BaseGame,
    val cells: Batch[Point]
) extends BoardOverlayType:
  val flag: Flag = Flag.DifficultTerrain
  case Rubble extends DifficultTerrain(BaseGame.Gloomhaven, Batch(Point(0, 0)))

enum Door(
    val baseGame: BaseGame,
    val cells: Batch[Point]
) extends BoardOverlayType:
  val flag: Flag = Flag.Door
  case Altar extends Door(BaseGame.Gloomhaven, Batch(Point(0, 0)))

enum Hazard(val baseGame: BaseGame, val cells: Batch[Point]) extends BoardOverlayType:
  val flag: Flag = Flag.Hazard
  case HotCoals extends Hazard(BaseGame.Gloomhaven, Batch(Point(0, 0)))
  case Thorns   extends Hazard(BaseGame.Gloomhaven, Batch(Point(0, 0)))

enum Highlight(val baseGame: BaseGame, val colour: RGB) extends BoardOverlayType:
  val cells: Batch[Point] = Batch(Point(0, 0))
  val flag: Flag          = Flag.Highlight
  case Red    extends Highlight(BaseGame.Gloomhaven, RGB.Red)
  case Orange extends Highlight(BaseGame.Gloomhaven, RGB.Orange)
  case Yellow extends Highlight(BaseGame.Gloomhaven, RGB.Yellow)
  case Green  extends Highlight(BaseGame.Gloomhaven, RGB.Green)
  case Blue   extends Highlight(BaseGame.Gloomhaven, RGB.Blue)
  case Indigo extends Highlight(BaseGame.Gloomhaven, RGB.Indigo)

enum Obstacle(val baseGame: BaseGame, val cells: Batch[Point]) extends BoardOverlayType:
  val flag: Flag = Flag.Obstacle
  case Boulder2 extends Obstacle(BaseGame.Gloomhaven, Batch(Point(0, 0), Point(1, 0)))

final case class Rift(val baseGame: BaseGame) extends BoardOverlayType {
  val cells: Batch[Point] = Batch(Point(0, 0))
  val flag: Flag          = Flag.Rift
}

enum StartingLocation(val baseGame: BaseGame) extends BoardOverlayType:
  val cells: Batch[Point] = Batch(Point(0, 0))
  val flag: Flag          = Flag.StartingLocation
  case Gloomhaven extends StartingLocation(BaseGame.Gloomhaven)

enum Trap(val baseGame: BaseGame, val cells: Batch[Point]) extends BoardOverlayType:
  val flag: Flag = Flag.Trap
  case BearTrap extends Trap(BaseGame.Gloomhaven, Batch(Point(0, 0)))

enum Treasure(val baseGame: BaseGame, val flag: Flag) extends BoardOverlayType:
  val cells: Batch[Point] = Batch(Point(0, 0))
  case Chest(val treasureType: TreasureChestType) extends Treasure(BaseGame.Gloomhaven, Flag.TreasureChest)
  case Coin(val amount: Byte)                     extends Treasure(BaseGame.Gloomhaven, Flag.Coin)

final case class Token(val baseGame: BaseGame, val letter: Char) extends BoardOverlayType:
  val cells: Batch[Point] = Batch(Point(0, 0))
  val flag: Flag          = Flag.Token

enum Wall(val baseGame: BaseGame, val cells: Batch[Point]) extends BoardOverlayType:
  val flag: Flag = Flag.Wall
  case Rock extends Wall(BaseGame.Gloomhaven, Batch(Point(0, 0)))
