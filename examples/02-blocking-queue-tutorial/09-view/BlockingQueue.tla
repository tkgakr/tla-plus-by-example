-------------------------- MODULE BlockingQueue ---------------------------
(***************************************************************************)
(* 07 章では「名前を入れ替えても同じ状態」を SYMMETRY で畳んだ。この章で  *)
(* 畳むのは「状態の中身のうち、性質に効かない部分」である。               *)
(*                                                                         *)
(* NoDeadlock も CapacityOK も、buffer に何が入っているかではなく、       *)
(* 何個入っているかしか見ていない。VIEW はその事実を TLC に伝える宣言で   *)
(* ある。仕様本体 (Init / Next / Put / Get / Wait / Notify) は 06 章から   *)
(* 一行も変えていない。                                                   *)
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

(***************************************************************************)
(* この章の主役。状態のうち TLC が「同じかどうか」の判定に使う部分を      *)
(* 指定する。buffer そのものではなく Len(buffer) を置くことで、中身の違う *)
(* 同じ長さのバッファを 1 つの状態として扱わせる。                        *)
(*                                                                         *)
(* View に載せなかった変数は判定から消える。ここでは buffer の中身だけを  *)
(* 落とし、waitSet と構成 3 変数はそのまま残している。                    *)
(***************************************************************************)
View ==
    <<Len(buffer), waitSet, producers, consumers, bufCapacity>>

CapacityOK ==
    Len(buffer) <= bufCapacity

NoDeadlock ==
    waitSet # Threads

(***************************************************************************)
(* ここから下は buffer の中身に依存する性質であり、この View のもとで     *)
(* 検査してはならないものである。                                         *)
(*                                                                         *)
(* NotThreeDistinct は「異なる 3 者のデータが同時にバッファに並ぶことは   *)
(* ない」と主張する (実際には偽)。VIEW なしなら違反が見つかるが、VIEW を  *)
(* 付けると見つからなくなる。5 節で確かめる。                             *)
(*                                                                         *)
(* TypeOK も buffer \in Seq(producers) という形で中身に触れるため、同じ   *)
(* 理由でこの VIEW とは相性が悪い。そこで中身を見ない ShapeOK を用意し、  *)
(* TypeOK は比較用に残してある。                                          *)
(***************************************************************************)
NotThreeDistinct ==
    ~ /\ Len(buffer) = 3
      /\ buffer[1] # buffer[2]
      /\ buffer[1] # buffer[3]
      /\ buffer[2] # buffer[3]

NoDuplicateInBuffer ==
    \A i, j \in 1..Len(buffer) :
        i # j => buffer[i] # buffer[j]

TypeOK ==
    /\ producers \in (SUBSET Producers) \ {{}}
    /\ consumers \in (SUBSET Consumers) \ {{}}
    /\ bufCapacity \in 1..BufCapacity
    /\ buffer \in Seq(producers)
    /\ waitSet \subseteq Threads

ShapeOK ==
    /\ producers \in (SUBSET Producers) \ {{}}
    /\ consumers \in (SUBSET Consumers) \ {{}}
    /\ bufCapacity \in 1..BufCapacity
    /\ Len(buffer) \in 0..bufCapacity
    /\ waitSet \subseteq Threads

=============================================================================
