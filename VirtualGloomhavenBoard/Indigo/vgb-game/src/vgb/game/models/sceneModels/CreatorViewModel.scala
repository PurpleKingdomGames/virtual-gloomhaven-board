package vgb.game.models.sceneModels

import indigo.*
import vgb.game.models.Room
import vgb.common.RoomType
import vgb.game.models.ScenarioMonster

final case class CreatorViewModel(dragging: Option[(Point, RoomType | ScenarioMonster)]) {
  val camera = Camera.Fixed(Point(-200, -200))
}

object CreatorViewModel:
  def apply(): CreatorViewModel = CreatorViewModel(None)
