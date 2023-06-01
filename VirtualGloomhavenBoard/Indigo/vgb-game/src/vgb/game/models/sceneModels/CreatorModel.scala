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

final case class CreatorModel(rooms: Batch[Room], monsters: Batch[ScenarioMonster], overlays: Batch[BoardOverlay])

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
