package vgb.ui.scenes

import cats.effect.IO
import tyrian.Cmd
import tyrian.Html
import vgb.common.GloomhavenMsg
import vgb.ui.Model
import vgb.ui.models.UiModel
import vgb.ui.Msg

trait TyrianScene:
  type SceneModel <: UiModel

  def getModel(model: Model): SceneModel
  def update(msg: GloomhavenMsg, model: SceneModel): (SceneModel, Cmd[IO, GloomhavenMsg])
  def getBoardAdditions(model: SceneModel): List[Html[Msg]]
  def getHeader(model: SceneModel): List[Html[Msg]]
