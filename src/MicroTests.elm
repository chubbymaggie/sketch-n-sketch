module MicroTests where

import Lang exposing (strVal)
import LangParser2 as Parser
import Eval
import Utils

_ `ignore` _ = ()

--------------------------------------------------------------------------------

-- right now, these always get run

parseE = Utils.fromOk_ << Parser.parseE
parseV = .val << .val << Utils.fromOk_ << Parser.parseV

testParser = ()

  `ignore` parseV "1"
  `ignore` parseV "[1]"
  `ignore` parseV " []"
  `ignore` parseV " [1  2 3]   "
  `ignore` parseV " 1.0 "
  `ignore` parseV " -1.0 "
  `ignore` parseV " -1 "

  `ignore` parseE "(\\x 1)"
  `ignore` parseE "(\\(x y z) 1)"
  `ignore` parseE "(let f (\\x (\\y [(+ x 0) (+ x y)])) ((f 3) 5))"
  `ignore` parseE "(let f (\\x (\\y [(+ x 0) (+ x y)])) (f 3 5))"
  `ignore` parseE "(let f (\\(x y) [(+ x 0) (+ x y)]) (f 3 5))"
  `ignore` parseE "(let f (\\(x y) [(+ x 0) (+ x y)]) ((f 3) 5))"
  `ignore` parseE " (- -1 0) "
  `ignore` parseE " (--1 0) "

  `ignore` parseE "true"
  `ignore` parseE "(< 1 2)"
  `ignore` parseE "(if true 2 [3])"
  `ignore` parseE "(if (< 1 2) [3] [])"

  `ignore` parseE "[1|2]"
  `ignore` parseE "[1 | 2]"
  `ignore` parseE "[1 2 | 3]"
  `ignore` parseE "  [1 | [2 | [3]]]"

  `ignore` parseE "((\\[x] x) [3])"
  `ignore` parseE "((\\  [x] x) [3])"
  `ignore` parseE "((\\[x y z] (+ x (+ y z))) [1 2 3])"

  `ignore` parseE "(let _ [] [])"
  `ignore` parseE "(case [] ([] true) ([_|_] false))"


--------------------------------------------------------------------------------

makeTest : String -> String -> {e:Lang.Exp, v:Lang.Val, vnew:Lang.Val}
makeTest se sv' =
  let e  = parseE se
      v  = Eval.run e
      v' = parseV sv'
  in
  {e=e, v=v, vnew=v'}

test0 () =
  makeTest
    "(let f (\\(x y) [(+ x 0) (+ x y)]) (f 3 5))"
    "[3 9]"

test1 () =
  makeTest
    "(if (< 1 2) (+ 2 4) (+ 3 3))"
    "10"

test2 () =
  makeTest
    "(letrec sum (\\n (if (< n 0) 0 (+ n (sum (- n 1))))) (sum 3))"
    "[]"

test3 () =
  makeTest
    "(letrec fact (\\n (if (< n 1) 1 (* n (fact (- n 1))))) (fact 5))"
    "[]"

test4 () =
  makeTest
    "(letrec foo (\\n (if (< n 1) [] [n (foo (- n 1))]))
     (letrec bar (\\n (if (< n 1) [] [n | (bar (- n 1))]))
       [(foo 5) (bar 5)]))"
    "[]"

test5 () =
  makeTest
    "[1 | [2 | [3]]]"
    "[1 2 3]"

test6 () =
  makeTest
    "(let sum3 (\\[x y z] (+ x (+ y z))) (sum3 [1 2 3]))"
    "[1 2 3]"


test7 () =
  makeTest
    "(let hd (\\[hd | tl] hd) (hd [1 2 3]))"
    "[1 2 3]"

test8 () =
  makeTest
    "(let tl (\\[hd | tl] tl) (tl [1 2 3]))"
    "[1 2 3]"

test9 () =
  makeTest
    "(let [x y z] [1 2 3] (+ x (+ y z)))"
    "[1 2 3]"

test10 () =
  makeTest
    "(let isNil (\\xs (case xs ([] true) ([_|_] false)))
       [(isNil []) (isNil [1])])"
    "[1 2 3]"

test11 () =
  makeTest
    "(let plus1 (\\x (+ x 1))
     (letrec map (\\f (\\xs (case xs ([] []) ([hd|tl] [(f hd)|(map f tl)]))))
       (map plus1 [1 2 3])))"
    "[1 2 3]"

test12 () =
  makeTest
    "(let plus1 (\\x (+ x 1))
     (letrec map (\\(f xs) (case xs ([] []) ([hd|tl] [(f hd)|(map f tl)])))
       (map plus1 [1 2 3])))"
    "[1 2 3]"

test13 () =
  makeTest
    "(letrec mult (\\(m n) (if (< m 1) 0 (+ n (mult (- m 1) n))))
       [(mult 0 10) (mult 2 4) (mult 10 9)])"
    "[1 2 3]"

test14 () =
  makeTest
    "(letrec map (\\(f xs) (case xs ([] []) ([hd|tl] [(f hd)|(map f tl)])))
     (letrec mult (\\(m n) (if (< m 1) 0 (+ n (mult (- m 1) n))))
     (let [x0 y0 sep] [10 8 30]
       (map (\\i [(+ x0 (mult i sep)) y0]) [0 1 2]))))"
    "[[10 8] [40 8] [100 8]]"

test15 () =
  makeTest
    "(let [x0 y0 sep] [10 28 30]
       (svg (map (\\i (circle_ (+ x0 (mult i sep)) y0 10)) [0 1 2])))"
    (strVal (Eval.run (parseE
      "(svg [(circle_ 10 28 10) (circle_ 40 28 10) (circle_ 100 28 10)])")))

test16 () =
  makeTest
    "(let [x0 y0 sep] [10 28 30]
       (svg (map (\\i (circle_ (+ x0 (mult i sep)) y0 10)) [0 1 2])))"
    (strVal (Eval.run (parseE
      "(svg [(circle_ 150 28 10) (circle_ 40 28 10) (circle_ 70 28 10)])")))

test17 () =
  makeTest
    "(let [x0 y0 sep] [10 28 30]
       (svg (map (\\i (circle_ (+ x0 (mult i sep)) y0 10)) [0 1 2])))"
    (strVal (Eval.run (parseE
      "(svg [(circle_ 10 28 10) (circle_ 150 28 10) (circle_ 70 28 10)])")))

test18 () =
  makeTest
    "(let [x0 y0 sep] [10 28 30]
       (svg (map (\\i (square_ (+ x0 (mult i sep)) y0 20)) [0 1 2])))"
    (strVal (Eval.run (parseE
      "(svg [(square_ 150 28 20) (square_ 40 28 20) (square_ 70 28 20)])")))

test19 () =
  makeTest
    "(let [x0 y0 sep] [10 28 30]
       (svg (map (\\i (rect_ (+ x0 (mult i sep)) y0 20 30)) [0 1 2])))"
    "[]"

test20 () =
  makeTest
    "(let i 200 (svg [(line_ 10 20 i 40) (line_ 10 70 i 40)]))"
    (strVal (Eval.run (parseE
      "(svg [(line_ 10 20 300 40) (line_ 10 70 200 40)])")))

test21 () =
  makeTest
    "(svg [(polygon_ [[10 10] [200 10] [100 50]])])"
    "[]"

-- approximation of elm logo:
-- https://github.com/evancz/elm-svg/blob/1.0.2/examples/Logo.elm
--
-- https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/transform
-- http://tutorials.jenkov.com/svg/svg-viewport-view-box.html
--
test22 () =
  makeTest
    "(let foo (\\(color pts) (polygon color 'black' 0 pts))
     [ 'svg' [['x' '0'] ['y' '0'] ['viewBox' '0 0 323.141 322.95']]
       [
       (foo '#F0AD00' [[161 152] [231 82] [91 82]])
       (foo '#7FD13B' [[8 0] [79 70] [232 70] [161 0]])
       (addAttr
          (rect '#7FD13B' 192 107 107 108)
          ['transform' 'matrix(0.7071 0.7071 -0.7071 0.7071 186.4727 -127.2386)'])
       (foo '#60B5CC' [[323 143] [323 0] [179 0]])
       (foo '#5A6378' [[152 161] [0 8] [0 314]])
       (foo '#F0AD00' [[255 246] [323 314] [323 178]])
       (foo '#60B5CC' [[161 170] [8 323] [314 323]])
       ]
     ])"
    "[]"

test23 () =
  makeTest
    "(let [x0 y0 sep] [10 28 30] (svg
       (map2 (\\(i j) (square_ (+ x0 (mult i sep)) (+ y0 (mult j sep)) 20))
             [0 1 2] [0 1 2])))"
    (strVal (Eval.run (parseE
      "(svg [(square_ 150 28 20) (square_ 40 58 20) (square_ 70 88 20)])")))

test24 () =
  makeTest
    "(let [x0 y0 sep] [10 28 30] (svg
       (map2 (\\(i j) (square_ (+ x0 (mult i sep)) (+ y0 (mult j sep)) 20))
             [0 1 2] [0 1 2])))"
    (strVal (Eval.run (parseE
      "(svg [(square_ 10 28 20) (square_ 40 58 20) (square_ 100 88 20)])")))

-- two equations that constrain the same variable, but both have same solution
test25 () =
  makeTest
    "(let [x0 y0 sep] [10 28 30] (svg
       (map2 (\\(i j) (square_ (+ x0 (mult i sep)) (+ y0 (mult j sep)) 20))
             [0 1 2] [0 1 2])))"
    (strVal (Eval.run (parseE
      "(svg [(square_ 10 28 20) (square_ 40 58 20) (square_ 100 118 20)])")))

test26 () =
  makeTest
    "(let [x0 y0 sep] [10 28 30] (svg
       (map (\\[i j] (square_ (+ x0 (mult i sep)) (+ y0 (mult j sep)) 20))
            (cartProd [0 1 2] [0 1]))))"
    "[ 'svg' []
     [['rect' [['x' 10] ['y' 28] ['width' 20] ['height' 20] ['fill' '#999999']] []]
      ['rect' [['x' 10] ['y' 58] ['width' 20] ['height' 20] ['fill' '#999999']] []]
      ['rect' [['x' 40] ['y' 28] ['width' 20] ['height' 20] ['fill' '#999999']] []]
      ['rect' [['x' 40] ['y' 99] ['width' 20] ['height' 20] ['fill' '#999999']] []]
      ['rect' [['x' 70] ['y' 28] ['width' 20] ['height' 20] ['fill' '#999999']] []]
      ['rect' [['x' 70] ['y' 58] ['width' 20] ['height' 20] ['fill' '#999999']] []]]]"

-- changing two leaves, each of which leads to two disjoint solutions
test27 () =
  makeTest
    "(let [x0 y0 xsep ysep] [10 28 30 30] (svg
       (map (\\[i j] (square_ (+ x0 (mult i xsep)) (+ y0 (mult j ysep)) 20))
            (cartProd [0 1 2] [0 1]))))"
    "[ 'svg' []
     [['rect' [['x' 10] ['y' 28] ['width' 20] ['height' 20] ['fill' '#999999']] []]
      ['rect' [['x' 10] ['y' 58] ['width' 20] ['height' 20] ['fill' '#999999']] []]
      ['rect' [['x' 40] ['y' 28] ['width' 20] ['height' 20] ['fill' '#999999']] []]
      ['rect' [['x' 60] ['y' 78] ['width' 20] ['height' 20] ['fill' '#999999']] []]
      ['rect' [['x' 70] ['y' 28] ['width' 20] ['height' 20] ['fill' '#999999']] []]
      ['rect' [['x' 70] ['y' 58] ['width' 20] ['height' 20] ['fill' '#999999']] []]]]"

-- rudimentary olympic rings
test28 () =
  makeTest
    "(let [x0 y0 w r dx dy] [30 30 7 20 32 20]
     (let dxHalf (div dx 2)
     (let row1
       (map (\\[i c] (ring c w (+ x0 (mult i dx)) y0 r))
            (zip [0 1 2] ['blue' 'black' 'red']))
     (let row2
       (map (\\[i c] (ring c w (+ (+ x0 dxHalf) (mult i dx)) (+ y0 dy) r))
            (zip [0 1] ['yellow' 'green']))
       (svg (append row1 row2))))))"
    "[]"

-- similar to test15, but one solution requires floating point division
-- instead of integer division
test29 () =
  makeTest
    "(let [x0 y0 sep] [10 28 30]
       (svg (map (\\i (circle_ (+ x0 (mult i sep)) y0 10)) [0 1 2])))"
    (strVal (Eval.run (parseE
      "(svg [(circle_ 10 28 10) (circle_ 40 28 10) (circle_ 101 28 10)])")))

test30 () =
  makeTest
    "(let [x0 y0 sep rx ry] [10 28 60 15 10]
       (svg (map (\\i (ellipse_ (+ x0 (mult i sep)) y0 rx ry)) [0 1 2])))"
    (strVal (Eval.run (parseE
      "(svg [(ellipse_ 10 28 15 10) (ellipse_ 70 28 25 40) (ellipse_ 130 28 15 10)])")))

test31 () =
  makeTest
    "(let [x0 y0 w h delta] [50 50 200 200 10] (svg
     [ (rect 'white' x0 y0 w h)
       (polygon 'black' 'DUMMY' 0
         [[(+ x0 delta) y0]
          [(+ x0 w) y0]
          [(+ x0 w) (minus (+ y0 h) delta)]])
       (polygon 'black' 'DUMMY' 0
         [[x0 (+ y0 delta)]
          [x0 (minus (+ y0 h) delta)]
          [(minus (+ x0 (div w 2)) delta) (+ y0 (div h 2))]])
       (polygon 'black' 'DUMMY' 0
         [[(+ x0 delta) (+ y0 h)]
          [(minus (+ x0 w) delta) (+ y0 h)]
          [(+ x0 (div w 2)) (+ (+ y0 (div h 2)) delta)]])
     ]))"
    "[]"

test32 () =
  makeTest
    "(let [x0 y0 w h delta] [50 50 200 200 10] (svg
     [ (rect 'white' x0 y0 w h)
       (polyline 'none' 'black' 1
         [[(+ x0 delta) y0]
          [(+ x0 w) y0]
          [(+ x0 w) (minus (+ y0 h) delta)]])
       (polyline 'none' 'black' 1
         [[x0 (+ y0 delta)]
          [x0 (minus (+ y0 h) delta)]
          [(minus (+ x0 (div w 2)) delta) (+ y0 (div h 2))]])
       (polyline 'none' 'black' 1
         [[(+ x0 delta) (+ y0 h)]
          [(minus (+ x0 w) delta) (+ y0 h)]
          [(+ x0 (div w 2)) (+ (+ y0 (div h 2)) delta)]])
     ]))"
    "[]"

test33 () =
  makeTest
    "(svg
     [ (path_ ['M' 10 10 'H' 90 'V' 90 'H' 10 'L' 10 10 'Z'])
       (path_ ['M' 20 20 'L' 60 20 'L' 60 80 'Z'])
       (path_ ['M' 150 0 'L' 75 200 'L' 225 200 'Z'])
     ])"
    "[]"

test34 () =
  makeTest
    "(svg
     [ (path_ ['M' 10 10   'C' 20 20 40 20 50 10])
       (path_ ['M' 70 10   'C' 70 20 120 20 120 10])
       (path_ ['M' 130 10  'C' 120 20 180 20 170 10])
       (path_ ['M' 10 60   'C' 20 80 40 80 50 60])
       (path_ ['M' 70 60   'C' 70 80 110 80 110 60])
       (path_ ['M' 130 60  'C' 120 80 180 80 170 60])
       (path_ ['M' 10 110  'C' 20 140 40 140 50 110])
       (path_ ['M' 70 110  'C' 70 140 110 140 110 110])
       (path_ ['M' 130 110 'C' 120 140 180 140 170 110])
     ])"
    "[]"

test35 () =
  makeTest
    "(svg
     [ (path_ ['M' 10 80 'C' 40 10 65 10 95 80 'S' 150 150 180 80])
       (path_ ['M' 10 80 'Q' 95 10 180 80])
       (path_ ['M' 10 80 'Q' 52.5 10 95 80 'T' 180 80])
     ])"
    "[]"

test36 () =
  makeTest
    "(svg
     [ (addAttr
         (path 'green' 'black' 2
           ['M' 10 315
            'L' 110 215
            'A' 30 50 0 0 1 162.55 162.45
            'L' 172.55 152.45
            'A' 30 50 -45 0 1 215.1 109.9
            'L' 315 10])
         ['opacity' 0.5]) ])"
    "[]"

test37 () =
  makeTest
    "(svg
     [ (path 'green' 'black' 2
         ['M' 80 80 'A' 45 45 0 0 0 125 125 'L' 125 80 'Z'])
       (path 'red' 'black' 2
         ['M' 230 80 'A' 45 45 0 1 0 275 125 'L' 275 80 'Z'])
       (path 'purple' 'black' 2
         ['M' 80 230 'A' 45 45 0 0 1 125 275 'L' 125 230 'Z'])
       (path 'blue' 'black' 2
         ['M' 230 230 'A' 45 45 0 1 1 275 275 'L' 275 230 'Z'])
     ])"
    "[]"

test38 () =
  makeTest
    "(svg
     [ ['text'
         [['x' 10] ['y' 20] ['style' 'fill:red']]
         [['TEXT' 'Several lines:']
          ['tspan' [['x' 10] ['y' 45]] [['TEXT' 'First line.']]]
          ['tspan' [['x' 10] ['y' 70]] [['TEXT' 'Second line.']]] ]]
     ])"
    "[]"

test39 () =
  makeTest
    "['svg'
        [['viewbox' '0 0 95 50']]
        [['g'
           [['stroke' 'green'] ['fill' 'white'] ['stroke-width' 5]]
           [ ['circle' [['cx' 25] ['cy' 25] ['r' 15]] []]
             ['circle' [['cx' 40] ['cy' 25] ['r' 15]] []]
             ['circle' [['cx' 55] ['cy' 25] ['r' 15]] []]
             ['circle' [['cx' 70] ['cy' 25] ['r' 15]] []] ]]]]"
    "[]"

test40 () =
  makeTest
    "['svg'
        [['viewbox' '0 0 95 50']]
        [['g' [['stroke' 'green'] ['fill' 'white'] ['stroke-width' 5]]
             (let [x0 y0 r sep] [25 25 15 15]
               (map (\\i ['circle' [['cx' (+ x0 (mult i sep))] ['cy' y0] ['r' r]] []])
                    [0 1 2 3])) ]]]"
    "[]"

test41 () =
  makeTest
    "(let [x y] [200 150] (svg [
       (rect_ 50 10 80 130)
       (circle 'lightblue' 300 100 50)
       (ellipse_ 40 280 30 50)
       (polygon_ [[110 110] [300 110] [x y]])
       (polygon_ [[110 210] [300 210] [x y]])
       (line_ 10 20 300 40)
     ]))"
    "[]"

test42 () =
  makeTest
    "(let [x0 y0 sep] [40 28 110]
       (svg (map (\\i (rect 'lightblue' (+ x0 (mult i sep)) y0 60 130)) [0 1 2])))"
    "[]"

test43 () =
  makeTest
    "(let [x0 y0 sep] [40 28 110]
       (svg (map (\\i (rect 'lightblue' (+ x0 (* i sep)) y0 60 130)) [0 1 2])))"
    "[]"

-- output of test31, so that Interior of polygons are draggable
test44 () =
  makeTest
    "['svg' [] [['rect' [['x' 50] ['y' 50] ['width' 200] ['height' 200] ['fill'
        'white']] []] ['polygon' [['fill' 'black'] ['points' [[60 50] [250 50] [250
        240]]] ['stroke' 'DUMMY'] ['strokeWidth' 0]] []] ['polygon' [['fill' 'black']
        ['points' [[50 60] [50 240] [140 150]]] ['stroke' 'DUMMY'] ['strokeWidth' 0]]
        []] ['polygon' [['fill' 'black'] ['points' [[60 250] [240 250] [150 160]]]
        ['stroke' 'DUMMY'] ['strokeWidth' 0]] []]]]"
    "[]"

test45 () =
  makeTest
    "(let ngon (\\(n cx cy d)
       (let dangle (/ (* 3! (pi)) 2!)
       (let anglei (\\i (+ dangle (/ (* i (* 2! (pi))) n)))
       (let xi     (\\i (+ cx (* d (cos (anglei i)))))
       (let yi     (\\i (+ cy (* d (sin (anglei i)))))
       (let pti    (\\i [(xi i) (yi i)])
         (polygon_ (map pti (list0N (- n 1!))))))))))
     (svg [
       (ngon 3 100 200 40)
       (ngon 4 200 200 30)
       (ngon 5 300 300 50)
       (ngon 7 300 100 40)
       (ngon 15 100 400 40)
     ]))"
    "[]"

-- disjoint length params for x and y
test46 () =
  makeTest
    "(let ngon (\\(n cx cy len1 len2)
       (let dangle (/ (* 3! (pi)) 2!)
       (let anglei (\\i (+ dangle (/ (* i (* 2! (pi))) n)))
       (let xi     (\\i (+ cx (* len1 (cos (anglei i)))))
       (let yi     (\\i (+ cy (* len2 (sin (anglei i)))))
       (let pti    (\\i [(xi i) (yi i)])
         (polygon_ (map pti (list0N (- n 1!))))))))))
     (svg [
       (ngon 3 100 200 40 40)
       (ngon 4 200 200 30 30)
       (ngon 5 300 300 50 50)
       (ngon 7 300 100 40 40)
       (ngon 15 100 400 40 40)
     ]))"
    "[]"

-- kind of a cool buggy program...
test47 () =
  makeTest
    "(let rot (/ (* 3! (pi)) 2!)
     (let ngonpts (\\(n cx cy len dangle)
       (let anglei (\\i (+ dangle (/ (* i (* 2! (pi))) n)))
       (let xi     (\\i (+ cx (* len (cos (anglei i)))))
       (let yi     (\\i (+ cy (* len (sin (anglei i)))))
       (let pti    (\\i [(xi i) (yi i)])
         (map pti (list0N (- n 1!))))))))
     (svg [
       (polygon_ (ngonpts 5 100 200 40 0))
       (polygon_ (ngonpts 5 100 200 40 (/ (pi) 5)))
       (polygon_ (ngonpts 5 100 100 40 0))
       (polygon_ (ngonpts 5 100 100 10 (/ (pi) 5)))
       (polygon_
         (intermingle
           (ngonpts 5 400 300 40 rot)
           (ngonpts 5 400 300 40 (+ rot (/ (pi) 5)))))
       (polygon_
         (intermingle
           (ngonpts 3 50 400 40 rot)
           (ngonpts 3 50 400 40 (+ rot (/ (pi) 3)))))
       (polygon_
         (intermingle
           (ngonpts 5 400 200 40 rot)
           (ngonpts 5 400 200 10 (+ rot (/ (pi) 5)))))
       (polygon_
         (intermingle
           (ngonpts 3 400 400 40 rot)
           (ngonpts 3 400 400 10 (+ rot (/ (pi) 3)))))
     ])))"
    "[]"

test48 () =
  makeTest
    "(let nstar (\\(n cx cy len1 len2 rot)
       (let pti (\\[i len]
         (let anglei (+ rot (/ (* i (pi)) n))
         (let xi (+ cx (* len (cos anglei)))
         (let yi (+ cy (* len (sin anglei)))
           [xi yi]))))
       (let lengths
         (map (\\b (if b len1 len2))
              (concat (repeat n [true false])))
       (let indices (list0N (- (* 2! n) 1!))
         (polygon_ (map pti (zip indices lengths)))))))

     (let upright (/ (* 3! (pi)) 2!)
     (let [x0 y0 sep ni nj] [100 100 100 3! 7!]
     (let [outerLen innerLen] [50 20]
     (svg
       (map (\\i
              (let off (mult (- i ni) sep)
              (nstar i (+ x0 off) (+ y0 off) outerLen innerLen upright)))
            (range ni nj))
     )))))"
    "[]"

--piechart example, incomplete
test49 () =
  makeTest
    "(let toRadian
    (\\a
      (* (/ (pi) 180!) a))
    (let [sx sy rad] [245 200 175]
    (let cut 
      (\\ang
        (let xend (* rad (cos ang))
        (let yend (* rad (sin ang))
        (line 'white' 6 sx sy (+ sx xend) (+ sy yend)))))
    (let [x0 y0 min max dim p] [80! 470 0! 360! 50! 1]
    (let [a1 a2 a3 a4] [p 45 90 180]
    (let radangs (map toRadian [a1 a2 a3 a4])
    (let cuts (map cut radangs)
    (let samplecirc (circle 'orange' sx sy rad)
    (let button (\\n (square 'lightgray' n y0 dim))
    (let bar (rect 'gray' x0 y0 max dim)
    (let slider
      (if (< a1 max)
        (if (< min a1)
          (button (+ a1 x0))
          (button x0))
        (button (- (+ x0 max) dim)))
      (svg  (append [samplecirc bar slider] cuts)))))))))))))"
    "[]"

--A simple graph (nodes and edges)
test50 () =
    makeTest
      "(let node (\\[x y] (circle 'lightblue' x y 20))
       (let edge (\\[[x y] [i j]] (line 'lightgreen' 5 x y i j))
       (letrec genpairs
          (\\xs
            (case xs
              ([x y | xx] [[x y] | (append (genpairs  (cons x xx)) (genpairs  (cons y xx)))])
              ([x] [])
              ([] [])))
       (let pts [[200 50] [400 50] [100 223] [200 389] [400 391] [500 223]]
       (let nodes (map node pts)
       (let pairs (genpairs  pts)
       (let edges (map edge pairs)
         (svg (append edges nodes)))))))))"
      "[]"

--Chicago Flag Example
test51 () =
  makeTest
    "(let nstar
    (\\(n cx cy len1 len2 rot)
      (let pti
        (\\[i len]
          (let anglei (+ rot (/ (* i (pi)) n))
          (let xi (+ cx (* len (cos anglei)))
          (let yi (+ cy (* len (sin anglei)))
            [xi yi]))))
      (let lengths
        (map
          (\\b
            (if b
              len1
              len2))
          (concat  (repeat n [true false])))
      (let indices (list0N  (- (* 2! n) 1!))
        (polygon 'red' 'DUMMY' 0 (map pti (zip indices lengths)))))))
    (let upright (/ (* 3! (pi)) 2!)
    (let [x0 y0 ni nj pts w h] [108 113 0.5! 3.5! 6! 454 300]
    (let [outerLen innerLen] [30 12]
    (let stripes
      (map
        (\\i
          (rect
            'lightblue'
            x0
            (+ y0 (* i h))
            w
            (/ h 6!)))
        [(/ 1! 6!) (/ 2! 3!)])
      (svg 
        (cons (rect 'white' (- x0 10!) (- y0 10!) (+ w 20!) (+ h 20!))
        (append
          stripes
          (map
            (\\i
              (let off (* i (/ w 4!))
                (nstar pts (+ x0 off) (+ y0 (/ h 2!)) outerLen innerLen upright)))
            (range ni nj))))))))))"
    "[]"

--Frank Lloyd Wright Initial, possibility for topographical maps example?
test52 () =
  makeTest
    "(let [x1 x2 x3 x4 x5 x6 x7 x8] [43 170 295 544 417 783 183 649]
    (let [y1 y2 y3 y4 y5 y6 y7 y8] [45 154 270 376 446 860 213 328]
    (let bwpoly (polygon 'white' 'black' 3)
      (svg 
        [(bwpoly  [[x1 y6] [x1 y1] [x6 y1] [x6 y6]])
         (bwpoly  [[x1 y1] [x5 y7] [x3 y3] [x1 y2]])
         (bwpoly  [[x6 y1] [x5 y7] [x4 y3] [x6 y2]])
         (bwpoly  [[x5 y7] [x3 y3] [x5 y8] [x4 y3]])
         (bwpoly  [[x1 y4] [x3 y3] [x5 y8] [x7 y5]])
         (bwpoly  [[x6 y4] [x4 y3] [x5 y8] [x8 y5]])]))))"
    "[]"

--A Frank Lloyd Wright Design
--Still In Progress: 
--http://www.artic.edu/aic/collections/citi/images/standard/WebLarge/WebImg_000207/123332_2318933.jpg
test53 () =
  makeTest
    "(let [x1 x2 x3 x4 x5 x6 x7 x8] [64 170 280 555 412 794 186 649]
    (let [y1 y2 y3 y4 y5 y6 y7 y8] [45 99 154 214 256 860 125 184]
    (let bwpoly (polygon 'lightyellow' 'black' 3)
    (let blkline (\\[[a b] [c d]] (line 'black' 3 a b c d))
      (svg 
        (append
          (map
            bwpoly
            [[[x1 y6] [x1 y1] [x6 y1] [x6 y6]]
             [[x1 y1] [x5 y7] [x3 y3] [x1 y2]]
             [[x6 y1] [x5 y7] [x4 y3] [x6 y2]]
             [[x5 y7] [x3 y3] [x5 y8] [x4 y3]]
             [[x1 y4] [x3 y3] [x5 y8] [x7 y5]]
             [[x6 y4] [x4 y3] [x5 y8] [x8 y5]]
             [[x3 y6] [x3 y5] [x5 y4] [x4 y5] [x4 y6]]
             [[x1 y3] [x7 y2] [x7 y3] [x1 y4]]
             [[x6 y3] [x8 y2] [x8 y3] [x6 y4]]])
          (map blkline [[[x7 y5] [x7 y6]] [[x8 y5] [x8 y6]]])))))))"
    "[]"

--testing out slider bar
--pass x, y, min, max (maybe start pos)
test54 () =
  makeTest
    "(let [x0 y0 min max dim cx] [80! 400 70! 500! 50! 80]
    (let [sx sy] [309 216]
    (let samplecirc (circle 'orange' sx sy cx)
    (let button (\\n (square 'lightgray' n y0 dim))
    (let bar (rect 'gray' x0 y0 max dim)
    (let slider
      (if (< cx max)
        (if (< min cx)
          (button (+ cx x0))
          (button x0))
        (button (- (+ x0 max) dim)))
      (svg  [samplecirc bar slider])))))))"
    "[]"

--original colonial flag
test55 () =
  makeTest
    "(let nstar
    (\\(n cx cy len1 len2 rot)
      (let pti
        (\\[i len]
          (let anglei (+ rot (/ (* i (pi)) n))
          (let xi (+ cx (* len (cos anglei)))
          (let yi (+ cy (* len (sin anglei)))
            [xi yi]))))
      (let lengths
        (map
          (\\b
            (if b
              len1
              len2))
          (concat  (repeat n [true false])))
      (let indices (list0N  (- (* 2! n) 1!))
        (polygon 'white' 'DUMMY' 0 (map pti (zip indices lengths)))))))
    (let rotate (\\a (/ (* (+ 9! a) (pi)) 6!))
    (let [x0 y0 ni nj pts w h] [108 20 0! 12! 5! 500 20]
    (let [blockw blockh] [(/ w 3!) (* 7! h)]
    (let min
      (if (< blockw blockh)
        (* 0.4! blockw)
        (* 0.4! blockh))
    (let [outerLen innerLen] [10 4]
    (let block (rect '#09096d' x0 y0 blockw blockh)
    (let stripes
      (map
        (\\i (rect 'red' x0 (+ y0 (* i h)) w h))
        [0! 2! 4! 6! 8! 10! 12!])
    (let base (append stripes [block])
      (svg 
        (append
          base
          (map
            (\\i
                (nstar
                  pts
                  (+ (+ x0 (/ w 6!)) (* min (cos (rotate  i))))
                  (+ (+ y0 (* h 3.5!)) (* min (sin (rotate  i))))
                  outerLen
                  innerLen
                  (rotate  i)))
          (range ni nj)))))))))))))"
    "[]"

--current US Flag (TODO: still in progress, need mod)
test56 () =
  makeTest
    "(let [x0 y0 ni nj pts w h rad] [108 20 0! 12! 5! 500 20 6]
    (let block (rect '#09096d' x0 y0 (* w (/ 2! 5!)) (* 7! h))
    (let stripes
      (map
        (\\i (rect 'red' x0 (+ y0 (* i h)) w h))
        [0! 2! 4! 6! 8! 10! 12!])
    (let base (append stripes [block])
      (svg 
        (append
          base
          (map
            (\\[i j]
              (let xsep (/ w 15!)
              (let ysep (* h 1.3)
                (circle
                  'white'
                  (+ x0 (* i xsep))
                  (+ y0 (* j ysep))
                  rad))))
          (append (cartProd (range 0.5 5.5) (range 0.75 4.75)) (cartProd (range 1 5) (range 1.2 4.2))))))))))"
    "[]"

--French Sudan Flag (200, 105)
test57 () =
  makeTest
    "(let [x0 y0 w h] [50 30 150 300]
    (let xoff (+ x0 w)
    (let yoff (+ y0 (/ h 4))
    (let stripe (\\[color x] (rect color x y0 w h))
    (let minrad
      (if (< (/ w 7.5!) (/ h 15!))
        (/ w 7.5!)
        (/ h 15!))
    (let figline (\\[[a b] [c d]] (line 'black' (/ minrad 2) a b c d))
    (let [x1 x2 x3] (map (\\n (+ x0 (* w n))) [1.2 1.5 1.8])
    (let [y1 y2 y3 y4] (map (\\n (+ y0 (/ h n))) [4.3 2.8 1.9 1.4])
      (svg 
        (append
          (map stripe [['blue' x0] ['white' (+ x0 w)] ['red' (+ x0 (* 2 w))]])
          (snoc
            (ellipse 'black' x2 y1 (/ w 7.5!) (/ h 15!))
            (map
              figline
              [[[x1 y1] [x1 y2]]
               [[x1 y2] [x3 y2]]
               [[x3 y1] [x3 y2]]
               [[x1 y4] [x1 y3]]
               [[x1 y3] [x3 y3]]
               [[x3 y3] [x3 y4]]
               [[x2 y1] [x2 y3]]]))))))))))))"
    "[]"

--Second Frank Lloyd Wright Example - linked box widths & heights
test58 () =
  makeTest
    "(let [x0 y0 w h max] [72 72 45 56 10!]
    (let xoff (\\n (+ x0 (* w n)))
    (let yoff (\\n (+ y0 (* h n)))
    (let blkline (\\[[a b] [c d]] (line 'black' 3 a b c d))
    (let redpoly
      (\\[a b]
        (polygon
          'red'
          'black'
          3
          [[(xoff  a) (yoff  a)]
           [(xoff  a) (yoff  b)]
           [(xoff  b) (yoff  b)]
           [(xoff  b) (yoff  a)]]))
    (let dimension [0! 1 2 3 4 5 6 7 8 9 10!]
    (let verticals
      (zip
        (map (\\n [(xoff  n) y0]) dimension)
        (map (\\n [(xoff  n) (+ y0 (* h max))]) dimension))
    (let horizontals
      (zip
        (map (\\n [x0 (yoff  n)]) dimension)
        (map (\\n [(+ x0 (* w max)) (yoff  n)]) dimension))
      (svg 
        (append
          (map blkline (append verticals horizontals))
          (append
            (append
              (let [p0 p1 p2 p3 p4] [0 1 2 3 4]
                (map redpoly [[p0 p1] [p1 p2] [p2 p3] [p3 p4]]))
              (map (\\[x y] (ellipse 'blue' x y (* w 4) h)) [[(xoff 5) (yoff 9)]]))
            (map
              (\\[x y r] (circle 'yellow' x y r))
              [[(xoff  6) (yoff  2) (+ w h)]
               [(xoff  6) (yoff  7) (/ (+ w h) 4)]
               [(xoff  6) (yoff  5) (/ (+ w h) 2)]]))))))))))))"
    "[]"

test59 () =
  makeTest
    "(let [x0 y0 w h max] [69 55 53.2 74.4 10!]
    (let xoff (\\n (+ x0 (* w n)))
    (let yoff (\\n (+ y0 (* h n)))
    (let blkline (\\[[a b] [c d]] (line 'black' 3 a b c d))
    (let redpoly
      (\\[a b]
        (polygon
          'red'
          'black'
          3
          [[(xoff  a) (yoff  a)]
           [(xoff  a) (yoff  b)]
           [(xoff  b) (yoff  b)]
           [(xoff  b) (yoff  a)]]))
    (let dimension
      [0! 1 2 2.9 2.4 1.5 9.1 7.9 8.2 8.7 10!]
    (let verticals
      (zip
        (map (\\n [(xoff  n) y0]) dimension)
        (map (\\n [(xoff  n) (+ y0 (* h max))]) dimension))
    (let horizontals
      (zip
        (map (\\n [x0 (yoff  n)]) dimension)
        (map (\\n [(+ x0 (* w max)) (yoff  n)]) dimension))
      (svg 
        (append
          (map blkline (append verticals horizontals))
          (append
            (append
              (let [p0 p1 p2 p3 p4] [0 1 2 2.9 5]
                (map redpoly [[p0 p1] [p1 p2] [p2 p3] [p3 p4]]))
              (map (\\[x y] (ellipse 'blue' x y (* w 4) h)) [[(xoff  5) (yoff  9)]]))
            (map
              (\\[x y r] (circle 'yellow' x y r))
              [[(xoff  6) (yoff  1.75) (+ w h)]
               [(xoff  6) (yoff  7) (/ (+ w h) 4)]
               [(xoff  6) (yoff  5) (/ (+ w h) 2)]]))))))))))))"
    "[]"

tests =
  [ (600, 100, test15)
  , (600, 100, test16)
  , (600, 100, test17)
  , (600, 100, test18)
  , (600, 100, test19)
  , (600, 100, test20)
  , (600, 100, test21)
  , (600, 600, test22)
  , (600, 200, test23)
  , (600, 200, test24)
  , (600, 200, test25)
  , (600, 200, test26)
  , (600, 200, test27)
  , (600, 200, test28)
  , (600, 200, test29)
  , (600, 200, test30)
  , (600, 600, test31)
  , (600, 300, test32)
  , (600, 300, test33)
  , (600, 200, test34)
  , (600, 200, test35)
  , (600, 330, test36)
  , (600, 330, test37)
  , (600, 200, test38)
  , (600, 200, test39)
  , (600, 200, test40)
  , (600, 200, test41)
  , (600, 200, test42)
  , (600, 200, test43)
  , (600, 300, test44)
  , (600, 300, test45)
  , (600, 300, test46)
  , (600, 300, test47)
  , (600, 300, test48)
  , (600, 600, test49)
  , (600, 600, test50)
  , (600, 600, test51)
  , (600, 600, test52)
  , (600, 600, test53)
  , (600, 600, test54)
  , (600, 600, test55)
  , (600, 600, test56)
  , (600, 600, test57)
  , (600, 600, test58)
  , (600, 600, test59)
  ]

sampleTests =
  tests
    |> List.map Utils.thd3
    |> Utils.mapi (\(i,f) ->
         let name = "test" ++ toString (i+14) in
         let thunk () = let {e,v} = f () in {e=e, v=v} in
         (name, thunk))
    |> List.reverse

