package vgb.game.models.storage

import vgb.game.models.sceneModels.CreatorModel

final case class CreatorStorage(
    scenarioTitle: String,
    baseGame: Option[String],
    roomData: List[RoomStorage],
    overlays: List[OverlayStorage],
    monsters: List[ScenarioMonsterStorage]
)

object CreatorStorage:
  def fromModel(model: CreatorModel) =
    CreatorStorage(
      model.scenarioTitle,
      Some(model.baseGame.toString()),
      model.rooms.map(r => RoomStorage.fromModel(r)).toList,
      model.overlays.map(o => OverlayStorage.fromModel(o)).toList,
      model.monsters.map(m => ScenarioMonsterStorage.fromModel(m)).toList
    )
