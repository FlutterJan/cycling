"""
===============================================================================
PRO PELOTON MANAGER - TIME TRIAL START PAVILION & RAMP GENERATOR
===============================================================================
Blender 5.3 Python API (bpy) script that procedurally models a 3D professional
Time Trial (ITT/TTT) start house and descent ramp
(`assets/3d/environment/tt_start_ramp.glb`):

  1. Covered Start Pavilion (Zadaszony pawilon startowy):
     - Modern architectural steel-and-glass frame in dark graphite (#181B22)
       and burgundy red (#8E4A49)
     - Structural H-columns, cantilevered aerodynamic roof canopy with recessed
       LED ceiling strips, tempered glass side curtain walls, rear media
       backdrop wall, and rear access stairs with handrails

  2. Inclined Descent Ramp & Start Hardware:
     - Elevated start deck (Z = 1.40m) transitioning smoothly into an 8.0m
       inclined descent ramp down to ground level (Z = 0.0m)
     - Anti-slip center rubberized strip with transverse grip cleats, guide
       stripes, and gold/white start-line marker
     - Rear-wheel TT starting stand (stojak startowy) with bolted steel base,
       hydraulic release actuator, and dual rubber-padded wheel clamping jaws
     - Overhead electronic countdown clock gantry & rider-facing countdown
       console with 7-segment LED timer ("00:05") and Red, Yellow, and Green
       LED signal lamps, plus photoelectric start-gate timing sensors

Usage:
  blender --background --python blender_scripts/generate_time_trial_start_ramp.py
  blender --background --python blender_scripts/generate_time_trial_start_ramp.py -- --output-dir assets/3d/environment

Compatible with Blender 3.6 LTS, 4.x, and 5.3+.
===============================================================================
"""

import math
import os
import sys
from typing import Dict, List, Optional, Tuple, Union

try:
    import bpy
    import bmesh
    from mathutils import Euler, Matrix, Vector
except ImportError:
    print("[ERROR] 'bpy' / 'mathutils' module not found. Run within Blender:")
    print("        blender --background --python blender_scripts/generate_time_trial_start_ramp.py")
    sys.exit(1)

script_dir = os.path.dirname(os.path.abspath(__file__))
if script_dir not in sys.path:
    sys.path.insert(0, script_dir)

try:
    import style_and_materials as sm
except ImportError:
    print(f"[ERROR] Could not import 'style_and_materials' from '{script_dir}'.")
    sys.exit(1)


# =============================================================================
# MATERIAL INDICES & PBR FACTORIES
# =============================================================================

MAT_DARK_GRAPHITE = 0
MAT_BURGUNDY_ACCENT = 1
MAT_ARCH_GLASS = 2
MAT_DECK_COMPOSITE = 3
MAT_ANTISLIP_RUBBER = 4
MAT_BRUSHED_STEEL = 5
MAT_START_GOLD = 6
MAT_LED_RED = 7
MAT_LED_YELLOW = 8
MAT_LED_GREEN = 9
MAT_LED_CLOCK_DIGITS = 10
MAT_CLOCK_DISPLAY_FACE = 11


def _make_pbr_material(
    name: str,
    hex_color: str,
    roughness: float = 0.5,
    metallic: float = 0.0,
    specular_ior: float = 0.5,
    ior: float = 1.45,
    alpha: float = 1.0,
    emission_color: Optional[str] = None,
    emission_strength: float = 0.0,
) -> bpy.types.Material:
    """Creates a Principled BSDF PBR material compatible with Blender 5.3 and glTF 2.0."""
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)
    sm._set_bsdf_socket(bsdf, ["Base Color"], sm.hex_to_linear_rgb(hex_color))
    sm._set_bsdf_socket(bsdf, ["Roughness"], roughness)
    sm._set_bsdf_socket(bsdf, ["Metallic"], metallic)
    sm._set_bsdf_socket(bsdf, ["Specular IOR Level", "Specular"], specular_ior)
    sm._set_bsdf_socket(bsdf, ["IOR"], ior)
    sm._set_bsdf_socket(bsdf, ["Alpha"], alpha)

    if alpha < 1.0:
        if hasattr(mat, "blend_method"):
            try:
                mat.blend_method = "BLEND"
            except Exception:
                pass
        if hasattr(mat, "shadow_method"):
            try:
                mat.shadow_method = "NONE"
            except Exception:
                pass

    if emission_color is not None and emission_strength > 0.0:
        sm._set_bsdf_socket(bsdf, ["Emission Color", "Emission"], sm.hex_to_linear_rgb(emission_color))
        sm._set_bsdf_socket(bsdf, ["Emission Strength"], emission_strength)

    return mat


def create_tt_ramp_materials() -> List[bpy.types.Material]:
    """Builds the ordered PBR material palette for the TT Start Pavilion & Ramp."""
    return [
        # 0: Dark graphite structural steel (#181B22)
        _make_pbr_material("Mat_TT_Dark_Graphite", "#181B22", roughness=0.38, metallic=0.78),
        # 1: Burgundy red architectural accent & branding (#8E4A49)
        _make_pbr_material("Mat_TT_Burgundy_Accent", "#8E4A49", roughness=0.32, metallic=0.25),
        # 2: Tempered architectural tinted glass
        _make_pbr_material(
            "Mat_TT_Architectural_Glass",
            "#1A2636",
            roughness=0.08,
            metallic=0.12,
            specular_ior=0.88,
            ior=1.52,
            alpha=0.42,
        ),
        # 3: Elevated platform & ramp composite deck
        _make_pbr_material("Mat_TT_Deck_Composite", "#222630", roughness=0.68, metallic=0.05),
        # 4: Anti-slip rubberized strip, cleats & wheel clamp pads
        _make_pbr_material("Mat_TT_AntiSlip_Rubber", "#0F1115", roughness=0.92, metallic=0.0),
        # 5: Brushed steel handrails, actuators & fasteners
        _make_pbr_material("Mat_TT_Brushed_Steel", "#94A3B8", roughness=0.28, metallic=0.90),
        # 6: Championship gold start line & trim
        _make_pbr_material("Mat_TT_Start_Line_Gold", "#D4AF37", roughness=0.35, metallic=0.45),
        # 7: Red LED countdown lamp
        _make_pbr_material(
            "Mat_TT_LED_Red",
            "#EF4444",
            roughness=0.18,
            metallic=0.0,
            emission_color="#EF4444",
            emission_strength=5.5,
        ),
        # 8: Yellow/Amber LED countdown lamp
        _make_pbr_material(
            "Mat_TT_LED_Yellow",
            "#F59E0B",
            roughness=0.18,
            metallic=0.0,
            emission_color="#F59E0B",
            emission_strength=5.5,
        ),
        # 9: Green LED countdown lamp
        _make_pbr_material(
            "Mat_TT_LED_Green",
            "#10B981",
            roughness=0.18,
            metallic=0.0,
            emission_color="#10B981",
            emission_strength=5.5,
        ),
        # 10: Cyan/White LED clock digits & pavilion ceiling strips
        _make_pbr_material(
            "Mat_TT_LED_Clock_Digits",
            "#F3F4F6",
            roughness=0.15,
            metallic=0.0,
            emission_color="#38BDF8",
            emission_strength=4.0,
        ),
        # 11: Dark glass clock display face
        _make_pbr_material("Mat_TT_Clock_Display_Face", "#090B0E", roughness=0.12, metallic=0.10),
    ]


def _create_mesh_object(name: str, materials: List[bpy.types.Material]) -> Tuple[bpy.types.Object, bpy.types.Mesh, bmesh.types.BMesh]:
    """Creates a linked Blender mesh object with pre-assigned material slots."""
    mesh = bpy.data.meshes.new(name + "_Mesh")
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    for mat in materials:
        obj.data.materials.append(mat)
    return obj, mesh, bmesh.new()


# =============================================================================
# BMESH GEOMETRY PRIMITIVES
# =============================================================================

def _assign_mat(faces: List[bmesh.types.BMFace], mat_index: int) -> None:
    for face in faces:
        face.material_index = mat_index


def _add_transformed_box(
    bm: bmesh.types.BMesh,
    center: Tuple[float, float, float],
    size: Tuple[float, float, float],
    mat_index: int,
    rot_euler_rad: Tuple[float, float, float] = (0.0, 0.0, 0.0),
) -> None:
    """Adds an oriented box into the BMesh with the given material index."""
    rot_mat = Euler(rot_euler_rad, "XYZ").to_matrix().to_4x4()
    scale_mat = Matrix.Diagonal((size[0], size[1], size[2], 1.0))
    trans_mat = Matrix.Translation(center)
    xform = trans_mat @ rot_mat @ scale_mat
    ret = bmesh.ops.create_cube(bm, size=1.0, matrix=xform)
    verts = ret["verts"]
    new_faces = [f for f in bm.faces if all(v in verts for v in f.verts)]
    _assign_mat(new_faces, mat_index)


def _add_cylinder(
    bm: bmesh.types.BMesh,
    center: Tuple[float, float, float],
    radius: float,
    depth: float,
    mat_index: int,
    segments: int = 16,
    rot_euler_rad: Tuple[float, float, float] = (0.0, 0.0, 0.0),
) -> None:
    """Adds an oriented cylinder into the BMesh."""
    rot_mat = Euler(rot_euler_rad, "XYZ").to_matrix().to_4x4()
    trans_mat = Matrix.Translation(center)
    xform = trans_mat @ rot_mat
    ret = bmesh.ops.create_cone(
        bm,
        cap_ends=True,
        cap_tris=False,
        segments=segments,
        radius1=radius,
        radius2=radius,
        depth=depth,
        matrix=xform,
    )
    verts = ret["verts"]
    new_faces = [f for f in bm.faces if all(v in verts for v in f.verts)]
    _assign_mat(new_faces, mat_index)


def _add_sphere(
    bm: bmesh.types.BMesh,
    center: Tuple[float, float, float],
    radius: float,
    mat_index: int,
    u_segments: int = 16,
    v_segments: int = 10,
    scale: Tuple[float, float, float] = (1.0, 1.0, 1.0),
) -> None:
    """Adds a UV sphere (used for LED domes) into the BMesh."""
    xform = Matrix.Translation(center) @ Matrix.Diagonal((scale[0], scale[1], scale[2], 1.0))
    ret = bmesh.ops.create_uvsphere(
        bm,
        u_segments=u_segments,
        v_segments=v_segments,
        radius=radius,
        matrix=xform,
    )
    verts = ret["verts"]
    new_faces = [f for f in bm.faces if all(v in verts for v in f.verts)]
    _assign_mat(new_faces, mat_index)


def _add_wedge_ramp(
    bm: bmesh.types.BMesh,
    width: float,
    y_start: float,
    y_end: float,
    z_start: float,
    z_end: float,
    thickness: float,
    mat_index: int,
) -> None:
    """Creates a sloped ramp slab from (y_start, z_start) down to (y_end, z_end)."""
    length = math.hypot(y_end - y_start, z_start - z_end)
    slope_angle = math.atan2(z_start - z_end, y_end - y_start)
    mid_y = 0.5 * (y_start + y_end)
    mid_z = 0.5 * (z_start + z_end) - 0.5 * thickness * math.cos(slope_angle)
    _add_transformed_box(
        bm,
        center=(0.0, mid_y, mid_z),
        size=(width, length, thickness),
        mat_index=mat_index,
        rot_euler_rad=(-slope_angle, 0.0, 0.0),
    )


# =============================================================================
# 1. PLATFORM, INCLINED DESCENT RAMP & ANTI-SLIP STRIP
# =============================================================================

DECK_Z = 1.40
RAMP_Y_START = 0.50
RAMP_Y_END = 8.50
RAMP_SLOPE_RAD = math.atan2(DECK_Z, RAMP_Y_END - RAMP_Y_START)


def _build_platform_and_ramp(bm: bmesh.types.BMesh) -> None:
    """Constructs the elevated start platform, inclined descent ramp, anti-slip strip, and stairs."""
    # Main elevated start deck (Y: -4.50 to +0.50, X: -2.60 to +2.60)
    _add_transformed_box(bm, center=(0.0, -2.0, DECK_Z - 0.08), size=(5.20, 5.00, 0.16), mat_index=MAT_DECK_COMPOSITE)
    # Burgundy perimeter fascia trim on main platform
    _add_transformed_box(bm, center=(-2.62, -2.0, DECK_Z - 0.12), size=(0.06, 5.04, 0.24), mat_index=MAT_BURGUNDY_ACCENT)
    _add_transformed_box(bm, center=(2.62, -2.0, DECK_Z - 0.12), size=(0.06, 5.04, 0.24), mat_index=MAT_BURGUNDY_ACCENT)
    _add_transformed_box(bm, center=(0.0, -4.52, DECK_Z - 0.12), size=(5.28, 0.06, 0.24), mat_index=MAT_BURGUNDY_ACCENT)

    # Structural steel support legs & under-deck longitudinal beams (#181B22)
    for lx in (-2.35, -1.15, 1.15, 2.35):
        _add_transformed_box(bm, center=(lx, -2.0, DECK_Z - 0.24), size=(0.14, 4.80, 0.18), mat_index=MAT_DARK_GRAPHITE)
        for ly in (-4.20, -2.00, 0.25):
            _add_transformed_box(bm, center=(lx, ly, (DECK_Z - 0.16) * 0.5), size=(0.14, 0.14, DECK_Z - 0.16), mat_index=MAT_DARK_GRAPHITE)
            _add_transformed_box(bm, center=(lx, ly, 0.03), size=(0.28, 0.28, 0.06), mat_index=MAT_DARK_GRAPHITE)

    # Cross bracing under platform
    for ly in (-4.20, 0.25):
        _add_transformed_box(bm, center=(0.0, ly, 0.65), size=(4.70, 0.08, 0.10), mat_index=MAT_DARK_GRAPHITE)

    # Inclined descent ramp (Y: 0.50 -> 8.50, Z: 1.40 -> 0.00, width: 2.80m)
    _add_wedge_ramp(
        bm,
        width=2.80,
        y_start=RAMP_Y_START,
        y_end=RAMP_Y_END,
        z_start=DECK_Z,
        z_end=0.0,
        thickness=0.14,
        mat_index=MAT_DECK_COMPOSITE,
    )

    # Ramp side steel stringers & burgundy branding skirts
    ramp_len = math.hypot(RAMP_Y_END - RAMP_Y_START, DECK_Z)
    mid_y = 0.5 * (RAMP_Y_START + RAMP_Y_END)
    mid_z = 0.5 * DECK_Z - 0.08
    for sx in (-1.42, 1.42):
        _add_transformed_box(
            bm,
            center=(sx, mid_y, mid_z),
            size=(0.08, ramp_len, 0.22),
            mat_index=MAT_DARK_GRAPHITE,
            rot_euler_rad=(-RAMP_SLOPE_RAD, 0.0, 0.0),
        )
        _add_transformed_box(
            bm,
            center=(sx + (0.045 if sx > 0 else -0.045), mid_y, mid_z - 0.04),
            size=(0.02, ramp_len * 0.94, 0.12),
            mat_index=MAT_BURGUNDY_ACCENT,
            rot_euler_rad=(-RAMP_SLOPE_RAD, 0.0, 0.0),
        )

    # Ramp intermediate steel support trestles
    for frac in (0.33, 0.66):
        ty = RAMP_Y_START + frac * (RAMP_Y_END - RAMP_Y_START)
        tz = DECK_Z * (1.0 - frac) - 0.14
        if tz > 0.08:
            for sx in (-1.28, 1.28):
                _add_transformed_box(bm, center=(sx, ty, tz * 0.5), size=(0.12, 0.12, tz), mat_index=MAT_DARK_GRAPHITE)
            _add_transformed_box(bm, center=(0.0, ty, tz * 0.45), size=(2.56, 0.07, 0.07), mat_index=MAT_DARK_GRAPHITE)

    # Ground transition lip at end of ramp
    _add_transformed_box(bm, center=(0.0, RAMP_Y_END + 0.22, 0.015), size=(2.88, 0.46, 0.03), mat_index=MAT_DARK_GRAPHITE)

    # Anti-slip rubberized center strip along flat deck (Y: -3.80 to 0.50)
    _add_transformed_box(bm, center=(0.0, -1.65, DECK_Z + 0.012), size=(1.10, 4.30, 0.024), mat_index=MAT_ANTISLIP_RUBBER)
    # Anti-slip center strip down the inclined ramp
    _add_wedge_ramp(
        bm,
        width=1.10,
        y_start=RAMP_Y_START,
        y_end=RAMP_Y_END - 0.05,
        z_start=DECK_Z + 0.024,
        z_end=0.024,
        thickness=0.024,
        mat_index=MAT_ANTISLIP_RUBBER,
    )

    # Transverse raised anti-slip grip cleats along the ramp (every 0.22m)
    num_cleats = 34
    for idx in range(num_cleats):
        t = (idx + 0.5) / num_cleats
        cy = RAMP_Y_START + t * (RAMP_Y_END - RAMP_Y_START - 0.15)
        cz = DECK_Z * (1.0 - t) + 0.028
        _add_transformed_box(
            bm,
            center=(0.0, cy, cz),
            size=(0.98, 0.05, 0.016),
            mat_index=MAT_DARK_GRAPHITE,
            rot_euler_rad=(-RAMP_SLOPE_RAD, 0.0, 0.0),
        )

    # Burgundy edge guide stripes flanking the anti-slip track
    for gx in (-0.58, 0.58):
        _add_transformed_box(bm, center=(gx, -1.65, DECK_Z + 0.014), size=(0.05, 4.30, 0.022), mat_index=MAT_BURGUNDY_ACCENT)
        _add_transformed_box(
            bm,
            center=(gx, mid_y, 0.5 * DECK_Z + 0.018),
            size=(0.05, ramp_len - 0.08, 0.022),
            mat_index=MAT_BURGUNDY_ACCENT,
            rot_euler_rad=(-RAMP_SLOPE_RAD, 0.0, 0.0),
        )

    # Championship Gold Start Line Strip at Y = +0.25m
    _add_transformed_box(bm, center=(0.0, 0.25, DECK_Z + 0.026), size=(1.22, 0.10, 0.008), mat_index=MAT_START_GOLD)

    # Ramp safety glass balustrades (left and right sides)
    for sx in (-1.36, 1.36):
        for frac in (0.05, 0.36, 0.68, 0.96):
            py = RAMP_Y_START + frac * (RAMP_Y_END - RAMP_Y_START)
            pz = DECK_Z * (1.0 - frac)
            _add_transformed_box(bm, center=(sx, py, pz + 0.48), size=(0.06, 0.06, 0.96), mat_index=MAT_DARK_GRAPHITE)
        # Sloped top handrail & glass panel
        _add_transformed_box(
            bm,
            center=(sx, mid_y, 0.5 * DECK_Z + 0.96),
            size=(0.05, ramp_len, 0.05),
            mat_index=MAT_BRUSHED_STEEL,
            rot_euler_rad=(-RAMP_SLOPE_RAD, 0.0, 0.0),
        )
        _add_transformed_box(
            bm,
            center=(sx, mid_y, 0.5 * DECK_Z + 0.48),
            size=(0.018, ramp_len * 0.92, 0.72),
            mat_index=MAT_ARCH_GLASS,
            rot_euler_rad=(-RAMP_SLOPE_RAD, 0.0, 0.0),
        )

    # Rear access staircase (Y: -4.50 down to -6.30)
    num_steps = 7
    for step_i in range(num_steps):
        sy = -4.65 - step_i * 0.25
        sz = DECK_Z - (step_i + 1) * (DECK_Z / num_steps)
        _add_transformed_box(bm, center=(0.0, sy, sz + 0.03), size=(1.60, 0.26, 0.06), mat_index=MAT_DARK_GRAPHITE)
        _add_transformed_box(bm, center=(0.0, sy, sz + 0.065), size=(1.50, 0.22, 0.012), mat_index=MAT_ANTISLIP_RUBBER)
    # Staircase stringers & handrails
    stair_angle = math.atan2(DECK_Z, 1.75)
    stair_len = math.hypot(1.75, DECK_Z)
    for sx in (-0.82, 0.82):
        _add_transformed_box(
            bm,
            center=(sx, -5.40, DECK_Z * 0.5),
            size=(0.06, stair_len, 0.14),
            mat_index=MAT_DARK_GRAPHITE,
            rot_euler_rad=(stair_angle, 0.0, 0.0),
        )
        _add_transformed_box(
            bm,
            center=(sx, -5.40, DECK_Z * 0.5 + 0.90),
            size=(0.04, stair_len, 0.04),
            mat_index=MAT_BRUSHED_STEEL,
            rot_euler_rad=(stair_angle, 0.0, 0.0),
        )
        _add_transformed_box(bm, center=(sx, -6.25, 0.45), size=(0.05, 0.05, 0.90), mat_index=MAT_DARK_GRAPHITE)


# =============================================================================
# 2. COVERED STEEL-AND-GLASS START PAVILION
# =============================================================================

ROOF_Z = 4.55


def _build_start_pavilion(bm: bmesh.types.BMesh) -> None:
    """Constructs the modern steel-and-glass start house (#181B22 & #8E4A49)."""
    col_height = ROOF_Z - DECK_Z
    col_z_mid = DECK_Z + col_height * 0.5

    # 6 structural steel columns (3 left, 3 right) with burgundy accent channels
    col_ys = (-4.15, -1.85, 0.35)
    for cx in (-2.48, 2.48):
        for cy in col_ys:
            _add_transformed_box(bm, center=(cx, cy, col_z_mid), size=(0.18, 0.18, col_height), mat_index=MAT_DARK_GRAPHITE)
            # Base mounting plate
            _add_transformed_box(bm, center=(cx, cy, DECK_Z + 0.02), size=(0.30, 0.30, 0.04), mat_index=MAT_BRUSHED_STEEL)
            # Outer burgundy vertical accent rib
            rib_x = cx + (0.095 if cx > 0 else -0.095)
            _add_transformed_box(bm, center=(rib_x, cy, col_z_mid), size=(0.025, 0.08, col_height * 0.92), mat_index=MAT_BURGUNDY_ACCENT)

    # Top longitudinal perimeter steel beams & burgundy fascia
    for cx in (-2.48, 2.48):
        _add_transformed_box(bm, center=(cx, -1.65, ROOF_Z - 0.08), size=(0.20, 5.60, 0.22), mat_index=MAT_DARK_GRAPHITE)
        # Side glass curtain walls (2 bays per side)
        for bay_y in (-3.00, -0.75):
            # Tempered glass pane
            _add_transformed_box(bm, center=(cx, bay_y, col_z_mid), size=(0.025, 2.12, col_height - 0.36), mat_index=MAT_ARCH_GLASS)
            # Horizontal middle transom bar in dark graphite + burgundy inlay
            _add_transformed_box(bm, center=(cx, bay_y, DECK_Z + 1.15), size=(0.09, 2.14, 0.07), mat_index=MAT_DARK_GRAPHITE)
            _add_transformed_box(
                bm,
                center=(cx + (0.05 if cx > 0 else -0.05), bay_y, DECK_Z + 1.15),
                size=(0.015, 2.10, 0.03),
                mat_index=MAT_BURGUNDY_ACCENT,
            )

    # Rear backdrop wall (Y = -4.15) leaving center doorway for stair access
    for side_x in (-1.68, 1.68):
        _add_transformed_box(bm, center=(side_x, -4.15, col_z_mid), size=(1.42, 0.12, col_height - 0.20), mat_index=MAT_DARK_GRAPHITE)
        _add_transformed_box(bm, center=(side_x, -4.08, DECK_Z + 1.55), size=(1.18, 0.03, 1.65), mat_index=MAT_BURGUNDY_ACCENT)
        _add_transformed_box(bm, center=(side_x, -4.06, DECK_Z + 2.55), size=(1.18, 0.03, 0.14), mat_index=MAT_START_GOLD)
    # Rear doorway lintel header
    _add_transformed_box(bm, center=(0.0, -4.15, DECK_Z + 2.55), size=(1.94, 0.16, 0.90), mat_index=MAT_DARK_GRAPHITE)
    _add_transformed_box(bm, center=(0.0, -4.06, DECK_Z + 2.55), size=(1.70, 0.03, 0.55), mat_index=MAT_BURGUNDY_ACCENT)

    # Cantilevered aerodynamic roof canopy (Y: -4.45 to +1.25, slight forward pitch)
    roof_pitch = math.radians(-2.5)
    _add_transformed_box(
        bm,
        center=(0.0, -1.60, ROOF_Z + 0.12),
        size=(5.40, 5.75, 0.18),
        mat_index=MAT_DARK_GRAPHITE,
        rot_euler_rad=(roof_pitch, 0.0, 0.0),
    )
    # Burgundy perimeter roof fascia band
    for fx in (-2.71, 2.71):
        _add_transformed_box(
            bm,
            center=(fx, -1.60, ROOF_Z + 0.12),
            size=(0.04, 5.78, 0.22),
            mat_index=MAT_BURGUNDY_ACCENT,
            rot_euler_rad=(roof_pitch, 0.0, 0.0),
        )
    _add_transformed_box(bm, center=(0.0, 1.28, ROOF_Z + 0.24), size=(5.44, 0.05, 0.22), mat_index=MAT_BURGUNDY_ACCENT)
    _add_transformed_box(bm, center=(0.0, -4.48, ROOF_Z + 0.00), size=(5.44, 0.05, 0.22), mat_index=MAT_BURGUNDY_ACCENT)

    # Exposed transverse steel roof rafters & recessed LED ceiling light strips
    for ry in (-3.70, -2.50, -1.30, -0.10, 0.85):
        rz = ROOF_Z - 0.02 + (ry + 1.60) * math.tan(-roof_pitch)
        _add_transformed_box(bm, center=(0.0, ry, rz), size=(4.85, 0.12, 0.14), mat_index=MAT_DARK_GRAPHITE)

    for lx in (-1.20, 1.20):
        _add_transformed_box(
            bm,
            center=(lx, -1.55, ROOF_Z - 0.01),
            size=(0.10, 4.40, 0.03),
            mat_index=MAT_LED_CLOCK_DIGITS,
            rot_euler_rad=(roof_pitch, 0.0, 0.0),
        )

    # Front platform side wing balustrades between pavilion front and ramp
    for side_sign in (-1.0, 1.0):
        _add_transformed_box(
            bm,
            center=(side_sign * 1.92, 0.46, DECK_Z + 0.48),
            size=(1.12, 0.05, 0.96),
            mat_index=MAT_ARCH_GLASS,
        )
        _add_transformed_box(
            bm,
            center=(side_sign * 1.92, 0.46, DECK_Z + 0.98),
            size=(1.14, 0.06, 0.05),
            mat_index=MAT_BRUSHED_STEEL,
        )


# =============================================================================
# 3. REAR-WHEEL TT STARTING STAND (STOJAK STARTOWY)
# =============================================================================

def _build_tt_starting_stand(bm: bmesh.types.BMesh) -> None:
    """Constructs the rear-wheel TT bike holding stand at (0.0, -0.75, DECK_Z)."""
    stand_y = -0.75
    base_z = DECK_Z + 0.024  # sits atop the anti-slip rubber strip

    # Heavy bolted steel base plate
    _add_transformed_box(bm, center=(0.0, stand_y, base_z + 0.02), size=(0.56, 0.62, 0.04), mat_index=MAT_DARK_GRAPHITE)
    for bx in (-0.23, 0.23):
        for by in (stand_y - 0.25, stand_y + 0.25):
            _add_cylinder(bm, center=(bx, by, base_z + 0.045), radius=0.016, depth=0.02, mat_index=MAT_BRUSHED_STEEL, segments=8)

    # Burgundy hydraulic/pneumatic actuator housing behind rear wheel
    _add_transformed_box(bm, center=(0.0, stand_y - 0.18, base_z + 0.14), size=(0.24, 0.20, 0.22), mat_index=MAT_BURGUNDY_ACCENT)
    # Brushed steel pneumatic release piston rod
    _add_cylinder(
        bm,
        center=(0.0, stand_y - 0.02, base_z + 0.16),
        radius=0.022,
        depth=0.22,
        mat_index=MAT_BRUSHED_STEEL,
        segments=12,
        rot_euler_rad=(math.radians(90.0), 0.0, 0.0),
    )

    # Dual articulated clamping arms & rubber-padded tire jaws (gripping 700c rear wheel)
    for side in (-1.0, 1.0):
        # Vertical pivot stanchion
        _add_transformed_box(bm, center=(side * 0.18, stand_y, base_z + 0.20), size=(0.06, 0.10, 0.34), mat_index=MAT_DARK_GRAPHITE)
        # Angled upper clamp arm
        _add_transformed_box(
            bm,
            center=(side * 0.11, stand_y, base_z + 0.38),
            size=(0.05, 0.14, 0.18),
            mat_index=MAT_DARK_GRAPHITE,
            rot_euler_rad=(0.0, side * math.radians(24.0), 0.0),
        )
        # Rubberized tire-grip jaw pad
        _add_transformed_box(
            bm,
            center=(side * 0.055, stand_y, base_z + 0.42),
            size=(0.032, 0.16, 0.12),
            mat_index=MAT_ANTISLIP_RUBBER,
        )
        # Burgundy arm accent cap
        _add_transformed_box(
            bm,
            center=(side * 0.18, stand_y, base_z + 0.37),
            size=(0.068, 0.108, 0.03),
            mat_index=MAT_BURGUNDY_ACCENT,
        )

    # Side mechanical release lever & timing trigger box
    _add_transformed_box(bm, center=(0.30, stand_y - 0.06, base_z + 0.10), size=(0.10, 0.16, 0.12), mat_index=MAT_DARK_GRAPHITE)
    _add_cylinder(
        bm,
        center=(0.30, stand_y - 0.06, base_z + 0.24),
        radius=0.012,
        depth=0.22,
        mat_index=MAT_BRUSHED_STEEL,
        segments=10,
        rot_euler_rad=(math.radians(-18.0), 0.0, 0.0),
    )
    _add_sphere(bm, center=(0.30, stand_y - 0.095, base_z + 0.35), radius=0.024, mat_index=MAT_BURGUNDY_ACCENT)


# =============================================================================
# 4. ELECTRONIC COUNTDOWN CLOCK GATE WITH RED / YELLOW / GREEN LEDS
# =============================================================================

def _add_seven_segment_char(
    bm: bmesh.types.BMesh,
    center: Tuple[float, float, float],
    char: str,
    scale: float,
    mat_index: int,
) -> None:
    """Adds a crisp 3D 7-segment LED digit or colon facing +Y and -Y."""
    # Segment bitmask: A(top), B(tr), C(br), D(bot), E(bl), F(tl), G(mid)
    seg_map = {
        "0": "ABCDEF",
        "1": "BC",
        "2": "ABDEG",
        "3": "ABCDG",
        "4": "BCFG",
        "5": "ACDFG",
        "6": "ACDEFG",
        "7": "ABC",
        "8": "ABCDEFG",
        "9": "ABCDFG",
    }
    cx, cy, cz = center
    if char == ":":
        for dz in (-0.18 * scale, 0.18 * scale):
            _add_transformed_box(bm, center=(cx, cy, cz + dz), size=(0.10 * scale, 0.04, 0.10 * scale), mat_index=mat_index)
        return

    active = seg_map.get(char, "")
    w = 0.42 * scale
    h = 0.42 * scale
    t = 0.08 * scale
    depth = 0.035

    if "A" in active:
        _add_transformed_box(bm, center=(cx, cy, cz + h), size=(w, depth, t), mat_index=mat_index)
    if "G" in active:
        _add_transformed_box(bm, center=(cx, cy, cz), size=(w, depth, t), mat_index=mat_index)
    if "D" in active:
        _add_transformed_box(bm, center=(cx, cy, cz - h), size=(w, depth, t), mat_index=mat_index)
    if "F" in active:
        _add_transformed_box(bm, center=(cx - w * 0.5, cy, cz + h * 0.5), size=(t, depth, h), mat_index=mat_index)
    if "B" in active:
        _add_transformed_box(bm, center=(cx + w * 0.5, cy, cz + h * 0.5), size=(t, depth, h), mat_index=mat_index)
    if "E" in active:
        _add_transformed_box(bm, center=(cx - w * 0.5, cy, cz - h * 0.5), size=(t, depth, h), mat_index=mat_index)
    if "C" in active:
        _add_transformed_box(bm, center=(cx + w * 0.5, cy, cz - h * 0.5), size=(t, depth, h), mat_index=mat_index)


def _add_led_signal_module(
    bm: bmesh.types.BMesh,
    center: Tuple[float, float, float],
    radius: float,
    led_mat_index: int,
) -> None:
    """Adds a recessed dark-graphite LED bezel, sun visor hood, and emissive dome."""
    cx, cy, cz = center
    # Cylindrical bezel housing (oriented along Y)
    _add_cylinder(
        bm,
        center=(cx, cy, cz),
        radius=radius * 1.24,
        depth=0.10,
        mat_index=MAT_DARK_GRAPHITE,
        segments=20,
        rot_euler_rad=(math.radians(90.0), 0.0, 0.0),
    )
    # Sun visor hood above LED
    _add_transformed_box(
        bm,
        center=(cx, cy + 0.04, cz + radius * 1.15),
        size=(radius * 2.2, 0.10, 0.02),
        mat_index=MAT_DARK_GRAPHITE,
    )
    # Emissive LED lens visible from both +Y (broadcast) and -Y (rider)
    _add_sphere(
        bm,
        center=(cx, cy, cz),
        radius=radius,
        mat_index=led_mat_index,
        u_segments=16,
        v_segments=10,
        scale=(1.0, 0.65, 1.0),
    )


def _build_countdown_clock_gate(bm: bmesh.types.BMesh) -> None:
    """Constructs the overhead electronic countdown clock gantry & rider-level LED console."""
    gate_y = 0.55
    gantry_z = 4.18

    # Overhead timing gantry housing spanning the front of the pavilion
    _add_transformed_box(bm, center=(0.0, gate_y, gantry_z), size=(3.90, 0.34, 0.72), mat_index=MAT_DARK_GRAPHITE)
    # Burgundy aerodynamic side wing fairings on the gantry
    for side in (-1.0, 1.0):
        _add_transformed_box(bm, center=(side * 2.18, gate_y, gantry_z), size=(0.48, 0.38, 0.60), mat_index=MAT_BURGUNDY_ACCENT)
        _add_transformed_box(bm, center=(side * 2.42, gate_y, gantry_z), size=(0.08, 0.42, 0.68), mat_index=MAT_START_GOLD)

    # Dark glass electronic clock display face (double-sided)
    _add_transformed_box(bm, center=(-0.38, gate_y, gantry_z), size=(1.95, 0.36, 0.52), mat_index=MAT_CLOCK_DISPLAY_FACE)

    # 7-segment LED countdown digits "00:05"
    digit_specs = [(-1.05, "0"), (-0.65, "0"), (-0.38, ":"), (-0.11, "0"), (0.29, "5")]
    for dx, ch in digit_specs:
        _add_seven_segment_char(bm, center=(dx, gate_y, gantry_z), char=ch, scale=0.40, mat_index=MAT_LED_CLOCK_DIGITS)

    # Three large horizontal LED signal lamps (Red, Yellow, Green) on the overhead gantry
    led_specs = [
        (0.86, MAT_LED_RED),
        (1.22, MAT_LED_YELLOW),
        (1.58, MAT_LED_GREEN),
    ]
    for lx, led_mat in led_specs:
        _add_led_signal_module(bm, center=(lx, gate_y, gantry_z), radius=0.11, led_mat_index=led_mat)

    # Rider eye-level vertical countdown console on right side of start gate
    console_x = 0.88
    console_y = 0.44
    _add_transformed_box(bm, center=(console_x, console_y, DECK_Z + 0.56), size=(0.08, 0.08, 1.12), mat_index=MAT_DARK_GRAPHITE)
    _add_transformed_box(bm, center=(console_x, console_y, DECK_Z + 1.16), size=(0.34, 0.16, 0.68), mat_index=MAT_DARK_GRAPHITE)
    _add_transformed_box(bm, center=(console_x, console_y - 0.082, DECK_Z + 1.16), size=(0.28, 0.02, 0.60), mat_index=MAT_CLOCK_DISPLAY_FACE)
    # Burgundy console top cap
    _add_transformed_box(bm, center=(console_x, console_y, DECK_Z + 1.51), size=(0.36, 0.18, 0.04), mat_index=MAT_BURGUNDY_ACCENT)

    # Vertical traffic-light LED stack on rider console (Red top, Yellow mid, Green bottom)
    for cz_off, led_mat in (
        (1.34, MAT_LED_RED),
        (1.16, MAT_LED_YELLOW),
        (0.98, MAT_LED_GREEN),
    ):
        _add_led_signal_module(bm, center=(console_x, console_y - 0.03, DECK_Z + cz_off), radius=0.058, led_mat_index=led_mat)

    # Photoelectric start-gate timing sensor posts at Y = +0.25m
    for sx in (-0.98, 0.98):
        _add_transformed_box(bm, center=(sx, 0.25, DECK_Z + 0.38), size=(0.07, 0.07, 0.76), mat_index=MAT_DARK_GRAPHITE)
        _add_transformed_box(bm, center=(sx, 0.25, DECK_Z + 0.78), size=(0.09, 0.09, 0.04), mat_index=MAT_BURGUNDY_ACCENT)
        _add_sphere(bm, center=(sx + (-0.038 if sx > 0 else 0.038), 0.25, DECK_Z + 0.52), radius=0.018, mat_index=MAT_LED_RED)


# =============================================================================
# MAIN GENERATOR & GLB EXPORT
# =============================================================================

def generate_time_trial_start_ramp_mesh(
    name: str = "TT_Start_Pavilion_And_Ramp",
    location: Tuple[float, float, float] = (0.0, 0.0, 0.0),
) -> bpy.types.Object:
    """Generates the complete Time Trial Start Pavilion & Ramp mesh object."""
    materials = create_tt_ramp_materials()
    obj, mesh, bm = _create_mesh_object(name, materials)

    _build_platform_and_ramp(bm)
    _build_start_pavilion(bm)
    _build_tt_starting_stand(bm)
    _build_countdown_clock_gate(bm)

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()

    obj.location = location
    sm.clean_zwift_mesh(obj, merge_distance=0.0005)
    sm.apply_zwift_style(obj, auto_smooth_angle_deg=35.0)
    return obj


def export_glb(
    objects: Union[bpy.types.Object, List[bpy.types.Object]],
    filepath: str,
) -> str:
    """Exports one or more Blender objects to a binary glTF 2.0 (.glb) file."""
    if isinstance(objects, bpy.types.Object):
        objects = [objects]

    os.makedirs(os.path.dirname(os.path.abspath(filepath)), exist_ok=True)

    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        if obj.name not in bpy.context.scene.objects:
            bpy.context.scene.collection.objects.link(obj)
        obj.select_set(True)

    bpy.context.view_layer.objects.active = objects[0]

    export_kwargs = {
        "filepath": filepath,
        "export_format": "GLB",
        "use_selection": True,
        "export_apply": True,
        "export_yup": True,
        "export_materials": "EXPORT",
    }
    if hasattr(bpy.types, "GLTF_OT_export"):
        export_kwargs["export_draco_mesh_compression_enable"] = False

    try:
        bpy.ops.export_scene.gltf(**export_kwargs)
    except TypeError:
        bpy.ops.export_scene.gltf(
            filepath=filepath,
            export_format="GLB",
            use_selection=True,
            export_apply=True,
        )

    size_kb = os.path.getsize(filepath) / 1024.0
    print(f"[EXPORT] {[o.name for o in objects]} -> '{filepath}' ({size_kb:.1f} KB)")
    return filepath


def export_time_trial_start_ramp(
    output_dir: str = "assets/3d/environment",
) -> Dict[str, str]:
    """Generates and exports the TT Start Pavilion & Ramp to `tt_start_ramp.glb`."""
    for obj in list(bpy.context.scene.objects):
        if obj.type == "MESH":
            bpy.data.objects.remove(obj, do_unlink=True)

    os.makedirs(output_dir, exist_ok=True)
    ramp_obj = generate_time_trial_start_ramp_mesh(location=(0.0, 0.0, 0.0))

    glb_path = os.path.join(output_dir, "tt_start_ramp.glb")
    exported_path = export_glb(ramp_obj, glb_path)

    bpy.data.objects.remove(ramp_obj, do_unlink=True)
    return {"tt_start_ramp": exported_path}


if __name__ == "__main__":
    out_dir = "assets/3d/environment"
    for idx, arg in enumerate(sys.argv):
        if arg in ["--output-dir", "-o"] and idx + 1 < len(sys.argv):
            out_dir = sys.argv[idx + 1]

    files = export_time_trial_start_ramp(output_dir=out_dir)
    sm.setup_zwift_studio_lighting()
    print(f"[SUCCESS] Time Trial Start Pavilion & Ramp generated: {files}")
