package vgb.common

import indigo.Batch

final case class Menu(private val internalItems: Batch[MenuItemTrait | MenuSeparator]) {
  val items: Batch[MenuItemTrait | MenuSeparator] = assignIds(internalItems, -1)._1;
  val isEmpty: Boolean = items.isEmpty || items.exists(_ match {
    case _: MenuItemTrait => true
    case _                => false
  }) == false
  def updateItems(items: Batch[MenuItemTrait | MenuSeparator]) =
    this.copy(internalItems = items)

  def add(item: Option[MenuItemTrait | MenuSeparator]): Menu =
    item match {
      case Some(i) => this.add(i)
      case None    => this
    }

  def add(item: MenuItemTrait | MenuSeparator): Menu =
    this.copy(internalItems = internalItems :+ item)

  def addOptions(items: Batch[Option[MenuItemTrait | MenuSeparator]]): Menu =
    this.copy(internalItems = internalItems ++ Batch.fromArray(items.toArray.flatten))

  def add(items: Batch[MenuItemTrait | MenuSeparator]): Menu =
    this.copy(internalItems = internalItems ++ items)

  private def assignIds(
      items: Batch[MenuItemTrait | MenuSeparator],
      initialId: Byte
  ): (Batch[MenuItemTrait | MenuSeparator], Byte) =
    items
      .foldLeft((Batch.empty[MenuItemTrait | MenuSeparator], initialId))((t, i) =>
        t match {
          case (seenItems, lastId) =>
            i match {
              case i: (MenuItem | MenuLink) =>
                val (newItem, newId) = assignIdToItem(i, lastId)
                (seenItems :+ newItem, (newId + 1).toByte)
              case _ => (seenItems :+ i, lastId)
            }
        }
      )

  private def assignIdToItem(item: MenuItem | MenuLink, lastId: Byte): (MenuItem | MenuLink, Byte) =
    val (subMenus, newId) = assignIds(item.subItems, lastId)
    val nextId            = (newId + 1).toByte;

    item match {
      case i: MenuItem =>
        (i.copy(subItems = subMenus, id = nextId), nextId)
      case i: MenuLink =>
        (i.copy(subItems = subMenus, id = nextId), nextId)
    };
}

trait MenuItemTrait:
  val id: Byte
  val name: String
  val subItems: Batch[MenuItemTrait | MenuSeparator]
  val hasSubMenu = !subItems.isEmpty

final case class MenuItem(
    id: Byte,
    name: String,
    selected: Boolean,
    open: Boolean,
    cmd: Option[GloomhavenMsg],
    subItems: Batch[MenuItemTrait | MenuSeparator]
) extends MenuItemTrait {
  def withSelected(s: Boolean) =
    this.copy(selected = s)
}

final case class MenuSeparator()

final case class MenuLink(
    id: Byte,
    name: String,
    url: String,
    target: String,
    subItems: Batch[MenuItemTrait | MenuSeparator]
) extends MenuItemTrait

object Menu:
  def apply(): Menu =
    Menu(Batch.empty)

object MenuItem:
  def apply(name: String, cmd: GloomhavenMsg): MenuItem =
    MenuItem(0, name, false, false, Some(cmd), Batch.empty)
  def apply(name: String, subItems: Batch[MenuItemTrait | MenuSeparator]): MenuItem =
    MenuItem(0, name, false, false, None, subItems)

object MenuLink:
  def apply(name: String, url: String, target: String): MenuLink =
    MenuLink(0, name, url, target, Batch.empty)
  def apply(name: String, url: String): MenuLink =
    MenuLink(0, name, url, "_self", Batch.empty)
