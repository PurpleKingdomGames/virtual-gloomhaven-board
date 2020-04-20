module BoardMapTiles exposing (MapTile, MapTileRef(..), getGridByRef, getMapTileListByRef, refToString)

import Array exposing (Array)


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


type alias MapTile =
    { ref : MapTileRef
    , x : Int
    , y : Int
    , originalX : Int
    , originalY : Int
    , passable : Bool
    , hidden : Bool
    }


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
        )


refToString : MapTileRef -> String
refToString ref =
    case ref of
        A1a ->
            "a1a"

        A1b ->
            "a1b"

        A2a ->
            "a2a"

        A2b ->
            "a2b"

        A3a ->
            "a3a"

        A3b ->
            "a3b"

        A4a ->
            "a4a"

        A4b ->
            "a4b"

        B1a ->
            "b1a"

        B1b ->
            "b1b"

        B2a ->
            "b2a"

        B2b ->
            "b2b"

        B3a ->
            "b3a"

        B3b ->
            "b3b"

        B4a ->
            "b4a"

        B4b ->
            "b4b"

        C1a ->
            "c1a"

        C1b ->
            "c1b"

        C2a ->
            "c2a"

        C2b ->
            "c2b"

        D1a ->
            "d1a"

        D1b ->
            "d1b"

        D2a ->
            "d2a"

        D2b ->
            "d2b"

        E1a ->
            "e1a"

        E1b ->
            "e1b"

        F1a ->
            "f1a"

        F1b ->
            "f1b"

        G1a ->
            "g1a"

        G1b ->
            "g1b"

        G2a ->
            "g2a"

        G2b ->
            "g2b"

        H1a ->
            "h1a"

        H1b ->
            "h1b"

        H2a ->
            "h2a"

        H2b ->
            "h2b"

        H3a ->
            "h3a"

        H3b ->
            "h3b"

        I1a ->
            "i1a"

        I1b ->
            "i1b"

        I2a ->
            "i2a"

        I2b ->
            "i2b"

        J1a ->
            "j1a"

        J1b ->
            "j1b"

        J2a ->
            "j2a"

        J2b ->
            "j2b"

        K1a ->
            "k1a"

        K1b ->
            "k1b"

        K2a ->
            "k2a"

        K2b ->
            "k2b"

        L1a ->
            "l1a"

        L1b ->
            "l1b"

        L2a ->
            "l2a"

        L2b ->
            "l2b"

        L3a ->
            "l3a"

        L3b ->
            "l3b"

        M1a ->
            "m1a"

        M1b ->
            "m1b"

        N1a ->
            "n1a"

        N1b ->
            "n1b"


indexedArrayYToMapTile : MapTileRef -> Int -> Array Bool -> List MapTile
indexedArrayYToMapTile ref y arr =
    Array.indexedMap (indexedArrayXToMapTile ref y) arr
        |> Array.toList


indexedArrayXToMapTile : MapTileRef -> Int -> Int -> Bool -> MapTile
indexedArrayXToMapTile ref y x passable =
    MapTile ref x y x y passable True
