package vgb.game.models.storage

import indigo.shared.datatypes.Point
import vgb.game.models.ScenarioMonster
import vgb.common.MonsterLevel
import vgb.common.MonsterType
import vgb.common.BaseGame

final case class ScenarioMonsterStorage(
    monster: String,
    initialX: Int,
    initialY: Int,
    twoPlayer: String,
    threePlayer: String,
    fourPlayer: String
) {
  def toModel(baseGame: BaseGame): Either[String, ScenarioMonster] =
    val monsterType = MonsterType.values.find(m =>
      m.baseGame == baseGame &&
        m.assetName.toString().toLowerCase() == monster.toLowerCase()
    )

    monsterType match {
      case Some(monsterType) =>
        Right(
          ScenarioMonster(
            monsterType,
            Point(initialX, initialY),
            MonsterLevel.fromString(twoPlayer),
            MonsterLevel.fromString(threePlayer),
            MonsterLevel.fromString(fourPlayer)
          )
        )
      case None => Left(s"""Monster ${monster} does not exist for ${baseGame}""")
    }
}

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
