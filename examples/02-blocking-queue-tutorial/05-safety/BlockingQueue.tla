-------------------------- MODULE BlockingQueue ---------------------------
(***************************************************************************)
(* Init/Next/Put/Get/Wait/Notify は 01〜04 章から変更しない。            *)
(* この章で増えるのは、安全性を表す不変条件 NoDeadlock だけである。     *)
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

(***************************************************************************)
(* TLA+ は型を持たないため、各状態で値の範囲を確かめる不変条件を置く。  *)
(***************************************************************************)
TypeOK ==
    /\ buffer \in Seq(Producers)
    /\ waitSet \subseteq (Producers \cup Consumers)

CapacityOK ==
    Len(buffer) <= BufCapacity

(***************************************************************************)
(* 安全性: 「全スレッドが同時に待機している」状態には決して到達しない。 *)
(* この 1 行が、これまで TLC の既定動作に任せていたデッドロック検出を   *)
(* 仕様の側へ明示的に書き出したものである。                             *)
(* 上流教材では Invariant という名前で導入される。                      *)
(***************************************************************************)
NoDeadlock ==
    waitSet # (Producers \cup Consumers)

=============================================================================
