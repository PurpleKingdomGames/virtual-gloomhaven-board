package vgb.common

import indigo.Batch

final case class ContextMenu(items: Batch[MenuItem | MenuSeparator])

final case class MenuItem(
    name: String,
    selected: Boolean,
    cmd: Option[GloomhavenMsg],
    subItems: Batch[MenuItem | MenuSeparator]
) {
  val hasSubMenu = !subItems.isEmpty
}

final case class MenuSeparator()

object MenuItem:
  def apply(name: String, cmd: Option[GloomhavenMsg]): MenuItem =
    MenuItem(name, false, cmd, Batch.empty)
