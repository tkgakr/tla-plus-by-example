# 基本演算子

出典: [learning.tlapl.us / Introduction / Basic Operators](https://learning.tlapl.us/intro/basic-operators/)

本家ページの要点と信号機サンプルを、このリポジトリで実行できる日本語教材として再構成しています。
赤 → 青 → 黄 → 赤と変化する信号機を使い、論理演算子、`Init` / `Next`、プライム記号、
`UNCHANGED`、`IF / THEN / ELSE` をまとめて確認します。

前のページ: [examples/04-variables-constants](../04-variables-constants)（変数と定数）

---

## 1. 真偽値を組み合わせる演算子

TLA+ でよく使う論理演算子は次のとおりです。仕様ファイルでは ASCII 表記と Unicode 表記のどちらも使えます。
このリポジトリでは、キーボードから入力しやすく、元ページとも対応させやすい ASCII 表記を使います。

| ASCII | Unicode | 意味 | 読み方 |
| --- | --- | --- | --- |
| `/\` | `∧` | 論理積 | A かつ B |
| `\/` | `∨` | 論理和 | A または B |
| `~` | `¬` | 否定 | A ではない |
| `=>` | `⇒` | 含意 | A ならば B |
| `<=>` | `⇔` | 同値 | A と B の真偽が同じ |

たとえば [BasicOperators.tla](BasicOperators.tla) の `OperatorLaws` は、これらを到達可能な全状態で検査します。

```tla
OperatorLaws ==
    /\ (IsGo <=> ~IsStop)
    /\ (IsStop => Instruction = "stop")
    /\ Instruction \in {"go", "stop"}
```

`A => B` が偽になるのは、A が真なのに B が偽の場合だけです。そのため 2 行目は、停止を示す状態なら
表示が必ず `"stop"` であることを表します。一方、`A <=> B` は両方向の含意、つまり A と B が同じ真偽値を
持つことを表します。

### 行頭の `/\` と `\/`

TLA+ では、同じ演算子を行頭にそろえて縦に書けます。

```tla
Init ==
    /\ light = "red"
    /\ cycles = 0
```

これは `(light = "red") /\ (cycles = 0)` と同じです。括弧の対応より構造が見やすくなるため、
複数の条件や候補を書くときによく使われます。

---

## 2. `Init` / `Next` パターン

多くの TLA+ 仕様は、初期状態を表す `Init` と、可能な状態遷移を表す `Next` に分けて書きます。

```tla
Init ==
    /\ light = "red"
    /\ cycles = 0

Next ==
    \/ ToGreen
    \/ ToYellow
    \/ ToRed
```

`Init` は論理積 `/\` なので、初期状態では `light = "red"` と `cycles = 0` の両方が成立します。
`Next` は論理和 `\/` なので、各状態では `ToGreen`、`ToYellow`、`ToRed` のうち、条件を満たす
いずれかのアクションを選べます。

ここでの「または」は、プログラムの `if` / `else if` を上から実行するという意味ではありません。
複数の候補が同時に成立すれば、TLC はそのすべてを別の遷移として探索します。この信号機では各色に対応する候補が
1 個だけなので、色の変化は決定的です。

---

## 3. アクションとプライム記号

アクションは、現在の状態と次の状態の関係を表す真偽式です。プライムなしの `light` は現在値、
プライム付きの `light'` は次状態の値を指します。

```tla
ToGreen ==
    /\ light = "red"
    /\ light' = "green"
    /\ UNCHANGED cycles
```

1 行目は遷移を選べる条件、2 行目以降は次状態への制約です。命令型言語の代入と違い、上から順番に値を
書き換える処理ではありません。3 行を同時に満たす現在状態と次状態の組を定義しています。

等しくないことは `#` で表します。次のアクション式は「現在が青なら、次に直接赤へ変わらない」という意味です。

```tla
NeverSkipYellow == (light = "green") => (light' # "red")
```

これは現在値と次状態値の両方を含むため、1 状態だけを調べる不変条件ではありません。この例では
`NeverSkipYellowAlways == [][NeverSkipYellow]_vars` として全ステップに対する時間的性質にし、`.cfg` の
`PROPERTY` で検査しています。

---

## 4. `UNCHANGED` — 値を変えない

アクションでは、すべての変数の次状態を制約する必要があります。`ToGreen` では色だけを変え、周回数 `cycles` は
変えないため、次のように書いています。

```tla
/\ UNCHANGED cycles
```

これは `cycles' = cycles` と同じです。実際、`ToYellow` では比較のために後者の書き方を使っています。
複数の変数をまとめて変えない場合は、タプルを使って次のように書けます。

```tla
UNCHANGED <<x, y>>
```

変数の次状態を指定し忘れると、その変数は「前と同じ」になるのではなく、任意の値を取れる状態になります。
変えない変数には必ず `UNCHANGED` または `x' = x` を書く、と覚えておくと安全です。

---

## 5. `IF / THEN / ELSE` — 値を選ぶ式

TLA+ の `IF / THEN / ELSE` は制御文ではなく、条件によって値を選ぶ**式**です。

```tla
Instruction == IF IsGo THEN "go" ELSE "stop"
```

`light = "green"` のときは `"go"`、それ以外は `"stop"` という値になります。どちらの枝も必須です。
この仕様では、黄から赤へ戻るたびに `cycles` を増やし、2 に達した後は有限状態に保つため同じ値に据え置きます。

```tla
/\ cycles' = IF cycles < 2 THEN cycles + 1 ELSE cycles
```

上限を設けるのは現実の信号機の制約ではなく、TLC が探索する状態数を有限にするためです。

---

## 6. 仕様全体と状態遷移

`vars` は、この仕様の状態を構成する変数をまとめたタプルです。

```tla
vars == <<light, cycles>>
Spec == Init /\ [][Next]_vars
```

`Spec` は「最初に `Init` が成立し、その後は `Next` の遷移または状態を変えない停滞ステップが続く」ことを表します。
到達する 9 状態は次のとおりです。

```text
(red, 0) → (green, 0) → (yellow, 0)
    → (red, 1) → (green, 1) → (yellow, 1)
    → (red, 2) → (green, 2) → (yellow, 2)
    → (red, 2) → ...
```

TLC は同じ状態を再訪した時点で、それより先を改めて展開する必要がないと判断します。そのためシステムが動き続ける
仕様でも、異なる状態が有限なら検査を完了できます。

---

## 7. TLC で実行する

`BasicOperators.tla` を開いて `Cmd + Shift + P` → **`TLA+: Check model with TLC`** を実行します。
同じディレクトリの [BasicOperators.cfg](BasicOperators.cfg) が設定ファイルです。

CLI なら次のコマンドです。

```bash
cd examples/05-basic-operators
java -cp "$(ls -d ~/.vscode/extensions/tlaplus.vscode-ide-*/tools/tla2tools.jar | tail -1)" \
  tlc2.TLC -workers 1 -config BasicOperators.cfg BasicOperators.tla
```

設定ファイルでは、状態についての性質を `INVARIANT`、遷移についての性質を `PROPERTY` として検査します。

```cfg
SPECIFICATION Spec

INVARIANT TypeOK
INVARIANT OperatorLaws

PROPERTY NeverSkipYellowAlways
```

正常なら `Model checking completed. No error has been found.` と表示され、終了コード `0` になります。
このモデルでは 9 個の異なる状態が見つかり、`TypeOK`、`OperatorLaws`、`NeverSkipYellowAlways` のすべてが成立します。

---

## 8. 触って確かめる

- `Next` から `ToYellow` を外す。青で進めなくなるため、TLC がデッドロックを報告します。
- `ToYellow` の `light' = "yellow"` を `light' = "red"` に変える。`NeverSkipYellowAlways` 違反の反例が得られます。
- `ToGreen` の `UNCHANGED cycles` を `cycles' = cycles` に変える。検査結果が変わらないことを確認できます。
- `ToGreen` から `UNCHANGED cycles` を削る。次状態の `cycles` が制約されないため、TLC のエラーになります。
- `IsStop` を `light = "red" /\ light = "yellow"` に変える。`OperatorLaws` 違反が見つかります。
- `Instruction` の `"stop"` を `"wait"` に変える。`OperatorLaws` のどの条件が破れるか確認できます。
- `ToRed` の上限 `2` と `TypeOK` の `0..2` を同じ値に変更し、探索状態数がどう変わるか比べます。

---

## 次に読むもの

- learning.tlapl.us の次ページは [Sets](https://learning.tlapl.us/intro/sets/) です。
- [examples/06-sets](../06-sets) — 集合演算、有限集合、内包表記、写像
- [examples/04-variables-constants](../04-variables-constants) — 変数、定数、`TypeOK`
- [examples/00-hello](../00-hello) — `Spec == Init /\ [][Next]_x` の最小例
