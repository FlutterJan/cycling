"""
===============================================================================
PRO PELOTON MANAGER - TV BROADCAST HELICOPTER GENERATOR
===============================================================================
Blender 5.3 Python API (bpy) script that procedurally models the 3D
TV Broadcast Helicopter circling above the peloton
(`assets/3d/environment/tv_helicopter.glb`):

  1. Aerodynamic Fuselage & Broadcast Livery (`TV_Heli_Fuselage`):
     - Lofted teardrop cabin & slender tapered tail boom in race broadcast
       livery (pearl white, graphite belly, burgundy racing stripe, gold trim).
     - Panoramic tinted iridium cockpit windshield & side observation windows.
     - Twin-turbine upper cowling, intake vents, and angled titanium exhausts.
     - Swept vertical tail fin, ventral fin, horizontal stabilizers with
       endplate winglets, SATCOM uplink dome, antennas, and nav/strobe lights.

  2. Landing Skids (`TV_Heli_Skids`):
     - Left & right tubular skids with upturned front toes, rear caps,
       non-slip boarding steps, and 4 swept aerodynamic cross-struts.

  3. Main Rotor & Tail Rotor (separate named objects for rotation animation):
     - `TV_Heli_Main_Rotor` (origin at (0.0, 0.0, 2.78), rotates around +Z):
       titanium mast, swashplate hub, and 4 airfoil blades with swept tips
       and high-visibility gold/amber tip stripes.
     - `TV_Heli_Tail_Rotor` (origin at (-0.22, -6.55, 1.62), rotates around +X):
       gearbox hub, spinner, and 4 airfoil blades in X-configuration.

  4. Cineflex Gyro-Stabilized Camera Gimbal (`TV_Heli_Cineflex_Gimbal`):
     - Origin at (0.0, 2.52, 0.42) under the nose via a carbon-fiber yoke.
     - Spherical matte-carbon gyro head with equatorial azimuth ring, recessed
       optical turret, telephoto broadcast lens barrel, coated iridium glass,
       secondary wide-angle port, and active telemetry LED.

Usage:
  blender --background --python blender_scripts/generate_helicopter_and_blimp.py
  blender --background --python blender_scripts/generate_helicopter_and_blimp.py -- --output-dir assets/3d/environment

Compatible with Blender 3.6 LTS, 4.x, and 5.3+.
===============================================================================
"""

import math
import os
import sys
from typing import List, Optional, Sequence, Tuple, Union

try:
    import bpy
    import bmesh
    from mathutils import Euler, Matrix, Vector
except ImportError:
    print("[ERROR] 'bpy' / 'mathutils' module not found. Run within Blender:")
    print("        blender --background --python blender_scripts/generate_helicopter_and_blimp.py")
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

HMAT_WHITE_LIVERY = 0    # #F8FAFC glossy broadcast pearl white upper fuselage
HMAT_GRAPHITE = 1        # #181B22 deep graphite belly, struts & skids
HMAT_BURGUNDY = 2        # #8E4A49 race broadcast burgundy stripe & tail accent
HMAT_GOLD = 3            # #D4AF37 championship gold pinstripe & tip stripes
HMAT_CARBON = 4          # #1A1D24 matte carbon rotor blades & Cineflex sphere
HMAT_TITANIUM = 5        # #94A3B8 brushed titanium mast, exhausts & skid shoes
HMAT_GLASS = 6           # #0B1320 tinted iridium cockpit & cabin glass
HMAT_LENS_GLASS = 7      # #0E4B68 coated telephoto Cineflex objective lens
HMAT_LED_RED = 8         # #EF4444 port nav light & tail anti-collision beacon
HMAT_LED_CYAN = 9        # #00E5FF starboard/telemetry nav & Cineflex status LED
HMAT_LED_WHITE = 10      # #FFFFFF aft strobe & landing spotlight


# =============================================================================
# HELICOPTER DIMENSIONS (METERS, +Y = FORWARD, +Z = UP, +X = RIGHT)
# =============================================================================

MAIN_ROTOR_PIVOT = (0.0, 0.0, 2.78)
MAIN_ROTOR_RADIUS = 4.85

TAIL_ROTOR_PIVOT = (-0.22, -6.55, 1.62)
TAIL_ROTOR_RADIUS = 0.90

CINEFLEX_PIVOT = (0.0, 2.52, 0.42)
CINEFLEX_RADIUS = 0.24


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
    coat_weight: float = 0.0,
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
    if coat_weight > 0.0:
        sm._set_bsdf_socket(bsdf, ["Coat Weight", "Clearcoat"], coat_weight)

    if emission_color is not None and emission_strength > 0.0:
        sm._set_bsdf_socket(
            bsdf,
            ["Emission Color", "Emission"],
            sm.hex_to_linear_rgb(emission_color),
        )
        sm._set_bsdf_socket(bsdf, ["Emission Strength"], emission_strength)

    return mat


def create_helicopter_materials() -> List[bpy.types.Material]:
    """Builds the ordered PBR material palette for the TV broadcast helicopter."""
    return [
        # 0: Glossy broadcast white livery
        _make_pbr_material(
            "Mat_Heli_White_Livery", "#F8FAFC",
            roughness=0.22, metallic=0.08, coat_weight=0.75,
        ),
        # 1: Deep graphite belly & structural frame
        _make_pbr_material(
            "Mat_Heli_Graphite", "#181B22",
            roughness=0.38, metallic=0.55,
        ),
        # 2: Pro Peloton Manager burgundy broadcast stripe
        _make_pbr_material(
            "Mat_Heli_Burgundy", "#8E4A49",
            roughness=0.24, metallic=0.22, coat_weight=0.65,
        ),
        # 3: Championship gold pinstripe & rotor tip accent
        _make_pbr_material(
            "Mat_Heli_Gold", "#D4AF37",
            roughness=0.20, metallic=0.92,
        ),
        # 4: Matte composite carbon (blades, Cineflex housing)
        _make_pbr_material(
            "Mat_Heli_Carbon", "#1A1D24",
            roughness=0.32, metallic=0.25,
        ),
        # 5: Brushed titanium (mast, exhausts, skid shoes)
        _make_pbr_material(
            "Mat_Heli_Titanium", "#94A3B8",
            roughness=0.24, metallic=0.92,
        ),
        # 6: Tinted iridium cockpit & cabin glass
        _make_pbr_material(
            "Mat_Heli_Glass", "#0B1320",
            roughness=0.06, metallic=0.25, specular_ior=0.90, ior=1.52,
            coat_weight=1.0,
        ),
        # 7: Coated Cineflex telephoto objective lens
        _make_pbr_material(
            "Mat_Heli_Lens_Glass", "#0E4B68",
            roughness=0.04, metallic=0.45, specular_ior=0.95, ior=1.65,
            coat_weight=1.0, emission_color="#00E5FF", emission_strength=0.18,
        ),
        # 8: Red port navigation & anti-collision beacon
        _make_pbr_material(
            "Mat_Heli_LED_Red", "#EF4444",
            roughness=0.15, metallic=0.0,
            emission_color="#EF4444", emission_strength=4.5,
        ),
        # 9: Cyan starboard/telemetry LED
        _make_pbr_material(
            "Mat_Heli_LED_Cyan", "#00E5FF",
            roughness=0.15, metallic=0.0,
            emission_color="#00E5FF", emission_strength=4.2,
        ),
        # 10: White strobe & landing light
        _make_pbr_material(
            "Mat_Heli_LED_White", "#FFFFFF",
            roughness=0.12, metallic=0.0,
            emission_color="#F8FAFC", emission_strength=5.5,
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
    segments: int = 24,
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


def _add_uv_sphere(
    bm: bmesh.types.BMesh,
    center: Tuple[float, float, float],
    radius: float,
    mat_idx: int,
    u_segments: int = 28,
    v_segments: int = 18,
    scale: Tuple[float, float, float] = (1.0, 1.0, 1.0),
) -> List[bmesh.types.BMFace]:
    """Adds a UV sphere (optionally ellipsoidal via `scale`) centered at `center`."""
    mat_scale = Matrix.Diagonal((scale[0], scale[1], scale[2], 1.0))
    mat_trans = Matrix.Translation(Vector(center))
    xform = mat_trans @ mat_scale

    res = bmesh.ops.create_uvsphere(
        bm,
        u_segments=u_segments,
        v_segments=v_segments,
        radius=radius,
        matrix=xform,
    )
    verts = res["verts"]
    faces = list({f for v in verts for f in v.link_faces})
    _assign_mat(faces, mat_idx)
    return faces


def _add_tube_along_points(
    bm: bmesh.types.BMesh,
    points: Sequence[Tuple[float, float, float]],
    radii: Union[float, Sequence[float]],
    mat_idx: int,
    segments: int = 14,
    cap_ends: bool = True,
) -> List[bmesh.types.BMFace]:
    """Sweeps a circular cross-section along a 3D polyline."""
    if len(points) < 2:
        return []

    if isinstance(radii, (int, float)):
        radii_list = [float(radii)] * len(points)
    else:
        radii_list = list(radii)

    rings: List[List[bmesh.types.BMVert]] = []
    prev_up = Vector((0.0, 0.0, 1.0))

    for i, pt in enumerate(points):
        p = Vector(pt)
        if i == 0:
            tangent = (Vector(points[1]) - p).normalized()
        elif i == len(points) - 1:
            tangent = (p - Vector(points[-2])).normalized()
        else:
            tangent = (Vector(points[i + 1]) - Vector(points[i - 1])).normalized()

        if tangent.length < 1e-6:
            tangent = Vector((0.0, 1.0, 0.0))

        if abs(tangent.dot(prev_up)) > 0.96:
            ref = Vector((1.0, 0.0, 0.0)) if abs(tangent.x) < 0.9 else Vector((0.0, 1.0, 0.0))
        else:
            ref = prev_up

        side = tangent.cross(ref).normalized()
        up = side.cross(tangent).normalized()
        prev_up = up

        r = radii_list[i]
        ring: List[bmesh.types.BMVert] = []
        for s in range(segments):
            ang = 2.0 * math.pi * s / segments
            offset = (side * math.cos(ang) + up * math.sin(ang)) * r
            ring.append(bm.verts.new(p + offset))
        rings.append(ring)

    faces: List[bmesh.types.BMFace] = []
    for i in range(len(rings) - 1):
        r0 = rings[i]
        r1 = rings[i + 1]
        for s in range(segments):
            sn = (s + 1) % segments
            f = bm.faces.new((r0[s], r0[sn], r1[sn], r1[s]))
            faces.append(f)

    if cap_ends:
        faces.append(bm.faces.new(list(reversed(rings[0]))))
        faces.append(bm.faces.new(rings[-1]))

    _assign_mat(faces, mat_idx)
    return faces


# =============================================================================
# 1. AERODYNAMIC FUSELAGE, TAIL BOOM, WINDOWS & LIVERY
# =============================================================================

# Station tuples: (y, z_center, half_width_x, half_height_z, superellipse_p)
_FUSELAGE_STATIONS: List[Tuple[float, float, float, float, float]] = [
    (3.12, 0.86, 0.14, 0.11, 2.0),   # Nose tip
    (2.85, 0.92, 0.42, 0.30, 2.1),   # Forward nose cone
    (2.35, 1.06, 0.68, 0.50, 2.2),   # Lower windshield base
    (1.70, 1.24, 0.85, 0.66, 2.4),   # Cockpit mid
    (0.95, 1.32, 0.92, 0.74, 2.6),   # Front cabin / pilot bulkhead
    (0.10, 1.34, 0.94, 0.76, 2.6),   # Main cabin center (under rotor)
    (-0.85, 1.34, 0.88, 0.74, 2.5),  # Rear cabin / camera op bay
    (-1.65, 1.36, 0.66, 0.60, 2.3),  # Aft cabin taper
    (-2.25, 1.40, 0.38, 0.38, 2.1),  # Cabin-to-boom transition
    (-2.85, 1.44, 0.22, 0.24, 2.0),  # Tail boom root
    (-4.20, 1.49, 0.16, 0.18, 2.0),  # Tail boom mid
    (-5.60, 1.54, 0.12, 0.14, 2.0),  # Tail boom aft
    (-6.68, 1.58, 0.08, 0.10, 2.0),  # Tail boom tip
]


def _superellipse_point(theta: float, rx: float, rz: float, p: float) -> Tuple[float, float]:
    """Evaluates a smooth superellipse cross-section at angle `theta`."""
    c = math.cos(theta)
    s = math.sin(theta)
    x = math.copysign(abs(c) ** (2.0 / p), c) * rx
    z = math.copysign(abs(s) ** (2.0 / p), s) * rz
    return x, z


def _classify_fuselage_face(y_mid: float, z_mid: float, theta_mid: float) -> int:
    """
    Assigns broadcast livery material index to each fuselage quad based on
    station Y and circumferential angle `theta` (0 = +X right, pi/2 = +Z top).
    """
    sin_t = math.sin(theta_mid)

    # Panoramic cockpit windshield & cabin side windows
    if 1.10 <= y_mid <= 2.65 and 0.10 <= sin_t <= 0.88:
        return HMAT_GLASS
    if -1.15 <= y_mid <= 0.90 and 0.18 <= sin_t <= 0.68 and abs(math.cos(theta_mid)) > 0.68:
        return HMAT_GLASS

    # Deep graphite lower belly & chin
    if sin_t < -0.22:
        return HMAT_GRAPHITE

    # Gold championship pinstripe separating graphite belly & burgundy band
    if -0.22 <= sin_t < -0.13:
        return HMAT_GOLD

    # Burgundy race broadcast stripe sweeping along fuselage & tail boom
    if -0.13 <= sin_t < 0.06:
        return HMAT_BURGUNDY

    # Glossy broadcast pearl white upper fuselage
    return HMAT_WHITE_LIVERY


def _build_fuselage_shell(bm: bmesh.types.BMesh) -> None:
    """Lofts the aerodynamic helicopter fuselage and tail boom with livery zones."""
    ring_segs = 36
    rings: List[List[bmesh.types.BMVert]] = []

    for y, zc, rx, rz, p in _FUSELAGE_STATIONS:
        ring: List[bmesh.types.BMVert] = []
        for s in range(ring_segs):
            theta = 2.0 * math.pi * s / ring_segs
            x, dz = _superellipse_point(theta, rx, rz, p)
            # Flatten belly slightly on main cabin stations
            if -1.5 <= y <= 2.0 and dz < 0.0:
                dz *= 0.90
            ring.append(bm.verts.new((x, y, zc + dz)))
        rings.append(ring)

    # Nose cap
    nose_y, nose_zc, _, _, _ = _FUSELAGE_STATIONS[0]
    nose_tip = bm.verts.new((0.0, nose_y + 0.08, nose_zc))
    for s in range(ring_segs):
        sn = (s + 1) % ring_segs
        f = bm.faces.new((nose_tip, rings[0][sn], rings[0][s]))
        f.material_index = HMAT_GRAPHITE

    # Lofted hull quads
    for i in range(len(rings) - 1):
        r0 = rings[i]
        r1 = rings[i + 1]
        y_mid = 0.5 * (_FUSELAGE_STATIONS[i][0] + _FUSELAGE_STATIONS[i + 1][0])
        z_mid = 0.5 * (_FUSELAGE_STATIONS[i][1] + _FUSELAGE_STATIONS[i + 1][1])

        for s in range(ring_segs):
            sn = (s + 1) % ring_segs
            theta_mid = 2.0 * math.pi * (s + 0.5) / ring_segs
            f = bm.faces.new((r0[s], r0[sn], r1[sn], r1[s]))
            f.material_index = _classify_fuselage_face(y_mid, z_mid, theta_mid)

    # Tail boom aft cap
    tail_y, tail_zc, _, _, _ = _FUSELAGE_STATIONS[-1]
    tail_tip = bm.verts.new((0.0, tail_y - 0.05, tail_zc))
    for s in range(ring_segs):
        sn = (s + 1) % ring_segs
        f = bm.faces.new((tail_tip, rings[-1][s], rings[-1][sn]))
        f.material_index = HMAT_GRAPHITE


def _build_engine_cowling_and_exhausts(bm: bmesh.types.BMesh) -> None:
    """Builds the upper twin-turbine engine cowling, air intakes, and exhausts."""
    # Main cowling fairing (white upper, burgundy side trim)
    _add_uv_sphere(
        bm,
        center=(0.0, -0.45, 2.04),
        radius=1.0,
        mat_idx=HMAT_WHITE_LIVERY,
        u_segments=28,
        v_segments=16,
        scale=(0.48, 1.38, 0.36),
    )

    # Forward rotor gearbox collar / fairing
    _add_cylinder(
        bm,
        center=(0.0, 0.0, 2.28),
        radius1=0.38,
        radius2=0.28,
        depth=0.28,
        mat_idx=HMAT_GRAPHITE,
        segments=24,
    )

    # Twin forward turbine air intake shrouds
    for side in (-1.0, 1.0):
        _add_box(
            bm,
            center=(side * 0.31, 0.25, 2.16),
            size=(0.20, 0.42, 0.18),
            mat_idx=HMAT_CARBON,
            rot_euler_rad=(math.radians(6.0), 0.0, side * math.radians(5.0)),
        )
        # Burgundy cowling accent fairing
        _add_box(
            bm,
            center=(side * 0.42, -0.55, 2.02),
            size=(0.08, 1.10, 0.14),
            mat_idx=HMAT_BURGUNDY,
        )

    # Twin angled titanium turbine exhaust pipes at aft end of cowling
    for side in (-1.0, 1.0):
        _add_cylinder(
            bm,
            center=(side * 0.20, -1.78, 2.06),
            radius1=0.11,
            radius2=0.095,
            depth=0.42,
            mat_idx=HMAT_TITANIUM,
            segments=18,
            rot_euler_rad=(math.radians(78.0), 0.0, side * math.radians(14.0)),
        )
        # Dark inner exhaust bore
        _add_cylinder(
            bm,
            center=(side * 0.23, -1.96, 2.10),
            radius1=0.075,
            radius2=0.075,
            depth=0.06,
            mat_idx=HMAT_GRAPHITE,
            segments=16,
            rot_euler_rad=(math.radians(78.0), 0.0, side * math.radians(14.0)),
        )


def _build_tail_empennage(bm: bmesh.types.BMesh) -> None:
    """Builds swept vertical tail fin, ventral fin, and horizontal stabilizers."""
    # Swept vertical tail fin (lofted airfoil-like trapezoidal fin)
    fin_profiles = [
        # (y_le, y_te, z, half_thick)
        (-5.75, -6.70, 1.54, 0.055),
        (-6.20, -7.02, 2.10, 0.042),
        (-6.58, -7.24, 2.55, 0.028),
    ]
    fin_rings: List[List[bmesh.types.BMVert]] = []
    for y_le, y_te, z, ht in fin_profiles:
        y_mid = 0.35 * y_le + 0.65 * y_te
        pts = [
            (0.0, y_le, z),
            (ht, y_mid, z),
            (0.0, y_te, z),
            (-ht, y_mid, z),
        ]
        fin_rings.append([bm.verts.new(p) for p in pts])

    for i in range(len(fin_rings) - 1):
        r0 = fin_rings[i]
        r1 = fin_rings[i + 1]
        mat = HMAT_BURGUNDY if i == 1 else HMAT_WHITE_LIVERY
        for s in range(4):
            sn = (s + 1) % 4
            f = bm.faces.new((r0[s], r0[sn], r1[sn], r1[s]))
            f.material_index = mat

    # Cap top of vertical fin in gold trim
    f_top = bm.faces.new(fin_rings[-1])
    f_top.material_index = HMAT_GOLD

    # Ventral stabilizing fin under tail boom
    _add_box(
        bm,
        center=(0.0, -6.22, 1.30),
        size=(0.045, 0.72, 0.42),
        mat_idx=HMAT_GRAPHITE,
        rot_euler_rad=(math.radians(-18.0), 0.0, 0.0),
    )

    # Horizontal stabilizers + endplate winglets
    for side in (-1.0, 1.0):
        _add_box(
            bm,
            center=(side * 0.62, -5.25, 1.54),
            size=(1.12, 0.44, 0.05),
            mat_idx=HMAT_WHITE_LIVERY,
            rot_euler_rad=(0.0, 0.0, side * math.radians(-4.0)),
        )
        # Endplate winglet
        _add_box(
            bm,
            center=(side * 1.18, -5.28, 1.58),
            size=(0.04, 0.48, 0.28),
            mat_idx=HMAT_BURGUNDY,
        )
        # Gold leading edge accent on stabilizer
        _add_box(
            bm,
            center=(side * 0.62, -5.02, 1.54),
            size=(1.10, 0.03, 0.035),
            mat_idx=HMAT_GOLD,
        )


def _build_broadcast_antennas_and_lights(bm: bmesh.types.BMesh) -> None:
    """Adds SATCOM broadcast uplink dome, antennas, pitot probe, and nav lights."""
    # SATCOM uplink radome behind main rotor cowling
    _add_uv_sphere(
        bm,
        center=(0.0, -2.05, 1.88),
        radius=0.18,
        mat_idx=HMAT_WHITE_LIVERY,
        u_segments=20,
        v_segments=12,
        scale=(1.0, 1.25, 0.72),
    )
    # Gold ring at base of SATCOM dome
    _add_cylinder(
        bm,
        center=(0.0, -2.05, 1.82),
        radius1=0.19,
        radius2=0.19,
        depth=0.025,
        mat_idx=HMAT_GOLD,
        segments=20,
    )

    # Nose pitot tube
    _add_cylinder(
        bm,
        center=(0.18, 3.18, 0.92),
        radius1=0.012,
        radius2=0.008,
        depth=0.38,
        mat_idx=HMAT_TITANIUM,
        segments=10,
        rot_euler_rad=(math.radians(90.0), 0.0, 0.0),
    )

    # Belly UHF broadcast downlink blade antennas
    for y_ant in (-0.80, -3.50):
        _add_box(
            bm,
            center=(0.0, y_ant, 0.56 if y_ant > -2.0 else 1.22),
            size=(0.02, 0.14, 0.24),
            mat_idx=HMAT_CARBON,
            rot_euler_rad=(math.radians(-18.0), 0.0, 0.0),
        )

    # Navigation & anti-collision strobe lights
    # Port (-X) red nav light on horizontal stabilizer winglet
    _add_uv_sphere(bm, center=(-1.19, -5.08, 1.66), radius=0.038, mat_idx=HMAT_LED_RED, u_segments=12, v_segments=8)
    # Starboard (+X) cyan/green telemetry nav light
    _add_uv_sphere(bm, center=(1.19, -5.08, 1.66), radius=0.038, mat_idx=HMAT_LED_CYAN, u_segments=12, v_segments=8)
    # Tail fin top red anti-collision beacon
    _add_uv_sphere(bm, center=(0.0, -6.92, 2.58), radius=0.045, mat_idx=HMAT_LED_RED, u_segments=12, v_segments=8)
    # Aft tail white strobe
    _add_uv_sphere(bm, center=(0.0, -7.25, 2.50), radius=0.035, mat_idx=HMAT_LED_WHITE, u_segments=12, v_segments=8)
    # Forward chin landing spotlight
    _add_cylinder(
        bm,
        center=(0.0, 2.92, 0.72),
        radius1=0.055,
        radius2=0.055,
        depth=0.03,
        mat_idx=HMAT_LED_WHITE,
        segments=16,
        rot_euler_rad=(math.radians(78.0), 0.0, 0.0),
    )


# =============================================================================
# 2. LANDING SKIDS
# =============================================================================

def _build_landing_skids(bm: bmesh.types.BMesh) -> None:
    """Builds tubular landing skids with upturned toes, cross-struts, and step pads."""
    skid_x = 1.02
    skid_r = 0.042

    for side in (-1.0, 1.0):
        x = side * skid_x
        # Main longitudinal runner + curved upturned front toe
        runner_pts = [
            (x, -1.65, 0.045),
            (x, -0.80, 0.045),
            (x, 0.40, 0.045),
            (x, 1.55, 0.045),
            (x, 1.92, 0.075),
            (x, 2.18, 0.165),
            (x, 2.34, 0.285),
        ]
        _add_tube_along_points(bm, runner_pts, skid_r, HMAT_GRAPHITE, segments=14)

        # Titanium abrasion wear shoes on bottom of skids
        for y_shoe in (-1.20, 0.0, 1.20):
            _add_box(
                bm,
                center=(x, y_shoe, 0.012),
                size=(0.06, 0.34, 0.022),
                mat_idx=HMAT_TITANIUM,
            )

        # Non-slip boarding step pad
        _add_box(
            bm,
            center=(side * (skid_x - 0.14), 0.35, 0.26),
            size=(0.14, 0.65, 0.025),
            mat_idx=HMAT_CARBON,
        )

        # Forward & aft swept cross-struts connecting skid to fuselage belly
        for y_skid, y_belly in ((1.05, 0.92), (-1.00, -0.92)):
            strut_pts = [
                (x, y_skid, 0.06),
                (side * 0.90, 0.5 * (y_skid + y_belly), 0.36),
                (side * 0.62, y_belly, 0.64),
            ]
            _add_tube_along_points(bm, strut_pts, 0.036, HMAT_GRAPHITE, segments=12)

            # Burgundy aerodynamic collar on each strut
            _add_cylinder(
                bm,
                center=(side * 0.90, 0.5 * (y_skid + y_belly), 0.36),
                radius1=0.044,
                radius2=0.044,
                depth=0.14,
                mat_idx=HMAT_BURGUNDY,
                segments=12,
                rot_euler_rad=(0.0, side * math.radians(-38.0), 0.0),
            )


# =============================================================================
# 3. MAIN ROTOR & TAIL ROTOR (SEPARATE ANIMATABLE OBJECTS)
# =============================================================================

def _add_airfoil_blade(
    bm: bmesh.types.BMesh,
    root_pos: Tuple[float, float, float],
    length: float,
    chord_root: float,
    chord_tip: float,
    thick_ratio: float,
    azimuth_rad: float,
    axis: str,
    mat_body: int,
    mat_tip: int,
) -> None:
    """
    Builds a single aerodynamic twisted airfoil rotor blade.
    `axis == 'Z'` builds a main rotor blade extending radially in XY.
    `axis == 'X'` builds a tail rotor blade extending radially in YZ.
    """
    num_span = 10
    profile_pts = [
        (0.50, 0.00),     # Leading edge
        (0.25, 0.65),     # Upper camber front
        (-0.15, 0.55),    # Upper camber aft
        (-0.50, 0.00),    # Trailing edge
        (-0.15, -0.22),   # Lower flat-camber aft
        (0.25, -0.28),    # Lower camber front
    ]

    rot_mat = (
        Matrix.Rotation(azimuth_rad, 4, "Z")
        if axis == "Z"
        else Matrix.Rotation(azimuth_rad, 4, "X")
    )
    origin = Vector(root_pos)
    rings: List[List[bmesh.types.BMVert]] = []

    for i in range(num_span):
        t = i / (num_span - 1)
        r = 0.24 + t * (length - 0.24)
        chord = chord_root + (chord_tip - chord_root) * (t ** 1.4)
        thick = chord * thick_ratio * (1.0 - 0.25 * t)
        pitch_rad = math.radians(10.0 - 6.0 * t)  # Aerodynamic washout twist
        sweep_lag = -0.08 * (t ** 3) if t > 0.7 else 0.0

        ring: List[bmesh.types.BMVert] = []
        cp = math.cos(pitch_rad)
        sp = math.sin(pitch_rad)

        for px, pz in profile_pts:
            cx = px * chord
            cz = pz * thick
            # Apply pitch twist
            tx = cx * cp - cz * sp
            tz = cx * sp + cz * cp

            if axis == "Z":
                local_v = Vector((r, tx + sweep_lag, tz))
            else:
                local_v = Vector((tz, tx + sweep_lag, r))

            world_v = origin + (rot_mat @ local_v)
            ring.append(bm.verts.new(world_v))
        rings.append(ring)

    n_prof = len(profile_pts)
    for i in range(len(rings) - 1):
        r0 = rings[i]
        r1 = rings[i + 1]
        is_tip = i >= num_span - 3
        mat = mat_tip if is_tip else mat_body
        for s in range(n_prof):
            sn = (s + 1) % n_prof
            f = bm.faces.new((r0[s], r0[sn], r1[sn], r1[s]))
            f.material_index = mat

    # Cap root and tip
    f_root = bm.faces.new(list(reversed(rings[0])))
    f_root.material_index = mat_body
    f_tip = bm.faces.new(rings[-1])
    f_tip.material_index = mat_tip


def _build_main_rotor(bm: bmesh.types.BMesh) -> None:
    """
    Builds the main rotor assembly around local origin (0, 0, 0)
    (placed at MAIN_ROTOR_PIVOT so Z-rotation animates smoothly).
    """
    # Titanium main rotor mast extending down into gearbox collar
    _add_cylinder(
        bm,
        center=(0.0, 0.0, -0.22),
        radius1=0.075,
        radius2=0.075,
        depth=0.46,
        mat_idx=HMAT_TITANIUM,
        segments=20,
    )
    # Swashplate ring
    _add_cylinder(
        bm,
        center=(0.0, 0.0, -0.14),
        radius1=0.19,
        radius2=0.19,
        depth=0.045,
        mat_idx=HMAT_BURGUNDY,
        segments=24,
    )
    # Central aerodynamic rotor head hub cap
    _add_uv_sphere(
        bm,
        center=(0.0, 0.0, 0.03),
        radius=0.26,
        mat_idx=HMAT_CARBON,
        u_segments=24,
        v_segments=14,
        scale=(1.0, 1.0, 0.42),
    )

    # 4 Main Rotor Blades + blade grip arms
    num_blades = 4
    for b in range(num_blades):
        az = 2.0 * math.pi * b / num_blades
        # Titanium blade grip arm
        gx = 0.18 * math.cos(az)
        gy = 0.18 * math.sin(az)
        _add_box(
            bm,
            center=(gx, gy, 0.0),
            size=(0.30, 0.09, 0.045),
            mat_idx=HMAT_TITANIUM,
            rot_euler_rad=(0.0, 0.0, az),
        )
        # Composite carbon airfoil blade with championship gold warning tip
        _add_airfoil_blade(
            bm,
            root_pos=(0.0, 0.0, 0.0),
            length=MAIN_ROTOR_RADIUS,
            chord_root=0.30,
            chord_tip=0.22,
            thick_ratio=0.14,
            azimuth_rad=az,
            axis="Z",
            mat_body=HMAT_CARBON,
            mat_tip=HMAT_GOLD,
        )


def _build_tail_rotor(bm: bmesh.types.BMesh) -> None:
    """
    Builds the tail rotor assembly around local origin (0, 0, 0)
    (placed at TAIL_ROTOR_PIVOT so X-rotation animates smoothly).
    """
    # Gearbox shaft extending from tail fin (+X) to rotor hub (0)
    _add_cylinder(
        bm,
        center=(0.08, 0.0, 0.0),
        radius1=0.045,
        radius2=0.045,
        depth=0.18,
        mat_idx=HMAT_TITANIUM,
        segments=16,
        rot_euler_rad=(0.0, math.radians(90.0), 0.0),
    )
    # Aerodynamic tail rotor hub spinner
    _add_uv_sphere(
        bm,
        center=(-0.03, 0.0, 0.0),
        radius=0.09,
        mat_idx=HMAT_BURGUNDY,
        u_segments=18,
        v_segments=12,
        scale=(0.65, 1.0, 1.0),
    )

    # 4-blade X-configuration quiet tail rotor
    x_angles_deg = [30.0, 150.0, 210.0, 330.0]
    for deg in x_angles_deg:
        _add_airfoil_blade(
            bm,
            root_pos=(0.0, 0.0, 0.0),
            length=TAIL_ROTOR_RADIUS,
            chord_root=0.11,
            chord_tip=0.085,
            thick_ratio=0.14,
            azimuth_rad=math.radians(deg),
            axis="X",
            mat_body=HMAT_CARBON,
            mat_tip=HMAT_GOLD,
        )


# =============================================================================
# 4. CINEFLEX GYRO-STABILIZED CAMERA GIMBAL
# =============================================================================

def _build_cineflex_gimbal(bm: bmesh.types.BMesh) -> None:
    """
    Builds the spherical Cineflex gyro-stabilized camera head around local
    origin (0, 0, 0) (placed at CINEFLEX_PIVOT under the nose).
    """
    # Vibration-isolated mounting flange & yoke bracket up into the nose chin
    _add_cylinder(
        bm,
        center=(0.0, -0.04, 0.34),
        radius1=0.12,
        radius2=0.14,
        depth=0.12,
        mat_idx=HMAT_GRAPHITE,
        segments=20,
    )
    # Dual curved yoke arms
    for side in (-1.0, 1.0):
        _add_box(
            bm,
            center=(side * 0.16, -0.02, 0.18),
            size=(0.045, 0.10, 0.32),
            mat_idx=HMAT_CARBON,
            rot_euler_rad=(math.radians(-10.0), side * math.radians(-12.0), 0.0),
        )

    # Main spherical matte-carbon Cineflex gyro turret
    _add_uv_sphere(
        bm,
        center=(0.0, 0.0, 0.0),
        radius=CINEFLEX_RADIUS,
        mat_idx=HMAT_CARBON,
        u_segments=32,
        v_segments=20,
    )

    # Equatorial azimuth bearing ring (burgundy + titanium)
    _add_cylinder(
        bm,
        center=(0.0, 0.0, 0.02),
        radius1=CINEFLEX_RADIUS + 0.008,
        radius2=CINEFLEX_RADIUS + 0.008,
        depth=0.028,
        mat_idx=HMAT_BURGUNDY,
        segments=32,
    )

    # Front optical aperture bezel & protruding telephoto broadcast lens barrel
    # Angled slightly downward (-14 deg) toward the peloton below
    pitch_down = math.radians(90.0 + 14.0)
    _add_cylinder(
        bm,
        center=(0.0, 0.22, -0.045),
        radius1=0.105,
        radius2=0.095,
        depth=0.10,
        mat_idx=HMAT_GRAPHITE,
        segments=24,
        rot_euler_rad=(pitch_down, 0.0, 0.0),
    )
    # Titanium lens focus ring
    _add_cylinder(
        bm,
        center=(0.0, 0.275, -0.058),
        radius1=0.092,
        radius2=0.092,
        depth=0.025,
        mat_idx=HMAT_TITANIUM,
        segments=24,
        rot_euler_rad=(pitch_down, 0.0, 0.0),
    )
    # Coated iridium-cyan telephoto objective glass
    _add_cylinder(
        bm,
        center=(0.0, 0.285, -0.061),
        radius1=0.078,
        radius2=0.078,
        depth=0.014,
        mat_idx=HMAT_LENS_GLASS,
        segments=24,
        rot_euler_rad=(pitch_down, 0.0, 0.0),
    )

    # Secondary wide-angle tracking optical port (offset right)
    _add_cylinder(
        bm,
        center=(0.11, 0.20, 0.05),
        radius1=0.042,
        radius2=0.042,
        depth=0.03,
        mat_idx=HMAT_TITANIUM,
        segments=16,
        rot_euler_rad=(pitch_down, 0.0, 0.0),
    )
    _add_cylinder(
        bm,
        center=(0.11, 0.215, 0.046),
        radius1=0.032,
        radius2=0.032,
        depth=0.01,
        mat_idx=HMAT_LENS_GLASS,
        segments=16,
        rot_euler_rad=(pitch_down, 0.0, 0.0),
    )

    # Active broadcast telemetry status LED on side of Cineflex sphere
    _add_uv_sphere(
        bm,
        center=(-0.22, 0.06, 0.04),
        radius=0.016,
        mat_idx=HMAT_LED_CYAN,
        u_segments=10,
        v_segments=8,
    )


# =============================================================================
# SCENE ASSEMBLY & GLB EXPORT
# =============================================================================

def generate_tv_helicopter_objects() -> List[bpy.types.Object]:
    """
    Generates all TV Broadcast Helicopter objects with proper animation pivots
    and parent-child hierarchy, and returns them.
    """
    materials = create_helicopter_materials()
    objects: List[bpy.types.Object] = []

    # 1. Fuselage, tail boom, windows, engine cowling, empennage & nav lights
    fuse_obj, fuse_mesh, fuse_bm = _create_mesh_object("TV_Heli_Fuselage", materials)
    _build_fuselage_shell(fuse_bm)
    _build_engine_cowling_and_exhausts(fuse_bm)
    _build_tail_empennage(fuse_bm)
    _build_broadcast_antennas_and_lights(fuse_bm)
    _finalize_mesh_object(fuse_obj, fuse_mesh, fuse_bm, location=(0.0, 0.0, 0.0))
    objects.append(fuse_obj)

    # 2. Landing skids
    skid_obj, skid_mesh, skid_bm = _create_mesh_object("TV_Heli_Skids", materials)
    _build_landing_skids(skid_bm)
    _finalize_mesh_object(skid_obj, skid_mesh, skid_bm, location=(0.0, 0.0, 0.0))
    skid_obj.parent = fuse_obj
    objects.append(skid_obj)

    # 3. Main rotor (separate named object with pivot at MAIN_ROTOR_PIVOT for Z rotation)
    main_rotor_obj, mr_mesh, mr_bm = _create_mesh_object("TV_Heli_Main_Rotor", materials)
    _build_main_rotor(mr_bm)
    _finalize_mesh_object(main_rotor_obj, mr_mesh, mr_bm, location=MAIN_ROTOR_PIVOT)
    main_rotor_obj.parent = fuse_obj
    objects.append(main_rotor_obj)

    # 4. Tail rotor (separate named object with pivot at TAIL_ROTOR_PIVOT for X rotation)
    tail_rotor_obj, tr_mesh, tr_bm = _create_mesh_object("TV_Heli_Tail_Rotor", materials)
    _build_tail_rotor(tr_bm)
    _finalize_mesh_object(tail_rotor_obj, tr_mesh, tr_bm, location=TAIL_ROTOR_PIVOT)
    tail_rotor_obj.parent = fuse_obj
    objects.append(tail_rotor_obj)

    # 5. Cineflex gyro-stabilized camera head under the nose
    gimbal_obj, gm_mesh, gm_bm = _create_mesh_object("TV_Heli_Cineflex_Gimbal", materials)
    _build_cineflex_gimbal(gm_bm)
    _finalize_mesh_object(gimbal_obj, gm_mesh, gm_bm, location=CINEFLEX_PIVOT)
    gimbal_obj.parent = fuse_obj
    objects.append(gimbal_obj)

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


def export_tv_helicopter(
    output_dir: str = "assets/3d/environment",
) -> str:
    """Generates and exports `tv_helicopter.glb` into `output_dir`."""
    os.makedirs(output_dir, exist_ok=True)
    _clear_scene_meshes()
    objs = generate_tv_helicopter_objects()
    out_path = os.path.join(output_dir, "tv_helicopter.glb")
    export_glb(objs, out_path)
    return out_path


if __name__ == "__main__":
    out_dir = "assets/3d/environment"
    for idx, arg in enumerate(sys.argv):
        if arg in ["--output-dir", "-o"] and idx + 1 < len(sys.argv):
            out_dir = sys.argv[idx + 1]

    out_file = export_tv_helicopter(output_dir=out_dir)
    sm.setup_zwift_studio_lighting()
    print(f"[SUCCESS] TV Broadcast Helicopter generated: {out_file}")
