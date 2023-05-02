package vgb.game

import cats.effect.IO
import indigo.*
import indigo.scenes.*
import tyrian.TyrianSubSystem
import vgb.common.*
import vgb.game.scenes.*
import vgb.game.models.GameModel
import vgb.game.models.GameViewModel
import vgb.game.models.components.HexComponent

final case class Main(tyrianSubSystem: TyrianSubSystem[IO, GloomhavenMsg])
    extends IndigoGame[Size, Size, GameModel, GameViewModel] {

  val magnification = 1

  def initialScene(bootData: Size): Option[SceneName] =
    None

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
    )

  def setup(
      bootData: Size,
      assetCollection: AssetCollection,
      dice: Dice
  ): Outcome[Startup[Size]] =
    Outcome(Startup.Success(bootData))

  def initialModel(startupData: Size): Outcome[GameModel] =
    Outcome(GameModel(startupData))

  def initialViewModel(startupData: Size, model: GameModel): Outcome[GameViewModel] =
    Outcome(GameViewModel(startupData))

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
    case MouseEvent.Move(p) =>
      IndigoLogger.consoleLog(HexComponent.screenPosToOddRow(p).toString)
      Outcome(viewModel)
    case _ => Outcome(viewModel)

  def present(
      context: FrameContext[Size],
      model: GameModel,
      viewModel: GameViewModel
  ): Outcome[SceneUpdateFragment] =
    Outcome(
      SceneUpdateFragment(
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
}
