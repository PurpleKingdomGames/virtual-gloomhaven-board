package vgb.game.models.components

import indigo.*
import indigo.shared.scenegraph.Shape.Box
import vgb.common.MonsterType
import vgb.game.models.Hexagon
import vgb.game.models.ScenarioMonster
import vgb.game.models.MonsterLevel
import indigo.shared.datatypes.Rectangle

object MonsterComponent:
  def render(monster: MonsterType, pos: Point): Graphic[Material.Bitmap] =
    val origin =
      Hexagon.evenRowToScreenPos(HexComponent.height, pos)
    val size = Size(180, 180)

    Graphic(size, Material.Bitmap(monster.assetName))
      .withRef((size / 2).toPoint)
      .moveTo(origin)
      .scaleBy(Vector2(HexComponent.height.toDouble / size.height.toDouble))

  def render(monster: ScenarioMonster): Group =
    val origin =
      Hexagon.evenRowToScreenPos(HexComponent.height, monster.initialPosition)
    val quarterSize = Math.ceil(HexComponent.halfWidth * 0.5).toInt
    val playerMarker = Box(
      Rectangle(
        Math.ceil(HexComponent.halfWidth).toInt,
        Math.ceil(HexComponent.halfWidth).toInt
      ),
      Fill.None
    )
      .withRef(Point(quarterSize, quarterSize))
      .withPosition(origin)
    Group(
      this.render(monster.monsterType, monster.initialPosition),
      playerMarker
        .withRotation(Radians.fromDegrees(32))
        .moveBy(Point(-Math.ceil(HexComponent.halfWidth).toInt, -Math.floor(HexComponent.quarterSize).toInt))
        .moveBy(Point(-5, -5))
        .withFill(getFillForLevel(monster.twoPlayerLevel)),
      playerMarker
        .withRotation(Radians.fromDegrees(60))
        .moveBy(Point(Math.ceil(HexComponent.halfWidth).toInt, -Math.floor(HexComponent.quarterSize).toInt))
        .moveBy(Point(10, -5))
        .withFill(getFillForLevel(monster.threePlayerLevel)),
      playerMarker
        .moveBy(Point(0, Math.ceil(HexComponent.halfSize).toInt))
        .moveBy(Point(0, 10))
        .withFill(getFillForLevel(monster.fourPlayerLevel))
    )

  private def getFillForLevel(level: MonsterLevel) =
    level match {
      case MonsterLevel.None   => Fill.Color(RGBA.Black)
      case MonsterLevel.Normal => Fill.Color(RGBA.White)
      case MonsterLevel.Elite  => Fill.Color(RGBA.fromHexString("#d9c200"))
    }
