------------------------------- MODULE Sets ----------------------------------
(***************************************************************************)
(* 色を選択・解除するモデルを使って、TLA+ の集合演算を確認する。         *)
(***************************************************************************)

EXTENDS Naturals, FiniteSets

VARIABLE picked

Colors == {"red", "green", "blue"}

WarmColors == {"red", "yellow"}

Init ==
    picked = {}

AddColor ==
    /\ Cardinality(picked) < Cardinality(Colors)
    /\ \E color \in Colors :
        /\ color \notin picked
        /\ picked' = picked \union {color}

RemoveColor ==
    /\ picked # {}
    /\ \E color \in picked :
        picked' = picked \ {color}

Next ==
    AddColor \/ RemoveColor

TypeOK ==
    picked \subseteq Colors

AlwaysSmall ==
    Cardinality(picked) <= Cardinality(Colors)

LargeNumbers == {number \in 1..10 : number > 5}

Doubled == {number * 2 : number \in 1..3}

SetExamplesOK ==
    /\ picked \in SUBSET Colors
    /\ IsFiniteSet(Colors)
    /\ Cardinality(Colors) = 3
    /\ Colors \union WarmColors = {"red", "green", "blue", "yellow"}
    /\ Colors \intersect WarmColors = {"red"}
    /\ Colors \ WarmColors = {"green", "blue"}
    /\ Cardinality(SUBSET Colors) = 8
    /\ LargeNumbers = {6, 7, 8, 9, 10}
    /\ Doubled = {2, 4, 6}

=============================================================================
