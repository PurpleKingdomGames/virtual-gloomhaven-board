package vgb.game.models

import indigo.shared.datatypes.Point
import indigo.shared.datatypes.Vector2
import indigo.shared.datatypes.Vector3

object Hexagon:
  private val oneOver3       = 1.0 / 3.0
  private val twoOver3       = 2.0 / 3.0;
  private val threeOver2     = 3.0 / 2.0;
  private val sqrtThree      = Math.sqrt(3)
  private val sqrtThreeOver3 = sqrtThree / 3

  def screenPosToAxial(size: Int, pos: Point) = {
    val halfSize = size * 0.5;
    val q        = (sqrtThreeOver3 * pos.x.toDouble - oneOver3 * pos.y.toDouble) / halfSize.toDouble
    val r        = (twoOver3 * pos.y.toDouble) / halfSize.toDouble

    cubeToAxial(
      cubeRound(axialToCube(Vector2(q, r)))
    )
  }

  def screenPosToEvenRow(size: Int, pos: Point) =
    axialToEvenRow(screenPosToAxial(size, pos))

  def axialToScreenPos(size: Int, pos: Vector2) =
    val halfSize = size * 0.5;
    Point(
      (halfSize * (sqrtThree * pos.x + (sqrtThree * 0.5) * pos.y)).toInt,
      (halfSize * threeOver2 * pos.y).toInt
    )

  def evenRowToScreenPos(size: Int, pos: Point) =
    axialToScreenPos(size, evenRowToAxial(Vector2.fromPoint(pos)))

  def axialToEvenRow(pos: Vector2) =
    Vector2(
      pos.x + (pos.y + (pos.y.toInt & 1)) * 0.5,
      pos.y
    )

  def evenRowToAxial(pos: Vector2) =
    Vector2(
      pos.x - (pos.y + (pos.y.toInt & 1)) * 0.5,
      pos.y
    )

  def cubeToEvenRow(pos: Vector3) =
    Vector2(pos.x + (pos.y + (pos.y.toInt & 1)) * 0.5, pos.y)

  def evenRowToCube(pos: Vector2) =
    val newX = pos.x - (pos.y + (pos.y.toInt & 1)) * 0.5
    Vector3(newX, pos.y, -newX - pos.y)

  def cubeToAxial(pos: Vector3) =
    Vector2(pos.x, pos.y)

  def axialToCube(pos: Vector2) =
    Vector3(pos.x, pos.y, -pos.x - pos.y)

  def cubeRound(pos: Vector3) = pos match {
    case Vector3(fracQ, fracR, fracS) =>
      val q = Math.round(fracQ).toDouble
      val r = Math.round(fracR).toDouble
      val s = Math.round(fracS).toDouble

      val qDiff = Math.abs(q - fracQ)
      val rDiff = Math.abs(r - fracR)
      val sDiff = Math.abs(s - fracS)

      if qDiff > rDiff && qDiff > sDiff then Vector3(-r - s, r, s)
      else if rDiff > sDiff then Vector3(q, -q - s, s)
      else Vector3(q, r, -q - r)
  }

  def evenRowRotate(origin: Vector2, rotationPoint: Vector2, numTurns: Byte): Vector2 =
    val rotateResult = evenRowSingleRotate(origin, rotationPoint)
    numTurns match
      case 0 => origin
      case 1 => rotateResult
      case other if other < 0 =>
        evenRowRotate(rotateResult, rotationPoint, (other + 1).toByte)
      case other =>
        evenRowRotate(rotateResult, rotationPoint, (other - 1).toByte)

  def evenRowSingleRotate(origin: Vector2, rotationPoint: Vector2): Vector2 =
    val (originX, originY, originZ) = evenRowToCube(origin) match
      case v => (v.x, v.y, v.z)
    val (rotateX, rotateY, rotateZ) = evenRowToCube(rotationPoint) match
      case v => (v.x, v.y, v.z)
    val (rX, rY, rZ) =
      (-(originY - rotateY), -(originZ - rotateZ), -(originX - rotateX))

    cubeToEvenRow(Vector3(rX + rotateX, rY + rotateY, rZ + rotateZ))
