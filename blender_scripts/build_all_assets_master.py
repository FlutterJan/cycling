"""
===============================================================================
PRO PELOTON MANAGER - MASTER 3D ASSETS BUILD & VERIFICATION PIPELINE
===============================================================================
Master build execution script that orchestrates the entire procedural 3D
graphics & jersey texture pipeline (tasks #086 through #182):

  1. Initializes the directory hierarchy under `assets/3d/` and `assets/textures/`:
     - `assets/3d/bikes/`
     - `assets/3d/cyclists/`
     - `assets/3d/riders/`
     - `assets/3d/roads/`
     - `assets/3d/furniture/`
     - `assets/3d/vehicles/`
     - `assets/3d/environment/`
     - `assets/textures/jerseys/`

  2. Sequentially executes all procedural generator scripts (#086 - #182):
     - #086: `style_and_materials.py`
     - #087: `generate_aero_frame.py`
     - #088: `generate_climbing_frame.py`
     - #089: `generate_tt_frame.py`
     - #090: `generate_wheelsets.py`
     - #091: `generate_cockpit_and_drivetrain.py`
     - #092: `generate_cyclist_mesh.py`
     - #093: `generate_helmets_and_glasses.py`
     - #094: `rig_and_animate_cyclist.py`
     - #095: `generate_road_tiles.py`
     - #096: `generate_race_furniture.py`
     - #097: `generate_support_vehicles.py`
     - #098: `generate_environment_assets.py`
     - #176: `generate_cobble_monument_props.py`
     - #177: `generate_alpine_summit_scenery.py`
     - #178: `generate_time_trial_start_ramp.py`
     - #179: `generate_podium_and_trophies.py`
     - #180: `generate_wind_tunnel_facility.py`
     - #181: `generate_helicopter_and_blimp.py`
     - #182: `generate_jersey_textures_baker.py`

  3. Verifies every single exported `.glb` and `.png` file:
     - Validates filesystem existence and non-zero file size
     - Performs binary glTF 2.0 header inspection (magic 0x46546C67, version 2)
     - Validates PNG signature for baked jersey textures
     - Isolates exceptions per script and per asset (`try/except`)

  4. Generates a consolidated JSON manifest at `assets/3d/asset_manifest.json`
     and prints a summary table and status dashboard.

Can be executed directly via Python or Blender 5.3.0 on Windows:
  blender --background --python blender_scripts/build_all_assets_master.py
  python blender_scripts/build_all_assets_master.py

Compatible with Blender 3.6 LTS, 4.x, and 5.3.0+.
===============================================================================
"""

from datetime import datetime, timezone
import json
import os
import platform
import shutil
import struct
import subprocess
import sys
import time
from typing import Any, Dict, List, Optional, Tuple


# =============================================================================
# PIPELINE STEP DEFINITION
# =============================================================================

class BuildStep:
    """Represents a single step in the procedural 3D generation pipeline."""

    def __init__(
        self,
        task_id: str,
        name: str,
        script_name: str,
        expected_outputs: List[str],
        description: str,
        extra_args: Optional[List[str]] = None,
    ):
        self.task_id = task_id
        self.name = name
        self.script_name = script_name
        self.expected_outputs = expected_outputs
        self.description = description
        self.extra_args = extra_args or []


# Complete catalogue of pipeline steps from #086 to #182
PIPELINE_STEPS: List[BuildStep] = [
    BuildStep(
        task_id="#086",
        name="Visual Style & PBR Materials Showcase",
        script_name="style_and_materials.py",
        expected_outputs=[],
        description="PBR shaders, Zwift studio lighting, and color utilities",
    ),
    BuildStep(
        task_id="#087",
        name="Aero Road Frame",
        script_name="generate_aero_frame.py",
        expected_outputs=["assets/3d/bikes/frame_aero.glb"],
        description="Kammtail profiles, dropped seatstays, aero seatpost",
    ),
    BuildStep(
        task_id="#088",
        name="Climbing Road Frame",
        script_name="generate_climbing_frame.py",
        expected_outputs=["assets/3d/bikes/frame_climbing.glb"],
        description="Ultra-lightweight round tubes, classic rear triangle",
    ),
    BuildStep(
        task_id="#089",
        name="Time Trial (TT) Frame",
        script_name="generate_tt_frame.py",
        expected_outputs=["assets/3d/bikes/frame_tt.glb"],
        description="Extreme aero TT frame with rear wheel cutout & aerobars",
    ),
    BuildStep(
        task_id="#090",
        name="Road Wheelsets Pack",
        script_name="generate_wheelsets.py",
        expected_outputs=[
            "assets/3d/bikes/wheel_35mm.glb",
            "assets/3d/bikes/wheel_50mm.glb",
            "assets/3d/bikes/wheel_65mm.glb",
            "assets/3d/bikes/wheel_disc.glb",
        ],
        description="35mm climbing, 50mm all-around, 65mm aero, disc wheel",
    ),
    BuildStep(
        task_id="#091",
        name="Cockpit & Drivetrain Components Pack",
        script_name="generate_cockpit_and_drivetrain.py",
        expected_outputs=["assets/3d/bikes/components_pack.glb"],
        description="Integrated aero bar, shifters, crankset, power meter, derailleurs, 3D saddle",
    ),
    BuildStep(
        task_id="#092",
        name="Procedural Cyclist Mesh with Morph Targets",
        script_name="generate_cyclist_mesh.py",
        expected_outputs=["assets/3d/cyclists/cyclist_road.glb"],
        description="Stylized rider anatomy with Climber, AllRounder, Sprinter shape keys",
    ),
    BuildStep(
        task_id="#093",
        name="Helmets & Glasses Pack",
        script_name="generate_helmets_and_glasses.py",
        expected_outputs=[
            "assets/3d/cyclists/helmet_vented.glb",
            "assets/3d/cyclists/helmet_aero.glb",
            "assets/3d/cyclists/helmet_tt.glb",
            "assets/3d/cyclists/glasses_pro.glb",
        ],
        description="Vented climbing helmet, aero helmet, TT teardrop visor, cylindrical shades",
    ),
    BuildStep(
        task_id="#094",
        name="Rigging & Animated Cyclist Actions",
        script_name="rig_and_animate_cyclist.py",
        expected_outputs=["assets/3d/riders/cyclist_animated.glb"],
        description="20-bone armature rig with 6 cyclic cycling animations & IK pedals",
    ),
    BuildStep(
        task_id="#095",
        name="Modular Road Tiles",
        script_name="generate_road_tiles.py",
        expected_outputs=[
            "assets/3d/roads/road_asphalt.glb",
            "assets/3d/roads/road_cobbles.glb",
            "assets/3d/roads/road_mountain_hairpin.glb",
        ],
        description="Smooth tarmac with graffiti, pave sector, 180-deg mountain hairpin",
    ),
    BuildStep(
        task_id="#096",
        name="Race Furniture & Grand Tour Infrastructure",
        script_name="generate_race_furniture.py",
        expected_outputs=[
            "assets/3d/furniture/barrier_finish.glb",
            "assets/3d/furniture/arch_finish.glb",
            "assets/3d/furniture/arch_kom_sprint.glb",
            "assets/3d/furniture/arch_flamme_rouge.glb",
            "assets/3d/furniture/arch_kom.glb",
            "assets/3d/furniture/arch_sprint.glb",
        ],
        description="Crowd barriers, finish truss with digital LED clock, Flamme Rouge, KOM & sprint arches",
    ),
    BuildStep(
        task_id="#097",
        name="Race Support Convoy Vehicles",
        script_name="generate_support_vehicles.py",
        expected_outputs=[
            "assets/3d/vehicles/vehicle_team_car.glb",
            "assets/3d/vehicles/vehicle_moto_tv.glb",
            "assets/3d/vehicles/vehicle_moto_commissaire.glb",
        ],
        description="Directeur Sportif car with 6 bikes & wheels, TV camera moto, Commissaire moto",
    ),
    BuildStep(
        task_id="#098",
        name="Roadside Environment Assets",
        script_name="generate_environment_assets.py",
        expected_outputs=[
            "assets/3d/environment/env_pack.glb",
            "assets/3d/environment/tree_pine.glb",
            "assets/3d/environment/tree_cypress.glb",
            "assets/3d/environment/tree_deciduous.glb",
            "assets/3d/environment/rock_boulder.glb",
            "assets/3d/environment/mountain_peak.glb",
            "assets/3d/environment/building_townhouse.glb",
            "assets/3d/environment/spectators_cheering.glb",
        ],
        description="Low/Mid-poly trees, mountain boulder, distant snow peak, European townhouse, cheering fans",
    ),
    BuildStep(
        task_id="#176",
        name="Cobble Monuments & Velodrome Props",
        script_name="generate_cobble_monument_props.py",
        expected_outputs=[
            "assets/3d/environment/velodrome_finish_arena.glb",
            "assets/3d/environment/cobble_sector_props.glb",
        ],
        description="Concrete velodrome finish arena and cobbled monument sector props",
    ),
    BuildStep(
        task_id="#177",
        name="Alpine Summit Hors Categorie Scenery",
        script_name="generate_alpine_summit_scenery.py",
        expected_outputs=[
            "assets/3d/environment/alpine_summit_pack.glb",
        ],
        description="Summit observatory tower, 3m snow walls, fan campervans, flags",
    ),
    BuildStep(
        task_id="#178",
        name="Time Trial Start Pavilion & Ramp",
        script_name="generate_time_trial_start_ramp.py",
        expected_outputs=[
            "assets/3d/environment/tt_start_ramp.glb",
        ],
        description="Steel-glass TT start house, anti-slip ramp, wheel stand, LED countdown clock",
    ),
    BuildStep(
        task_id="#179",
        name="Post-Stage Podium & Trophies Pack",
        script_name="generate_podium_and_trophies.py",
        expected_outputs=[
            "assets/3d/environment/podium_stage.glb",
            "assets/3d/environment/trophies_pack.glb",
        ],
        description="3-tier ceremony podium with sponsor backdrop and 4 prestigious cycling trophies",
    ),
    BuildStep(
        task_id="#180",
        name="Aerodynamic Wind Tunnel Facility",
        script_name="generate_wind_tunnel_facility.py",
        expected_outputs=[
            "assets/3d/environment/wind_tunnel_room.glb",
        ],
        description="Cylindrical wind tunnel chamber, 12-blade turbine, yaw turntable, smoke streamlines",
    ),
    BuildStep(
        task_id="#181",
        name="TV Broadcast Helicopter",
        script_name="generate_helicopter_and_blimp.py",
        expected_outputs=[
            "assets/3d/environment/tv_helicopter.glb",
        ],
        description="TV broadcast helicopter with separate main/tail rotors and Cineflex gimbal",
    ),
    BuildStep(
        task_id="#182",
        name="Procedural Jersey Textures Baker (1024x1024)",
        script_name="generate_jersey_textures_baker.py",
        expected_outputs=[
            "assets/textures/jerseys/jersey_gc_yellow.png",
            "assets/textures/jerseys/jersey_points_green.png",
            "assets/textures/jerseys/jersey_kom_polkadot.png",
            "assets/textures/jerseys/jersey_youth_white.png",
            "assets/textures/jerseys/jersey_world_champ_rainbow.png",
            "assets/textures/jerseys/jersey_template_chevron.png",
            "assets/textures/jerseys/jersey_template_chest_stripe.png",
            "assets/textures/jerseys/jersey_template_alpine_gradient.png",
            "assets/textures/jerseys/jersey_template_vertical_stripes.png",
            "assets/textures/jerseys/jersey_template_checkerboard.png",
            "assets/textures/jerseys/jersey_template_diagonal_sash.png",
            "assets/textures/jerseys/jersey_template_contrast_sleeves.png",
            "assets/textures/jerseys/jersey_template_racing_hoops.png",
        ],
        description="5 leader jerseys and 8 team pattern templates baked at 1024x1024 PNG",
    ),
]


# =============================================================================
# ENVIRONMENT & DIRECTORY SETUP
# =============================================================================

REQUIRED_DIRECTORIES = [
    "assets/3d/bikes",
    "assets/3d/cyclists",
    "assets/3d/riders",
    "assets/3d/roads",
    "assets/3d/furniture",
    "assets/3d/vehicles",
    "assets/3d/environment",
    "assets/textures/jerseys",
]

MANIFEST_RELATIVE_PATH = os.path.join("assets", "3d", "asset_manifest.json")


def normalize_rel_path(path: str) -> str:
    """Normalizes a relative path to forward slashes for manifest portability."""
    return path.replace("\\", "/")


def ensure_directory_structure(base_dir: str = ".") -> None:
    """Creates all required asset directories under `assets/3d/` and `assets/textures/`."""
    print("[INIT] Creating target directory structure...")
    abs_base = os.path.abspath(base_dir)
    for rel_path in REQUIRED_DIRECTORIES:
        full_path = os.path.normpath(os.path.join(abs_base, *rel_path.split("/")))
        os.makedirs(full_path, exist_ok=True)
        print(f"       + {full_path}")


# =============================================================================
# BLENDER 5.3.0 COMPATIBILITY & EXECUTABLE DETECTION
# =============================================================================

def get_bpy_5x_compatibility_info() -> Dict[str, Any]:
    """
    Inspects the active `bpy` runtime (when executed inside Blender) and returns
    Blender 5.x API compatibility metadata for diagnostics and manifest output.
    """
    info: Dict[str, Any] = {
        "in_blender": False,
        "version_tuple": None,
        "version_string": "unknown",
        "is_blender_5x": False,
        "eevee_engine": "BLENDER_EEVEE",
        "gltf_exporter_available": False,
    }
    try:
        import bpy  # type: ignore

        info["in_blender"] = True
        ver = tuple(getattr(bpy.app, "version", (0, 0, 0)))
        info["version_tuple"] = ver
        info["version_string"] = ".".join(str(x) for x in ver)
        info["is_blender_5x"] = len(ver) > 0 and ver[0] >= 5

        # Blender 4.2 - 4.5 used BLENDER_EEVEE_NEXT; Blender 5.0+ unified it back to BLENDER_EEVEE
        render_enum = bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items.keys()
        if "BLENDER_EEVEE" in render_enum:
            info["eevee_engine"] = "BLENDER_EEVEE"
        elif "BLENDER_EEVEE_NEXT" in render_enum:
            info["eevee_engine"] = "BLENDER_EEVEE_NEXT"

        info["gltf_exporter_available"] = hasattr(bpy.ops.export_scene, "gltf")
    except ImportError:
        pass
    except Exception as exc:
        info["error"] = str(exc)

    return info


def find_blender_binary() -> str:
    """
    Locates the Blender executable on the host system across common installation
    paths on Windows, macOS, and Linux, prioritizing Blender 5.3.0 on Windows.
    """
    env_blender = os.environ.get("BLENDER_PATH")
    if env_blender and os.path.isfile(env_blender):
        return os.path.normpath(env_blender)

    try:
        import bpy  # type: ignore

        binary_path = getattr(bpy.app, "binary_path", "")
        if binary_path and os.path.isfile(binary_path):
            return os.path.normpath(binary_path)
    except ImportError:
        pass

    program_files = os.environ.get("ProgramFiles", r"C:\Program Files")
    program_files_x86 = os.environ.get("ProgramFiles(x86)", r"C:\Program Files (x86)")
    local_app_data = os.environ.get("LOCALAPPDATA", "")

    windows_versions = ["5.3", "5.2", "5.1", "5.0", "4.4", "4.3", "4.2", "4.1", "4.0", "3.6"]
    windows_candidates: List[str] = []
    for ver in windows_versions:
        windows_candidates.append(
            os.path.join(program_files, "Blender Foundation", f"Blender {ver}", "blender.exe")
        )
        if local_app_data:
            windows_candidates.append(
                os.path.join(local_app_data, "Programs", "Blender Foundation", f"Blender {ver}", "blender.exe")
            )
    windows_candidates.append(
        os.path.join(program_files_x86, "Blender Foundation", "Blender 5.3", "blender.exe")
    )

    for cand in windows_candidates:
        if os.path.isfile(cand):
            return os.path.normpath(cand)

    which_blender = shutil.which("blender")
    if which_blender and os.path.isfile(which_blender):
        return os.path.normpath(which_blender)

    mac_candidates = [
        "/Applications/Blender.app/Contents/MacOS/Blender",
        os.path.expanduser("~/Applications/Blender.app/Contents/MacOS/Blender"),
    ]
    for cand in mac_candidates:
        if os.path.isfile(cand):
            return os.path.normpath(cand)

    linux_candidates = [
        "/usr/bin/blender",
        "/usr/local/bin/blender",
        "/snap/bin/blender",
    ]
    for cand in linux_candidates:
        if os.path.isfile(cand):
            return os.path.normpath(cand)

    raise FileNotFoundError(
        "Could not locate Blender executable. Please set BLENDER_PATH environment variable:\n"
        "  $env:BLENDER_PATH = 'C:\\Program Files\\Blender Foundation\\Blender 5.3\\blender.exe'"
    )


def detect_blender_version(blender_bin: str) -> str:
    """Queries the Blender binary for its version string."""
    compat = get_bpy_5x_compatibility_info()
    if compat.get("in_blender") and compat.get("version_string") != "unknown":
        return str(compat["version_string"])

    try:
        proc = subprocess.run(
            [blender_bin, "--version"],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=15,
            check=False,
        )
        first_line = (proc.stdout or "").strip().splitlines()[0] if proc.stdout else ""
        if first_line.lower().startswith("blender "):
            return first_line.split()[1]
        return first_line or "unknown"
    except Exception:
        return "unknown"


# =============================================================================
# ASSET BINARY VALIDATORS (.GLB & .PNG)
# =============================================================================

def validate_gltf_binary(filepath: str) -> Tuple[bool, str]:
    """
    Validates that the file exists, has non-trivial size, and possesses a
    valid binary glTF 2.0 header (magic 0x46546C67 = "glTF", version 2).
    """
    norm_path = os.path.normpath(filepath)
    if not os.path.isfile(norm_path):
        return False, "File does not exist"

    size = os.path.getsize(norm_path)
    if size < 1024:
        return False, f"File suspiciously small ({size} bytes)"

    try:
        with open(norm_path, "rb") as f:
            header = f.read(12)
            if len(header) < 12:
                return False, "Truncated header"
            magic, version, length = struct.unpack("<4sII", header)
            if magic != b"glTF":
                return False, f"Invalid magic header: {magic!r}"
            if version != 2:
                return False, f"Unsupported glTF version: {version}"
            if length != size:
                return False, f"Header length ({length}) != filesystem size ({size})"
    except Exception as e:
        return False, f"Header inspection error: {e}"

    return True, f"OK ({size / 1024.0:.1f} KB)"


def validate_png_binary(filepath: str) -> Tuple[bool, str]:
    """Validates that the PNG texture exists, is non-empty, and has a valid PNG header."""
    norm_path = os.path.normpath(filepath)
    if not os.path.isfile(norm_path):
        return False, "File does not exist"

    size = os.path.getsize(norm_path)
    if size < 256:
        return False, f"PNG file suspiciously small ({size} bytes)"

    try:
        with open(norm_path, "rb") as f:
            sig = f.read(8)
            if sig != b"\x89PNG\r\n\x1a\n":
                return False, f"Invalid PNG signature: {sig!r}"
    except Exception as e:
        return False, f"PNG inspection error: {e}"

    return True, f"OK ({size / 1024.0:.1f} KB)"


def validate_asset_file(filepath: str) -> Tuple[bool, str]:
    """Dispatches validation based on asset extension (`.glb` or `.png`)."""
    ext = os.path.splitext(filepath)[1].lower()
    if ext == ".png":
        return validate_png_binary(filepath)
    return validate_gltf_binary(filepath)


# =============================================================================
# SCRIPT EXECUTION WORKER
# =============================================================================

def execute_pipeline_step(
    blender_bin: str,
    step: BuildStep,
    scripts_dir: str,
    base_dir: str = ".",
) -> Tuple[bool, float, List[str], str]:
    """
    Executes a single pipeline step script inside an isolated Blender subprocess.
    Returns: (success: bool, elapsed_seconds: float, output_files: List[str], logs: str).
    """
    abs_base = os.path.abspath(base_dir)
    script_path = os.path.normpath(os.path.join(scripts_dir, step.script_name))
    if not os.path.isfile(script_path):
        return False, 0.0, [], f"Script '{script_path}' not found"

    cmd = [
        blender_bin,
        "--background",
        "--python-exit-code",
        "1",
        "--python",
        script_path,
    ]
    if step.extra_args:
        cmd.append("--")
        cmd.extend(step.extra_args)

    t0 = time.time()
    try:
        result = subprocess.run(
            cmd,
            cwd=abs_base,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
            check=False,
            timeout=240,
        )
        elapsed = time.time() - t0
        output_log = result.stdout or ""

        if result.returncode != 0:
            return False, elapsed, [], f"Exit code {result.returncode}\n{output_log[-800:]}"

        verified_outputs: List[str] = []
        failed_validations: List[str] = []
        for out_rel in step.expected_outputs:
            out_full = os.path.normpath(os.path.join(abs_base, *out_rel.split("/")))
            try:
                is_valid, msg = validate_asset_file(out_full)
                if is_valid:
                    verified_outputs.append(out_full)
                else:
                    failed_validations.append(f"{out_rel}: {msg}")
            except Exception as val_exc:
                failed_validations.append(f"{out_rel}: {val_exc}")

        if failed_validations:
            return (
                False,
                elapsed,
                verified_outputs,
                "Output validation failed: " + "; ".join(failed_validations),
            )

        return True, elapsed, verified_outputs, "Success"

    except subprocess.TimeoutExpired:
        return False, time.time() - t0, [], "Execution timed out (240s limit)"
    except Exception as e:
        return False, time.time() - t0, [], f"Subprocess error: {e}"


# =============================================================================
# MANIFEST GENERATION
# =============================================================================

def generate_asset_manifest(
    base_dir: str,
    blender_bin: str,
    blender_version: str,
    step_results: List[Dict[str, Any]],
    overall_elapsed: float,
) -> str:
    """
    Writes a structured JSON manifest of all pipeline steps and generated assets
    to `assets/3d/asset_manifest.json` and returns the manifest file path.
    """
    abs_base = os.path.abspath(base_dir)
    manifest_path = os.path.normpath(os.path.join(abs_base, MANIFEST_RELATIVE_PATH))
    os.makedirs(os.path.dirname(manifest_path), exist_ok=True)

    asset_entries: List[Dict[str, Any]] = []
    step_entries: List[Dict[str, Any]] = []
    total_size_bytes = 0
    valid_assets = 0
    failed_assets = 0

    for res in step_results:
        step: BuildStep = res["step"]
        step_outputs_info: List[Dict[str, Any]] = []

        for out_rel in step.expected_outputs:
            out_full = os.path.normpath(os.path.join(abs_base, *out_rel.split("/")))
            ext = os.path.splitext(out_rel)[1].lstrip(".").lower() or "bin"
            try:
                is_valid, msg = validate_asset_file(out_full)
                size_bytes = os.path.getsize(out_full) if os.path.isfile(out_full) else 0
            except Exception as exc:
                is_valid = False
                msg = f"Validation exception: {exc}"
                size_bytes = 0

            if is_valid:
                valid_assets += 1
                total_size_bytes += size_bytes
            else:
                failed_assets += 1

            entry = {
                "path": normalize_rel_path(out_rel),
                "filename": os.path.basename(out_rel),
                "task_id": step.task_id,
                "type": ext,
                "status": "OK" if is_valid else "FAILED",
                "size_bytes": size_bytes,
                "validation_message": msg,
            }
            asset_entries.append(entry)
            step_outputs_info.append(entry)

        step_entries.append(
            {
                "task_id": step.task_id,
                "name": step.name,
                "script": step.script_name,
                "status": "PASS" if res["success"] else "FAIL",
                "elapsed_seconds": round(float(res["elapsed"]), 3),
                "error": None if res["success"] else str(res["log"]),
                "outputs": step_outputs_info,
            }
        )

    passed_steps = sum(1 for r in step_results if r["success"])
    failed_steps = len(step_results) - passed_steps

    manifest_payload = {
        "schema_version": "1.0.0",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "platform": {
            "system": platform.system(),
            "release": platform.release(),
            "machine": platform.machine(),
            "python_version": platform.python_version(),
        },
        "blender": {
            "executable": blender_bin,
            "version": blender_version,
            "bpy_5x_compat": get_bpy_5x_compatibility_info(),
        },
        "summary": {
            "total_steps": len(step_results),
            "passed_steps": passed_steps,
            "failed_steps": failed_steps,
            "total_assets": len(asset_entries),
            "valid_assets": valid_assets,
            "failed_assets": failed_assets,
            "total_size_bytes": total_size_bytes,
            "total_duration_seconds": round(overall_elapsed, 3),
        },
        "steps": step_entries,
        "assets": asset_entries,
    }

    with open(manifest_path, "w", encoding="utf-8") as mf:
        json.dump(manifest_payload, mf, indent=2, ensure_ascii=False)

    return manifest_path


# =============================================================================
# MASTER BUILD ORCHESTRATOR
# =============================================================================

def build_all_assets_master(
    base_dir: str = ".",
    blender_path: Optional[str] = None,
) -> bool:
    """
    Orchestrates the end-to-end execution of all pipeline tasks (#086 - #182),
    isolates errors per script via try/except, validates every exported asset,
    writes `assets/3d/asset_manifest.json`, and prints a consolidated report.
    """
    abs_base = os.path.abspath(base_dir)

    print("\n" + "=" * 80)
    print("PRO PELOTON MANAGER: MASTER 3D ASSET BUILD & VERIFICATION PIPELINE (#086-#182)")
    print("=" * 80)

    ensure_directory_structure(base_dir=abs_base)

    try:
        blender_bin = blender_path or find_blender_binary()
        blender_version = detect_blender_version(blender_bin)
        print(f"[BLENDER] Using executable: '{blender_bin}' (version {blender_version})")
    except FileNotFoundError as e:
        print(f"\n[FATAL] {e}")
        return False

    scripts_dir = os.path.normpath(os.path.join(abs_base, "blender_scripts"))
    if not os.path.isdir(scripts_dir):
        scripts_dir = os.path.dirname(os.path.abspath(__file__))

    total_steps = len(PIPELINE_STEPS)
    step_results: List[Dict[str, Any]] = []
    all_exported_files: List[str] = []
    overall_start = time.time()

    print("\n" + "-" * 80)
    print(f"STARTING PIPELINE EXECUTION ({total_steps} STEPS: #086 - #182)")
    print("-" * 80)

    for idx, step in enumerate(PIPELINE_STEPS, 1):
        progress_str = f"[{idx:02d}/{total_steps:02d}]"
        print(f"\n{progress_str} {step.task_id} - {step.name}")
        print(f"       Script: {step.script_name}")
        print(f"       About:  {step.description}")

        try:
            success, elapsed, outputs, log = execute_pipeline_step(
                blender_bin=blender_bin,
                step=step,
                scripts_dir=scripts_dir,
                base_dir=abs_base,
            )
        except Exception as exc:
            success = False
            elapsed = 0.0
            outputs = []
            log = f"Unhandled orchestrator exception for {step.script_name}: {exc}"

        step_results.append(
            {
                "step": step,
                "success": success,
                "elapsed": elapsed,
                "outputs": outputs,
                "log": log,
            }
        )

        if success:
            all_exported_files.extend(outputs)
            out_count = len(outputs)
            out_info = f" -> {out_count} assets generated" if out_count > 0 else ""
            print(f"       Status: [OK] in {elapsed:.2f}s{out_info}")
            for out_file in outputs:
                size_kb = os.path.getsize(out_file) / 1024.0
                print(f"         * {os.path.basename(out_file)} ({size_kb:.1f} KB)")
        else:
            print(f"       Status: [FAILED] in {elapsed:.2f}s (continuing remaining steps)")
            print(f"       Error:  {log}")

    overall_elapsed = time.time() - overall_start

    # Generate asset_manifest.json regardless of individual step failures
    manifest_path = ""
    try:
        manifest_path = generate_asset_manifest(
            base_dir=abs_base,
            blender_bin=blender_bin,
            blender_version=blender_version,
            step_results=step_results,
            overall_elapsed=overall_elapsed,
        )
        print(f"\n[MANIFEST] Saved build report to: {manifest_path}")
    except Exception as manifest_exc:
        print(f"\n[ERROR] Failed to write asset_manifest.json: {manifest_exc}")

    # =========================================================================
    # FINAL VERIFICATION & REPORTING DASHBOARD
    # =========================================================================
    print("\n" + "=" * 80)
    print("PIPELINE EXECUTION SUMMARY REPORT")
    print("=" * 80)

    total_size_bytes = 0
    total_valid_assets = 0
    passed_steps = sum(1 for r in step_results if r["success"])

    print(f"{'Task':<6} | {'Step Name':<38} | {'Time':<7} | {'Status':<6} | {'Assets'}")
    print("-" * 80)

    for res in step_results:
        s: BuildStep = res["step"]
        status_tag = "PASS" if res["success"] else "FAIL"
        num_out = len(res["outputs"])
        print(f"{s.task_id:<6} | {s.name[:38]:<38} | {res['elapsed']:>5.2f}s | {status_tag:<6} | {num_out} files")

    print("-" * 80)

    print("\n[VERIFICATION] Binary inspection of all verified assets:")
    for out_path in all_exported_files:
        try:
            is_valid, msg = validate_asset_file(out_path)
            rel_p = normalize_rel_path(os.path.relpath(out_path, abs_base))
            size = os.path.getsize(out_path)
            if is_valid:
                total_size_bytes += size
                total_valid_assets += 1
            tag = "VALID" if is_valid else "INVALID"
            print(f"  [{tag}] {rel_p:<52} {size / 1024.0:>7.1f} KB | {msg}")
        except Exception as inspect_exc:
            print(f"  [ERROR] {out_path}: {inspect_exc}")

    total_size_mb = total_size_bytes / (1024.0 * 1024.0)
    all_passed = passed_steps == total_steps

    print("\n" + "=" * 80)
    print("GRAND TOTALS:")
    print(f"  * Total Pipeline Steps:     {passed_steps}/{total_steps} PASSED")
    print(f"  * Total Assets Verified:    {total_valid_assets} files")
    print(f"  * Total Binary Size:        {total_size_mb:.2f} MB ({total_size_bytes:,} bytes)")
    print(f"  * Total Pipeline Duration:  {overall_elapsed:.2f} seconds")
    if manifest_path:
        print(f"  * Asset Manifest:           {normalize_rel_path(os.path.relpath(manifest_path, abs_base))}")
    print("=" * 80)

    if all_passed:
        print("[SUCCESS] ALL 3D ASSETS & TEXTURES BUILT AND VERIFIED WITH 100% SUCCESS!\n")
    else:
        print(f"[WARNING] Pipeline finished with {total_steps - passed_steps} failed step(s).\n")

    return all_passed


# =============================================================================
# CLI ENTRY POINT
# =============================================================================

if __name__ == "__main__":
    blender_arg: Optional[str] = None
    target_base: str = "."

    script_args = sys.argv
    if "--" in script_args:
        script_args = script_args[script_args.index("--") + 1:]

    for idx, arg in enumerate(script_args):
        if arg == "--blender" and idx + 1 < len(script_args):
            blender_arg = script_args[idx + 1]
        elif arg == "--dir" and idx + 1 < len(script_args):
            target_base = script_args[idx + 1]

    success = build_all_assets_master(base_dir=target_base, blender_path=blender_arg)
    sys.exit(0 if success else 1)
