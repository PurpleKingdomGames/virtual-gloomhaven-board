package vgb.game.models

import indigo.shared.datatypes.Point
import indigo.shared.datatypes.Vector2
import indigo.shared.datatypes.Vector3

object Hexagon:
  private val oneOver3   = 1.0 / 3.0
  private val twoOver3   = 2.0 / 3.0;
  private val threeOver2 = 3.0 / 2.0;
  private val sqrtThree  = Math.sqrt(3)
  private val baseQ      = sqrtThree / 3

  def screenPosToCube(size: Int, pos: Point) = {
    val halfSize = size * 0.5;
    val q        = (baseQ * pos.x.toDouble + (oneOver3 * pos.y.toDouble)) / halfSize.toDouble
    val r        = (twoOver3 * pos.y.toDouble) / halfSize.toDouble
    cubeRound(axialToCube(Vector2(q, r)))
  }

  def screenPosToOddRow(size: Int, pos: Point) =
    cubeToOddRow(screenPosToCube(size, pos))

  def axialToScreenPos(size: Int, pos: Vector2) =
    val halfSize = size * 0.5;
    Point(
      (halfSize * (sqrtThree * pos.x - (sqrtThree * 0.5) * pos.y)).toInt,
      (halfSize * threeOver2 * pos.y).toInt
    )

  def oddRowToScreenPos(size: Int, pos: Point) =
    axialToScreenPos(size, oddRowToAxial(pos))

  def oddRowToAxial(pos: Point) =
    Vector2(
      pos.x + (pos.y - (pos.y.toInt & 1)) * 0.5,
      pos.y
    )

  def cubeToOddRow(pos: Vector3) =
    Vector2(pos.x - (pos.y - (pos.y.toInt & 1)) * 0.5, pos.y)

  def oddRowToCube(pos: Vector2) =
    val newX = (pos.x + (pos.y - (pos.y.toInt & 1))) * 0.5
    Vector3(newX, pos.y, -pos.x - pos.y)

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

  def oddRowRotate(origin: Vector2, rotationPoint: Vector2, numTurns: Byte): Vector2 =
    val rotateResult = oddRowSingleRotate(origin, rotationPoint)
    numTurns match
      case 0 => origin
      case 1 => rotateResult
      case other =>
        oddRowRotate(rotateResult, rotationPoint, (other - 1).toByte)

  def oddRowSingleRotate(origin: Vector2, rotationPoint: Vector2): Vector2 =
    val (originX, originY, originZ) = oddRowToCube(origin) match
      case v => (v.x, v.y, v.z)
    val (rotateX, rotateY, rotateZ) = oddRowToCube(rotationPoint) match
      case v => (v.x, v.y, v.z)
    val (rX, rY, rZ) =
      (-(originZ - rotateZ), -(originX - rotateX), -(originY - rotateY))

    cubeToOddRow(Vector3(rX + rotateX, rY + rotateY, rZ + rotateZ))
