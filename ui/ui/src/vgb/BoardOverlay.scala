package vgb

object BoardOverlay:

  val overlayDictionary: Map[String, BoardOverlayType] = {
    import BoardOverlayType.*
    import DoorSubType.*
    import CorridorSize.*
    import CorridorMaterial.*
    import DifficultTerrainSubType.*
    import WallSubType.*
    import ObstacleSubType.*
    import HazardSubType.*
    import TreasureSubType.*
    import ChestType.*
    import TrapSubType.*
    Map(
      "door-altar"                    -> Door(AltarDoor, Nil),
      "door-stone"                    -> Door(Stone, Nil),
      "door-wooden"                   -> Door(Wooden, Nil),
      "door-dark-fog"                 -> Door(DarkFog, Nil),
      "door-light-fog"                -> Door(LightFog, Nil),
      "door-breakable-wall"           -> Door(BreakableWall, Nil),
      "corridor-dark-1"               -> Door((Corridor(Dark, One)), Nil),
      "corridor-earth-1"              -> Door((Corridor(Earth, One)), Nil),
      "corridor-manmade-stone-1"      -> Door((Corridor(ManmadeStone, One)), Nil),
      "corridor-natural-stone-1"      -> Door((Corridor(NaturalStone, One)), Nil),
      "corridor-pressure-plate-1"     -> Door((Corridor(PressurePlate, One)), Nil),
      "corridor-wood-1"               -> Door((Corridor(Wood, One)), Nil),
      "corridor-dark-2"               -> Door((Corridor(Dark, Two)), Nil),
      "corridor-earth-2"              -> Door((Corridor(Earth, Two)), Nil),
      "corridor-manmade-stone-2"      -> Door((Corridor(ManmadeStone, Two)), Nil),
      "corridor-natural-stone-2"      -> Door((Corridor(NaturalStone, Two)), Nil),
      "corridor-wood-2"               -> Door((Corridor(Wood, Two)), Nil),
      "difficult-terrain-log"         -> DifficultTerrain(Log),
      "difficult-terrain-rubble"      -> DifficultTerrain(Rubble),
      "difficult-terrain-stairs"      -> DifficultTerrain(Stairs),
      "difficult-terrain-stairs-vert" -> DifficultTerrain(VerticalStairs),
      "difficult-terrain-water"       -> DifficultTerrain(Water),
      "hazard-hot-coals"              -> Hazard(HotCoals),
      "hazard-thorns"                 -> Hazard(Thorns),
      "obstacle-altar"                -> Obstacle(Altar),
      "obstacle-barrel"               -> Obstacle(Barrel),
      "obstacle-bookcase"             -> Obstacle(Bookcase),
      "obstacle-boulder-1"            -> Obstacle(Boulder1),
      "obstacle-boulder-2"            -> Obstacle(Boulder2),
      "obstacle-boulder-3"            -> Obstacle(Boulder3),
      "obstacle-bush"                 -> Obstacle(Bush),
      "obstacle-cabinet"              -> Obstacle(Cabinet),
      "obstacle-crate"                -> Obstacle(Crate),
      "obstacle-crystal"              -> Obstacle(Crystal),
      "obstacle-dark-pit"             -> Obstacle(DarkPit),
      "obstacle-fountain"             -> Obstacle(Fountain),
      "obstacle-mirror"               -> Obstacle(Mirror),
      "obstacle-nest"                 -> Obstacle(Nest),
      "obstacle-pillar"               -> Obstacle(Pillar),
      "obstacle-rock-column"          -> Obstacle(RockColumn),
      "obstacle-sarcophagus"          -> Obstacle(Sarcophagus),
      "obstacle-shelf"                -> Obstacle(Shelf),
      "obstacle-stalagmites"          -> Obstacle(Stalagmites),
      "obstacle-stump"                -> Obstacle(Stump),
      "obstacle-table"                -> Obstacle(Table),
      "obstacle-totem"                -> Obstacle(Totem),
      "obstacle-tree-3"               -> Obstacle(Tree3),
      "obstacle-wall-section"         -> Obstacle(WallSection),
      "rift"                          -> Rift,
      "starting-location"             -> StartingLocation,
      "token-a"                       -> Token("a"),
      "token-b"                       -> Token("b"),
      "token-c"                       -> Token("c"),
      "token-d"                       -> Token("d"),
      "token-e"                       -> Token("e"),
      "token-f"                       -> Token("f"),
      "token-1"                       -> Token("1"),
      "token-2"                       -> Token("2"),
      "token-3"                       -> Token("3"),
      "token-4"                       -> Token("4"),
      "token-5"                       -> Token("5"),
      "token-6"                       -> Token("6"),
      "trap-bear"                     -> Trap(BearTrap),
      "trap-spike"                    -> Trap(Spike),
      "trap-poison"                   -> Trap(Poison),
      "treasure-chest"                -> Treasure(Chest(Locked)),
      "treasure-coin"                 -> Treasure(Coin(1)),
      "wall-huge-rock"                -> Wall(HugeRock),
      "wall-iron"                     -> Wall(Iron),
      "wall-large-rock"               -> Wall(LargeRock),
      "wall-obsidian-glass"           -> Wall(ObsidianGlass),
      "wall-rock"                     -> Wall(Rock)
    )
  }

  def getBoardOverlayName(overlay: BoardOverlayType): Option[String] = {
    val compare =
      overlay match {
        case BoardOverlayType.Door(d, _) =>
          BoardOverlayType.Door(d, Nil)

        case BoardOverlayType.Treasure(t) =>
          t match {
            case TreasureSubType.Chest(_) =>
              BoardOverlayType.Treasure(TreasureSubType.Chest(ChestType.Locked))

            case TreasureSubType.Coin(_) =>
              BoardOverlayType.Treasure(TreasureSubType.Coin(1))
          }

        case _ =>
          overlay
      }

    overlayDictionary.filter(_ == compare).keys.headOption
  }

  def getBoardOverlayType(overlayName: String): Option[BoardOverlayType] =
    overlayDictionary.get(overlayName)

  def getAllOverlayTypes: List[BoardOverlayType] =
    overlayDictionary.values.toList

  def getOverlayTypesWithLabel: Map[String, BoardOverlayType] =
    overlayDictionary

  def getOverlayLabel(overlay: BoardOverlayType): String = {
    import BoardOverlayType.*
    import DoorSubType.*
    import CorridorSize.*
    import CorridorMaterial.*
    import DifficultTerrainSubType.*
    import WallSubType.*
    import ObstacleSubType.*
    import HazardSubType.*
    import TreasureSubType.*
    import ChestType.*
    import TrapSubType.*

    overlay match {
      case Door(d, _) =>
        d match {
          case AltarDoor =>
            "Altar"

          case Stone =>
            "Stone Door"

          case Wooden =>
            "Wooden Door"

          case BreakableWall =>
            "Breakable Wall"

          case Corridor(c, _) =>
            c match {
              case Dark =>
                "Dark Corridor"

              case Earth =>
                "Earth Corridor"

              case ManmadeStone =>
                "Manmade Stone Corridor"

              case NaturalStone =>
                "Natural Stone Corridor"

              case PressurePlate =>
                "Pressure Plate"

              case Wood =>
                "Wooden Corridor"
            }

          case DarkFog =>
            "Dark Fog"

          case LightFog =>
            "Light Fog"
        }

      case DifficultTerrain(d) =>
        d match {
          case Log =>
            "Fallen Log"

          case Rubble =>
            "Rubble"

          case Stairs =>
            "Stairs"

          case VerticalStairs =>
            "Stairs"

          case Water =>
            "Water"
        }

      case Hazard(h) =>
        h match {
          case HotCoals =>
            "Hot Coals"

          case Thorns =>
            "Thorns"
        }

      case Highlight(c) =>
        c.toString ++ " Highlight"

      case Obstacle(o) =>
        o match {
          case Altar =>
            "Altar"

          case Barrel =>
            "Barrel"

          case Bookcase =>
            "Bookcase"

          case Boulder1 =>
            "Boulder"

          case Boulder2 =>
            "Boulder"

          case Boulder3 =>
            "Boulder"

          case Bush =>
            "Bush"

          case Cabinet =>
            "Cabinet"

          case Crate =>
            "Crate"

          case Crystal =>
            "Crystal"

          case DarkPit =>
            "Dark Pit"

          case Fountain =>
            "Fountain"

          case Mirror =>
            "Mirror"

          case Nest =>
            "Nest"

          case Pillar =>
            "Pillar"

          case RockColumn =>
            "Rock Column"

          case Sarcophagus =>
            "Sarcophagus"

          case Shelf =>
            "Sheelves"

          case Stalagmites =>
            "Stalagmites"

          case Stump =>
            "Tree Stump"

          case Table =>
            "Table"

          case Totem =>
            "Totem"

          case Tree3 =>
            "Tree"

          case WallSection =>
            "Wall"
        }

      case Rift =>
        "Rift"

      case StartingLocation =>
        "Starting Location"

      case Trap(t) =>
        t match {
          case BearTrap =>
            "Bear Trap"

          case Spike =>
            "Spike Trap"

          case Poison =>
            "Poison Trap"
        }

      case Treasure(t) =>
        t match {
          case Chest(c) =>
            "Treasure Chest "
              ++ (c match {
                case Goal =>
                  "Goal"

                case Locked =>
                  "(locked)"

                case NormalChest(i) =>
                  i.toString
              })

          case Coin(i) =>
            i.toString
              ++ (i match {
                case 1 =>
                  " Coin"

                case _ =>
                  " Coins"
              })
        }

      case Token(t) =>
        "Token (" ++ t ++ ")"

      case Wall(w) =>
        w match {
          case HugeRock =>
            "Huge Rock Wall"

          case Iron =>
            "Iron Wall"

          case LargeRock =>
            "Large Rock Wall"

          case ObsidianGlass =>
            "Obsidian Glass Wall"

          case Rock =>
            "Rock Wall"
        }
    }
  }

enum BoardOverlayType:
  case DifficultTerrain(typ: DifficultTerrainSubType)
  case Door(typ: DoorSubType, tiles: List[MapTileRef])
  case Hazard(typ: HazardSubType)
  case Highlight(colour: Colour)
  case Obstacle(typ: ObstacleSubType)
  case Rift
  case StartingLocation
  case Trap(typ: TrapSubType)
  case Treasure(typ: TreasureSubType)
  case Token(value: String)
  case Wall(typ: WallSubType)

enum DoorSubType:
  case AltarDoor
  case BreakableWall
  case Corridor(material: CorridorMaterial, size: CorridorSize)
  case DarkFog
  case LightFog
  case Stone
  case Wooden

enum CorridorMaterial:
  case Dark
  case Earth
  case ManmadeStone
  case NaturalStone
  case PressurePlate
  case Wood

enum CorridorSize:
  case One
  case Two

enum TrapSubType:
  case BearTrap
  case Poison
  case Spike

enum HazardSubType:
  case HotCoals
  case Thorns

enum DifficultTerrainSubType:
  case Log
  case Rubble
  case Stairs
  case VerticalStairs
  case Water

enum ObstacleSubType:
  case Altar
  case Barrel
  case Bookcase
  case Boulder1
  case Boulder2
  case Boulder3
  case Bush
  case Cabinet
  case Crate
  case Crystal
  case DarkPit
  case Fountain
  case Mirror
  case Nest
  case Pillar
  case RockColumn
  case Sarcophagus
  case Shelf
  case Stalagmites
  case Stump
  case Table
  case Totem
  case Tree3
  case WallSection

enum TreasureSubType:
  case Chest(typ: ChestType)
  case Coin(value: Int)

enum ChestType:
  case NormalChest(i: Int)
  case Goal
  case Locked

enum WallSubType:
  case HugeRock
  case Iron
  case LargeRock
  case ObsidianGlass
  case Rock

enum BoardOverlayDirectionType:
  case Default
  case Horizontal
  case Vertical
  case VerticalReverse
  case DiagonalLeft
  case DiagonalRight
  case DiagonalLeftReverse
  case DiagonalRightReverse

final case class BoardOverlay(
    ref: BoardOverlayType,
    id: Int,
    direction: BoardOverlayDirectionType,
    cells: List[(Int, Int)]
)
