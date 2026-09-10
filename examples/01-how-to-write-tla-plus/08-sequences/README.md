# シーケンス

出典: [learning.tlapl.us / Introduction / Sequences](https://learning.tlapl.us/intro/sequences/)

本家ページの要点と上限付きスタックのサンプルを、このリポジトリで実行できる日本語教材として再構成しています。
シーケンスのリテラルと参照、`Seq`、`Len`、`Head`、`Tail`、`Append`、連結、`SubSeq`、
`SelectSeq`、関数としてのシーケンスを扱います。

前のページ: [examples/01-how-to-write-tla-plus/07-functions](../07-functions)（関数）

---

## 1. 順序と重複を持つ値

シーケンスは、要素を順番に並べた有限の列です。山括弧を二重にした `<<...>>` で書きます。

| 構文 | 意味 |
| --- | --- |
| `<<1, 2, 3>>` | 3 要素のシーケンス |
| `<<>>` | 空シーケンス |
| `<<"hello">>` | 1 要素のシーケンス |
| `s[1]` | 先頭の要素 |
| `s[Len(s)]` | 最後の要素 |

前章までに扱った集合と違い、シーケンスは順序と重複を保持します。

```tla
<<1, 2, 1>> # <<1, 1, 2>>
```

どちらにも同じ数が現れますが、並び方が違うので等しくありません。また、値 `1` が 2 回現れることにも意味が
あります。キュー、スタック、履歴、メッセージ列のように、並び順や同じ値の繰り返しが重要なデータに使います。

添字は多くのプログラミング言語と違って **1 から**始まります。空シーケンスや範囲外の添字を参照した結果には
依存できません。`Head` や `Tail` を使う前にも、シーケンスが空でないことを確認します。

---

## 2. `Sequences` 標準モジュール

シーケンス用の演算子を使うには、標準モジュール `Sequences` を拡張します。

```tla
EXTENDS Naturals, FiniteSets, Sequences
```

実行用ファイルを `Sequences.tla` ではなく `BoundedStack.tla` としているのは、標準モジュールと同名にすると
自分自身を読み込む循環参照になってしまうためです。

主な演算子は次のとおりです。

| 演算子 | 意味 | 例 |
| --- | --- | --- |
| `Seq(S)` | `S` の要素からなる、すべての有限シーケンスの集合 | `<<"red">> \in Seq(Items)` |
| `Len(s)` | 要素数 | `Len(<<1, 2>>) = 2` |
| `Head(s)` | 先頭の要素 | `Head(<<1, 2>>) = 1` |
| `Tail(s)` | 先頭を除いたシーケンス | `Tail(<<1, 2>>) = <<2>>` |
| `Append(s, e)` | `e` を末尾に追加 | `Append(<<1>>, 2) = <<1, 2>>` |
| `s \o t` | 2 個のシーケンスを連結 | `<<1>> \o <<2, 3>> = <<1, 2, 3>>` |
| `SubSeq(s, m, n)` | 添字 `m` から `n` までを取り出す | `SubSeq(<<1, 2, 3>>, 2, 3) = <<2, 3>>` |
| `SelectSeq(s, Test)` | 条件を満たす要素だけを残す | 後述 |

`\o` は Unicode では `∘` と書けます。このリポジトリでは入力しやすい ASCII 表記を使います。

`Seq(S)` は長さに上限のないシーケンスをすべて含むため、`S` が有限でも無限集合です。型のような不変条件には
使えますが、変数を `Seq(S)` から無制限に選ぶモデルは TLC で有限個の状態として列挙できません。この例では
`MaxDepth` を設け、遷移側でも長さを制限します。

---

## 3. シーケンスは関数

TLA+ では、長さ `n` のシーケンスは定義域が `1..n` の関数です。そのため、前章の関数と同じ角括弧で
要素を参照できます。

```tla
Example == <<"red", "green", "red", "blue">>

Example[1]                   \* "red"
DOMAIN Example               \* {1, 2, 3, 4}
DOMAIN Example = 1..Len(Example)
```

「シーケンスは関数」というのは、単に似た記法を使うという意味ではありません。`<<"a", "b">>` は、
`[i \in 1..2 |-> IF i = 1 THEN "a" ELSE "b"]` と同じ値です。

[BoundedStack.tla](BoundedStack.tla) の `DomainOK` は、到達するすべての `stack` についてこの関係を検査します。

```tla
DomainOK == DOMAIN stack = 1..Len(stack)
```

---

## 4. 部分列と絞り込み

`SubSeq(s, m, n)` は、`s` の添字 `m` から `n` までを順序どおりに取り出します。両端を含むことに
注意してください。

```tla
SubSeq(Example, 2, 3) = <<"green", "red">>
```

`SelectSeq` は、条件を演算子として受け取り、真になった要素だけを残します。集合の内包表記と違い、元の順序と
重複は保たれます。

```tla
IsRed(item) == item = "red"

SelectSeq(Example, IsRed) = <<"red", "red">>
```

条件に渡すのは `IsRed(item)` の計算結果ではなく、引数を受け取れる演算子名 `IsRed` です。

---

## 5. 上限付きスタック

この例では `stack` の先頭をスタックの一番上として扱います。初期状態は空です。

```tla
Init == stack = <<>>
```

`Push` は、選んだ要素 1 個のシーケンスを現在の `stack` の前へ連結します。

```tla
Push ==
    /\ Len(stack) < MaxDepth
    /\ \E item \in Items :
        stack' = <<item>> \o stack
```

1 行目は深さを 3 以下に保つガードです。2 行目では 3 色のどれを積むかを非決定的に選ぶため、TLC は各候補を
別の遷移として探索します。

`Pop` は先頭を取り除きます。`Tail(<<>>)` を評価しないように、空でないことをガードで確認しています。

```tla
Pop ==
    /\ stack # <<>>
    /\ stack' = Tail(stack)
```

本家ページにある末尾追加のキューなら、次のように書けます。スタックとキューでは、追加する側だけが異なります。

```tla
Enqueue(s, e) == Append(s, e)
Dequeue(s)    == Tail(s)
Front(s)      == Head(s)
```

---

## 6. 状態数と不変条件

要素は 3 色、最大の長さは 3 です。到達可能なシーケンスの個数は、長さごとの場合の数を足して
`1 + 3 + 3^2 + 3^3 = 40` 状態になります。

```text
長さ 0:  1 状態   <<>>
長さ 1:  3 状態   例: <<"red">>
長さ 2:  9 状態   例: <<"red", "green">>
長さ 3: 27 状態   例: <<"red", "green", "red">>
```

`TypeOK` は、要素と長さを別々に検査します。

```tla
TypeOK ==
    /\ stack \in Seq(Items)
    /\ Len(stack) <= MaxDepth
```

`stack \in Seq(Items)` だけでは、すべての要素が `Items` に属することは保証できても長さを制限できません。
逆に `Len(stack) <= MaxDepth` だけでは、未知の値が混ざることを防げません。

`SequenceExamplesOK` では、静的な `Example` を使って各演算子の結果も全状態で検査します。この条件は状態に
よらないため同じ計算を繰り返す形ですが、例を変更したときに期待値とのずれを TLC が検出できます。

---

## 7. TLC で実行する

`BoundedStack.tla` を開いて `Cmd + Shift + P` → **`TLA+: Check model with TLC`** を実行します。
同じディレクトリの [BoundedStack.cfg](BoundedStack.cfg) が設定ファイルです。

CLI なら次のコマンドです。

```bash
cd examples/01-how-to-write-tla-plus/08-sequences
java -cp "$(ls -d ~/.vscode/extensions/tlaplus.vscode-ide-*/tools/tla2tools.jar | tail -1)" \
  tlc2.TLC -workers 1 -config BoundedStack.cfg BoundedStack.tla
```

設定ファイルでは次の 3 つを検査します。

```cfg
INIT Init
NEXT Next

INVARIANT TypeOK
INVARIANT DomainOK
INVARIANT SequenceExamplesOK
```

正常なら `Model checking completed. No error has been found.` と表示され、終了コード `0` になります。
このモデルでは 40 個の異なる状態が見つかります。

---

## 8. 触って確かめる

- `MaxDepth` を `2` に変える。到達状態数が `1 + 3 + 9 = 13` になることを確認します。
- `Items` に `"yellow"` を加える。到達状態数が `1 + 4 + 16 + 64 = 85` になります。
- `Push` の `<<item>> \o stack` を `Append(stack, item)` に変える。追加位置は変わりますが、全シーケンスに
  到達できるため状態数は 40 のままです。
- `Pop` から `stack # <<>>` を削る。空シーケンスに `Tail` を適用したとき、TLC がエラーを報告します。
- `Push` の長さのガードを削る。長さが増え続けるため、TLC の探索が終了しないモデルになります。
- `IsRed` を `item # "green"` に変え、`SelectSeq` の期待値を `<<"red", "red", "blue">>` に直します。
- `SubSeq(Example, 2, 3)` の範囲を変え、両端を含むことと 1 始まりの添字を確認します。

---

## 次に読むもの

- learning.tlapl.us の次ページは [Records](https://learning.tlapl.us/intro/records/) です。
- [examples/01-how-to-write-tla-plus/07-functions](../07-functions) — 関数の定義、`DOMAIN`、関数集合、`EXCEPT`
- [examples/01-how-to-write-tla-plus/06-sets](../06-sets) — 集合の順序・重複とシーケンスとの違い
- [examples/01-how-to-write-tla-plus/05-basic-operators](../05-basic-operators) — アクション、プライム記号、`UNCHANGED`
