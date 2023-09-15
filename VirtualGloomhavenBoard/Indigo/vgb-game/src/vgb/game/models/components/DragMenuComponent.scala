package vgb.game.models.components

import vgb.game.models.sceneModels.CreatorModel
import vgb.common.DragDropSection
import vgb.common.DragDropItem
import vgb.common.RoomType
import vgb.common.Door
import vgb.common.Obstacle
import vgb.common.Treasure
import vgb.common.BaseGame
import vgb.common.MonsterType
import indigo.shared.collections.Batch

object DragMenuComponent:
  def getForModel(model: CreatorModel) =
    val currentRooms = model.rooms.map(r => r.roomType)
    Batch(
      DragDropSection(
        "Tiles",
        Batch(
          DragDropItem(RoomType.RoomA1A, false),
          DragDropItem(RoomType.RoomA1B, false)
        ).filter(i =>
          i.item match {
            case r: RoomType => currentRooms.contains(r) == false
            case _           => false
          }
        )
      ),
      DragDropSection(
        "Doors",
        Batch(
          DragDropItem(Door.Altar, false)
        )
      ),
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
