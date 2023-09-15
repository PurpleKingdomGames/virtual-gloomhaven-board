package vgb

final case class Colour(red: Int, green: Int, blue: Int, alpha: Int)

object Colour:
  val red: Colour    = Colour(255, 0, 0, 1)
  val green: Colour  = Colour(0, 128, 0, 1)
  val blue: Colour   = Colour(0, 0, 255, 1)
  val yellow: Colour = Colour(255, 255, 0, 1)
  val orange: Colour = Colour(255, 165, 0, 1)
  val indigo: Colour = Colour(75, 0, 130, 1)

  def toHexString(colour: Colour): String =
    "#" +
      (colour.red.toHexString.reverse.padTo(2, '0').reverse) +
      (colour.green.toHexString.reverse.padTo(2, '0').reverse) +
      (colour.blue.toHexString.reverse.padTo(2, '0').reverse)

  def toRGBAString(colour: Colour): String =
    s"rgba(${colour.red.toString()}, ${colour.green.toString()}, ${colour.blue.toString()}, ${colour.alpha.toString()})"

  def fromHexString(str: String): Colour =
    val strNoHash = str.replaceAll("#", "")

    Colour(
      hexToInt(strNoHash.take(2)),
      hexToInt(strNoHash.drop(2).take(2)),
      hexToInt(strNoHash.drop(4).take(2)),
      if strNoHash.length > 6 then hexToInt(strNoHash.drop(6).take(2))
      else 1
    )

  def hexToInt(hex: String): Int =
    Integer.parseInt(hex, 16)
