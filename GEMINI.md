# GEMINI.md - Unified AI Assistant Rules (for Gemini)

Version: 1.1.0
Created: 2026-02-08
Updated: 2026-02-09
Status: ACTIVE — Gemini MUST read and follow this document.

**NOTE**: When deployed to ~/.gemini/, this file is concatenated with CLAUDE.md content by deploy.ps1.
In the governance repository, this file contains only Gemini-specific additions.

---

## Gemini-Specific Notes

- Always use available documentation search tools or web search for API documentation before coding.
- `@Web` や `@docs` 機能が利用可能な場合、活用して最新情報を取得すること。
- 計画時、利用可能なレビューツールを用いて批判的評価を受けること（Section 13 参照）。
- Mermaid Diagram や図解で構造を可視化し、矛盾がないか点検すること。

---

## Verification Effort & Deep Understanding (CLAUDE.md SECTION 12A applies)

**CRITICAL (v1.1.0)**: The following requirements from CLAUDE.md SECTION 12A apply to all Gemini sessions:
- 検証にかける労力は、成果物を作る労力の**3倍～10倍**でなければならない。
- 原因や仕組みを理解したと主張する前に、「なぜ？」を最低3回（複雑な問題では最大10回）繰り返すこと。
- 各「なぜ」の回答は具体的でなければならない：ファイル名、関数名、行番号、データフローを挙げること。
- 「確認しました」と証拠なしに言うことはSECTION 1違反（絶対禁止事項）である。
- See CLAUDE.md SECTION 12A for full details.
