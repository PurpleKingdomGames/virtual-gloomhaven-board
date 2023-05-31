package vgb.common

import indigo.*

enum MonsterClass:
  case Normal, Boss

enum MonsterType(val baseGame: BaseGame, val name: String, val monsterClass: MonsterClass, val bucketSize: Byte):
  val assetName = AssetName(name.toLowerCase().replace(" ", "-"))
  case AestherAshblade extends MonsterType(BaseGame.Gloomhaven, "Aesther Ashblade", MonsterClass.Normal, 4)
