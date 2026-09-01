# TLA+ / TLC の直感 — 状態機械として読む

出典: [learning.tlapl.us / Introduction / The TLA+ / TLC Intuition](https://learning.tlapl.us/intro/tla-intuition/)
本家は「構文に入る前に、TLA+ が何をしているのかの直感を作る」ページです。掲載されている DieHard 仕様を
**そのまま**このディレクトリに置き、ローカルの TLC で動かして確認できるようにしています。

前のページ: [examples/01-diehard](../01-diehard)（プラットフォームの使い方）

---

## 1. TLA+ における「アルゴリズム」= 状態機械

TLA+ では、あらゆるアルゴリズムを**状態機械**としてモデル化します。必要なものは 4 つだけです。

- 状態を定める**変数**（variables）
- **初期状態**の述語（initial state predicate）
- 起こりうる遷移をすべて表す**次状態関係**（next-state relation）
- 到達可能なすべての状態で成り立つべき**不変条件**（invariants）

[DieHard.tla](DieHard.tla) がこの 4 つにどう対応しているかが、このページの本題です。

| 状態機械の要素 | このファイルでの姿 |
| --- | --- |
| 変数 | `VARIABLES big, small` |
| 初期状態 | `Init == big = 0 /\ small = 0` |
| 次状態関係 | `Next == FillSmallJug \/ FillBigJug \/ ... \/ BigToSmall` |
| 不変条件 | `NotSolved == big # 4` |

題材は 5 ガロン容器（`big`）と 3 ガロン容器（`small`）で、ちょうど 4 ガロンを量る水差しパズルです。

---

## 2. 仕様の読み方

### 変数とプライム記号

```tla
FillBigJug    == /\ big' = 5
                 /\ small' = small
```

`big` は**現在の状態**の値、`big'`（プライム付き）は**次の状態**の値です。
アクションは「現在と次の関係」を書いた論理式にすぎません。`FillBigJug` は
「次の状態では `big` が 5 で、`small` は変わらない」と言っています。

`/\ small' = small` を書き忘れると、`small'` が何にも制約されないため、TLC は
「そのアクションは次状態を決めきれていない」というエラーで止まります（§7 で実際に試せます）。
**変わらない変数も毎回書く**、が TLA+ のお約束です。

### 次状態関係は「選択肢の論理和」

```tla
Next == \/ FillSmallJug
        \/ FillBigJug
        \/ EmptySmallJug
        \/ EmptyBigJug
        \/ SmallToBig
        \/ BigToSmall
```

`\/`（論理和）なので、各状態で 6 つのうち**どれが起きてもよい**という意味になります。
「どれを選ぶか」は書きません。**非決定的**であることが仕様の強みで、TLC はその全分岐を探索します。

### わざと嘘の不変条件

```tla
NotSolved == big # 4
```

`#` は「等しくない」（`/=` と同じ）です。「5 ガロン容器がちょうど 4 ガロンになることは絶対にない」と主張しています。
これは**嘘**です。TLC はこれを破る状態を見つけ、そこに至る経路を提示します。その経路がパズルの**解答**になります。

---

## 3. 設定ファイル — この仕様には `Spec` がない

[01-diehard](../01-diehard) の `DieHard.tla` には次の定義がありました。

```tla
Spec == Init /\ [][Next]_<<small, big>>
```

本家のこのページの仕様には **`Spec` 式も `TypeOK` もありません**。`Init` と `Next` を裸で置いただけです。
そのため設定ファイルでは `SPECIFICATION` ではなく、`INIT` / `NEXT` を直接指定します。

[DieHard.cfg](DieHard.cfg):

```
INIT Init
NEXT Next

INVARIANT NotSolved

CHECK_DEADLOCK FALSE
```

| 書き方 | 使う場面 |
| --- | --- |
| `INIT Init` + `NEXT Next` | `Init` / `Next` だけがある仕様（このページ） |
| `SPECIFICATION Spec` | `Spec == Init /\ [][Next]_vars` を定義した仕様（[01-diehard](../01-diehard)） |

安全性（不変条件）の検査だけなら両者は等価です。違いが出るのは公平性（fairness）や時相性質を扱うときで、
それは `SPECIFICATION` 形式が必要になります。ここでは深追いしません。

---

## 4. 実行

`DieHard.tla` を開いて `Cmd + Shift + P` → **`TLA+: Check model with TLC`**。
同名の [DieHard.cfg](DieHard.cfg) が自動で使われます。

CLI なら:

```bash
cd examples/02-tla-intuition && java -cp "$(ls -d ~/.vscode/extensions/tlaplus.vscode-ide-*/tools/tla2tools.jar | tail -1)" tlc2.TLC -workers 1 -config DieHard.cfg DieHard.tla
```

### 実際の出力（この環境で確認済み）

```
Computing initial states...
Finished computing initial states: 1 distinct state generated

Error: Invariant NotSolved is violated.
Error: The behavior up to this point is:
State 1: <Initial predicate>
/\ big = 0
/\ small = 0

State 2: <FillBigJug line 23, col 18 to line 24, col 34 of module DieHard>
/\ big = 5
/\ small = 0

State 3: <BigToSmall line 37, col 15 to line 38, col 48 of module DieHard>
/\ big = 2
/\ small = 3

State 4: <EmptySmallJug line 26, col 18 to line 27, col 30 of module DieHard>
/\ big = 2
/\ small = 0

State 5: <BigToSmall line 37, col 15 to line 38, col 48 of module DieHard>
/\ big = 0
/\ small = 2

State 6: <FillBigJug line 23, col 18 to line 24, col 34 of module DieHard>
/\ big = 5
/\ small = 2

State 7: <BigToSmall line 37, col 15 to line 38, col 48 of module DieHard>
/\ big = 4
/\ small = 3

73 states generated, 14 distinct states found, 1 states left on queue.
The depth of the complete state graph search is 7.
```

終了コードは `12`（不変条件違反あり）。トレースを読み下すと 6 手の解答です。

1. 5 ガロンを満タン → (small 0, big 5)
2. 5 → 3 に注ぐ → (3, 2)
3. 3 ガロンを空にする → (0, 2)
4. 5 → 3 に注ぐ → (2, 0)
5. 5 ガロンを満タン → (2, 5)
6. 5 → 3 に注ぐ（3 ガロンには残り 1 しか入らない）→ (3, **4**)

幅優先探索なので、これが**最短手数**であることも同時に分かります。

---

## 5. 状態空間の全体を見る

`INVARIANT NotSolved` の行を `\*` でコメントアウトして再実行すると、TLC は違反を見つけずに全状態を検査し切ります。

```
Model checking completed. No error has been found.
97 states generated, 16 distinct states found, 0 states left on queue.
The depth of the complete state graph search is 8.
The average outdegree of the complete state graph is 1 (minimum is 0, the maximum 2 and the 95th percentile is 2).
```

**到達可能な状態は全部で 16 個**です。`(small, big)` の組み合わせは 4 × 6 = 24 通りありますが、
6 つのアクションだけでは残り 8 通りには到達できません。「状態機械」という言い方の実体がこれです。

その 16 個のグラフを実際に描くこともできます（要 [Graphviz](https://graphviz.org/)）。

```bash
java -cp "$(ls -d ~/.vscode/extensions/tlaplus.vscode-ide-*/tools/tla2tools.jar | tail -1)" tlc2.TLC \
  -workers 1 -config DieHard.cfg -dump dot,colorize,actionlabels states.dot DieHard.tla
dot -Tsvg states.dot -o states.svg
```

ノードが状態、辺がアクション（色分け・ラベル付き）です。`Next` の `\/` が分岐として目に見えます。
`*.dot` / `*.svg` は `.gitignore` 済みなので、生成しても差分には出ません。

---

## 6. デッドロックについて

`CHECK_DEADLOCK FALSE` を外して実行すると、この仕様では**何も起きません**（違反なしで完走します）。
`FillSmallJug` はどの状態でも実行可能なので、「次に進める遷移がない状態」が存在しないからです。

TLC の言う「デッドロック」は `Next` を満たす次状態が 1 つも無い状態のことです。
「正常終了」を表現した仕様では終了状態がそれに該当してしまうため、`CHECK_DEADLOCK FALSE` で無効化するのが定石です。
このパズルでは有効にしたままでも問題ありません。

---

## 7. 触って確かめる

- `NotSolved == big # 4` を `big # 1` にしてみる。1 ガロンも作れます（トレースが手順を教えてくれます）。
- `big # 6` にしてみる。5 ガロン容器に 6 ガロンは入らないので、違反なしで完走します。
- `FillBigJug` から `/\ small' = small` を削って実行する。次のエラーが出ます。
  「変わらない変数も書く」理由が体感できます。

  ```
  Error: Successor state is not completely specified by action FillBigJug
  of the next-state relation. The following variable is not defined: small.
  ```

- `Next` から `BigToSmall` を消す。それでも 4 ガロンは作れますが、手数が増えます
  （8 手・到達可能な状態は 11 個）。片方向にしか注げなくなった分、遠回りになったということです。
- `Next` から `SmallToBig` と `BigToSmall` の両方を消す。注ぐ操作が無くなるので `big` は 0 か 5 しか取れず、
  到達可能な状態はわずか 4 個、違反なしで完走します。

---

## 次に読むもの

- learning.tlapl.us の次ページは [Module Structure](https://learning.tlapl.us/intro/module-structure/) です。
- [examples/00-hello](../00-hello) — 変数ひとつだけの最小の仕様
- [examples/01-diehard](../01-diehard) — TLC の出力の読み方
