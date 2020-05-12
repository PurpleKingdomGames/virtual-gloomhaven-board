module Character exposing (CharacterClass(..), characterToString, stringToCharacter)

import Dict exposing (filter, fromList, get, toList)
import List exposing (head)


characterDict =
    fromList
        [ ( "brute", Brute )
        , ( "cragheart", Cragheart )
        , ( "mindthief", Mindthief )
        , ( "scoundrel", Scoundrel )
        , ( "spellweaver", Spellweaver )
        , ( "tinkerer", Tinkerer )
        ]


type CharacterClass
    = Brute
    | Cragheart
    | Mindthief
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
