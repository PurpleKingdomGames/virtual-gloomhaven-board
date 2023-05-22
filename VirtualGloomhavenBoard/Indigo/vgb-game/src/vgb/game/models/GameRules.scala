package vgb.game.models

import indigo.*
import vgb.common.*
import vgb.game.models.ScenarioMonster

object GameRules:
  def MoveMonster(newPos: Point, monster: ScenarioMonster, monsters: Batch[ScenarioMonster]): Batch[ScenarioMonster] =
    if (monsters.exists(m => m != monster && m.initialPosition == newPos))
      monsters
    else
      monsters.map(m => if m == monster then m.copy(initialPosition = newPos) else m)
