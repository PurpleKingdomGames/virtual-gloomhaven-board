package vgb.game.models

import indigo.*
import vgb.common.*
import vgb.game.models.ScenarioMonster

object GameRules:
  def moveMonster(
      newPos: Point,
      monster: ScenarioMonster,
      monsters: Batch[ScenarioMonster],
      cellMap: Map[Point, Int]
  ): Batch[ScenarioMonster] =
    if (isValidMonsterPos(newPos, monster, cellMap))
      monsters.filter(m => m != monster)
        :+ monster.copy(initialPosition = newPos)
    else
      monsters

  def moveOverlay(
      newPos: Point,
      overlay: BoardOverlay,
      overlays: Batch[BoardOverlay],
      cellMap: Map[Point, Int]
  ): Batch[BoardOverlay] =
    if (isValidOverlayPos(newPos, overlay, cellMap))
      overlays.filter(o => o.id != overlay.id)
        :+ overlay.copy(
          origin = newPos,
          id = if overlay.id == 0 then (overlays.foldLeft(0)((i, o) => Math.max(o.id, i))) + 1 else overlay.id
        )
    else
      overlays

  def rotateOverlay(
      overlay: BoardOverlay,
      overlays: Batch[BoardOverlay],
      cellMap: Map[Point, Int]
  ): Batch[BoardOverlay] =
    val newMap = overlay.worldCells.foldLeft(cellMap)((m, c) =>
      m.get(c) match {
        case Some(v) if (v & overlay.overlayType.flag.value) != 0 =>
          m.updated(c, v - overlay.overlayType.flag.value)
        case _ => m
      }
    )

    val newOverlay = nextValidOverlayRotation(overlay.rotation, overlay, newMap)
    overlays.map(o => if o.id == overlay.id then newOverlay else o)

  def isValidMonsterPos(newPos: Point, monster: ScenarioMonster, cellMap: Map[Point, Int]): Boolean =
    val newMap = cellMap.get(monster.initialPosition) match {
      case Some(v) if (v & Flag.Monster.value) != 0 =>
        cellMap.updated(monster.initialPosition, v - Flag.Monster.value)
      case _ => cellMap
    }

    newMap.get(newPos) match {
      case Some(v) => (v & (Flag.Hidden.value | Flag.Monster.value)) == 0
      case None    => true
    }

  def isValidOverlayPos(newPos: Point, overlay: BoardOverlay, cellMap: Map[Point, Int]): Boolean =
    val newMap = overlay.worldCells
      .foldLeft(cellMap)((m, c) =>
        m.get(c) match {
          case Some(v) if (v & overlay.overlayType.flag.value) != 0 =>
            m.updated(c, v - overlay.overlayType.flag.value)
          case _ => m
        }
      )

    canPlaceOverlay(overlay.copy(origin = newPos), newMap)

  def nextValidOverlayRotation(
      initialRotation: TileRotation,
      overlay: BoardOverlay,
      cellMap: Map[Point, Int]
  ): BoardOverlay =
    val rotatedOverlay = overlay.rotate()
    if rotatedOverlay.overlayType.flag == Flag.Coin || initialRotation == rotatedOverlay.rotation then
      rotatedOverlay
    else if canPlaceOverlay(rotatedOverlay, cellMap) then rotatedOverlay
    else nextValidOverlayRotation(initialRotation, rotatedOverlay, cellMap)

  private def canPlaceOverlay(overlay: BoardOverlay, cellMap: Map[Point, Int]) =
    overlay.worldCells
      .exists(p =>
        cellMap.get(p) match {
          case Some(v) =>
            // Coins can be placed anywhere except on hidden tiles
            if overlay.overlayType.flag == Flag.Coin then (v & Flag.Hidden.value) != 0
            // Other overlays cannot be placed on the same squares
            else (v & (Flag.Hidden.value | overlay.overlayType.flag.value)) != 0
          case None => false
        }
      ) == false
