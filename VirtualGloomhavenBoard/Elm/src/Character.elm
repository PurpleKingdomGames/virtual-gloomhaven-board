module Character exposing (CharacterClass(..), characterDictionary, characterToString, stringToCharacter)

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
        ]


type CharacterClass
    = BeastTyrant
    | Berserker
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
