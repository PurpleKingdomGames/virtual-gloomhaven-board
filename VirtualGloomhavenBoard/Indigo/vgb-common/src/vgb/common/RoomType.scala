package vgb.common

import indigo.*

enum RoomType(val baseGame: BaseGame, val mapRef: String, val offset: Point, val cells: Batch[Point], val size: Size):
  override def toString(): String = mapRef.capitalize
  val assetName                   = AssetName(baseGame.shortName + "-" + mapRef)
  case RoomA1A
      extends RoomType(
        BaseGame.Gloomhaven,
        "a1a",
        Point(27, 33),
        Batch(
          Point(0, 1),
          Point(1, 1),
          Point(2, 1),
          Point(3, 1),
          Point(0, 2),
          Point(1, 2),
          Point(2, 2),
          Point(3, 2),
          Point(4, 2)
        ),
        Size(432, 244)
      )
  case RoomA1B
      extends RoomType(
        BaseGame.Gloomhaven,
        "a1b",
        Point(27, 33),
        Batch(
          Point(0, 1),
          Point(1, 1),
          Point(2, 1),
          Point(3, 1),
          Point(0, 2),
          Point(1, 2),
          Point(2, 2),
          Point(3, 2),
          Point(4, 2)
        ),
        Size(432, 244)
      )
/*
{
    tileset: "gloomhaven",
    mapRef: "a1a",
    offset: {
        x: -16,
        y: -34
    },
    cells: [
        { x: 0, y: 0 },

        { x: 1, y: 0 },

        { x: 2, y: 0 },

        { x: 3, y: 0 },

        { x: 0, y: 1 },

        { x: 1, y: 1 },

        { x: 2, y: 1 },

        { x: 3, y: 1 },

        { x: 4, y: 1 }
    ]
}
 */

object RoomType:
  def fromRef(baseGame: BaseGame, ref: String): Option[RoomType] =
    RoomType.values
      .find(r =>
        r.baseGame == baseGame &&
          r.mapRef.toLowerCase() == ref.toLowerCase()
      )
