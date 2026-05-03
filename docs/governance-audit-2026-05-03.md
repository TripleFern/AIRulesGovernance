# Governance Audit — AIRulesGovernance × SciContextCompressor

Status: VERIFIED
Created: 2026-05-03
Author: TripleFern (assisted by Claude Code)

---

## 背景

SciContextCompressor リポジトリでのcontext compression / code search hooks開発を契機に、
AIRulesGovernance のルール管理と他リポジトリへの配信上の問題を点検した。

---

## 発見した問題と対処

### 問題 1 — Section 18 のクロスリファレンスが配信先で壊れる (対処済み)

**発見**: CLAUDE.md Section 18 に以下の記述があった。

```
see ... docs/CURSOR_PAL_COST_TIERED_AGENTS.md (e.g. universal-tools)
```

`deploy.ps1` は CLAUDE.md を全リポジトリに上書きコピーするが、`universal-tools` は
以前試みた類似プロジェクトであり現在は参照対象外。また `docs/CURSOR_PAL_COST_TIERED_AGENTS.md`
は配信先リポジトリに存在しないため、AIが参照しようとすると失敗する。

**対処**: Section 18 の2箇所を修正。
- `docs/CURSOR_PAL_COST_TIERED_AGENTS.md (e.g. universal-tools)` 参照を削除
- task tier の説明を自己完結した記述 (L0-L4 の定義) に変更
- `data/pal-metrics/` 行の末尾ファイル参照も削除

変更箇所: `CLAUDE.md` line 495 前後 (Section 18)

---

### 問題 2 — CLAUDE.md.bootstrap-additions.md が存在しても参照されない (対処済み)

**発見**: SciContextCompressor の bootstrap.sh/ps1 は `CLAUDE.md.bootstrap-additions.md`
を配信するが、CLAUDE.md にその参照がなく、AIが自動では読まない。
Sections X/Y (memory system protocol, code search priority) は開発中のため
CLAUDE.md 本体への取り込みは時期尚早。

**対処**: CLAUDE.md Section 9 (Before Starting Work) に item 6 を追加。

```
6. If `CLAUDE.md.bootstrap-additions.md` exists in this repository,
   read it before starting work — it contains project-specific additions
   to these universal rules.
```

変更箇所: `CLAUDE.md` Section 9, item 6

---

### 問題 3 — deploy.ps1 が SciContextCompressor にも上書き配信する (把握・許容)

**発見**: `deploy.ps1` は `C:\gitkraken\*` 下の全 git リポジトリ (AIRulesGovernance のみ除外)
を対象とするため、SciContextCompressor も含まれる。SciContextCompressor 固有の変更を
CLAUDE.md に加えると次の deploy で消える。

**判断**: 現時点では SciContextCompressor の CLAUDE.md 内容は本家と同一であるため実害なし。
将来 SciContextCompressor 固有ルールを CLAUDE.md に追加する場合は、
`CLAUDE_LOCAL.md` に記載する方法 (deploy.ps1 が自動で参照注記を追記する仕組み済み) を使う。

---

### 問題 4 — AIRulesGovernance 自体に hooks が設定されていない (把握・未対処)

**発見**: AIRulesGovernance の `.claude/settings.local.json` には Stop/UserPromptSubmit hooks がない。
このリポジトリでの作業セッションは context compression の恩恵を受けられない。

**判断**: bootstrap.ps1 を使えば対処可能だが、ガバナンスリポジトリへの自動書き込みを
慎重に検討したいため未実施。必要なら `.\SciContextCompressor\bootstrap.ps1 -Target .` を実行。

---

### 問題 5 — SciContextCompressor の settings.json が python3 (相対) を使用 (把握)

**発見**: SciContextCompressor の `.claude/settings.json` の hooks コマンドが
`python3 hooks/...` (PATH 依存) になっており、native Windows では機能しない可能性がある。

**対処**: bootstrap.ps1 を SciContextCompressor に対して `-ForceReinstallHooks` 付きで実行すれば
`C:\Python313\python.exe hooks/...` に修正される。

---

## CLAUDE.md 変更サマリー

| 変更箇所 | 変更前 | 変更後 |
|---|---|---|
| Section 9, item 6 | (存在しない) | bootstrap-additions.md 参照追加 |
| Section 18, task tiers 行 | `see docs/CURSOR_PAL_COST_TIERED_AGENTS.md (e.g. universal-tools)` | `L0-L4 (L0 = trivial/no-AI, L4 = complex/multi-model)` |
| Section 18, iterative data 行 | `— see project docs/CURSOR_PAL_COST_TIERED_AGENTS.md` | 末尾参照を削除 |

同じ変更を `SciContextCompressor/CLAUDE.md` にも同期適用済み (deploy.ps1 実行前の手動同期)。

---

## 次回 deploy.ps1 実行時の注意

変更済み `CLAUDE.md` (Section 9 item 6、Section 18 修正) が全リポジトリに配信される。
他リポジトリに `CLAUDE_LOCAL.md` がある場合、deploy.ps1 が参照注記を自動追記する。

---

## 参照

- `deploy.ps1` — 配信スクリプト
- `local/config.ps1` — ReposDir 設定 (`C:\gitkraken`)
- `SciContextCompressor/docs/bootstrap-improvements-2026-05-03.md` — hooks 改善記録
