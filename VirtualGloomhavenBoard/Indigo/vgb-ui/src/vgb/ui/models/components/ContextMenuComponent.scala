package vgb.ui.models.components

import indigo.shared.datatypes.Point
import indigo.shared.collections.Batch
import vgb.common.ContextMenu
import tyrian.*
import tyrian.Html.*
import vgb.common.MenuItem
import vgb.common.MenuSeparator
import vgb.ui.Msg

object ContextMenuComponent:
  def render(pos: Point, menu: ContextMenu): Html[Msg] =
    div(
      attributes(
        ("class", s"""context-menu ${if menu.items.isEmpty then "closed" else "open"}"""),
        ("aria-live", "polite"),
        ("aria-atomic", "true"),
        ("aria-hidden", if menu.items.isEmpty then "true" else "false")
      )
    )(
      nav(
        ul(
          renderItems(menu.items)
        )
      )
    )

  private def renderItem(item: MenuItem, separator: Boolean): Html[Msg] =
    val menuList =
      if item.hasSubMenu then
        List(
          text(item.name),
          div(
            ul(
              renderItems(item.subItems)
            )
          )
        )
      else List(text(item.name))

    li(
      `class` := s"""${if item.hasSubMenu then "has-sub-menu" else ""} ${if separator then " separator" else ""}""",
      onClick(
        item.cmd match {
          case Some(c) => Msg.IndigoSend(c)
          case None    => Msg.OpenContextItem(item)
        }
      )
    )(menuList)

  private def renderItems(items: Batch[MenuItem | MenuSeparator]): List[Html[Msg]] =
    items
      .foldRight(Batch.empty[Html[Msg]], false)((item, h) =>
        h match {
          case (html, separator) =>
            item match {
              case i: MenuItem      => (html :+ renderItem(i, separator), false)
              case s: MenuSeparator => (html, true)
            }
        }
      )
      ._1
      .reverse
      .toList
