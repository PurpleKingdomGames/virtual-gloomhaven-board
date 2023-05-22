package vgb.game.models.sceneModels

import indigo.*
import vgb.game.models.Room
import vgb.game.models.ScenarioMonster

// Remove these later
import vgb.common.RoomType
import vgb.common.MonsterType
import vgb.game.models.MonsterLevel

final case class CreatorModel(rooms: Batch[Room], monsters: Batch[ScenarioMonster])

object CreatorModel:
  def apply(): CreatorModel =
    CreatorModel(
      Batch(
        Room(RoomType.RoomA1A, Point.zero, 0)
      ),
      Batch(
        ScenarioMonster(
          MonsterType.AestherAshblade,
          Point(1, 0),
          MonsterLevel.None,
          MonsterLevel.Normal,
          MonsterLevel.Elite
        )
      )
    )
