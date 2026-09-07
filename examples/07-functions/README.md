# 関数

出典: [learning.tlapl.us / Introduction / Functions](https://learning.tlapl.us/intro/functions/)

本家ページの要点を、既存の集合・基本演算子の章に続く日本語教材として再構成しています。
関数の定義、値の参照、`DOMAIN`、関数集合、`EXCEPT`、`@` を扱います。
実行用には、固定した 2 個のキーに数値を保存する小さなモデルをこの教材用に用意しました。

前のページ: [examples/06-sets](../06-sets)（集合）

---

## 1. 関数を値として扱う

TLA+ の関数は、定義域の各要素に 1 個の値を対応させるものです。辞書やマップに似ています。
次の `Double` は、入力が `1`、`2`、`3` のとき、それぞれ `2`、`4`、`6` に対応する関数です。

```tla
Double == [x \in 1..3 |-> x * 2]
```

`[x \in S |-> 式]` は、集合 `S` を定義域とし、各 `x` に式の値を対応させます。
ここで `Double` は引数なしの演算子名であり、その値が関数です。

これまでの章で使った引数付きの演算子とは、次のように書き分けます。

| 対象 | 定義例 | 使い方 |
| --- | --- | --- |
| 引数付きの演算子 | `Twice(x) == x * 2` | `Twice(2)` |
| 関数を値に持つ演算子 | `Double == [x \in 1..3 |-> x * 2]` | `Double[2]` |

関数は、変数に保存したり、集合の要素にしたりできます。今回の状態変数 `store` も関数を値に持ちます。

---

## 2. 値の参照と `DOMAIN`

関数の値を参照するときは角括弧 `[]` を使います。`DOMAIN` は定義域の集合を返します。

```tla
Double[2]       \* 4
DOMAIN Double   \* {1, 2, 3}
```

定義域にない入力での値には依存しないでください。このモデルで `Double[4]` を評価しようとすると、
TLC は定義域外の関数参照としてエラーにします。参照するキーが定義域に含まれることを意識します。

前章の集合の写像との違いも確認できます。

```tla
{x * 2 : x \in 1..3}     \* 出力値を集めた集合 {2, 4, 6}
[x \in 1..3 |-> x * 2]   \* 入力と出力の対応を持つ関数
```

集合 `{2, 4, 6}` 自体には、入力 `2` に出力 `4` を対応させる情報はありません。

---

## 3. 関数集合と `TypeOK`

`[S -> T]` は、定義域がちょうど `S` で、すべての出力が `T` に属する関数の集合です。

```tla
Keys == {"a", "b"}
Values == 0..2

TypeOK == store \in [Keys -> Values]
```

この条件は、`store` が `"a"` と `"b"` の両方をキーに持ち、それ以外のキーは持たず、
各値が `0`、`1`、`2` のいずれかであることを表します。各キーで同じ値を選んでも構いません。
また、出力として `Values` の全要素を使い切る必要もありません。

次の 3 種類の角括弧は、形が似ていても役割が異なります。

| 構文 | 結果 |
| --- | --- |
| `[key \in Keys |-> 0]` | すべてのキーで値が `0` の関数 1 個 |
| `[Keys -> Values]` | 各キーに `Values` の値を割り当てる関数すべての集合 |
| `store["a"]` | 現在の `store` でキー `"a"` に対応する値 |

[Functions.tla](Functions.tla) では、真偽値を保存する場合も静的な例として定義しています。

```tla
Flags == [Keys -> BOOLEAN]
```

`BOOLEAN` は `{TRUE, FALSE}` なので、この集合には 4 個の関数が含まれます。
次の表の各行が、1 個の関数に相当します。

| `"a"` の値 | `"b"` の値 |
| --- | --- |
| `FALSE` | `FALSE` |
| `FALSE` | `TRUE` |
| `TRUE` | `FALSE` |
| `TRUE` | `TRUE` |

---

## 4. `EXCEPT` — 一部だけ異なる関数を作る

`EXCEPT` は、元の関数の指定箇所だけを変えた新しい関数を返す式です。

```tla
[Double EXCEPT ![2] = 10]
```

この式の結果は、入力 `1`、`2`、`3` にそれぞれ `2`、`10`、`6` を対応させます。
`Double` 自体は変わりません。`![2]` は、更新対象が入力 `2` に対応する箇所であることを示します。

状態変数を更新するアクションでは、この式を次状態の値に結び付けます。

```tla
store' = [store EXCEPT !["a"] = 2]
```

`EXCEPT` が新しい関数を作り、`store' = ...` が次状態の `store` を制約します。
キー `"b"` の値も右辺の関数に含まれるため、別途 `UNCHANGED` を書く必要はありません。
ただし、ほかに状態変数を追加した場合は、その変数の次状態も指定する必要があります。

この章ではキー集合を固定しています。`EXCEPT` は定義域を拡張してキーを追加するための構文ではありません。

---

## 5. `@` — 更新対象の元の値を使う

`EXCEPT` の更新式で `@` を使うと、その箇所の更新前の値を参照できます。

```tla
store' = [store EXCEPT ![key] = @ + 1]
```

この式での `@` は `store[key]` に相当します。関数全体でも、次状態の値でもありません。
たとえば `store["a"] = 1` の状態で `key = "a"` を選ぶと、次状態では `store["a"] = 2` になります。

`Increment` では上限に達したキーを選ばないようにガードを付けています。

```tla
Increment ==
    \E key \in Keys :
        /\ store[key] < 2
        /\ store' = [store EXCEPT ![key] = @ + 1]
```

`TypeOK` は値が範囲内に収まるかを検査する条件です。上限を超える遷移を自動で取り除くものではないため、
`store[key] < 2` をアクション側に書きます。

---

## 6. ストアの状態遷移

初期状態は、両方のキーの値が `0` の関数です。

```tla
Init == store = [key \in Keys |-> 0]
```

`Put` はキーと値を非決定的に選んで保存します。`\E` の候補を TLC がすべて探索します。

```tla
Put ==
    \E key \in Keys :
        \E value \in Values :
            store' = [store EXCEPT ![key] = value]

Next == Put \/ Increment
```

現在と同じ値の保存も可能なので、`Put` には自己ループがあります。すべての状態で `Put` を実行できるため、
両キーが上限に達して `Increment` ができなくなってもデッドロックにはなりません。

各キーの値には 3 通りあり、すべての組合せに到達できるので、状態数は `3^2 = 9` です。
次の表では関数を `(store["a"], store["b"])` の組で略記しています。

| `"a"` の値 | `"b" = 0` | `"b" = 1` | `"b" = 2` |
| --- | --- | --- | --- |
| `0` | `(0, 0)` | `(0, 1)` | `(0, 2)` |
| `1` | `(1, 0)` | `(1, 1)` | `(1, 2)` |
| `2` | `(2, 0)` | `(2, 1)` | `(2, 2)` |

1 ステップで変わるのは最大 1 キーです。たとえば `(0, 0)` から `(2, 2)` には、少なくとも 2 ステップ必要です。
`Increment` の遷移は `Put` でも表せますが、`@` を使う例として別に定義しています。

---

## 7. TLC で実行する

`Functions.tla` を開いて `Cmd + Shift + P` → **`TLA+: Check model with TLC`** を実行します。
同じディレクトリの [Functions.cfg](Functions.cfg) が設定ファイルです。

CLI なら次のコマンドです。

```bash
cd examples/07-functions
java -cp "$(ls -d ~/.vscode/extensions/tlaplus.vscode-ide-*/tools/tla2tools.jar | tail -1)" \
  tlc2.TLC -workers 1 -config Functions.cfg Functions.tla
```

設定ファイルでは次の 3 つを検査します。

```cfg
INIT Init
NEXT Next

INVARIANT TypeOK
INVARIANT DomainOK
INVARIANT FunctionExamplesOK
```

| 不変条件 | 確認する内容 |
| --- | --- |
| `TypeOK` | ストアが `[Keys -> Values]` に属する |
| `DomainOK` | `DOMAIN store = Keys` が成立する |
| `FunctionExamplesOK` | 関数参照・関数集合・更新式の例が期待どおりである |

`DomainOK` は `TypeOK` に含まれる条件を、`DOMAIN` の練習として明示したものです。
`FunctionExamplesOK` には、各状態のストアの `"a"` を `0` に置き換えた関数も期待する関数集合に属する、という検査を含めています。

正常なら `Model checking completed. No error has been found.` と表示され、終了コード `0` になります。
このモデルでは 9 個の異なる状態が見つかります。

---

## 8. 触って確かめる

- `Keys` に `"c"` を追加する。各キーが 3 通りの値を取れるので、到達状態数は 27 になります。
  `Flags` の要素数も 8 になるため、`FunctionExamplesOK` の期待値 `4` を `8` に変更します。
- `Increment` のガード `store[key] < 2` を削る。値 `3` が生成され、`TypeOK` 違反になります。
- `@ + 1` を `store[key] + 1` に書き換える。同じ検査結果になることを確認できます。
- `Next` を `Put` だけにする。`Increment` の遷移は `Put` にも含まれるため、到達状態数は 9 のままです。
- `Next` を `Increment` だけにする。両キーが `2` になると進めず、デッドロックになります。
- `Put` の右辺を `[key \in Keys |-> value]` に変える。選んだキーだけでなく、全キーを同じ値にする遷移になります。
  `TypeOK` はこれでも成立します。「値の範囲」と「変更するキーの数」は異なる性質だと確認できます。

---

## 次に読むもの

- learning.tlapl.us の次ページは [Sequences](https://learning.tlapl.us/intro/sequences/) です。
- [examples/06-sets](../06-sets) — 集合演算、有限集合、内包表記、写像
- [examples/05-basic-operators](../05-basic-operators) — アクション、プライム記号、`UNCHANGED`
- [examples/04-variables-constants](../04-variables-constants) — 変数、定数、`TypeOK`
