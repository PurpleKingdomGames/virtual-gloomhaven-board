package vgb.game.models.components

import indigo.*
import vgb.common.*
import vgb.game.models.ScenarioMonster
import vgb.game.models.BoardOverlay

object ContextMenuComponent:
  def getForCreator(
      room: Option[RoomType],
      monster: Option[ScenarioMonster],
      overlays: Batch[BoardOverlay]
  ): ContextMenu =
    ContextMenu()
      .add(
        monster
          .map(m =>
            Batch(
              getMenuForLevel(2, m, m.twoPlayerLevel),
              getMenuForLevel(3, m, m.threePlayerLevel),
              getMenuForLevel(4, m, m.fourPlayerLevel)
            )
          )
          .getOrElse(Batch.empty)
      )
      .add(
        overlays
          .filter(o =>
            o.overlayType match {
              case _: (Treasure | Token) => false
              case _                     => true
            }
          )
          .map(o => MenuItem(s"""Rotate ${o.overlayType}""", CreatorMsgType.RotateOverlay(o.id, o.overlayType)))
      )
      .add(room.map(r => MenuItem(s"""Rotate ${r}""", CreatorMsgType.RotateRoom(r))))
      .add(MenuSeparator())
      .add(
        monster
          .map(m =>
            MenuItem(
              s"""Remove ${m.monsterType.name}""",
              CreatorMsgType.RemoveMonster(m.initialPosition, m.monsterType)
            )
          )
      )
      .add(
        overlays
          .map(o => MenuItem(s"""Remove ${o.overlayType}""", CreatorMsgType.RemoveOverlay(o.id, o.overlayType)))
      )
      .add(room.map(r => MenuItem(s"""Remove ${r}""", CreatorMsgType.RemoveRoom(r))))

  private def getMenuForLevel(playerNum: Byte, monster: ScenarioMonster, currentLevel: MonsterLevel) =
    MenuItem(
      s"""${playerNum} Player State""",
      Batch(
        MenuItem(
          "None",
          CreatorMsgType.ChangeMonsterLevel(monster.initialPosition, monster.monsterType, playerNum, MonsterLevel.None)
        ).withSelected(currentLevel == MonsterLevel.None),
        MenuItem(
          "Normal",
          CreatorMsgType.ChangeMonsterLevel(
            monster.initialPosition,
            monster.monsterType,
            playerNum,
            MonsterLevel.Normal
          )
        ).withSelected(currentLevel == MonsterLevel.Normal),
        MenuItem(
          "Elite",
          CreatorMsgType.ChangeMonsterLevel(monster.initialPosition, monster.monsterType, playerNum, MonsterLevel.Elite)
        ).withSelected(currentLevel == MonsterLevel.Elite)
      )
    )
