package vgb.ui.models

import indigo.shared.datatypes.Point
import vgb.common.Menu

trait UiModel:
  val contextMenu: Option[(Point, Menu)]
  val mainMenu: Menu
  val showMainMenu: Boolean
  def updateContextMenu(menu: Option[(Point, Menu)]): UiModel
  def toggleMainMenu(): UiModel
