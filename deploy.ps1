# deploy.ps1 — Deploy unified AI rules to all repositories
# Usage: .\deploy.ps1 [-DryRun] [-TargetRepo <name>]
#
# This script copies the unified rule files to all repositories under your repos directory
# and updates ~/.gemini/GEMINI.md with the unified rules.
#
# Configuration:
#   Set $env:AI_RULES_REPOS_DIR to your repositories parent directory.
#   Default: parent directory of this script's location (i.e., the directory containing AIRulesGovernance).

param(
    [switch]$DryRun,
    [string]$TargetRepo = ""
)

$SourceDir = $PSScriptRoot

# Load local config if present (gitignored — contains personal paths)
$localConfig = Join-Path $SourceDir "local\config.ps1"
if (Test-Path $localConfig) { . $localConfig }

# Defaults (overridden by local/config.ps1 or environment variables)
if (-not $ReposDir) {
    $ReposDir = if ($env:AI_RULES_REPOS_DIR) { $env:AI_RULES_REPOS_DIR } else { (Split-Path $PSScriptRoot -Parent) }
}
if (-not $GeminiDir) {
    $GeminiDir = "$env:USERPROFILE\.gemini"
}

# Files to deploy to each repo
$RepoFiles = @(
    @{ Source = "CLAUDE.md";     Dest = "CLAUDE.md" },
    @{ Source = "AGENTS.md";     Dest = "AGENTS.md" },
    @{ Source = ".cursorrules";  Dest = ".cursorrules" }
)

# Get target repositories
if ($TargetRepo) {
    $repos = @(Get-Item "$ReposDir\$TargetRepo" -ErrorAction Stop)
} else {
    $repos = Get-ChildItem $ReposDir -Directory | Where-Object {
        $_.Name -ne "AIRulesGovernance" -and
        ((Test-Path "$($_.FullName)\.git") -or (Test-Path "$($_.FullName)\.jj"))
    }
}

Write-Host "=== AI Rules Governance Deployment ===" -ForegroundColor Cyan
Write-Host "Source: $SourceDir" -ForegroundColor Gray
Write-Host "Targets: $($repos.Count) repositories" -ForegroundColor Gray
if ($DryRun) { Write-Host "[DRY RUN MODE]" -ForegroundColor Yellow }
Write-Host ""

# Deploy to repositories
foreach ($repo in $repos) {
    Write-Host "--- $($repo.Name) ---" -ForegroundColor Green

    foreach ($file in $RepoFiles) {
        $destPath = Join-Path $repo.FullName $file.Dest
        $sourcePath = Join-Path $SourceDir $file.Source

        if ($DryRun) {
            Write-Host "  [DRY] Would copy $($file.Source) -> $destPath"
        } else {
            Copy-Item $sourcePath $destPath -Force
            Write-Host "  Copied $($file.Source) -> $destPath"
        }
    }

    # If repo has CLAUDE_LOCAL.md, append a reference to CLAUDE.md
    $localPath = Join-Path $repo.FullName "CLAUDE_LOCAL.md"
    if (Test-Path $localPath) {
        $claudePath = Join-Path $repo.FullName "CLAUDE.md"
        $refLine = "`n`n---`n`n**NOTE**: This project has additional project-specific rules in CLAUDE_LOCAL.md. Read it before starting work.`n"
        if ($DryRun) {
            Write-Host "  [DRY] Would append CLAUDE_LOCAL.md reference to CLAUDE.md"
        } else {
            Add-Content $claudePath $refLine
            Write-Host "  Appended CLAUDE_LOCAL.md reference" -ForegroundColor Magenta
        }
    }
}

# Deploy GEMINI.md to ~/.gemini/ (concatenate Gemini header + CLAUDE.md content)
Write-Host ""
Write-Host "--- Global GEMINI.md ---" -ForegroundColor Green
$geminiHeader = Join-Path $SourceDir "GEMINI.md"
$claudeSource = Join-Path $SourceDir "CLAUDE.md"
$geminiDest = Join-Path $GeminiDir "GEMINI.md"

if ($DryRun) {
    Write-Host "  [DRY] Would generate GEMINI.md (header + CLAUDE.md) -> $geminiDest"
} else {
    if (-not (Test-Path $GeminiDir)) { New-Item $GeminiDir -ItemType Directory -Force | Out-Null }
    $headerContent = Get-Content $geminiHeader -Raw
    $claudeContent = Get-Content $claudeSource -Raw
    $combined = $headerContent + "`n`n---`n`n" + $claudeContent
    Set-Content $geminiDest $combined -Encoding UTF8
    Write-Host "  Generated GEMINI.md (header + CLAUDE.md rules) -> $geminiDest"
}

Write-Host ""
Write-Host "=== Deployment complete ===" -ForegroundColor Cyan
