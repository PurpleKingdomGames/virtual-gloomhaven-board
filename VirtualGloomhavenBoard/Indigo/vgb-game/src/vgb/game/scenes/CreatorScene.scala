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
import vgb.game.models.sceneModels.CreatorModel
import vgb.game.models.sceneModels.CreatorViewModel
import vgb.game.models.Room
import vgb.game.models.RoomType
import vgb.game.models.Hexagon
import vgb.game.models.components.RoomComponent
import vgb.game.MoveRoomStart
import vgb.game.MoveRoomEnd

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
        gameModel.sceneModel match {
          case m: CreatorModel => m
        },
      (gameModel: GameModel, model: CreatorModel) => gameModel.copy(sceneModel = model)
    )

  val viewModelLens: Lens[GameViewModel, CreatorViewModel] =
    Lens(
      (gameViewModel: GameViewModel) =>
        gameViewModel.sceneModel match {
          case m: CreatorViewModel => m
        },
      (gameViewModel: GameViewModel, viewModel: CreatorViewModel) => gameViewModel.copy(sceneModel = viewModel)
    )

  val eventFilters: EventFilters =
    EventFilters.AllowAll

  val subSystems: Set[SubSystem] =
    Set(tyrianSubSystem)

  def updateModel(
      context: SceneContext[Size],
      model: SceneModel
  ): GlobalEvent => Outcome[SceneModel] = {
    case MoveRoomEnd(p, r) =>
      r match {
        case r: RoomType =>
          Outcome(
            model.copy(rooms =
              model.rooms.map(room =>
                if room.roomType == r then room.copy(origin = p)
                else room
              )
            )
          )
      }
    case _ => Outcome(model)
  }

  def updateViewModel(
      context: SceneContext[Size],
      model: SceneModel,
      viewModel: SceneViewModel
  ): GlobalEvent => Outcome[SceneViewModel] = {
    case MoveRoomStart(p, r) =>
      Outcome(viewModel.copy(dragging = Some((p, r))))
    case MouseEvent.MouseUp(_, _) =>
      viewModel.dragging match {
        case Some((p, r)) =>
          Outcome(viewModel.copy(dragging = None))
            .addGlobalEvents(r match {
              case r: RoomType => MoveRoomEnd(p, r)
            })
        case None => Outcome(viewModel)
      }
    case MouseEvent.Move(p) =>
      viewModel.dragging match {
        case Some((_, r)) =>
          Outcome(
            viewModel.copy(dragging =
              Some(Hexagon.screenPosToOddRow(HexComponent.height, p + viewModel.camera.position).toPoint, r)
            )
          )
        case None => Outcome(viewModel)
      }
    case _ =>
      Outcome(viewModel)
  }

  def present(
      context: SceneContext[Size],
      model: SceneModel,
      viewModel: SceneViewModel
  ): Outcome[SceneUpdateFragment] =
    val cells = model.rooms.map(r => r.worldCells).flatten
    Outcome(
      SceneUpdateFragment.empty
        .addLayers(
          model.rooms
            .filter(r =>
              viewModel.dragging match {
                case Some((_, r1)) => r1 != r.roomType
                case None          => true
              }
            )
            .map(r => RoomComponent.render(r, viewModel.camera, true))
        )
        .addLayer(
          viewModel.dragging match {
            case Some((p, r: RoomType)) =>
              model.rooms.filter(r1 => r1.roomType == r).headOption match {
                case Some(r) => RoomComponent.render(r.copy(origin = p), viewModel.camera, false)
                case None    => Layer()
              }
            case None => Layer()
          }
        )
        .addLayer(
          Layer(
            Batch.fromArray(
              (0 until 10).toArray
                .map(x =>
                  (0 until 10).toArray
                    .map(y =>
                      HexComponent.render(
                        Point(x, y),
                        if cells.contains(Point(x, y)) then RGBA(0, 1, 0, 0.5) else RGBA.Zero
                      )
                    )
                )
                .flatten
            )
          )
        )
        .withCamera(viewModel.camera)
    )
