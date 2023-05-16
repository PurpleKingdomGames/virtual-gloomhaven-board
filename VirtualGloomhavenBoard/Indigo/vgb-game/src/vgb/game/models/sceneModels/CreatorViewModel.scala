package vgb.game.models.sceneModels

import indigo.*
import vgb.game.models.Room
import vgb.common.RoomType

final case class CreatorViewModel(dragging: Option[(Point, RoomType)]) {
  val camera = Camera.Fixed(Point(-200, -200))
}

object CreatorViewModel:
  def apply(): CreatorViewModel = CreatorViewModel(None)
