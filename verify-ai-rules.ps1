# verify-ai-rules.ps1 — Compare AGENTS.md / CLAUDE.md in each consumer repo to this repo's canonical copies.
# Usage: .\verify-ai-rules.ps1
#
# Rules:
#   - AGENTS.md must match canonical exactly (after normalizing line endings / BOM).
#   - CLAUDE.md must match canonical, OR canonical + deploy.ps1's CLAUDE_LOCAL.md reference block
#     when that repo contains CLAUDE_LOCAL.md.
#
# Configuration: same as deploy.ps1 (local\config.ps1, AI_RULES_REPOS_DIR).

$ErrorActionPreference = "Stop"
$SourceDir = $PSScriptRoot

$localConfig = Join-Path $SourceDir "local\config.ps1"
if (Test-Path $localConfig) { . $localConfig }

if (-not $ReposDir) {
    $ReposDir = if ($env:AI_RULES_REPOS_DIR) { $env:AI_RULES_REPOS_DIR } else { (Split-Path $SourceDir -Parent) }
}

# Must match deploy.ps1 exactly
$ClaudeLocalRefSuffix = "`n`n---`n`n**NOTE**: This project has additional project-specific rules in CLAUDE_LOCAL.md. Read it before starting work.`n"

function Get-NormalizedContent {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $raw = [System.IO.File]::ReadAllText($Path)
    if ($raw.Length -gt 0 -and [int][char]$raw[0] -eq 0xFEFF) {
        $raw = $raw.Substring(1)
    }
    $raw = $raw -replace "`r`n", "`n" -replace "`r", "`n"
    return $raw
}

function Test-ContentMatch {
    param(
        [string]$Actual,
        [string]$Expected,
        [string]$Label
    )
    if ($null -eq $Actual) { return @{ Ok = $false; Detail = "$Label missing" } }
    if ($Actual.Length -eq 0) { return @{ Ok = $false; Detail = "$Label empty" } }
    if ($Actual -eq $Expected) { return @{ Ok = $true; Detail = "match" } }
    $aHash = [System.BitConverter]::ToString(
        [System.Security.Cryptography.SHA256]::Create().ComputeHash(
            [System.Text.Encoding]::UTF8.GetBytes($Actual)
        )
    ).Replace("-", "").Substring(0, 16)
    $eHash = [System.BitConverter]::ToString(
        [System.Security.Cryptography.SHA256]::Create().ComputeHash(
            [System.Text.Encoding]::UTF8.GetBytes($Expected)
        )
    ).Replace("-", "").Substring(0, 16)
    return @{ Ok = $false; Detail = "diverges (actual SHA256 prefix $aHash, expected $eHash)" }
}

$canonAgents = Get-NormalizedContent (Join-Path $SourceDir "AGENTS.md")
$canonClaude = Get-NormalizedContent (Join-Path $SourceDir "CLAUDE.md")

if ($null -eq $canonAgents -or $null -eq $canonClaude) {
    Write-Error "Canonical AGENTS.md or CLAUDE.md missing under $SourceDir"
}

Write-Host "=== AI Rules verification ===" -ForegroundColor Cyan
Write-Host "Canonical source: $SourceDir" -ForegroundColor Gray
Write-Host "Repos directory:  $ReposDir" -ForegroundColor Gray
Write-Host ""

$repos = Get-ChildItem $ReposDir -Directory -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -ne "AIRulesGovernance" -and
    ((Test-Path "$($_.FullName)\.git") -or (Test-Path "$($_.FullName)\.jj"))
}

$results = @()

foreach ($repo in $repos) {
    $name = $repo.Name
    $agentsPath = Join-Path $repo.FullName "AGENTS.md"
    $claudePath = Join-Path $repo.FullName "CLAUDE.md"
    $localPath = Join-Path $repo.FullName "CLAUDE_LOCAL.md"

    $ag = Get-NormalizedContent $agentsPath
    $cl = Get-NormalizedContent $claudePath
    $hasLocal = Test-Path -LiteralPath $localPath

    $agResult = Test-ContentMatch -Actual $ag -Expected $canonAgents -Label "AGENTS.md"

    $expectedClaude = $canonClaude
    $claudeNote = "canonical only"
    if ($hasLocal) {
        $expectedClaude = $canonClaude + $ClaudeLocalRefSuffix
        $claudeNote = "canonical + CLAUDE_LOCAL.md deploy suffix"
    }

    $clResult = Test-ContentMatch -Actual $cl -Expected $expectedClaude -Label "CLAUDE.md"

    # Helpful secondary diagnosis for CLAUDE.md
    if (-not $clResult.Ok -and $null -ne $cl) {
        if ($cl -eq $canonClaude) {
            if ($hasLocal) {
                $clResult.Detail = "matches canonical only; missing deploy.ps1 CLAUDE_LOCAL.md reference block"
            }
        }
        elseif ($hasLocal -and $cl.StartsWith($canonClaude) -and $cl.Length -gt $canonClaude.Length) {
            $extra = $cl.Substring($canonClaude.Length)
            if ($extra -ne $ClaudeLocalRefSuffix) {
                $clResult.Detail = "has extra content after canonical body (not the standard CLAUDE_LOCAL.md suffix only)"
            }
        }
        elseif (-not $hasLocal -and $cl.StartsWith($canonClaude) -and $cl.Length -gt $canonClaude.Length) {
            $clResult.Detail = "has appended content but repo has no CLAUDE_LOCAL.md (unexpected extension)"
        }
    }

    $results += [PSCustomObject]@{
        Repo           = $name
        AGENTS         = if ($agResult.Ok) { "OK" } else { "DIFF" }
        CLAUDE         = if ($clResult.Ok) { "OK" } else { "DIFF" }
        CLAUDE_LOCAL   = if ($hasLocal) { "yes" } else { "no" }
        ExpectedClaude = $claudeNote
        AgentsDetail   = $agResult.Detail
        ClaudeDetail   = $clResult.Detail
    }
}

$diffCount = ($results | Where-Object { $_.AGENTS -eq "DIFF" -or $_.CLAUDE -eq "DIFF" }).Count
$okCount = $results.Count - $diffCount

Write-Host ("Checked {0} repositories. Match: {1}, Divergence: {2}." -f $results.Count, $okCount, $diffCount) -ForegroundColor $(if ($diffCount -eq 0) { "Green" } else { "Yellow" })
Write-Host ""

$results | Format-Table -AutoSize Repo, AGENTS, CLAUDE, CLAUDE_LOCAL

$diverged = $results | Where-Object { $_.AGENTS -eq "DIFF" -or $_.CLAUDE -eq "DIFF" }
if ($diverged) {
    Write-Host "--- Divergence details ---" -ForegroundColor Yellow
    foreach ($r in $diverged) {
        Write-Host "`n[$($r.Repo)]" -ForegroundColor Green
        if ($r.AGENTS -eq "DIFF") {
            Write-Host "  AGENTS.md: $($r.AgentsDetail)"
        }
        if ($r.CLAUDE -eq "DIFF") {
            Write-Host "  CLAUDE.md: $($r.ClaudeDetail)  (expected: $($r.ExpectedClaude))"
        }
    }
}

exit $(if ($diffCount -gt 0) { 1 } else { 0 })
