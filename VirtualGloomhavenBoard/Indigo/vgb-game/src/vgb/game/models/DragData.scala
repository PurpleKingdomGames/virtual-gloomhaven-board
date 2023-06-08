package vgb.game.models

import indigo.*
import vgb.common.RoomType
import vgb.game.models.ScenarioMonster
import vgb.game.models.BoardOverlay
import vgb.common.Flag

final case class DragData(
    val originalPos: Point,
    val pos: Point,
    val dragger: RoomType | ScenarioMonster | BoardOverlay,
    val hasMoved: Boolean
) {
  def getCellMap(
      map: Map[Point, Int],
      rooms: Batch[Room]
  ): Map[Point, Int] =
    if originalPos != pos then
      val cells =
        dragger match {
          case m: ScenarioMonster =>
            Batch((m.initialPosition, -Flag.Monster.value), (pos, Flag.Monster.value))
          case o: BoardOverlay =>
            o.worldCells.map(c => (c, -Flag.Obstacle.value)) ++
              o.copy(origin = pos).worldCells.map(c => (c, Flag.Obstacle.value))
          case r: RoomType =>
            rooms.find(r1 => r1.roomType == r) match {
              case Some(r) =>
                r.worldCells.map(c => (c, -Flag.Room.value)) ++
                  r.copy(origin = pos).worldCells.map(c => (c, Flag.Room.value))
              case None => Batch.empty
            }
        }

      cells.foldLeft(map)((m, c) =>
        c match {
          case (point, flag) =>
            m.get(point) match {
              case Some(f) =>
                if flag < 0 then
                  if (f & -flag) != 0 then m.updated(point, f + flag)
                  else m
                else m.updated(point, f | flag)
              case None => m + (point -> flag)
            }
        }
      )
    else map
}
