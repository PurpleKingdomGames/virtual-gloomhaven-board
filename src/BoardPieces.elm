module BoardPieces exposing (BoardPiece, BoardRef(..), getGridByRef, refToString)

import Array exposing (Array)


type BoardRef
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


type alias BoardPiece =
    { ref : BoardRef
    , x : Int
    , y : Int
    , rotated : Bool
    }


getGridByRef : BoardRef -> Array (Array Int)
getGridByRef ref =
    let
        configA =
            [ Array.fromList [ 0, 0, 0, 0, 0 ]
            , Array.fromList [ 1, 1, 1, 1, 0 ]
            , Array.fromList [ 1, 1, 1, 1, 1 ]
            , Array.fromList [ 0, 0, 0, 0, 0 ]
            ]

        configB =
            [ Array.fromList [ 1, 1, 1, 1 ]
            , Array.fromList [ 1, 1, 1, 0 ]
            , Array.fromList [ 1, 1, 1, 1 ]
            , Array.fromList [ 1, 1, 1, 0 ]
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
        )


refToString : BoardRef -> String
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
