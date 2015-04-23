module Sync where

import List
import Dict
import Set
import Utils

import Lang (..)

type Equation = Equation Int Trace

locsOfTrace : Trace -> List Loc
locsOfTrace =
  let foo t = case t of
    TrLoc l   -> Set.singleton l
    TrOp _ ts -> List.foldl Set.union Set.empty (List.map foo ts)
  in
  Set.toList << foo

inferSubsts : Subst -> Val -> List Subst
inferSubsts s (VConst i tr) =
  List.map
    (\l -> let s' = Dict.remove l s in
           let n  = solve s' (Equation i tr) in
           Dict.insert l n s')
    (locsOfTrace tr)

-- assumes that a single variable is being solved for
solve : Subst -> Equation -> Int
solve subst (Equation sum tr) =
  let evalTrace t = case t of
    TrLoc l      -> case Dict.get l subst of
                      Nothing -> (0, 1)
                      Just i  -> (i, 0)
    TrOp Plus ts -> List.foldl plusplus (0,0) (List.map evalTrace ts)
  in
  let (partialSum,n) = evalTrace tr in
  (sum - partialSum) // n
 
plusplus = Utils.lift_2_2 (+)

compareVals : (Val, Val) -> Int
compareVals (v1, v2) = case (v1, v2) of
  (VConst i _, VConst j _) -> abs (i-j)
  (VList vs1, VList vs2)   -> case Utils.maybeZip vs1 vs2 of
                                Nothing -> largeInt
                                Just l  -> Utils.sum (List.map compareVals l)
  _                        -> if | v1 == v2  -> 0
                                 | otherwise -> largeInt

largeInt = 99999999

