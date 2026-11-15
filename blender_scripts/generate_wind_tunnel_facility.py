"""
===============================================================================
PRO PELOTON MANAGER - WIND TUNNEL TESTING CHAMBER GENERATOR
===============================================================================
Blender 5.3 Python API (bpy) script that procedurally models the 3D
Aerodynamic Wind Tunnel Testing Facility (`assets/3d/environment/wind_tunnel_room.glb`):

  1. Cylindrical Air Duct (`WindTunnel_Chamber`):
     - Flat-floor aerodynamic test section inside a 13.3 m cylindrical duct
       (R = 3.10 m) with structural graphite steel ribs, segmented wall panels,
       observation window bay, and recessed pit for the yaw turntable.
     - Huge 12-blade composite carbon fan rotor (`WindTunnel_Fan_Rotor`) with
       aerodynamic twisted airfoil blades, central nosecone spinner, outer shroud,
       and rear stator struts in the background.
     - Flow straightener honeycomb/louver grid (`WindTunnel_Flow_Straightener`)
       upstream of the test section.

  2. Rotating Yaw Platform & Telemetry Equipment:
     - Flush rotating floor turntable (`WindTunnel_Yaw_Turntable`, R = 1.65 m)
       engineered for crosswind yaw testing (-15 deg to +15 deg) with gold
       degree scale ticks (-15, -10, -5, 0, +5, +10, +15), burgundy pointer,
       and front/rear brushed-steel bicycle wheel rollers.
     - Wall-mounted & overhead LED light strips (`WindTunnel_LED_Strips`) in
       telemetry cyan (#00E5FF) and studio white (#F8FAFC).
     - Articulated floor-mounted smoke rake nozzle (`WindTunnel_Smoke_Nozzle`)
       positioned ahead of the front wheel, emitting 6 translucent aerodynamic
       smoke streamlines (`WindTunnel_Smoke_Streams`).

Usage:
  blender --background --python blender_scripts/generate_wind_tunnel_facility.py
  blender --background --python blender_scripts/generate_wind_tunnel_facility.py -- --output-dir assets/3d/environment

Compatible with Blender 3.6 LTS, 4.x, and 5.3+.
===============================================================================
"""

import math
import os
import sys
from typing import Dict, List, Optional, Sequence, Tuple, Union

try:
    import bpy
    import bmesh
    from mathutils import Euler, Matrix, Vector
except ImportError:
    print("[ERROR] 'bpy' / 'mathutils' module not found. Run within Blender:")
    print("        blender --background --python blender_scripts/generate_wind_tunnel_facility.py")
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
# MATERIAL INDICES
# =============================================================================

WTMAT_GRAPHITE = 0       # #181B22 structural ribs & fan housing
WTMAT_SURFACE_DARK = 1   # #222630 aerodynamic wall panels
WTMAT_FLOOR_DECK = 2     # #13161C anti-slip test chamber floor
WTMAT_TURNTABLE = 3      # #1E222B brushed anodized yaw turntable disc
WTMAT_BURGUNDY = 4       # #8E4A49 Pro Peloton Manager accent trim
WTMAT_GOLD = 5           # #D4AF37 precision yaw degree scale markers
WTMAT_BRUSHED_STEEL = 6  # #94A3B8 wheel rollers, smoke wand, hardware
WTMAT_CARBON_BLADE = 7   # #1A1D24 12-blade fan rotor & stator vanes
WTMAT_HONEYCOMB = 8      # #475569 flow straightener louver grid
WTMAT_LED_CYAN = 9       # #00E5FF telemetry LED wall & floor strips
WTMAT_LED_WHITE = 10     # #F8FAFC overhead studio LED light bars
WTMAT_SMOKE_STREAM = 11  # #E0F2FE translucent smoke streamlines


# =============================================================================
# TUNNEL DIMENSIONS (METERS, +Y = UPSTREAM)
# =============================================================================

TUNNEL_CENTER_Z = 1.40
TUNNEL_RADIUS_INNER = 3.10
TUNNEL_RADIUS_OUTER = 3.32
TUNNEL_Y_MIN = -5.50
TUNNEL_Y_MAX = 7.80
FAN_Y = 7.10
STRAIGHTENER_Y = 5.15
TURNTABLE_RADIUS = 1.65
FRONT_WHEEL_Y = 0.52
REAR_WHEEL_Y = -0.52
SMOKE_NOZZLE_Y = 1.48


# =============================================================================
# PBR MATERIAL FACTORY
# =============================================================================

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
        sm._set_bsdf_socket(
            bsdf,
            ["Emission Color", "Emission"],
            sm.hex_to_linear_rgb(emission_color),
        )
        sm._set_bsdf_socket(bsdf, ["Emission Strength"], emission_strength)

    return mat


def create_wind_tunnel_materials() -> List[bpy.types.Material]:
    """Builds the ordered PBR material palette for the wind tunnel testing chamber."""
    return [
        # 0: Dark graphite structural frame (#181B22)
        _make_pbr_material("Mat_WT_Graphite", "#181B22", roughness=0.40, metallic=0.72),
        # 1: Aerodynamic wall panels (#222630)
        _make_pbr_material("Mat_WT_Surface_Dark", "#222630", roughness=0.48, metallic=0.25),
        # 2: Anti-slip test chamber floor (#13161C)
        _make_pbr_material("Mat_WT_Floor_Deck", "#13161C", roughness=0.58, metallic=0.14),
        # 3: Brushed anodized yaw turntable disc (#1E222B)
        _make_pbr_material("Mat_WT_Turntable", "#1E222B", roughness=0.32, metallic=0.68),
        # 4: Pro Peloton Manager burgundy accent (#8E4A49)
        _make_pbr_material("Mat_WT_Burgundy", "#8E4A49", roughness=0.36, metallic=0.35),
        # 5: Precision gold yaw scale markers (#D4AF37)
        _make_pbr_material("Mat_WT_Gold", "#D4AF37", roughness=0.20, metallic=0.96),
        # 6: Brushed steel rollers & smoke nozzle (#94A3B8)
        _make_pbr_material("Mat_WT_Brushed_Steel", "#94A3B8", roughness=0.24, metallic=0.92),
        # 7: Composite carbon fan blades (#1A1D24)
        _make_pbr_material("Mat_WT_Carbon_Blade", "#1A1D24", roughness=0.25, metallic=0.32),
        # 8: Flow straightener honeycomb metal (#475569)
        _make_pbr_material("Mat_WT_Honeycomb", "#475569", roughness=0.38, metallic=0.80),
        # 9: Telemetry cyan LED strip (#00E5FF)
        _make_pbr_material(
            "Mat_WT_LED_Cyan",
            "#00E5FF",
            roughness=0.15,
            metallic=0.0,
            emission_color="#00E5FF",
            emission_strength=4.8,
        ),
        # 10: Studio white overhead LED bar (#F8FAFC)
        _make_pbr_material(
            "Mat_WT_LED_White",
            "#F8FAFC",
            roughness=0.15,
            metallic=0.0,
            emission_color="#E2E8F0",
            emission_strength=3.8,
        ),
        # 11: Translucent aerodynamic smoke streamlines
        _make_pbr_material(
            "Mat_WT_Smoke_Stream",
            "#E0F2FE",
            roughness=0.85,
            metallic=0.0,
            alpha=0.36,
            emission_color="#38BDF8",
            emission_strength=0.65,
        ),
    ]


# =============================================================================
# BMESH GEOMETRY HELPERS
# =============================================================================

def _create_mesh_object(
    name: str,
    materials: Sequence[bpy.types.Material],
) -> Tuple[bpy.types.Object, bpy.types.Mesh, bmesh.types.BMesh]:
    """Creates a new Blender mesh object with pre-assigned material slots."""
    mesh = bpy.data.meshes.new(f"{name}_Mesh")
    for mat in materials:
        mesh.materials.append(mat)

    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    bm = bmesh.new()
    return obj, mesh, bm


def _finalize_mesh_object(
    obj: bpy.types.Object,
    mesh: bpy.types.Mesh,
    bm: bmesh.types.BMesh,
    location: Tuple[float, float, float] = (0.0, 0.0, 0.0),
    auto_smooth_deg: float = 35.0,
) -> bpy.types.Object:
    """Finalizes bmesh into the mesh data-block and applies clean shading."""
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()

    obj.location = Vector(location)
    sm.apply_zwift_style(obj, auto_smooth_angle_deg=auto_smooth_deg)
    return obj


def _assign_mat(faces: Sequence[bmesh.types.BMFace], mat_idx: int) -> None:
    """Assigns a material index to all given bmesh faces."""
    for f in faces:
        f.material_index = mat_idx


def _add_box(
    bm: bmesh.types.BMesh,
    center: Tuple[float, float, float],
    size: Tuple[float, float, float],
    mat_idx: int,
    rot_euler_rad: Tuple[float, float, float] = (0.0, 0.0, 0.0),
) -> List[bmesh.types.BMFace]:
    """Adds an oriented box centered at `center` with full dimensions `size`."""
    sx, sy, sz = size
    mat_rot = Euler(rot_euler_rad, "XYZ").to_matrix().to_4x4()
    mat_scale = Matrix.Diagonal((sx, sy, sz, 1.0))
    mat_trans = Matrix.Translation(Vector(center))
    xform = mat_trans @ mat_rot @ mat_scale

    res = bmesh.ops.create_cube(bm, size=1.0, matrix=xform)
    verts = res["verts"]
    faces = list({f for v in verts for f in v.link_faces})
    _assign_mat(faces, mat_idx)
    return faces


def _add_cylinder(
    bm: bmesh.types.BMesh,
    center: Tuple[float, float, float],
    radius1: float,
    radius2: float,
    depth: float,
    mat_idx: int,
    segments: int = 32,
    rot_euler_rad: Tuple[float, float, float] = (0.0, 0.0, 0.0),
    cap_ends: bool = True,
) -> List[bmesh.types.BMFace]:
    """Adds an oriented cylinder/cone centered at `center`."""
    mat_rot = Euler(rot_euler_rad, "XYZ").to_matrix().to_4x4()
    mat_trans = Matrix.Translation(Vector(center))
    xform = mat_trans @ mat_rot

    res = bmesh.ops.create_cone(
        bm,
        cap_ends=cap_ends,
        cap_tris=False,
        segments=segments,
        radius1=radius1,
        radius2=radius2,
        depth=depth,
        matrix=xform,
    )
    verts = res["verts"]
    faces = list({f for v in verts for f in v.link_faces})
    _assign_mat(faces, mat_idx)
    return faces


def _add_arc_ring(
    bm: bmesh.types.BMesh,
    center: Tuple[float, float, float],
    r_inner: float,
    r_outer: float,
    y_depth: float,
    mat_idx: int,
    segments: int = 48,
    angle_start_rad: float = 0.0,
    angle_end_rad: float = 2.0 * math.pi,
) -> List[bmesh.types.BMFace]:
    """
    Builds a cylindrical ring/arch extruded along the Y axis in the X-Z plane
    around `center`. Angles are measured in X-Z: 0 = +X, pi/2 = +Z.
    """
    cx, cy, cz = center
    half_y = y_depth * 0.5
    closed_loop = abs((angle_end_rad - angle_start_rad) - 2.0 * math.pi) < 1e-4

    ring_verts_front_in: List[bmesh.types.BMVert] = []
    ring_verts_front_out: List[bmesh.types.BMVert] = []
    ring_verts_back_in: List[bmesh.types.BMVert] = []
    ring_verts_back_out: List[bmesh.types.BMVert] = []

    steps = segments if closed_loop else segments + 1
    for i in range(steps):
        t = i / segments
        ang = angle_start_rad + t * (angle_end_rad - angle_start_rad)
        cos_a = math.cos(ang)
        sin_a = math.sin(ang)

        xi, zi = cx + r_inner * cos_a, cz + r_inner * sin_a
        xo, zo = cx + r_outer * cos_a, cz + r_outer * sin_a

        ring_verts_front_in.append(bm.verts.new((xi, cy - half_y, zi)))
        ring_verts_front_out.append(bm.verts.new((xo, cy - half_y, zo)))
        ring_verts_back_in.append(bm.verts.new((xi, cy + half_y, zi)))
        ring_verts_back_out.append(bm.verts.new((xo, cy + half_y, zo)))

    faces: List[bmesh.types.BMFace] = []
    quad_count = segments if closed_loop else segments
    for i in range(quad_count):
        j = (i + 1) % segments if closed_loop else i + 1
        # Inner wall
        faces.append(bm.faces.new((
            ring_verts_front_in[i],
            ring_verts_back_in[i],
            ring_verts_back_in[j],
            ring_verts_front_in[j],
        )))
        # Outer wall
        faces.append(bm.faces.new((
            ring_verts_front_out[i],
            ring_verts_front_out[j],
            ring_verts_back_out[j],
            ring_verts_back_out[i],
        )))
        # Front cap (-Y)
        faces.append(bm.faces.new((
            ring_verts_front_in[i],
            ring_verts_front_in[j],
            ring_verts_front_out[j],
            ring_verts_front_out[i],
        )))
        # Back cap (+Y)
        faces.append(bm.faces.new((
            ring_verts_back_in[i],
            ring_verts_back_out[i],
            ring_verts_back_out[j],
            ring_verts_back_in[j],
        )))

    if not closed_loop:
        faces.append(bm.faces.new((
            ring_verts_front_in[0],
            ring_verts_front_out[0],
            ring_verts_back_out[0],
            ring_verts_back_in[0],
        )))
        faces.append(bm.faces.new((
            ring_verts_front_in[-1],
            ring_verts_back_in[-1],
            ring_verts_back_out[-1],
            ring_verts_front_out[-1],
        )))

    _assign_mat(faces, mat_idx)
    return faces


def _add_tube_along_points(
    bm: bmesh.types.BMesh,
    points: Sequence[Tuple[float, float, float]],
    radii: Sequence[float],
    mat_idx: int,
    segments: int = 10,
) -> List[bmesh.types.BMFace]:
    """Sweeps a circular cross-section along a 3D polyline with per-point radius."""
    if len(points) < 2:
        return []

    rings: List[List[bmesh.types.BMVert]] = []
    up_ref = Vector((0.0, 0.0, 1.0))

    for idx, pt in enumerate(points):
        p = Vector(pt)
        if idx == 0:
            tangent = (Vector(points[1]) - p).normalized()
        elif idx == len(points) - 1:
            tangent = (p - Vector(points[-2])).normalized()
        else:
            tangent = (Vector(points[idx + 1]) - Vector(points[idx - 1])).normalized()

        if abs(tangent.dot(up_ref)) > 0.95:
            side = tangent.cross(Vector((1.0, 0.0, 0.0))).normalized()
        else:
            side = tangent.cross(up_ref).normalized()
        binorm = side.cross(tangent).normalized()

        r = radii[idx]
        ring: List[bmesh.types.BMVert] = []
        for s in range(segments):
            ang = 2.0 * math.pi * s / segments
            offset = (side * math.cos(ang) + binorm * math.sin(ang)) * r
            ring.append(bm.verts.new(p + offset))
        rings.append(ring)

    faces: List[bmesh.types.BMFace] = []
    for i in range(len(rings) - 1):
        r0 = rings[i]
        r1 = rings[i + 1]
        for s in range(segments):
            sn = (s + 1) % segments
            faces.append(bm.faces.new((r0[s], r0[sn], r1[sn], r1[s])))

    # Cap ends
    faces.append(bm.faces.new(list(reversed(rings[0]))))
    faces.append(bm.faces.new(rings[-1]))

    _assign_mat(faces, mat_idx)
    return faces


# =============================================================================
# 1. CYLINDRICAL AIR DUCT & TEST FLOOR
# =============================================================================

def _build_cylindrical_air_duct(bm: bmesh.types.BMesh) -> None:
    """
    Builds the cylindrical wind tunnel air duct, flat test floor with recessed
    turntable pit, structural arch ribs, and upstream contraction collar.
    """
    tunnel_len = TUNNEL_Y_MAX - TUNNEL_Y_MIN
    tunnel_mid_y = 0.5 * (TUNNEL_Y_MAX + TUNNEL_Y_MIN)

    # Compute the arc angles where the cylinder intersects the Z=0 floor plane
    # z = TUNNEL_CENTER_Z + R * sin(angle) = 0  => sin(angle) = -1.40 / 3.10
    sin_floor = -TUNNEL_CENTER_Z / TUNNEL_RADIUS_INNER
    angle_floor_right = math.asin(sin_floor)          # ~ -0.468 rad (-26.8 deg)
    angle_floor_left = math.pi - angle_floor_right    # ~ +3.610 rad (+206.8 deg)

    # Main arched cylindrical shell from floor-right over the top to floor-left
    _add_arc_ring(
        bm,
        center=(0.0, tunnel_mid_y, TUNNEL_CENTER_Z),
        r_inner=TUNNEL_RADIUS_INNER,
        r_outer=TUNNEL_RADIUS_OUTER,
        y_depth=tunnel_len,
        mat_idx=WTMAT_SURFACE_DARK,
        segments=56,
        angle_start_rad=angle_floor_right,
        angle_end_rad=angle_floor_left,
    )

    # Full circular rear housing around the fan & flow straightener (Y = +4.80 to +7.80)
    _add_arc_ring(
        bm,
        center=(0.0, 6.30, TUNNEL_CENTER_Z),
        r_inner=TUNNEL_RADIUS_INNER - 0.04,
        r_outer=TUNNEL_RADIUS_OUTER + 0.06,
        y_depth=3.00,
        mat_idx=WTMAT_GRAPHITE,
        segments=56,
    )

    # Structural heavy steel arch ribs spaced along the tunnel
    rib_y_positions = [-5.30, -3.50, -1.75, 0.00, 1.75, 3.50, 4.95, 6.40, 7.72]
    for y_pos in rib_y_positions:
        is_rear = y_pos >= 4.90
        _add_arc_ring(
            bm,
            center=(0.0, y_pos, TUNNEL_CENTER_Z),
            r_inner=TUNNEL_RADIUS_INNER - 0.08,
            r_outer=TUNNEL_RADIUS_OUTER + 0.16,
            y_depth=0.18,
            mat_idx=WTMAT_GRAPHITE,
            segments=56,
            angle_start_rad=0.0 if is_rear else angle_floor_right,
            angle_end_rad=2.0 * math.pi if is_rear else angle_floor_left,
        )

    # Longitudinal floor deck around the recessed turntable pit (Z = -0.18 to 0.0)
    floor_half_w = TUNNEL_RADIUS_INNER * math.cos(angle_floor_right) + 0.15
    pit_r = TURNTABLE_RADIUS + 0.04

    # Front floor slab (Y = +pit_r to TUNNEL_Y_MAX)
    front_len = TUNNEL_Y_MAX - pit_r
    _add_box(
        bm,
        center=(0.0, pit_r + front_len * 0.5, -0.09),
        size=(floor_half_w * 2.0, front_len, 0.18),
        mat_idx=WTMAT_FLOOR_DECK,
    )
    # Rear floor slab (Y = TUNNEL_Y_MIN to -pit_r)
    rear_len = -pit_r - TUNNEL_Y_MIN
    _add_box(
        bm,
        center=(0.0, TUNNEL_Y_MIN + rear_len * 0.5, -0.09),
        size=(floor_half_w * 2.0, rear_len, 0.18),
        mat_idx=WTMAT_FLOOR_DECK,
    )
    # Left & Right floor slabs flanking the turntable pit (Y = -pit_r to +pit_r)
    side_w = floor_half_w - pit_r
    for side in (-1.0, 1.0):
        _add_box(
            bm,
            center=(side * (pit_r + side_w * 0.5), 0.0, -0.09),
            size=(side_w, pit_r * 2.0, 0.18),
            mat_idx=WTMAT_FLOOR_DECK,
        )

    # Corner filler wedges around the circular pit so the floor meets the pit ring cleanly
    corner_segs = 32
    for i in range(corner_segs):
        a0 = 2.0 * math.pi * i / corner_segs
        a1 = 2.0 * math.pi * (i + 1) / corner_segs
        am = 0.5 * (a0 + a1)
        box_x = math.copysign(pit_r, math.cos(am))
        box_y = math.copysign(pit_r, math.sin(am))
        p0_in = (pit_r * math.cos(a0), pit_r * math.sin(a0))
        p1_in = (pit_r * math.cos(a1), pit_r * math.sin(a1))

        # Project outward to the square pit_r bounding box
        def _to_square(px: float, py: float) -> Tuple[float, float]:
            scale = pit_r / max(abs(px), abs(py), 1e-6)
            return (px * scale, py * scale)

        p0_out = _to_square(p0_in[0], p0_in[1])
        p1_out = _to_square(p1_in[0], p1_in[1])

        v_bot = [
            bm.verts.new((p0_in[0], p0_in[1], -0.18)),
            bm.verts.new((p1_in[0], p1_in[1], -0.18)),
            bm.verts.new((p1_out[0], p1_out[1], -0.18)),
            bm.verts.new((p0_out[0], p0_out[1], -0.18)),
        ]
        v_top = [
            bm.verts.new((p0_in[0], p0_in[1], 0.0)),
            bm.verts.new((p1_in[0], p1_in[1], 0.0)),
            bm.verts.new((p1_out[0], p1_out[1], 0.0)),
            bm.verts.new((p0_out[0], p0_out[1], 0.0)),
        ]
        f_top = bm.faces.new((v_top[0], v_top[1], v_top[2], v_top[3]))
        f_bot = bm.faces.new((v_bot[3], v_bot[2], v_bot[1], v_bot[0]))
        f_in = bm.faces.new((v_bot[0], v_top[0], v_top[1], v_bot[1]))
        _assign_mat([f_top, f_bot, f_in], WTMAT_FLOOR_DECK)

    # Pit floor pan underneath the turntable
    _add_cylinder(
        bm,
        center=(0.0, 0.0, -0.14),
        radius1=pit_r + 0.02,
        radius2=pit_r + 0.02,
        depth=0.08,
        mat_idx=WTMAT_GRAPHITE,
        segments=48,
    )

    # Outer pit bezel ring in brushed steel
    _add_cylinder(
        bm,
        center=(0.0, 0.0, -0.002),
        radius1=TURNTABLE_RADIUS + 0.055,
        radius2=TURNTABLE_RADIUS + 0.055,
        depth=0.012,
        mat_idx=WTMAT_GRAPHITE,
        segments=64,
    )

    # Side floor safety trim rails along the wall bases
    for side in (-1.0, 1.0):
        _add_box(
            bm,
            center=(side * (floor_half_w - 0.12), tunnel_mid_y, 0.06),
            size=(0.16, tunnel_len, 0.12),
            mat_idx=WTMAT_GRAPHITE,
        )
        _add_box(
            bm,
            center=(side * (floor_half_w - 0.21), tunnel_mid_y, 0.06),
            size=(0.025, tunnel_len - 0.4, 0.04),
            mat_idx=WTMAT_BURGUNDY,
        )

    # Burgundy accent stripe along the upper arch ribs
    for y_pos in [-3.50, 0.00, 3.50]:
        _add_arc_ring(
            bm,
            center=(0.0, y_pos, TUNNEL_CENTER_Z),
            r_inner=TUNNEL_RADIUS_INNER - 0.095,
            r_outer=TUNNEL_RADIUS_INNER - 0.075,
            y_depth=0.06,
            mat_idx=WTMAT_BURGUNDY,
            segments=56,
            angle_start_rad=angle_floor_right + 0.12,
            angle_end_rad=angle_floor_left - 0.12,
        )


# =============================================================================
# 2. HUGE 12-BLADE FAN ROTOR & STATOR HOUSING
# =============================================================================

def _build_12_blade_fan_rotor(bm: bmesh.types.BMesh) -> None:
    """
    Builds the huge 12-blade aerodynamic fan rotor in local coordinates
    (centered at origin; the object itself is placed at (0, FAN_Y, TUNNEL_CENTER_Z)).
    """
    # Central rotor hub drum
    _add_cylinder(
        bm,
        center=(0.0, 0.0, 0.0),
        radius1=0.72,
        radius2=0.72,
        depth=0.56,
        mat_idx=WTMAT_GRAPHITE,
        segments=36,
        rot_euler_rad=(math.radians(90.0), 0.0, 0.0),
    )

    # Burgundy hub collar ring
    _add_cylinder(
        bm,
        center=(0.0, -0.26, 0.0),
        radius1=0.735,
        radius2=0.735,
        depth=0.07,
        mat_idx=WTMAT_BURGUNDY,
        segments=36,
        rot_euler_rad=(math.radians(90.0), 0.0, 0.0),
    )

    # Aerodynamic front nosecone spinner pointing toward the test section (-Y)
    _add_cylinder(
        bm,
        center=(0.0, -0.68, 0.0),
        radius1=0.04,
        radius2=0.70,
        depth=0.82,
        mat_idx=WTMAT_CARBON_BLADE,
        segments=36,
        rot_euler_rad=(math.radians(90.0), 0.0, 0.0),
    )

    # Nosecone tip cap in gold
    _add_cylinder(
        bm,
        center=(0.0, -1.10, 0.0),
        radius1=0.01,
        radius2=0.05,
        depth=0.08,
        mat_idx=WTMAT_GOLD,
        segments=20,
        rot_euler_rad=(math.radians(90.0), 0.0, 0.0),
    )

    # 12 sculpted twisted airfoil blades
    num_blades = 12
    span_stations = 6
    r_root = 0.68
    r_tip = 2.86

    for b_idx in range(num_blades):
        blade_angle = 2.0 * math.pi * b_idx / num_blades
        cos_b = math.cos(blade_angle)
        sin_b = math.sin(blade_angle)

        # Radial axis in X-Z plane, tangential axis perpendicular in X-Z plane
        radial = Vector((cos_b, 0.0, sin_b))
        tangential = Vector((-sin_b, 0.0, cos_b))
        axial = Vector((0.0, 1.0, 0.0))

        station_rings: List[List[bmesh.types.BMVert]] = []
        for s in range(span_stations):
            t = s / (span_stations - 1)
            r = r_root + t * (r_tip - r_root)
            # Chord widens mid-span then tapers toward tip
            chord = 0.34 + 0.14 * math.sin(t * math.pi) - 0.10 * t
            thickness = 0.045 * (1.0 - 0.65 * t)
            # Aerodynamic twist from 44 deg at root to 18 deg at tip
            pitch = math.radians(44.0 - 26.0 * t)

            chord_dir = tangential * math.cos(pitch) + axial * math.sin(pitch)
            thick_dir = -tangential * math.sin(pitch) + axial * math.cos(pitch)

            # 6-point airfoil cross-section
            profile_offsets = [
                (-0.48 * chord, 0.0),
                (-0.18 * chord, 0.55 * thickness),
                (0.22 * chord, 0.42 * thickness),
                (0.52 * chord, 0.0),
                (0.22 * chord, -0.32 * thickness),
                (-0.18 * chord, -0.40 * thickness),
            ]
            ring: List[bmesh.types.BMVert] = []
            center_pt = radial * r
            for c_off, th_off in profile_offsets:
                pt = center_pt + chord_dir * c_off + thick_dir * th_off
                ring.append(bm.verts.new(pt))
            station_rings.append(ring)

        blade_faces: List[bmesh.types.BMFace] = []
        pts_per_ring = len(station_rings[0])
        for s in range(span_stations - 1):
            r0 = station_rings[s]
            r1 = station_rings[s + 1]
            for p in range(pts_per_ring):
                pn = (p + 1) % pts_per_ring
                blade_faces.append(bm.faces.new((r0[p], r0[pn], r1[pn], r1[p])))

        # Cap tip & root
        blade_faces.append(bm.faces.new(station_rings[-1]))
        blade_faces.append(bm.faces.new(list(reversed(station_rings[0]))))
        _assign_mat(blade_faces, WTMAT_CARBON_BLADE)


def _build_fan_shroud_and_stators(bm: bmesh.types.BMesh) -> None:
    """Builds the stationary fan shroud ring and 8 rear stator motor struts."""
    _add_arc_ring(
        bm,
        center=(0.0, FAN_Y, TUNNEL_CENTER_Z),
        r_inner=2.92,
        r_outer=3.14,
        y_depth=0.90,
        mat_idx=WTMAT_GRAPHITE,
        segments=56,
    )

    # 8 radial stator struts behind the fan rotor (Y = FAN_Y + 0.52)
    for i in range(8):
        ang = 2.0 * math.pi * i / 8
        mid_r = 1.85
        cx = mid_r * math.cos(ang)
        cz = TUNNEL_CENTER_Z + mid_r * math.sin(ang)
        _add_box(
            bm,
            center=(cx, FAN_Y + 0.52, cz),
            size=(2.25, 0.16, 0.08),
            mat_idx=WTMAT_GRAPHITE,
            rot_euler_rad=(0.0, -ang, 0.0),
        )


# =============================================================================
# 3. FLOW STRAIGHTENER HONEYCOMB / LOUVER GRID
# =============================================================================

def _build_flow_straightener_grid(bm: bmesh.types.BMesh) -> None:
    """
    Builds the upstream aerodynamic flow-straightener screen at Y = STRAIGHTENER_Y
    consisting of a circular outer frame and crisscrossing vertical/horizontal
    aerodynamic louver vanes clipped inside the tunnel radius.
    """
    r_grid = TUNNEL_RADIUS_INNER - 0.12
    vane_depth = 0.24
    vane_thick = 0.016
    spacing = 0.36

    # Outer mounting collar
    _add_arc_ring(
        bm,
        center=(0.0, STRAIGHTENER_Y, TUNNEL_CENTER_Z),
        r_inner=r_grid - 0.06,
        r_outer=TUNNEL_RADIUS_INNER,
        y_depth=vane_depth + 0.06,
        mat_idx=WTMAT_GRAPHITE,
        segments=56,
    )

    # Vertical flow-straightening vanes
    n_steps = int(r_grid / spacing)
    for ix in range(-n_steps, n_steps + 1):
        x_pos = ix * spacing
        if abs(x_pos) >= r_grid - 0.08:
            continue
        half_h = math.sqrt(max(0.0, r_grid * r_grid - x_pos * x_pos))
        # Clip bottom at floor Z = 0.0
        z_bot = max(0.02, TUNNEL_CENTER_Z - half_h)
        z_top = TUNNEL_CENTER_Z + half_h
        if z_top <= z_bot + 0.05:
            continue
        _add_box(
            bm,
            center=(x_pos, STRAIGHTENER_Y, 0.5 * (z_bot + z_top)),
            size=(vane_thick, vane_depth, z_top - z_bot),
            mat_idx=WTMAT_HONEYCOMB,
        )

    # Horizontal flow-straightening vanes
    z_min_grid = 0.28
    z_max_grid = TUNNEL_CENTER_Z + r_grid - 0.12
    z_val = z_min_grid
    while z_val <= z_max_grid:
        dz = z_val - TUNNEL_CENTER_Z
        if abs(dz) < r_grid - 0.05:
            half_w = math.sqrt(max(0.0, r_grid * r_grid - dz * dz))
            _add_box(
                bm,
                center=(0.0, STRAIGHTENER_Y, z_val),
                size=(half_w * 2.0, vane_depth, vane_thick),
                mat_idx=WTMAT_HONEYCOMB,
            )
        z_val += spacing

    # Concentric reinforcement ring at mid-radius
    _add_arc_ring(
        bm,
        center=(0.0, STRAIGHTENER_Y, TUNNEL_CENTER_Z),
        r_inner=1.50,
        r_outer=1.54,
        y_depth=vane_depth + 0.02,
        mat_idx=WTMAT_GRAPHITE,
        segments=48,
    )


# =============================================================================
# 4. ROTATING YAW TURNTABLE (-15 DEG TO +15 DEG) & BIKE WHEEL ROLLERS
# =============================================================================

def _build_yaw_turntable_and_rollers(bm: bmesh.types.BMesh) -> None:
    """
    Builds the flush rotating aerodynamic turntable platform centered at (0, 0, 0)
    with -15 deg to +15 deg yaw degree scale markers, cyan perimeter ring, and
    front/rear brushed-steel bicycle wheel rollers.
    """
    # Main rotating platform disc (flush at Z = 0.0)
    _add_cylinder(
        bm,
        center=(0.0, 0.0, -0.035),
        radius1=TURNTABLE_RADIUS,
        radius2=TURNTABLE_RADIUS,
        depth=0.07,
        mat_idx=WTMAT_TURNTABLE,
        segments=64,
    )

    # Outer cyan telemetry LED ring around the turntable edge
    _add_arc_ring(
        bm,
        center=(0.0, 0.0, 0.0),
        r_inner=TURNTABLE_RADIUS - 0.025,
        r_outer=TURNTABLE_RADIUS - 0.005,
        y_depth=0.01,
        mat_idx=WTMAT_LED_CYAN,
        segments=64,
    )

    # Precision Yaw Angle Scale ticks (-15 deg to +15 deg every 5 deg) on front & rear
    for deg in range(-15, 16, 5):
        ang = math.radians(deg)
        is_major = (deg % 15 == 0) or (deg == 0)
        tick_len = 0.14 if is_major else 0.08
        tick_w = 0.020 if deg == 0 else 0.012
        mat_tick = WTMAT_BURGUNDY if deg == 0 else WTMAT_GOLD

        for end_sign in (1.0, -1.0):
            r_mid = TURNTABLE_RADIUS - 0.11
            tx = end_sign * r_mid * math.sin(ang)
            ty = end_sign * r_mid * math.cos(ang)
            _add_box(
                bm,
                center=(tx, ty, 0.003),
                size=(tick_w, tick_len, 0.006),
                mat_idx=mat_tick,
                rot_euler_rad=(0.0, 0.0, -ang),
            )

    # Centerline alignment stripe along Y
    _add_box(
        bm,
        center=(0.0, 0.0, 0.002),
        size=(0.03, 2.35, 0.004),
        mat_idx=WTMAT_BURGUNDY,
    )

    # Front & Rear Wheel Roller Assemblies
    for wheel_y in (FRONT_WHEEL_Y, REAR_WHEEL_Y):
        # Recessed roller housing tray
        _add_box(
            bm,
            center=(0.0, wheel_y, -0.015),
            size=(0.44, 0.30, 0.05),
            mat_idx=WTMAT_GRAPHITE,
        )
        # Beveled steel frame rails around roller bay
        for side in (-1.0, 1.0):
            _add_box(
                bm,
                center=(side * 0.21, wheel_y, 0.010),
                size=(0.03, 0.32, 0.02),
                mat_idx=WTMAT_BRUSHED_STEEL,
            )

        # Twin parallel brushed-steel rollers under each tire contact patch
        for dy in (-0.068, 0.068):
            _add_cylinder(
                bm,
                center=(0.0, wheel_y + dy, -0.002),
                radius1=0.042,
                radius2=0.042,
                depth=0.36,
                mat_idx=WTMAT_BRUSHED_STEEL,
                segments=24,
                rot_euler_rad=(0.0, math.radians(90.0), 0.0),
            )
            # Roller end-cap bearings in gold
            for side in (-1.0, 1.0):
                _add_cylinder(
                    bm,
                    center=(side * 0.185, wheel_y + dy, -0.002),
                    radius1=0.028,
                    radius2=0.028,
                    depth=0.015,
                    mat_idx=WTMAT_GOLD,
                    segments=16,
                    rot_euler_rad=(0.0, math.radians(90.0), 0.0),
                )

    # Rear trainer retention stanchion base behind rear wheel (Y = -0.88)
    _add_box(
        bm,
        center=(0.0, REAR_WHEEL_Y - 0.34, 0.03),
        size=(0.38, 0.18, 0.06),
        mat_idx=WTMAT_GRAPHITE,
    )
    for side in (-1.0, 1.0):
        _add_box(
            bm,
            center=(side * 0.14, REAR_WHEEL_Y - 0.34, 0.19),
            size=(0.04, 0.06, 0.32),
            mat_idx=WTMAT_BRUSHED_STEEL,
            rot_euler_rad=(math.radians(-12.0), 0.0, 0.0),
        )


def _build_turntable_led_ring(bm: bmesh.types.BMesh) -> None:
    """
    Builds a flat circular cyan LED ring in the X-Y plane at Z = 0.003
    for the rotating yaw turntable.
    """
    segs = 64
    r_in = TURNTABLE_RADIUS - 0.026
    r_out = TURNTABLE_RADIUS - 0.006
    z_top = 0.004
    z_bot = 0.000

    v_in_t, v_out_t, v_in_b, v_out_b = [], [], [], []
    for i in range(segs):
        a = 2.0 * math.pi * i / segs
        ca, sa = math.cos(a), math.sin(a)
        v_in_t.append(bm.verts.new((r_in * ca, r_in * sa, z_top)))
        v_out_t.append(bm.verts.new((r_out * ca, r_out * sa, z_top)))
        v_in_b.append(bm.verts.new((r_in * ca, r_in * sa, z_bot)))
        v_out_b.append(bm.verts.new((r_out * ca, r_out * sa, z_bot)))

    faces: List[bmesh.types.BMFace] = []
    for i in range(segs):
        j = (i + 1) % segs
        faces.append(bm.faces.new((v_in_t[i], v_out_t[i], v_out_t[j], v_in_t[j])))
        faces.append(bm.faces.new((v_in_b[i], v_in_b[j], v_out_b[j], v_out_b[i])))
        faces.append(bm.faces.new((v_in_b[i], v_in_t[i], v_in_t[j], v_in_b[j])))
        faces.append(bm.faces.new((v_out_b[i], v_out_b[j], v_out_t[j], v_out_t[i])))

    _assign_mat(faces, WTMAT_LED_CYAN)


# =============================================================================
# 5. WALL & OVERHEAD LED LIGHT STRIPS
# =============================================================================

def _build_led_light_strips(bm: bmesh.types.BMesh) -> None:
    """
    Builds longitudinal telemetry cyan LED strips along the curved tunnel walls
    and overhead studio white LED bars between the structural ribs.
    """
    strip_y_spans = [(-4.90, -3.70), (-3.15, -1.95), (-1.40, -0.20), (0.35, 1.55), (2.10, 3.30), (3.85, 4.75)]
    wall_angles_deg = [18.0, 48.0, 132.0, 162.0]  # Left & Right curved walls

    for y0, y1 in strip_y_spans:
        y_mid = 0.5 * (y0 + y1)
        y_len = y1 - y0

        # Curved wall cyan telemetry LED bars
        for ang_deg in wall_angles_deg:
            ang = math.radians(ang_deg)
            r_mount = TUNNEL_RADIUS_INNER - 0.03
            cx = r_mount * math.cos(ang)
            cz = TUNNEL_CENTER_Z + r_mount * math.sin(ang)

            # Aluminum housing channel
            _add_box(
                bm,
                center=(cx, y_mid, cz),
                size=(0.04, y_len, 0.075),
                mat_idx=WTMAT_GRAPHITE,
                rot_euler_rad=(0.0, -ang, 0.0),
            )
            # Emissive cyan LED diffuser strip
            r_led = TUNNEL_RADIUS_INNER - 0.055
            lx = r_led * math.cos(ang)
            lz = TUNNEL_CENTER_Z + r_led * math.sin(ang)
            _add_box(
                bm,
                center=(lx, y_mid, lz),
                size=(0.02, y_len - 0.04, 0.042),
                mat_idx=WTMAT_LED_CYAN,
                rot_euler_rad=(0.0, -ang, 0.0),
            )

        # Overhead studio white LED light bars at top of cylinder (ang = 80, 100 deg)
        for ang_deg in (78.0, 102.0):
            ang = math.radians(ang_deg)
            r_mount = TUNNEL_RADIUS_INNER - 0.04
            cx = r_mount * math.cos(ang)
            cz = TUNNEL_CENTER_Z + r_mount * math.sin(ang)
            _add_box(
                bm,
                center=(cx, y_mid, cz),
                size=(0.05, y_len, 0.14),
                mat_idx=WTMAT_GRAPHITE,
                rot_euler_rad=(0.0, -ang, 0.0),
            )
            r_led = TUNNEL_RADIUS_INNER - 0.068
            lx = r_led * math.cos(ang)
            lz = TUNNEL_CENTER_Z + r_led * math.sin(ang)
            _add_box(
                bm,
                center=(lx, y_mid, lz),
                size=(0.022, y_len - 0.05, 0.10),
                mat_idx=WTMAT_LED_WHITE,
                rot_euler_rad=(0.0, -ang, 0.0),
            )


# =============================================================================
# 6. SMOKE WAND NOZZLE & AERODYNAMIC SMOKE STREAMLINES
# =============================================================================

SMOKE_JET_HEIGHTS = [0.22, 0.46, 0.72, 0.98, 1.24, 1.48]


def _build_smoke_nozzle(bm: bmesh.types.BMesh) -> None:
    """
    Builds the streamlined floor-mounted smoke rake wand directly in front of
    the front wheel (Y = SMOKE_NOZZLE_Y) with 6 horizontal micro-nozzle jets.
    """
    # Floor mounting plate
    _add_cylinder(
        bm,
        center=(0.0, SMOKE_NOZZLE_Y, 0.012),
        radius1=0.14,
        radius2=0.12,
        depth=0.024,
        mat_idx=WTMAT_GRAPHITE,
        segments=24,
    )

    # Aerodynamic teardrop/blade vertical mast
    _add_box(
        bm,
        center=(0.0, SMOKE_NOZZLE_Y, 0.78),
        size=(0.028, 0.095, 1.54),
        mat_idx=WTMAT_BRUSHED_STEEL,
    )
    # Burgundy aerodynamic mast collar
    _add_box(
        bm,
        center=(0.0, SMOKE_NOZZLE_Y, 0.08),
        size=(0.042, 0.115, 0.08),
        mat_idx=WTMAT_BURGUNDY,
    )

    # 6 horizontal smoke emitter jets pointing toward the front wheel (-Y)
    for z_jet in SMOKE_JET_HEIGHTS:
        _add_cylinder(
            bm,
            center=(0.0, SMOKE_NOZZLE_Y - 0.075, z_jet),
            radius1=0.008,
            radius2=0.014,
            depth=0.10,
            mat_idx=WTMAT_GOLD,
            segments=12,
            rot_euler_rad=(math.radians(90.0), 0.0, 0.0),
        )


def _build_smoke_streamlines(bm: bmesh.types.BMesh) -> None:
    """
    Builds 6 smooth translucent aerodynamic smoke streamlines flowing from the
    smoke nozzle jets over the front wheel, handlebars, and rider silhouette zone.
    """
    y_start = SMOKE_NOZZLE_Y - 0.12
    y_end = -1.65
    num_pts = 18

    for idx, z_base in enumerate(SMOKE_JET_HEIGHTS):
        points: List[Tuple[float, float, float]] = []
        radii: List[float] = []

        for step in range(num_pts):
            t = step / (num_pts - 1)
            y = y_start + t * (y_end - y_start)

            # Aerodynamic upwash & deflection curve over the front wheel & rider
            bell = math.exp(-((y - 0.10) ** 2) / 0.72)
            lift = (0.14 + 0.04 * (idx % 2)) * bell
            # Slight wake expansion in X for upper/mid streamlines
            x_off = (0.04 if idx % 2 == 0 else -0.04) * math.sin(t * math.pi) * (0.3 + 0.15 * idx)
            z = z_base + lift + 0.03 * math.sin(t * 2.5 * math.pi) * t

            # Smoke filament widens slightly as it diffuses downstream
            r = 0.009 + 0.020 * (t ** 0.85)
            points.append((x_off, y, z))
            radii.append(r)

        _add_tube_along_points(bm, points, radii, WTMAT_SMOKE_STREAM, segments=10)


# =============================================================================
# SCENE ASSEMBLY & GLB EXPORT
# =============================================================================

def generate_wind_tunnel_objects() -> List[bpy.types.Object]:
    """
    Generates all Wind Tunnel Testing Chamber objects and returns them.
    """
    materials = create_wind_tunnel_materials()
    objects: List[bpy.types.Object] = []

    # 1. Main cylindrical chamber, floor deck, fan shroud & stator struts
    chamber_obj, chamber_mesh, chamber_bm = _create_mesh_object("WindTunnel_Chamber", materials)
    _build_cylindrical_air_duct(chamber_bm)
    _build_fan_shroud_and_stators(chamber_bm)
    _finalize_mesh_object(chamber_obj, chamber_mesh, chamber_bm, location=(0.0, 0.0, 0.0))
    objects.append(chamber_obj)

    # 2. Huge 12-blade fan rotor (centered at FAN_Y, TUNNEL_CENTER_Z for rotation)
    fan_obj, fan_mesh, fan_bm = _create_mesh_object("WindTunnel_Fan_Rotor", materials)
    _build_12_blade_fan_rotor(fan_bm)
    _finalize_mesh_object(fan_obj, fan_mesh, fan_bm, location=(0.0, FAN_Y, TUNNEL_CENTER_Z))
    objects.append(fan_obj)

    # 3. Flow straightener honeycomb/louver grid
    grid_obj, grid_mesh, grid_bm = _create_mesh_object("WindTunnel_Flow_Straightener", materials)
    _build_flow_straightener_grid(grid_bm)
    _finalize_mesh_object(grid_obj, grid_mesh, grid_bm, location=(0.0, 0.0, 0.0))
    objects.append(grid_obj)

    # 4. Rotating Yaw Turntable (-15 deg to +15 deg) with wheel rollers
    turn_obj, turn_mesh, turn_bm = _create_mesh_object("WindTunnel_Yaw_Turntable", materials)
    _build_yaw_turntable_and_rollers(turn_bm)
    _build_turntable_led_ring(turn_bm)
    _finalize_mesh_object(turn_obj, turn_mesh, turn_bm, location=(0.0, 0.0, 0.0))
    objects.append(turn_obj)

    # 5. Wall & overhead LED light strips
    led_obj, led_mesh, led_bm = _create_mesh_object("WindTunnel_LED_Strips", materials)
    _build_led_light_strips(led_bm)
    _finalize_mesh_object(led_obj, led_mesh, led_bm, location=(0.0, 0.0, 0.0))
    objects.append(led_obj)

    # 6. Smoke nozzle wand ahead of front wheel
    nozzle_obj, nozzle_mesh, nozzle_bm = _create_mesh_object("WindTunnel_Smoke_Nozzle", materials)
    _build_smoke_nozzle(nozzle_bm)
    _finalize_mesh_object(nozzle_obj, nozzle_mesh, nozzle_bm, location=(0.0, 0.0, 0.0))
    objects.append(nozzle_obj)

    # 7. Translucent aerodynamic smoke streamlines
    smoke_obj, smoke_mesh, smoke_bm = _create_mesh_object("WindTunnel_Smoke_Streams", materials)
    _build_smoke_streamlines(smoke_bm)
    _finalize_mesh_object(smoke_obj, smoke_mesh, smoke_bm, location=(0.0, 0.0, 0.0))
    objects.append(smoke_obj)

    return objects


def _clear_scene_meshes() -> None:
    """Removes all mesh objects from the current Blender scene."""
    for obj in list(bpy.context.scene.objects):
        if obj.type == "MESH":
            bpy.data.objects.remove(obj, do_unlink=True)


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


def export_wind_tunnel_facility(
    output_dir: str = "assets/3d/environment",
) -> str:
    """Generates and exports `wind_tunnel_room.glb` into `output_dir`."""
    os.makedirs(output_dir, exist_ok=True)
    _clear_scene_meshes()
    objs = generate_wind_tunnel_objects()
    out_path = os.path.join(output_dir, "wind_tunnel_room.glb")
    export_glb(objs, out_path)
    return out_path


if __name__ == "__main__":
    out_dir = "assets/3d/environment"
    for idx, arg in enumerate(sys.argv):
        if arg in ["--output-dir", "-o"] and idx + 1 < len(sys.argv):
            out_dir = sys.argv[idx + 1]

    out_file = export_wind_tunnel_facility(output_dir=out_dir)
    sm.setup_zwift_studio_lighting()
    print(f"[SUCCESS] Wind Tunnel facility generated: {out_file}")
