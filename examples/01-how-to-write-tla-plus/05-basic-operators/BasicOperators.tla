------------------------- MODULE BasicOperators -----------------------------
(***************************************************************************)
(* 基本演算子を使って、赤・青・黄を順番に遷移する信号機をモデル化する。 *)
(***************************************************************************)

EXTENDS Naturals

VARIABLES light, cycles

vars == <<light, cycles>>

LightColors == {"red", "green", "yellow"}

Init ==
    /\ light = "red"
    /\ cycles = 0

ToGreen ==
    /\ light = "red"
    /\ light' = "green"
    /\ UNCHANGED cycles

ToYellow ==
    /\ light = "green"
    /\ light' = "yellow"
    /\ cycles' = cycles

ToRed ==
    /\ light = "yellow"
    /\ light' = "red"
    /\ cycles' = IF cycles < 2 THEN cycles + 1 ELSE cycles

Next ==
    \/ ToGreen
    \/ ToYellow
    \/ ToRed

IsGo == light = "green"

IsStop == light = "red" \/ light = "yellow"

Instruction == IF IsGo THEN "go" ELSE "stop"

TypeOK ==
    /\ light \in LightColors
    /\ cycles \in 0..2

OperatorLaws ==
    /\ (IsGo <=> ~IsStop)
    /\ (IsStop => Instruction = "stop")
    /\ Instruction \in {"go", "stop"}

\* 現在が青なら、次状態で直接赤にはならない、というアクション式。
NeverSkipYellow == (light = "green") => (light' # "red")

Spec == Init /\ [][Next]_vars

\* アクション式を全ステップで検査する時間的性質に持ち上げる。
NeverSkipYellowAlways == [][NeverSkipYellow]_vars

=============================================================================
