package vgb

object Hexagon:

  def rotate(origin: (Int, Int), rotationPoint: (Int, Int), numTurns: Int): (Int, Int) =
    val rotateResult = singleRotate(origin, rotationPoint)

    numTurns match
      case 0 =>
        origin

      case 1 =>
        rotateResult

      case other if other < 0 =>
        rotate(rotateResult, rotationPoint, other + 1)

      case other =>
        rotate(rotateResult, rotationPoint, other - 1)

  def singleRotate(origin: (Int, Int), rotationPoint: (Int, Int)): (Int, Int) =
    val (originX, originY, originZ) = oddRowToCube(origin._1, origin._2)
    val (rotateX, rotateY, rotateZ) = oddRowToCube(rotationPoint._1, rotationPoint._2)
    val (rX, rY, rZ)                = (-(originZ - rotateZ), -(originX - rotateX), -(originY - rotateY))

    cubeToOddRow(rX + rotateX, rY + rotateY, rZ + rotateZ)

  def cubeToOddRow(x: Int, y: Int, z: Int): (Int, Int) =
    (x + (z - (z & 1)), z)

  def oddRowToCube(x: Int, y: Int): (Int, Int, Int) =
    val newX = x - (y - (y & 1))
    (newX, -newX - y, y)
