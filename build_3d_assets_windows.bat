@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul

set "ROOT_DIR=%~dp0"
if "%ROOT_DIR:~-1%"=="\" set "ROOT_DIR=%ROOT_DIR:~0,-1%"

set "MASTER_SCRIPT=%ROOT_DIR%\blender_scripts\build_all_assets_master.py"
set "MANIFEST_PATH=%ROOT_DIR%\assets\3d\asset_manifest.json"
set "LOG_PATH=%ROOT_DIR%\assets\3d\build_3d_assets.log"

if not exist "%ROOT_DIR%\assets\3d" mkdir "%ROOT_DIR%\assets\3d"

echo ===============================================================================
echo PRO PELOTON MANAGER - WINDOWS 3D ASSETS BUILDER (BLENDER 5.3.0)
echo ===============================================================================

set "BLENDER_EXE="
if defined BLENDER_PATH (
    if exist "%BLENDER_PATH%" set "BLENDER_EXE=%BLENDER_PATH%"
)
if not defined BLENDER_EXE (
    if exist "C:\Program Files\Blender Foundation\Blender 5.3\blender.exe" (
        set "BLENDER_EXE=C:\Program Files\Blender Foundation\Blender 5.3\blender.exe"
    )
)
if not defined BLENDER_EXE (
    for /f "delims=" %%I in ('where blender 2^>nul') do (
        if not defined BLENDER_EXE set "BLENDER_EXE=%%I"
    )
)

if not defined BLENDER_EXE (
    echo [ERROR] Blender 5.3.0 executable not found.
    echo         Install Blender 5.3 or set BLENDER_PATH environment variable.
    exit /b 1
)

echo [INFO] Blender : "%BLENDER_EXE%"
echo [INFO] Script  : "%MASTER_SCRIPT%"
echo [INFO] Log     : "%LOG_PATH%"
echo [INFO] Running Blender in background mode (--background)...
echo.

"%BLENDER_EXE%" --background --python-exit-code 1 --python "%MASTER_SCRIPT%" -- --blender "%BLENDER_EXE%" --dir "%ROOT_DIR%" > "%LOG_PATH%" 2>&1
set "BUILD_EXIT=%ERRORLEVEL%"

type "%LOG_PATH%"

echo.
echo ===============================================================================
echo STATUS WYGENEROWANYCH PLIKOW .GLB
echo ===============================================================================

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$manifestPath = '%MANIFEST_PATH%';" ^
  "if (Test-Path $manifestPath) {" ^
  "  $m = Get-Content -Raw -Encoding UTF8 $manifestPath | ConvertFrom-Json;" ^
  "  foreach ($a in $m.assets) {" ^
  "    if ($a.type -eq 'glb') {" ^
  "      $kb = [math]::Round($a.size_bytes / 1024.0, 1);" ^
  "      $tag = if ($a.status -eq 'OK') { '[OK]    ' } else { '[FAILED]' };" ^
  "      Write-Host ('{0} {1,-52} {2,8:N1} KB | {3}' -f $tag, $a.path, $kb, $a.validation_message)" ^
  "    }" ^
  "  }" ^
  "  Write-Host ('-------------------------------------------------------------------------------');" ^
  "  Write-Host ('Manifest: {0} | Valid: {1}/{2} | Steps: {3}/{4}' -f $manifestPath, $m.summary.valid_assets, $m.summary.total_assets, $m.summary.passed_steps, $m.summary.total_steps)" ^
  "} else {" ^
  "  Write-Host '[WARN] asset_manifest.json not found. Scanning assets\3d for .glb files...';" ^
  "  Get-ChildItem -Path '%ROOT_DIR%\assets\3d' -Recurse -Filter '*.glb' | ForEach-Object {" ^
  "    $kb = [math]::Round($_.Length / 1024.0, 1);" ^
  "    Write-Host ('[FOUND]  {0,-52} {1,8:N1} KB' -f $_.FullName, $kb)" ^
  "  }" ^
  "}"

echo ===============================================================================
if not "%BUILD_EXIT%"=="0" (
    echo [FAILED] Build zakonczony bledem (exit code: %BUILD_EXIT%). Sprawdz log: "%LOG_PATH%"
    exit /b %BUILD_EXIT%
)

echo [SUCCESS] Wszystkie assety 3D zostaly zbudowane i zweryfikowane.
exit /b 0
