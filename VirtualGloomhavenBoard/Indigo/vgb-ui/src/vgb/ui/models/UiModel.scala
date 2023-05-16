package vgb.ui.models

import indigo.shared.datatypes.Point
import vgb.common.ContextMenu

trait UiModel:
  val contextMenu: Option[(Point, ContextMenu)]
  def updateContextMenu(menu: Option[(Point, ContextMenu)]): UiModel
