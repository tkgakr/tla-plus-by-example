----------------------------- MODULE DieHard --------------------------------
(***************************************************************************)
(* learning.tlapl.us / Introduction / The TLA+ / TLC Intuition に          *)
(* 掲載されている DieHard 仕様をそのまま写したもの。                        *)
(*                                                                         *)
(* 状態機械の 4 要素が、このファイルのどこに対応しているかを確認する。      *)
(*   変数         -> VARIABLES big, small                                  *)
(*   初期状態     -> Init                                                  *)
(*   次状態関係   -> Next（6 つのアクションの選択）                        *)
(*   不変条件     -> NotSolved                                             *)
(***************************************************************************)
EXTENDS Naturals

VARIABLES big,   \* gallons in the 5-gallon jug
          small  \* gallons in the 3-gallon jug

Init == /\ big = 0
        /\ small = 0

FillSmallJug  == /\ small' = 3
                 /\ big' = big

FillBigJug    == /\ big' = 5
                 /\ small' = small

EmptySmallJug == /\ small' = 0
                 /\ big' = big

EmptyBigJug   == /\ big' = 0
                 /\ small' = small

Min(m,n) == IF m < n THEN m ELSE n

SmallToBig == /\ big'   = Min(big + small, 5)
              /\ small' = small - (big' - big)

BigToSmall == /\ small' = Min(big + small, 3)
              /\ big'   = big - (small' - small)

Next == \/ FillSmallJug
        \/ FillBigJug
        \/ EmptySmallJug
        \/ EmptyBigJug
        \/ SmallToBig
        \/ BigToSmall

NotSolved == big # 4
=============================================================================
