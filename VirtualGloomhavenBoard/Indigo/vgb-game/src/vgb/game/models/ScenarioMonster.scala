package vgb.game.models

import vgb.common.MonsterType
import indigo.shared.datatypes.Point
import vgb.game.models.MonsterLevel

final case class ScenarioMonster(
    `type`: MonsterType,
    initialPosition: Point,
    twoPlayerLevel: MonsterLevel,
    threePlayerLevel: MonsterLevel,
    fourPlayerLevel: MonsterLevel
)
