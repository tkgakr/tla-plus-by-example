# レコード

出典: [learning.tlapl.us / Introduction / Records](https://learning.tlapl.us/intro/records/)

本家ページの要点とユーザーアカウントのサンプルを、このリポジトリで実行できる日本語教材として再構成しています。
レコードの生成、フィールド参照、レコード集合、`EXCEPT` による更新、関数としてのレコードを扱います。

前のページ: [examples/08-sequences](../08-sequences)（シーケンス）

---

## 1. 名前付きフィールドをまとめる

レコードは、名前の付いた複数のフィールドを 1 個の値としてまとめたものです。プログラミング言語の構造体や
オブジェクトに似ています。

```tla
person == [name |-> "Alice", age |-> 30]
```

角括弧の中に `フィールド名 |-> 値` をカンマで区切って並べます。フィールドごとに異なる種類の値を持てます。
上の例では `name` の値は文字列、`age` の値は整数です。

レコードは値なので、変数に保存したり、演算子の引数や戻り値にしたり、ほかのレコードやシーケンスの中へ入れたり
できます。フィールドの記述順序は値の同一性に影響しません。

```tla
[name |-> "Alice", age |-> 30]
    = [age |-> 30, name |-> "Alice"]
```

---

## 2. フィールドを参照する

決まった名前のフィールドは、ドット記法で参照できます。

```tla
person.name    \* "Alice"
person.age     \* 30
```

[UserAccounts.tla](UserAccounts.tla) では、サンプルのアカウントを次のように定義しています。

```tla
Example == [name |-> "Alice", age |-> 30, active |-> TRUE]
```

レコードは後述するように関数でもあるため、文字列をキーにした `Example["name"]` でも参照できます。

```tla
Example["name"] = Example.name
```

通常はフィールドがコード上で明確になるドット記法が読みやすいでしょう。フィールド名を値として動的に選びたい
場合は、関数の角括弧による参照が使えます。存在しないフィールドを参照した結果には依存できません。

---

## 3. レコード集合を型として使う

次の式はレコード 1 個ではなく、条件に合う**すべてのレコードの集合**を表します。

```tla
[name : Names, age : Ages, active : BOOLEAN]
```

コロン `:` の右側には、各フィールドが取り得る値の集合を書きます。この例では次のように範囲を定義しています。

```tla
Names == {"Alice", "Bob"}
Ages == 30..32
```

したがって、名前は 2 通り、年齢は 3 通り、有効状態は 2 通りで、レコード集合には
`2 * 3 * 2 = 12` 個の値があります。

状態変数の形を検査する `TypeOK` には、このレコード集合への所属判定を使えます。

```tla
TypeOK ==
    account \in [name : Names, age : Ages, active : BOOLEAN]
```

この条件は、3 フィールドの値の範囲だけでなく、フィールドの集合がちょうど `name`、`age`、`active` であることも
表します。必要なフィールドが欠けたレコードや、余分なフィールドを持つレコードは、この集合の要素ではありません。

レコード値を作る `|->` と、レコード集合を作る `:` を区別してください。

| 構文 | 結果 |
| --- | --- |
| `[name |-> "Alice", age |-> 30]` | 具体的なレコード 1 個 |
| `[name : Names, age : Ages]` | 条件に合うレコードの集合 |
| `account.name` | 現在のレコードのフィールド値 |

---

## 4. `EXCEPT` でフィールドを更新する

レコードは不変の値です。フィールドを書き換えるのではなく、`EXCEPT` で指定フィールドだけが異なる新しい
レコードを作ります。

```tla
[Example EXCEPT !.age = 31]
```

`!.age` が更新箇所を示します。結果は次の値です。元の `Example` 自体は変化しません。

```tla
[name |-> "Alice", age |-> 31, active |-> TRUE]
```

状態遷移では、新しいレコードを次状態の変数へ結び付けます。

```tla
Birthday ==
    /\ account.age < 32
    /\ account' = [account EXCEPT !.age = @ + 1]
```

`@` は更新対象の元の値、この場合は `account.age` を表します。現在の年齢が 30 なら、次状態の年齢は 31 です。
名前と有効状態も右辺のレコードに含まれているため、別途 `UNCHANGED` を書く必要はありません。

複数のフィールドを一度に変えた新しいレコードも作れます。

```tla
[Example EXCEPT !.name = "Bob", !.active = FALSE]
```

`EXCEPT` は元のレコードに存在する場所を置き換える構文です。新しいフィールドを追加する用途には使いません。

---

## 5. レコードは関数

TLA+ のレコードは、フィールド名の文字列を定義域とする関数です。

```tla
[name |-> "Alice", age |-> 30]
```

上のレコードは、次の関数と同じ値です。

```tla
[field \in {"name", "age"} |->
    IF field = "name" THEN "Alice" ELSE 30]
```

そのため `DOMAIN` も利用できます。

```tla
DOMAIN Example = {"name", "age", "active"}
```

ただし、`DOMAIN` は集合なのでフィールドの順序を持ちません。[前章](../08-sequences)のシーケンスが
`1..Len(s)` を定義域にするのに対し、レコードはフィールド名の集合を定義域にします。

`DomainOK` は、到達するすべての `account` に必要なフィールドだけがあることを明示的に検査します。
これは `TypeOK` に含まれる条件ですが、「レコードは関数」という性質を確認するために分けています。

---

## 6. ユーザーアカウントの状態遷移

初期状態は Alice、30 歳、有効なアカウントです。

```tla
Init == account = Example
```

`Next` では 3 種類の操作を選べます。

```tla
Next ==
    Birthday \/ Rename \/ ToggleActive
```

| アクション | 変更内容 |
| --- | --- |
| `Birthday` | 年齢を 1 増やす。32 歳が上限 |
| `Rename` | 名前を `Names` のいずれかにする |
| `ToggleActive` | `active` の真偽を反転する |

`Rename` は新しい名前を非決定的に選びます。

```tla
Rename ==
    \E newName \in Names :
        account' = [account EXCEPT !.name = newName]
```

現在と同じ名前も選べるため、このアクションには自己ループがあります。すべての組み合わせに到達でき、異なる状態は
レコード集合の要素数と同じ 12 個です。

`RecordExamplesOK` では、フィールド参照、関数との等価性、1 フィールドと複数フィールドの更新、レコード集合の
要素数を、具体例を使って検査します。

---

## 7. TLC で実行する

`UserAccounts.tla` を開いて `Cmd + Shift + P` → **`TLA+: Check model with TLC`** を実行します。
同じディレクトリの [UserAccounts.cfg](UserAccounts.cfg) が設定ファイルです。

CLI なら次のコマンドです。

```bash
cd examples/09-records
java -cp "$(ls -d ~/.vscode/extensions/tlaplus.vscode-ide-*/tools/tla2tools.jar | tail -1)" \
  tlc2.TLC -workers 1 -config UserAccounts.cfg UserAccounts.tla
```

設定ファイルでは次の 3 つを検査します。

```cfg
INIT Init
NEXT Next

INVARIANT TypeOK
INVARIANT DomainOK
INVARIANT RecordExamplesOK
```

正常なら `Model checking completed. No error has been found.` と表示され、終了コード `0` になります。
このモデルでは 12 個の異なる状態が見つかります。

---

## 8. 触って確かめる

- `Names` に `"Carol"` を追加する。到達状態数とレコード集合の要素数が 18 になるため、
  `RecordExamplesOK` の期待値も `18` に変えます。
- `Birthday` のガード `account.age < 32` を削る。年齢 33 の状態が生成され、`TypeOK` 違反になります。
- `Birthday` の `@ + 1` を `account.age + 1` に変える。同じ検査結果になることを確認します。
- `ToggleActive` の `~@` を `TRUE` に変える。無効状態から有効には戻れますが、有効状態から無効へ移れなくなります。
- `Rename` の更新式を `[name |-> newName]` に変える。`age` と `active` が欠けるため、`TypeOK` 違反になります。
- `Init` に `role |-> "user"` を追加する。レコード集合に余分なフィールドが認められず、初期状態で
  `TypeOK` 違反になります。
- `Next` を `Birthday` だけにする。32 歳になると遷移できず、TLC がデッドロックを報告します。

---

## 次に読むもの

- 次のページ: [examples/10-tlc-config](../10-tlc-config)（TLC の設定ファイル）
- learning.tlapl.us の次ページは [TLC Configuration](https://learning.tlapl.us/intro/tlc-config/) です。
- [examples/08-sequences](../08-sequences) — 関数としてのシーケンス、`DOMAIN`
- [examples/07-functions](../07-functions) — 関数の定義、参照、関数集合、`EXCEPT`、`@`
- [examples/06-sets](../06-sets) — 集合への所属判定と要素数
