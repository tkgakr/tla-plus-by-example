# 集合

出典: [learning.tlapl.us / Introduction / Sets](https://learning.tlapl.us/intro/sets/)

本家ページの要点と色を選択するサンプルを、このリポジトリで実行できる日本語教材として再構成しています。
集合リテラル、所属判定、集合演算、有限集合、内包表記、写像、整数の範囲を扱います。

前のページ: [examples/05-basic-operators](../05-basic-operators)（基本演算子）

---

## 1. TLA+ の基礎は集合

TLA+ は集合論を基礎にしています。集合はプログラミング言語のリストや配列とは異なり、要素の**順序**を持たず、
同じ要素を重複して持ちません。

```tla
Colors == {"red", "green", "blue"}
```

したがって、次の 2 つの集合は等しい値です。

```tla
{1, 2, 3} = {3, 2, 1}
```

`{1, 1, 2}` も `{1, 2}` と同じ集合です。集合を列のように先頭から処理したり、同じ値を複数回数えたりは
できません。そのようなデータには、後の章で扱うシーケンスを使います。

---

## 2. 集合リテラルと所属判定

中括弧 `{...}` で有限集合を直接書けます。

| 構文 | 意味 |
| --- | --- |
| `{1, 2, 3}` | 数の集合 |
| `{"a", "b", "c"}` | 文字列の集合 |
| `{}` | 空集合 |
| `x \in S` | `x` は `S` の要素である |
| `x \notin S` | `x` は `S` の要素ではない |

所属記号は Unicode の `∈`、`∉` でも書けます。このリポジトリでは入力しやすい ASCII 表記の `\in` と
`\notin` を使います。

[Sets.tla](Sets.tla) の `AddColor` は、まだ選ばれていない色を探します。

```tla
/\ \E color \in Colors :
    /\ color \notin picked
    /\ picked' = picked \union {color}
```

`\E color \in Colors : P(color)` は「`Colors` の中に条件 `P` を満たす `color` が少なくとも 1 つ存在する」
という存在量化です。候補が複数あれば、TLC はそれぞれを異なる次状態として探索します。

---

## 3. 集合を組み合わせる演算子

この例では、次の集合も定義しています。

```tla
WarmColors == {"red", "yellow"}
```

`Colors` と `WarmColors` に演算子を適用すると、次の値になります。

| 演算子 | 意味 | この例の結果 |
| --- | --- | --- |
| `S \union T` | 和集合: どちらかに含まれる要素 | `{"red", "green", "blue", "yellow"}` |
| `S \intersect T` | 積集合: 両方に含まれる要素 | `{"red"}` |
| `S \ T` | 差集合: `S` にだけ含まれる要素 | `{"green", "blue"}` |
| `S \subseteq T` | `S` の全要素が `T` に含まれるか | 真偽値 |
| `SUBSET S` | `S` のすべての部分集合からなる集合 | べき集合 |

和集合、積集合、部分集合は、それぞれ Unicode の `∪`、`∩`、`⊆` でも書けます。

`SUBSET Colors` には次の 8 要素が入ります。外側の集合の各要素が、それぞれ集合であることに注目してください。

```tla
{
  {},
  {"red"}, {"green"}, {"blue"},
  {"red", "green"}, {"red", "blue"}, {"green", "blue"},
  {"red", "green", "blue"}
}
```

要素数が 3 の集合には `2^3 = 8` 個の部分集合があります。仕様では
`Cardinality(SUBSET Colors) = 8` を実際に検査します。

---

## 4. `FiniteSets` — 有限集合の演算

有限集合の要素数などを扱うには、標準モジュール `FiniteSets` を拡張します。

```tla
EXTENDS Naturals, FiniteSets
```

| 演算子 | 意味 |
| --- | --- |
| `IsFiniteSet(S)` | `S` が有限集合なら `TRUE` |
| `Cardinality(S)` | 有限集合 `S` の要素数 |

`Cardinality` は有限集合に対してだけ使います。`IsFiniteSet(Colors)` と `Cardinality(Colors) = 3` は
`SetExamplesOK` に含め、TLCで検査しています。

色を追加する前のガードも、要素数を使って書いています。

```tla
Cardinality(picked) < Cardinality(Colors)
```

これにより、すべての色を選択済みの状態では `AddColor` を実行できません。

---

## 5. 内包表記 — 条件に合う要素を残す

集合 `S` の要素から条件 `P` を満たすものだけを選ぶには、次の形を使います。

```tla
{x \in S : P(x)}
```

この例では、1 から 10 のうち 5 より大きい数を選びます。

```tla
LargeNumbers == {number \in 1..10 : number > 5}
```

結果は `{6, 7, 8, 9, 10}` です。元の集合の要素を条件で**絞り込む**構文であり、要素そのものを別の値へ
変換する構文ではありません。

---

## 6. 集合の写像 — 各要素を変換する

集合 `S` の各要素へ式 `f(x)` を適用した集合は、次の形で作ります。

```tla
{f(x) : x \in S}
```

この例では、1 から 3 の各整数を 2 倍します。

```tla
Doubled == {number * 2 : number \in 1..3}
```

結果は `{2, 4, 6}` です。写像の結果が重複した場合、その重複は集合では 1 要素にまとまります。

### 整数の範囲 `a..b`

`1..5` は `{1, 2, 3, 4, 5}` と同じ集合です。`..` を使うには `Naturals` または `Integers` など、
範囲演算子を提供する標準モジュールを `EXTENDS` します。

下端が上端より大きい範囲は空集合です。たとえば `3..2 = {}` になります。

---

## 7. 色を追加・削除する状態遷移

状態変数 `picked` は、現在選ばれている色の集合です。初期状態は空集合です。

```tla
Init == picked = {}
```

`AddColor` は未選択の色を 1 つ加え、`RemoveColor` は選択済みの色を 1 つ除きます。

```tla
picked' = picked \union {color}
picked' = picked \ {color}
```

どの色を追加または削除するかは `\E` で非決定的に選ばれます。そのため TLC は、3 色のすべての部分集合に当たる
8 状態を探索します。

```text
                         {red, green, blue}
                        /        |        \
              {red, green}  {red, blue}  {green, blue}
                 /    \        /    \        /    \
              {red}          {green}          {blue}
                 \              |              /
                              {}
```

図は集合の包含関係を簡略化したものです。実際の `Next` では、要素を 1 個追加する遷移と 1 個削除する遷移の
両方向があります。

`TypeOK` は、どの到達状態でも `picked` に未知の色が混入しないことを表します。

```tla
TypeOK == picked \subseteq Colors
```

`AlwaysSmall` は同じ安全性を要素数の観点から補助的に検査します。ただし、要素数だけでは未知の色の混入を防げないため、
`TypeOK` の代わりにはなりません。

---

## 8. TLC で実行する

`Sets.tla` を開いて `Cmd + Shift + P` → **`TLA+: Check model with TLC`** を実行します。
同じディレクトリの [Sets.cfg](Sets.cfg) が設定ファイルです。

CLI なら次のコマンドです。

```bash
cd examples/06-sets
java -cp "$(ls -d ~/.vscode/extensions/tlaplus.vscode-ide-*/tools/tla2tools.jar | tail -1)" \
  tlc2.TLC -workers 1 -config Sets.cfg Sets.tla
```

設定ファイルでは、3 つの不変条件を到達可能な全状態で検査します。

```cfg
INIT Init
NEXT Next

INVARIANT TypeOK
INVARIANT AlwaysSmall
INVARIANT SetExamplesOK
```

正常なら `Model checking completed. No error has been found.` と表示され、終了コード `0` になります。
このモデルでは 8 個の異なる状態が見つかります。

---

## 9. 触って確かめる

- `Colors` に `"yellow"` を追加する。到達状態数が 8 から 16 に増えることを確認できます。
- `AddColor` の `color \notin picked` を削る。同じ色を追加しても集合は変わらないため、自己ループが加わります。
- `AddColor` の `{color}` を `Colors` に変える。空集合から一度ですべての色を選ぶ遷移になります。
- `RemoveColor` の `picked \ {color}` を `{}` に変える。どの状態からも全色を一度に解除するモデルになります。
- `TypeOK` を `picked \subseteq Colors \union {"yellow"}` に緩める。状態遷移が `"yellow"` を生成しない限り、
  到達状態数は変化しません。
- `LargeNumbers` の条件を `number % 2 = 0` に変え、期待値を `{2, 4, 6, 8, 10}` に合わせます。
- `Doubled` を `{number % 2 : number \in 1..4}` に変える。重複が消えて結果が `{0, 1}` になることを確認できます。

---

## 次に読むもの

- learning.tlapl.us の次ページは [Functions](https://learning.tlapl.us/intro/functions/) です。
- [examples/05-basic-operators](../05-basic-operators) — 論理演算子、アクション、`UNCHANGED`、条件式
- [examples/04-variables-constants](../04-variables-constants) — 変数、定数、`TypeOK`
