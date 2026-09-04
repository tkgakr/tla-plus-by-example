# 変数と定数

出典: [learning.tlapl.us / Introduction / Variables & Constants](https://learning.tlapl.us/intro/variables-constants/)

本家ページの要点とサンプルを、このリポジトリでそのまま実行できる日本語教材として再構成しています。
題材は、上限 `N` まで数える `count` と、全体で 5 まで増える `total` を持つカウンタです。

前のページ: [examples/03-module-structure](../03-module-structure)（モジュールの構造）

---

## 1. `VARIABLE` — 状態とともに変わる値

`VARIABLE` は、システムの**状態**を構成し、状態遷移によって変化しうる値を宣言します。

```tla
VARIABLES count, total
```

複数なら `VARIABLES`、1 個なら `VARIABLE` と書けます。実際には両方とも同じ宣言キーワードなので、
1 個を `VARIABLES x`、複数を `VARIABLE x, y` と書いても意味は変わりません。単数・複数を使い分けるのは
読みやすさのためです。

この仕様の 1 状態は、`count` と `total` の値の組で決まります。たとえば初期状態は
`count = 0, total = 0` です。

---

## 2. プライム記号 `'` — 次の状態の値

アクションの中では、プライムなしの変数が**現在の状態**、プライム付きの変数が**次の状態**の値です。

```tla
Increment ==
    /\ count < N
    /\ total < 5
    /\ count' = count + 1
    /\ total' = total + 1
```

前半 2 行は、この遷移を実行できる条件（ガード）です。後半 2 行は、次の状態で両方の変数を 1 増やします。
これは代入文を上から順に実行しているのではなく、現在値と次の値の**関係**をひとつの論理式で表しています。

変化させない変数も、次の値を明示する必要があります。

```tla
Reset ==
    /\ count = N
    /\ count' = 0
    /\ total' = total
```

`total' = total` は「次の状態でも `total` は同じ」という意味です。これは `UNCHANGED total` とも書けます。
この行を削ると `total'` が制約されず、TLC は次状態を完全に決められないというエラーを報告します。

---

## 3. `CONSTANT` — 1 回のモデル検査中は変わらない値

`CONSTANT` は、仕様をパラメータ化するための値を宣言します。

```tla
CONSTANT N
```

`N` は状態の一部ではなく、ひとつのモデル検査を通して固定されています。値は
[VarsAndConsts.cfg](VarsAndConsts.cfg) で割り当てます。

```cfg
CONSTANT N = 3
```

この分離により、仕様を変更せず `N = 2`、`N = 4` など別の大きさを検査できます。バッファ容量、プロセス集合、
タイムアウトの上限のように、モデルごとに変えたい設定値を定数にするのが典型です。

複数の定数には `CONSTANTS N, MaxVal` と書けます。`VARIABLE` / `VARIABLES` と同様、
`CONSTANT` / `CONSTANTS` の単数・複数形は同じ働きです。

| 宣言 | 状態遷移で変わるか | 値を決める場所 | この例 |
| --- | --- | --- | --- |
| `VARIABLE(S)` | 変わりうる | `Init` と各アクション | `count`, `total` |
| `CONSTANT(S)` | 変わらない | `.cfg` などのモデル設定 | `N` |

---

## 4. `TypeOK` — 型の代わりに期待する値の範囲を書く

TLA+ には、変数への代入を事前に制限する組み込みの型システムがありません。そこで、各変数が期待する集合に
属することを表す式を、慣例として `TypeOK` という不変条件にします。

```tla
TypeOK ==
    /\ count \in 0..N
    /\ total \in 0..5
```

`0..N` は 0 から `N` までの整数の集合、`\in` は「左辺が右辺の集合に属する」という意味です。
`N = 3` のモデルでは、`count` の期待範囲は `{0, 1, 2, 3}` になります。

ただし、`TypeOK` は特殊な型宣言ではなく、単なる真偽式です。定義しただけでは自動検査されないため、設定ファイルで
不変条件として明示します。

```cfg
INVARIANT TypeOK
```

TLC は初期状態と、そこから到達可能なすべての状態で `TypeOK` を検査します。アクションの書き間違いによって
`count = 4` や `total = 6` に到達すれば、その状態までの反例トレースを表示します。

---

## 5. `N = 3` の状態遷移を読む

`Next == Increment \/ Reset` なので、各状態では条件を満たす方のアクションが候補になります。
この設定で到達する状態は次のとおりです。

```text
(count, total)
    (0, 0)
      ↓ Increment
    (1, 1)
      ↓ Increment
    (2, 2)
      ↓ Increment
    (3, 3)
      ↓ Reset
    (0, 3)
      ↓ Increment
    (1, 4)
      ↓ Increment
    (2, 5)
```

最後の `(2, 5)` では、`total < 5` が偽なので `Increment` はできず、`count = N` も偽なので `Reset` も
できません。したがって、この状態は**デッドロック**です。

`TypeOK` は最後まで成立しています。「値の範囲が正しい」ことと「必ず次の遷移がある」ことは別の性質です。
本家の設定と同じく、この例では TLC のデッドロック検査を有効なままにして、その違いも観察します。

---

## 6. TLC で実行する

`VarsAndConsts.tla` を開いて `Cmd + Shift + P` → **`TLA+: Check model with TLC`** を実行します。
同じディレクトリの [VarsAndConsts.cfg](VarsAndConsts.cfg) が設定ファイルです。

CLI なら次のコマンドです。

```bash
cd examples/04-variables-constants
java -cp "$(ls -d ~/.vscode/extensions/tlaplus.vscode-ide-*/tools/tla2tools.jar | tail -1)" \
  tlc2.TLC -workers 1 -config VarsAndConsts.cfg VarsAndConsts.tla
```

TLC は 7 個の到達可能状態すべてで `TypeOK` が成立することを確認した後、意図どおりデッドロックを報告します。
トレースの最後は次の値です。

```text
Error: Deadlock reached.
...
State 7: <Increment ... of module VarsAndConsts>
/\ count = 2
/\ total = 5
```

TLC はエラーとして非ゼロで終了します（具体的な終了コードは TLC のバージョンに依存します）。これは `TypeOK` 違反では
ありません。デッドロックを今回の検査対象から外したい場合だけ、設定ファイルの末尾に次を追加します。

```cfg
CHECK_DEADLOCK FALSE
```

その場合は違反なしで完了し、終了コードは `0` になります。

---

## 7. 触って確かめる

- `VarsAndConsts.cfg` の `N = 3` を `N = 2` や `N = 4` に変更する。仕様ファイルを変えずに別モデルを検査できます。
- `Increment` の `total' = total + 1` を `total' = total + 2` にする。`total = 6` に到達し、
  `TypeOK` 違反の反例が得られます。
- `Reset` の `total' = total` を `UNCHANGED total` に書き換える。検査結果が変わらないことを確認できます。
- `Reset` から `total' = total` を削除する。`total` の次状態が未指定だという TLC のエラーを確認できます。
- `.cfg` の `INVARIANT TypeOK` をコメントアウトしてから、上限を破る変更を実行する。
  `TypeOK` は定義するだけでは検査されないことが分かります。
- `.cfg` に `CHECK_DEADLOCK FALSE` を追加する。型の不変条件だけを検査して正常終了することを確認できます。

---

## 次に読むもの

- learning.tlapl.us の次ページは [Basic Operators](https://learning.tlapl.us/intro/basic-operators/) です。
- [examples/05-basic-operators](../05-basic-operators) — 論理演算子、アクション、`UNCHANGED`、条件式
- [examples/03-module-structure](../03-module-structure) — モジュール、`EXTENDS`、コメント、デバッグ出力
- [examples/00-hello](../00-hello) — `Spec == Init /\ [][Next]_x` を使う最小構成
