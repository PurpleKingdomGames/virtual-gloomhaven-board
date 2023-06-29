package vgb.common

final case class DragDropItem(item: BoardOverlayType | MonsterType | RoomType, dragging: Boolean)
