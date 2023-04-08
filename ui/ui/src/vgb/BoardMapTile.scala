package vgb

object BoardMapTile:

  def getMapTileListByRef(ref: MapTileRef): List[MapTile] =
    getGridByRef(ref).zipWithIndex.flatMap { case (lb, y) =>
      indexedArrayYToMapTile(ref, y, lb)
    }

  def refToString(ref: MapTileRef): Option[String] =
    boardRefDict.toList.filter(_ == ref).headOption.map(_._1)

  def stringToRef(ref: String): Option[MapTileRef] =
    boardRefDict.get(ref.toLowerCase())

  val getAllRefs: List[MapTileRef] =
    boardRefDict.values.toList.filterNot(_ == MapTileRef.Empty)

  def indexedArrayYToMapTile(ref: MapTileRef, y: Int, arr: List[Boolean]): List[MapTile] =
    arr.zipWithIndex.map { case (p, x) =>
      indexedArrayXToMapTile(ref, y, x, p)
    }

  def indexedArrayXToMapTile(ref: MapTileRef, y: Int, x: Int, passable: Boolean): MapTile =
    MapTile(ref, x, y, 0, x, y, passable, true)

  val boardRefDict: Map[String, MapTileRef] =
    Map(
      ("a1a", MapTileRef.A1a),
      ("a1b", MapTileRef.A1b),
      ("a2a", MapTileRef.A2a),
      ("a2b", MapTileRef.A2b),
      ("a3a", MapTileRef.A3a),
      ("a3b", MapTileRef.A3b),
      ("a4a", MapTileRef.A4a),
      ("a4b", MapTileRef.A4b),
      ("b1a", MapTileRef.B1a),
      ("b1b", MapTileRef.B1b),
      ("b2a", MapTileRef.B2a),
      ("b2b", MapTileRef.B2b),
      ("b3a", MapTileRef.B3a),
      ("b3b", MapTileRef.B3b),
      ("b4a", MapTileRef.B4a),
      ("b4b", MapTileRef.B4b),
      ("c1a", MapTileRef.C1a),
      ("c1b", MapTileRef.C1b),
      ("c2a", MapTileRef.C2a),
      ("c2b", MapTileRef.C2b),
      ("d1a", MapTileRef.D1a),
      ("d1b", MapTileRef.D1b),
      ("d2a", MapTileRef.D2a),
      ("d2b", MapTileRef.D2b),
      ("e1a", MapTileRef.E1a),
      ("e1b", MapTileRef.E1b),
      ("f1a", MapTileRef.F1a),
      ("f1b", MapTileRef.F1b),
      ("g1a", MapTileRef.G1a),
      ("g1b", MapTileRef.G1b),
      ("g2a", MapTileRef.G2a),
      ("g2b", MapTileRef.G2b),
      ("h1a", MapTileRef.H1a),
      ("h1b", MapTileRef.H1b),
      ("h2a", MapTileRef.H2a),
      ("h2b", MapTileRef.H2b),
      ("h3a", MapTileRef.H3a),
      ("h3b", MapTileRef.H3b),
      ("i1a", MapTileRef.I1a),
      ("i1b", MapTileRef.I1b),
      ("i2a", MapTileRef.I2a),
      ("i2b", MapTileRef.I2b),
      ("j1a", MapTileRef.J1a),
      ("j1b", MapTileRef.J1b),
      ("j1ba", MapTileRef.J1ba),
      ("j1bb", MapTileRef.J1bb),
      ("j2a", MapTileRef.J2a),
      ("j2b", MapTileRef.J2b),
      ("k1a", MapTileRef.K1a),
      ("k1b", MapTileRef.K1b),
      ("k2a", MapTileRef.K2a),
      ("k2b", MapTileRef.K2b),
      ("l1a", MapTileRef.L1a),
      ("l1b", MapTileRef.L1b),
      ("l2a", MapTileRef.L2a),
      ("l2b", MapTileRef.L2b),
      ("l3a", MapTileRef.L3a),
      ("l3b", MapTileRef.L3b),
      ("m1a", MapTileRef.M1a),
      ("m1b", MapTileRef.M1b),
      ("n1a", MapTileRef.N1a),
      ("n1b", MapTileRef.N1b),
      ("empty", MapTileRef.Empty)
    )

  def getGridByRef(ref: MapTileRef): List[List[Boolean]] =

    val configA =
      List(
        List(false, false, false, false, false),
        List(true, true, true, true, false),
        List(true, true, true, true, true),
        List(false, false, false, false, false)
      )

    val configB =
      List(
        List(true, true, true, true),
        List(true, true, true, false),
        List(true, true, true, true),
        List(true, true, true, false)
      )

    val configC =
      List(
        List(false, true, true, false),
        List(true, true, true, false),
        List(true, true, true, true),
        List(true, true, true, false)
      )

    val configD =
      List(
        List(false, true, true, true, false),
        List(true, true, true, true, false),
        List(true, true, true, true, true),
        List(true, true, true, true, false),
        List(false, true, true, true, false)
      )

    val configE =
      List(
        List(false, true, true, true, true),
        List(true, true, true, true, true),
        List(false, true, true, true, true),
        List(true, true, true, true, true),
        List(false, true, true, true, true)
      )

    val configF =
      List(
        List(true, true, true),
        List(true, true, false),
        List(true, true, true),
        List(true, true, false),
        List(true, true, true),
        List(true, true, false),
        List(true, true, true),
        List(true, true, false),
        List(true, true, true)
      )

    val configG =
      List(
        List(true, true, true, true, true, true, true, true),
        List(true, true, true, true, true, true, true, false),
        List(true, true, true, true, true, true, true, true)
      )

    val configH =
      List(
        List(false, true, true, true, true, true, true),
        List(true, true, true, true, true, true, true),
        List(false, false, false, true, true, false, false),
        List(false, false, true, true, true, false, false),
        List(false, false, false, true, true, false, false),
        List(false, false, true, true, true, false, false),
        List(false, false, false, true, true, false, false)
      )

    val configI =
      List(
        List(true, true, true, true, true, true),
        List(true, true, true, true, true, false),
        List(true, true, true, true, true, true),
        List(true, true, true, true, true, false),
        List(true, true, true, true, true, true)
      )

    val configJ =
      List(
        List(false, false, false, false, false, false, true, false),
        List(false, false, false, false, false, true, true, true),
        List(false, false, false, false, false, true, true, true),
        List(false, false, false, false, true, true, true, false),
        List(true, true, true, true, true, true, true, false),
        List(true, true, true, true, true, true, false, false),
        List(true, true, true, true, true, false, false, false)
      )

    val configJ1ba =
      List(
        List(false, false, false, false, false, false, false, false),
        List(false, false, false, false, true, true, false, false),
        List(false, false, false, false, true, true, true, false),
        List(false, false, false, false, true, true, true, false),
        List(false, false, false, false, false, true, true, true),
        List(false, false, false, false, false, true, false, false),
        List(false, false, false, false, false, false, false, false)
      )

    val configJ1bb =
      List(
        List(true, true, true, true, true, false, false, false),
        List(true, true, true, true, false, false, false, false),
        List(true, true, true, true, false, false, false, false),
        List(false, false, false, false, false, false, false, false),
        List(false, false, false, false, false, false, false, false),
        List(false, false, false, false, false, false, false, false),
        List(false, false, false, false, false, false, false, false)
      )

    val configK =
      List(
        List(false, false, true, true, true, true, false, false),
        List(false, true, true, true, true, true, false, false),
        List(false, true, true, true, true, true, true, false),
        List(true, true, true, false, true, true, true, false),
        List(true, true, true, false, false, true, true, true),
        List(true, true, false, false, false, true, true, false)
      )

    val configL =
      List(
        List(true, true, true, true, true),
        List(true, true, true, true, false),
        List(true, true, true, true, true),
        List(true, true, true, true, false),
        List(true, true, true, true, true),
        List(true, true, true, true, false),
        List(true, true, true, true, true)
      )

    val configM =
      List(
        List(false, true, true, true, true, false),
        List(true, true, true, true, true, false),
        List(true, true, true, true, true, true),
        List(true, true, true, true, true, false),
        List(true, true, true, true, true, true),
        List(true, true, true, true, true, false),
        List(false, true, true, true, true, false)
      )

    val configN =
      List(
        List(true, true, true, true, true, true, true, true),
        List(true, true, true, true, true, true, true, false),
        List(true, true, true, true, true, true, true, true),
        List(true, true, true, true, true, true, true, false),
        List(true, true, true, true, true, true, true, true),
        List(true, true, true, true, true, true, true, false),
        List(true, true, true, true, true, true, true, true)
      )

    ref match
      case MapTileRef.A1a   => configA
      case MapTileRef.A1b   => configA
      case MapTileRef.A2a   => configA
      case MapTileRef.A2b   => configA
      case MapTileRef.A3a   => configA
      case MapTileRef.A3b   => configA
      case MapTileRef.A4a   => configA
      case MapTileRef.A4b   => configA
      case MapTileRef.B1a   => configB
      case MapTileRef.B1b   => configB
      case MapTileRef.B2a   => configB
      case MapTileRef.B2b   => configB
      case MapTileRef.B3a   => configB
      case MapTileRef.B3b   => configB
      case MapTileRef.B4a   => configB
      case MapTileRef.B4b   => configB
      case MapTileRef.C1a   => configC
      case MapTileRef.C1b   => configC
      case MapTileRef.C2a   => configC
      case MapTileRef.C2b   => configC
      case MapTileRef.D1a   => configD
      case MapTileRef.D1b   => configD
      case MapTileRef.D2a   => configD
      case MapTileRef.D2b   => configD
      case MapTileRef.E1a   => configE
      case MapTileRef.E1b   => configE
      case MapTileRef.F1a   => configF
      case MapTileRef.F1b   => configF
      case MapTileRef.G1a   => configG
      case MapTileRef.G1b   => configG
      case MapTileRef.G2a   => configG
      case MapTileRef.G2b   => configG
      case MapTileRef.H1a   => configH
      case MapTileRef.H1b   => configH
      case MapTileRef.H2a   => configH
      case MapTileRef.H2b   => configH
      case MapTileRef.H3a   => configH
      case MapTileRef.H3b   => configH
      case MapTileRef.I1a   => configI
      case MapTileRef.I1b   => configI
      case MapTileRef.I2a   => configI
      case MapTileRef.I2b   => configI
      case MapTileRef.J1a   => configJ
      case MapTileRef.J1b   => configJ.reverse
      case MapTileRef.J1ba  => configJ1ba
      case MapTileRef.J1bb  => configJ1bb
      case MapTileRef.J2a   => configJ
      case MapTileRef.J2b   => configJ.reverse
      case MapTileRef.K1a   => configK
      case MapTileRef.K1b   => configK
      case MapTileRef.K2a   => configK
      case MapTileRef.K2b   => configK
      case MapTileRef.L1a   => configL
      case MapTileRef.L1b   => configL
      case MapTileRef.L2a   => configL
      case MapTileRef.L2b   => configL
      case MapTileRef.L3a   => configL
      case MapTileRef.L3b   => configL
      case MapTileRef.M1a   => configM
      case MapTileRef.M1b   => configM
      case MapTileRef.N1a   => configN
      case MapTileRef.N1b   => configN
      case MapTileRef.Empty => List(List(true))

final case class MapTile(
    ref: MapTileRef,
    x: Int,
    y: Int,
    turns: Int,
    originalX: Int,
    originalY: Int,
    passable: Boolean,
    hidden: Boolean
)

enum MapTileRef:
  case A1a
  case A1b
  case A2a
  case A2b
  case A3a
  case A3b
  case A4a
  case A4b
  case B1a
  case B1b
  case B2a
  case B2b
  case B3a
  case B3b
  case B4a
  case B4b
  case C1a
  case C1b
  case C2a
  case C2b
  case D1a
  case D1b
  case D2a
  case D2b
  case E1a
  case E1b
  case F1a
  case F1b
  case G1a
  case G1b
  case G2a
  case G2b
  case H1a
  case H1b
  case H2a
  case H2b
  case H3a
  case H3b
  case I1a
  case I1b
  case I2a
  case I2b
  case J1a
  case J1b
  case J1ba
  case J1bb
  case J2a
  case J2b
  case K1a
  case K1b
  case K2a
  case K2b
  case L1a
  case L1b
  case L2a
  case L2b
  case L3a
  case L3b
  case M1a
  case M1b
  case N1a
  case N1b
  case Empty
