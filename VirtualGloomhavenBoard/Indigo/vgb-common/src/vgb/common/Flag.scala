package vgb.common

enum Flag(val value: Int):
  case Room             extends Flag(1)
  case Obstacle         extends Flag(2)
  case DifficultTerrain extends Flag(4)
  case Hazard           extends Flag(8)
  case Trap             extends Flag(16)
  case Rift             extends Flag(32)
  case Wall             extends Flag(64)
  case Door             extends Flag(128)
  case Corridor         extends Flag(256)
  case TreasureChest    extends Flag(512)
  case Coin             extends Flag(1024)
  case Token            extends Flag(2048)
  case StartingLocation extends Flag(4096)
  case Highlight        extends Flag(8192)
  case Monster          extends Flag(16384)
  case Character        extends Flag(32768)
  case Summons          extends Flag(65536)
  case Hidden           extends Flag(131072)

object Flag:
  lazy val All = Flag.values.foldLeft(0)((v, f) => v | f.value)
  lazy val MinimiseCoin = (Flag.All - Flag.Coin.value - Flag.Token.value - Flag.Room.value - Flag.Hidden.value - Flag.Highlight.value)
  lazy val MinimiseToken = (Flag.Coin.value | Flag.TreasureChest.value | Flag.Monster.value | Flag.Character.value)

implicit class FlagOps(left: Int) {
  def +(right: Flag): Int =
    if (left & right.value) == 0 then left + right.value
    else left

  def -(right: Flag): Int =
    if (left & right.value) == 0 then left - right.value
    else left
}
