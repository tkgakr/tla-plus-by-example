--------------------------- MODULE BoundedStack ------------------------------
(***************************************************************************)
(* 上限付きスタックを使って、TLA+ のシーケンス演算を確認する。             *)
(***************************************************************************)

EXTENDS Naturals, FiniteSets, Sequences

VARIABLE stack

Items == {"red", "green", "blue"}
MaxDepth == 3

Example == <<"red", "green", "red", "blue">>

IsRed(item) == item = "red"

Init ==
    stack = <<>>

Push ==
    /\ Len(stack) < MaxDepth
    /\ \E item \in Items :
        stack' = <<item>> \o stack

Pop ==
    /\ stack # <<>>
    /\ stack' = Tail(stack)

Next ==
    Push \/ Pop

TypeOK ==
    /\ stack \in Seq(Items)
    /\ Len(stack) <= MaxDepth

DomainOK ==
    DOMAIN stack = 1..Len(stack)

SequenceExamplesOK ==
    /\ Len(<<>>) = 0
    /\ Len(Example) = 4
    /\ Example[1] = "red"
    /\ Example[Len(Example)] = "blue"
    /\ Head(Example) = "red"
    /\ Tail(Example) = <<"green", "red", "blue">>
    /\ Append(<<"red", "green">>, "blue") = <<"red", "green", "blue">>
    /\ <<"red">> \o <<"green", "blue">> = <<"red", "green", "blue">>
    /\ SubSeq(Example, 2, 3) = <<"green", "red">>
    /\ SelectSeq(Example, IsRed) = <<"red", "red">>
    /\ Cardinality(DOMAIN Example) = Len(Example)

=============================================================================
