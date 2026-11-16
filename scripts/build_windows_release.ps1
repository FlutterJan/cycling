<#
.SYNOPSIS
    Production Windows release build and packaging script for Pro Peloton Manager.

.DESCRIPTION
    Executes the full release pipeline for Windows desktop:
      1. Validates environment, pubspec.yaml metadata, and Windows runner setup.
      2. Verifies presence and GLB binary header integrity of all 3D assets under assets/3d/.
      3. Restores Flutter dependencies and runs `flutter test` (with configurable timeout).
      4. Compiles `flutter build windows --release`.
      5. Verifies the generated `.exe`, `.dll` libraries, and `data/` bundle.
      6. Packages the executable folder into a distributable `.zip` archive with SHA-256 checksum.

.PARAMETER ProjectRoot
    Root directory of the Flutter project. Defaults to the parent of the scripts/ directory.

.PARAMETER OutputDir
    Destination directory for the distributable `.zip` archive and `.sha256` checksum file.

.PARAMETER Version
    Optional version override. Defaults to the `version:` field in pubspec.yaml.

.PARAMETER TestTimeout
    Timeout passed to `flutter test --timeout`. Defaults to `30s`.

.PARAMETER SkipTests
    Skips running `flutter test`.

.PARAMETER SkipBuild
    Skips `flutter build windows --release` (useful for packaging an existing Release folder).

.PARAMETER Clean
    Runs `flutter clean` before building.

.PARAMETER AllowMissingAssets
    Downgrades missing or invalid 3D asset checks from a fatal error to a warning.

.PARAMETER DryRun
    Validates environment, pubspec.yaml, and 3D assets without executing tests, build, or packaging.

.EXAMPLE
    .\scripts\build_windows_release.ps1

.EXAMPLE
    .\scripts\build_windows_release.ps1 -Clean -OutputDir "dist\releases"

.EXAMPLE
    .\scripts\build_windows_release.ps1 -DryRun
#>

[CmdletBinding()]
param(
    [string]$ProjectRoot = "",
    [string]$OutputDir = "",
    [string]$Version = "",
    [string]$TestTimeout = "30s",
    [switch]$SkipTests,
    [switch]$SkipBuild,
    [switch]$Clean,
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

function Resolve-WindowsReleaseDir {
    param([Parameter(Mandatory)][string]$RootPath)

    $candidates = @(
        (Join-Path $RootPath "build\windows\x64\runner\Release"),
        (Join-Path $RootPath "build\windows\runner\Release")
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Container) {
            return $candidate
        }
    }

    return $null
}

# ==============================================================================
# Main Execution Pipeline
# ==============================================================================

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}
else {
    $ProjectRoot = (Resolve-Path $ProjectRoot).Path
}

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $ProjectRoot "dist\windows"
}

Write-StepHeader "Step 1: Validating Environment & Project Metadata"
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

$windowsDir = Join-Path $ProjectRoot "windows"
$hasWindowsRunner = Test-Path -LiteralPath $windowsDir -PathType Container
if (-not $hasWindowsRunner) {
    if ($DryRun -or $SkipBuild) {
        Write-Warn "Windows runner directory ('windows/') not found. Run 'flutter create --platforms=windows .' before building."
    }
    else {
        Fail-Build "Windows runner directory ('windows/') not found. Run 'flutter create --platforms=windows .' first."
    }
}
else {
    Write-Success "Windows runner directory found at '$windowsDir'."
}

$assetSummary = Assert-3dAssetsPresent -RootPath $ProjectRoot -AllowMissing:$AllowMissingAssets

if ($DryRun) {
    Write-StepHeader "Dry Run Complete"
    Write-Success "All pre-flight checks passed (Project: $($meta.Name), Version: $resolvedVersion, 3D Assets: $($assetSummary.GlbCount) .glb / $($assetSummary.TotalMb) MB)."
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

if (-not $SkipBuild) {
    Write-StepHeader "Step 4: Building Windows Release Executable"

    if ($Clean) {
        Invoke-CheckedCommand -FilePath "flutter" -Arguments @("clean") -WorkingDirectory $ProjectRoot -Description "flutter clean"
        Invoke-CheckedCommand -FilePath "flutter" -Arguments @("pub", "get") -WorkingDirectory $ProjectRoot -Description "flutter pub get"
    }

    Invoke-CheckedCommand -FilePath "flutter" -Arguments @("build", "windows", "--release") -WorkingDirectory $ProjectRoot -Description "flutter build windows --release"
    Write-Success "Windows release build completed."
}
else {
    Write-Warn "Skipping 'flutter build windows --release' because -SkipBuild was specified."
}

Write-StepHeader "Step 5: Verifying Build Output & Packaging ZIP Archive"

$releaseDir = Resolve-WindowsReleaseDir -RootPath $ProjectRoot
if ($null -eq $releaseDir) {
    Fail-Build "Windows Release directory not found under build\windows\x64\runner\Release or build\windows\runner\Release."
}
Write-Info "Release directory: $releaseDir"

$exeFiles = @(Get-ChildItem -LiteralPath $releaseDir -Filter "*.exe" -File)
if ($exeFiles.Count -eq 0) {
    Fail-Build "No .exe executable found in '$releaseDir'."
}

$dllFiles = @(Get-ChildItem -LiteralPath $releaseDir -Filter "*.dll" -File)
if ($dllFiles.Count -eq 0) {
    Fail-Build "No .dll runtime libraries found in '$releaseDir'."
}

$flutterDll = Join-Path $releaseDir "flutter_windows.dll"
if (-not (Test-Path -LiteralPath $flutterDll -PathType Leaf)) {
    Fail-Build "Required runtime library 'flutter_windows.dll' is missing from '$releaseDir'."
}

$dataDir = Join-Path $releaseDir "data"
if (-not (Test-Path -LiteralPath $dataDir -PathType Container)) {
    Fail-Build "Required 'data' directory is missing from '$releaseDir'."
}

Write-Success "Verified $($exeFiles.Count) executable(s) ($($exeFiles[0].Name)), $($dllFiles.Count) DLL(s), and data/ bundle."

if (-not (Test-Path -LiteralPath $OutputDir -PathType Container)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$archiveBaseName = "$($meta.Name)-v$safeVersionForFile-windows-x64"
$zipPath = Join-Path $OutputDir "$archiveBaseName.zip"
$shaPath = Join-Path $OutputDir "$archiveBaseName.zip.sha256"
$stagingDir = Join-Path ([System.IO.Path]::GetTempPath()) "ppm_win_pkg_$([Guid]::NewGuid().ToString('N'))"

try {
    New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null
    Write-Info "Staging release files to '$stagingDir'..."
    Copy-Item -Path (Join-Path $releaseDir "*") -Destination $stagingDir -Recurse -Force

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

    $manifestLines = @(
        "Pro Peloton Manager - Windows Release Manifest",
        "================================================",
        "App Name       : $($meta.Name)",
        "Version        : $resolvedVersion",
        "Git Commit     : $gitCommit",
        "Built At (UTC) : $([DateTime]::UtcNow.ToString('yyyy-MM-dd HH:mm:ss')) UTC",
        "Executable     : $($exeFiles[0].Name)",
        "DLL Count      : $($dllFiles.Count)",
        "3D Assets (.glb): $($assetSummary.GlbCount) files ($($assetSummary.TotalMb) MB)"
    )
    $manifestPath = Join-Path $stagingDir "BUILD_MANIFEST.txt"
    Set-Content -LiteralPath $manifestPath -Value $manifestLines -Encoding UTF8

    if (Test-Path -LiteralPath $zipPath -PathType Leaf) {
        Remove-Item -LiteralPath $zipPath -Force
    }

    Write-Info "Compressing archive to '$zipPath'..."
    Compress-Archive -Path (Join-Path $stagingDir "*") -DestinationPath $zipPath -CompressionLevel Optimal -Force

    if (-not (Test-Path -LiteralPath $zipPath -PathType Leaf)) {
        Fail-Build "Failed to create archive at '$zipPath'."
    }

    $zipInfo = Get-Item -LiteralPath $zipPath
    $zipSizeMb = [Math]::Round($zipInfo.Length / 1MB, 2)
    $hashObj = Get-FileHash -LiteralPath $zipPath -Algorithm SHA256
    $shaContent = "$($hashObj.Hash.ToLowerInvariant())  $($zipInfo.Name)"
    Set-Content -LiteralPath $shaPath -Value $shaContent -Encoding ASCII

    $script:Stopwatch.Stop()
    $elapsed = $script:Stopwatch.Elapsed.ToString("mm\:ss")

    Write-StepHeader "Windows Release Packaging Complete"
    Write-Success "Archive  : $zipPath ($zipSizeMb MB)"
    Write-Success "SHA-256  : $($hashObj.Hash.ToLowerInvariant())"
    Write-Success "Checksum : $shaPath"
    Write-Success "Elapsed  : $elapsed"
}
finally {
    if (Test-Path -LiteralPath $stagingDir -PathType Container) {
        Remove-Item -LiteralPath $stagingDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
