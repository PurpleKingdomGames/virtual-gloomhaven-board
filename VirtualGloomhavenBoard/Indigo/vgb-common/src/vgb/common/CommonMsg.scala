package vgb.common

/** A message from the VGB app
  */
trait GloomhavenMsg
object GloomhavenMsg:
  given CanEqual[GloomhavenMsg, GloomhavenMsg] = CanEqual.derived

  /** General messages that can be used across many scenes
    */
enum GeneralMsgType extends GloomhavenMsg:
  case Empty
