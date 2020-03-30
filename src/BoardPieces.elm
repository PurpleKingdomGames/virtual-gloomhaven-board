module BoardPieces exposing (BoardPiece, getGridByRef)

import Array exposing (Array)


type alias BoardPiece =
    { ref : String
    , x : Int
    , y : Int
    , rotated : Bool
    }


getGridByRef : String -> Array (Array Int)
getGridByRef ref =
    Array.fromList
        (case String.toLower ref of
            "a1a" ->
                [ Array.fromList [ 0, 0, 0, 0, 0 ]
                , Array.fromList [ 1, 1, 1, 1, 0 ]
                , Array.fromList [ 1, 1, 1, 1, 1 ]
                , Array.fromList [ 0, 0, 0, 0, 0 ]
                ]

            _ ->
                []
        )
