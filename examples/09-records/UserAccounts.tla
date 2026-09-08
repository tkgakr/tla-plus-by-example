--------------------------- MODULE UserAccounts ------------------------------
(***************************************************************************)
(* ユーザーアカウントを使って、TLA+ のレコードの参照と更新を確認する。    *)
(***************************************************************************)

EXTENDS Naturals, FiniteSets

VARIABLE account

Names == {"Alice", "Bob"}
Ages == 30..32

Example == [name |-> "Alice", age |-> 30, active |-> TRUE]

Init ==
    account = Example

Birthday ==
    /\ account.age < 32
    /\ account' = [account EXCEPT !.age = @ + 1]

Rename ==
    \E newName \in Names :
        account' = [account EXCEPT !.name = newName]

ToggleActive ==
    account' = [account EXCEPT !.active = ~@]

Next ==
    Birthday \/ Rename \/ ToggleActive

TypeOK ==
    account \in [name : Names, age : Ages, active : BOOLEAN]

DomainOK ==
    DOMAIN account = {"name", "age", "active"}

RecordExamplesOK ==
    /\ Example.name = "Alice"
    /\ Example.age = 30
    /\ Example.active = TRUE
    /\ Example["name"] = Example.name
    /\ Example =
        [field \in {"name", "age", "active"} |->
            CASE field = "name" -> "Alice"
              [] field = "age" -> 30
              [] field = "active" -> TRUE]
    /\ [Example EXCEPT !.age = @ + 1] =
        [name |-> "Alice", age |-> 31, active |-> TRUE]
    /\ [Example EXCEPT !.name = "Bob", !.active = FALSE] =
        [name |-> "Bob", age |-> 30, active |-> FALSE]
    /\ Cardinality([name : Names, age : Ages, active : BOOLEAN]) = 12

=============================================================================
