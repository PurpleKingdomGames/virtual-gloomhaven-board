package vgb.game.models.components

import vgb.game.models.sceneModels.CreatorModel
import vgb.common.DragDropSection
import vgb.common.DragDropItem
import vgb.common.RoomType
import vgb.common.Obstacle
import vgb.common.Treasure
import vgb.common.BaseGame
import vgb.common.MonsterType
import indigo.shared.collections.Batch

object DragMenuComponent:
  def getForModel(mode: CreatorModel) =
    Batch(
      DragDropSection(
        "Tiles",
        Batch(
          DragDropItem(RoomType.RoomA1A, false)
        )
      ),
      DragDropSection("Doors", Batch.empty),
      DragDropSection(
        "Obstacles",
        Batch(
          DragDropItem(Obstacle.Boulder2, false)
        )
      ),
      DragDropSection(
        "Misc.",
        Batch(
          DragDropItem(Treasure.Coin(BaseGame.Gloomhaven, 1), false)
        )
      ),
      DragDropSection(
        "Monsters",
        Batch(
          DragDropItem(MonsterType.AestherAshblade, false)
        )
      ),
      DragDropSection("Bosses", Batch.empty)
    )
