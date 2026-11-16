<#
.SYNOPSIS
    Production Android APK (split-per-abi) and AAB (App Bundle) release build script for Pro Peloton Manager.

.DESCRIPTION
    Executes the full release pipeline for Android phones and tablets:
      1. Validates environment, pubspec.yaml metadata, Android Gradle setup, and resource shrinking (`isShrinkResources` + `isMinifyEnabled`).
      2. Verifies presence and GLB binary header integrity of all 3D assets under assets/3d/.
      3. Restores Flutter dependencies and runs `flutter test` (with configurable timeout).
      4. Compiles optimized split-per-abi APKs (`flutter build apk --release --split-per-abi`).
      5. Compiles Play Store App Bundle (`flutter build appbundle --release`) with unused resource shrinking enabled.
      6. Verifies generated `.apk` and `.aab` artifacts, copies them to the output directory with versioned names,
         generates `BUILD_MANIFEST.txt`, and writes SHA-256 checksums.

.PARAMETER ProjectRoot
    Root directory of the Flutter project. Defaults to the parent of the scripts/ directory.

.PARAMETER OutputDir
    Destination directory for the distributable `.apk`, `.aab`, `BUILD_MANIFEST.txt`, and `.sha256` files.
    Defaults to `<ProjectRoot>\dist\android`.

.PARAMETER Version
    Optional version override. Defaults to the `version:` field in pubspec.yaml.

.PARAMETER TestTimeout
    Timeout passed to `flutter test --timeout`. Defaults to `30s`.

.PARAMETER SkipTests
    Skips running `flutter test`.

.PARAMETER SkipBuild
    Skips both `flutter build apk` and `flutter build appbundle` (useful for packaging existing build outputs).

.PARAMETER SkipApk
    Skips building and packaging split-per-abi `.apk` files.

.PARAMETER SkipAab
    Skips building and packaging the `.aab` App Bundle.

.PARAMETER Clean
    Runs `flutter clean` before building.

.PARAMETER Obfuscate
    Enables Dart code obfuscation and split debug info (`--obfuscate --split-debug-info`).

.PARAMETER AllowMissingAssets
    Downgrades missing or invalid 3D asset checks from a fatal error to a warning.

.PARAMETER DryRun
    Validates environment, pubspec.yaml, Android Gradle resource shrinking config, and 3D assets
    without executing tests, build, or packaging.

.EXAMPLE
    .\scripts\build_android_apk_aab.ps1

.EXAMPLE
    .\scripts\build_android_apk_aab.ps1 -Clean -Obfuscate -OutputDir "dist\android_release"

.EXAMPLE
    .\scripts\build_android_apk_aab.ps1 -DryRun
#>

[CmdletBinding()]
param(
    [string]$ProjectRoot = "",
    [string]$OutputDir = "",
    [string]$Version = "",
    [string]$TestTimeout = "30s",
    [switch]$SkipTests,
    [switch]$SkipBuild,
    [switch]$SkipApk,
    [switch]$SkipAab,
    [switch]$Clean,
    [switch]$Obfuscate,
    [switch]$AllowMissingAssets,
    [switch]$DryRun
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

function Fail-Build {
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
            Fail-Build "$Description failed with exit code $code." $code
        }
    }
    finally {
        Pop-Location
    }
}

function Get-PubspecMetadata {
    param([Parameter(Mandatory)][string]$PubspecPath)

    if (-not (Test-Path -LiteralPath $PubspecPath -PathType Leaf)) {
        Fail-Build "pubspec.yaml not found at '$PubspecPath'."
    }

    $content = Get-Content -LiteralPath $PubspecPath -Raw -Encoding UTF8
    $name = "pro_peloton_manager"
    $version = "0.1.0+1"

    if ($content -match '(?m)^name:\s*([^\s#]+)') {
        $name = $Matches[1].Trim().Trim('"').Trim("'")
    }
    if ($content -match '(?m)^version:\s*([^\s#]+)') {
        $version = $Matches[1].Trim().Trim('"').Trim("'")
    }

    return [PSCustomObject]@{
        Name    = $name
        Version = $version
    }
}

function Test-AndroidResourceShrinking {
    param([Parameter(Mandatory)][string]$RootPath)

    $ktsPath = Join-Path $RootPath "android\app\build.gradle.kts"
    $groovyPath = Join-Path $RootPath "android\app\build.gradle"

    $gradlePath = $null
    if (Test-Path -LiteralPath $ktsPath -PathType Leaf) {
        $gradlePath = $ktsPath
    }
    elseif (Test-Path -LiteralPath $groovyPath -PathType Leaf) {
        $gradlePath = $groovyPath
    }
    else {
        Fail-Build "Neither 'android/app/build.gradle.kts' nor 'android/app/build.gradle' was found."
    }

    $content = Get-Content -LiteralPath $gradlePath -Raw -Encoding UTF8
    $hasMinify = ($content -match '(?m)\b(isMinifyEnabled\s*=\s*true|minifyEnabled\s+true)\b')
    $hasShrink = ($content -match '(?m)\b(isShrinkResources\s*=\s*true|shrinkResources\s+true)\b')

    if (-not ($hasMinify -and $hasShrink)) {
        Fail-Build "Android release resource shrinking is not enabled in '$gradlePath'. Ensure both 'isMinifyEnabled = true' (minifyEnabled true) and 'isShrinkResources = true' (shrinkResources true) are set in buildTypes.release."
    }

    Write-Success "Verified Android release resource shrinking & R8 minification in '$gradlePath'."
    return $gradlePath
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
        # glTF binary magic header: 'g','l','T','F' (0x46546C67 LE)
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

    Write-StepHeader "Step 2: Verifying 3D Assets (assets/3d/)"

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
            Fail-Build "3D asset verification failed with $($issues.Count) issue(s). Run Blender asset pipeline or pass -AllowMissingAssets."
        }
    }

    $totalMb = [Math]::Round($totalBytes / 1MB, 2)
    Write-Success "Verified $($allGlbFiles.Count) .glb 3D assets ($totalMb MB total)."

    return [PSCustomObject]@{
        GlbCount   = $allGlbFiles.Count
        TotalBytes = $totalBytes
        TotalMb    = $totalMb
    }
}

function Write-Sha256File {
    param([Parameter(Mandatory)][string]$FilePath)

    $fileInfo = Get-Item -LiteralPath $FilePath
    $hashObj = Get-FileHash -LiteralPath $FilePath -Algorithm SHA256
    $hashHex = $hashObj.Hash.ToLowerInvariant()
    $shaPath = "$FilePath.sha256"
    $shaLine = "$hashHex  $($fileInfo.Name)"
    Set-Content -LiteralPath $shaPath -Value $shaLine -Encoding ASCII

    return [PSCustomObject]@{
        FileName = $fileInfo.Name
        SizeMb   = [Math]::Round($fileInfo.Length / 1MB, 2)
        Sha256   = $hashHex
        ShaPath  = $shaPath
    }
}

# ==============================================================================
# Main Execution Pipeline
# ==============================================================================

if ($SkipApk -and $SkipAab -and -not $DryRun) {
    Fail-Build "Both -SkipApk and -SkipAab were specified; nothing to build or package."
}

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}
else {
    $ProjectRoot = (Resolve-Path $ProjectRoot).Path
}

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $ProjectRoot "dist\android"
}

Write-StepHeader "Step 1: Validating Environment, Android Gradle & Project Metadata"
Write-Info "Project root: $ProjectRoot"
Write-Info "Output dir:   $OutputDir"

$pubspecPath = Join-Path $ProjectRoot "pubspec.yaml"
$meta = Get-PubspecMetadata -PubspecPath $pubspecPath

$resolvedVersion = if ([string]::IsNullOrWhiteSpace($Version)) { $meta.Version } else { $Version }
$safeVersionForFile = $resolvedVersion -replace '[^0-9A-Za-z\.\-_]', '-'

Write-Success "Detected project '$($meta.Name)' version '$resolvedVersion'."

$flutterCmd = Get-Command "flutter" -ErrorAction SilentlyContinue
if ($null -eq $flutterCmd) {
    Fail-Build "Flutter CLI ('flutter') was not found in PATH. Install Flutter SDK and add it to PATH."
}
Write-Info "Flutter CLI: $($flutterCmd.Source)"

$androidDir = Join-Path $ProjectRoot "android"
if (-not (Test-Path -LiteralPath $androidDir -PathType Container)) {
    Fail-Build "Android project directory ('android/') not found. Run 'flutter create --platforms=android .' first."
}
Write-Success "Android directory found at '$androidDir'."

$gradleConfigPath = Test-AndroidResourceShrinking -RootPath $ProjectRoot
$assetSummary = Assert-3dAssetsPresent -RootPath $ProjectRoot -AllowMissing:$AllowMissingAssets

if ($DryRun) {
    Write-StepHeader "Dry Run Complete"
    Write-Success "All pre-flight checks passed (Project: $($meta.Name), Version: $resolvedVersion, Gradle: $gradleConfigPath, 3D Assets: $($assetSummary.GlbCount) .glb / $($assetSummary.TotalMb) MB)."
    $script:Stopwatch.Stop()
    exit 0
}

Write-StepHeader "Step 3: Restoring Dependencies & Running Tests"
Invoke-CheckedCommand -FilePath "flutter" -Arguments @("pub", "get") -WorkingDirectory $ProjectRoot -Description "flutter pub get"
Write-Success "Dependencies restored."

if (-not $SkipTests) {
    Invoke-CheckedCommand -FilePath "flutter" -Arguments @("test", "--timeout", $TestTimeout) -WorkingDirectory $ProjectRoot -Description "flutter test"
    Write-Success "All Flutter tests passed."
}
else {
    Write-Warn "Skipping 'flutter test' because -SkipTests was specified."
}

$debugSymbolsDir = Join-Path $OutputDir "symbols-v$safeVersionForFile"

if (-not $SkipBuild) {
    Write-StepHeader "Step 4: Building Android Release Artifacts (APK Split-Per-ABI & AAB)"

    if ($Clean) {
        Invoke-CheckedCommand -FilePath "flutter" -Arguments @("clean") -WorkingDirectory $ProjectRoot -Description "flutter clean"
        Invoke-CheckedCommand -FilePath "flutter" -Arguments @("pub", "get") -WorkingDirectory $ProjectRoot -Description "flutter pub get"
    }

    $extraFlags = @()
    if ($Obfuscate) {
        if (-not (Test-Path -LiteralPath $debugSymbolsDir -PathType Container)) {
            New-Item -ItemType Directory -Path $debugSymbolsDir -Force | Out-Null
        }
        $extraFlags = @("--obfuscate", "--split-debug-info=$debugSymbolsDir")
        Write-Info "Code obfuscation enabled; split debug symbols -> $debugSymbolsDir"
    }

    if (-not $SkipApk) {
        $apkArgs = @("build", "apk", "--release", "--split-per-abi") + $extraFlags
        Invoke-CheckedCommand -FilePath "flutter" -Arguments $apkArgs -WorkingDirectory $ProjectRoot -Description "flutter build apk --release --split-per-abi"
        Write-Success "Android split-per-abi APK build completed."
    }
    else {
        Write-Warn "Skipping split-per-abi APK build because -SkipApk was specified."
    }

    if (-not $SkipAab) {
        $aabArgs = @("build", "appbundle", "--release") + $extraFlags
        Invoke-CheckedCommand -FilePath "flutter" -Arguments $aabArgs -WorkingDirectory $ProjectRoot -Description "flutter build appbundle --release"
        Write-Success "Android App Bundle (.aab) build completed with resource shrinking."
    }
    else {
        Write-Warn "Skipping AAB build because -SkipAab was specified."
    }
}
else {
    Write-Warn "Skipping Android compilation because -SkipBuild was specified."
}

Write-StepHeader "Step 5: Verifying & Packaging Android Artifacts"

if (-not (Test-Path -LiteralPath $OutputDir -PathType Container)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$packagedRecords = New-Object System.Collections.Generic.List[object]

if (-not $SkipApk) {
    $apkDir = Join-Path $ProjectRoot "build\app\outputs\flutter-apk"
    if (-not (Test-Path -LiteralPath $apkDir -PathType Container)) {
        Fail-Build "Expected APK output directory not found at '$apkDir'."
    }

    $splitApks = @(Get-ChildItem -LiteralPath $apkDir -Filter "app-*-release.apk" -File | Sort-Object Name)
    if ($splitApks.Count -eq 0) {
        Fail-Build "No split-per-abi release APKs (app-*-release.apk) found in '$apkDir'."
    }

    foreach ($apk in $splitApks) {
        if ($apk.Length -le 0) {
            Fail-Build "Generated APK is empty (0 bytes): $($apk.FullName)"
        }

        $abiTag = $apk.BaseName -replace '^app-', '' -replace '-release$', ''
        $destApkName = "$($meta.Name)-v$safeVersionForFile-android-$abiTag.apk"
        $destApkPath = Join-Path $OutputDir $destApkName
        Copy-Item -LiteralPath $apk.FullName -Destination $destApkPath -Force

        $record = Write-Sha256File -FilePath $destApkPath
        $packagedRecords.Add($record)
        Write-Success "Packaged APK [$abiTag]: $($record.FileName) ($($record.SizeMb) MB)"
    }
}

if (-not $SkipAab) {
    $aabPath = Join-Path $ProjectRoot "build\app\outputs\bundle\release\app-release.aab"
    if (-not (Test-Path -LiteralPath $aabPath -PathType Leaf)) {
        Fail-Build "Expected Android App Bundle not found at '$aabPath'."
    }

    $aabInfo = Get-Item -LiteralPath $aabPath
    if ($aabInfo.Length -le 0) {
        Fail-Build "Generated AAB is empty (0 bytes): $aabPath"
    }

    $destAabName = "$($meta.Name)-v$safeVersionForFile-android.aab"
    $destAabPath = Join-Path $OutputDir $destAabName
    Copy-Item -LiteralPath $aabPath -Destination $destAabPath -Force

    $record = Write-Sha256File -FilePath $destAabPath
    $packagedRecords.Add($record)
    Write-Success "Packaged AAB: $($record.FileName) ($($record.SizeMb) MB)"
}

$gitCommit = "unknown"
$gitCmd = Get-Command "git" -ErrorAction SilentlyContinue
if ($null -ne $gitCmd) {
    Push-Location $ProjectRoot
    try {
        $rev = (& git rev-parse --short HEAD 2>$null)
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($rev)) {
            $gitCommit = $rev.Trim()
        }
    }
    finally {
        Pop-Location
    }
}

$manifestLines = New-Object System.Collections.Generic.List[string]
$manifestLines.Add("Pro Peloton Manager - Android Release Manifest")
$manifestLines.Add("================================================")
$manifestLines.Add("App Name           : $($meta.Name)")
$manifestLines.Add("Version            : $resolvedVersion")
$manifestLines.Add("Git Commit         : $gitCommit")
$manifestLines.Add("Built At (UTC)     : $([DateTime]::UtcNow.ToString('yyyy-MM-dd HH:mm:ss')) UTC")
$manifestLines.Add("Resource Shrinking : Enabled (isMinifyEnabled=true, isShrinkResources=true)")
$manifestLines.Add("APK Split-Per-ABI  : $(-not $SkipApk)")
$manifestLines.Add("App Bundle (.aab)  : $(-not $SkipAab)")
$manifestLines.Add("Obfuscation        : $Obfuscate")
$manifestLines.Add("3D Assets (.glb)   : $($assetSummary.GlbCount) files ($($assetSummary.TotalMb) MB)")
$manifestLines.Add("")
$manifestLines.Add("Artifacts:")

$sumLines = New-Object System.Collections.Generic.List[string]
foreach ($rec in $packagedRecords) {
    $manifestLines.Add("  - $($rec.FileName) ($($rec.SizeMb) MB) | SHA-256: $($rec.Sha256)")
    $sumLines.Add("$($rec.Sha256)  $($rec.FileName)")
}

$manifestPath = Join-Path $OutputDir "BUILD_MANIFEST.txt"
$sumsPath = Join-Path $OutputDir "SHA256SUMS.txt"
Set-Content -LiteralPath $manifestPath -Value $manifestLines -Encoding UTF8
Set-Content -LiteralPath $sumsPath -Value $sumLines -Encoding ASCII

$script:Stopwatch.Stop()
$elapsed = $script:Stopwatch.Elapsed.ToString("mm\:ss")

Write-StepHeader "Android Release Packaging Complete"
Write-Success "Output Dir : $OutputDir"
Write-Success "Artifacts  : $($packagedRecords.Count) file(s) packaged"
Write-Success "Manifest   : $manifestPath"
Write-Success "Checksums  : $sumsPath"
Write-Success "Elapsed    : $elapsed"
