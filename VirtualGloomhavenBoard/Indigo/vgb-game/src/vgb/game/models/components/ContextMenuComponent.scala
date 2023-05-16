package vgb.game.models.components

import indigo.*
import vgb.common.ContextMenu
import vgb.common.MenuItem
import vgb.common.MenuSeparator
import vgb.common.CreatorMsgType
import vgb.common.RoomType

object ContextMenuComponent:
  def getForCreator(room: Option[RoomType]): ContextMenu =
    ContextMenu(
      Batch.fromArray(
        Array[Option[MenuItem | MenuSeparator]](
          room.map(r => MenuItem(s"""Rotate ${r}""", Some(CreatorMsgType.RotateRoom(r)))),
          Some(MenuSeparator()),
          room.map(r => MenuItem(s"""Remove ${r}""", Some(CreatorMsgType.RemoveRoom(r))))
        ).flatten
      )
    )
