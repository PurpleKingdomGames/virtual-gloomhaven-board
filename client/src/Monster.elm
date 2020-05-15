module Monster exposing (BossType(..), Monster, MonsterLevel(..), MonsterType(..), NormalMonsterType(..), monsterTypeToString, stringToMonsterType)

import Dict exposing (Dict, filter, fromList, get, toList)
import List exposing (head)


normalDict : Dict String NormalMonsterType
normalDict =
    fromList
        [ ( "bandit-guard", BanditGuard )
        , ( "bandit-archer", BanditArcher )
        , ( "city-guard", CityGuard )
        , ( "city-archer", CityArcher )
        , ( "inox-guard", InoxGuard )
        , ( "inox-archer", InoxArcher )
        , ( "inox-shaman", InoxShaman )
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
        , ( "fores-timp", ForestImp )
        , ( "hound", Hound )
        , ( "cave-bear", CaveBear )
        , ( "stone-golem", StoneGolem )
        , ( "ancient-artillery", AncientArtillery )
        , ( "vicious-drake", ViciousDrake )
        , ( "spitting-drake", SpittingDrake )
        , ( "lurker", Lurker )
        , ( "savvas-icestorm", SavvasIcestorm )
        , ( "savva-lavaflow", SavvaLavaflow )
        , ( "harrower-infester", HarrowerInfester )
        , ( "deep-terror", DeepTerror )
        , ( "black-imp", BlackImp )
        ]


bossDict : Dict String BossType
bossDict =
    fromList
        [ ( "bandit-commander", BanditCommander )
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
        ]


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
    | TheGloom


type alias Monster =
    { monster : MonsterType
    , id : Int
    , level : MonsterLevel
    }


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
