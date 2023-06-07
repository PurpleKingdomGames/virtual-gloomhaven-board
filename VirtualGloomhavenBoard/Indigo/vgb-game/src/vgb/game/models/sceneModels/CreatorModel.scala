package vgb.game.models.sceneModels

import indigo.*
import vgb.game.models.Room
import vgb.game.models.ScenarioMonster

// Remove these later
import vgb.common.RoomType
import vgb.common.MonsterType
import vgb.common.Obstacle
import vgb.common.MonsterLevel
import vgb.game.models.BoardOverlay
import vgb.common.Flag

final case class CreatorModel(rooms: Batch[Room], monsters: Batch[ScenarioMonster], overlays: Batch[BoardOverlay]) {
  val cellMap: Map[Point, Int] = (rooms
    .foldLeft(Batch.empty[(Point, Int)])((batch, room) =>
      room.worldCells
        .foldLeft(batch)((b, cell) => b :+ (cell, Flag.Room.value))
    ) ++
    overlays
      .foldLeft(Batch.empty[(Point, Int)])((batch, overlay) =>
        overlay.worldCells
          .foldLeft(batch)((b, cell) => b :+ (cell, overlay.overlayType.flag.value))
      ) ++
    monsters
      .foldLeft(Batch.empty[(Point, Int)])((batch, monster) => batch :+ (monster.initialPosition, Flag.Monster.value)))
    .foldLeft(Map.empty)((map, d) =>
      d match {
        case (cell, value) =>
          map.get(cell) match {
            case Some(existingVal) => map.updated(cell, value | existingVal)
            case None              => map + (cell -> value)
          }
      }
    )
}

object CreatorModel:
  def apply(): CreatorModel =
    CreatorModel(
      Batch(
        Room(RoomType.RoomA1A, Point.zero, 0)
      ),
      Batch(
        ScenarioMonster(
          MonsterType.AestherAshblade,
          Point(2, 2),
          MonsterLevel.None,
          MonsterLevel.Normal,
          MonsterLevel.Elite
        )
      ),
      Batch(
        BoardOverlay(1, Obstacle.Boulder2, Point(0, 0), 0)
      )
    )
