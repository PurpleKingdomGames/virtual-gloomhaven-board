package vgb.ui

import cats.effect.IO
import tyrian.TyrianIndigoBridge
import vgb.common.GloomhavenMsg
import vgb.ui.scenes.*
import vgb.ui.models.UiModel

/** Represents a model for the application
  *
  * @param bridge
  *   The bridge between Indigo and Tyrian
  */
final case class Model(
    bridge: TyrianIndigoBridge[IO, GloomhavenMsg],
    indigoStarted: Boolean,
    sceneModel: UiModel,
    scene: TyrianScene
)

object Model:
  def apply(): Model =
    Model(
      TyrianIndigoBridge(),
      false,
      CreatorModel(),
      CreatorScene
    )
