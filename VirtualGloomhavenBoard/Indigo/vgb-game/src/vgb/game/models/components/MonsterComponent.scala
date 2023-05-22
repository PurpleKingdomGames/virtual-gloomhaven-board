package vgb.game.models.components

import indigo.*
import vgb.common.MonsterType
import vgb.game.models.Hexagon
import vgb.game.models.ScenarioMonster

object MonsterComponent:
  def render(monster: MonsterType, pos: Point): Graphic[Material.Bitmap] =
    val origin =
      Hexagon.evenRowToScreenPos(HexComponent.height, pos)
    val size = Size(180, 180)

    IndigoLogger.consoleLog(Vector2(size.height.toDouble / HexComponent.height.toDouble).toString())

    Graphic(size, Material.Bitmap(monster.assetName))
      .withRef((size / 2).toPoint)
      .moveTo(origin)
      .scaleBy(Vector2(HexComponent.height.toDouble / size.height.toDouble))

  def render(monster: ScenarioMonster): Group =
    Group(
      this.render(monster.`type`, monster.initialPosition)
    )
