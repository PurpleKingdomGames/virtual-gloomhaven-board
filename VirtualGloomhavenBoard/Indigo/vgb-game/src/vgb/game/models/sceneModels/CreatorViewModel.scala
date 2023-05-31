package vgb.game.models.sceneModels

import indigo.*
import vgb.game.models.DragData

final case class CreatorViewModel(dragging: Option[DragData]) {
  val camera = Camera.Fixed(Point(-200, -200))
}

object CreatorViewModel:
  def apply(): CreatorViewModel = CreatorViewModel(None)
