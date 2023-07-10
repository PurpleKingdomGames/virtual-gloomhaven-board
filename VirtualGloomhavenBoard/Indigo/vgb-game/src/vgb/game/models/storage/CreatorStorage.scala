package vgb.game.models.storage

import vgb.game.models.sceneModels.CreatorModel
import vgb.common.BaseGame
import indigo.shared.collections.Batch
import vgb.game.models.Room
import vgb.game.models.ScenarioMonster
import vgb.game.models.BoardOverlay

final case class CreatorStorage(
    scenarioTitle: String,
    baseGame: Option[String],
    roomData: List[RoomStorage],
    overlays: List[OverlayStorage],
    monsters: List[ScenarioMonsterStorage]
) {
  def toModel(): Either[String, CreatorModel] =
    val baseGame = this.baseGame match {
      case Some(value) =>
        BaseGame.values.find(g => g.toString().toLowerCase() == value) match {
          case Some(bg) => bg
          case None     => BaseGame.Gloomhaven
        }
      case None => BaseGame.Gloomhaven
    }

    val roomData = this.roomData.map(r => r.toModel(baseGame))
    val overlays = this.overlays.map(o => o.toModel(baseGame))
    val monsters = this.monsters.map(m => m.toModel(baseGame))

    val errors =
      roomData.collect { case Left(e) => e } ++
        overlays.collect { case Left(e) => e } ++
        monsters.collect { case Left(e) => e }

    errors.headOption match {
      case Some(value) => Left(value)
      case None =>
        Right(
          CreatorModel(
            scenarioTitle,
            baseGame,
            Batch.fromList(roomData.collect { case Right(r) => r }),
            Batch.fromList(monsters.collect { case Right(m) => m }),
            Batch.fromList(overlays.collect { case Right(o) => o })
          )
        )
    }
}

object CreatorStorage:
  def fromModel(model: CreatorModel) =
    CreatorStorage(
      model.scenarioTitle,
      model.baseGame match {
        case BaseGame.Gloomhaven => None
        case _                   => Some(model.baseGame.toString().toLowerCase())
      },
      model.rooms.map(r => RoomStorage.fromModel(r)).toList,
      model.overlays.map(o => OverlayStorage.fromModel(o)).toList,
      model.monsters.map(m => ScenarioMonsterStorage.fromModel(m)).toList
    )
