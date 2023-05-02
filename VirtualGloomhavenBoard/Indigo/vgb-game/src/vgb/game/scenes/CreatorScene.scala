package vgb.game.scenes

import cats.effect.IO
import indigo.*
import indigo.scenes.*
import tyrian.TyrianSubSystem
import vgb.common.*
import vgb.game.models.GameModel
import vgb.game.models.GameViewModel

/** Placeholder scene for the space station
  *
  * @param tyrianSubSystem
  */
final case class CreatorScene(tyrianSubSystem: TyrianSubSystem[IO, GloomhavenMsg])
    extends Scene[Size, GameModel, GameViewModel]:

  type SceneModel     = GameModel
  type SceneViewModel = GameViewModel

  val name: SceneName = SceneName("creator-scene")

  val modelLens: Lens[GameModel, SceneModel] =
    Lens(
      (gameModel: GameModel) => gameModel,
      (gameModel: GameModel, model: SceneModel) => model
    )

  val viewModelLens: Lens[GameViewModel, SceneViewModel] =
    Lens(
      (gameViewModel: GameViewModel) => gameViewModel,
      (gameViewModel: GameViewModel, viewModel: SceneViewModel) => viewModel
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
  ): GlobalEvent => Outcome[SceneViewModel] = { case _ =>
    Outcome(viewModel)
  }

  def present(
      context: SceneContext[Size],
      model: SceneModel,
      viewModel: SceneViewModel
  ): Outcome[SceneUpdateFragment] =
    Outcome(
      SceneUpdateFragment.empty
    )
