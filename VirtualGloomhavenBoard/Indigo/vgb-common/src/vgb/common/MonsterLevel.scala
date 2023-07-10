package vgb.common

enum MonsterLevel:
  case None, Normal, Elite

object MonsterLevel:
  def fromString(str: String) =
    MonsterLevel.values
      .find(l => l.toString().toLowerCase() == str)
      .getOrElse(None)
