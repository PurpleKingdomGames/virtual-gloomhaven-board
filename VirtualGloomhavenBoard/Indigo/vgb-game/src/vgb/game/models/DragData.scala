package vgb.game.models

import indigo.*
import vgb.common.RoomType
import vgb.game.models.ScenarioMonster
import vgb.game.models.BoardOverlay

final case class DragData(
    val originalPos: Point,
    val pos: Point,
    val dragger: RoomType | ScenarioMonster | BoardOverlay
)
