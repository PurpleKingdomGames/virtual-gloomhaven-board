package vgb.game.models

import vgb.common.MonsterType
import indigo.shared.datatypes.Point
import vgb.common.MonsterLevel

final case class ScenarioMonster(
    monsterType: MonsterType,
    initialPosition: Point,
    twoPlayerLevel: MonsterLevel,
    threePlayerLevel: MonsterLevel,
    fourPlayerLevel: MonsterLevel
)
