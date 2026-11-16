#!/usr/bin/env bash
# ==============================================================================
# Production macOS (.app / .dmg) & iOS/iPadOS (.ipa) Release Build Script
# Pro Peloton Manager
# ==============================================================================
# Executes the full Apple release pipeline on macOS:
#   1. Validates macOS environment, Xcode, Flutter CLI, and pubspec.yaml metadata.
#   2. Verifies presence and GLB binary header ('glTF') of 3D assets in assets/3d/.
#   3. Restores Flutter dependencies (`flutter pub get`) and runs `flutter test`.
#   4. Builds native macOS app (`flutter build macos --release`) and packages
#      both `.app.zip` (via ditto) and drag-and-drop `.dmg` (via hdiutil).
#   5. Builds universal iPhone & iPad package (`flutter build ipa --release`).
#   6. Generates `BUILD_MANIFEST.txt` and `.sha256` checksums for all artifacts.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT=""
OUTPUT_DIR=""
VERSION_OVERRIDE=""
TARGET="all"
EXPORT_METHOD="app-store"
EXPORT_OPTIONS_PLIST=""
CODESIGN_IDENTITY=""
TEST_TIMEOUT="30s"
SKIP_TESTS=false
SKIP_PODS=false
CLEAN_BUILD=false
CREATE_DMG=true
ALLOW_MISSING_ASSETS=false
DRY_RUN=false

START_EPOCH="$(date +%s)"
TMP_STAGING_DIR=""

# ------------------------------------------------------------------------------
# Logging & Error Helpers
# ------------------------------------------------------------------------------

if [[ -t 1 ]]; then
  CLR_RESET="\033[0m"
  CLR_CYAN="\033[0;36m"
  CLR_DARK_CYAN="\033[0;34m"
  CLR_GRAY="\033[0;37m"
  CLR_GREEN="\033[0;32m"
  CLR_YELLOW="\033[0;33m"
  CLR_RED="\033[0;31m"
else
  CLR_RESET=""
  CLR_CYAN=""
  CLR_DARK_CYAN=""
  CLR_GRAY=""
  CLR_GREEN=""
  CLR_YELLOW=""
  CLR_RED=""
fi

write_step_header() {
  local title="$1"
  echo ""
  echo -e "${CLR_DARK_CYAN}======================================================================${CLR_RESET}"
  echo -e "${CLR_CYAN}  ${title}${CLR_RESET}"
  echo -e "${CLR_DARK_CYAN}======================================================================${CLR_RESET}"
}

write_info() {
  echo -e "${CLR_GRAY}[INFO]  $1${CLR_RESET}"
}

write_success() {
  echo -e "${CLR_GREEN}[OK]    $1${CLR_RESET}"
}

write_warn() {
  echo -e "${CLR_YELLOW}[WARN]  $1${CLR_RESET}"
}

fail_build() {
  local message="$1"
  local exit_code="${2:-1}"
  echo -e "${CLR_RED}[ERROR] ${message}${CLR_RESET}" >&2
  exit "${exit_code}"
}

cleanup() {
  if [[ -n "${TMP_STAGING_DIR}" && -d "${TMP_STAGING_DIR}" ]]; then
    rm -rf "${TMP_STAGING_DIR}"
  fi
}
trap cleanup EXIT

usage() {
  cat <<'EOF'
Usage: ./scripts/build_macos_and_ios_release.sh [OPTIONS]

Options:
  --project-root PATH          Flutter project root (default: parent of scripts/)
  --output-dir PATH            Output directory for .dmg/.zip/.ipa (default: dist/apple)
  --version VERSION            Version override (default: pubspec.yaml version)
  --target TARGET              Build target: all | macos | ios (default: all)
  --export-method METHOD       IPA export method: app-store | ad-hoc | enterprise | development
                               (default: app-store)
  --export-options-plist PATH  Path to ExportOptions.plist (overrides --export-method)
  --codesign-identity ID       Optional macOS codesign identity for the .app bundle
  --test-timeout DURATION      Timeout for flutter test (default: 30s)
  --no-dmg                     Skip creating .dmg (still creates .app.zip)
  --skip-tests                 Skip running `flutter test`
  --skip-pods                  Skip running `pod install` in macos/ and ios/
  --clean                      Run `flutter clean` before building
  --allow-missing-assets       Downgrade missing/invalid .glb 3D assets to warnings
  --dry-run                    Validate environment, runners, and 3D assets only
  -h, --help                   Show this help message

Examples:
  ./scripts/build_macos_and_ios_release.sh
  ./scripts/build_macos_and_ios_release.sh --target macos --clean
  ./scripts/build_macos_and_ios_release.sh --target ios --export-method ad-hoc
  ./scripts/build_macos_and_ios_release.sh --dry-run
EOF
}

# ------------------------------------------------------------------------------
# Argument Parsing
# ------------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root)
      [[ $# -ge 2 ]] || fail_build "--project-root requires a path argument."
      PROJECT_ROOT="$2"
      shift 2
      ;;
    --output-dir)
      [[ $# -ge 2 ]] || fail_build "--output-dir requires a path argument."
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --version)
      [[ $# -ge 2 ]] || fail_build "--version requires a value."
      VERSION_OVERRIDE="$2"
      shift 2
      ;;
    --target)
      [[ $# -ge 2 ]] || fail_build "--target requires one of: all, macos, ios."
      TARGET="$2"
      shift 2
      ;;
    --export-method)
      [[ $# -ge 2 ]] || fail_build "--export-method requires a value."
      EXPORT_METHOD="$2"
      shift 2
      ;;
    --export-options-plist)
      [[ $# -ge 2 ]] || fail_build "--export-options-plist requires a path."
      EXPORT_OPTIONS_PLIST="$2"
      shift 2
      ;;
    --codesign-identity)
      [[ $# -ge 2 ]] || fail_build "--codesign-identity requires an identity string."
      CODESIGN_IDENTITY="$2"
      shift 2
      ;;
    --test-timeout)
      [[ $# -ge 2 ]] || fail_build "--test-timeout requires a duration (e.g. 30s)."
      TEST_TIMEOUT="$2"
      shift 2
      ;;
    --no-dmg)
      CREATE_DMG=false
      shift
      ;;
    --skip-tests)
      SKIP_TESTS=true
      shift
      ;;
    --skip-pods)
      SKIP_PODS=true
      shift
      ;;
    --clean)
      CLEAN_BUILD=true
      shift
      ;;
    --allow-missing-assets)
      ALLOW_MISSING_ASSETS=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail_build "Unknown option: $1 (use --help for usage)"
      ;;
  esac
done

case "${TARGET}" in
  all|macos|ios) ;;
  *) fail_build "Invalid --target '${TARGET}'. Expected: all, macos, or ios." ;;
esac

case "${EXPORT_METHOD}" in
  app-store|ad-hoc|enterprise|development) ;;
  *) fail_build "Invalid --export-method '${EXPORT_METHOD}'. Expected: app-store, ad-hoc, enterprise, or development." ;;
esac

if [[ -z "${PROJECT_ROOT}" ]]; then
  PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
else
  PROJECT_ROOT="$(cd "${PROJECT_ROOT}" && pwd)"
fi

if [[ -z "${OUTPUT_DIR}" ]]; then
  OUTPUT_DIR="${PROJECT_ROOT}/dist/apple"
fi

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------

require_command() {
  local cmd="$1"
  local hint="${2:-}"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    if [[ -n "${hint}" ]]; then
      fail_build "Required command '${cmd}' not found in PATH. ${hint}"
    else
      fail_build "Required command '${cmd}' not found in PATH."
    fi
  fi
}

parse_pubspec_metadata() {
  local pubspec_path="${PROJECT_ROOT}/pubspec.yaml"
  if [[ ! -f "${pubspec_path}" ]]; then
    fail_build "pubspec.yaml not found at '${pubspec_path}'."
  fi

  APP_NAME="$(awk -F': *' '/^name:/{gsub(/["'\''[:space:]]/, "", $2); print $2; exit}' "${pubspec_path}")"
  PUBSPEC_VERSION="$(awk -F': *' '/^version:/{gsub(/["'\''[:space:]]/, "", $2); split($2, a, "#"); print a[1]; exit}' "${pubspec_path}")"

  APP_NAME="${APP_NAME:-pro_peloton_manager}"
  PUBSPEC_VERSION="${PUBSPEC_VERSION:-0.1.0+1}"
}

test_glb_binary_header() {
  local file_path="$1"
  local file_size
  file_size="$(wc -c < "${file_path}" | tr -d '[:space:]')"
  if [[ "${file_size}" -lt 12 ]]; then
    return 1
  fi

  local magic_hex
  magic_hex="$(dd if="${file_path}" bs=4 count=1 2>/dev/null | od -An -tx1 | tr -d '[:space:]')"
  # glTF binary magic header: 'g','l','T','F' -> 67 6c 54 46
  [[ "${magic_hex}" == "676c5446" ]]
}

verify_3d_assets() {
  write_step_header "Step 2: Verifying 3D Assets (assets/3d/)"

  local required_dirs=(
    "assets/3d/bikes"
    "assets/3d/cyclists"
    "assets/3d/riders"
    "assets/3d/roads"
    "assets/3d/furniture"
    "assets/3d/vehicles"
    "assets/3d/environment"
  )

  local critical_glb_files=(
    "assets/3d/bikes/frame_aero.glb"
    "assets/3d/bikes/frame_climbing.glb"
    "assets/3d/bikes/frame_tt.glb"
    "assets/3d/bikes/wheel_50mm.glb"
    "assets/3d/cyclists/cyclist_road.glb"
    "assets/3d/riders/cyclist_animated.glb"
    "assets/3d/roads/road_asphalt.glb"
    "assets/3d/roads/road_cobbles.glb"
    "assets/3d/roads/road_mountain_hairpin.glb"
    "assets/3d/furniture/arch_finish.glb"
    "assets/3d/furniture/arch_flamme_rouge.glb"
    "assets/3d/vehicles/vehicle_team_car.glb"
    "assets/3d/vehicles/vehicle_moto_tv.glb"
    "assets/3d/environment/podium_stage.glb"
    "assets/3d/environment/trophies_pack.glb"
    "assets/3d/environment/wind_tunnel_room.glb"
    "assets/3d/environment/tv_helicopter.glb"
  )

  local issues=()

  for rel_dir in "${required_dirs[@]}"; do
    if [[ ! -d "${PROJECT_ROOT}/${rel_dir}" ]]; then
      issues+=("Missing 3D asset directory: ${rel_dir}")
    fi
  done

  for rel_file in "${critical_glb_files[@]}"; do
    if [[ ! -f "${PROJECT_ROOT}/${rel_file}" ]]; then
      issues+=("Missing critical 3D asset: ${rel_file}")
    fi
  done

  GLB_COUNT=0
  GLB_TOTAL_BYTES=0
  if [[ -d "${PROJECT_ROOT}/assets/3d" ]]; then
    while IFS= read -r -d '' glb_file; do
      GLB_COUNT=$((GLB_COUNT + 1))
      local sz
      sz="$(wc -c < "${glb_file}" | tr -d '[:space:]')"
      GLB_TOTAL_BYTES=$((GLB_TOTAL_BYTES + sz))
      if [[ "${sz}" -lt 12 ]]; then
        issues+=("Corrupt or empty .glb file (<12 bytes): ${glb_file}")
      elif ! test_glb_binary_header "${glb_file}"; then
        issues+=("Invalid GLB binary header (expected 'glTF'): ${glb_file}")
      fi
    done < <(find "${PROJECT_ROOT}/assets/3d" -type f -name "*.glb" -print0)
  fi

  if [[ "${GLB_COUNT}" -eq 0 ]]; then
    issues+=("No .glb files found under assets/3d/.")
  fi

  if [[ "${#issues[@]}" -gt 0 ]]; then
    for issue in "${issues[@]}"; do
      if [[ "${ALLOW_MISSING_ASSETS}" == "true" ]]; then
        write_warn "${issue}"
      else
        echo -e "${CLR_RED}[FAIL]  ${issue}${CLR_RESET}" >&2
      fi
    done
    if [[ "${ALLOW_MISSING_ASSETS}" != "true" ]]; then
      fail_build "3D asset verification failed with ${#issues[@]} issue(s). Run Blender asset pipeline or pass --allow-missing-assets."
    fi
  fi

  GLB_TOTAL_MB="$(awk -v b="${GLB_TOTAL_BYTES}" 'BEGIN { printf "%.2f", b / (1024 * 1024) }')"
  write_success "Verified ${GLB_COUNT} .glb 3D assets (${GLB_TOTAL_MB} MB total)."
}

write_sha256_file() {
  local artifact_path="$1"
  local sha_path="${artifact_path}.sha256"
  local artifact_dir
  local artifact_name
  artifact_dir="$(dirname "${artifact_path}")"
  artifact_name="$(basename "${artifact_path}")"

  local hash_val
  hash_val="$(cd "${artifact_dir}" && shasum -a 256 "${artifact_name}" | awk '{print $1}')"
  printf "%s  %s\n" "${hash_val}" "${artifact_name}" > "${sha_path}"
  echo "${hash_val}"
}

format_size_mb() {
  local file_path="$1"
  local bytes
  bytes="$(wc -c < "${file_path}" | tr -d '[:space:]')"
  awk -v b="${bytes}" 'BEGIN { printf "%.2f MB", b / (1024 * 1024) }'
}

write_build_manifest() {
  local manifest_path="$1"
  local platform_label="$2"
  local artifact_label="$3"
  local git_commit="unknown"

  if command -v git >/dev/null 2>&1; then
    git_commit="$(git -C "${PROJECT_ROOT}" rev-parse --short HEAD 2>/dev/null || echo "unknown")"
  fi

  cat > "${manifest_path}" <<EOF
Pro Peloton Manager - ${platform_label} Release Manifest
================================================
App Name        : ${APP_NAME}
Version         : ${RESOLVED_VERSION}
Build Name      : ${BUILD_NAME}
Build Number    : ${BUILD_NUMBER}
Git Commit      : ${git_commit}
Built At (UTC)  : $(date -u '+%Y-%m-%d %H:%M:%S UTC')
Host OS         : $(sw_vers -productName 2>/dev/null || uname -s) $(sw_vers -productVersion 2>/dev/null || uname -r) ($(uname -m))
Xcode           : $(xcodebuild -version 2>/dev/null | head -n 1 || echo "N/A")
Artifact        : ${artifact_label}
3D Assets (.glb): ${GLB_COUNT} files (${GLB_TOTAL_MB} MB)
EOF
}

# ------------------------------------------------------------------------------
# Step 1: Validate Environment & Metadata
# ------------------------------------------------------------------------------

write_step_header "Step 1: Validating macOS Environment & Project Metadata"
write_info "Project root : ${PROJECT_ROOT}"
write_info "Output dir   : ${OUTPUT_DIR}"
write_info "Build target : ${TARGET}"

HOST_OS="$(uname -s)"
if [[ "${HOST_OS}" != "Darwin" ]]; then
  fail_build "This script must run on macOS (Darwin). Detected OS: ${HOST_OS}."
fi
write_success "Running on macOS ($(sw_vers -productVersion 2>/dev/null || uname -r), $(uname -m))."

require_command "flutter" "Install Flutter SDK and add it to PATH."
require_command "xcodebuild" "Install Xcode from the Mac App Store and run 'sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer'."
require_command "shasum" "macOS shasum utility is required."

if [[ "${TARGET}" == "all" || "${TARGET}" == "macos" ]]; then
  require_command "ditto" "macOS ditto utility is required to package .app.zip."
  if [[ "${CREATE_DMG}" == "true" ]]; then
    require_command "hdiutil" "macOS hdiutil utility is required to build .dmg (or pass --no-dmg)."
  fi
fi

write_info "Flutter CLI  : $(command -v flutter)"
write_info "Xcode        : $(xcodebuild -version | tr '\n' ' ' | sed 's/ *$//')"

parse_pubspec_metadata
RESOLVED_VERSION="${VERSION_OVERRIDE:-${PUBSPEC_VERSION}}"
SAFE_VERSION="${RESOLVED_VERSION//[^0-9A-Za-z._-]/-}"
BUILD_NAME="${RESOLVED_VERSION%%+*}"
if [[ "${RESOLVED_VERSION}" == *"+"* ]]; then
  BUILD_NUMBER="${RESOLVED_VERSION##*+}"
else
  BUILD_NUMBER="1"
fi

write_success "Detected project '${APP_NAME}' version '${RESOLVED_VERSION}' (build-name=${BUILD_NAME}, build-number=${BUILD_NUMBER})."

if [[ "${TARGET}" == "all" || "${TARGET}" == "macos" ]]; then
  if [[ ! -d "${PROJECT_ROOT}/macos" ]]; then
    if [[ "${DRY_RUN}" == "true" ]]; then
      write_warn "macOS runner directory ('macos/') not found. Run 'flutter create --platforms=macos .' before building."
    else
      fail_build "macOS runner directory ('macos/') not found. Run 'flutter create --platforms=macos .' first."
    fi
  else
    write_success "macOS runner directory found at '${PROJECT_ROOT}/macos'."
  fi
fi

if [[ "${TARGET}" == "all" || "${TARGET}" == "ios" ]]; then
  if [[ ! -d "${PROJECT_ROOT}/ios" ]]; then
    if [[ "${DRY_RUN}" == "true" ]]; then
      write_warn "iOS runner directory ('ios/') not found. Run 'flutter create --platforms=ios .' before building."
    else
      fail_build "iOS runner directory ('ios/') not found. Run 'flutter create --platforms=ios .' first."
    fi
  else
    write_success "iOS runner directory found at '${PROJECT_ROOT}/ios'."
    local_plist="${PROJECT_ROOT}/ios/Runner/Info.plist"
    if [[ -f "${local_plist}" ]] && command -v /usr/libexec/PlistBuddy >/dev/null 2>&1; then
      write_info "Checking iOS UIDeviceFamily (iPhone + iPad support) in Info.plist..."
      /usr/libexec/PlistBuddy -c "Print :UIDeviceFamily" "${local_plist}" >/dev/null 2>&1 || \
        write_info "UIDeviceFamily not explicitly set in Info.plist (Xcode TARGETED_DEVICE_FAMILY=1,2 controls iPhone+iPad)."
    fi
  fi
fi

if [[ -n "${EXPORT_OPTIONS_PLIST}" && ! -f "${EXPORT_OPTIONS_PLIST}" ]]; then
  fail_build "ExportOptions.plist not found at '${EXPORT_OPTIONS_PLIST}'."
fi

verify_3d_assets

if [[ "${DRY_RUN}" == "true" ]]; then
  write_step_header "Dry Run Complete"
  write_success "All pre-flight checks passed (Project: ${APP_NAME}, Version: ${RESOLVED_VERSION}, Target: ${TARGET}, 3D Assets: ${GLB_COUNT} .glb / ${GLB_TOTAL_MB} MB)."
  exit 0
fi

# ------------------------------------------------------------------------------
# Step 3: Restore Dependencies, CocoaPods & Run Tests
# ------------------------------------------------------------------------------

write_step_header "Step 3: Restoring Dependencies & Running Tests"

if [[ "${CLEAN_BUILD}" == "true" ]]; then
  write_info "Running: flutter clean"
  (cd "${PROJECT_ROOT}" && flutter clean)
fi

write_info "Running: flutter pub get"
(cd "${PROJECT_ROOT}" && flutter pub get)
write_success "Flutter dependencies restored."

if [[ "${SKIP_PODS}" != "true" ]] && command -v pod >/dev/null 2>&1; then
  if [[ ( "${TARGET}" == "all" || "${TARGET}" == "macos" ) && -f "${PROJECT_ROOT}/macos/Podfile" ]]; then
    write_info "Running: pod install in macos/"
    (cd "${PROJECT_ROOT}/macos" && pod install)
    write_success "macOS CocoaPods installed."
  fi
  if [[ ( "${TARGET}" == "all" || "${TARGET}" == "ios" ) && -f "${PROJECT_ROOT}/ios/Podfile" ]]; then
    write_info "Running: pod install in ios/"
    (cd "${PROJECT_ROOT}/ios" && pod install)
    write_success "iOS CocoaPods installed."
  fi
elif [[ "${SKIP_PODS}" == "true" ]]; then
  write_warn "Skipping CocoaPods install because --skip-pods was specified."
fi

if [[ "${SKIP_TESTS}" != "true" ]]; then
  write_info "Running: flutter test --timeout ${TEST_TIMEOUT}"
  (cd "${PROJECT_ROOT}" && flutter test --timeout "${TEST_TIMEOUT}")
  write_success "All Flutter tests passed."
else
  write_warn "Skipping 'flutter test' because --skip-tests was specified."
fi

mkdir -p "${OUTPUT_DIR}"
GENERATED_ARTIFACTS=()

# ------------------------------------------------------------------------------
# Step 4: Build & Package macOS Release (.app.zip & .dmg)
# ------------------------------------------------------------------------------

if [[ "${TARGET}" == "all" || "${TARGET}" == "macos" ]]; then
  write_step_header "Step 4: Building macOS Native Release (.app / .dmg)"

  write_info "Running: flutter build macos --release --build-name=${BUILD_NAME} --build-number=${BUILD_NUMBER}"
  (cd "${PROJECT_ROOT}" && flutter build macos --release --build-name="${BUILD_NAME}" --build-number="${BUILD_NUMBER}")

  MACOS_PRODUCTS_DIR="${PROJECT_ROOT}/build/macos/Build/Products/Release"
  APP_BUNDLE="$(find "${MACOS_PRODUCTS_DIR}" -maxdepth 1 -type d -name "*.app" | head -n 1 || true)"
  if [[ -z "${APP_BUNDLE}" || ! -d "${APP_BUNDLE}" ]]; then
    fail_build "Built macOS .app bundle not found under '${MACOS_PRODUCTS_DIR}'."
  fi

  APP_BUNDLE_NAME="$(basename "${APP_BUNDLE}")"
  if [[ ! -f "${APP_BUNDLE}/Contents/Info.plist" ]]; then
    fail_build "Missing Contents/Info.plist inside '${APP_BUNDLE}'."
  fi
  if command -v plutil >/dev/null 2>&1; then
    plutil -lint "${APP_BUNDLE}/Contents/Info.plist" >/dev/null
  fi

  if [[ -n "${CODESIGN_IDENTITY}" ]]; then
    write_info "Signing '${APP_BUNDLE_NAME}' with identity '${CODESIGN_IDENTITY}'..."
    codesign --force --deep --options runtime --sign "${CODESIGN_IDENTITY}" "${APP_BUNDLE}"
    codesign --verify --deep --strict "${APP_BUNDLE}"
    write_success "Code signature verified for '${APP_BUNDLE_NAME}'."
  fi

  MACOS_BASE="${APP_NAME}-v${SAFE_VERSION}-macos-universal"
  APP_ZIP_PATH="${OUTPUT_DIR}/${MACOS_BASE}.app.zip"
  rm -f "${APP_ZIP_PATH}" "${APP_ZIP_PATH}.sha256"

  write_info "Packaging .app bundle to '${APP_ZIP_PATH}'..."
  ditto -c -k --sequesterRsrc --keepParent "${APP_BUNDLE}" "${APP_ZIP_PATH}"
  APP_ZIP_SHA="$(write_sha256_file "${APP_ZIP_PATH}")"
  GENERATED_ARTIFACTS+=("${APP_ZIP_PATH} ($(format_size_mb "${APP_ZIP_PATH}"), sha256=${APP_ZIP_SHA})")
  write_success "Created macOS .app.zip: ${APP_ZIP_PATH}"

  if [[ "${CREATE_DMG}" == "true" ]]; then
    DMG_PATH="${OUTPUT_DIR}/${MACOS_BASE}.dmg"
    rm -f "${DMG_PATH}" "${DMG_PATH}.sha256"

    TMP_STAGING_DIR="$(mktemp -d /tmp/ppm_macos_dmg.XXXXXX)"
    ditto "${APP_BUNDLE}" "${TMP_STAGING_DIR}/${APP_BUNDLE_NAME}"
    ln -s /Applications "${TMP_STAGING_DIR}/Applications"
    write_build_manifest "${TMP_STAGING_DIR}/BUILD_MANIFEST.txt" "macOS" "${APP_BUNDLE_NAME}"

    VOL_NAME="${APP_NAME} ${BUILD_NAME}"
    write_info "Creating compressed .dmg image at '${DMG_PATH}'..."
    hdiutil create \
      -volname "${VOL_NAME}" \
      -srcfolder "${TMP_STAGING_DIR}" \
      -ov \
      -format UDZO \
      "${DMG_PATH}" >/dev/null

    rm -rf "${TMP_STAGING_DIR}"
    TMP_STAGING_DIR=""

    if [[ ! -f "${DMG_PATH}" ]]; then
      fail_build "Failed to create macOS .dmg at '${DMG_PATH}'."
    fi

    DMG_SHA="$(write_sha256_file "${DMG_PATH}")"
    GENERATED_ARTIFACTS+=("${DMG_PATH} ($(format_size_mb "${DMG_PATH}"), sha256=${DMG_SHA})")
    write_success "Created macOS .dmg: ${DMG_PATH}"
  else
    write_warn "Skipping .dmg creation because --no-dmg was specified."
  fi
fi

# ------------------------------------------------------------------------------
# Step 5: Build & Package iOS / iPadOS IPA Release
# ------------------------------------------------------------------------------

if [[ "${TARGET}" == "all" || "${TARGET}" == "ios" ]]; then
  write_step_header "Step 5: Building iOS & iPadOS Universal Release (.ipa)"

  IPA_ARGS=(
    build ipa --release
    --build-name="${BUILD_NAME}"
    --build-number="${BUILD_NUMBER}"
  )

  if [[ -n "${EXPORT_OPTIONS_PLIST}" ]]; then
    IPA_ARGS+=(--export-options-plist="${EXPORT_OPTIONS_PLIST}")
  else
    IPA_ARGS+=(--export-method="${EXPORT_METHOD}")
  fi

  write_info "Running: flutter ${IPA_ARGS[*]}"
  (cd "${PROJECT_ROOT}" && flutter "${IPA_ARGS[@]}")

  IPA_BUILD_DIR="${PROJECT_ROOT}/build/ios/ipa"
  BUILT_IPA="$(find "${IPA_BUILD_DIR}" -maxdepth 1 -type f -name "*.ipa" | head -n 1 || true)"
  if [[ -z "${BUILT_IPA}" || ! -f "${BUILT_IPA}" ]]; then
    fail_build "Built .ipa package not found under '${IPA_BUILD_DIR}'."
  fi

  IOS_BASE="${APP_NAME}-v${SAFE_VERSION}-ios-universal"
  FINAL_IPA_PATH="${OUTPUT_DIR}/${IOS_BASE}.ipa"
  rm -f "${FINAL_IPA_PATH}" "${FINAL_IPA_PATH}.sha256"

  cp "${BUILT_IPA}" "${FINAL_IPA_PATH}"
  IPA_SHA="$(write_sha256_file "${FINAL_IPA_PATH}")"
  write_build_manifest "${OUTPUT_DIR}/${IOS_BASE}.MANIFEST.txt" "iOS & iPadOS" "$(basename "${FINAL_IPA_PATH}")"

  GENERATED_ARTIFACTS+=("${FINAL_IPA_PATH} ($(format_size_mb "${FINAL_IPA_PATH}"), sha256=${IPA_SHA})")
  write_success "Created universal iPhone/iPad .ipa: ${FINAL_IPA_PATH}"
fi

# ------------------------------------------------------------------------------
# Step 6: Summary
# ------------------------------------------------------------------------------

END_EPOCH="$(date +%s)"
ELAPSED_SEC=$((END_EPOCH - START_EPOCH))
ELAPSED_FMT="$(printf '%02d:%02d' $((ELAPSED_SEC / 60)) $((ELAPSED_SEC % 60)))"

write_step_header "Apple Release Packaging Complete"
for item in "${GENERATED_ARTIFACTS[@]}"; do
  write_success "${item}"
done
write_success "Elapsed time: ${ELAPSED_FMT}"
