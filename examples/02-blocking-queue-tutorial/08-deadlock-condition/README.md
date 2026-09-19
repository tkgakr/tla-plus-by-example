# デッドロック条件 — 表から不等式へ

出典: [learning.tlapl.us / BlockingQueue Tutorial / Deadlock Inequation](https://learning.tlapl.us/blocking-queue/inequation/)

06 章で構成を変数にし、07 章で対称性を宣言して、「どの構成がデッドロックするか」の表が手に入りました。
表を眺めて立てた予想はこうでした。

> producer 数 + consumer 数 <= 2 × 容量 なら違反が出ない

この章では、この予想を**式として書き下し、TLC に検査させます**。上流教材の言い方では、
元の（待機集合が 1 つの）アルゴリズムがデッドロックしないのは

```text
2 * BufCapacity >= Cardinality(Producers \cup Consumers)
```

が成り立つとき、かつそのときに限る、という主張です。予想を眺めるのと、検査可能な形にして
TLC に当てるのとでは、分かることの強さが違います。

前のページ: [examples/02-blocking-queue-tutorial/07-symmetry](../07-symmetry)（対称性集合）

---

## 1. 予想を式にする

仕様本体（`Init`、`Next`、`Put`、`Get`、`Wait`、`Notify`）は 06 章から一行も変えていません。
足すのは性質の定義だけです。

```tla
Threads ==
    producers \cup consumers

Deadlock ==
    waitSet = Threads

NoDeadlock ==
    ~Deadlock

Inequation ==
    2 * bufCapacity >= Cardinality(Threads)
```

大文字の `Producers` ではなく小文字の `producers` を使っている点に注意してください。06 章以降、
構成は変数なので、不等式も**その振る舞いが選んだ構成**について述べています。

このディレクトリのファイルは次のとおりです。

| ファイル | 役割 |
| --- | --- |
| [BlockingQueue.tla](BlockingQueue.tla) | 07 章の仕様に `Inequation` と検査用の性質を足したもの |
| [BlockingQueue.cfg](BlockingQueue.cfg) | 主張の検査。producer 4 / consumer 3 / 容量 3 |
| [BlockingQueueOffByOne.cfg](BlockingQueueOffByOne.cfg) | 境界確認。わざと 1 ずらした不等式を検査する |
| [BlockingQueueLog.cfg](BlockingQueueLog.cfg) | 逆向きの調査。デッドロックした構成を印字する |
| [BlockingQueueLarge.cfg](BlockingQueueLarge.cfg) | 一般化の確認。producer 5 / consumer 4 / 容量 4 |
| [BlockingQueueLargeLog.cfg](BlockingQueueLargeLog.cfg) | 大きい上限で構成を印字する |

---

## 2. 不変条件で書ける向きと、書けない向き

「かつそのときに限る」は 2 つの主張の合成です。この 2 つは、TLC での扱いがまったく違います。

| 向き | 主張 | TLC での扱い |
| --- | --- | --- |
| A | 不等式が成り立つ ⇒ デッドロックしない | **不変条件として書ける** |
| B | 不等式が成り立たない ⇒ デッドロックに到達できる | 不変条件では書けない |

向き A は「すべての到達可能状態について〜が成り立つ」という形なので、そのまま不変条件になります。

```tla
DeadlockFreeIfInequation ==
    Inequation => NoDeadlock
```

向き B は「〜という状態に**到達できる**」という存在の主張です。不変条件はすべての状態について
成り立つことを言う道具なので、存在を直接は表現できません。3 節で A を検査し、5 節で B を
別の方法（印字と集計）で調べます。**この非対称性が、この章でいちばん持ち帰る価値のある話です。**

---

## 3. 向き A を検査する

```bash
cd examples/02-blocking-queue-tutorial/08-deadlock-condition
java -cp "$(ls -d ~/.vscode/extensions/tlaplus.vscode-ide-*/tools/tla2tools.jar | tail -1)" \
  tlc2.TLC -workers 1 -config BlockingQueue.cfg BlockingQueue.tla
```

```text
Finished computing initial states: 315 states generated, with 36 of them distinct
Model checking completed. No error has been found.
8955 states generated, 1647 distinct states found, 0 states left on queue.
The depth of the complete state graph search is 47.
```

`0 states left on queue` と `No error has been found` の組み合わせが読みどころです。TLC は
36 通りの構成すべて、1,647 状態すべてを最後まで調べたうえで、`Inequation => NoDeadlock` を
一度も破らなかったと言っています。07 章で `-continue` を付けてやっと得た全探索が、ここでは
違反が起きないので自然に最後まで走りきります。

これで、**この上限のもとでは向き A は確かめられました**。「2 × 容量 以上のスレッドがいない構成なら
デッドロックしない」は、少なくとも producer 4 人・consumer 3 人・容量 3 までは真です。

---

## 4. 境界がどこにあるかを TLC に確かめさせる

不等式を書いたとき、本当に確かめたいのは「右辺と左辺の関係が合っているか」だけでなく、
**境界が 1 つずれていないか**です。予想が `<=` なのか `<` なのかを取り違えるのは、この種の作業で
いちばん起きやすい誤りです。

そこで、わざと 1 だけ緩めた版を用意してあります。

```tla
InequationOffByOne ==
    2 * bufCapacity >= Cardinality(Threads) - 1

DeadlockFreeIfOffByOne ==
    InequationOffByOne => NoDeadlock
```

```bash
java -cp "$(ls -d ~/.vscode/extensions/tlaplus.vscode-ide-*/tools/tla2tools.jar | tail -1)" \
  tlc2.TLC -workers 1 -config BlockingQueueOffByOne.cfg BlockingQueue.tla
```

```text
Error: Invariant DeadlockFreeIfOffByOne is violated.
State 1: <Initial predicate>
/\ producers = {p1}
/\ buffer = <<>>
/\ waitSet = {}
/\ bufCapacity = 1
/\ consumers = {c1, c2}
...
State 8:
/\ producers = {p1}
/\ buffer = <<>>
/\ waitSet = {p1, c1, c2}
/\ bufCapacity = 1
/\ consumers = {c1, c2}
```

返ってきたのは、02〜07 章でおなじみの **p1c2b1 の 8 状態**です。この構成は容量 1・スレッド 3 人なので
`2 * 1 = 2` と `3 - 1 = 2` が等しく、緩めた不等式は成り立ってしまいます。それでもデッドロックする。
つまり境界は緩めた側ではなく、元の `2 * bufCapacity >= Cardinality(Threads)` の側にあります。

**予想を書いたら、わざと 1 ずらした版も検査する。**これで、たまたま通っただけの式を見分けられます。

---

## 5. 向き B を調べる — デッドロックした構成を印字して集計する

向き B は不変条件で書けないので、上流教材と同じ手を使います。デッドロック状態に出会うたびに
**その構成を印字**させ、`-continue` で最後まで走らせ、印字された組を集計します。

```tla
LogDeadlock ==
    \/ NoDeadlock
    \/ /\ PrintT(<<"InvVio", bufCapacity, Cardinality(Threads)>>)
       /\ FALSE
```

`PrintT` は `TLC` モジュールの演算子で、値を印字して `TRUE` を返します。デッドロック状態では
第 1 選言が偽になるので第 2 選言が評価され、構成が印字されたうえで `/\ FALSE` により違反として
報告されます。**印字を副作用として使い、違反報告を「記録装置」に変えている**わけです。

```bash
java -cp "$(ls -d ~/.vscode/extensions/tlaplus.vscode-ide-*/tools/tla2tools.jar | tail -1)" \
  tlc2.TLC -workers 1 -continue -config BlockingQueueLog.cfg BlockingQueue.tla \
  | grep InvVio | sort | uniq -c
```

```text
   2 <<"InvVio", 1, 3>>
   4 <<"InvVio", 1, 4>>
   5 <<"InvVio", 1, 5>>
   4 <<"InvVio", 1, 6>>
   2 <<"InvVio", 1, 7>>
   5 <<"InvVio", 2, 5>>
   5 <<"InvVio", 2, 6>>
   3 <<"InvVio", 2, 7>>
   5 <<"InvVio", 3, 7>>
```

左の数（何回報告されたか）には意味がありません。読むのは**どの組が現れたか**です。
容量を縦、スレッド総数を横に置き直すと次のようになります（`X` がデッドロックあり）。

| | スレッド 2 | 3 | 4 | 5 | 6 | 7 |
| --- | :---: | :---: | :---: | :---: | :---: | :---: |
| `bufCapacity = 1` | . | X | X | X | X | X |
| `bufCapacity = 2` | . | . | . | X | X | X |
| `bufCapacity = 3` | . | . | . | . | . | X |

各行で `X` が始まるのは、スレッド総数が `2 * bufCapacity` を**超えた**ところです。
`2 * bufCapacity < Cardinality(Threads)` が成り立つ 9 組すべてが現れ、成り立たない 9 組は
1 つも現れていません。3 節の結果（向き A）と合わせて、**この上限のもとでは「かつそのときに限る」が
確かめられました**。

06 章の表は producer 数と consumer 数を別々の軸に取った 12 行 × 3 列でした。18 個あった違反構成が、
ここでは 9 組に減っています。**producer と consumer の内訳は効かず、合計だけが効く**ことが、
表の形が変わったことで見えます。p1c2b1 と p2c1b1 が同じ `<<"InvVio", 1, 3>>` に落ちるのは
そのためです。

---

## 6. 一回り大きい上限で試す

ここまでの結論は、producer 4 人・consumer 3 人・容量 3 という上限の内側の話です。予想が上限の
選び方に引きずられていないかを見るため、[BlockingQueueLarge.cfg](BlockingQueueLarge.cfg)
（producer 5 / consumer 4 / 容量 4、構成の形は 5 × 4 × 4 = 80 通り）で同じ 2 つを検査します。

```bash
java -cp "$(ls -d ~/.vscode/extensions/tlaplus.vscode-ide-*/tools/tla2tools.jar | tail -1)" \
  tlc2.TLC -workers 1 -config BlockingQueueLarge.cfg BlockingQueue.tla

java -cp "$(ls -d ~/.vscode/extensions/tlaplus.vscode-ide-*/tools/tla2tools.jar | tail -1)" \
  tlc2.TLC -workers 1 -continue -config BlockingQueueLargeLog.cfg BlockingQueue.tla \
  | grep -o 'InvVio", [0-9]*, [0-9]*' | sort -u
```

| 上限 | 初期状態（異なる） | 生成状態数 | 異なる状態数 | 深さ | 向き A | 実行時間 |
| --- | ---: | ---: | ---: | ---: | --- | ---: |
| p4 / c3 / 容量 3 | 36 | 8,955 | 1,647 | 47 | 違反なし | 1 秒未満 |
| p5 / c4 / 容量 4 | 80 | 87,408 | 10,470 | 78 | 違反なし | 約 23 秒 |

印字された組は 16 通りで、やはり `2 * bufCapacity < スレッド総数` と完全に一致します。

| | スレッド 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
| --- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `bufCapacity = 1` | . | X | X | X | X | X | X | X |
| `bufCapacity = 2` | . | . | . | X | X | X | X | X |
| `bufCapacity = 3` | . | . | . | . | . | X | X | X |
| `bufCapacity = 4` | . | . | . | . | . | . | . | X |

上限を 1 段階広げるだけで、状態数は 1,647 から 10,470 へ、実行時間は 1 秒未満から 23 秒へ増えました。
07 章の `SYMMETRY` がなければこの実行は現実的ではありません（対称性なしの初期状態は
`(2^5 - 1) * (2^4 - 1) * 4 = 1,860` 個です）。**削減の道具を先に用意しておくと、一般化の確認に使える。**
これが 07 章を先に置いた理由です。

---

## 7. なぜそうなるのか — 無駄になる `notify`

上流教材は不等式を経験的な観察として提示し、理由には踏み込みません。ここでは 4 節の 8 状態を読んで、
何が起きているかを言葉にしておきます。構成は容量 1、producer `p1`、consumer `c1` と `c2` です。

| 状態 | 行動 | `buffer` | `waitSet` |
| ---: | --- | --- | --- |
| 1 | 初期状態 | `<<>>` | `{}` |
| 2 | `c1` が Get → 空なので待機 | `<<>>` | `{c1}` |
| 3 | `c2` が Get → 空なので待機 | `<<>>` | `{c1, c2}` |
| 4 | `p1` が Put 成功 → `notify` が `c1` を起こす | `<<p1>>` | `{c2}` |
| 5 | `p1` が Put → 満杯なので待機 | `<<p1>>` | `{p1, c2}` |
| 6 | `c1` が Get 成功 → `notify` が **`c2`** を起こす | `<<>>` | `{p1}` |
| 7 | `c1` が Get → 空なので待機 | `<<>>` | `{p1, c1}` |
| 8 | `c2` が Get → 空なので待機 | `<<>>` | `{p1, c1, c2}` |

急所は状態 6 です。`c1` がバッファを空にしたので、いま起こすべきなのは**満杯で待っている `p1`** です。
ところが待機集合は 1 つしかなく、`Notify` は

```tla
\E thread \in waitSet : waitSet' = waitSet \ {thread}
```

と書かれているため、誰が起きるかは非決定的です。ここで `c2` が起きてしまうと、`c2` は空のバッファを
見て（状態 8 で）また眠ります。**起こす権利を 1 回使ったのに、誰も前に進まない。**これが
「無駄になる `notify`」です。

不等式はこの現象に必要な人数を言っています。バッファの容量が `cap` のとき、満杯で眠れる producer と
空で眠れる consumer を同時に成立させるには、バッファを満杯にし、また空にするだけの働き手が要ります。
スレッドが `2 * cap` 人以下しかいなければ、起こされた側が必ず仕事を見つけてしまい、全員が眠った状態を
作れません。`2 * cap` を超える人数がいて初めて、余った 1 人に「無駄な目覚め」を割り当てられます。

**ただし、これは 8 状態の反例から読み取った説明であって、証明ではありません。**
すべての `cap` と人数について示すには帰納的不変条件と TLAPS が要ります。この章で TLC が言えたのは
「調べた上限の内側では正しい」までです。

なお、原因が「待機集合が 1 つしかないこと」だと分かれば、直し方の候補も見えます。producer 用と
consumer 用に待機集合を分ければ、状態 6 の `notify` は必ず `p1` に届きます。これが 12 章
（論理的に二つの mutex）でやることです。11 章の `notifyAll` は別の直し方で、起こす相手を選ぶ代わりに
全員を起こします。**同じバグに対する異なる修正を比べられる**ようになったのは、この章で条件を
式として掴んだからです。

---

## 8. 何を検査し、何を検査していないか

- **検査した。** producer 5 人・consumer 4 人・容量 4 までのすべての構成について、向き A（不等式が
  成り立てばデッドロックしない）が成り立つ。TLC は全状態を調べ切っている。
- **検査した。** 同じ範囲で、不等式が成り立たない構成のすべてに、実際にデッドロック状態が存在する。
  向き B は印字の集計として確かめた。
- **検査していない。** producer 6 人、容量 5 といった範囲外。上流教材の言うとおり、
  有限のデータ点から関係を推測したにすぎず、すべての個数と容量についての数学的証明ではありません。
- **検査していない。** 向き B を TLC の性質として書いたわけではない。`PrintT` は副作用であり、
  「印字されなかった＝到達不可能」は、全探索が完了している（`0 states left on queue`）ことを
  確認して初めて言えます。`-continue` を忘れると最初の違反で止まり、集計は無意味になります。

この 3 つ目と 4 つ目は、モデル検査の結果を人に伝えるときに省かれがちな部分です。
「デッドロックしない条件が分かった」ではなく「この範囲ではこの条件と一致した」と書けることが、
この章の到達点です。

---

## 9. 触って確かめる

1. `Inequation` を `2 * bufCapacity > Cardinality(Threads)` に変えて実行する。違反は出るか。
   出ないとしたら、その式は元の主張より強いのか弱いのか、どちらとして正しくないのかを説明する。
2. `LogDeadlock` の `/\ FALSE` を外して実行し、何が起きるか確かめる。印字はされるか、
   違反は報告されるか、`-continue` の意味はどうなるか。
3. `BlockingQueueLog.cfg` から `SYMMETRY` を外して同じ集計をし、印字された**組**が変わらないことを
   確認する（報告回数だけが増えるはず）。07 章の「結論は変わらない」がここでも成り立つ理由を書く。
4. `LogDeadlock` の印字内容に `Len(buffer)` を足し、デッドロック状態のバッファ長を集計する。
   ほとんどの組では `0`（空）と容量そのもの（満杯）の両方が現れる。7 節の表の状態 8 と見比べて、
   どちらが「最後に眠ったのが producer か consumer か」に対応するかを説明する。そのうえで、
   容量 3・スレッド 7 人の組だけは片方しか現れない。どちらが現れないか、そしてその理由を、
   producer 4 人・consumer 3 人という内訳から説明する。
5. `BufCapacity = 5`、`Producers` を 6 個に増やして向き A だけを検査し、実行時間を記録する。
   6 節の表（36 → 80 で 1 秒未満 → 23 秒）から所要時間を予想してから走らせる。
6. 7 節の説明を、`waitSet` の大きさと `Len(buffer)` を使った帰納的不変条件の候補として書いてみる。
   TLC で検査し、初期状態で成り立つか、`Next` で保たれるかを確かめる（これが TLAPS への入口です）。

---

## 次に読むもの

- [`VIEW` による抽象化](../09-view) — 性質に不要なバッファ内容を捨てて状態を減らす（[上流ページ](https://learning.tlapl.us/blocking-queue/view/)）
- [対称性集合](../07-symmetry) — 6 節の実行を可能にしている削減
- [定数から変数へ](../06-variables) — 5 節で不等式にまとめた元の表

## 参考資料

- [BlockingQueue Tutorial / Deadlock Inequation](https://learning.tlapl.us/blocking-queue/inequation/)
- [TLC Model Checker](https://docs.tlapl.us/using:tlc:start) — `-continue`、`PrintT` による調査
- [TLAPS](https://proofs.tlapl.us/) — 有限の検査を全事例の証明に変えたくなったときの行き先
- [lemmy/BlockingQueue の対応リビジョン](https://github.com/lemmy/BlockingQueue) — MIT License（[ライセンス表示](LICENSE.upstream)）
