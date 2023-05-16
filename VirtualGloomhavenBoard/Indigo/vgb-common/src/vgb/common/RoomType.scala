package vgb.common

import indigo.*

enum RoomType(val baseGame: BaseGame, val mapRef: String, val offset: Point, val cells: Batch[Point], val size: Size):
  override def toString(): String = mapRef.capitalize

  case RoomA1A
      extends RoomType(
        BaseGame.Gloomhaven,
        "a1a",
        Point(-13, -34),
        Batch(
          Point(0, 0),
          Point(1, 0),
          Point(2, 0),
          Point(3, 0),
          Point(0, 1),
          Point(1, 1),
          Point(2, 1),
          Point(3, 1),
          Point(4, 1)
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
