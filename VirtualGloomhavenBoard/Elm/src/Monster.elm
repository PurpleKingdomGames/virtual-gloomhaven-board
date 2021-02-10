module Monster exposing (BossType(..), Monster, MonsterLevel(..), MonsterType(..), NormalMonsterType(..), getAllBosses, getAllMonsters, getMonsterBucketSize, monsterTypeToString, stringToMonsterType)

import Dict exposing (Dict, filter, fromList, get, toList)
import List exposing (head)


normalDict : Dict String NormalMonsterType
normalDict =
    fromList
        [ ( "aesther-ashblade", AestherAshblade )
        , ( "aesther-scout", AestherScout )
        , ( "bandit-guard", BanditGuard )
        , ( "bandit-archer", BanditArcher )
        , ( "city-guard", CityGuard )
        , ( "city-archer", CityArcher )
        , ( "inox-guard", InoxGuard )
        , ( "inox-archer", InoxArcher )
        , ( "inox-shaman", InoxShaman )
        , ( "valrath-tracker", ValrathTracker )
        , ( "valrath-savage", ValrathSavage )
        , ( "vermling-scout", VermlingScout )
        , ( "vermling-shaman", VermlingShaman )
        , ( "living-bones", LivingBones )
        , ( "living-corpse", LivingCorpse )
        , ( "living-spirit", LivingSpirit )
        , ( "cultist", Cultist )
        , ( "flame-demon", FlameDemon )
        , ( "frost-demon", FrostDemon )
        , ( "earth-demon", EarthDemon )
        , ( "wind-demon", WindDemon )
        , ( "night-demon", NightDemon )
        , ( "sun-demon", SunDemon )
        , ( "ooze", Ooze )
        , ( "giant-viper", GiantViper )
        , ( "forest-imp", ForestImp )
        , ( "hound", Hound )
        , ( "cave-bear", CaveBear )
        , ( "stone-golem", StoneGolem )
        , ( "ancient-artillery", AncientArtillery )
        , ( "rending-drake", RendingDrake )
        , ( "spitting-drake", SpittingDrake )
        , ( "lurker", Lurker )
        , ( "savvas-icestorm", SavvasIcestorm )
        , ( "savvas-lavaflow", SavvaLavaflow )
        , ( "harrower-infester", HarrowerInfester )
        , ( "deep-terror", DeepTerror )
        , ( "black-imp", BlackImp )
        ]


bossDict : Dict String BossType
bossDict =
    fromList
        [ ( "bandit-commander", BanditCommander )
        , ( "human-commander", HumanCommander )
        , ( "valrath-commander", ValrathCommander )
        , ( "merciless-overseer", MercilessOverseer )
        , ( "inox-bodyguard", InoxBodyguard )
        , ( "captain-of-the-guard", CaptainOfTheGuard )
        , ( "jekserah", Jekserah )
        , ( "prime-demon", PrimeDemon )
        , ( "elder-drake", ElderDrake )
        , ( "the-betrayer", TheBetrayer )
        , ( "the-colorless", TheColorless )
        , ( "the-sightless-eye", TheSightlessEye )
        , ( "dark-rider", DarkRider )
        , ( "winged-horror", WingedHorror )
        , ( "the-gloom", TheGloom )
        , ( "manifestation-of-corruption", ManifestationOfCorruption )
        ]


type MonsterType
    = NormalType NormalMonsterType
    | BossType BossType


type MonsterLevel
    = None
    | Normal
    | Elite


type NormalMonsterType
    = AestherAshblade
    | AestherScout
    | BanditGuard
    | BanditArcher
    | CityGuard
    | CityArcher
    | InoxGuard
    | InoxArcher
    | InoxShaman
    | ValrathTracker
    | ValrathSavage
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
    | RendingDrake
    | SpittingDrake
    | Lurker
    | SavvasIcestorm
    | SavvaLavaflow
    | HarrowerInfester
    | DeepTerror
    | BlackImp


type BossType
    = BanditCommander
    | HumanCommander
    | ValrathCommander
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
    | TheGloom
    | ManifestationOfCorruption


type alias Monster =
    { monster : MonsterType
    , id : Int
    , level : MonsterLevel
    , wasSummoned : Bool
    }


getAllMonsters : Dict String NormalMonsterType
getAllMonsters =
    normalDict


getAllBosses : Dict String BossType
getAllBosses =
    bossDict


stringToMonsterType : String -> Maybe MonsterType
stringToMonsterType monster =
    case get (String.toLower monster) normalDict of
        Just m ->
            Just (NormalType m)

        Nothing ->
            Maybe.map (\v -> BossType v) (get (String.toLower monster) bossDict)


monsterTypeToString : MonsterType -> Maybe String
monsterTypeToString monster =
    case monster of
        NormalType m ->
            let
                maybeKey =
                    head (toList (filter (\_ v -> v == m) normalDict))
            in
            Maybe.map (\( k, _ ) -> k) maybeKey

        BossType b ->
            let
                maybeKey =
                    head (toList (filter (\_ v -> v == b) bossDict))
            in
            Maybe.map (\( k, _ ) -> k) maybeKey


getMonsterBucketSize : MonsterType -> Int
getMonsterBucketSize monster =
    case monster of
        BossType b ->
            case b of
                InoxBodyguard ->
                    2

                _ ->
                    1

        NormalType t ->
            case t of
                AestherAshblade ->
                    6

                AestherScout ->
                    6

                BanditGuard ->
                    6

                BanditArcher ->
                    6

                CityGuard ->
                    6

                CityArcher ->
                    6

                InoxGuard ->
                    6

                InoxArcher ->
                    6

                InoxShaman ->
                    4

                ValrathTracker ->
                    6

                ValrathSavage ->
                    6

                VermlingScout ->
                    10

                VermlingShaman ->
                    6

                LivingBones ->
                    10

                LivingCorpse ->
                    6

                LivingSpirit ->
                    6

                Cultist ->
                    6

                FlameDemon ->
                    6

                FrostDemon ->
                    6

                EarthDemon ->
                    6

                WindDemon ->
                    6

                NightDemon ->
                    6

                SunDemon ->
                    6

                Ooze ->
                    10

                GiantViper ->
                    10

                ForestImp ->
                    10

                Hound ->
                    6

                CaveBear ->
                    4

                StoneGolem ->
                    6

                AncientArtillery ->
                    6

                RendingDrake ->
                    6

                SpittingDrake ->
                    6

                Lurker ->
                    6

                SavvasIcestorm ->
                    4

                SavvaLavaflow ->
                    4

                HarrowerInfester ->
                    4

                DeepTerror ->
                    10

                BlackImp ->
                    10
