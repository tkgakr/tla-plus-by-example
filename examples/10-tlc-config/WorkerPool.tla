--------------------------- MODULE WorkerPool -------------------------------
(***************************************************************************)
(* 作業者を 1 人ずつ稼働させるモデルで、TLC の設定項目を確認する。        *)
(***************************************************************************)

EXTENDS Naturals, FiniteSets, TLC

CONSTANTS Size, Procs

VARIABLE active

vars == <<active>>

Init ==
    active = {}

Activate ==
    \E proc \in Procs \ active :
        active' = active \cup {proc}

Complete ==
    /\ active = Procs
    /\ UNCHANGED active

Next ==
    Activate \/ Complete

TypeOK ==
    active \subseteq Procs

SizeOK ==
    /\ Size = Cardinality(Procs)
    /\ Cardinality(active) <= Size

AllActive ==
    active = Procs

EventuallyAllActive ==
    WF_vars(Activate) => <>AllActive

Perms ==
    Permutations(Procs)

=============================================================================
