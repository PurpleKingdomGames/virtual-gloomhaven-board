package vgb.game.models

import indigo.shared.datatypes.Point
import indigo.shared.collections.Batch

final case class TestPlaceable(
    rotation: TileRotation,
    origin: Point,
    worldCells: Batch[Point]
) extends Placeable {
  val minPoint: Point = origin
  val maxPoint: Point = origin
}

class PlaceableTests extends munit.FunSuite {
  def checkConversionToWorld(
      localPoint: Point,
      origin: Point,
      expectedResult: Point,
      rotation: TileRotation = TileRotation.Default
  )(implicit loc: munit.Location): Unit =
    test(
      s"""local ${localPoint} to world ${expectedResult} and back with origin ${origin} and rotation ${rotation}"""
    ) {
      val p = TestPlaceable(rotation, origin, Batch.empty)

      assertEquals(
        expectedResult,
        p.localToWorld(localPoint),
        "Local point to world point fails"
      )
      assertEquals(
        localPoint,
        p.worldToLocal(expectedResult),
        "World point to local point fails"
      )
    }

  // Simple tests for 0,0 local positions
  checkConversionToWorld(Point(0, 0), Point(0, 0), Point(0, 0))
  checkConversionToWorld(Point(0, 0), Point(0, 1), Point(0, 1))
  checkConversionToWorld(Point(0, 0), Point(0, 2), Point(0, 2))
  checkConversionToWorld(Point(0, 0), Point(1, 0), Point(1, 0))
  checkConversionToWorld(Point(0, 0), Point(1, 1), Point(1, 1))
  checkConversionToWorld(Point(0, 0), Point(1, 2), Point(1, 2))

  // Simple tests for 1,0 local positions
  checkConversionToWorld(Point(1, 0), Point(0, 0), Point(1, 0))
  checkConversionToWorld(Point(1, 0), Point(0, 1), Point(1, 1))
  checkConversionToWorld(Point(1, 0), Point(0, 2), Point(1, 2))
  checkConversionToWorld(Point(1, 0), Point(1, 0), Point(2, 0))
  checkConversionToWorld(Point(1, 0), Point(1, 1), Point(2, 1))
  checkConversionToWorld(Point(1, 0), Point(1, 2), Point(2, 2))

  // Simple tests for 0,1 local positions
  checkConversionToWorld(Point(0, 1), Point(0, 0), Point(0, 1))

  // This is where things get tricksy - In order to be correct on the
  // hexagon grid the actual amount that the tile needs to move is 1, 1 not 0,1
  // as you might expect
  checkConversionToWorld(Point(0, 1), Point(0, 1), Point(1, 2))
  checkConversionToWorld(Point(0, 1), Point(0, 2), Point(0, 3))
  checkConversionToWorld(Point(0, 1), Point(1, 0), Point(1, 1))

  // Likewise, in order to be correct on the
  // hexagon grid the actual amount that the tile needs to move is 2, 1 not 1,1
  // as you might expect
  checkConversionToWorld(Point(0, 1), Point(1, 1), Point(2, 2))
  checkConversionToWorld(Point(0, 1), Point(1, 2), Point(1, 3))

  // Now test a range of cells with a single rotation
  checkConversionToWorld(Point(0, 0), Point(1, 1), Point(1, 1), TileRotation.DiagonalLeft)
  checkConversionToWorld(Point(1, 0), Point(1, 1), Point(2, 2), TileRotation.DiagonalLeft)
  checkConversionToWorld(Point(0, 1), Point(1, 1), Point(1, 2), TileRotation.DiagonalLeft)
  checkConversionToWorld(Point(1, 1), Point(1, 1), Point(1, 3), TileRotation.DiagonalLeft)
  checkConversionToWorld(Point(2, 1), Point(1, 1), Point(2, 4), TileRotation.DiagonalLeft)
  checkConversionToWorld(Point(0, 2), Point(1, 1), Point(0, 2), TileRotation.DiagonalLeft)
  checkConversionToWorld(Point(1, 2), Point(1, 1), Point(0, 3), TileRotation.DiagonalLeft)
  checkConversionToWorld(Point(2, 2), Point(1, 1), Point(1, 4), TileRotation.DiagonalLeft)
}
