"""
===============================================================================
PRO PELOTON MANAGER - MASTER 3D ASSETS BUILD & VERIFICATION PIPELINE
===============================================================================
Master build execution script that orchestrates the entire procedural 3D
graphics pipeline (tasks #086 through #098):

  1. Initializes the directory hierarchy under `assets/3d/`:
     - `assets/3d/bikes/`
     - `assets/3d/cyclists/`
     - `assets/3d/riders/`
     - `assets/3d/roads/`
     - `assets/3d/furniture/`
     - `assets/3d/vehicles/`
     - `assets/3d/environment/`

  2. Sequentially executes all procedural generator scripts (#086 - #098):
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

  3. Verifies every single exported `.glb` file:
     - Validates filesystem existence and non-zero file size
     - Performs binary glTF 2.0 header inspection (magic 0x46546C67, version 2)
     - Validates internal byte-length consistency

  4. Outputs a consolidated summary table and status dashboard.

Can be executed directly via Python or Blender:
  blender --background --python blender_scripts/build_all_assets_master.py
  python blender_scripts/build_all_assets_master.py

Compatible with Blender 3.6 LTS, 4.x, and 5.x+.
===============================================================================
"""

import os
import shutil
import struct
import subprocess
import sys
import time
from typing import Dict, List, Optional, Tuple


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
    ):
        self.task_id = task_id
        self.name = name
        self.script_name = script_name
        self.expected_outputs = expected_outputs
        self.description = description


# Complete catalogue of pipeline steps from #086 to #098
PIPELINE_STEPS: List[BuildStep] = [
    BuildStep(
        task_id="#086",
        name="Visual Style & PBR Materials Showcase",
        script_name="style_and_materials.py",
        expected_outputs=[],  # Style foundation module
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
        description="Smooth tarmac with graffiti, pavé sector, 180-deg mountain hairpin",
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
        description="Directeur Sportif car with 6 bikes & wheels, TV camera moto with cameraman, Commissaire moto",
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
]


def ensure_directory_structure(base_dir: str = ".") -> None:
    """Creates all required asset directories under `assets/3d/`."""
    print("[INIT] Creating target directory structure...")
    for rel_path in REQUIRED_DIRECTORIES:
        full_path = os.path.join(base_dir, rel_path)
        os.makedirs(full_path, exist_ok=True)
        print(f"       + {os.path.normpath(full_path)}")


# =============================================================================
# BLENDER EXECUTABLE DETECTION
# =============================================================================

def find_blender_binary() -> str:
    """
    Locates the Blender executable on the host system across common installation
    paths on Windows, macOS, and Linux.
    """
    # 1. Environment variable override
    env_blender = os.environ.get("BLENDER_PATH")
    if env_blender and os.path.isfile(env_blender):
        return env_blender

    # 2. If running from within Blender, use bpy.app.binary_path
    try:
        import bpy
        if hasattr(bpy.app, "binary_path") and os.path.isfile(bpy.app.binary_path):
            return bpy.app.binary_path
    except ImportError:
        pass

    # 3. Common Windows paths (check latest Blender versions first)
    windows_candidates = [
        r"C:\Program Files\Blender Foundation\Blender 5.3\blender.exe",
        r"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe",
        r"C:\Program Files\Blender Foundation\Blender 5.1\blender.exe",
        r"C:\Program Files\Blender Foundation\Blender 5.0\blender.exe",
        r"C:\Program Files\Blender Foundation\Blender 4.3\blender.exe",
        r"C:\Program Files\Blender Foundation\Blender 4.2\blender.exe",
        r"C:\Program Files\Blender Foundation\Blender 4.1\blender.exe",
        r"C:\Program Files\Blender Foundation\Blender 4.0\blender.exe",
        r"C:\Program Files\Blender Foundation\Blender 3.6\blender.exe",
    ]
    for cand in windows_candidates:
        if os.path.isfile(cand):
            return cand

    # 4. PATH lookup
    which_blender = shutil.which("blender")
    if which_blender and os.path.isfile(which_blender):
        return which_blender

    # 5. macOS candidates
    mac_candidates = [
        "/Applications/Blender.app/Contents/MacOS/Blender",
        os.path.expanduser("~/Applications/Blender.app/Contents/MacOS/Blender"),
    ]
    for cand in mac_candidates:
        if os.path.isfile(cand):
            return cand

    # 6. Linux candidates
    linux_candidates = [
        "/usr/bin/blender",
        "/usr/local/bin/blender",
        "/snap/bin/blender",
    ]
    for cand in linux_candidates:
        if os.path.isfile(cand):
            return cand

    raise FileNotFoundError(
        "Could not locate Blender executable. Please set BLENDER_PATH environment variable:\n"
        "  $env:BLENDER_PATH = 'C:\\Program Files\\Blender Foundation\\Blender 5.3\\blender.exe'"
    )


# =============================================================================
# GLTF 2.0 BINARY VALIDATOR
# =============================================================================

def validate_gltf_binary(filepath: str) -> Tuple[bool, str]:
    """
    Validates that the file exists, has non-trivial size, and possesses a
    valid binary glTF 2.0 header (magic 0x46546C67 = "glTF", version 2).
    """
    if not os.path.isfile(filepath):
        return False, "File does not exist"

    size = os.path.getsize(filepath)
    if size < 1024:
        return False, f"File suspiciously small ({size} bytes)"

    try:
        with open(filepath, "rb") as f:
            header = f.read(12)
            if len(header) < 12:
                return False, "Truncated header"
            magic, version, length = struct.unpack("<4sII", header)
            if magic != b"glTF":
                return False, f"Invalid magic header: {magic}"
            if version != 2:
                return False, f"Unsupported glTF version: {version}"
            if length != size:
                return False, f"Header length ({length}) != filesystem size ({size})"
    except Exception as e:
        return False, f"Header inspection error: {e}"

    return True, f"OK ({size / 1024.0:.1f} KB)"


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
    script_path = os.path.join(scripts_dir, step.script_name)
    if not os.path.isfile(script_path):
        return False, 0.0, [], f"Script '{script_path}' not found"

    cmd = [
        blender_bin,
        "--background",
        "--python",
        script_path,
    ]

    t0 = time.time()
    try:
        result = subprocess.run(
            cmd,
            cwd=base_dir,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            check=False,
            timeout=180,  # 3 minute timeout per script
        )
        elapsed = time.time() - t0
        output_log = result.stdout or ""

        if result.returncode != 0:
            return False, elapsed, [], f"Exit code {result.returncode}\n{output_log[-600:]}"

        # Verify expected outputs
        verified_outputs = []
        for out_rel in step.expected_outputs:
            out_full = os.path.join(base_dir, out_rel)
            is_valid, msg = validate_gltf_binary(out_full)
            if not is_valid:
                return False, elapsed, verified_outputs, f"Output validation failed for '{out_rel}': {msg}"
            verified_outputs.append(out_full)

        return True, elapsed, verified_outputs, "Success"

    except subprocess.TimeoutExpired:
        return False, time.time() - t0, [], "Execution timed out (180s limit)"
    except Exception as e:
        return False, time.time() - t0, [], f"Subprocess error: {e}"


# =============================================================================
# MASTER BUILD ORCHESTRATOR
# =============================================================================

def build_all_assets_master(
    base_dir: str = ".",
    blender_path: Optional[str] = None,
) -> bool:
    """
    Orchestrates the end-to-end execution of all 13 pipeline tasks (#086 - #098),
    validates every exported 3D asset, and displays a consolidated build report.
    """
    print("\n" + "=" * 80)
    print("PRO PELOTON MANAGER: MASTER 3D ASSET BUILD & VERIFICATION PIPELINE")
    print("================================================================================")

    # 1. Ensure output directory tree exists
    ensure_directory_structure(base_dir=base_dir)

    # 2. Locate Blender binary
    try:
        blender_bin = blender_path or find_blender_binary()
        print(f"[BLENDER] Using executable: '{blender_bin}'")
    except FileNotFoundError as e:
        print(f"\n[FATAL] {e}")
        return False

    scripts_dir = os.path.join(base_dir, "blender_scripts")
    if not os.path.isdir(scripts_dir):
        scripts_dir = os.path.dirname(os.path.abspath(__file__))

    total_steps = len(PIPELINE_STEPS)
    step_results = []
    all_exported_files = []
    overall_start = time.time()

    print("\n" + "-" * 80)
    print(f"STARTING PIPELINE EXECUTION ({total_steps} STEPS: #086 - #098)")
    print("-" * 80)

    # 3. Execute each step sequentially
    for idx, step in enumerate(PIPELINE_STEPS, 1):
        progress_str = f"[{idx:02d}/{total_steps:02d}]"
        print(f"\n{progress_str} {step.task_id} - {step.name}")
        print(f"       Script: {step.script_name}")
        print(f"       About:  {step.description}")

        success, elapsed, outputs, log = execute_pipeline_step(
            blender_bin=blender_bin,
            step=step,
            scripts_dir=scripts_dir,
            base_dir=base_dir,
        )

        step_results.append({
            "step": step,
            "success": success,
            "elapsed": elapsed,
            "outputs": outputs,
            "log": log,
        })

        if success:
            all_exported_files.extend(outputs)
            out_count = len(outputs)
            out_info = f" -> {out_count} assets generated" if out_count > 0 else ""
            print(f"       Status: [OK] in {elapsed:.2f}s{out_info}")
            for out_file in outputs:
                size_kb = os.path.getsize(out_file) / 1024.0
                print(f"         * {os.path.basename(out_file)} ({size_kb:.1f} KB)")
        else:
            print(f"       Status: [FAILED] in {elapsed:.2f}s")
            print(f"       Error:  {log}")
            print("\n[ABORT] Pipeline stopped due to failure.")
            return False

    overall_elapsed = time.time() - overall_start

    # =========================================================================
    # FINAL VERIFICATION & REPORTING DASHBOARD
    # =========================================================================
    print("\n" + "=" * 80)
    print("PIPELINE EXECUTION SUMMARY REPORT")
    print("=" * 80)

    total_size_bytes = 0
    total_valid_assets = 0

    print(f"{'Task':<6} | {'Step Name':<38} | {'Time':<7} | {'Status':<6} | {'Assets'}")
    print("-" * 80)

    for res in step_results:
        s = res["step"]
        status_tag = "PASS" if res["success"] else "FAIL"
        num_out = len(res["outputs"])
        print(f"{s.task_id:<6} | {s.name[:38]:<38} | {res['elapsed']:>5.2f}s | {status_tag:<6} | {num_out} files")

    print("-" * 80)

    # Inspect all generated assets
    print("\n[VERIFICATION] Deep binary inspection of all generated 3D assets:")
    for out_path in all_exported_files:
        is_valid, msg = validate_gltf_binary(out_path)
        rel_p = os.path.relpath(out_path, base_dir)
        size = os.path.getsize(out_path)
        total_size_bytes += size
        total_valid_assets += 1
        print(f"  [VALID] {rel_p:<50} {size / 1024.0:>7.1f} KB | {msg}")

    total_size_mb = total_size_bytes / (1024.0 * 1024.0)

    print("\n" + "=" * 80)
    print("GRAND TOTALS:")
    print(f"  * Total Pipeline Steps:     {total_steps}/{total_steps} PASSED")
    print(f"  * Total 3D Models Verified: {total_valid_assets} assets (.glb)")
    print(f"  * Total Binary Size:        {total_size_mb:.2f} MB ({total_size_bytes:,} bytes)")
    print(f"  * Total Pipeline Duration:  {overall_elapsed:.2f} seconds")
    print("================================================================================")
    print("[SUCCESS] ALL 3D ASSETS BUILT AND VERIFIED WITH 100% SUCCESS!\n")

    return True


# =============================================================================
# CLI ENTRY POINT
# =============================================================================

if __name__ == "__main__":
    blender_arg: Optional[str] = None
    target_base: str = "."

    # In Blender, arguments after '--' are custom script arguments.
    # If no '--' is passed, only inspect script_args excluding blender flags.
    script_args = sys.argv
    if "--" in script_args:
        script_args = script_args[script_args.index("--") + 1:]

    for idx, arg in enumerate(script_args):
        if arg in ["--blender"] and idx + 1 < len(script_args):
            blender_arg = script_args[idx + 1]
        elif arg in ["--dir"] and idx + 1 < len(script_args):
            target_base = script_args[idx + 1]

    success = build_all_assets_master(base_dir=target_base, blender_path=blender_arg)
    sys.exit(0 if success else 1)

