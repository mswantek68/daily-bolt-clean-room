#!/usr/bin/env pwsh
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT
#Requires -Version 7.0

<#
.SYNOPSIS
    Validates the repository foundation.
.DESCRIPTION
    Confirms required foundation files, Git integrity, whitespace quality,
    and the absence of nested repositories or submodules.
.PARAMETER RepoRoot
    The repository root to validate.
.EXAMPLE
    ./scripts/Test-Repository.ps1
.NOTES
    Runs locally and in the repository validation workflow.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$RepoRoot = (git rev-parse --show-toplevel 2>$null)
)

$ErrorActionPreference = 'Stop'

#region Functions
function Test-RequiredFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Root
    )

    $RequiredPaths = @(
        'README.md'
        '.gitignore'
        '.markdownlint.json'
        '.github/workflows/validate.yml'
        'docs/clean-room-experiment.md'
    )

    $MissingPaths = @(
        $RequiredPaths | Where-Object {
            -not (Test-Path -LiteralPath (Join-Path $Root $_) -PathType Leaf)
        }
    )

    if ($MissingPaths.Count -gt 0) {
        throw "Required repository files are missing: $($MissingPaths -join ', ')"
    }
}

function Test-GitIntegrity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Root
    )

    $ResolvedRoot = (Resolve-Path -LiteralPath $Root).Path
    $GitRoot = (& git -C $ResolvedRoot rev-parse --show-toplevel).Trim()
    if ($LASTEXITCODE -ne 0) {
        throw 'The target directory is not a Git repository.'
    }

    if ((Resolve-Path -LiteralPath $GitRoot).Path -ne $ResolvedRoot) {
        throw "Repository root mismatch. Expected '$ResolvedRoot', found '$GitRoot'."
    }

    & git -C $ResolvedRoot rev-parse --verify HEAD 2>$null
    $HasCommit = $LASTEXITCODE -eq 0
    if ($HasCommit) {
        & git -C $ResolvedRoot diff --check HEAD
    }
    else {
        & git -C $ResolvedRoot diff --check --cached
    }
    if ($LASTEXITCODE -ne 0) {
        throw 'Git whitespace validation failed.'
    }

    $Gitlinks = @(& git -C $ResolvedRoot ls-files --stage | Where-Object {
            $_ -match '^160000 '
        })
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to inspect tracked files for Git submodules.'
    }
    if ($Gitlinks.Count -gt 0) {
        throw 'Git submodules are not permitted in the clean-room foundation.'
    }

    $NestedRepositories = @(
        Get-ChildItem -LiteralPath $ResolvedRoot -Directory -Recurse -Force |
            Where-Object {
                $_.Name -eq '.git' -and $_.FullName -ne (Join-Path $ResolvedRoot '.git')
            }
    )
    if ($NestedRepositories.Count -gt 0) {
        throw 'Nested Git repositories are not permitted.'
    }
}
#endregion Functions

#region Main Execution
if ($MyInvocation.InvocationName -ne '.') {
    try {
        if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
            throw 'Unable to determine the repository root.'
        }

        Test-RequiredFiles -Root $RepoRoot
        Test-GitIntegrity -Root $RepoRoot
        Write-Host 'Repository validation passed.' -ForegroundColor Green
        exit 0
    }
    catch {
        Write-Error -ErrorAction Continue "Repository validation failed: $($_.Exception.Message)"
        exit 1
    }
}
#endregion Main Execution
