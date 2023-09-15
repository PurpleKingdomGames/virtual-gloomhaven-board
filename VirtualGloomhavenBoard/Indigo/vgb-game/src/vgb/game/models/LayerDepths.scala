package vgb.game.models

import indigo.shared.datatypes.Depth

object LayerDepths:
  val Room        = Depth(0)
  val Overlay     = Depth(1)
  val Monster     = Depth(2)
  val Summons     = Depth(3)
  val Character   = Depth(4)
  val CoinOrToken = Depth(5)
