package vgb.game.models

import indigo.*

final case class GameViewModel()

object GameViewModel:
  def apply(startupData: Size): GameViewModel = GameViewModel()
