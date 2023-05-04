package vgb.game.scenes

import cats.effect.IO
import indigo.*
import indigo.scenes.*
import tyrian.TyrianSubSystem
import vgb.common.*
import vgb.game.models.GameModel
import vgb.game.models.GameViewModel
import indigo.shared.datatypes.RGBA
import vgb.game.models.components.HexComponent
import vgb.game.models.components.sceneModels.CreatorModel
import vgb.game.models.components.sceneModels.CreatorViewModel
import vgb.game.models.Room
import vgb.game.models.RoomType
import vgb.game.models.components.RoomComponent

/** Placeholder scene for the space station
  *
  * @param tyrianSubSystem
  */
final case class CreatorScene(tyrianSubSystem: TyrianSubSystem[IO, GloomhavenMsg])
    extends Scene[Size, GameModel, GameViewModel]:

  type SceneModel     = CreatorModel
  type SceneViewModel = CreatorViewModel

  val name: SceneName = SceneName("creator-scene")

  val modelLens: Lens[GameModel, CreatorModel] =
    Lens(
      (gameModel: GameModel) =>
        CreatorModel(
          Batch(
            Room(RoomType.RoomA1A, Point(2, 1), 0)
          )
        ),
      (gameModel: GameModel, model: CreatorModel) => gameModel
    )

  val viewModelLens: Lens[GameViewModel, CreatorViewModel] =
    Lens(
      (gameViewModel: GameViewModel) => CreatorViewModel(),
      (gameViewModel: GameViewModel, viewModel: CreatorViewModel) => gameViewModel
    )

  val eventFilters: EventFilters =
    EventFilters.AllowAll

  val subSystems: Set[SubSystem] =
    Set(tyrianSubSystem)

  def updateModel(
      context: SceneContext[Size],
      model: SceneModel
  ): GlobalEvent => Outcome[SceneModel] = { case _ =>
    Outcome(model)
  }

  def updateViewModel(
      context: SceneContext[Size],
      model: SceneModel,
      viewModel: SceneViewModel
  ): GlobalEvent => Outcome[SceneViewModel] = {

    case MouseEvent.Move(p) =>
      IndigoLogger.consoleLog(HexComponent.screenPosToOddRow(p + Point(-150, -150)).toString)
      Outcome(viewModel)
    case _ =>
      Outcome(viewModel)
  }

  def present(
      context: SceneContext[Size],
      model: SceneModel,
      viewModel: SceneViewModel
  ): Outcome[SceneUpdateFragment] =
    Outcome(
      SceneUpdateFragment.empty
        .addLayers(model.rooms.map(r => RoomComponent.render(r, true)))
        .addLayer(
          Layer(
            Batch.fromArray(
              (0 until 10).toArray
                .map(x =>
                  (0 until 10).toArray
                    .map(y => HexComponent.render(Point(x, y)))
                )
                .flatten
            )
          )
        )
        .withCamera(Camera.Fixed(Point(-150, -150)))
    )
