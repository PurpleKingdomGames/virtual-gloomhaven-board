module Monster exposing (BossType(..), Monster, MonsterLevel(..), MonsterType(..), NormalMonsterType(..), getMonsterName)


type MonsterType
    = NormalType NormalMonsterType
    | BossType BossType


type MonsterLevel
    = None
    | Normal
    | Elite


type NormalMonsterType
    = BanditGuard
    | BanditArcher
    | CityGuard
    | CityArcher
    | InoxGuard
    | InoxArcher
    | InoxShaman
    | VermlingScout
    | VermlingShaman
    | LivingBones
    | LivingCorpse
    | LivingSpirit
    | Cultist
    | FlameDemon
    | FrostDemon
    | EarthDemon
    | WindDemon
    | NightDemon
    | SunDemon
    | Ooze
    | GiantViper
    | ForestImp
    | Hound
    | CaveBear
    | StoneGolem
    | AncientArtillery
    | ViciousDrake
    | SpittingDrake
    | Lurker
    | SavvasIcestorm
    | SavvaLavaflow
    | HarrowerInfester
    | DeepTerror
    | BlackImp


type BossType
    = BanditCommander
    | MercilessOverseer
    | InoxBodyguard
    | CaptainOfTheGuard
    | Jekserah
    | PrimeDemon
    | ElderDrake
    | TheBetrayer
    | TheColorless
    | TheSightlessEye
    | DarkRider
    | WingedHorror
    | TheGoom


type alias Monster =
    { monster : MonsterType
    , id : Int
    , level : MonsterLevel
    }


getMonsterName : MonsterType -> String
getMonsterName monster =
    case monster of
        NormalType m ->
            case m of
                BanditGuard ->
                    "bandit-guard"

                BanditArcher ->
                    "bandit-archer"

                CityGuard ->
                    "city-guard"

                CityArcher ->
                    "city-archer"

                InoxGuard ->
                    "inox-guard"

                InoxArcher ->
                    "inox-archer"

                InoxShaman ->
                    "inox-shaman"

                VermlingScout ->
                    "vermling-scout"

                VermlingShaman ->
                    "vermling-shaman"

                LivingBones ->
                    "living-bones"

                LivingCorpse ->
                    "living-corpse"

                LivingSpirit ->
                    "living-spirit"

                Cultist ->
                    "cultist"

                FlameDemon ->
                    "flame-demon"

                FrostDemon ->
                    "frost-demon"

                EarthDemon ->
                    "earth-demon"

                WindDemon ->
                    "wind-demon"

                NightDemon ->
                    "night-demon"

                SunDemon ->
                    "sun-demon"

                Ooze ->
                    "ooze"

                GiantViper ->
                    "giant-viper"

                ForestImp ->
                    "fores-timp"

                Hound ->
                    "hound"

                CaveBear ->
                    "cave-bear"

                StoneGolem ->
                    "stone-golem"

                AncientArtillery ->
                    "ancient-artillery"

                ViciousDrake ->
                    "vicious-drake"

                SpittingDrake ->
                    "spitting-drake"

                Lurker ->
                    "lurker"

                SavvasIcestorm ->
                    "savvas-icestorm"

                SavvaLavaflow ->
                    "savva-lavaflow"

                HarrowerInfester ->
                    "harrower-infester"

                DeepTerror ->
                    "deep-terror"

                BlackImp ->
                    "black-imp"

        BossType b ->
            case b of
                BanditCommander ->
                    "bandit-commander"

                MercilessOverseer ->
                    "merciless-overseer"

                InoxBodyguard ->
                    "inox-bodyguard"

                CaptainOfTheGuard ->
                    "captain-of-the-guard"

                Jekserah ->
                    "jekserah"

                PrimeDemon ->
                    "prime-demon"

                ElderDrake ->
                    "elder-drake"

                TheBetrayer ->
                    "the-betrayer"

                TheColorless ->
                    "the-colorless"

                TheSightlessEye ->
                    "the-sightless-eye"

                DarkRider ->
                    "dark-rider"

                WingedHorror ->
                    "winged-horror"

                TheGoom ->
                    "the-goom"
