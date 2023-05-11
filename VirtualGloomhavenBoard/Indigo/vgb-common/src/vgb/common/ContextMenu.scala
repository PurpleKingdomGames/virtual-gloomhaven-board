package vgb.common

import indigo.Batch

final case class ContextMenu(items: Batch[MenuItem | MenuSeparator])

final case class MenuItem(name: String, cmd: GloomhavenMsg, subItems: Batch[MenuItem | MenuSeparator]) {
  val hasSubMenu = !subItems.isEmpty
}

final case class MenuSeparator()
