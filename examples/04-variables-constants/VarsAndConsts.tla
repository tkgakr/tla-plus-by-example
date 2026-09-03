------------------------- MODULE VarsAndConsts -----------------------------
(***************************************************************************)
(* VARIABLE と CONSTANT の違い、および TypeOK 不変条件を示す仕様。         *)
(***************************************************************************)

EXTENDS Naturals

CONSTANT N

VARIABLES count, total

TypeOK ==
    /\ count \in 0..N
    /\ total \in 0..5

Init ==
    /\ count = 0
    /\ total = 0

Increment ==
    /\ count < N
    /\ total < 5
    /\ count' = count + 1
    /\ total' = total + 1

Reset ==
    /\ count = N
    /\ count' = 0
    /\ total' = total

Next ==
    Increment \/ Reset

=============================================================================
