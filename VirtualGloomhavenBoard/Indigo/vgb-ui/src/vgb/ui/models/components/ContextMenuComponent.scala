package vgb.ui.models.components

import indigo.shared.datatypes.Point
import indigo.shared.collections.Batch
import indigo.*
import vgb.common.Menu
import vgb.common.MenuItem
import vgb.common.MenuSeparator
import tyrian.*
import tyrian.Html.*
import vgb.ui.Msg

object ContextMenuComponent:
  def render(pos: Point, menu: Menu): Html[Msg] =
    val hasItems = menu.isEmpty == false
    val isSubMenuOpen = menu.items.exists(i =>
      i match {
        case i: MenuItem =>
          i.open || i.subItems.exists(_ match {
            case i: MenuItem => i.open
            case _           => false
          })
        case _ => false
      }
    )

    div(
      attributes(
        ("id", "context-menu"),
        (
          "class",
          s"""context-menu ${if hasItems then "open" else "closed"} ${if isSubMenuOpen then "sub-menu-open" else ""}"""
            .trim()
        ),
        ("aria-live", "polite"),
        ("aria-atomic", "true"),
        ("aria-hidden", if hasItems then "false" else "true"),
        ("style", s"""top: ${pos.y}px; left: ${pos.x}px""")
      )
    )(
      if hasItems then MenuComponent.render(menu, hasItems)
      else Empty
    )
