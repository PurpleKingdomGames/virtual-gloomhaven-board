package vgb.common

import indigo.*

enum TreasureChestType:
  case Normal(val number: Byte) extends TreasureChestType
  case Goal, Locked

trait BoardOverlayType:
  val baseGame: BaseGame
  val cells: Batch[Point]
  val name: String         = s"""${baseGame.shortName}-${this}"""
  val assetName: AssetName = AssetName(name)

enum DifficultTerrain(
    val baseGame: BaseGame,
    val cells: Batch[Point]
) extends BoardOverlayType:
  case Rubble extends DifficultTerrain(BaseGame.Gloomhaven, Batch(Point(0, 0)))

enum Door(
    val baseGame: BaseGame,
    val cells: Batch[Point]
) extends BoardOverlayType:
  case Altar extends Door(BaseGame.Gloomhaven, Batch(Point(0, 0)))

enum Hazard(val baseGame: BaseGame, val cells: Batch[Point]) extends BoardOverlayType:
  case HotCoals extends Hazard(BaseGame.Gloomhaven, Batch(Point(0, 0)))
  case Thorns   extends Hazard(BaseGame.Gloomhaven, Batch(Point(0, 0)))

enum Highlight(val baseGame: BaseGame, val colour: RGB) extends BoardOverlayType:
  val cells: Batch[Point] = Batch(Point(0, 0))
  case Red    extends Highlight(BaseGame.Gloomhaven, RGB.Red)
  case Orange extends Highlight(BaseGame.Gloomhaven, RGB.Orange)
  case Yellow extends Highlight(BaseGame.Gloomhaven, RGB.Yellow)
  case Green  extends Highlight(BaseGame.Gloomhaven, RGB.Green)
  case Blue   extends Highlight(BaseGame.Gloomhaven, RGB.Blue)
  case Indigo extends Highlight(BaseGame.Gloomhaven, RGB.Indigo)

enum Obstacle(val baseGame: BaseGame, val cells: Batch[Point]) extends BoardOverlayType:
  case Boulder2 extends Obstacle(BaseGame.Gloomhaven, Batch(Point(0, 0), Point(1, 0)))

final case class Rift(val baseGame: BaseGame) extends BoardOverlayType {
  val cells: Batch[Point] = Batch(Point(0, 0))
}

enum StartingLocation(val baseGame: BaseGame) extends BoardOverlayType:
  val cells: Batch[Point] = Batch(Point(0, 0))
  case Gloomhaven extends StartingLocation(BaseGame.Gloomhaven)

enum Trap(val baseGame: BaseGame, val cells: Batch[Point]) extends BoardOverlayType:
  case BearTrap extends Trap(BaseGame.Gloomhaven, Batch(Point(0, 0)))

enum Treasure(val baseGame: BaseGame) extends BoardOverlayType:
  val cells: Batch[Point] = Batch(Point(0, 0))
  case Chest(val treasureType: TreasureChestType) extends Treasure(BaseGame.Gloomhaven)
  case Coin(val amount: Byte)                     extends Treasure(BaseGame.Gloomhaven)

final case class Token(val baseGame: BaseGame, val letter: Char) extends BoardOverlayType:
  val cells: Batch[Point] = Batch(Point(0, 0))

enum Wall(val baseGame: BaseGame, val cells: Batch[Point]) extends BoardOverlayType:
  case Rock extends Wall(BaseGame.Gloomhaven, Batch(Point(0, 0)))
