package vgb.game.models.sceneModels

import indigo.*
import vgb.game.models.DragData
import vgb.common.RoomType
import vgb.common.BoardOverlayType
import vgb.common.MonsterType

final case class CreatorViewModel(
    initialDragger: Option[RoomType | BoardOverlayType | MonsterType],
    dragging: Option[DragData]
) {
  val camera = Camera.Fixed(Point(-200, -200))
}

object CreatorViewModel:
  def apply(): CreatorViewModel = CreatorViewModel(None, None)
