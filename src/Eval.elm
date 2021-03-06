module Eval (run, parseAndRun, evalDelta) where

import Debug

import Lang exposing (..)
import LangParser2 as Parser
import Utils

------------------------------------------------------------------------------
-- Big-Step Operational Semantics

match : (Pat, Val) -> Maybe Env
match (p,v) = case (p.val, v) of
  (PVar x, _) -> Just [(x,v)]
  (PList ps Nothing, VList vs) ->
    Utils.bindMaybe matchList (Utils.maybeZip ps vs)
  (PList ps (Just rest), VList vs) ->
    let (n,m) = (List.length ps, List.length vs) in
    if | n > m     -> Nothing
       | otherwise -> let (vs1,vs2) = Utils.split n vs in
                      (rest, VList vs2) `cons` (matchList (Utils.zip ps vs1))
  (PList _ _, _) -> Nothing

matchList : List (Pat, Val) -> Maybe Env
matchList pvs =
  List.foldl (\pv acc ->
    case (acc, match pv) of
      (Just old, Just new) -> Just (new ++ old)
      _                    -> Nothing
  ) (Just []) pvs

cons : (Pat, Val) -> Maybe Env -> Maybe Env
cons pv menv =
  case (menv, match pv) of
    (Just env, Just env') -> Just (env' ++ env)
    _                     -> Nothing

lookupVar env x pos =
  case Utils.maybeFind x env of
    Just v -> v
    Nothing -> errorMsg <| strPos pos ++ " variable not found: " ++ x

-- eval propagates output environment in order to extract
-- initial environment from prelude

-- eval inserts dummyPos during evaluation

eval_ : Env -> Exp -> Val
eval_ env e = fst <| eval env e

eval : Env -> Exp -> (Val, Env)
eval env e =

  let ret v = (v, env) in

  case e.val of

  EConst i l -> ret <| VConst (i, TrLoc l)
  EBase v    -> ret <| VBase v
  EVar x     -> ret <| lookupVar env x e.start
  EFun [p] e -> ret <| VClosure Nothing p e env
  EOp op es  -> ret <| evalOp env op es

  EList es m ->
    let vs = List.map (eval_ env) es in
    case m of
      Nothing   -> ret <| VList vs
      Just rest -> case eval_ env rest of
                     VList vs' -> ret <| VList (vs ++ vs')

  EIndList rs -> 
      let vrs = List.concat <| List.map rangeToList rs
      in ret <| VList vrs

  EIf e1 e2 e3 ->
    case eval_ env e1 of
      VBase (Bool True)  -> eval env e2
      VBase (Bool False) -> eval env e3
      _                  -> errorMsg <| strPos e1.start ++ " if-statement expected a Bool but got something else."

  ECase e1 l ->
    let v1 = eval_ env e1 in
    case evalBranches env v1 l of
      Just v2 -> ret v2
      _       -> errorMsg <| strPos e1.start ++ " non-exhaustive case statement"

  EApp e1 [e2] ->
    let (v1,v2) = (eval_ env e1, eval_ env e2) in
    case v1 of
      VClosure Nothing p e env' ->
        case (p, v2) `cons` Just env' of
          Just env'' -> eval env'' e
      VClosure (Just f) p e env' ->
        case (pVar f, v1) `cons` ((p, v2) `cons` Just env') of
          Just env'' -> eval env'' e
      _ ->
        errorMsg <| strPos e1.start ++ " not a function"

  ELet _ True p e1 e2 ->
    case (p.val, eval_ env e1) of
      (PVar f, VClosure Nothing x body env') ->
        let _   = Utils.assert "eval letrec" (env == env') in
        let v1' = VClosure (Just f) x body env in
        case (pVar f, v1') `cons` Just env of
          Just env' -> eval env' e2
      (PList _ _, _) ->
        errorMsg <|
          strPos e1.start ++
          "mutually recursive functions (i.e. letrec [...] [...] e) \
           not yet implemented"

  EComment _ e1 -> eval env e1
  EOption _ _ e1 -> eval env e1

  -- abstract syntactic sugar
  EFun ps e  -> eval env (eFun ps e)
  EApp e1 es -> eval env (eApp e1 es)
  ELet _ False p e1 e2 -> eval env (eApp (eFun [p] e2) [e1])

evalOp env opWithInfo es =
  let (op,opStart) = (opWithInfo.val, opWithInfo.start) in
  case List.map (eval_ env) es of
    [VConst (i,it), VConst (j,jt)] ->
      case op of
        Plus  -> VConst (evalDelta op [i,j], TrOp op [it,jt])
        Minus -> VConst (evalDelta op [i,j], TrOp op [it,jt])
        Mult  -> VConst (evalDelta op [i,j], TrOp op [it,jt])
        Div   -> VConst (evalDelta op [i,j], TrOp op [it,jt])
        Lt    -> vBool  (i < j)
        Eq    -> vBool  (i == j)
    [VBase (String s1), VBase (String s2)] ->
      case op of
        Plus  -> VBase (String (s1 ++ s2))
        Eq    -> vBool (s1 == s2)
    [] ->
      case op of
        Pi    -> VConst (pi, TrOp op [])
    [VConst (n,t)] ->
      case op of
        Cos    -> VConst (cos n, TrOp op [t])
        Sin    -> VConst (sin n, TrOp op [t])
        ArcCos -> VConst (acos n, TrOp op [t])
        ArcSin -> VConst (asin n, TrOp op [t])
        Floor  -> VConst (toFloat <| floor n, TrOp op [t])
        Ceil   -> VConst (toFloat <| ceiling n, TrOp op [t])
        Round  -> VConst (toFloat <| round n, TrOp op [t])
        ToStr  -> VBase (String (toString n))
    [VBase (Bool b)] ->
      case op of
        ToStr  -> VBase (String (toString b))
    _ ->
      errorMsg
        <| "Bad arguments to " ++ strOp op ++ " operator " ++ strPos opStart
        ++ ":\n" ++ Utils.lines (List.map sExp es)

evalBranches env v l =
  List.foldl (\(p,e) acc ->
    case (acc, (p,v) `cons` Just env) of
      (Just done, _)       -> Just done
      (Nothing, Just env') -> Just (eval_ env' e)
      _                    -> Nothing

  ) Nothing (List.map .val l)

evalDelta op is =
  case (op, is) of
    (Plus,   [i,j]) -> (+) i j
    (Minus,  [i,j]) -> (-) i j
    (Mult,   [i,j]) -> (*) i j
    (Div,    [i,j]) -> (/) i j
    (Cos,    [n])   -> cos n
    (Sin,    [n])   -> sin n
    (ArcCos, [n])   -> acos n
    (ArcSin, [n])   -> asin n
    (Pi,     [])    -> pi
    (Floor,  [n])   -> toFloat <| floor n
    (Ceil,   [n])   -> toFloat <| ceiling n
    (Round,  [n])   -> toFloat <| round n
    _               -> errorMsg <| "Eval.evalDelta " ++ strOp op

initEnv = snd (eval [] Parser.prelude)

run : Exp -> Val
run e =
  eval_ initEnv e

parseAndRun : String -> String
parseAndRun = strVal << run << Utils.fromOk_ << Parser.parseE

-- Inflates a range to a list, which is then Concat-ed in eval
rangeToList : ERange -> List Val
rangeToList r = 
    let (l,u) = r.val
    in
      case (l.val, u.val) of
        (EConst nl tl, EConst nu tu) ->
           let walkVal i =
             let j = toFloat i in
             if | (nl + j) < nu -> VConst (nl + j, TrOp (RangeOffset i) [TrLoc tl]) :: walkVal (i + 1)
                | otherwise     -> [ VConst (nu, TrLoc tu) ]
           in
           if | nl == nu  -> [ VConst (nl, TrLoc tl) ]
              | otherwise -> walkVal 0
        _ -> errorMsg "Range not specified with numeric constants"
