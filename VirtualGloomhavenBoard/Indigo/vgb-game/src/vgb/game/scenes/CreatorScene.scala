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
import vgb.game.models.BoardOverlay
import vgb.game.models.DragData

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
    case SceneEvent.SceneChange(_, to, _) =>
      if to == name then
        Outcome(model)
          .addGlobalEvents(
            tyrianSubSystem.TyrianEvent
              .Send(CreatorMsgType.UpdateDragMenu(DragMenuComponent.getForModel(model)))
          )
      else Outcome(model)
    case MoveEnd(newPos, d) =>
      val newModel =
        d match {
          case o: BoardOverlay =>
            model.copy(overlays = GameRules.moveOverlay(newPos, o, model.overlays, model.cellMap))

          case m: ScenarioMonster =>
            model.copy(monsters = GameRules.moveMonster(newPos, m, model.monsters, model.cellMap))

          case r: Room =>
            model.copy(rooms =
              model.rooms
                .filter(room => room.roomType != r.roomType)
                :+ r.copy(origin = newPos)
            )
        }

      Outcome(newModel)
        .addGlobalEvents(
          tyrianSubSystem.TyrianEvent
            .Send(CreatorMsgType.UpdateDragMenu(DragMenuComponent.getForModel(newModel)))
        )
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
    case MoveStart(p, d) =>
      viewModel.dragging match {
        case None => Outcome(viewModel.copy(dragging = Some(DragData(p, p, d, false))))
        case _    => Outcome(viewModel)
      }
    case MouseEvent.MouseDown(p, MouseButton.LeftMouseButton) =>
      (
        viewModel.dragging match {
          case None =>
            val pos = Hexagon.screenPosToEvenRow(HexComponent.height, p + viewModel.camera.position).toPoint
            val data = model.monsters.find(m => m.initialPosition == pos) match {
              case Some(v) => Some(v)
              case None    => model.overlays.find(o => o.worldCells.contains(pos))
            }

            data match {
              case Some(d) => Outcome(viewModel.copy(dragging = Some(DragData(pos, pos, d, false))))
              case None    => Outcome(viewModel)
            }
          case _ => Outcome(viewModel)
        }
      ).addGlobalEvents(
        tyrianSubSystem.TyrianEvent
          .Send(GeneralMsgType.CloseContextMenu)
      )
    case MouseEvent.Move(p) =>
      val pos = Hexagon.screenPosToEvenRow(HexComponent.height, p + viewModel.camera.position).toPoint
      val draggingData =
        viewModel.dragging.orElse(
          viewModel.initialDragger match {
            case Some(d) =>
              val item = d match {
                case r: RoomType => Room(r, pos, 0)
                case m: MonsterType =>
                  ScenarioMonster(
                    m,
                    pos,
                    MonsterLevel.None,
                    MonsterLevel.None,
                    MonsterLevel.None
                  )
                case o: BoardOverlayType => BoardOverlay(0, o, pos, 0)
              }
              Some(DragData(pos, pos, item, true))
            case None => None
          }
        )
      draggingData match {
        case Some(d) =>
          val isValid = d.dragger match {
            case r: Room            => true
            case o: BoardOverlay    => GameRules.isValidOverlayPos(pos, o, model.cellMap)
            case m: ScenarioMonster => GameRules.isValidMonsterPos(pos, m, model.cellMap)
          }

          if isValid then
            Outcome(
              viewModel.copy(
                dragging = Some(d.copy(pos = pos, hasMoved = d.hasMoved || (d.originalPos != d.pos))),
                initialDragger = None
              )
            )
          else Outcome(viewModel)
        case None => Outcome(viewModel)
      }
    case MouseEvent.MouseUp(p, MouseButton.LeftMouseButton) =>
      viewModel.dragging match {
        case Some(d) if d.originalPos != d.pos =>
          Outcome(viewModel.copy(dragging = None))
            .addGlobalEvents(MoveEnd(d.pos, d.dragger))
        case Some(d) if d.hasMoved =>
          Outcome(viewModel.copy(dragging = None))
        case _ =>
          val hexPos = Hexagon.screenPosToEvenRow(HexComponent.height, p + viewModel.camera.position).toPoint
          Outcome(viewModel.copy(dragging = None))
            .addGlobalEvents(
              tyrianSubSystem.TyrianEvent
                .Send(
                  GeneralMsgType.ShowContextMenu(
                    p,
                    ContextMenuComponent.getForCreator(
                      model.rooms.find(r => r.worldCells.exists(rp => rp == hexPos)).map(r => r.roomType),
                      model.monsters.find(m => m.initialPosition == hexPos),
                      model.overlays.filter(o => o.worldCells.contains(hexPos))
                    )
                  )
                )
            )
      }
    case tyrianSubSystem.TyrianEvent.Receive(msg) =>
      updateViewModelFromTyrian(context, viewModel, msg)
    case _ =>
      Outcome(viewModel)
  }

  def present(
      context: SceneContext[Size],
      model: SceneModel,
      viewModel: SceneViewModel
  ): Outcome[SceneUpdateFragment] =
    val cellMap = viewModel.dragging
      .map(d => d.getCellMap(model.cellMap, model.rooms))
      .getOrElse(model.cellMap)

    Outcome(
      SceneUpdateFragment.empty
        .addLayers(
          model.rooms
            .filter(r =>
              viewModel.dragging match {
                case Some(d) if d.originalPos != d.pos =>
                  d.dragger match {
                    case r1: Room => r1.roomType != r.roomType
                    case _        => true
                  }
                case _ => true
              }
            )
            .map(r => RoomComponent.render(r, viewModel.camera, true))
        )
        .addLayers(
          model.monsters
            .filter(m =>
              viewModel.dragging match {
                case Some(d) if d.originalPos != d.pos =>
                  d.dragger match {
                    case m1: ScenarioMonster => m1 != m
                    case _                   => true
                  }
                case _ => true
              }
            )
            .map(m => MonsterComponent.render(m, cellMap))
        )
        .addLayers(
          model.overlays
            .filter(o =>
              viewModel.dragging match {
                case Some(d) if d.originalPos != d.pos =>
                  d.dragger match {
                    case o1: BoardOverlay => o1.id != o.id
                    case _                => true
                  }
                case _ => true
              }
            )
            .map(o => BoardOverlayComponent.render(o, cellMap))
        )
        .addLayer(
          viewModel.dragging match {
            case Some(d) if d.originalPos != d.pos =>
              d.dragger match {
                case m: ScenarioMonster =>
                  MonsterComponent.render(m.copy(initialPosition = d.pos), cellMap)
                case o: BoardOverlay =>
                  IndigoLogger.consoleLog(d.pos.toString())
                  BoardOverlayComponent.render(o.copy(origin = d.pos), cellMap)
                case r: Room =>
                  RoomComponent.render(r.copy(origin = d.pos), viewModel.camera, false)
              }
            case _ => Layer()
          }
        )
        .withCamera(viewModel.camera)
    )

  def updateModelFromTyrian(
      context: SceneContext[Size],
      model: SceneModel,
      msg: CreatorMsgType
  ) =
    msg match {
      case CreatorMsgType.ChangeMonsterLevel(p, m, playerNum, level) =>
        model.monsters.find(m1 => p == m1.initialPosition && m == m1.monsterType) match {
          case Some(m) =>
            val newMonster = m.copy(
              twoPlayerLevel = if playerNum == 2 then level else m.twoPlayerLevel,
              threePlayerLevel = if playerNum == 3 then level else m.threePlayerLevel,
              fourPlayerLevel = if playerNum == 4 then level else m.fourPlayerLevel
            )

            Outcome(model.copy(monsters = model.monsters.map(m1 => if m1 == m then newMonster else m1)))
          case _ => Outcome(model)
        }
      case CreatorMsgType.RemoveMonster(p, m) =>
        Outcome(model.copy(monsters = model.monsters.filterNot(m1 => p == m1.initialPosition && m == m1.monsterType)))
      case CreatorMsgType.RemoveOverlay(id, o) =>
        Outcome(model.copy(overlays = model.overlays.filterNot(o1 => id == o1.id && o == o1.overlayType)))
      case CreatorMsgType.RotateOverlay(id, o) =>
        model.overlays.find(o1 => id == o1.id && o == o1.overlayType) match {
          case Some(overlay) =>
            Outcome(
              model.copy(overlays = GameRules.rotateOverlay(overlay, model.overlays, model.cellMap))
            )
          case None => Outcome(model)
        }
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

      case _ =>
        Outcome(model)
    }

  def updateViewModelFromTyrian(
      context: SceneContext[Size],
      viewModel: SceneViewModel,
      msg: GloomhavenMsg
  ) =
    msg match {
      case CreatorMsgType.NewDragStart(item) =>
        Outcome(viewModel.copy(initialDragger = Some(item)))
      case CreatorMsgType.DragEnd =>
        Outcome(viewModel.copy(initialDragger = None, dragging = None))
      case _ => Outcome(viewModel)
    }
