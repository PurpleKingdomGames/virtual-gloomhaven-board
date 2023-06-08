package vgb.game.models

import indigo.*
import vgb.common.*
import vgb.game.models.ScenarioMonster

object GameRules:
  def MoveMonster(
      newPos: Point,
      monster: ScenarioMonster,
      monsters: Batch[ScenarioMonster],
      cellMap: Map[Point, Int]
  ): Batch[ScenarioMonster] =
    if (IsValidMonsterPos(newPos, monster, cellMap))
      monsters.map(m => if m == monster then m.copy(initialPosition = newPos) else m)
    else
      monsters

  def MoveOverlay(
      newPos: Point,
      overlay: BoardOverlay,
      overlays: Batch[BoardOverlay],
      cellMap: Map[Point, Int]
  ): Batch[BoardOverlay] =
    if (IsValidOverlayPos(newPos, overlay, cellMap))
      overlays.map(o => if o.id == overlay.id then o.copy(origin = newPos) else o)
    else
      overlays

  def IsValidMonsterPos(newPos: Point, monster: ScenarioMonster, cellMap: Map[Point, Int]): Boolean =
    val newMap = cellMap.get(monster.initialPosition) match {
      case Some(v) =>
        if (v & Flag.Monster.value) != 0 then cellMap.updated(monster.initialPosition, v - Flag.Monster.value)
        else cellMap
      case None => cellMap
    }

    newMap.get(newPos) match {
      case Some(v) => (v & Flag.Monster.value) == 0
      case None    => true
    }

  def IsValidOverlayPos(newPos: Point, overlay: BoardOverlay, cellMap: Map[Point, Int]): Boolean =
    // A Coin can go anywhere
    if (overlay.overlayType.flag == Flag.Coin) true
    else
      val newMap = overlay.worldCells
        .foldLeft(cellMap)((m, c) =>
          m.get(c) match {
            case Some(v) =>
              if (v & overlay.overlayType.flag.value) != 0 then m.updated(c, v - overlay.overlayType.flag.value)
              else m
            case None => m
          }
        )

      overlay
        .copy(origin = newPos)
        .worldCells
        .exists(p =>
          newMap.get(p) match {
            case Some(v) => (v & overlay.overlayType.flag.value) != 0
            case None    => false
          }
        ) == false
