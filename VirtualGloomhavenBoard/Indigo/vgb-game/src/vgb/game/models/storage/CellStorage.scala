package vgb.game.models.storage

import indigo.shared.datatypes.Point

final case class CellStorage(x: Int, y: Int):
  def toList = List(x, y)

object CellStorage:
  def fromPoint(p: Point) =
    CellStorage(p.x, p.y)
