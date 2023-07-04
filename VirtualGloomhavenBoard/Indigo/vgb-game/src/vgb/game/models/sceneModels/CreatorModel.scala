package vgb.game.models.sceneModels

import io.circe.*
import io.circe.generic.auto.*
import io.circe.parser.*
import io.circe.syntax.*
import indigo.*
import vgb.common.*
import vgb.game.models.BoardOverlay
import vgb.game.models.Room
import vgb.game.models.ScenarioMonster
import vgb.game.models.storage.CreatorStorage

final case class CreatorModel(
    scenarioTitle: String,
    baseGame: BaseGame,
    rooms: Batch[Room],
    monsters: Batch[ScenarioMonster],
    overlays: Batch[BoardOverlay]
) {
  val cellMap: Map[Point, Int] = (rooms
    .foldLeft(Batch.empty[(Point, Int)])((batch, room) =>
      room.worldCells
        .foldLeft(batch)((b, cell) => b :+ (cell, Flag.Room.value))
    ) ++
    overlays
      .foldLeft(Batch.empty[(Point, Int)])((batch, overlay) =>
        overlay.worldCells
          .foldLeft(batch)((b, cell) => b :+ (cell, overlay.overlayType.flag.value))
      ) ++
    monsters
      .foldLeft(Batch.empty[(Point, Int)])((batch, monster) => batch :+ (monster.initialPosition, Flag.Monster.value)))
    .foldLeft(Map.empty)((map, d) =>
      d match {
        case (cell, value) =>
          map.get(cell) match {
            case Some(existingVal) => map.updated(cell, value | existingVal)
            case None              => map + (cell -> value)
          }
      }
    )

  override def toString(): String =
    CreatorStorage.fromModel(this).asJson.deepDropNullValues.noSpaces
}

object CreatorModel:
  def apply(): CreatorModel =
    CreatorModel(
      "",
      BaseGame.Gloomhaven,
      Batch.empty,
      Batch.empty,
      Batch.empty
    )
