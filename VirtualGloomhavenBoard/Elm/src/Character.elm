module Character exposing (CharacterClass(..), characterDictionary, characterToString, getSoloScenarios, stringToCharacter)

import Dict exposing (Dict, filter, fromList, get, toList)
import List exposing (head)


characterDictionary : Dict String CharacterClass
characterDictionary =
    fromList
        [ ( "brute", Brute )
        , ( "tinkerer", Tinkerer )
        , ( "scoundrel", Scoundrel )
        , ( "cragheart", Cragheart )
        , ( "mindthief", Mindthief )
        , ( "spellweaver", Spellweaver )
        , ( "diviner", Diviner )

        -- Unlockable Characters
        , ( "phoenix-face", BeastTyrant )
        , ( "lightning-bolt", Berserker )
        , ( "angry-face", Doomstalker )
        , ( "triforce", Elementalist )
        , ( "eclipse", Nightshroud )
        , ( "cthulhu", PlagueHerald )
        , ( "three-spears", Quartermaster )
        , ( "saw", Sawbones )
        , ( "music-note", Soothsinger )
        , ( "concentric-circles", Summoner )
        , ( "sun", Sunkeeper )
        , ( "envelope-x", Bladeswarm )
        ]


soloScenarioDict : Dict String ( Int, String )
soloScenarioDict =
    fromList
        [ ( "brute", ( 1, "Return to Black Barrow" ) )
        , ( "tinkerer", ( 2, "An Unfortunate Intrusion" ) )
        , ( "scoundrel", ( 4, "Armory Heist" ) )
        , ( "cragheart", ( 5, "Stone Defense" ) )
        , ( "mindthief", ( 6, "Rodent Liberation" ) )
        , ( "spellweaver", ( 3, "Corrupted Laboratory" ) )
        , ( "diviner", ( 18, "Forecast of the Inevitable" ) )

        -- Unlockable Characters
        , ( "phoenix-face", ( 17, "The Caged Bear" ) )
        , ( "lightning-bolt", ( 8, "Unnatural Insults" ) )
        , ( "angry-face", ( 14, "Corrupted Hunt" ) )
        , ( "triforce", ( 16, "Elemental Secrets" ) )
        , ( "eclipse", ( 11, "Harvesting the Night" ) )
        , ( "cthulhu", ( 12, "Plagued Crypt" ) )
        , ( "three-spears", ( 9, "Storage Fees" ) )
        , ( "saw", ( 15, "Aftermath" ) )
        , ( "music-note", ( 13, "Battle of the Bards" ) )
        , ( "concentric-circles", ( 10, "Plane of Wild Beasts" ) )
        , ( "sun", ( 7, "Caravan Escort" ) )
        ]


type CharacterClass
    = BeastTyrant
    | Berserker
    | Bladeswarm
    | Brute
    | Cragheart
    | Diviner
    | Doomstalker
    | Elementalist
    | Mindthief
    | Nightshroud
    | PlagueHerald
    | Quartermaster
    | Sawbones
    | Scoundrel
    | Soothsinger
    | Spellweaver
    | Summoner
    | Sunkeeper
    | Tinkerer


characterToString : CharacterClass -> Maybe String
characterToString character =
    let
        maybeKey =
            head (toList (filter (\_ v -> v == character) characterDictionary))
    in
    Maybe.map (\( k, _ ) -> k) maybeKey


stringToCharacter : String -> Maybe CharacterClass
stringToCharacter character =
    get (String.toLower character) characterDictionary


getSoloScenarios : Dict String ( Int, String )
getSoloScenarios =
    soloScenarioDict
