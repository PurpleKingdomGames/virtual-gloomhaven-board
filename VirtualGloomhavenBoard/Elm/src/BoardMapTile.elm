module BoardMapTile exposing (MapTile, MapTileRef(..), getAllRefs, getGridByRef, getMapTileListByRef, refToString, stringToRef)

import Array exposing (Array)
import Dict exposing (Dict, filter, get, toList)
import List exposing (head)


type MapTileRef
    = A1a
    | A1b
    | A2a
    | A2b
    | A3a
    | A3b
    | A4a
    | A4b
    | B1a
    | B1b
    | B2a
    | B2b
    | B3a
    | B3b
    | B4a
    | B4b
    | C1a
    | C1b
    | C2a
    | C2b
    | D1a
    | D1b
    | D2a
    | D2b
    | E1a
    | E1b
    | F1a
    | F1b
    | G1a
    | G1b
    | G2a
    | G2b
    | H1a
    | H1b
    | H2a
    | H2b
    | H3a
    | H3b
    | I1a
    | I1b
    | I2a
    | I2b
    | J1a
    | J1b
    | J1ba
    | J1bb
    | J2a
    | J2b
    | K1a
    | K1b
    | K2a
    | K2b
    | L1a
    | L1b
    | L2a
    | L2b
    | L3a
    | L3b
    | M1a
    | M1b
    | N1a
    | N1b
    | Empty


type alias MapTile =
    { ref : MapTileRef
    , x : Int
    , y : Int
    , turns : Int
    , originalX : Int
    , originalY : Int
    , passable : Bool
    , hidden : Bool
    }


boardRefDict : Dict String MapTileRef
boardRefDict =
    Dict.fromList
        [ ( "a1a", A1a )
        , ( "a1b", A1b )
        , ( "a2a", A2a )
        , ( "a2b", A2b )
        , ( "a3a", A3a )
        , ( "a3b", A3b )
        , ( "a4a", A4a )
        , ( "a4b", A4b )
        , ( "b1a", B1a )
        , ( "b1b", B1b )
        , ( "b2a", B2a )
        , ( "b2b", B2b )
        , ( "b3a", B3a )
        , ( "b3b", B3b )
        , ( "b4a", B4a )
        , ( "b4b", B4b )
        , ( "c1a", C1a )
        , ( "c1b", C1b )
        , ( "c2a", C2a )
        , ( "c2b", C2b )
        , ( "d1a", D1a )
        , ( "d1b", D1b )
        , ( "d2a", D2a )
        , ( "d2b", D2b )
        , ( "e1a", E1a )
        , ( "e1b", E1b )
        , ( "f1a", F1a )
        , ( "f1b", F1b )
        , ( "g1a", G1a )
        , ( "g1b", G1b )
        , ( "g2a", G2a )
        , ( "g2b", G2b )
        , ( "h1a", H1a )
        , ( "h1b", H1b )
        , ( "h2a", H2a )
        , ( "h2b", H2b )
        , ( "h3a", H3a )
        , ( "h3b", H3b )
        , ( "i1a", I1a )
        , ( "i1b", I1b )
        , ( "i2a", I2a )
        , ( "i2b", I2b )
        , ( "j1a", J1a )
        , ( "j1b", J1b )
        , ( "j1ba", J1ba )
        , ( "j1bb", J1bb )
        , ( "j2a", J2a )
        , ( "j2b", J2b )
        , ( "k1a", K1a )
        , ( "k1b", K1b )
        , ( "k2a", K2a )
        , ( "k2b", K2b )
        , ( "l1a", L1a )
        , ( "l1b", L1b )
        , ( "l2a", L2a )
        , ( "l2b", L2b )
        , ( "l3a", L3a )
        , ( "l3b", L3b )
        , ( "m1a", M1a )
        , ( "m1b", M1b )
        , ( "n1a", N1a )
        , ( "n1b", N1b )
        , ( "empty", Empty )
        ]


getMapTileListByRef : MapTileRef -> List MapTile
getMapTileListByRef ref =
    Array.indexedMap (indexedArrayYToMapTile ref) (getGridByRef ref)
        |> Array.toList
        |> List.concat


getGridByRef : MapTileRef -> Array (Array Bool)
getGridByRef ref =
    let
        configA =
            [ Array.fromList [ False, False, False, False, False ]
            , Array.fromList [ True, True, True, True, False ]
            , Array.fromList [ True, True, True, True, True ]
            , Array.fromList [ False, False, False, False, False ]
            ]

        configB =
            [ Array.fromList [ True, True, True, True ]
            , Array.fromList [ True, True, True, False ]
            , Array.fromList [ True, True, True, True ]
            , Array.fromList [ True, True, True, False ]
            ]

        configC =
            [ Array.fromList [ False, True, True, False ]
            , Array.fromList [ True, True, True, False ]
            , Array.fromList [ True, True, True, True ]
            , Array.fromList [ True, True, True, False ]
            ]

        configD =
            [ Array.fromList [ False, True, True, True, False ]
            , Array.fromList [ True, True, True, True, False ]
            , Array.fromList [ True, True, True, True, True ]
            , Array.fromList [ True, True, True, True, False ]
            , Array.fromList [ False, True, True, True, False ]
            ]

        configE =
            [ Array.fromList [ False, True, True, True, True ]
            , Array.fromList [ True, True, True, True, True ]
            , Array.fromList [ False, True, True, True, True ]
            , Array.fromList [ True, True, True, True, True ]
            , Array.fromList [ False, True, True, True, True ]
            ]

        configF =
            [ Array.fromList [ True, True, True ]
            , Array.fromList [ True, True, False ]
            , Array.fromList [ True, True, True ]
            , Array.fromList [ True, True, False ]
            , Array.fromList [ True, True, True ]
            , Array.fromList [ True, True, False ]
            , Array.fromList [ True, True, True ]
            , Array.fromList [ True, True, False ]
            , Array.fromList [ True, True, True ]
            ]

        configG =
            [ Array.fromList [ True, True, True, True, True, True, True, True ]
            , Array.fromList [ True, True, True, True, True, True, True, False ]
            , Array.fromList [ True, True, True, True, True, True, True, True ]
            ]

        configH =
            [ Array.fromList [ False, True, True, True, True, True, True ]
            , Array.fromList [ True, True, True, True, True, True, True ]
            , Array.fromList [ False, False, False, True, True, False, False ]
            , Array.fromList [ False, False, True, True, True, False, False ]
            , Array.fromList [ False, False, False, True, True, False, False ]
            , Array.fromList [ False, False, True, True, True, False, False ]
            , Array.fromList [ False, False, False, True, True, False, False ]
            ]

        configI =
            [ Array.fromList [ True, True, True, True, True, True ]
            , Array.fromList [ True, True, True, True, True, False ]
            , Array.fromList [ True, True, True, True, True, True ]
            , Array.fromList [ True, True, True, True, True, False ]
            , Array.fromList [ True, True, True, True, True, True ]
            ]

        configJ =
            [ Array.fromList [ False, False, False, False, False, False, True, False ]
            , Array.fromList [ False, False, False, False, False, True, True, True ]
            , Array.fromList [ False, False, False, False, False, True, True, True ]
            , Array.fromList [ False, False, False, False, True, True, True, False ]
            , Array.fromList [ True, True, True, True, True, True, True, False ]
            , Array.fromList [ True, True, True, True, True, True, False, False ]
            , Array.fromList [ True, True, True, True, True, False, False, False ]
            ]

        configJ1ba =
            [ Array.fromList [ False, False, False, False, False, False, False, False ]
            , Array.fromList [ False, False, False, False, True, True, False, False ]
            , Array.fromList [ False, False, False, False, True, True, True, False ]
            , Array.fromList [ False, False, False, False, True, True, True, False ]
            , Array.fromList [ False, False, False, False, False, True, True, True ]
            , Array.fromList [ False, False, False, False, False, True, False, False ]
            , Array.fromList [ False, False, False, False, False, False, False, False ]
            ]

        configJ1bb =
            [ Array.fromList [ True, True, True, True, True, False, False, False ]
            , Array.fromList [ True, True, True, True, False, False, False, False ]
            , Array.fromList [ True, True, True, True, False, False, False, False ]
            , Array.fromList [ False, False, False, False, False, False, False, False ]
            , Array.fromList [ False, False, False, False, False, False, False, False ]
            , Array.fromList [ False, False, False, False, False, False, False, False ]
            , Array.fromList [ False, False, False, False, False, False, False, False ]
            ]

        configK =
            [ Array.fromList [ False, False, True, True, True, True, False, False ]
            , Array.fromList [ False, True, True, True, True, True, False, False ]
            , Array.fromList [ False, True, True, True, True, True, True, False ]
            , Array.fromList [ True, True, True, False, True, True, True, False ]
            , Array.fromList [ True, True, True, False, False, True, True, True ]
            , Array.fromList [ True, True, False, False, False, True, True, False ]
            ]

        configL =
            [ Array.fromList [ True, True, True, True, True ]
            , Array.fromList [ True, True, True, True, False ]
            , Array.fromList [ True, True, True, True, True ]
            , Array.fromList [ True, True, True, True, False ]
            , Array.fromList [ True, True, True, True, True ]
            , Array.fromList [ True, True, True, True, False ]
            , Array.fromList [ True, True, True, True, True ]
            ]

        configM =
            [ Array.fromList [ False, True, True, True, True, False ]
            , Array.fromList [ True, True, True, True, True, False ]
            , Array.fromList [ True, True, True, True, True, True ]
            , Array.fromList [ True, True, True, True, True, False ]
            , Array.fromList [ True, True, True, True, True, True ]
            , Array.fromList [ True, True, True, True, True, False ]
            , Array.fromList [ False, True, True, True, True, False ]
            ]

        configN =
            [ Array.fromList [ True, True, True, True, True, True, True, True ]
            , Array.fromList [ True, True, True, True, True, True, True, False ]
            , Array.fromList [ True, True, True, True, True, True, True, True ]
            , Array.fromList [ True, True, True, True, True, True, True, False ]
            , Array.fromList [ True, True, True, True, True, True, True, True ]
            , Array.fromList [ True, True, True, True, True, True, True, False ]
            , Array.fromList [ True, True, True, True, True, True, True, True ]
            ]
    in
    Array.fromList
        (case ref of
            A1a ->
                configA

            A1b ->
                configA

            A2a ->
                configA

            A2b ->
                configA

            A3a ->
                configA

            A3b ->
                configA

            A4a ->
                configA

            A4b ->
                configA

            B1a ->
                configB

            B1b ->
                configB

            B2a ->
                configB

            B2b ->
                configB

            B3a ->
                configB

            B3b ->
                configB

            B4a ->
                configB

            B4b ->
                configB

            C1a ->
                configC

            C1b ->
                configC

            C2a ->
                configC

            C2b ->
                configC

            D1a ->
                configD

            D1b ->
                configD

            D2a ->
                configD

            D2b ->
                configD

            E1a ->
                configE

            E1b ->
                configE

            F1a ->
                configF

            F1b ->
                configF

            G1a ->
                configG

            G1b ->
                configG

            G2a ->
                configG

            G2b ->
                configG

            H1a ->
                configH

            H1b ->
                configH

            H2a ->
                configH

            H2b ->
                configH

            H3a ->
                configH

            H3b ->
                configH

            I1a ->
                configI

            I1b ->
                configI

            I2a ->
                configI

            I2b ->
                configI

            J1a ->
                configJ

            J1b ->
                List.reverse configJ

            J1ba ->
                configJ1ba

            J1bb ->
                configJ1bb

            J2a ->
                configJ

            J2b ->
                List.reverse configJ

            K1a ->
                configK

            K1b ->
                configK

            K2a ->
                configK

            K2b ->
                configK

            L1a ->
                configL

            L1b ->
                configL

            L2a ->
                configL

            L2b ->
                configL

            L3a ->
                configL

            L3b ->
                configL

            M1a ->
                configM

            M1b ->
                configM

            N1a ->
                configN

            N1b ->
                configN

            Empty ->
                [ Array.fromList [ True ] ]
        )


refToString : MapTileRef -> Maybe String
refToString ref =
    let
        maybeKey =
            head (toList (filter (\_ v -> v == ref) boardRefDict))
    in
    Maybe.map (\( k, _ ) -> k) maybeKey


stringToRef : String -> Maybe MapTileRef
stringToRef ref =
    get (String.toLower ref) boardRefDict


getAllRefs : List MapTileRef
getAllRefs =
    Dict.values boardRefDict
        |> List.filter (\r -> r /= Empty)


indexedArrayYToMapTile : MapTileRef -> Int -> Array Bool -> List MapTile
indexedArrayYToMapTile ref y arr =
    Array.indexedMap (indexedArrayXToMapTile ref y) arr
        |> Array.toList


indexedArrayXToMapTile : MapTileRef -> Int -> Int -> Bool -> MapTile
indexedArrayXToMapTile ref y x passable =
    MapTile ref x y 0 x y passable True
