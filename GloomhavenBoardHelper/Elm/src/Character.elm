module Character exposing (CharacterClass(..), characterToString, stringToCharacter)

import Dict exposing (Dict, filter, fromList, get, toList)
import List exposing (head)


characterDict : Dict String CharacterClass
characterDict =
    fromList
        [ ( "berserker", Berserker )
        , ( "brute", Brute )
        , ( "cragheart", Cragheart )
        , ( "mindthief", Mindthief )
        , ( "plagueherald", PlagueHerald )
        , ( "quartermaster", Quartermaster )
        , ( "scoundrel", Scoundrel )
        , ( "spellweaver", Spellweaver )
        , ( "tinkerer", Tinkerer )
        ]


type CharacterClass
    = Berserker
    | Brute
    | Cragheart
    | Mindthief
    | PlagueHerald
    | Quartermaster
    | Scoundrel
    | Spellweaver
    | Tinkerer


characterToString : CharacterClass -> Maybe String
characterToString character =
    let
        maybeKey =
            head (toList (filter (\_ v -> v == character) characterDict))
    in
    Maybe.map (\( k, _ ) -> k) maybeKey


stringToCharacter : String -> Maybe CharacterClass
stringToCharacter character =
    get (String.toLower character) characterDict
