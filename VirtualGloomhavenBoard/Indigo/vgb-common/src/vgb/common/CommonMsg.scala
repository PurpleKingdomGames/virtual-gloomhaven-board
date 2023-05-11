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
