package vgb.common

import indigo.*

enum MonsterClass:
  case Normal, Boss

enum MonsterType(name: String, `class`: MonsterClass, bucketSize: Byte):
  val assetName = AssetName(name.toLowerCase().replace(" ", "-"))
  case AestherAshblade extends MonsterType("Aesther Ashblade", MonsterClass.Normal, 4)
