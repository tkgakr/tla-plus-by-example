# はじめに — プラットフォームの使い方（ローカル版）

出典: [learning.tlapl.us / Introduction / The Platform](https://learning.tlapl.us/intro/platform/)
本家はブラウザ上の Playground で TLC を実行しますが、ここではその内容を **このリポジトリ + ローカルの TLC** で
そのまま追体験できるように再構成しています。

---

## 1. 本家の Playground と、このリポジトリの対応

本家サイトの画面は右側にエディタ、下側に出力パネルという構成です。ローカルでは次のように読み替えます。

| 本家 Playground | このリポジトリ |
| --- | --- |
| `Spec.tla` タブ | [DieHard.tla](DieHard.tla) |
| `Spec.cfg` タブ | [DieHard.cfg](DieHard.cfg) |
| `▶ Run TLC` ボタン | `DieHard.tla` を開いて `Cmd + Shift + P` → `TLA+: Check model with TLC` |
| 下部の出力パネル | VS Code の TLA+ 検査結果ビュー |

ブラウザ版と違い、仕様はどこにもアップロードされず、手元の JVM だけで完結します。

---

## 2. TLA+ とは

TLA+ は Leslie Lamport が作った**形式仕様記述言語**です。並行システムや分散システムを設計・モデル化・検証するために使われ、
Amazon・Microsoft・Intel といった企業が、本番投入前に重要システムの不具合を洗い出す目的で採用しています。

ひとつの仕様は、だいたい次の 4 つで構成されます。

- **変数（variables）** — システムの状態を表すもの
- **初期状態（initial state）** — 開始時に成り立っている条件
- **次状態関係（next-state relation）** — 状態がどう遷移しうるか
- **不変条件（invariants）** — 常に成り立っていてほしい性質

`DieHard.tla` で言えば、`small` / `big` が変数、`Init` が初期状態、`Next` が次状態関係、
`TypeOK` と `NotSolved` が不変条件です。

---

## 3. TLC とは

TLC は TLA+ の**モデル検査器**です。初期状態から出発して、到達可能な状態を**すべて**列挙し、
各状態で不変条件が成り立つかを確認します。破れた場合は、そこに至るまでの手順（**反例トレース**）を提示します。

ランダムテストと違い網羅的なので、「たまたま踏まれなかったバグ」が残りません。

---

## 4. DieHard の例

映画『ダイ・ハード3』の水差しパズルです。5 ガロンと 3 ガロンの容器だけを使って、ちょうど 4 ガロンを量ります。

面白いのは解き方で、「**4 ガロンは作れない**」という**わざと嘘の不変条件** `NotSolved == big /= 4` を置きます。
TLC はこれを破る状態を探し当て、その反例トレースがそのまま**解答手順**になります。

```tla
NotSolved ==
    big /= 4
```

### 実行

`DieHard.tla` を開いて `Cmd + Shift + P` → **`TLA+: Check model with TLC`**。
拡張は同じディレクトリの同名 `.cfg`（ここでは `DieHard.cfg`）を自動で設定ファイルとして使います。

初回は「どの設定で動かすか」を聞かれることがありますが、`DieHard.cfg` を選べば以降は記憶されます。

---

## 5. TLC の出力の読み方

以下は、この環境で実際に実行したときの出力です（パス等は環境依存）。

### ヘッダ — バージョンと探索方式

```
TLC2 Version 2026.08.21.155922 (rev: 9787e65)
Running breadth-first search Model-Checking with fp 97 and seed -8255587049881290483
with 1 worker on 8 cores with 7282MB heap and 64MB offheap memory ...
```

`breadth-first search`（幅優先探索）である点が重要です。これにより、報告される反例は**最短経路**になります。
DieHard なら「最小手数の解答」が得られる、ということです。

### パース — モジュールの読み込みと検証

```
Parsing file .../examples/01-diehard/DieHard.tla
Parsing file .../Naturals.tla (jar:...!/tla2sany/StandardModules/Naturals.tla)
Semantic processing of module Naturals
Semantic processing of module DieHard
```

`EXTENDS` した標準モジュール（ここでは `Naturals`）も一緒に読み込まれ、構文・意味の両面で検査されます。
ここでエラーが出る場合は、まだモデル検査に入っていません。単なる書き間違いです。

### 初期状態の計算

```
Computing initial states...
Finished computing initial states: 1 distinct state generated
```

`Init` から生成される状態の数です。DieHard の `Init` は `small = 0 /\ big = 0` を一意に定めるので 1 個。
`Init` に選択肢を書けばここが複数になります。

### 不変条件の違反

```
Error: Invariant NotSolved is violated.
Error: The behavior up to this point is:
```

宣言した性質を破る状態が見つかった、という報告です。今回はそれが目的なので、これが「正解」です。

### 反例トレース

各状態は「**実行されたアクション名 + 定義位置**」と「**その結果の変数の値**」で表示されます。

```
State 1: <Initial predicate>
/\ big = 0
/\ small = 0

State 2: <FillBig line 27, col 5 to line 28, col 21 of module DieHard>
/\ big = 5
/\ small = 0

State 3: <BigToSmall line 43, col 5 to line 44, col 38 of module DieHard>
/\ big = 2
/\ small = 3

State 4: <EmptySmall line 31, col 5 to line 32, col 19 of module DieHard>
/\ big = 2
/\ small = 0

State 5: <BigToSmall line 43, col 5 to line 44, col 38 of module DieHard>
/\ big = 0
/\ small = 2

State 6: <FillBig line 27, col 5 to line 28, col 21 of module DieHard>
/\ big = 5
/\ small = 2

State 7: <BigToSmall line 43, col 5 to line 44, col 38 of module DieHard>
/\ big = 4
/\ small = 3
```

日本語で読み下すと、6 手で 4 ガロンが得られます。

1. 5 ガロン容器を満タンにする → (small 0, big 5)
2. 5 → 3 に注ぐ → (3, 2)
3. 3 ガロン容器を空にする → (0, 2)
4. 5 → 3 に注ぐ → (2, 0)
5. 5 ガロン容器を満タンにする → (2, 5)
6. 5 → 3 に注ぐ（3 ガロン容器は残り 1 しか入らない）→ (3, **4**)

### 統計と終了

```
73 states generated, 14 distinct states found, 1 states left on queue.
The depth of the complete state graph search is 7.
```

### 終了コード

| 状況 | プロセス終了コード | `-tool` モードのメッセージコード |
| --- | --- | --- |
| 不変条件の違反あり | `12` | `2110`（`@!@!@STARTMSG 2110:1 @!@!@`） |
| すべて検査して問題なし | `0` | — |

本家サイトが挙げている **2110** は、TLC を `-tool` オプション付きで動かしたときに出力される
**メッセージコード**（「Invariant violated」を表す番号）です。VS Code 拡張やブラウザ版はこの `-tool` 形式を
パースして画面に整形しているので、そちらでは 2110 が見えます。
一方、CLI から `java -cp tla2tools.jar tlc2.TLC ...` を素で実行した場合、シェルから見える `$?` は **12** です。
どちらも同じ事象を指しています。

---

## 6. 解けたことを確かめる（違反を消す）

`DieHard.cfg` の `INVARIANT NotSolved` の行を、行頭に `\*` を付けてコメントアウトします
（`.tla` と同じく `.cfg` でも `\*` が行コメントです）。

```
SPECIFICATION Spec

INVARIANT TypeOK
\* INVARIANT NotSolved

CHECK_DEADLOCK FALSE
```

再実行すると、今度は違反なしで全状態を検査し切ります。

```
Model checking completed. No error has been found.
97 states generated, 16 distinct states found, 0 states left on queue.
The depth of the complete state graph search is 8.
```

到達可能な状態は全部で 16 個しかないので、TLC は文字通り「すべて」を確認しています。

`NotSolved` を外した状態の `TypeOK` だけの検査は、「どの手順を踏んでも容器の中身が容量を超えない」ことの証明になります。

---

## 7. ローカル開発環境

本家ページ末尾の「Local Development」に相当します。

- **VS Code TLA+ 拡張** — `tlaplus.vscode-ide`。構文ハイライト、`TLA+: Check model with TLC`、
  反例トレースのビューアが付きます。このリポジトリの [.vscode/settings.json](../../.vscode/settings.json) では
  `-workers 1 -coverage 1` を既定にしています。
- **CLI（任意）** — CI で回したいなど、VS Code を開かずに実行したい場合のみ。拡張に同梱の
  `tla2tools.jar` をそのまま使えます。

  ```bash
  cd examples/01-diehard && java -cp "$(ls -d ~/.vscode/extensions/tlaplus.vscode-ide-*/tools/tla2tools.jar | tail -1)" tlc2.TLC -workers 1 -config DieHard.cfg DieHard.tla
  ```

  単体で欲しい場合は [tlaplus/tlaplus のリリース](https://github.com/tlaplus/tlaplus/releases)から取得してください。
- **Java** — TLC は JVM 上で動きます。この環境では Temurin 25 で確認済みです。

---

## 次に読むもの

- [examples/00-hello](../00-hello) — 変数ひとつだけの最小の仕様（`Init` / `Next` / `Spec` / `TypeOK` の型紙）
