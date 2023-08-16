package vgb.ui.scenes

import cats.effect.IO
import indigo.shared.datatypes.Point
import tyrian.*
import tyrian.Html.*
import tyrian.cmds.Download
import tyrian.cmds.File
import vgb.common.CreatorMsgType
import vgb.common.GloomhavenMsg
import vgb.common.Menu
import vgb.ui.Model
import vgb.ui.models.UiModel
import vgb.common.MenuItem
import vgb.common.MenuSeparator
import vgb.ui.Msg
import vgb.common.DragDropSection
import indigo.shared.collections.Batch
import vgb.common.GeneralMsgType
import vgb.common.MonsterType
import vgb.common.BoardOverlayType
import vgb.common.RoomType
import org.scalajs.dom
import indigo.shared.IndigoLogger

object CreatorScene extends TyrianScene {
  type SceneModel = CreatorModel

  def getModel(model: Model): CreatorModel =
    model.sceneModel match {
      case m: CreatorModel => m
      case _               => CreatorModel()
    }

  def update(msg: vgb.common.GloomhavenMsg, model: CreatorModel): (CreatorModel, Cmd[IO, GloomhavenMsg]) =
    msg match {
      case CreatorMsgType.SetSelectedDragSection(s) => (model.copy(dragMenuSelect = s), Cmd.None)
      case CreatorMsgType.ChangeScenarioTitle(t)    => (model.copy(scenarioTitle = t), Cmd.None)
      case CreatorMsgType.UpdateDragMenu(menu) =>
        (
          model.copy(
            dragMenu = menu,
            dragMenuSelect =
              if model.dragMenuSelect == "" then menu.headOption.map(s => s.name).getOrElse("")
              else model.dragMenuSelect
          ),
          Cmd.None
        )
      case CreatorMsgType.ShowImportDialog =>
        (model, File.select(Array("application/json"))(f => CreatorMsgType.ImportFileSelected(f)))
      case CreatorMsgType.ExportFileString(title, json) =>
        (model, Download.fromString(title + ".json", "application/json", json))

      case _ =>
        (model, Cmd.None)
    }

  def getHeader(model: CreatorModel): List[Html[Msg]] = List(
    header(
      attribute("aria-label", "Scenario Title")
    )(
      span(`class` := "title")(
        input(
          `type`      := "text",
          placeholder := "Enter Scenario Title",
          maxLength   := 30,
          value       := model.scenarioTitle,
          onInput(_ match {
            case t => Msg.IndigoSend(CreatorMsgType.ChangeScenarioTitle(t))
          })
        )
      )
    )
  )

  def getBoardAdditions(model: CreatorModel): List[Html[Msg]] = List(
    div(`class` := "page-shadow")(),
    div(`class` := "action-list")(
      model.dragMenu
        .map(s =>
          section(`class` := (if s.name == model.dragMenuSelect then "active" else ""))(
            header(onClick(Msg.IndigoReceive(CreatorMsgType.SetSelectedDragSection(s.name))))(s.name),
            ul(`class` := s.name.toLowerCase().replace(".", ""))(
              s.items
                .map(i =>
                  li(
                    draggable := true,
                    `class`   := (if i.dragging then "dragging" else ""),
                    onDragStart(Msg.IndigoSend(CreatorMsgType.NewDragStart(i.item))),
                    onDragEnd(Msg.IndigoSend(CreatorMsgType.DragEnd))
                  )(
                    i.item match {
                      case m: MonsterType      => m.name
                      case o: BoardOverlayType => o.name
                      case r: RoomType         => s"""Map tile ${i.item.toString()}"""
                    }
                  )
                )
                .toList
            )
          )
        )
        .toList
    )
  )
}

final case class CreatorModel(
    scenarioTitle: String,
    mainMenu: Menu,
    showMainMenu: Boolean,
    dragMenu: Batch[DragDropSection],
    dragMenuSelect: String,
    contextMenu: Option[(Point, Menu)]
) extends UiModel {
  def updateContextMenu(menu: Option[(Point, Menu)]): UiModel =
    this.copy(contextMenu = menu)
  def toggleMainMenu(): UiModel =
    this.copy(showMainMenu = showMainMenu != true)
}

object CreatorModel:
  def apply(): CreatorModel = CreatorModel(
    "",
    Menu()
      .add(Some(MenuItem("Create New", CreatorMsgType.CreateNewScenario)))
      .add(MenuSeparator())
      .add(Some(MenuItem("Export", CreatorMsgType.ExportFile)))
      .add(Some(MenuItem("Import", CreatorMsgType.ShowImportDialog)))
      .add(MenuSeparator()),
    false,
    Batch.empty,
    "",
    None
  )
