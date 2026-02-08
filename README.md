# AIRulesGovernance

Centralized repository for managing AI assistant rules across all projects.

## Structure

```
CLAUDE.md          # Unified strict rules (master source of truth)
AGENTS.md          # Warp AI agents (references CLAUDE.md)
GEMINI.md          # Gemini (references CLAUDE.md + Gemini-specific notes)
.cursorrules       # Cursor IDE (references CLAUDE.md + Cursor-specific rules)
addenda/           # Project-specific addenda (appended during deployment)
  PhotoSelection.md
  AImgGUI.md
deploy.ps1         # Deployment script
```

## Deployment

### Deploy to all repos (dry run first):
```powershell
.\deploy.ps1 -DryRun
.\deploy.ps1
```

### Deploy to a specific repo:
```powershell
.\deploy.ps1 -TargetRepo AImgGUI
```

## Adding Project-Specific Rules

1. Create `addenda/<RepoName>.md` with project-specific content only.
2. Run `.\deploy.ps1 -TargetRepo <RepoName>`.
3. The addendum will be appended to CLAUDE.md in the target repo.

## Updating Rules

1. Edit `CLAUDE.md` in this repo (single source of truth).
2. Run `.\deploy.ps1` to propagate to all repos.
3. Commit both here and in target repos.
