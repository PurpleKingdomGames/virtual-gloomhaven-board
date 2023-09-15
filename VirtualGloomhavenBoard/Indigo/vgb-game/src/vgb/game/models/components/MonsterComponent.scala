package vgb.game.models.components

import indigo.*
import indigo.shared.scenegraph.Shape.Box
import vgb.common.MonsterType
import vgb.common.Hexagon
import vgb.game.models.ScenarioMonster
import vgb.common.MonsterLevel
import indigo.shared.datatypes.Rectangle
import vgb.game.models.LayerDepths
import vgb.common.Flag

object MonsterComponent:
  val actualImageSize = Size(180, 180)
  val borderAsset     = AssetName("hex-border")
  def render(monster: MonsterType): Graphic[Material.Bitmap] =
    Graphic(actualImageSize, Material.Bitmap(monster.assetName))
      .withRef((actualImageSize / 2).toPoint)
      .scaleBy(Vector2(HexComponent.height.toDouble / actualImageSize.height.toDouble))

  def render(monster: ScenarioMonster, cellMap: Map[Point, Int]): Layer =
    val origin =
      Hexagon.oddRowToScreenPos(HexComponent.height, monster.initialPosition)
    val quarterSize = Math.ceil(HexComponent.halfWidth * 0.5).toInt
    val playerMarker = Box(
      Rectangle(
        Math.ceil(HexComponent.halfWidth).toInt,
        Math.ceil(HexComponent.halfWidth).toInt
      ),
      Fill.None
    )
      .withRef(Point(quarterSize, quarterSize))
    Layer(
      Group.empty
        .addChildren(
          Batch(
            this.render(monster.monsterType),
            playerMarker
              .withRotation(Radians.fromDegrees(32))
              .moveBy(Point(-Math.ceil(HexComponent.halfWidth).toInt, -Math.floor(HexComponent.quarterSize).toInt))
              .moveBy(Point(-5, -5))
              .withFill(getFillForLevel(monster.twoPlayerLevel)),
            playerMarker
              .withRotation(Radians.fromDegrees(60))
              .moveBy(Point(Math.ceil(HexComponent.halfWidth).toInt, -Math.floor(HexComponent.quarterSize).toInt))
              .moveBy(Point(5, -5))
              .withFill(getFillForLevel(monster.threePlayerLevel)),
            playerMarker
              .moveBy(Point(0, Math.ceil(HexComponent.halfSize).toInt))
              .moveBy(Point(0, 7))
              .withFill(getFillForLevel(monster.fourPlayerLevel)),
            Graphic(
              actualImageSize,
              Material.Bitmap(borderAsset).toImageEffects.withTint(RGBA.fromHexString("#bc1717"))
            )
              .withRef((actualImageSize / 2).toPoint)
              .scaleBy(Vector2(HexComponent.height.toDouble / actualImageSize.height.toDouble))
          )
        )
        .withPosition(origin)
        .withScale(Vector2(getScale(monster.initialPosition, cellMap)))
    ).withDepth(LayerDepths.Monster)

  private def getFillForLevel(level: MonsterLevel) =
    level match {
      case MonsterLevel.None   => Fill.Color(RGBA.Black)
      case MonsterLevel.Normal => Fill.Color(RGBA.White)
      case MonsterLevel.Elite  => Fill.Color(RGBA.fromHexString("#d9c200"))
    }

  private def getScale(pos: Point, cellMap: Map[Point, Int]): Double =
    cellMap.get(pos) match {
      case Some(v) =>
        val flags =
          Flag.All
            - Flag.Room.value
            - Flag.Corridor.value
            - Flag.Coin.value
            - Flag.Token.value
            - Flag.Monster.value
            - Flag.Character.value
        if (flags & v) == 0 then 1
        else 0.85
      case None => 1
    }
