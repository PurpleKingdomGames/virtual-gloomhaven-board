package vgb.common

import indigo.Point

/** A message from the VGB app
  */
trait GloomhavenMsg
object GloomhavenMsg:
  given CanEqual[GloomhavenMsg, GloomhavenMsg] = CanEqual.derived

  /** General messages that can be used across many scenes
    */
enum GeneralMsgType extends GloomhavenMsg:
  case ShowContextMenu(position: Point, menu: ContextMenu)
  case CloseContextMenu

enum CreatorMsgType extends GloomhavenMsg:
  case ChangeMonsterLevel(pos: Point, m: MonsterType, playerNum: Byte, monsterLevel: MonsterLevel)
  case RemoveMonster(pos: Point, m: MonsterType)
  case RotateOverlay(id: Int, o: BoardOverlayType)
  case RemoveOverlay(id: Int, o: BoardOverlayType)
  case RotateRoom(r: RoomType)
  case RemoveRoom(r: RoomType)
