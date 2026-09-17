-------------------------- MODULE BlockingQueue ---------------------------
(***************************************************************************)
(* 06 章と同じ仕様である。構成は Init が選び、Next は UNCHANGED config で  *)
(* それを固定する。この章で足すのは Symmetry の定義だけであり、Init /     *)
(* Next / 不変条件はいっさい変えていない。                                *)
(*                                                                         *)
(* Permutations は TLC モジュールの演算子なので EXTENDS に TLC を足す。   *)
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

(***************************************************************************)
(* この仕様も、検査する 3 つの不変条件も、producer 同士・consumer 同士の  *)
(* 名前を入れ替えても値が変わらない。したがって Producers の置換全体と    *)
(* Consumers の置換全体を SYMMETRY として宣言してよい。                   *)
(*                                                                         *)
(* Permutations(S) は S 上の全単射（S の要素同士の入れ替え）の集合を返す。*)
(* 注意: 健全性を TLC は検査しない。宣言が誤っていれば違反を見逃す。      *)
(***************************************************************************)
Symmetry ==
    Permutations(Producers) \cup Permutations(Consumers)

(***************************************************************************)
(* 以下は「不健全な宣言は違反を隠す」ことを実演するためだけの定義であり、 *)
(* BlockingQueue の性質ではない。ChosenProducer / SecondProducer は       *)
(* Producers の要素を個別に名指しするため、Producers の置換で値が変わる。 *)
(* つまり NotSoleChosen も NotSoleSecond も Symmetry に対して対称でない。 *)
(*                                                                         *)
(* 対称性なしなら両方とも初期状態で違反する。SYMMETRY を付けると片方しか  *)
(* 報告されない。BlockingQueueUnsound.cfg を参照。                        *)
(***************************************************************************)
ChosenProducer ==
    CHOOSE p \in Producers : TRUE

SecondProducer ==
    CHOOSE p \in Producers : p # ChosenProducer

NotSoleChosen ==
    producers # {ChosenProducer}

NotSoleSecond ==
    producers # {SecondProducer}

=============================================================================
