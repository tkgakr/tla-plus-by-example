# TLA+ by Example — 日本語で手を動かして学ぶ

このリポジトリは、[TLA+ By Example](https://learning.tlapl.us/) の内容を、ローカルで実行できる小さな仕様と
日本語の解説に再構成した学習用リポジトリです。

`How to Write TLA+` の構文入門は完了しました。次の目標は、構文を増やすことではなく、並行システムを
**モデル化し、性質を書き、TLC の反例から設計を直す一連の流れ**を自力で回せるようになることです。

## 現在地

| 章 | 内容 | 教材 |
| --- | --- | --- |
| 0 | 最小の仕様 | [`examples/00-hello`](examples/00-hello) |
| 1 | プラットフォームと TLC | [`examples/01-diehard`](examples/01-diehard) |
| 2 | 状態機械としての TLA+ | [`examples/02-tla-intuition`](examples/02-tla-intuition) |
| 3 | モジュール構造 | [`examples/03-module-structure`](examples/03-module-structure) |
| 4 | 変数と定数 | [`examples/04-variables-constants`](examples/04-variables-constants) |
| 5 | 基本演算子 | [`examples/05-basic-operators`](examples/05-basic-operators) |
| 6 | 集合 | [`examples/06-sets`](examples/06-sets) |
| 7 | 関数 | [`examples/07-functions`](examples/07-functions) |
| 8 | シーケンス | [`examples/08-sequences`](examples/08-sequences) |
| 9 | レコード | [`examples/09-records`](examples/09-records) |
| 10 | TLC の設定 | [`examples/10-tlc-config`](examples/10-tlc-config) |

ここまでで、`Init`、`Next`、不変条件、基本的なデータ構造、定数の割り当て、対称性、簡単な時相性質を
読んで実行できる状態です。一方、実際の設計に使うには、次の力がまだ必要です。

- 実装の詳細を捨て、検証目的に必要な状態だけを選ぶ
- 安全性とライブネスを区別し、適切な性質として記述する
- 反例トレースを原因まで読み下し、モデルまたは設計を修正する
- 状態爆発を観測し、定数、対称性、抽象化を安全に使う
- 高水準仕様と詳細仕様の対応を refinement として考える

## 推奨学習ロードマップ

各フェーズの完了条件を満たしたら、次のフェーズへ進みます。

### Phase 1 — BlockingQueue で検証の一周を経験する

最優先で [BlockingQueue Tutorial](https://learning.tlapl.us/blocking-queue/introduction/) を順番どおりに
日本語再構成します。共有バッファ、producer、consumer、待機集合を持つ一つのモデルを段階的に変更するため、
「仕様を書く → TLC で反例を得る → 原因を説明する → 設計を直す」が連続した物語として学べます。

追加するディレクトリの案は次のとおりです。

| # | テーマ | 身につけること |
| --- | --- | --- |
| 11 | BlockingQueue 導入 | 実装からモデルへ何を残すかを決める |
| 12 | 最小構成の状態グラフ | 状態と遷移をグラフとして読む |
| 13 | 構成を大きくする | 定数変更と状態数の増え方を観測する |
| 14 | 状態グラフのデバッグ | 正しそうなモデル自体を疑う |
| 15 | デッドロックの安全性 | 「全員待機」を不変条件で表す |
| 16 | 定数から変数へ | 一回の探索で複数構成を扱う |
| 17 | 対称性集合 | ID の置換を同一視して状態を減らす |
| 18 | デッドロック条件 | 反例群から成立条件を推測し検査する |
| 19 | `VIEW` による抽象化 | 性質に不要なバッファ内容を捨てる |
| 20 | 非決定的な通知 | 実装が許す選択を漏れなくモデル化する |
| 21 | `notifyAll` | 正しさと効率の異なる修正を比較する |
| 22 | 論理的に二つの mutex | 待機集合を分離して設計を改善する |

このフェーズの完了条件:

- デッドロックに至る反例を、変数値の列ではなく業務上の出来事として説明できる
- 小さいモデルが十分な理由と、構成を大きくして再検査する理由を説明できる
- 対称性や `VIEW` が、どの性質を保存するか確認せずには使えないと理解している
- 「期待する動作」だけでなく、実装が許す非決定的な動作を `Next` に含められる

### Phase 2 — 時相論理、公平性、ライブネスを固める

現在の `WorkerPool` を発展させ、次を一つずつ独立した小例にします。

1. `[]P` と `<>P`、安全性とライブネスの違い
2. stuttering を含む `Spec == Init /\ [][Next]_vars`
3. `ENABLED A` と、アクションが実行可能であることの意味
4. `WF_vars(A)` と `SF_vars(A)` の差
5. 公平性がないために発生するライブネス反例

教材候補は `examples/30-liveness-fairness` とし、同じモデルに「成立する設定」「公平性を外して失敗する設定」
「強公平性が必要になる設定」を用意します。

完了条件は、`<>Done` が直感的に正しそうでも自動的には成立しない理由を、無限の反例を使って説明できることです。

### Phase 3 — 分散プロトコルと refinement を学ぶ

[TLA+ Video Course](https://lamport.azurewebsites.net/video/videos.html) のうち、次を順に扱います。

1. Transaction Commit
2. Two-Phase Commit
3. Paxos Commit
4. Implementation
5. Alternating Bit Protocol
6. Implementation with Refinement

ここでは各仕様を最初から再入力するより、まず既存仕様を読み、次に性質を一つ壊し、最後に小さな変更を加えます。
特に Transaction Commit と Two-Phase Commit の関係を使い、高水準仕様の振る舞いを詳細仕様が実装しているとは
何を意味するのかを学びます。

完了条件:

- プロトコルの状態変数、環境の仮定、安全性、ライブネスを分けて説明できる
- 高水準モデルと詳細モデルの変数を対応付ける refinement mapping を書ける
- 実装の詳細を増やしても、外から観測できる振る舞いが高水準仕様に収まることを検査できる

### Phase 4 — 既存仕様を読み、自分の題材を一つ完成させる

まず [TLA+ Examples](https://github.com/tlaplus/Examples) または
[TLA+ By Example の Community Specifications](https://learning.tlapl.us/#community-specifications) から、
初心者向け仕様を 2 本選びます。おすすめは、有限状態でトレースを追いやすい `DiningPhilosophers` と、
複数プロセスの合意を扱う `Majority` です。

その後、身近なシステムを一つ選んで最終課題にします。題材は「失敗、再試行、並行実行のうち二つ以上がある」
ものが適しています。

- 排他的なジョブ取得と再試行
- 在庫の仮押さえと期限切れ
- リーダーの lease 更新
- メッセージの再送と重複排除
- レート制限付きワーカープール

最終課題の成果物:

```text
examples/50-capstone/
├── README.md          # 目的、抽象化、仮定、検査結果、分かったこと
├── System.tla         # 仕様
├── System.cfg         # 基本モデル
├── SystemSmall.cfg    # 反例を短く得るモデル
└── SystemLarge.cfg    # 状態数の増加を確認するモデル
```

完了条件は、少なくとも `TypeOK`、設計上の安全性 2 個、ライブネス 1 個を定義し、意図的にバグを入れた版の
反例と修正版の検査結果を README で説明できることです。

### Phase 5 — 目的に応じて選ぶ発展課題

以下は全員が直ちに進む必修項目ではありません。最終課題を一つ終えてから、目的に合わせて選びます。

| 目的 | 次の教材 | 位置付け |
| --- | --- | --- |
| 手続き的に並行アルゴリズムを書きたい | [PlusCal Tutorial](https://lamport.azurewebsites.net/tla/tutorial/home.html) | PlusCal から生成された TLA+ も読む |
| 言語と設計原則を体系的に確認したい | [Specifying Systems](https://lamport.azurewebsites.net/tla/book.html) 1〜8 章 | 辞書ではなく例題を実行しながら読む |
| TLC で扱いにくい整数制約を調べたい | [Apalache](https://apalache-mc.org/) | TLC との意味と制約の違いを比較する |
| 検査ではなく数学的に証明したい | [TLAPS](https://proofs.tlapl.us/) と Hyperbook の Proof Track | 不変条件の帰納証明から始める |

## 1 回の学習サイクル

各章は、次の順序で進めます。読むだけ、正常終了させるだけでは完了にしません。

1. **予想する** — 変数、初期状態、遷移、検査したい性質を自然言語で先に書く
2. **最小化する** — プロセス数や値域を、問題が再現する最小値にする
3. **検査する** — TLC の生成状態数、異なる状態数、探索深さ、結果を記録する
4. **壊す** — アクションまたは性質を一つ変更し、短い反例を得る
5. **説明する** — 反例をシステム上の出来事として README に日本語で書く
6. **直す** — 修正前後で性質と状態数がどう変わったか比較する
7. **一般化する** — 定数を一段階大きくし、偶然の成功でないことを再確認する

各 README には、最低限次を残します。

- このモデルで明らかにしたい問い
- 現実の何を残し、何を捨てたか
- 検査する不変条件と時相性質
- 実行コマンドと TLC の主要な結果
- 反例の読み方
- 変更して試す課題

## 実行方法

Java と [TLA+ for Visual Studio Code](https://marketplace.visualstudio.com/items?itemName=alygin.vscode-tlaplus) を
用意し、対象の `.tla` を開いてコマンドパレットから `TLA+: Check model with TLC` を実行します。

CLI では、各ディレクトリに移動して同名の `.cfg` を指定します。例:

```bash
cd examples/10-tlc-config
java -cp "$(ls -d ~/.vscode/extensions/tlaplus.vscode-ide-*/tools/tla2tools.jar | tail -1)" \
  tlc2.TLC -workers 1 -config WorkerPool.cfg WorkerPool.tla
```

小さな教材では、反例と探索深さを再現しやすくするため `-workers 1` を使います。性能比較をするときだけ
`-workers auto` も試します。TLC は有限モデルを明示的に探索するモデル検査器なので、定数と値域は最初から
現実の最大値にせず、問いに答えられる最小値から始めます。

## 直近の着手順

迷ったら、次の 3 項目だけを進めます。

1. `examples/11-blocking-queue-introduction` を作り、実装から抽出する状態とアクションを日本語で定義する
2. `examples/12-blocking-queue-state-graph` で最小構成の全状態グラフを生成し、各辺を説明する
3. `examples/15-blocking-queue-safety` まで進め、最初のデッドロック反例を README に読み下す

ここまで終えた時点で一度立ち止まり、「モデルのバグ」と「対象システムのバグ」を区別できているかを確認してから、
対称性と `VIEW` に進みます。

## 参考資料

- [TLA+ By Example](https://learning.tlapl.us/) — このリポジトリの主な出典
- [Learning TLA+](https://lamport.azurewebsites.net/tla/learning.html) — 公式の学習資料案内
- [TLA+ Video Course](https://lamport.azurewebsites.net/video/videos.html) — 分散プロトコル、ライブネス、refinement
- [Specifying Systems](https://lamport.azurewebsites.net/tla/book.html) — TLA+ と TLC の体系的な解説
- [TLC Model Checker](https://docs.tlapl.us/using:tlc:start) — TLC の実行方法とオプション
- [TLA+ Examples](https://github.com/tlaplus/Examples) — 検証済みの仕様例集
