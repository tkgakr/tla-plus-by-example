# BlockingQueue 導入 — 実装からモデルへ

出典: [learning.tlapl.us / BlockingQueue Tutorial / Introduction](https://learning.tlapl.us/blocking-queue/introduction/)

Markus Kuppe の [BlockingQueue チュートリアル](https://github.com/lemmy/BlockingQueue)をもとに、
producer と consumer が共有する有界バッファを、このリポジトリで実行できる日本語教材として再構成します。
この章では、実装を TLA+ に翻訳するときに**何を状態として残し、何を捨てるか**を決めます。

前のコース: [examples/01-how-to-write-tla-plus/10-tlc-config](../../01-how-to-write-tla-plus/10-tlc-config)

---

## 1. このモデルで明らかにしたい問い

扱うのは、複数のスレッドが共有する容量つきキューです。

- producer はキューにデータを追加する
- consumer はキューの先頭からデータを取り出す
- キューが満杯なら producer は待つ
- キューが空なら consumer は待つ
- 追加または取り出しの後、待機中のスレッドを 1 つ通知する

実装では producer と consumer が同じ待機集合を使います。`notify` が起こす相手を選べないときでも、
この設計は停止しないでしょうか。これがチュートリアル全体で調べる問いです。

ただし、最初から答えを探しにはいきません。まず producer 1、consumer 1、容量 1 の最小構成
**p1c1b1** が表す状態と遷移を確認します。

---

## 2. 現実の実装から何を残すか

Java 実装は配列をリングバッファとして使い、`synchronized`、`wait()`、`notify()` でスレッドを協調させます。
C 実装も mutex と 1 個の condition variable で同じ構造を表します。今回の検証目的には、配列の添字や
メモリ配置そのものは重要ではありません。

| 実装上の要素 | モデルでの表現 | 判断 |
| --- | --- | --- |
| リングバッファ、`head`、`tail`、`size` | シーケンス `buffer` | 順序と要素数だけを残す |
| `wait()` したスレッド | 集合 `waitSet` | 誰が停止中かを残す |
| 実行可能なスレッド | `(Producers \cup Consumers) \ waitSet` | `RunningThreads` として導出する |
| `notify()` が選ぶ 1 スレッド | `waitSet` から非決定的に 1 要素を除く | 実装が選択を保証しないことを残す |
| Java モニター / C の mutex | 1 回の TLA+ アクション | キュー操作が排他的であることだけを残す |
| 配列の添字、ログ、乱数による待ち時間 | なし | 今回の問いに不要なので捨てる |

「実装を短く書き直す」のではなく、「調べたい設計判断に必要な状態だけを選ぶ」のがモデル化です。

---

## 3. 状態を表す 2 つの変数

[BlockingQueue.tla](BlockingQueue.tla) の状態変数は 2 つだけです。

```tla
VARIABLES buffer, waitSet

vars == <<buffer, waitSet>>
```

- `buffer` は producer ID を要素とするシーケンスです。先頭が次に取り出されます。
- `waitSet` は現在待機している producer / consumer の集合です。

実行中のスレッドは独立した変数にせず、全スレッドから待機中のスレッドを引いて求めます。

```tla
RunningThreads ==
    (Producers \cup Consumers) \ waitSet
```

同じ情報を複数の変数に保存しないため、「`waitSet` と実行中集合が食い違う」というモデル固有のバグを避けられます。

---

## 4. 実装の操作をアクションへ写す

### 待機と通知

`Wait(thread)` はスレッドを待機集合へ追加し、バッファを変更しません。

```tla
Wait(thread) ==
    /\ waitSet' = waitSet \cup {thread}
    /\ UNCHANGED buffer
```

`Notify` は待機集合が空でなければ 1 スレッドを選んで取り除きます。ここで `\E` を使うのは、どのスレッドが
起こされるかをモデルが決め打ちしないためです。

```tla
Notify ==
    IF waitSet # {}
    THEN \E thread \in waitSet : waitSet' = waitSet \ {thread}
    ELSE UNCHANGED waitSet
```

### 追加と取り出し

`Put` には 2 通りの遷移があります。空きがあれば末尾にデータを加えて 1 スレッドを通知し、満杯なら自分が待ちます。

```tla
Put(thread, data) ==
    \/ /\ Len(buffer) < BufCapacity
       /\ buffer' = Append(buffer, data)
       /\ Notify
    \/ /\ Len(buffer) = BufCapacity
       /\ Wait(thread)
```

`Get` も同様です。要素があれば先頭を除いて通知し、空なら自分が待ちます。

```tla
Get(thread) ==
    \/ /\ buffer # <<>>
       /\ buffer' = Tail(buffer)
       /\ Notify
    \/ /\ buffer = <<>>
       /\ Wait(thread)
```

ここでは通知されたスレッドが次に必ず実行されるとは仮定していません。`Next` は、その時点で実行可能なスレッドを
1 つ選び、producer なら `Put`、consumer なら `Get` を実行します。

---

## 5. 初期状態と、最低限の安全性

初期状態ではバッファも待機集合も空です。

```tla
Init ==
    /\ buffer = <<>>
    /\ waitSet = {}
```

この章では、モデルの形が崩れていないことを 2 つの不変条件で検査します。

```tla
TypeOK ==
    /\ buffer \in Seq(Producers)
    /\ waitSet \subseteq (Producers \cup Consumers)

CapacityOK ==
    Len(buffer) <= BufCapacity
```

`TypeOK` は変数の取りうる範囲、`CapacityOK` はバッファが設定容量を超えないことを表します。
チュートリアルの中心となる「全スレッドが待機してしまわないか」は、後の章で別の安全性として導入します。

---

## 6. 最小構成を TLC で検査する

[BlockingQueue.cfg](BlockingQueue.cfg) は **p1c1b1** を指定します。名前は順に producer 数、consumer 数、
buffer capacity を表します。

```cfg
CONSTANTS
    BufCapacity = 1
    Producers = {p1}
    Consumers = {c1}

INIT Init
NEXT Next

INVARIANT TypeOK
INVARIANT CapacityOK

CHECK_DEADLOCK TRUE
```

VS Code では `BlockingQueue.tla` を開き、`Cmd + Shift + P` → **`TLA+: Check model with TLC`** を実行します。
CLI なら次のコマンドです。

```bash
cd examples/02-blocking-queue-tutorial/01-introduction
java -cp "$(ls -d ~/.vscode/extensions/tlaplus.vscode-ide-*/tools/tla2tools.jar | tail -1)" \
  tlc2.TLC -workers 1 -config BlockingQueue.cfg BlockingQueue.tla
```

この最小構成はデッドロックせず、2 つの不変条件も成立します。しかし、これはより大きな構成も安全だという証明では
ありません。producer または consumer が 1 人しかいないため、「同じ種類のスレッドを誤って通知する」という
選択肢がほとんど現れないからです。

この環境で `-workers 1` を指定して実行した結果は次のとおりです。

```text
Model checking completed. No error has been found.
7 states generated, 4 distinct states found, 0 states left on queue.
The depth of the complete state graph search is 3.
```

`states generated` は遷移先として生成した状態の延べ数、`distinct states found` は重複を除いた到達可能状態数です。
この 4 状態を図として読むのが次章の題材です。

---

## 7. 元の実装を動かす（任意）

上流の現行版には後の修正が含まれるため、導入時点を再現するには履歴上のリビジョンを使います。

```bash
git clone https://github.com/lemmy/BlockingQueue.git
cd BlockingQueue
git switch --detach cc8acf5c8c47eccb6064941937567353b414ddc4
mkdir -p build/classes
javac -d build/classes impl/src/org/kuppe/*.java
java -cp build/classes org.kuppe.App
```

既定値は **p4c3b3** です。プログラムは終了せず、実行順によってデッドロックする可能性があります。
停止するときは `Ctrl+C` を押します。

C 版は同じ checkout で次のように実行します。

```bash
cd impl
make
./producer_consumer 3 4 3
```

C 版の引数順は `buffer capacity`、`producer 数`、`consumer 数` です。こちらも `Ctrl+C` で停止します。

---

## 8. 触って確かめる

1. 実行前に、`buffer` と `waitSet` の組み合わせを紙に書き、到達可能な状態を予想する。
2. 比較用の [BlockingQueueTwoConsumers.cfg](BlockingQueueTwoConsumers.cfg) で **p1c2b1** を検査する。
   どのスレッドが最後に動き、誰が待っているかを TLC の反例から日本語で説明する。
3. `Notify` が常に producer を優先するよう変更したら何が起きるか、コードを変える前に予想する。
4. `CapacityOK` の `<=` を `<` に変え、最初の違反までのトレースをキュー上の出来事として読み下す。

2 の変更では、この章の「最小構成では問題なし」という結果が一般化できないことが分かります。原因と修正は後の章で
段階的に扱うため、ここでは反例を消すより、まず各状態を正確に読むことを優先してください。

```bash
java -cp "$(ls -d ~/.vscode/extensions/tlaplus.vscode-ide-*/tools/tla2tools.jar | tail -1)" \
  tlc2.TLC -workers 1 -config BlockingQueueTwoConsumers.cfg BlockingQueue.tla
```

この比較設定では、TLC が深さ 8 でデッドロックを見つけます。反例は次の出来事として読めます。

1. 空のため `c1` と `c2` が順に待つ。
2. `p1` が 1 個追加し、`c1` だけを起こす。
3. 満杯のため `p1` が待つ。
4. `c1` が 1 個取り出すが、通知相手として consumer の `c2` だけを起こす。
5. 空のため `c1` と `c2` が再び待つ。
6. `p1` も待ったままなので、実行可能なスレッドがなくなる。

```text
Error: Deadlock reached.
27 states generated, 14 distinct states found, 0 states left on queue.
The depth of the complete state graph search is 8.
```

不変条件 `TypeOK` と `CapacityOK` は最後まで破れていません。型と容量が正しくてもシステム全体は停止しうるため、
検証したい問いに対応する性質を別に書く必要があります。

---

## 次に読むもの

- [最小構成の状態グラフ](../02-state-graph) — 最小構成の全状態グラフを生成し、状態と辺を読む
- [TLC の設定ファイル](../../01-how-to-write-tla-plus/10-tlc-config) — `INIT`、`NEXT`、`INVARIANT` の復習

## 参考資料

- [BlockingQueue Tutorial / Introduction](https://learning.tlapl.us/blocking-queue/introduction/)
- [lemmy/BlockingQueue の対応リビジョン](https://github.com/lemmy/BlockingQueue/commit/cc8acf5c8c47eccb6064941937567353b414ddc4) — MIT License（[ライセンス表示](LICENSE.upstream)）
- [An Example of Debugging Java with a Model Checker](http://www.cs.unh.edu/~charpov/programming-tlabuffer.html)
