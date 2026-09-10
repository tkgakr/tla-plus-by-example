----------------------------- MODULE DieHard -----------------------------
(***************************************************************************)
(* 映画『ダイ・ハード3』の水差しパズル。                                    *)
(* 5 ガロンと 3 ガロンの容器だけを使って、ちょうど 4 ガロンを量る。         *)
(***************************************************************************)

EXTENDS Naturals

VARIABLES small,   \* 3 ガロン容器の中身
          big      \* 5 ガロン容器の中身

Min(m, n) == IF m < n THEN m ELSE n

TypeOK ==
    /\ small \in 0..3
    /\ big   \in 0..5

Init ==
    /\ small = 0
    /\ big   = 0

FillSmall ==
    /\ small' = 3
    /\ big'   = big

FillBig ==
    /\ big'   = 5
    /\ small' = small

EmptySmall ==
    /\ small' = 0
    /\ big'   = big

EmptyBig ==
    /\ big'   = 0
    /\ small' = small

SmallToBig ==
    /\ big'   = Min(big + small, 5)
    /\ small' = small - (big' - big)

BigToSmall ==
    /\ small' = Min(big + small, 3)
    /\ big'   = big - (small' - small)

Next ==
    \/ FillSmall
    \/ FillBig
    \/ EmptySmall
    \/ EmptyBig
    \/ SmallToBig
    \/ BigToSmall

Spec ==
    Init /\ [][Next]_<<small, big>>

(***************************************************************************)
(* 「4 ガロンは作れない」という(わざと嘘の)不変条件。                       *)
(* TLC がこれを破る状態を見つけ、その反例トレースが解答になる。             *)
(***************************************************************************)
NotSolved ==
    big /= 4

==========================================================================
