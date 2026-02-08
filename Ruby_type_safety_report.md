# Rubyの型安全性・信頼性の現状調査 — Pythonとの比較を含む

Version: 1.0.0
Created: 2026-02-08
Status: DRAFT
Purpose: ChatGPTによるPython調査（`ChatGPT_python_deep-research-report.md`）と対になるRuby側の現状整理。

---

## 結論の要約

Rubyは設計当初からPythonより型安全寄りの特徴を複数持っている（Symbol型、freeze機構、強い型の一貫性）。しかし、静的型チェックのエコシステムは2025年時点でPython（mypy/Pyright）より**分裂・未成熟**であり、「CIで強制する」体制の構築はPythonより困難。Ruby 4.0（2025年12月リリース）のfrozen string literal強制は大きな前進だが、Ractorはまだ実験段階。

| 観点 | Ruby | Python |
|------|------|--------|
| 型の強さ（言語本体） | 強い型付け + Symbol + freeze | 強い型付け（文字列は不変） |
| 静的型チェッカー | Sorbet / Steep（分裂） | mypy / Pyright（収束傾向） |
| 型注釈の書き方 | `.rbs`別ファイル or Sorbetインライン | インライン（PEP 484） |
| ランタイム検証 | dry-validation / dry-types | Pydantic |
| Design by Contract | dry-validation（Contract） | deal / icontract |
| CI強制の成熟度 | Shopify規模では実績あり、中小は困難 | pre-commit + mypy --strict が定番化 |
| 不変性サポート | freeze（任意オブジェクト）、Ruby 4.0で文字列デフォルト凍結 | 文字列は元から不変、他は弱い |
| パターンマッチング | Ruby 2.7〜（in/case）+ dry-monads | Python 3.10〜（match/case） |

---

## Part I: Rubyが当初からPythonより優れている点

### 1.1 Symbol型 — 不変の識別子が言語組込み

RubyのSymbol（`:name`）は常にfrozen（不変）でインターン済み。同じシンボルは同じオブジェクトIDを持ち、変更不可。Pythonにはこれに相当する組込み型がない（文字列のインターンはCPython実装の最適化であり、言語仕様ではない）。

Symbolの存在により、Rubyではハッシュキーや設定値の「名前」が型レベルで文字列と区別される。これは正名（名と実の一致）を型で強制する仕組みと言える。

### 1.2 freeze — 任意オブジェクトの不変化機構

`Object#freeze`はRubyの任意オブジェクトに適用可能。freezeされたオブジェクトへの変更はRuntimeErrorを発生させる。解凍（unfreeze）は不可能。

- Fixnum, Bignum, Float, Symbol, true, false, nil は常にfrozen
- `# frozen_string_literal: true` で文字列リテラルをファイル単位で凍結可能
- Ruby 4.0（2025年12月リリース）では文字列リテラルがデフォルトで凍結

Pythonの文字列はデフォルトで不変だが、freeze相当の汎用機構は存在しない。`tuple`は不変だが`list`との変換は暗黙的で、任意オブジェクトをfreeze不可。

### 1.3 型変換の一貫した厳密さ

Rubyは暗黙の型変換がPythonより少ない。例えば`"3" + 3`はRubyではTypeError、Pythonでも同様だが、Rubyでは`to_i`/`to_s`等の明示的変換メソッドが慣習として根付いており、変換の意図が明確になりやすい。

---

## Part II: 静的型チェックの現状（2025年）

### 2.1 二つの系統 — Sorbet vs RBS+Steep

Rubyの静的型チェックは**二系統に分裂**しており、これが最大の問題。

#### Sorbet（Stripe開発）
- **インライン型注釈**: `sig { params(x: Integer).returns(String) }` をRubyファイル内に直接記述
- **段階的導入**: `# typed: false` → `true` → `strict` → `strong` の段階的strictness
- **大規模実績**: Stripe（15万ファイル以上）、Shopify（3.7万ファイル）が本番運用
- **Shopifyの状況**: 100%のファイルを`typed: true`以上に引き上げ済み。新規ファイルは必須。日次でメトリクス計測
- **ツール群**: Tapioca（RBIファイル自動生成）、rubocop-sorbet（sigil強制）

#### RBS + Steep（Ruby公式）
- **別ファイル型注釈**: `.rbs`ファイルにTypeScript `.d.ts`/C `.h`相当の型定義を記述
- **標準ライブラリの型情報**: Ruby本体に同梱
- **課題**:
  - 多くのgemがRBSファイルを同梱していない（`rbs collection`のfallbackは大半が`untyped`）
  - **フロー感度（type narrowing）の弱さ**: nilチェック後でもSteepが型を絞り込めないケースが多い
  - **TypeProfの自動生成は手直し必須**: 自動生成された型定義は`untyped`だらけで実用には手動修正が不可欠
  - **RSpec未対応**: テストフレームワークとの統合が弱い
  - **Rails対応が不完全**: `rbs_rails`は追加設定が必要で、設定が煩雑
  - IDEの補完・エラー検出がSorbetより弱い

#### 2025年の動向
Sorbet側が2025年2月からRBSコメント構文の**実験的サポート**を開始（`--enable-experimental-rbs-comments`）。両系統の収束の兆しはあるが、まだ実用段階ではない。

### 2.2 Pythonとの比較

Pythonはインライン型注釈（PEP 484）に一本化されており、mypy/Pyright/Pyreの三者とも同じ型注釈フォーマットを使う。RubyのSorbet vs RBS+Steepの分裂に相当する問題がない。

さらにPythonではPEP 561により`py.typed`マーカーファイルの標準が確立し、pipパッケージの型情報配布が制度化されている。Rubyの`rbs collection`はこれに比べて貧弱。

---

## Part III: ランタイム検証 — dry-rb エコシステム

### 3.1 dry-validation — Rubyの「Pydantic相当」

dry-validationはContract（契約）パターンを中核とした検証ライブラリ。PydanticのRuby版に最も近い位置づけ。

- **スキーマ（dry-schema）**: 型チェック・型変換・必須項目チェックを宣言的に記述
- **ルール**: スキーマを通過した値に対してドメイン固有のバリデーションを適用
- **分離原則**: 型レベルの検証（スキーマ）とビジネスロジックの検証（ルール）を明確に分離
- **マクロ**: 重複するルールのパターンを抽出・再利用可能
- **依存性注入**: 外部依存（DB、API等）をContractに注入可能

### 3.2 dry-types — 型制約の宣言

dry-typesは「制約付き型」を宣言的に定義する。Pydanticの`Field(ge=0, le=100)`等に相当。

### 3.3 dry-monads — 安全なエラーハンドリング

`Result`（Success/Failure）モナドによる関数型エラーハンドリング。Pythonには標準的な対応物がない（`returns`ライブラリが近いが普及度が低い）。dry-validationの結果をパターンマッチングで分岐可能。

### 3.4 Pythonとの比較

| | Ruby (dry-rb) | Python (Pydantic) |
|---|---|---|
| 型駆動の検証 | dry-schema + dry-types | Pydantic BaseModel |
| ビジネスルール分離 | dry-validation Contract | Pydantic validator / model_validator |
| エラーハンドリング | dry-monads (Result型) | 例外ベース（or returns ライブラリ） |
| シリアライズ | 別gem必要 | Pydantic内蔵 |
| 普及度 | Railsコミュニティで一定の普及 | Python全体で事実上の標準 |

dry-rbはPydanticより**概念的には洗練されている**（スキーマとルールの分離、モナドによるエラーハンドリング）が、Pydanticの「一つのモデル定義で検証もシリアライズも完結」という実用性には劣る。

---

## Part IV: Ruby 4.0 の変更点と信頼性への影響

### 4.1 frozen string literal のデフォルト化

Ruby 4.0（2025年12月25日リリース）で、`# frozen_string_literal: true`コメントなしの文字列リテラルへの変更がRuntimeErrorに変更。

- Ruby 3.4で非推奨警告を導入（`-W:deprecated`で有効化）
- 移行パス: `# frozen_string_literal: true` + `.dup`で可変文字列を明示的に作成
- **メモリ効率の改善**: 同一リテラルの共有（GC圧力の削減、ベンチマークで約5%の性能向上）
- **スレッド安全性**: 不変文字列はRactor間で安全に共有可能

### 4.2 Ractor — まだ実験段階

Ractor（Ruby Actor）はGVL（Global VM Lock）なしの並列実行を目指すが、Ruby 4.0時点でも実験ステータス。2026年中の正式化を目標としているが、Ractor対応Webサーバーは実験プロジェクト以外に存在しない。

Ractorの設計原則:
- **共有可能オブジェクト**: frozenまたは本質的に不変のオブジェクトのみ
- **非共有オブジェクト**: コピーまたは「移動」で他のRactorに送る
- frozen string literalのデフォルト化はRactor対応の前提条件

### 4.3 ZJIT — 新JITコンパイラ

デフォルト無効。YJITより遅いが将来の最適化余地がある。信頼性への直接的影響は現時点では限定的。

---

## Part V: AI IDE向けRuby信頼性ポリシー（テンプレート）

以下はChatGPTが作成したPython版テンプレート（`ChatGPT_python_deep-research-report.md`のAI IDE Strict Python Reliability Policy）に対応するRuby版。

```markdown
# AI IDE Strict Ruby Reliability Policy

## Role
あなたは本リポジトリの「信頼性最優先」Ruby開発を支援するAIコーディングアシスタントです。
以下のルールは"最上位ポリシー"として必ず守ってください。

## Non-negotiables (絶対ルール)
- すべての公開メソッド・クラスはSorbet sig を持つ。
- 変更・追加コードは **型チェック + RuboCop + テスト** を必ず通す前提で書く。
- `T.untyped` / `untyped` は原則禁止。必要な場合は「理由」「代替案」「スコープ最小化」をコメントで明記。
- 外部との境界（API入力・JSON・ENV・DB・CLI・ファイル）では **必ずランタイム検証** を行う（dry-validation / dry-schema）。
- 例外・失敗は握りつぶさない（`rescue => e; end` のような空rescueは禁止）。
- `# frozen_string_literal: true` を全ファイルに付与（Ruby 4.0以前のプロジェクトでも）。

## Toolchain
- Type checker: Sorbet (`# typed: strict` を目標) + Tapioca (RBI自動生成)
- Linter: RuboCop + rubocop-sorbet (sigil レベル強制)
- Tests: RSpec or Minitest
- Validation (境界): dry-validation + dry-schema + dry-types
- Error handling (推奨): dry-monads (Result型)
- Security: Brakeman (Rails), bundler-audit

## Definition of Done (完了条件)
変更を「完了」と見なすには:
- `bundle exec rubocop --autocorrect-all` でlint通過
- `bundle exec srb tc` で型チェック通過
- `bundle exec rspec` (or `rake test`) で全テスト通過

必要に応じて:
- `bundle exec brakeman` (Rails セキュリティスキャン)
- `bundle audit check --update` (依存脆弱性チェック)

## Coding Rules

### Types
- 新規ファイルは `# typed: strict` 以上。既存ファイルは触った範囲でstrictに近づける。
- `T.untyped` は原則禁止。必要な場合は理由・代替案・スコープ最小化をコメントで明記。
- nilの可能性がある値は `T.nilable(X)` で明示し、必ずnilガードで潰す。

### Data modeling
- 生のHashでデータを持ち回らない。Struct / Data (Ruby 3.2+) / T::Struct (Sorbet) / dry-struct で構造化。
- 外部入力は dry-validation Contract で validate してから内部型へ変換。
- Data クラス（Ruby 3.2+）は不変データ構造として積極活用。

### Immutability
- freeze を積極使用。設定値・定数は freeze する。
- 配列・ハッシュの定数は `.freeze` を付ける。
- 可変性が必要な場合は `.dup` で明示的にコピーを作る。

### Error handling
- dry-monads の Result 型（Success/Failure）を推奨。例外は本当に例外的な状況のみ。
- rescue は具体的な例外クラスを指定（`rescue StandardError` 以上の広さは禁止）。
- パターンマッチング（case/in）で Result を分岐処理。

### Testing
- RSpec/Minitest で単体テストを必ず追加/更新。
- 境界値、nil入力、不正型入力のテストを必ず含める。
- Contract のテストは dry-validation の result をアサートする形で書く。

### Style / Structure
- RuboCop 準拠。メソッドは短く（10行以下を目安）。
- 副作用のあるメソッド（!メソッド）は明示的に名前で区別。
- クラスは単一責任。大きくなったら分割。

## Change Policy
- 挙動を変えない修正では、テストを壊さず、差分を最小化。
- 型が足りない既存領域に触れる場合は「触った範囲だけでも」strictに近づける。
- 全体リファクタは勝手にしない。必要最小範囲の改善に留める。

## If you are uncertain
- 不確かな推測で実装しない。
- まず「期待仕様」「入力境界」「失敗モード」を確認し、型/Contract/テストに落としてから実装する。
```

---

## Part VI: 推奨事項

### Ruby プロジェクトへの推奨
1. **Sorbet優先**: 実績・ツール成熟度でRBS+Steepを大きくリード。Shopifyの運用実績が根拠。
2. **dry-rb エコシステム活用**: dry-validation + dry-types + dry-monads の三点セットで境界検証とエラーハンドリングを型安全に。
3. **frozen_string_literal: true**: Ruby 4.0移行を待たず、全ファイルに即座に適用。
4. **Data クラス（Ruby 3.2+）活用**: 不変データ構造として、Struct より安全。
5. **RuboCop + rubocop-sorbet**: CIで強制。新規ファイルの `# typed: strict` を rubocop-sorbet の MinimumStrictness で自動検出。

### Python と比較した場合のRubyの弱点
1. **型チェッカーの分裂**: Sorbet vs RBS+Steep。PythonのPEP 484一本化に比べ、コミュニティの力が分散。
2. **gem の型情報不足**: PythonのPEP 561（py.typed）に相当する標準がない。
3. **CI強制の敷居**: Pythonの `mypy --strict` + `pre-commit` ほどの「定番構成」がまだ確立していない。

### Python と比較した場合のRubyの強み
1. **freeze の汎用性**: 任意オブジェクトを不変化できる。Pythonにはない。
2. **Symbol型**: 名前と値を型レベルで区別。辞書キーの安全性が高い。
3. **dry-monads**: Result型による関数型エラーハンドリングがエコシステムに定着。Pythonにはまだ標準的な対応物がない。
4. **Ruby 4.0のfrozen string default**: 言語レベルでの不変性強制はPythonの「文字列だけ不変」より包括的。

---

## 参考文献

- [The State of Static Typing in Ruby in 2025](https://dev.to/aeremin/the-state-of-static-typing-in-ruby-in-2025-3o4b) — DEV Community
- [Ruby typing 2024: RBS, Steep, RBS Collections](https://brandur.org/fragments/ruby-typing-2024) — brandur.org
- [Sorbet vs RBS: Choosing a Type System for Ruby](https://betterstack.com/community/guides/scaling-ruby/sorbet-vs-rbs/) — Better Stack
- [Adopting Sorbet at Scale](https://shopify.engineering/adopting-sorbet) — Shopify Engineering
- [The State of Ruby Static Typing at Shopify](https://shopify.engineering/the-state-of-ruby-static-typing-at-shopify) — Shopify Engineering
- [Static Typing for Ruby](https://shopify.engineering/static-typing-ruby) — Shopify Engineering
- [Ruby 4.0.0 Released](https://www.ruby-lang.org/en/news/2025/12/25/ruby-4-0-0-released/) — ruby-lang.org
- [Frozen String Literals: Past, Present, Future?](https://byroot.github.io/ruby/performance/2025/10/28/string-literals.html) — byroot
- [What's The Deal With Ractors?](https://byroot.github.io/ruby/performance/2025/02/27/whats-the-deal-with-ractors.html) — byroot
- [A Thorough Look into RBS for Rails](https://mgmarlow.com/words/2025-09-21-brief-look-into-rbs-rails/) — mgmarlow.com
- [dry-validation Introduction](https://dry-rb.org/gems/dry-validation/1.10/) — dry-rb.org
- [Climbing Steep hills, or adopting Ruby 3 types with RBS](https://evilmartians.com/chronicles/climbing-steep-hills-or-adopting-ruby-types) — Evil Martians
- [A Review of Immutability in Ruby](https://www.rubypigeon.com/posts/a-review-of-immutability-in-ruby/) — Ruby Pigeon

---

*This document is licensed under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).*
