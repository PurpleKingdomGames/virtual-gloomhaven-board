package vgb.game

import indigo.shared.events.GlobalEvent
import indigo.shared.datatypes.Point
import vgb.common.RoomType
import vgb.game.models.ScenarioMonster
import vgb.game.models.BoardOverlay

final case class MoveStart(originalPos: Point, drag: RoomType | ScenarioMonster | BoardOverlay) extends GlobalEvent
final case class MoveEnd(newPos: Point, drag: RoomType | ScenarioMonster | BoardOverlay)        extends GlobalEvent
