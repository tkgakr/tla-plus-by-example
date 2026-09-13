-------------------------- MODULE BlockingQueue ---------------------------
(***************************************************************************)
(* 仕様は最小構成の章から変えず、定数だけを p1c2b1 へ変更して検査する。  *)
(***************************************************************************)

EXTENDS Naturals, Sequences, FiniteSets

CONSTANTS Producers, Consumers, BufCapacity

ASSUME Assumption ==
    /\ Producers # {}
    /\ Consumers # {}
    /\ Producers \intersect Consumers = {}
    /\ BufCapacity \in (Nat \ {0})

VARIABLES buffer, waitSet

vars == <<buffer, waitSet>>

RunningThreads ==
    (Producers \cup Consumers) \ waitSet

Notify ==
    IF waitSet # {}
    THEN \E thread \in waitSet : waitSet' = waitSet \ {thread}
    ELSE UNCHANGED waitSet

Wait(thread) ==
    /\ waitSet' = waitSet \cup {thread}
    /\ UNCHANGED buffer

Put(thread, data) ==
    \/ /\ Len(buffer) < BufCapacity
       /\ buffer' = Append(buffer, data)
       /\ Notify
    \/ /\ Len(buffer) = BufCapacity
       /\ Wait(thread)

Get(thread) ==
    \/ /\ buffer # <<>>
       /\ buffer' = Tail(buffer)
       /\ Notify
    \/ /\ buffer = <<>>
       /\ Wait(thread)

Init ==
    /\ buffer = <<>>
    /\ waitSet = {}

Next ==
    \E thread \in RunningThreads :
        \/ /\ thread \in Producers
           /\ Put(thread, thread)
        \/ /\ thread \in Consumers
           /\ Get(thread)

TypeOK ==
    /\ buffer \in Seq(Producers)
    /\ waitSet \subseteq (Producers \cup Consumers)

CapacityOK ==
    Len(buffer) <= BufCapacity

=============================================================================
