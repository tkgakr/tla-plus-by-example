-------------------------- MODULE BlockingQueue ---------------------------
(***************************************************************************)
(* 最小構成 p1c1b1 の到達可能状態をすべて列挙し、状態グラフとして読む。   *)
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
