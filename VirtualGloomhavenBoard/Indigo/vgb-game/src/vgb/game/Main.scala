package vgb.game

import cats.effect.IO
import indigo.*
import indigo.scenes.*
import tyrian.TyrianSubSystem
import vgb.common.*
import vgb.game.scenes.*
import vgb.game.models.GameModel
import vgb.game.models.GameViewModel
import vgb.game.models.sceneModels.CreatorModel
import vgb.game.models.sceneModels.CreatorViewModel
import indigo.shared.assets.AssetType
import vgb.game.models.Room
import vgb.common.RoomType

final case class Main(tyrianSubSystem: TyrianSubSystem[IO, GloomhavenMsg])
    extends IndigoGame[Size, Size, GameModel, GameViewModel] {

  val magnification = 1

  def initialScene(bootData: Size): Option[SceneName] =
    Some(SceneName("creator-scene"))

  def scenes(bootData: Size): NonEmptyList[Scene[Size, GameModel, GameViewModel]] =
    NonEmptyList(CreatorScene(tyrianSubSystem))

  val eventFilters: EventFilters =
    EventFilters.AllowAll

  def boot(flags: Map[String, String]): Outcome[BootResult[Size]] =
    val gameViewport =
      (flags.get("width"), flags.get("height")) match {
        case (Some(w), Some(h)) =>
          GameViewport(w.toInt, h.toInt)

        case _ =>
          GameViewport(300, 300)
      }

    Outcome(
      BootResult(
        GameConfig.default
          .withMagnification(magnification)
          .withClearColor(RGBA.White)
          .withViewport(gameViewport),
        gameViewport.size / magnification
      )
        .withSubSystems(tyrianSubSystem)
        .withAssets(
          AssetType.Image(AssetName("gh-a1a"), AssetPath("img/map-tiles/gloomhaven/a1a.webp")),
          AssetType.Image(AssetName("aesther-ashblade"), AssetPath("img/monsters/aesther-ashblade.webp")),
          AssetType.Image(AssetName("move-icon"), AssetPath("img/move-icon.webp"))
        )
    )

  def setup(
      bootData: Size,
      assetCollection: AssetCollection,
      dice: Dice
  ): Outcome[Startup[Size]] =
    Outcome(Startup.Success(bootData))

  def initialModel(startupData: Size): Outcome[GameModel] =
    Outcome(
      GameModel(
        startupData,
        CreatorModel()
      )
    )

  def initialViewModel(startupData: Size, model: GameModel): Outcome[GameViewModel] =
    Outcome(
      GameViewModel(
        startupData,
        CreatorViewModel()
      )
    )

  def updateModel(
      context: FrameContext[Size],
      model: GameModel
  ): GlobalEvent => Outcome[GameModel] = {
    case tyrianSubSystem.TyrianEvent.Receive(msg) =>
      msg match {
        case _ =>
          Outcome(model)
      }
    case _ =>
      Outcome(model)
  }

  def updateViewModel(
      context: FrameContext[Size],
      model: GameModel,
      viewModel: GameViewModel
  ): GlobalEvent => Outcome[GameViewModel] =
    _ => Outcome(viewModel)

  def present(
      context: FrameContext[Size],
      model: GameModel,
      viewModel: GameViewModel
  ): Outcome[SceneUpdateFragment] =
    Outcome(SceneUpdateFragment.empty)
}
