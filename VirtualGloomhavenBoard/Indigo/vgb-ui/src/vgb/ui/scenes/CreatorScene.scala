package vgb.ui.scenes

import cats.effect.IO
import indigo.shared.datatypes.Point
import tyrian.*
import tyrian.Html.*
import vgb.common.CreatorMsgType
import vgb.common.GloomhavenMsg
import vgb.common.Menu
import vgb.ui.Model
import vgb.ui.models.UiModel
import vgb.common.MenuItem
import vgb.common.MenuSeparator
import vgb.ui.Msg

object CreatorScene extends TyrianScene {
  type SceneModel = CreatorModel

  def getModel(model: Model): CreatorModel =
    model.sceneModel match {
      case m: CreatorModel => m
      case _               => CreatorModel()
    }

  def update(msg: vgb.common.GloomhavenMsg, model: CreatorModel): (CreatorModel, Cmd[IO, GloomhavenMsg]) =
    msg match {
      case CreatorMsgType.ChangeScenarioTitle(t) => (model.copy(scenarioTitle = t), Cmd.None)
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
          onInput(_ match {
            case t => Msg.IndigoReceive(CreatorMsgType.ChangeScenarioTitle(t))
          })
        )
      )
    )
  )
}

final case class CreatorModel(
    scenarioTitle: String,
    mainMenu: Menu,
    showMainMenu: Boolean,
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
      .add(Some(MenuItem("Export", CreatorMsgType.ShowExportDialog)))
      .add(Some(MenuItem("Import", CreatorMsgType.ShowImportDialog)))
      .add(MenuSeparator()),
    false,
    None
  )
