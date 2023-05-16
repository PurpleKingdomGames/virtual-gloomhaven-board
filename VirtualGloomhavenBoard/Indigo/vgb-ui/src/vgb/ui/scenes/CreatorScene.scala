package vgb.ui.scenes

import cats.effect.IO
import indigo.shared.datatypes.Point
import tyrian.*
import tyrian.Html.*
import vgb.common.GloomhavenMsg
import vgb.common.ContextMenu
import vgb.ui.Model
import vgb.ui.models.UiModel

object CreatorScene extends TyrianScene {
  type SceneModel = CreatorModel

  def getModel(model: Model): CreatorModel =
    model.sceneModel match {
      case m: CreatorModel => m
      case _               => CreatorModel()
    }

  def update(msg: vgb.common.GloomhavenMsg, model: CreatorModel): (CreatorModel, Cmd[IO, GloomhavenMsg]) =
    msg match {
      case _ =>
        (model, Cmd.None)
    }

  def header(model: CreatorModel): Html[GloomhavenMsg] =
    div()
}

final case class CreatorModel(
    contextMenu: Option[(Point, ContextMenu)]
) extends UiModel {
  def updateContextMenu(menu: Option[(Point, ContextMenu)]): UiModel =
    this.copy(contextMenu = menu)
}

object CreatorModel:
  def apply(): CreatorModel = CreatorModel(None)
