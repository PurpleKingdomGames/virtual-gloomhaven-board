package vgb.game.scenes

import cats.effect.IO
import indigo.*
import indigo.scenes.*
import tyrian.TyrianSubSystem
import indigo.shared.datatypes.RGBA
import vgb.game.models.Room
import vgb.common.*
import vgb.game.models.GameModel
import vgb.game.models.GameViewModel
import vgb.game.MoveStart
import vgb.game.MoveEnd
import vgb.game.models.Hexagon
import vgb.game.models.ScenarioMonster
import vgb.game.models.components.*
import vgb.game.models.sceneModels.CreatorModel
import vgb.game.models.sceneModels.CreatorViewModel
import vgb.game.models.GameRules

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
    case MoveEnd(newPos, d) =>
      d match {
        case m: ScenarioMonster =>
          Outcome(
            model.copy(monsters = GameRules.MoveMonster(newPos, m, model.monsters))
          )
        case r: RoomType =>
          Outcome(
            model.copy(rooms =
              model.rooms.map(room =>
                if room.roomType == r then room.copy(origin = newPos)
                else room
              )
            )
          )
      }
    case tyrianSubSystem.TyrianEvent.Receive(msg) =>
      msg match {
        case msg: CreatorMsgType =>
          updateModelFromTyrian(context, model, msg)
        case _ =>
          Outcome(model)
      }
    case _ => Outcome(model)
  }

  def updateViewModel(
      context: SceneContext[Size],
      model: SceneModel,
      viewModel: SceneViewModel
  ): GlobalEvent => Outcome[SceneViewModel] = {
    case MoveStart(p, r) =>
      viewModel.dragging match {
        case None => Outcome(viewModel.copy(dragging = Some((p, r))))
        case _    => Outcome(viewModel)
      }
    case MouseEvent.MouseDown(p, MouseButton.LeftMouseButton) =>
      viewModel.dragging match {
        case None =>
          val pos  = Hexagon.screenPosToEvenRow(HexComponent.height, p + viewModel.camera.position).toPoint
          val data = model.monsters.find(m => m.initialPosition == pos)

          data match {
            case Some(d) => Outcome(viewModel.copy(dragging = Some((p, d))))
            case None    => Outcome(viewModel)
          }
        case _ => Outcome(viewModel)
      }
    case MouseEvent.MouseUp(_, MouseButton.LeftMouseButton) =>
      viewModel.dragging match {
        case Some((p, d)) =>
          Outcome(viewModel.copy(dragging = None))
            .addGlobalEvents(MoveEnd(p, d))
        case None => Outcome(viewModel)
      }
    case MouseEvent.Move(p) =>
      viewModel.dragging match {
        case Some((_, r)) =>
          Outcome(
            viewModel.copy(dragging =
              Some(
                Hexagon.screenPosToEvenRow(HexComponent.height, p + viewModel.camera.position).toPoint,
                r
              )
            )
          )
        case None => Outcome(viewModel)
      }
    case MouseEvent.Click(p) =>
      val hexPos = Hexagon.screenPosToEvenRow(HexComponent.height, p + viewModel.camera.position).toPoint
      Outcome(viewModel)
        .addGlobalEvents(
          tyrianSubSystem.TyrianEvent
            .Send(
              GeneralMsgType.ShowContextMenu(
                p,
                ContextMenuComponent.getForCreator(
                  model.rooms.find(r => r.worldCells.exists(rp => rp == hexPos)).map(r => r.roomType)
                )
              )
            )
        )
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
                case Some((_, r1: RoomType)) => r1 != r.roomType
                case _                       => true
              }
            )
            .map(r => RoomComponent.render(r, viewModel.camera, true))
        )
        .addLayer(
          viewModel.dragging match {
            case Some((p, r: RoomType)) =>
              model.rooms.find(r1 => r1.roomType == r) match {
                case Some(r) => RoomComponent.render(r.copy(origin = p), viewModel.camera, false)
                case None    => Layer()
              }
            case _ => Layer()
          }
        )
        .addLayers(
          model.monsters
            .filter(m =>
              viewModel.dragging match {
                case Some((_, m1: ScenarioMonster)) => m1 != m
                case _                              => true
              }
            )
            .map(m => Layer(MonsterComponent.render(m)))
        )
        .addLayer(
          viewModel.dragging match {
            case Some((p, m: ScenarioMonster)) =>
              model.monsters.find(m1 => m1 == m) match {
                case Some(m) => Layer(MonsterComponent.render(m.copy(initialPosition = p)))
                case None    => Layer()
              }
            case _ => Layer()
          }
        )
        /*.addLayer(
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
        )*/
        .withCamera(viewModel.camera)
    )

  def updateModelFromTyrian(
      context: SceneContext[Size],
      model: SceneModel,
      msg: CreatorMsgType
  ) =
    msg match {
      case CreatorMsgType.RemoveRoom(r) =>
        Outcome(model.copy(rooms = model.rooms.filterNot(r1 => r == r1.roomType)))
      case CreatorMsgType.RotateRoom(r) =>
        model.rooms.find(r1 => r1.roomType == r) match {
          case Some(room) =>
            val rotatedOrigin =
              Hexagon.evenRowRotate(Vector2.fromPoint(room.origin), Vector2.fromPoint(room.rotationPoint), 1)
            val newRoom = room.copy(
              origin = rotatedOrigin.toPoint,
              numRotations = if room.numRotations == 5 then 0 else (room.numRotations + 1).toByte
            )
            Outcome(model.copy(rooms = model.rooms.map(r1 => if r1 == room then newRoom else r1)))
          case None => Outcome(model)
        }
    }
