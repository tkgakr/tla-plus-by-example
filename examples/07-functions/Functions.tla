----------------------------- MODULE Functions -------------------------------
(***************************************************************************)
(* 固定キーのストアを使って、関数の参照と更新を確認する。                 *)
(***************************************************************************)

EXTENDS Naturals, FiniteSets

VARIABLE store

Keys == {"a", "b"}
Values == 0..2

Double == [x \in 1..3 |-> x * 2]
Flags == [Keys -> BOOLEAN]

Init ==
    store = [key \in Keys |-> 0]

Put ==
    \E key \in Keys :
        \E value \in Values :
            store' = [store EXCEPT ![key] = value]

Increment ==
    \E key \in Keys :
        /\ store[key] < 2
        /\ store' = [store EXCEPT ![key] = @ + 1]

Next ==
    Put \/ Increment

TypeOK ==
    store \in [Keys -> Values]

DomainOK ==
    DOMAIN store = Keys

FunctionExamplesOK ==
    /\ [store EXCEPT !["a"] = 0] \in [Keys -> Values]
    /\ DOMAIN Double = 1..3
    /\ Double[1] = 2
    /\ Double[2] = 4
    /\ Double[3] = 6
    /\ Double \in [1..3 -> {2, 4, 6}]
    /\ Cardinality(Flags) = 4
    /\ [key \in Keys |-> FALSE] \in Flags
    /\ [Double EXCEPT ![2] = 10] = [x \in 1..3 |-> IF x = 2 THEN 10 ELSE x * 2]
    /\ [Double EXCEPT ![2] = @ + 1] = [x \in 1..3 |-> IF x = 2 THEN 5 ELSE x * 2]

=============================================================================
