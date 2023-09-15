package vgb.game.models

import indigo.*
import vgb.game.models.sceneModels.*

final case class GameViewModel(sceneModel: CreatorViewModel)

object GameViewModel:
  def apply(startupData: Size, sceneModel: CreatorViewModel): GameViewModel = GameViewModel(sceneModel)
