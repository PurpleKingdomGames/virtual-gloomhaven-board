package vgb.game.models

import indigo.*
import vgb.common.*
import vgb.game.models.ScenarioMonster

object GameRules:
  def MoveMonster(newPos: Point, monster: ScenarioMonster, monsters: Batch[ScenarioMonster]): Batch[ScenarioMonster] =
    if (IsValidMonsterPos(newPos, monster, monsters))
      monsters.map(m => if m == monster then m.copy(initialPosition = newPos) else m)
    else
      monsters

  def MoveOverlay(newPos: Point, overlay: BoardOverlay, overlays: Batch[BoardOverlay]): Batch[BoardOverlay] =
    if (IsValidOverlayPos(newPos, overlay, overlays))
      overlays.map(o => if o.id == overlay.id then o.copy(origin = newPos) else o)
    else
      overlays

  def IsValidMonsterPos(newPos: Point, monster: ScenarioMonster, monsters: Batch[ScenarioMonster]): Boolean =
    monsters.exists(m => m != monster && m.initialPosition == newPos) == false

  def IsValidOverlayPos(newPos: Point, overlay: BoardOverlay, overlays: Batch[BoardOverlay]): Boolean =
    overlays.exists(o => o.id != overlay.id && o.worldCells.contains(newPos)) == false
