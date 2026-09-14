------------------------ MODULE BlockingQueueDebug ------------------------
(***************************************************************************)
(* BlockingQueue を検査用に拡張するだけのモジュール。仕様そのもの        *)
(* (Init/Next/Put/Get/Wait/Notify) は一切変更しない。                     *)
(*                                                                         *)
(* NoDeadLock を ACTION_CONSTRAINT に指定すると、次状態で全スレッドが     *)
(* 待機集合に入る瞬間だけ TLC が停止し、後続状態を対話的に選べる。       *)
(***************************************************************************)

EXTENDS BlockingQueue, TLCExt

\* PickSuccessor(exp) は exp が FALSE のときだけ後続状態の選択を求める。
\* ここでは「次状態の waitSet が全スレッド = デッドロック」のときに停止する。
NoDeadLock ==
    PickSuccessor(waitSet' # (Producers \cup Consumers))

=============================================================================
