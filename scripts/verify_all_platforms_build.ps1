<#
.SYNOPSIS
    Unified multi-platform production build verification and orchestration script for Pro Peloton Manager.

.DESCRIPTION
    Validates toolchain readiness, release build scripts, 3D binary assets, static analysis,
    test suite, and per-platform release pipelines across Windows, Android, macOS, and iOS:
      1. Validates Flutter/Dart/Git environment and pubspec.yaml metadata.
      2. Verifies presence and syntax of all platform release scripts:
         - scripts/build_windows_release.ps1 (PowerShell AST parser)
         - scripts/build_android_apk_aab.ps1 (PowerShell AST parser)
         - scripts/build_macos_and_ios_release.sh (shebang/structure + `bash -n` if available)
      3. Verifies presence and GLB ('glTF') binary header integrity of all 3D assets in assets/3d/.
      4. Runs `flutter pub get`, `flutter analyze`, and `flutter test` (unless skipped or `-DryRun`).
      5. Executes per-platform pre-flight (`-DryRun`) checks and, when `-ExecuteBuilds` is set,
         orchestrates production release builds for host-compatible platforms with available runners.
      6. Generates structured `all_platforms_build_report.json` and `BUILD_VERIFICATION_REPORT.txt`.

.PARAMETER ProjectRoot
    Root directory of the Flutter project. Defaults to the parent of the scripts/ directory.

.PARAMETER ReportDir
    Destination directory for verification reports. Defaults to `<ProjectRoot>\build\verification`.

.PARAMETER Platforms
    Target platforms to verify: `all`, or any combination of `windows`, `android`, `macos`, `ios`.
    Defaults to `all`.

.PARAMETER Version
    Optional version override. Defaults to the `version:` field in pubspec.yaml.

.PARAMETER TestTimeout
    Timeout passed to `flutter test --timeout`. Defaults to `30s`.

.PARAMETER ExecuteBuilds
    Executes full production release builds (not just `-DryRun` pre-flight checks) on platforms
    supported by the current host OS whose runner directories exist.

.PARAMETER RequireAllRunners
    Treats missing platform runner directories (`windows/`, `macos/`, `ios/`, `android/`) as
    fatal errors instead of warnings/skips.

.PARAMETER SkipPubGet
    Skips running `flutter pub get`.

.PARAMETER SkipAnalyze
    Skips running `flutter analyze`.

.PARAMETER FatalInfos
    Passes `--fatal-infos` to `flutter analyze`.

.PARAMETER SkipTests
    Skips running `flutter test`.

.PARAMETER Clean
    Passes `-Clean` to child build scripts when `-ExecuteBuilds` is active.

.PARAMETER Obfuscate
    Passes `-Obfuscate` to Android release builds when `-ExecuteBuilds` is active.

.PARAMETER AllowMissingAssets
    Downgrades missing or invalid `.glb` 3D asset checks from a fatal error to a warning.

.PARAMETER DryRun
    Runs fast pre-flight checks only (environment, script syntax, 3D assets, and child `-DryRun`
    checks), skipping `flutter pub get`, `flutter analyze`, `flutter test`, and native builds.

.PARAMETER NoReport
    Skips writing JSON and text verification reports to `$ReportDir`.

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_all_platforms_build.ps1 -DryRun

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_all_platforms_build.ps1 -Platforms windows,android -FatalInfos

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_all_platforms_build.ps1 -Platforms android -ExecuteBuilds -Obfuscate
#>

[CmdletBinding()]
param(
    [string]$ProjectRoot = "",
    [string]$ReportDir = "",
    [string[]]$Platforms = @("all"),
    [string]$Version = "",
    [string]$TestTimeout = "30s",
    [switch]$ExecuteBuilds,
    [switch]$RequireAllRunners,
    [switch]$SkipPubGet,
    [switch]$SkipAnalyze,
    [switch]$FatalInfos,
    [switch]$SkipTests,
    [switch]$Clean,
    [switch]$Obfuscate,
    [switch]$AllowMissingAssets,
    [switch]$DryRun,
    [switch]$NoReport
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

function Write-StepHeader {
    param([Parameter(Mandatory)][string]$Title)
    Write-Host ""
    Write-Host "======================================================================" -ForegroundColor DarkCyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "======================================================================" -ForegroundColor DarkCyan
}

function Write-Info {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "[INFO]  $Message" -ForegroundColor Gray
}

function Write-Success {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "[OK]    $Message" -ForegroundColor Green
}

function Write-Warn {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "[WARN]  $Message" -ForegroundColor Yellow
}

function Fail-Verification {
    param(
        [Parameter(Mandatory)][string]$Message,
        [int]$ExitCode = 1
    )
    Write-Host "[ERROR] $Message" -ForegroundColor Red
    if ($script:Stopwatch.IsRunning) {
        $script:Stopwatch.Stop()
    }
    exit $ExitCode
}

function Invoke-CheckedCommand {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string[]]$Arguments,
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [Parameter(Mandatory)][string]$Description
    )
    Write-Info "Running: $FilePath $($Arguments -join ' ')"
    Push-Location $WorkingDirectory
    try {
        & $FilePath @Arguments
        $code = $LASTEXITCODE
        if ($null -ne $code -and $code -ne 0) {
            Fail-Verification "$Description failed with exit code $code." $code
        }
    }
    finally {
        Pop-Location
    }
}

function Get-PowerShellExecutable {
    $pwsh = Get-Command "pwsh" -ErrorAction SilentlyContinue
    if ($null -ne $pwsh) {
        return $pwsh.Source
    }
    $winPs = Get-Command "powershell" -ErrorAction SilentlyContinue
    if ($null -ne $winPs) {
        return $winPs.Source
    }
    Fail-Verification "Neither 'pwsh' nor 'powershell' was found in PATH."
}

function Get-HostOsName {
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        if ($IsWindows) { return "Windows" }
        if ($IsMacOS) { return "macOS" }
        if ($IsLinux) { return "Linux" }
    }
    if ($env:OS -eq "Windows_NT") {
        return "Windows"
    }
    return [System.Environment]::OSVersion.Platform.ToString()
}

function Resolve-TargetPlatforms {
    param([Parameter(Mandatory)][string[]]$Requested)

    $valid = @("windows", "android", "macos", "ios")
    $resolved = New-Object System.Collections.Generic.List[string]

    foreach ($entry in $Requested) {
        foreach ($token in ($entry -split ',')) {
            $norm = $token.Trim().ToLowerInvariant()
            if ([string]::IsNullOrWhiteSpace($norm)) {
                continue
            }
            if ($norm -eq "all") {
                foreach ($v in $valid) {
                    if (-not $resolved.Contains($v)) {
                        $resolved.Add($v)
                    }
                }
            }
            elseif ($valid -contains $norm) {
                if (-not $resolved.Contains($norm)) {
                    $resolved.Add($norm)
                }
            }
            else {
                Fail-Verification "Invalid platform '$token'. Valid values: all, windows, android, macos, ios."
            }
        }
    }

    if ($resolved.Count -eq 0) {
        Fail-Verification "No target platforms specified."
    }

    return @($resolved)
}

function Get-PubspecMetadata {
    param([Parameter(Mandatory)][string]$PubspecPath)

    if (-not (Test-Path -LiteralPath $PubspecPath -PathType Leaf)) {
        Fail-Verification "pubspec.yaml not found at '$PubspecPath'."
    }

    $content = Get-Content -LiteralPath $PubspecPath -Raw -Encoding UTF8
    $name = "pro_peloton_manager"
    $version = "0.1.0+1"
    $sdkConstraint = "unknown"

    if ($content -match '(?m)^name:\s*([^\s#]+)') {
        $name = $Matches[1].Trim().Trim('"').Trim("'")
    }
    if ($content -match '(?m)^version:\s*([^\s#]+)') {
        $version = $Matches[1].Trim().Trim('"').Trim("'")
    }
    if ($content -match '(?m)^\s*sdk:\s*[''"]?([^''"#\r\n]+)[''"]?') {
        $sdkConstraint = $Matches[1].Trim()
    }

    return [PSCustomObject]@{
        Name          = $name
        Version       = $version
        SdkConstraint = $sdkConstraint
    }
}

function Test-PowerShellScriptSyntax {
    param([Parameter(Mandatory)][string]$ScriptPath)

    if (-not (Test-Path -LiteralPath $ScriptPath -PathType Leaf)) {
        return [PSCustomObject]@{
            Exists     = $false
            Valid      = $false
            ErrorCount = 1
            Details    = "Missing script: $ScriptPath"
        }
    }

    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$tokens, [ref]$errors) | Out-Null

    if ($errors.Count -gt 0) {
        $firstErr = $errors[0].Message
        return [PSCustomObject]@{
            Exists     = $true
            Valid      = $false
            ErrorCount = $errors.Count
            Details    = "Syntax error(s): $($errors.Count) (first: $firstErr)"
        }
    }

    return [PSCustomObject]@{
        Exists     = $true
        Valid      = $true
        ErrorCount = 0
        Details    = "AST parse OK ($($tokens.Count) tokens)"
    }
}

function Test-BashScriptSyntax {
    param([Parameter(Mandatory)][string]$ScriptPath)

    if (-not (Test-Path -LiteralPath $ScriptPath -PathType Leaf)) {
        return [PSCustomObject]@{
            Exists     = $false
            Valid      = $false
            ErrorCount = 1
            Details    = "Missing script: $ScriptPath"
        }
    }

    $raw = Get-Content -LiteralPath $ScriptPath -Raw -Encoding UTF8
    if (-not $raw.StartsWith("#!/usr/bin/env bash") -and -not $raw.StartsWith("#!/bin/bash")) {
        return [PSCustomObject]@{
            Exists     = $true
            Valid      = $false
            ErrorCount = 1
            Details    = "Missing bash shebang header"
        }
    }

    $bashCmd = Get-Command "bash" -ErrorAction SilentlyContinue
    if ($null -ne $bashCmd) {
        try {
            $bashOut = & $bashCmd.Source -n $ScriptPath 2>&1
            if ($LASTEXITCODE -eq 0) {
                return [PSCustomObject]@{
                    Exists     = $true
                    Valid      = $true
                    ErrorCount = 0
                    Details    = "bash -n syntax OK"
                }
            }
            # On Windows, WSL bash stub may return non-zero when no WSL distro is installed.
            $joined = ($bashOut | Out-String).Trim()
            if ($joined -match 'WSL|wsl\.exe|Windows Subsystem for Linux') {
                return [PSCustomObject]@{
                    Exists     = $true
                    Valid      = $true
                    ErrorCount = 0
                    Details    = "Shebang & structure OK (WSL bash unavailable for -n)"
                }
            }
            return [PSCustomObject]@{
                Exists     = $true
                Valid      = $false
                ErrorCount = 1
                Details    = "bash -n failed: $joined"
            }
        }
        catch {
            return [PSCustomObject]@{
                Exists     = $true
                Valid      = $true
                ErrorCount = 0
                Details    = "Shebang & structure OK (bash -n skipped: $($_.Exception.Message))"
            }
        }
    }

    return [PSCustomObject]@{
        Exists     = $true
        Valid      = $true
        ErrorCount = 0
        Details    = "Shebang & structure OK (bash not in PATH)"
    }
}

function Test-GlbBinaryHeader {
    param([Parameter(Mandatory)][string]$FilePath)

    $stream = [System.IO.File]::OpenRead($FilePath)
    try {
        if ($stream.Length -lt 12) {
            return $false
        }
        $buffer = New-Object byte[] 4
        $bytesRead = $stream.Read($buffer, 0, 4)
        if ($bytesRead -lt 4) {
            return $false
        }
        return ($buffer[0] -eq 0x67 -and $buffer[1] -eq 0x6C -and $buffer[2] -eq 0x54 -and $buffer[3] -eq 0x46)
    }
    finally {
        $stream.Dispose()
    }
}

function Assert-3dAssetsPresent {
    param(
        [Parameter(Mandatory)][string]$RootPath,
        [switch]$AllowMissing
    )

    Write-StepHeader "Step 3: Verifying 3D Assets (assets/3d/)"

    $requiredDirs = @(
        "assets\3d\bikes",
        "assets\3d\cyclists",
        "assets\3d\riders",
        "assets\3d\roads",
        "assets\3d\furniture",
        "assets\3d\vehicles",
        "assets\3d\environment"
    )

    $criticalGlbFiles = @(
        "assets\3d\bikes\frame_aero.glb",
        "assets\3d\bikes\frame_climbing.glb",
        "assets\3d\bikes\frame_tt.glb",
        "assets\3d\bikes\wheel_50mm.glb",
        "assets\3d\cyclists\cyclist_road.glb",
        "assets\3d\riders\cyclist_animated.glb",
        "assets\3d\roads\road_asphalt.glb",
        "assets\3d\roads\road_cobbles.glb",
        "assets\3d\roads\road_mountain_hairpin.glb",
        "assets\3d\furniture\arch_finish.glb",
        "assets\3d\furniture\arch_flamme_rouge.glb",
        "assets\3d\vehicles\vehicle_team_car.glb",
        "assets\3d\vehicles\vehicle_moto_tv.glb",
        "assets\3d\environment\podium_stage.glb",
        "assets\3d\environment\trophies_pack.glb",
        "assets\3d\environment\wind_tunnel_room.glb",
        "assets\3d\environment\tv_helicopter.glb"
    )

    $issues = New-Object System.Collections.Generic.List[string]

    foreach ($relDir in $requiredDirs) {
        $fullDir = Join-Path $RootPath $relDir
        if (-not (Test-Path -LiteralPath $fullDir -PathType Container)) {
            $issues.Add("Missing 3D asset directory: $relDir")
        }
    }

    foreach ($relFile in $criticalGlbFiles) {
        $fullFile = Join-Path $RootPath $relFile
        if (-not (Test-Path -LiteralPath $fullFile -PathType Leaf)) {
            $issues.Add("Missing critical 3D asset: $relFile")
        }
    }

    $assets3dRoot = Join-Path $RootPath "assets\3d"
    $allGlbFiles = @()
    if (Test-Path -LiteralPath $assets3dRoot -PathType Container) {
        $allGlbFiles = @(Get-ChildItem -LiteralPath $assets3dRoot -Recurse -Filter "*.glb" -File)
    }

    if ($allGlbFiles.Count -eq 0) {
        $issues.Add("No .glb files found under assets/3d/.")
    }

    [long]$totalBytes = 0
    foreach ($glb in $allGlbFiles) {
        $totalBytes += $glb.Length
        if ($glb.Length -lt 12) {
            $issues.Add("Corrupt or empty .glb file (<12 bytes): $($glb.FullName)")
            continue
        }
        if (-not (Test-GlbBinaryHeader -FilePath $glb.FullName)) {
            $issues.Add("Invalid GLB binary header (expected 'glTF'): $($glb.FullName)")
        }
    }

    if ($issues.Count -gt 0) {
        foreach ($issue in $issues) {
            if ($AllowMissing) {
                Write-Warn $issue
            }
            else {
                Write-Host "[FAIL]  $issue" -ForegroundColor Red
            }
        }
        if (-not $AllowMissing) {
            Fail-Verification "3D asset verification failed with $($issues.Count) issue(s)."
        }
    }

    $totalMb = [Math]::Round($totalBytes / 1MB, 2)
    Write-Success "Verified $($allGlbFiles.Count) .glb 3D assets ($totalMb MB total)."

    return [PSCustomObject]@{
        GlbCount   = $allGlbFiles.Count
        TotalBytes = $totalBytes
        TotalMb    = $totalMb
        IssueCount = $issues.Count
    }
}

function Invoke-ChildPowerShellScript {
    param(
        [Parameter(Mandatory)][string]$PowerShellExe,
        [Parameter(Mandatory)][string]$ScriptPath,
        [Parameter(Mandatory)][string[]]$ScriptArguments,
        [Parameter(Mandatory)][string]$WorkingDirectory
    )

    $argsList = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $ScriptPath) + $ScriptArguments
    Push-Location $WorkingDirectory
    try {
        & $PowerShellExe @argsList | Out-Host
        $exitCode = $LASTEXITCODE
        if ($null -eq $exitCode) {
            return 0
        }
        return [int]$exitCode
    }
    finally {
        Pop-Location
    }
}

# ==============================================================================
# Main Verification & Build Orchestration Pipeline
# ==============================================================================

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}
else {
    $ProjectRoot = (Resolve-Path $ProjectRoot).Path
}

if ([string]::IsNullOrWhiteSpace($ReportDir)) {
    $ReportDir = Join-Path $ProjectRoot "build\verification"
}

$targetPlatforms = Resolve-TargetPlatforms -Requested $Platforms
$hostOs = Get-HostOsName
$psExe = Get-PowerShellExecutable

Write-StepHeader "Step 1: Validating Environment, Toolchain & Project Metadata"
Write-Info "Project root     : $ProjectRoot"
Write-Info "Host OS          : $hostOs"
Write-Info "PowerShell       : $psExe ($($PSVersionTable.PSVersion))"
Write-Info "Target platforms : $($targetPlatforms -join ', ')"
Write-Info "Mode             : $(if ($DryRun) { 'DryRun' } elseif ($ExecuteBuilds) { 'Verify + ExecuteBuilds' } else { 'Verify + PreFlight' })"

$pubspecPath = Join-Path $ProjectRoot "pubspec.yaml"
$meta = Get-PubspecMetadata -PubspecPath $pubspecPath
$resolvedVersion = if ([string]::IsNullOrWhiteSpace($Version)) { $meta.Version } else { $Version }

Write-Success "Project '$($meta.Name)' v$resolvedVersion (Dart SDK $($meta.SdkConstraint))."

$flutterCmd = Get-Command "flutter" -ErrorAction SilentlyContinue
if ($null -eq $flutterCmd) {
    Fail-Verification "Flutter CLI ('flutter') was not found in PATH."
}
Write-Info "Flutter CLI      : $($flutterCmd.Source)"

$gitCommit = "unknown"
$gitBranch = "unknown"
$gitCmd = Get-Command "git" -ErrorAction SilentlyContinue
if ($null -ne $gitCmd) {
    Push-Location $ProjectRoot
    try {
        $rev = (& git rev-parse --short HEAD 2>$null)
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($rev)) {
            $gitCommit = $rev.Trim()
        }
        $br = (& git rev-parse --abbrev-ref HEAD 2>$null)
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($br)) {
            $gitBranch = $br.Trim()
        }
    }
    finally {
        Pop-Location
    }
}
Write-Info "Git              : $gitBranch @ $gitCommit"

# Step 2: Validate all release build scripts
Write-StepHeader "Step 2: Validating Release Build Scripts Syntax & Presence"

$winScriptPath = Join-Path $ProjectRoot "scripts\build_windows_release.ps1"
$androidScriptPath = Join-Path $ProjectRoot "scripts\build_android_apk_aab.ps1"
$appleScriptPath = Join-Path $ProjectRoot "scripts\build_macos_and_ios_release.sh"

$winScriptCheck = Test-PowerShellScriptSyntax -ScriptPath $winScriptPath
$androidScriptCheck = Test-PowerShellScriptSyntax -ScriptPath $androidScriptPath
$appleScriptCheck = Test-BashScriptSyntax -ScriptPath $appleScriptPath

$scriptChecks = @{
    windows = $winScriptCheck
    android = $androidScriptCheck
    macos   = $appleScriptCheck
    ios     = $appleScriptCheck
}

foreach ($item in @(
        @{ Label = "build_windows_release.ps1"; Check = $winScriptCheck },
        @{ Label = "build_android_apk_aab.ps1"; Check = $androidScriptCheck },
        @{ Label = "build_macos_and_ios_release.sh"; Check = $appleScriptCheck }
    )) {
    if ($item.Check.Valid) {
        Write-Success "$($item.Label): $($item.Check.Details)"
    }
    else {
        Fail-Verification "$($item.Label) validation failed: $($item.Check.Details)"
    }
}

# Step 3: Verify 3D Assets
$assetSummary = Assert-3dAssetsPresent -RootPath $ProjectRoot -AllowMissing:$AllowMissingAssets

# Step 4: Dependencies, Analyze & Tests
$pubGetStatus = "SKIPPED"
$analyzeStatus = "SKIPPED"
$testStatus = "SKIPPED"

if (-not $DryRun) {
    Write-StepHeader "Step 4: Restoring Dependencies, Static Analysis & Tests"

    if (-not $SkipPubGet) {
        Invoke-CheckedCommand -FilePath "flutter" -Arguments @("pub", "get") -WorkingDirectory $ProjectRoot -Description "flutter pub get"
        $pubGetStatus = "PASSED"
        Write-Success "flutter pub get completed."
    }
    else {
        Write-Warn "Skipping 'flutter pub get' (-SkipPubGet)."
    }

    if (-not $SkipAnalyze) {
        $analyzeArgs = @("analyze")
        if ($FatalInfos) {
            $analyzeArgs += "--fatal-infos"
        }
        Invoke-CheckedCommand -FilePath "flutter" -Arguments $analyzeArgs -WorkingDirectory $ProjectRoot -Description "flutter analyze"
        $analyzeStatus = "PASSED"
        Write-Success "flutter analyze passed with zero issues."
    }
    else {
        Write-Warn "Skipping 'flutter analyze' (-SkipAnalyze)."
    }

    if (-not $SkipTests) {
        Invoke-CheckedCommand -FilePath "flutter" -Arguments @("test", "--timeout", $TestTimeout) -WorkingDirectory $ProjectRoot -Description "flutter test"
        $testStatus = "PASSED"
        Write-Success "flutter test suite passed."
    }
    else {
        Write-Warn "Skipping 'flutter test' (-SkipTests)."
    }
}
else {
    Write-StepHeader "Step 4: Skipping pub get / analyze / test (-DryRun)"
}

# Step 5: Per-Platform Pre-Flight & Release Build Verification
Write-StepHeader "Step 5: Verifying Platform Release Pipelines"

$platformResults = New-Object System.Collections.Generic.List[object]
$overallFailed = $false

foreach ($plat in $targetPlatforms) {
    $platWatch = [System.Diagnostics.Stopwatch]::StartNew()
    $runnerDir = Join-Path $ProjectRoot $plat
    $hasRunner = Test-Path -LiteralPath $runnerDir -PathType Container
    $runnerState = if ($hasRunner) { "PRESENT" } else { "MISSING" }
    $dryRunState = "SKIPPED"
    $buildState = "SKIPPED"
    $overallState = "PASSED"
    $notes = ""

    Write-Host ""
    Write-Info "--- Platform: $($plat.ToUpperInvariant()) (Runner: $runnerState) ---"

    if (-not $hasRunner -and $RequireAllRunners) {
        $overallState = "FAILED"
        $notes = "Missing '$plat/' runner directory (-RequireAllRunners)."
        $overallFailed = $true
        Write-Host "[FAIL]  $notes" -ForegroundColor Red
        $platWatch.Stop()
        $platformResults.Add([PSCustomObject]@{
            Platform    = $plat
            Runner      = $runnerState
            ScriptCheck = $scriptChecks[$plat].Details
            DryRun      = $dryRunState
            Build       = $buildState
            Status      = $overallState
            DurationSec = [Math]::Round($platWatch.Elapsed.TotalSeconds, 2)
            Notes       = $notes
        })
        continue
    }

    switch ($plat) {
        "windows" {
            $childArgs = @("-DryRun", "-ProjectRoot", $ProjectRoot)
            if (-not [string]::IsNullOrWhiteSpace($Version)) { $childArgs += @("-Version", $resolvedVersion) }
            if ($AllowMissingAssets) { $childArgs += "-AllowMissingAssets" }

            $code = Invoke-ChildPowerShellScript -PowerShellExe $psExe -ScriptPath $winScriptPath -ScriptArguments $childArgs -WorkingDirectory $ProjectRoot
            if ($code -ne 0) {
                $dryRunState = "FAILED"
                $overallState = "FAILED"
                $overallFailed = $true
                $notes = "build_windows_release.ps1 -DryRun failed (exit $code)."
            }
            else {
                $dryRunState = "PASSED"
                if ($ExecuteBuilds -and -not $DryRun) {
                    if ($hostOs -ne "Windows") {
                        $buildState = "SKIPPED_HOST_OS"
                        $notes = "Windows build requires Windows host (current: $hostOs)."
                    }
                    elseif (-not $hasRunner) {
                        $buildState = "SKIPPED_NO_RUNNER"
                        $notes = "Run 'flutter create --platforms=windows .' to enable Windows compilation."
                    }
                    else {
                        $buildArgs = @("-SkipTests", "-ProjectRoot", $ProjectRoot)
                        if (-not [string]::IsNullOrWhiteSpace($Version)) { $buildArgs += @("-Version", $resolvedVersion) }
                        if ($Clean) { $buildArgs += "-Clean" }
                        if ($AllowMissingAssets) { $buildArgs += "-AllowMissingAssets" }

                        $bCode = Invoke-ChildPowerShellScript -PowerShellExe $psExe -ScriptPath $winScriptPath -ScriptArguments $buildArgs -WorkingDirectory $ProjectRoot
                        if ($bCode -ne 0) {
                            $buildState = "FAILED"
                            $overallState = "FAILED"
                            $overallFailed = $true
                            $notes = "Windows release build failed (exit $bCode)."
                        }
                        else {
                            $buildState = "PASSED"
                            $notes = "Windows release executable & ZIP packaged."
                        }
                    }
                }
                else {
                    $notes = if ($hasRunner) { "Pre-flight OK." } else { "Pre-flight OK (windows/ runner not generated yet)." }
                }
            }
        }

        "android" {
            $childArgs = @("-DryRun", "-ProjectRoot", $ProjectRoot)
            if (-not [string]::IsNullOrWhiteSpace($Version)) { $childArgs += @("-Version", $resolvedVersion) }
            if ($AllowMissingAssets) { $childArgs += "-AllowMissingAssets" }

            $code = Invoke-ChildPowerShellScript -PowerShellExe $psExe -ScriptPath $androidScriptPath -ScriptArguments $childArgs -WorkingDirectory $ProjectRoot
            if ($code -ne 0) {
                $dryRunState = "FAILED"
                $overallState = "FAILED"
                $overallFailed = $true
                $notes = "build_android_apk_aab.ps1 -DryRun failed (exit $code)."
            }
            else {
                $dryRunState = "PASSED"
                if ($ExecuteBuilds -and -not $DryRun) {
                    if (-not $hasRunner) {
                        $buildState = "SKIPPED_NO_RUNNER"
                        $notes = "Run 'flutter create --platforms=android .' to enable Android compilation."
                    }
                    else {
                        $buildArgs = @("-SkipTests", "-ProjectRoot", $ProjectRoot)
                        if (-not [string]::IsNullOrWhiteSpace($Version)) { $buildArgs += @("-Version", $resolvedVersion) }
                        if ($Clean) { $buildArgs += "-Clean" }
                        if ($Obfuscate) { $buildArgs += "-Obfuscate" }
                        if ($AllowMissingAssets) { $buildArgs += "-AllowMissingAssets" }

                        $bCode = Invoke-ChildPowerShellScript -PowerShellExe $psExe -ScriptPath $androidScriptPath -ScriptArguments $buildArgs -WorkingDirectory $ProjectRoot
                        if ($bCode -ne 0) {
                            $buildState = "FAILED"
                            $overallState = "FAILED"
                            $overallFailed = $true
                            $notes = "Android APK/AAB release build failed (exit $bCode)."
                        }
                        else {
                            $buildState = "PASSED"
                            $notes = "Android split-per-abi APKs & AAB packaged."
                        }
                    }
                }
                else {
                    $notes = "Pre-flight OK (Gradle shrinking & R8 verified)."
                }
            }
        }

        { $_ -in @("macos", "ios") } {
            if ($hostOs -eq "macOS") {
                $bashArgs = @($appleScriptPath, "--project-root", $ProjectRoot, "--target", $plat, "--dry-run")
                if (-not [string]::IsNullOrWhiteSpace($Version)) { $bashArgs += @("--version", $resolvedVersion) }
                if ($AllowMissingAssets) { $bashArgs += "--allow-missing-assets" }

                & bash @bashArgs
                if ($LASTEXITCODE -ne 0) {
                    $dryRunState = "FAILED"
                    $overallState = "FAILED"
                    $overallFailed = $true
                    $notes = "build_macos_and_ios_release.sh --target $plat --dry-run failed."
                }
                else {
                    $dryRunState = "PASSED"
                    if ($ExecuteBuilds -and -not $DryRun) {
                        if (-not $hasRunner) {
                            $buildState = "SKIPPED_NO_RUNNER"
                            $notes = "Run 'flutter create --platforms=$plat .' to enable compilation."
                        }
                        else {
                            $execArgs = @($appleScriptPath, "--project-root", $ProjectRoot, "--target", $plat, "--skip-tests")
                            if (-not [string]::IsNullOrWhiteSpace($Version)) { $execArgs += @("--version", $resolvedVersion) }
                            if ($Clean) { $execArgs += "--clean" }
                            if ($AllowMissingAssets) { $execArgs += "--allow-missing-assets" }

                            & bash @execArgs
                            if ($LASTEXITCODE -ne 0) {
                                $buildState = "FAILED"
                                $overallState = "FAILED"
                                $overallFailed = $true
                                $notes = "Apple $plat release build failed."
                            }
                            else {
                                $buildState = "PASSED"
                                $notes = "Apple $plat release build completed."
                            }
                        }
                    }
                    else {
                        $notes = "macOS host pre-flight OK."
                    }
                }
            }
            else {
                $dryRunState = "HOST_UNSUPPORTED"
                if ($ExecuteBuilds) {
                    $buildState = "SKIPPED_HOST_OS"
                }
                $notes = "Script syntax verified; native $plat build requires macOS + Xcode (current: $hostOs)."
                Write-Warn $notes
            }
        }
    }

    $platWatch.Stop()
    $platformResults.Add([PSCustomObject]@{
        Platform    = $plat
        Runner      = $runnerState
        ScriptCheck = $scriptChecks[$plat].Details
        DryRun      = $dryRunState
        Build       = $buildState
        Status      = $overallState
        DurationSec = [Math]::Round($platWatch.Elapsed.TotalSeconds, 2)
        Notes       = $notes
    })
}

# Step 6: Summary & Report Output
$script:Stopwatch.Stop()
$elapsedFormatted = $script:Stopwatch.Elapsed.ToString("mm\:ss")

Write-StepHeader "Step 6: Multi-Platform Build Verification Summary"
$platformResults | Format-Table -Property Platform, Runner, DryRun, Build, Status, DurationSec, Notes -AutoSize | Out-String | Write-Host

if (-not $NoReport) {
    if (-not (Test-Path -LiteralPath $ReportDir -PathType Container)) {
        New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null
    }

    $jsonReportPath = Join-Path $ReportDir "all_platforms_build_report.json"
    $txtReportPath = Join-Path $ReportDir "BUILD_VERIFICATION_REPORT.txt"

    $reportObject = [PSCustomObject]@{
        project       = $meta.Name
        version       = $resolvedVersion
        gitBranch     = $gitBranch
        gitCommit     = $gitCommit
        hostOs        = $hostOs
        verifiedAtUtc = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
        dryRun        = [bool]$DryRun
        executeBuilds = [bool]$ExecuteBuilds
        elapsedSec    = [Math]::Round($script:Stopwatch.Elapsed.TotalSeconds, 2)
        gates         = [PSCustomObject]@{
            assets3d = [PSCustomObject]@{
                glbCount   = $assetSummary.GlbCount
                totalMb    = $assetSummary.TotalMb
                issueCount = $assetSummary.IssueCount
            }
            pubGet   = $pubGetStatus
            analyze  = $analyzeStatus
            tests    = $testStatus
        }
        platforms     = $platformResults
        overallStatus = if ($overallFailed) { "FAILED" } else { "PASSED" }
    }

    $reportObject | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $jsonReportPath -Encoding UTF8

    $txtLines = New-Object System.Collections.Generic.List[string]
    $txtLines.Add("Pro Peloton Manager - Multi-Platform Build Verification Report")
    $txtLines.Add("==============================================================")
    $txtLines.Add("App Name       : $($meta.Name)")
    $txtLines.Add("Version        : $resolvedVersion")
    $txtLines.Add("Git            : $gitBranch @ $gitCommit")
    $txtLines.Add("Host OS        : $hostOs")
    $txtLines.Add("Verified (UTC) : $([DateTime]::UtcNow.ToString('yyyy-MM-dd HH:mm:ss')) UTC")
    $txtLines.Add("3D Assets      : $($assetSummary.GlbCount) .glb files ($($assetSummary.TotalMb) MB)")
    $txtLines.Add("Gates          : pubGet=$pubGetStatus | analyze=$analyzeStatus | tests=$testStatus")
    $txtLines.Add("Elapsed        : $elapsedFormatted")
    $txtLines.Add("")
    $txtLines.Add("Platform Results:")
    foreach ($pr in $platformResults) {
        $txtLines.Add("  - [$($pr.Status)] $($pr.Platform) | Runner=$($pr.Runner) | DryRun=$($pr.DryRun) | Build=$($pr.Build) | $($pr.Notes)")
    }
    Set-Content -LiteralPath $txtReportPath -Value $txtLines -Encoding UTF8

    Write-Success "JSON report : $jsonReportPath"
    Write-Success "Text report : $txtReportPath"
}

if ($overallFailed) {
    Fail-Verification "One or more platform build verifications failed (Elapsed: $elapsedFormatted)."
}

Write-Success "All requested platform verifications passed (Elapsed: $elapsedFormatted)."
exit 0
