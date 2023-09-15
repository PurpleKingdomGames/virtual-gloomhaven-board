package vgb.ui.models.components

import tyrian.*
import tyrian.Html.*
import vgb.ui.Msg
import vgb.common.Menu
import vgb.common.MenuItem
import vgb.common.MenuLink
import vgb.common.MenuSeparator
import indigo.shared.collections.Batch
import vgb.common.MenuItemTrait
import vgb.common.GeneralMsgType

object MenuComponent:
  def render(menu: Menu, visible: Boolean): Html[Msg] =
    nav(attribute("aria-hidden", if visible then "false" else "true"))(
      ul(attribute("role", "menu"))(
        renderItems(None, menu.items)
      )
    )

  private def renderItem(parentItem: Option[MenuItem], item: MenuItemTrait, separator: Boolean): Html[Msg] =
    val menuItemElem = item match {
      case i: MenuItem => text(i.name)
      case l: MenuLink => a(href := l.url, target := l.target)(l.name)
    }

    val isOpen = item match {
      case i: MenuItem =>
        i.open || i.subItems.exists(_ match {
          case i: MenuItem => i.open
          case _           => false
        })
      case _ => false
    }

    val menuList =
      if item.hasSubMenu then
        List(
          menuItemElem,
          div(
            ul(`class` := s"""${if isOpen then "open" else ""}""")(
              renderItems(
                item match {
                  case i: MenuItem => Some(i)
                  case _           => None
                },
                item.subItems
              )
            )
          )
        )
      else List(menuItemElem)

    val selected = item match {
      case i: MenuItem => i.selected
      case _           => false
    }

    val isCancel =
      item match {
        case item: MenuItem =>
          item.cmd match {
            case Some(_) => false
            case None =>
              parentItem match {
                case Some(_) => true
                case None    => item.subItems.isEmpty
              }
          }
        case _ => false
      }

    li(
      attributes(
        (
          "class",
          s"""${if item.hasSubMenu then "has-sub-menu" else ""}${if selected then " selected" else ""}${
              if separator then " separator" else ""
            }${if isCancel then " cancel cancel-menu" else ""}""".trim()
        ),
        ("tabIndex", "0"),
        ("role", "menuitem")
      ) ++
        (item match {
          case item: MenuItem =>
            List(onClick(item.cmd match {
              case Some(m: GeneralMsgType.ShowImportDialog) => Msg.IndigoReceive(m)
              case Some(c)                                  => Msg.IndigoSend(c)
              case None =>
                parentItem match {
                  case Some(p) => Msg.CloseContextItem(p.id)
                  case None =>
                    if item.subItems.isEmpty then Msg.CloseContextMenu
                    else Msg.OpenContextItem(item.id)
                }
            }))
          case _ => List.empty
        })
    )(menuList)

  private def renderItems(parentItem: Option[MenuItem], items: Batch[MenuItemTrait | MenuSeparator]): List[Html[Msg]] =
    items
      .foldRight(Batch.empty[Html[Msg]], false)((item, h) =>
        h match {
          case (html, separator) =>
            item match {
              case i: MenuItemTrait => (html :+ renderItem(parentItem, i, separator), false)
              case s: MenuSeparator => (html, true)
            }
        }
      )
      ._1
      .reverse
      .toList
