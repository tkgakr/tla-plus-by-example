# TLC の設定ファイル

出典: [learning.tlapl.us / Introduction / TLC Configuration](https://learning.tlapl.us/intro/tlc-config/)

本家ページの要点を、作業者を 1 人ずつ稼働させる小さなモデルとともに、このリポジトリで実行できる
日本語教材として再構成しています。`.cfg` に記述する `INIT`、`NEXT`、`INVARIANT`、`CONSTANT`、
`PROPERTY`、`SYMMETRY`、`CHECK_DEADLOCK` を扱います。

前のページ: [examples/09-records](../09-records)（レコード）

---

## 1. `.tla` と `.cfg` の役割を分ける

[WorkerPool.tla](WorkerPool.tla) は、状態や遷移、検査したい性質を TLA+ の式として定義します。
[WorkerPool.cfg](WorkerPool.cfg) は、その定義のうち何を初期状態や次状態関係として使い、どの性質を TLC に
検査させるかを指定します。

```text
WorkerPool.tla                 WorkerPool.cfg
---------------------------   -----------------------------
CONSTANTS Size, Procs          CONSTANT Size = 3
Init == ...                    CONSTANT Procs = {p1, p2, p3}
Next == ...                    INIT Init
TypeOK == ...                  NEXT Next
EventuallyAllActive == ...     INVARIANT TypeOK
                               PROPERTY EventuallyAllActive
```

設定ファイルには、原則として式そのものではなく `.tla` 側で定義した名前を指定します。この章では通常の
[WorkerPool.cfg](WorkerPool.cfg) と、対称性を確認する [WorkerPoolSymmetry.cfg](WorkerPoolSymmetry.cfg) を
用意しています。同じ仕様に複数の `.cfg` を用意すれば、仕様を変更せず、定数の値や検査する性質が異なる
モデルを実行できます。

---

## 2. `INIT` と `NEXT` — 状態機械の入口と遷移

最も基本的な設定は、初期状態述語と次状態関係の指定です。

```cfg
INIT Init
NEXT Next
```

`INIT Init` は、`WorkerPool.tla` の `Init` を初期状態述語として使うという意味です。このモデルでは、稼働中の
作業者を表す集合 `active` を空集合で初期化します。

```tla
Init ==
    active = {}
```

`NEXT Next` は、`Next` を現在の状態と次の状態の関係として使います。まだ稼働していない作業者を 1 人選ぶ
`Activate` と、全員が稼働した後の自己ループ `Complete` のどちらかです。

```tla
Next ==
    Activate \/ Complete
```

`.tla` に同名の定義を書いただけでは、TLC はどれが初期状態や次状態関係なのかを推測しません。`.cfg` から
明示的に結び付けます。

---

## 3. `INVARIANT` — すべての到達可能状態を検査する

`INVARIANT` には、初期状態と、そこから到達できるすべての状態で常に真であるべき状態述語を指定します。

```cfg
INVARIANT TypeOK
INVARIANT SizeOK
```

このモデルでは、稼働中の作業者が必ず `Procs` の要素であることと、設定した人数を超えないことを検査します。

```tla
TypeOK ==
    active \subseteq Procs

SizeOK ==
    /\ Size = Cardinality(Procs)
    /\ Cardinality(active) <= Size
```

不変条件は複数行指定できます。TLC が偽になる状態を見つけると、どの不変条件が破られたかと、その状態に
到達するまでの反例トレースを報告します。定義を作るだけでは検査されないため、必要な名前を `.cfg` に列挙します。

---

## 4. `CONSTANT` — モデルごとの値を割り当てる

仕様で宣言した定数には、設定ファイルで具体的な値を割り当てます。

```tla
CONSTANTS Size, Procs
```

```cfg
CONSTANT Size = 3
CONSTANT Procs = {p1, p2, p3}
```

`Size` は通常の整数です。`p1`、`p2`、`p3` は、TLA+ の文字列ではなく TLC の**モデル値**です。モデル値は
内部構造を持たない互いに異なる値なので、作業者 ID のように名前以外の性質を使わない対象に向いています。
文字列を使う場合は `{"p1", "p2", "p3"}` のように引用符が必要です。

同じキーワードをまとめて書くこともできます。

```cfg
CONSTANTS Size = 3,
          Procs = {p1, p2, p3}
```

`Size` だけを `2` に変えると `SizeOK` が初期状態から偽になります。人数を変えるときは、`Size` と `Procs` の
要素数を一致させます。

---

## 5. `PROPERTY` — 時間にまたがる性質を検査する

`PROPERTY` は、状態 1 個ではなく、状態が続く**振る舞い**についての時相性質を検査します。このモデルでは、
いつか全作業者が稼働することを指定します。

```tla
AllActive ==
    active = Procs

EventuallyAllActive ==
    WF_vars(Activate) => <>AllActive
```

```cfg
PROPERTY EventuallyAllActive
```

`<>P` は「いつか `P` が成立する」という意味です。これは、各状態だけを調べる `INVARIANT` では表せない
ライブネス性質です。`WF_vars(Activate)` は、`Activate` が実行可能であり続けるなら、いつか実行されるという
弱公平性を表します。したがってこの性質は、「`Activate` が弱公平に選ばれるなら、いつか全員が稼働する」
という含意です。

TLA+ の振る舞いは同じ状態にとどまるステップを許すため、公平性を仮定しない単純な `<>AllActive` では、途中で
永遠に停止する振る舞いが反例になります。弱公平性の仮定の下では、`Activate` が 1 ステップごとに `active` の
要素を必ず増やすため、有限集合 `Procs` の全員がいずれ稼働します。全員が稼働した後は `Complete` が同じ状態へ
遷移し続けます。

---

## 6. `SYMMETRY` — 入れ替え可能な値を同一視する

`p1`、`p2`、`p3` の動作が完全に同じなら、名前を交換した状態を別々に調べる必要はありません。仕様側では、
`Procs` のすべての置換を定義します。

```tla
EXTENDS Naturals, FiniteSets, TLC

Perms ==
    Permutations(Procs)
```

対称性確認用の `WorkerPoolSymmetry.cfg` で、その置換集合を対称性集合として指定します。

```cfg
SYMMETRY Perms
```

対称性を使わない場合、`active` は `Procs` の部分集合なので 8 状態あります。対称性を使うと、「誰が稼働中か」
ではなく「何人が稼働中か」が同じ状態をまとめられ、代表となる 4 状態だけを保持すれば済みます。

対称性は単なる高速化指定ではなく、名前を入れ替えても仕様と検査する性質の意味が変わらない、という主張です。
特定の作業者だけを特別扱いする式がある場合、その作業者をほかと交換する対称性は指定できません。

また、TLC の対称性縮約はライブネス違反を見落とす可能性があるため、`SYMMETRY` と `PROPERTY` を併用すると
警告されます。この教材でも設定を分け、`WorkerPool.cfg` でライブネスを縮約なしに検査し、
`WorkerPoolSymmetry.cfg` では `PROPERTY` を指定せず安全性と状態数だけを検査します。

---

## 7. `CHECK_DEADLOCK` — 後続状態の有無を検査する

TLC は既定で、次の状態が 1 個もない到達可能状態をデッドロックとして報告します。この検査を明示する設定は
次のとおりです。

```cfg
CHECK_DEADLOCK TRUE
```

検査対象から外す場合だけ `FALSE` にします。

```cfg
CHECK_DEADLOCK FALSE
```

このモデルでは、全員が稼働した状態で `Complete` が自己ループするため、デッドロックはありません。
`Complete` を `Next` から削除すると、`active = Procs` で `Activate` の候補がなくなり、TLC がデッドロックを
報告します。

`CHECK_DEADLOCK FALSE` はデッドロックを解消する設定ではなく、報告を抑止するだけです。停止状態が仕様として
正しい場合に限って無効にし、意図せず遷移を書き忘れた可能性があるときは有効なまま原因を調べます。

---

## 8. TLC で実行する

`WorkerPool.tla` を開いて `Cmd + Shift + P` → **`TLA+: Check model with TLC`** を実行します。
同じディレクトリの [WorkerPool.cfg](WorkerPool.cfg) が設定ファイルです。

CLI なら次のコマンドです。

```bash
cd examples/10-tlc-config
java -cp "$(ls -d ~/.vscode/extensions/tlaplus.vscode-ide-*/tools/tla2tools.jar | tail -1)" \
  tlc2.TLC -workers 1 -config WorkerPool.cfg WorkerPool.tla
```

正常なら `Model checking completed. No error has been found.` と表示され、終了コード `0` になります。
通常の設定では 8 個の異なる状態が見つかります。

対称性による縮約だけを確認する場合は、別の設定ファイルを指定します。

```bash
java -cp "$(ls -d ~/.vscode/extensions/tlaplus.vscode-ide-*/tools/tla2tools.jar | tail -1)" \
  tlc2.TLC -workers 1 -config WorkerPoolSymmetry.cfg WorkerPool.tla
```

この設定では TLC が保持する異なる状態が 4 個になります。ライブネス性質は通常の `WorkerPool.cfg` で検査します。

---

## 9. 触って確かめる

- 2 個の `.cfg` の `Size` と `Procs` を 2 人、4 人へ変える。対称性を有効にした設定で保持する状態は、
  それぞれ 3 個、5 個です。
- `Size = 2` のまま `Procs = {p1, p2, p3}` にする。初期状態で `SizeOK` 違反になります。
- `INVARIANT TypeOK` をコメントアウトする。定義が存在するだけでは検査されないことを確認できます。
- `PROPERTY EventuallyAllActive` をコメントアウトする。状態探索は行われますが、時相性質は検査されません。
- `WorkerPoolSymmetry.cfg` の `SYMMETRY Perms` をコメントアウトする。到達可能な 8 状態を保持するようになります。
- `Next` を `Activate` だけにする。全員が稼働した状態でデッドロックが報告されます。
- そのまま `CHECK_DEADLOCK FALSE` にする。報告は消えますが、後続状態がないという仕様の性質は変わりません。
- `EventuallyAllActive` から `WF_vars(Activate) =>` を削る。全員が稼働する前に永遠に停止する振る舞いが、
  `<>AllActive` 違反の反例として得られます。

---

## 次に読むもの

- [examples/09-records](../09-records) — レコード集合を使った `TypeOK` と `.cfg` による不変条件の指定
- [examples/04-variables-constants](../04-variables-constants) — 変数、定数、`CHECK_DEADLOCK`
- [examples/00-hello](../00-hello) — `SPECIFICATION` を使う最小構成
