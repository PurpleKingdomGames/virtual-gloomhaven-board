package vgb.common

import indigo.shared.datatypes.Vector2

class HexagonTests extends munit.FunSuite {

  test("should rotate (0, 2) 0 turn around 0, 0") {
    assertEquals(
      Vector2(0, 2),
      Hexagon.oddRowRotate(Vector2(0, 2), Vector2(0, 0), 0)
    )
  }

  test("should rotate (0, 2) 1 turn around 0, 0") {
    assertEquals(
      Vector2(-2, 1),
      Hexagon.oddRowRotate(Vector2(0, 2), Vector2(0, 0), 1)
    )
  }

  test("should rotate (-1, 0) 1 turns around 0, 0") {
    assertEquals(
      Vector2(-1, -1),
      Hexagon.oddRowRotate(Vector2(-1, 0), Vector2(0, 0), 1)
    )
  }

  test("should rotate (0, 1) 6 turns around 0, 0") {
    assertEquals(
      Vector2(0, 1),
      Hexagon.oddRowRotate(Vector2(0, 1), Vector2(0, 0), 6)
    )
  }

  test("should rotate (0, 1) 5 turns around 0, 0") {
    assertEquals(
      Vector2(1, 0),
      Hexagon.oddRowRotate(Vector2(0, 1), Vector2(0, 0), 5)
    )
  }

  test("should rotate (0, 1) 4 turns around 0, 0") {
    assertEquals(
      Vector2(0, -1),
      Hexagon.oddRowRotate(Vector2(0, 1), Vector2(0, 0), 4)
    )
  }

  test("should rotate (0, 1) 3 turns around 0, 0") {
    assertEquals(
      Vector2(-1, -1),
      Hexagon.oddRowRotate(Vector2(0, 1), Vector2(0, 0), 3)
    )
  }

  test("should rotate (0, 1) 2 turns around 0, 0") {
    assertEquals(
      Vector2(-1, 0),
      Hexagon.oddRowRotate(Vector2(0, 1), Vector2(0, 0), 2)
    )
  }

  test("should rotate (0, 1) 1 turn around 0, 0") {
    assertEquals(
      Vector2(-1, 1),
      Hexagon.oddRowRotate(Vector2(0, 1), Vector2(0, 0), 1)
    )
  }

  test("should rotate (0, 2) 1 turn around 0, 3") {
    assertEquals(
      Vector2(1, 2),
      Hexagon.oddRowRotate(Vector2(0, 2), Vector2(0, 3), 1)
    )
  }

  test("should rotate (0, 2) 3 turns around 0, 3") {
    assertEquals(
      Vector2(1, 4),
      Hexagon.oddRowRotate(Vector2(0, 2), Vector2(0, 3), 3)
    )
  }

  test("should rotate (-1, 6) 1 turn around 0, 6") {
    assertEquals(
      Vector2(-1, 5),
      Hexagon.oddRowRotate(Vector2(-1, 6), Vector2(0, 6), 1)
    )
  }

  test("should rotate (1, 1) 1 turns around 0, 1") {
    assertEquals(
      Vector2(1, 2),
      Hexagon.oddRowRotate(Vector2(1, 1), Vector2(0, 1), 1)
    )
  }

  test("should rotate (1, 1) 2 turns around 0, 1") {
    assertEquals(
      Vector2(0, 2),
      Hexagon.oddRowRotate(Vector2(1, 1), Vector2(0, 1), 2)
    )
  }
}
