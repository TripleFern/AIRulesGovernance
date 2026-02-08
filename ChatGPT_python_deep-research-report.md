# Pythonの信頼性をC++/関数型並みに寄せるための主要技術とAI IDE強制Markdown

## 調査の前提と結論

Python自体は、型ヒント（型アノテーション）を書いても**ランタイムがそれを強制しない**設計で、型情報は主に型チェッカーやIDE、リンターなどの外部ツールが利用します。citeturn13view2 また、型ヒント標準化の中心文書であるPEPは、静的解析（型チェッカー等）やIDE支援を主目的としつつ、**Pythonを静的型付け言語に変える意図はなく、型ヒントを必須にしたいわけではない**ことも明記しています。citeturn5view0

そのため「C++のようにコンパイルで落ちる」「関数型のように（強い型＋不変・純粋性）で壊れにくい」に近づけるには、**言語本体の“仕様”を変えるのではなく**、(a) 静的型チェック、(b) リント/フォーマット、(c) 境界での入力検証（ランタイム検証）、(d) 契約（Design by Contract）と必要なら記号実行、(e) テスト（特に性質ベーステスト）を**開発プロセス側で強制**するのが現実解になります。citeturn5view0turn6view2turn7view1turn1search16turn6view3turn2search1turn5view2turn2search6turn2search11turn4search0

本調査で「少し前に見たはずの、Pythonの信頼性を上げる取り組み」に最も近い中心テーマは、**Gradual Typing（段階的型付け）＋静的型チェッカーをCI/IDEに組み込む潮流**です。これはPEP 484を核に、型情報の配布（PEP 561）やジェネリクス記法の改善（PEP 695）などが積み上がり、周辺に契約・検証・テストのエコシステムが接続して「壊れにくいPython」を作る、という流れです。citeturn5view0turn10view0turn11view0

代表的に組み合わせられるツール群（“強制”の対象）を、役割で整理すると次の構図になります：静的型チェックは entity["organization","mypy","python type checker"] / entity["organization","Pyright","python type checker"]（entity["company","Microsoft","software company"]）/ entity["organization","Pyre","python type checker"]（entity["company","Meta Platforms","tech company"]、後継として entity["organization","Pyrefly","meta type checker"]）、リント/整形は entity["organization","Ruff","python linter formatter"]（entity["company","Astral","python tooling company"]）、境界での検証は entity["organization","Pydantic","python data validation"]、性質ベーステストは entity["organization","Hypothesis","python property testing"]、契約（DbC）は entity["organization","deal","python design by contract"] / entity["organization","icontract","python design by contract"]、仕様違反の反例探索に entity["organization","CrossHair","python symbolic execution"]、テスト実行基盤に entity["organization","pytest","python test framework"]、コミット時強制に entity["organization","pre-commit","git hooks framework"]、セキュリティ静的解析に entity["organization","Bandit","python security linter"]（entity["organization","PyCQA","python code quality org"]）、依存脆弱性スキャンに entity["organization","pip-audit","python vulnerability scanner"]（entity["organization","Python Packaging Authority","packaging org"] のAdvisory DB活用）という形です。citeturn6view2turn8view0turn7view1turn6view1turn1search6turn1search16turn5view3turn6view3turn2search0turn2search1turn5view2turn2search6turn2search11turn4search0turn4search1turn4search2turn4search3

## 静的型付けの中核であるGradual TypingとPEP群

型ヒントの標準はPEP 484が中心で、目的は「標準化された注釈により、静的解析・リファクタ・IDE支援を容易にする」ことに置かれています。citeturn5view0 ただし同PEPは、Pythonが動的型付けであり続けること／型ヒントを必須にするつもりがないことも強調しており、**型だけで“完全に安全”にする発想は成立しません**。citeturn5view0turn13view2

この「型は書けるが強制は外部ツール」というギャップを埋めるのが、段階的型付け（Gradual Typing）＋型チェッカー運用です。たとえばmypyは、実行せずに型の不整合を検出でき、段階的に型付けを導入できる設計であることを明言しています。citeturn6view2turn8view0

一方で、現実のプロジェクト運用では「依存ライブラリが型情報を持つか」が品質の上限を左右します。そこでPEP 561は、パッケージが型チェック対応であることを示す**`py.typed`マーカーファイル**やスタブ専用パッケージ命名（`*-stubs`）など、型情報配布の標準を定義しました。citeturn10view0 これにより「型チェッカーをCIで強制したいのに、依存側の型がなくて詰む」状況を減らす方向へエコシステムが進みます。citeturn10view0turn8view0

さらに型記法自体も改善されており、PEP 695は**型パラメータの新しい構文**（例：`class C[T]: ...` や `type Alias[T] = ...`）を導入し、従来のTypeVar中心の“後付け感”と混乱を減らす動機を説明しています。citeturn11view0 これは特にジェネリクスを多用する（=型で不変条件を表現したい）設計に効きます。citeturn11view0

「不変データ構造っぽく寄せる」文脈では、標準ライブラリのdataclasses（PEP 557）が重要です。PEP 557は、型注釈（PEP 526の記法）をフィールドとして読み取り、`__init__`や比較等を自動生成すること、そして静的型チェッカー支援を主要目標に含むことを述べています。citeturn9view0 ただし、dataclasses自体は型注釈を基本的に検証に使わず、値検証・変換が必要なら別手段が必要とも明示しています。citeturn9view0 つまり「型で設計意図を表す」には有効だが、「境界入力が正しいか」は別レイヤーで担保すべき、という切り分けが自然です。citeturn9view0turn6view3

image_group{"layout":"carousel","aspect_ratio":"1:1","query":["mypy static type checker logo","Pyright Python type checker logo","Ruff Python linter formatter logo","Pydantic logo"],"num_per_query":1}

## 型チェックをCI/IDEに強制するための実務ツール設計

「Pythonの信頼性を上げる取り組み」を“使える形”に落とすと、要点は**ツールの強制力（強制＝自動化＋ゲート化）**です。言語が型を強制しない以上、型や規約は“書いてあるだけ”だと必ず崩れます。citeturn13view2turn5view0

mypyは、無注釈関数はデフォルトで型チェックしない（＝放置すると未型付け領域が残る）こと、そして `--disallow-untyped-defs` や `--check-untyped-defs` などで厳格化できることを説明しています。citeturn8view0 さらに `--strict` については、追加チェックを有効化し、型関連のランタイムエラーを（意図的に回避しない限り）大きく減らす趣旨の主張をしています。citeturn8view0

Pyright側も「strict」を明確な運用単位として持ち、設定の `strict` パス指定が `# pyright: strict` コメントと同等であり、strictでは大半の型チェック規則が有効になることを仕様として述べています。citeturn7view1 また設定は `pyrightconfig.json` だけでなく `pyproject.toml` の `[tool.pyright]` にも置ける、とされています。citeturn7view1 つまり「リポジトリに設定を置き、CIで常に回す」構成が作れます。citeturn7view1turn8view0

コード規約の強制は、実務上は（静的型よりも）まずリンターとフォーマッタで“揺れ”を潰すのが効率的です。RuffはRust実装の高速リンター兼フォーマッタであることを明言し、`ruff format` による整形も公式に提供しています。citeturn1search16turn5view3 さらに、Ruffは「`Any` はエスケープハッチであり、乱用は悪い」という観点のルール（例：ANN401）を明確に文書化しており、型の厳格運用と相性が良いです。citeturn12search5

強制の“入口”としては、pre-commitが「各コミットでフックを走らせ、些細な問題をコードレビュー前に洗い出す」狙いを説明しており、型チェック・リント・整形をコミット時に自動適用する定番の仕組みになります。citeturn4search1

なお、AI IDE向けMarkdownを運用する場合、「Markdown中のPythonコード例」まで体裁を揃えたいことが多いですが、RuffはMarkdown内のPythonフェンスコードブロック整形を（プレビュー機能として）提供しているため、ドキュメント駆動の運用とも接続しやすいです。citeturn5view3

## 実行時保証としてのデータ検証とランタイム型チェック

Python標準ドキュメントは、型注釈はランタイムで強制されず、外部ツールが使う、と明記しています。citeturn13view2 これは「静的型チェックに通っても、実行時に外部から入るデータは壊れている」問題が残る、ということです。citeturn13view2turn6view3

この“境界問題”に対し、Pydanticは型をもとに**検証（validation）とシリアライズ**を行う設計で、型と制約・厳格性を制御できることを説明しています。citeturn2search0turn6view3 またPydanticはstrict/laxという実行時の振る舞いモードも提供するとしています。citeturn6view3 これは「内部は型チェッカーで保証を厚くし、外部入力はPydanticで検証する」という二層構造を作りやすい、という意味で、C++的な“境界で弾く”設計に寄せられます。citeturn6view3turn13view2

一方で「関数の引数・戻り値など、実行時にも型違反を捕捉したい」場合は、Typeguardのようなランタイム型チェックが選択肢になります。Typeguardは、PEP 484の注釈に基づいて関数などの実行時型チェックを提供し、静的型チェッカーと併用して“実行時にしかわからない違反”を捕捉する追加層として使える旨を述べています。citeturn3search5turn3search1 同系統としてBeartypeも、デコレータで実行時型チェックを行う利用形態をドキュメントで示しています。citeturn3search2turn3search13

ここで重要なのは、**「静的型チェック＝設計の整合性」と「実行時検証＝境界の安全性」は目的が異なる**ことです。Pythonの型注釈がそもそも強制されない以上、どちらか片方だけでC++的な失敗モード（早期に落ちる）を再現するのは難しく、両者を“使い分けて強制”する方が現実的です。citeturn13view2turn8view0turn6view3

## 仕様の形式化としてのDesign by Contractと記号実行

静的型は「形」を強くしますが、「値の範囲」「例外条件」「副作用」「不変条件（invariant）」など、型だけでは表現しづらい仕様は残ります。そこで再注目されるのがDesign by Contract（DbC）です。citeturn5view2turn2search9

dealは、前提条件・事後条件・不変条件などの“古典的DbC”に加え、例外や副作用の追跡、性質ベーステスト、静的チェッカー、さらには形式検証（formal verification）などまで射程に入れた設計を掲げています。citeturn5view2 さらにpytestやHypothesis等との統合も明記しており、「契約を書いたらテスト生成や静的検査に接続する」という、関数型の“プロパティ＋反例探索”っぽいスタイルに寄せやすいです。citeturn5view2turn2search1

icontractもDbCを提供し、違反時メッセージや継承サポートを特徴として説明しています。citeturn2search3turn2search6 またクラス不変条件（invariant）が「初期化後および公開メソッド呼び出し前後で成り立つべき性質」を表す、と不変条件の位置付けを文書化しています。citeturn2search9

さらに一歩進めると、CrossHairのような記号実行（symbolic execution）系のツールが出てきます。CrossHairは、関数を“実行”はするものの、通常の値ではなく**記号的な入力**を与え、SMTソルバを使って実行パスを探索し、仕様（契約）に反する反例を見つける仕組みを説明しています。citeturn2search2turn2search5turn2search11 これは「型＋契約＋反例探索」による“準形式手法”の実用寄り実装で、PythonでC++/関数型に近い信頼性を作る文脈で、ここ数年再び注目が集まる理由になります。citeturn2search11turn5view2

なお、Python本体にDbC（特にクラス不変条件）をネイティブ導入できないか、という議論自体も継続して存在します。citeturn2search24 ただし現状の主戦場はあくまでライブラリ／ツールであり、「AI IDEに強制させる」設計でも、当面は外部ツール前提で組むのが妥当です。citeturn13view2turn2search24turn5view2

## AI IDE向けに新機能を強制するMarkdownテンプレート

以下は、AI IDE（コーディング支援LLM）に**“壊れにくいPython”の規約を強制**させるための「リポジトリ常駐Markdown」です。設計思想は、(1) 型注釈は強制されないため型チェッカーでゲート化する（PEP 484の目的に沿う）citeturn5view0turn8view0turn7view1、(2) 境界入力はランタイム検証が必要citeturn13view2turn2search0turn6view3、(3) 型で表現しにくい仕様は契約＋性質ベーステスト／反例探索で補うciteturn5view2turn2search1turn2search11、(4) 強制力はpre-commit/CIで作るciteturn4search1turn5view3、です。

```markdown
# AI IDE Strict Python Reliability Policy

## Role
あなたは本リポジトリの「信頼性最優先」Python開発を支援するAIコーディングアシスタントです。
以下のルールは“最上位ポリシー”として必ず守ってください。

## Non-negotiables (絶対ルール)
- すべての公開関数・メソッド・クラスは型注釈を持つ（引数/戻り値/属性）。
- 変更・追加コードは **静的型チェック + lint + format + テスト** を必ず通す前提で書く。
- `Any` は原則禁止。どうしても必要な場合は「理由」「代替案」「スコープ最小化」をコメントで明記。
- “外部”との境界（API入力・JSON・ENV・DB・CLI・ファイル）では **必ずランタイム検証** を行う。
- 例外・失敗は握りつぶさない（`except: pass` などは禁止、例外を型・契約・テストで扱う）。

## Toolchain (CIで強制される前提)
- Formatter/Linter: ruff
- Type checker: pyright (strict) + mypy (--strict)
- Tests: pytest (+ hypothesis を推奨)
- Contracts (必要箇所): deal または icontract (+ 反例探索に CrossHair を検討)
- Security (必要箇所): bandit / pip-audit

## Definition of Done (完了条件)
変更を「完了」と見なすには、少なくとも以下が成立していること:
- `ruff format --check .`
- `ruff check .`
- `pyright` (strict 対象は strict として)
- `mypy --strict <対象パス>`
- `pytest -q`

必要に応じて:
- `pip-audit`（依存の脆弱性チェック）
- `bandit -r <src>`（SAST）

## Coding Rules (生成コードの必須規約)
### Types
- すべての関数は型注釈必須。未型付けの関数を追加しない。
- Unionは `A | B` を優先（Python 3.10+ 前提）。
- ジェネリクスは Python 3.12+ なら PEP 695 の構文を優先。
- Optionalは「Noneが入る可能性」を設計上の境界として扱い、必ず分岐で潰す。

### Data modeling
- ただの辞書でデータを持ち回らない。`dataclass` / attrs / TypedDict / Pydantic Model で構造化する。
- 外部入力は Pydantic で validate してから内部型へ変換（境界で弾く）。

### Contracts
- 型では表現できない仕様（範囲、不変条件、事後条件、副作用など）は契約で明文化する。
- 契約が正しいことを pytest + hypothesis のプロパティテストで裏取りする。
- 重要関数は CrossHair で「反例がないか」を探索できる形に保つ（純粋関数寄りに分離）。

### Testing
- pytest で単体テストを必ず追加/更新。
- 例外ケースと境界値を必ず含める。
- 性質ベーステスト（Hypothesis）は「変換」「パーサ」「最適化」「集計」「ソート/検索」などに優先適用。

### Style / Structure
- 生成したコードは ruff 前提のスタイルで書く（整形は ruff format に従う）。
- 大きい関数は分割し、純粋関数（副作用なし）とI/O境界を分離する。

## Change Policy (既存コードを直すとき)
- 挙動を変えない修正では、テストを壊さず、差分を最小化する。
- 型が足りない既存領域に触れる場合は「触った範囲だけでも」strictに近づける。
- ただし全体リファクタは勝手にしない。必要な最小範囲の改善に留める。

## If you are uncertain
- 不確かな推測で実装しない。
- まず「期待仕様」「入力境界」「失敗モード」を文章で確認し、型/契約/テストに落としてから実装する。

## Output Requirements (AIの出力形式)
- 変更点の要約
- 追加した型/契約/テストの要約
- 想定される落とし穴（例: None, 例外, 境界入力）と、その対策
```

このテンプレートは、特に「型注釈はランタイムで強制されない」citeturn13view2turn5view0 というPythonの前提の上に、mypy strict（強い追加チェック）citeturn8view0 とPyright strict（strict対象パス＝`# pyright: strict`相当）citeturn7view1 をCIでゲート化し、Ruffで整形・リントを固定するciteturn1search16turn5view3turn12search5 ことで“強制”を担保する設計です。さらに境界ではPydanticのような型駆動の検証を行いciteturn2search0turn6view3、型では足りない仕様は契約（deal/icontract）と反例探索（CrossHair）へ接続するciteturn5view2turn2search6turn2search11、という構造になっています。