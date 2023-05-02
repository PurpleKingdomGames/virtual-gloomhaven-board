package vgb.ui

import cats.effect.IO
import vgb.common.GloomhavenMsg
import tyrian.TyrianIndigoBridge

/** Represents a model for the application
  *
  * @param bridge
  *   The bridge between Indigo and Tyrian
  */
final case class Model(
    bridge: TyrianIndigoBridge[IO, GloomhavenMsg]
)

object Model:
  def apply(): Model =
    Model(
      TyrianIndigoBridge()
    )
