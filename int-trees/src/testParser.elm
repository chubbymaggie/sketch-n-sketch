module TestParser where

import Lang
import LangParser (parseV, parseE, freshen)

_ `ignore` _ = ()

--------------------------------------------------------------------------------

-- right now, these always get run

testParser = ()

  `ignore` parseV "1"
  `ignore` parseV "[1]"
  `ignore` parseV " []"
  `ignore` parseV " [1  2 3]   "

  `ignore` parseE "(\\x 1)"
  `ignore` parseE "(\\(x y z) 1)"
  `ignore` parseE "(let f (\\x (\\y [(+ x 0) (+ x y)])) ((f 3) 5))"
  `ignore` parseE "(let f (\\x (\\y [(+ x 0) (+ x y)])) (f 3 5))"
  `ignore` parseE "(let f (\\(x y) [(+ x 0) (+ x y)]) (f 3 5))"
  `ignore` parseE "(let f (\\(x y) [(+ x 0) (+ x y)]) ((f 3) 5))"

  `ignore` parseE "true"
  `ignore` parseE "(< 1 2)"
  `ignore` parseE "(if true 2 [3])"
  `ignore` parseE "(if (< 1 2) [3] [])"

--------------------------------------------------------------------------------

test0 () =
  let
    se = "
      (let f (\\(x y) [(+ x 0) (+ x y)])
        (f 3 5))
    "
    
    e   = se |> parseE |> freshen 1 |> fst
    v   = Lang.run e
    sv' = "[3 9]"
    v'  = parseV sv'
  in
  {e=e, v=v, vnew=v'}

test1 () =
  let
    se  = "(if (< 1 2) (+ 2 4) (+ 3 3))"
    e   = se |> parseE |> freshen 1 |> fst
    v   = Lang.run e
    sv' = "10"
    v'  = parseV sv'
  in
  {e=e, v=v, vnew=v'}

