package vgb

object Character {

  val characterDictionary: Map[String, CharacterClass] =
    import CharacterClass.*
    Map(
      ("brute", Brute),
      ("tinkerer", Tinkerer),
      ("scoundrel", Scoundrel),
      ("cragheart", Cragheart),
      ("mindthief", Mindthief),
      ("spellweaver", Spellweaver),
      ("diviner", Diviner),

      // Unlockable Characters
      ("phoenix-face", BeastTyrant),
      ("lightning-bolt", Berserker),
      ("angry-face", Doomstalker),
      ("triforce", Elementalist),
      ("eclipse", Nightshroud),
      ("cthulhu", PlagueHerald),
      ("three-spears", Quartermaster),
      ("saw", Sawbones),
      ("music-note", Soothsinger),
      ("concentric-circles", Summoner),
      ("sun", Sunkeeper),
      ("envelope-x", Bladeswarm)
    )

  val soloScenarioDict: Map[String, (Int, String)] =
    Map(
      ("brute", (1, "Return to Black Barrow")),
      ("tinkerer", (2, "An Unfortunate Intrusion")),
      ("scoundrel", (4, "Armory Heist")),
      ("cragheart", (5, "Stone Defense")),
      ("mindthief", (6, "Rodent Liberation")),
      ("spellweaver", (3, "Corrupted Laboratory")),
      ("diviner", (18, "Forecast of the Inevitable")),

      // -- Unlockable Characters
      ("phoenix-face", (17, "The Caged Bear")),
      ("lightning-bolt", (8, "Unnatural Insults")),
      ("angry-face", (14, "Corrupted Hunt")),
      ("triforce", (16, "Elemental Secrets")),
      ("eclipse", (11, "Harvesting the Night")),
      ("cthulhu", (12, "Plagued Crypt")),
      ("three-spears", (9, "Storage Fees")),
      ("saw", (15, "Aftermath")),
      ("music-note", (13, "Battle of the Bards")),
      ("concentric-circles", (10, "Plane of Wild Beasts")),
      ("sun", (7, "Caravan Escort"))
    )

  def characterToString(character: CharacterClass): Option[String] =
    characterDictionary.find(_._2 == character).map(_._1)

  def stringToCharacter(character: String): Option[CharacterClass] =
    characterDictionary.get(character.toLowerCase)

  def getRealCharacterName(character: CharacterClass): String =
    import CharacterClass.*
    character match
      case BeastTyrant =>
        "Beast Tyrant"

      case Berserker =>
        "Berserker"

      case Bladeswarm =>
        "Bladeswarm"

      case Brute =>
        "Brute"

      case Cragheart =>
        "Cragheart"

      case Diviner =>
        "Diviner"

      case Doomstalker =>
        "Doomstalker"

      case Elementalist =>
        "Elementalist"

      case Mindthief =>
        "Mindthief"

      case Nightshroud =>
        "Nightshroud"

      case PlagueHerald =>
        "Plague Herald"

      case Quartermaster =>
        "Quartermaster"

      case Sawbones =>
        "Sawbones"

      case Scoundrel =>
        "Scoundrel"

      case Soothsinger =>
        "Soothsinger"

      case Spellweaver =>
        "Spellweaver"

      case Summoner =>
        "Summoner"

      case Sunkeeper =>
        "Sunkeeper"

      case Tinkerer =>
        "Tinkerer"

  def getSoloScenarios: Map[String, (Int, String)] =
    soloScenarioDict

}

enum CharacterClass:
  case BeastTyrant
  case Berserker
  case Bladeswarm
  case Brute
  case Cragheart
  case Diviner
  case Doomstalker
  case Elementalist
  case Mindthief
  case Nightshroud
  case PlagueHerald
  case Quartermaster
  case Sawbones
  case Scoundrel
  case Soothsinger
  case Spellweaver
  case Summoner
  case Sunkeeper
  case Tinkerer
