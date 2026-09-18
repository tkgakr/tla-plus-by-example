-------------------------- MODULE BlockingQueue ---------------------------
(***************************************************************************)
(* 06 章で構成を変数にし、07 章で対称性を宣言した。ここまでで「どの構成が *)
(* デッドロックするか」は表として得られている。この章では、その表を       *)
(* 不等式として書き下し、TLC に検査させる。                               *)
(*                                                                         *)
(* 仕様本体 (Init / Next / Put / Get / Wait / Notify) は 06 章から一切     *)
(* 変えていない。足すのは性質の定義だけである。                           *)
(***************************************************************************)

EXTENDS Naturals, Sequences, FiniteSets, TLC

CONSTANTS Producers, Consumers, BufCapacity

ASSUME Assumption ==
    /\ Producers # {}
    /\ Consumers # {}
    /\ Producers \intersect Consumers = {}
    /\ BufCapacity \in (Nat \ {0})

VARIABLES buffer, waitSet, producers, consumers, bufCapacity

vars == <<buffer, waitSet, producers, consumers, bufCapacity>>

config == <<producers, consumers, bufCapacity>>

Threads ==
    producers \cup consumers

RunningThreads ==
    Threads \ waitSet

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

Init ==
    /\ buffer = <<>>
    /\ waitSet = {}
    /\ producers \in (SUBSET Producers) \ {{}}
    /\ consumers \in (SUBSET Consumers) \ {{}}
    /\ bufCapacity \in 1..BufCapacity

Next ==
    /\ \E thread \in RunningThreads :
           \/ /\ thread \in producers
              /\ Put(thread, thread)
           \/ /\ thread \in consumers
              /\ Get(thread)
    /\ UNCHANGED config

Symmetry ==
    Permutations(Producers) \cup Permutations(Consumers)

TypeOK ==
    /\ producers \in (SUBSET Producers) \ {{}}
    /\ consumers \in (SUBSET Consumers) \ {{}}
    /\ bufCapacity \in 1..BufCapacity
    /\ buffer \in Seq(producers)
    /\ waitSet \subseteq Threads

CapacityOK ==
    Len(buffer) <= bufCapacity

Deadlock ==
    waitSet = Threads

NoDeadlock ==
    ~Deadlock

(***************************************************************************)
(* この章の主役。06 章の表から読み取った予想を、そのまま式にしたもの。    *)
(*                                                                         *)
(*   2 * bufCapacity >= スレッド総数  なら、デッドロックは起きない        *)
(*                                                                         *)
(* 不変条件として書けるのはこの向きだけである。逆向き「不等式が成り立た   *)
(* ないならデッドロックに到達できる」は到達可能性の主張なので、不変条件   *)
(* では表現できない (LogDeadlock を参照)。                                *)
(***************************************************************************)
Inequation ==
    2 * bufCapacity >= Cardinality(Threads)

DeadlockFreeIfInequation ==
    Inequation => NoDeadlock

(***************************************************************************)
(* わざと 1 だけずらした版。境界 (2 * bufCapacity = スレッド総数) の構成  *)
(* で違反するはずであり、「不等式の境界がどこにあるか」を TLC に          *)
(* 確かめさせるために使う。BlockingQueueOffByOne.cfg で検査する。         *)
(***************************************************************************)
InequationOffByOne ==
    2 * bufCapacity >= Cardinality(Threads) - 1

DeadlockFreeIfOffByOne ==
    InequationOffByOne => NoDeadlock

(***************************************************************************)
(* 逆向きを調べるための道具。デッドロック状態に出会うたびに、その構成を   *)
(* <<"InvVio", 容量, スレッド総数>> として印字してから違反を報告する。    *)
(* -continue と組み合わせ、印字された組を集計する。                       *)
(*                                                                         *)
(* PrintT は TLC モジュールの演算子で、値を印字して TRUE を返す。         *)
(* /\ FALSE を続けることで「この状態は違反」として報告させている。        *)
(***************************************************************************)
LogDeadlock ==
    \/ NoDeadlock
    \/ /\ PrintT(<<"InvVio", bufCapacity, Cardinality(Threads)>>)
       /\ FALSE

=============================================================================
