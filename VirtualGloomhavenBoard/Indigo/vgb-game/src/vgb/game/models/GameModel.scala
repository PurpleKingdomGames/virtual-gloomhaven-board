package vgb.game.models

import indigo.*
import vgb.game.models.sceneModels.CreatorModel

final case class GameModel(sceneModel: CreatorModel)

object GameModel:
  def apply(startupData: Size, sceneModel: CreatorModel): GameModel = GameModel(sceneModel)
