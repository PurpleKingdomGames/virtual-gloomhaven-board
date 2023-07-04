package vgb.game.models.storage

import vgb.game.models.ScenarioMonster

final case class ScenarioMonsterStorage(
    monster: String,
    initialX: Int,
    initialY: Int,
    twoPlayer: String,
    threePlayer: String,
    fourPlayer: String
)

object ScenarioMonsterStorage:
  def fromModel(monster: ScenarioMonster) =
    ScenarioMonsterStorage(
      monster.monsterType.assetName.toString(),
      monster.initialPosition.x,
      monster.initialPosition.y,
      monster.twoPlayerLevel.toString().toLowerCase(),
      monster.threePlayerLevel.toString().toLowerCase(),
      monster.fourPlayerLevel.toString().toLowerCase()
    )
