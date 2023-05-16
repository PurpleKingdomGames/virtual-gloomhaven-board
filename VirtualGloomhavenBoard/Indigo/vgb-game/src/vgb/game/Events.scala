package vgb.game

import indigo.shared.events.GlobalEvent
import indigo.shared.datatypes.Point
import vgb.common.RoomType

final case class MoveRoomStart(originalPos: Point, room: RoomType) extends GlobalEvent
final case class MoveRoomEnd(newPos: Point, room: RoomType)        extends GlobalEvent
