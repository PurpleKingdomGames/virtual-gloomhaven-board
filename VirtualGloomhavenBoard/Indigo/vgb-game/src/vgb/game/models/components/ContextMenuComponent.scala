package vgb.game.models.components

import indigo.*
import vgb.common.ContextMenu
import vgb.common.MenuItem
import vgb.common.MenuSeparator
import vgb.common.CreatorMsgType
import vgb.common.RoomType
import vgb.common.Treasure
import vgb.game.models.ScenarioMonster
import vgb.game.models.BoardOverlay

object ContextMenuComponent:
  def getForCreator(
      room: Option[RoomType],
      monster: Option[ScenarioMonster],
      overlays: Batch[BoardOverlay]
  ): ContextMenu =
    ContextMenu()
      .add(
        overlays
          .filter(o =>
            o.overlayType match {
              case _: Treasure => false
              case _           => true
            }
          )
          .map(o => MenuItem(s"""Rotate ${o.overlayType}""", CreatorMsgType.RotateOverlay(o.id, o.overlayType)))
      )
      .add(room.map(r => MenuItem(s"""Rotate ${r}""", CreatorMsgType.RotateRoom(r))))
      .add(MenuSeparator())
      .add(
        overlays
          .map(o => MenuItem(s"""Remove ${o.overlayType}""", CreatorMsgType.RemoveOverlay(o.id, o.overlayType)))
      )
      .add(room.map(r => MenuItem(s"""Remove ${r}""", CreatorMsgType.RemoveRoom(r))))
