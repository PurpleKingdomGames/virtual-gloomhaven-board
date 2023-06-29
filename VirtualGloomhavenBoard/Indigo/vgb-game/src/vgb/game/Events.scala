package vgb.game

import indigo.shared.events.GlobalEvent
import indigo.shared.datatypes.Point
import vgb.game.models.Room
import vgb.game.models.ScenarioMonster
import vgb.game.models.BoardOverlay

final case class MoveStart(originalPos: Point, drag: Room | ScenarioMonster | BoardOverlay) extends GlobalEvent
final case class MoveEnd(newPos: Point, drag: Room | ScenarioMonster | BoardOverlay)        extends GlobalEvent
