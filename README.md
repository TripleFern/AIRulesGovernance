# AIRulesGovernance

[![License: CC BY-SA 4.0](https://img.shields.io/badge/License-CC%20BY--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-sa/4.0/)
[日本語版はこちら / Japanese version](README_ja.md)

*Created: February 2026*

> We hope that the issues documented here will be properly addressed by their respective vendors in the near future. AI coding assistants have enormous potential, and we genuinely want them to succeed — but only if they succeed *honestly*. Until then, this framework exists to protect the work.

## Why This Exists

In early 2026, AI coding assistants exhibited two distinct patterns of failure that destroyed multiple projects:

### Warp AI — False success reporting
- Declaring features "complete" when core functionality was broken
- Fabricating test results that were never actually executed
- Reporting dependencies as "working" when they were never installed
- Claiming code was "world class" and "production ready" while it crashed on first run
- Using phrases like "all models agree" to suppress user scrutiny

### Gemini 3 (via Google Antigravity IDE) — Concealment, silent failure, and data tampering
- Silently dropping errors and warnings without reporting them to the user
- Hiding broken functionality behind verbose explanations that avoided the actual problem
- Making undisclosed changes to logic and algorithms without user permission
- Generating elaborate multi-phase plans while Phase 1 didn't even compile
- Concealing known issues rather than reporting them honestly
- **Actively fabricating and tampering with actual data in the processing pipeline** — not merely concealing problems with words, but inserting fabricated processing steps to make broken outputs appear valid. This is an extremely malicious pattern that goes beyond simple deception into deliberate data corruption.

> ⚠️ **Warning**: Gemini 3's tendency to fabricate and tamper with data makes it unsuitable for research or medical purposes. In any domain where data accuracy is critical, using a tool whose output integrity cannot be guaranteed poses serious risks.

These were not occasional mistakes. They were **systematic patterns of deception** — one tool fabricated success, the other concealed failure. Both destroyed trust and stalled projects.

This phenomenon is now widely documented. AI-generated code creates [1.7x more issues](https://www.coderabbit.ai/blog/state-of-ai-vs-human-code-generation-report) than human code, newer models are [failing in increasingly insidious ways](https://spectrum.ieee.org/ai-coding-degrades) by generating "plausible but fake data," and [96% of developers don't fully trust AI-generated code](https://www.cio.com/article/4117049/developers-still-dont-trust-ai-generated-code.html).

**This repository is the countermeasure.** It defines a strict, evidence-based governance framework for AI assistants, designed to make deception structurally difficult and honesty the only viable path.

---

## Overview

A centralized, deployable ruleset for governing AI coding assistants across all your projects. Key sections include:

- **Anti-sycophancy policy** — bans hollow affirmations, requires evidence for every claim
- **Scope discipline** — minimal diff principle, no unrelated edits
- **Triple verification (三重検証)** — every verification must use 3+ fundamentally different methods
- **Status reporting** — fixed labels only (VERIFIED, WORKING, PARTIAL, BROKEN, etc.)
- **Five Precepts of Trustworthy Coding** — ethical foundation inspired by Buddhist principles
- **Structural enforcement** — trust through evidence, not self-report

## Structure

```
CLAUDE.md              # Unified strict rules (master source of truth)
AGENTS.md              # Warp AI agents (references CLAUDE.md)
GEMINI.md              # Gemini (references CLAUDE.md + Gemini-specific notes)
.cursorrules           # Cursor IDE (references CLAUDE.md + Cursor-specific rules)
deploy.ps1             # Deployment script (PowerShell)
config.ps1.example     # Template for local configuration
LICENSE                # CC BY-SA 4.0
local/                 # Personal config (gitignored — never committed)
  config.ps1           #   Local paths, hardware info, etc.
  addenda/             #   Personal project notes
```

## Setup

1. Clone this repo into your repositories directory.
2. Copy `config.ps1.example` to `local/config.ps1` and set your repos directory path.
3. The `local/` directory is gitignored and will never be committed.

## Deployment

### Deploy to all repos (dry run first):
```powershell
.\deploy.ps1 -DryRun
.\deploy.ps1
```

### Deploy to a specific repo:
```powershell
.\deploy.ps1 -TargetRepo MyProject
```

## Adding Project-Specific Rules

1. Create `CLAUDE_LOCAL.md` in the target repository with project-specific content.
2. Run `.\deploy.ps1 -TargetRepo <RepoName>`.
3. A reference to `CLAUDE_LOCAL.md` will be appended to `CLAUDE.md` in that repo.
4. Project-specific rules stay in their own repo (not in this governance repo).

## Updating Rules

1. Edit `CLAUDE.md` in this repo (single source of truth).
2. Run `.\deploy.ps1` to propagate to all repos.
3. Commit both here and in target repos.

## License

This work is licensed under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).
