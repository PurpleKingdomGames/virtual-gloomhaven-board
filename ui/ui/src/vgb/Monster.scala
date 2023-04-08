package vgb

object Monster:

  private val normalDict: Map[String, NormalMonsterType] =
    import NormalMonsterType.*
    Map(
      ("aesther-ashblade", AestherAshblade),
      ("aesther-scout", AestherScout),
      ("bandit-guard", BanditGuard),
      ("bandit-archer", BanditArcher),
      ("city-guard", CityGuard),
      ("city-archer", CityArcher),
      ("inox-guard", InoxGuard),
      ("inox-archer", InoxArcher),
      ("inox-shaman", InoxShaman),
      ("valrath-tracker", ValrathTracker),
      ("valrath-savage", ValrathSavage),
      ("vermling-scout", VermlingScout),
      ("vermling-shaman", VermlingShaman),
      ("living-bones", LivingBones),
      ("living-corpse", LivingCorpse),
      ("living-spirit", LivingSpirit),
      ("cultist", Cultist),
      ("flame-demon", FlameDemon),
      ("frost-demon", FrostDemon),
      ("earth-demon", EarthDemon),
      ("wind-demon", WindDemon),
      ("night-demon", NightDemon),
      ("sun-demon", SunDemon),
      ("ooze", Ooze),
      ("giant-viper", GiantViper),
      ("forest-imp", ForestImp),
      ("hound", Hound),
      ("cave-bear", CaveBear),
      ("stone-golem", StoneGolem),
      ("ancient-artillery", AncientArtillery),
      ("rending-drake", RendingDrake),
      ("spitting-drake", SpittingDrake),
      ("lurker", Lurker),
      ("savvas-icestorm", SavvasIcestorm),
      ("savvas-lavaflow", SavvaLavaflow),
      ("harrower-infester", HarrowerInfester),
      ("deep-terror", DeepTerror),
      ("black-imp", BlackImp)
    )

  private val bossDict: Map[String, BossType] =
    import BossType.*
    Map(
      ("bandit-commander", BanditCommander),
      ("human-commander", HumanCommander),
      ("valrath-commander", ValrathCommander),
      ("merciless-overseer", MercilessOverseer),
      ("inox-bodyguard", InoxBodyguard),
      ("captain-of-the-guard", CaptainOfTheGuard),
      ("jekserah", Jekserah),
      ("prime-demon", PrimeDemon),
      ("elder-drake", ElderDrake),
      ("the-betrayer", TheBetrayer),
      ("the-colorless", TheColorless),
      ("the-sightless-eye", TheSightlessEye),
      ("dark-rider", DarkRider),
      ("winged-horror", WingedHorror),
      ("the-gloom", TheGloom),
      ("manifestation-of-corruption", ManifestationOfCorruption)
    )

  val getAllMonsters: Map[String, NormalMonsterType] = normalDict

  val getAllBosses: Map[String, BossType] = bossDict

  def stringToMonsterType(monster: String): Option[MonsterType] =
    normalDict.get(monster.toLowerCase()) match
      case Some(m) =>
        Option(MonsterType.Normal(m))

      case None =>
        bossDict.get(monster.toLowerCase()).map(v => MonsterType.Boss(v))

  def monsterTypeToString(monster: MonsterType): Option[String] =
    monster match
      case MonsterType.Normal(m) =>
        normalDict.toList.filter(_ == m).headOption.map(_._1)

      case MonsterType.Boss(b) =>
        bossDict.toList.filter(_ == b).headOption.map(_._1)

  def getMonsterBucketSize(monster: MonsterType): Int =
    monster match
      case MonsterType.Boss(b) =>
        b match
          case BossType.InoxBodyguard => 2
          case _                      => 1

      case MonsterType.Normal(t) =>
        import NormalMonsterType.*
        t match
          case AestherAshblade  => 4
          case AestherScout     => 4
          case BanditGuard      => 6
          case BanditArcher     => 6
          case CityGuard        => 6
          case CityArcher       => 6
          case InoxGuard        => 6
          case InoxArcher       => 6
          case InoxShaman       => 4
          case ValrathTracker   => 6
          case ValrathSavage    => 6
          case VermlingScout    => 10
          case VermlingShaman   => 6
          case LivingBones      => 10
          case LivingCorpse     => 6
          case LivingSpirit     => 6
          case Cultist          => 6
          case FlameDemon       => 6
          case FrostDemon       => 6
          case EarthDemon       => 6
          case WindDemon        => 6
          case NightDemon       => 6
          case SunDemon         => 6
          case Ooze             => 10
          case GiantViper       => 10
          case ForestImp        => 10
          case Hound            => 6
          case CaveBear         => 4
          case StoneGolem       => 6
          case AncientArtillery => 6
          case RendingDrake     => 6
          case SpittingDrake    => 6
          case Lurker           => 6
          case SavvasIcestorm   => 4
          case SavvaLavaflow    => 4
          case HarrowerInfester => 4
          case DeepTerror       => 10
          case BlackImp         => 10

enum MonsterType:
  case Normal(normalType: NormalMonsterType)
  case Boss(bossType: BossType)

enum MonsterLevel:
  case None
  case Normal
  case Elite

enum NormalMonsterType:
  case AestherAshblade
  case AestherScout
  case BanditGuard
  case BanditArcher
  case CityGuard
  case CityArcher
  case InoxGuard
  case InoxArcher
  case InoxShaman
  case ValrathTracker
  case ValrathSavage
  case VermlingScout
  case VermlingShaman
  case LivingBones
  case LivingCorpse
  case LivingSpirit
  case Cultist
  case FlameDemon
  case FrostDemon
  case EarthDemon
  case WindDemon
  case NightDemon
  case SunDemon
  case Ooze
  case GiantViper
  case ForestImp
  case Hound
  case CaveBear
  case StoneGolem
  case AncientArtillery
  case RendingDrake
  case SpittingDrake
  case Lurker
  case SavvasIcestorm
  case SavvaLavaflow
  case HarrowerInfester
  case DeepTerror
  case BlackImp

enum BossType:
  case BanditCommander
  case HumanCommander
  case ValrathCommander
  case MercilessOverseer
  case InoxBodyguard
  case CaptainOfTheGuard
  case Jekserah
  case PrimeDemon
  case ElderDrake
  case TheBetrayer
  case TheColorless
  case TheSightlessEye
  case DarkRider
  case WingedHorror
  case TheGloom
  case ManifestationOfCorruption

final case class Monster(monster: MonsterType, id: Int, level: MonsterLevel, wasSummoned: Boolean, outOfPhase: Boolean)
