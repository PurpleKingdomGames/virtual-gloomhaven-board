package vgb.ui.models.components

import vgb.common.Menu
import vgb.common.MenuLink
import vgb.common.MenuSeparator
import vgb.ui.Msg
import tyrian.*
import tyrian.Html.*

object MainMenuComponent:
  def render(menu: Menu, visible: Boolean) =
    div(
      attributes(
        ("class", s"""menu ${if visible then "show" else "hide"}"""),
        ("aria-label", "Toggle Menu"),
        ("aria-keyshortcuts", "m"),
        ("role", "button"),
        ("aria-pressed", if visible then "true" else "false")
      ) ++
        List(onClick(Msg.ToggleMainMenu))
    )(
      MenuComponent.render(
        menu
          .add(MenuSeparator())
          .add(
            MenuLink(
              "Donate",
              "https://github.com/sponsors/PurpleKingdomGames?o=esb",
              "_new"
            )
          ),
        visible
      )
    )
