-------------------------- MODULE BlockingQueue ---------------------------
(***************************************************************************)
(* 01〜05 章では構成 (producer 数・consumer 数・容量) を CONSTANTS で固定  *)
(* し、構成ごとに .cfg を書き分けていた。この章では構成そのものを変数に   *)
(* して、Init で選ばせる。CONSTANTS は「選んでよい範囲の上限」になる。    *)
(***************************************************************************)

EXTENDS Naturals, Sequences, FiniteSets

CONSTANTS Producers, Consumers, BufCapacity

ASSUME Assumption ==
    /\ Producers # {}
    /\ Consumers # {}
    /\ Producers \intersect Consumers = {}
    /\ BufCapacity \in (Nat \ {0})

(***************************************************************************)
(* buffer と waitSet に加え、構成を表す 3 変数を持つ。小文字の             *)
(* producers / consumers / bufCapacity が「この振る舞いで使う構成」、      *)
(* 大文字の CONSTANTS が「構成として選べる範囲」である。                   *)
(***************************************************************************)
VARIABLES buffer, waitSet, producers, consumers, bufCapacity

vars == <<buffer, waitSet, producers, consumers, bufCapacity>>

config == <<producers, consumers, bufCapacity>>

RunningThreads ==
    (producers \cup consumers) \ waitSet

Notify ==
    IF waitSet # {}
    THEN \E thread \in waitSet : waitSet' = waitSet \ {thread}
    ELSE UNCHANGED waitSet

Wait(thread) ==
    /\ waitSet' = waitSet \cup {thread}
    /\ UNCHANGED buffer

Put(thread, data) ==
    \/ /\ Len(buffer) < bufCapacity
       /\ buffer' = Append(buffer, data)
       /\ Notify
    \/ /\ Len(buffer) = bufCapacity
       /\ Wait(thread)

Get(thread) ==
    \/ /\ buffer # <<>>
       /\ buffer' = Tail(buffer)
       /\ Notify
    \/ /\ buffer = <<>>
       /\ Wait(thread)

(***************************************************************************)
(* 初期状態で構成を一つ選ぶ。空の producer 集合・consumer 集合は          *)
(* ASSUME と同じ理由で除き、容量は 1..BufCapacity から選ぶ。              *)
(***************************************************************************)
Init ==
    /\ buffer = <<>>
    /\ waitSet = {}
    /\ producers \in (SUBSET Producers) \ {{}}
    /\ consumers \in (SUBSET Consumers) \ {{}}
    /\ bufCapacity \in 1..BufCapacity

(***************************************************************************)
(* Next は構成を変えない。一つの振る舞いは、選ばれた一つの構成のまま      *)
(* 最後まで進む。                                                         *)
(***************************************************************************)
Next ==
    /\ \E thread \in RunningThreads :
           \/ /\ thread \in producers
              /\ Put(thread, thread)
           \/ /\ thread \in consumers
              /\ Get(thread)
    /\ UNCHANGED config

TypeOK ==
    /\ producers \in (SUBSET Producers) \ {{}}
    /\ consumers \in (SUBSET Consumers) \ {{}}
    /\ bufCapacity \in 1..BufCapacity
    /\ buffer \in Seq(producers)
    /\ waitSet \subseteq (producers \cup consumers)

CapacityOK ==
    Len(buffer) <= bufCapacity

NoDeadlock ==
    waitSet # (producers \cup consumers)

=============================================================================
