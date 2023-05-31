package vgb.common

import indigo.Batch

final case class ContextMenu(items: Batch[MenuItem | MenuSeparator]) {
  def add(item: Option[MenuItem | MenuSeparator]): ContextMenu =
    item match {
      case Some(i) => this.add(i)
      case None    => this
    }

  def add(item: MenuItem | MenuSeparator): ContextMenu =
    this.copy(items = items :+ item)

  def addOptions(items: Batch[Option[MenuItem | MenuSeparator]]): ContextMenu =
    this.copy(items = this.items ++ Batch.fromArray(items.toArray.flatten))

  def add(items: Batch[MenuItem | MenuSeparator]): ContextMenu =
    this.copy(items = this.items ++ items)

}

final case class MenuItem(
    name: String,
    selected: Boolean,
    cmd: Option[GloomhavenMsg],
    subItems: Batch[MenuItem | MenuSeparator]
) {
  val hasSubMenu = !subItems.isEmpty
}

final case class MenuSeparator()

object ContextMenu:
  def apply(): ContextMenu =
    ContextMenu(Batch.empty)

object MenuItem:
  def apply(name: String, cmd: GloomhavenMsg): MenuItem =
    MenuItem(name, false, Some(cmd), Batch.empty)
  def apply(name: String, subItems: Batch[MenuItem | MenuSeparator]): MenuItem =
    MenuItem(name, false, None, subItems)
