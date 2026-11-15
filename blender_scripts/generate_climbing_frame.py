"""
===============================================================================
PRO PELOTON MANAGER - PROCEDURAL CLIMBING ROAD BICYCLE FRAME GENERATOR
===============================================================================
Blender Python API (bpy) script that procedurally models a modern ultra-lightweight
climbing road racing bicycle frame (inspired by Specialized S-Works Aethos, Trek
Émonda SLR, Canyon Ultimate CFR, Giant TCR Advanced SL, Wilier Zero SLR).

Key Climbing Engineering Features:
  1. Slender, Rounded Main Triangle: continuous organic round/oval tube shapes
     maximizing carbon fiber stress distribution and stiffness-to-weight ratio
     without heavy deep aerodynamic fins.
  2. Classic Lightweight Rear Triangle: traditional high seatstay junction meeting
     directly at the seat tube / top tube cluster; ultra-pencil-thin seatstays
     (10-12mm) engineered for vertical compliance, vibration dampening, and gram-saving.
  3. Classic Round 27.2mm Seatpost & Minimalist Collar: traditional slender round
     seatpost with a lightweight external CNC clamp collar.
  4. Slender Climbing Disc Fork: razor-sharp, lightweight tapered straight blades
     for agility on high-gradient Alpine switchbacks and technical descents.
  5. Compact Tapered Head Tube & Round BB Shell.
  6. Material Assignment: PBR materials from `style_and_materials.py`
     (High-Gloss Frame Paint, Carbon Matte, Metal Inserts).
  7. Export to GLB format at `assets/3d/bikes/frame_climbing.glb`.

Compatible with Blender 3.6 LTS, 4.x, and 5.x+.
===============================================================================
"""

import math
import os
import sys
from typing import Callable, List, Optional, Tuple, Union

try:
    import bpy
    import bmesh
    from mathutils import Matrix, Vector
except ImportError:
    print("[ERROR] 'bpy' / 'mathutils' module not found. This script must be run within Blender:")
    print("        blender --background --python blender_scripts/generate_climbing_frame.py")
    sys.exit(1)

# Ensure local script directory is in sys.path to import style_and_materials
script_dir = os.path.dirname(os.path.abspath(__file__))
if script_dir not in sys.path:
    sys.path.insert(0, script_dir)

try:
    import style_and_materials as sm
except ImportError:
    print(f"[ERROR] Could not import 'style_and_materials' from '{script_dir}'.")
    sys.exit(1)


# =============================================================================
# 2D ROUND / OVAL / SQUOVAL PROFILE GENERATORS FOR CLIMBING BICYCLES
# =============================================================================

def generate_oval_2d_points(
    radius_x: float,
    radius_y: float,
    num_points: int = 16,
) -> List[Vector]:
    """
    Generates a 2D smooth ellipse/oval closed polygon in the XY plane.
    When radius_x == radius_y, produces a perfect circular tube cross-section.
    """
    pts = []
    for i in range(num_points):
        angle = (i / float(num_points)) * 2.0 * math.pi
        x = radius_x * math.cos(angle)
        y = radius_y * math.sin(angle)
        pts.append(Vector((x, y, 0.0)))
    return pts


def generate_squoval_2d_points(
    radius_x: float,
    radius_y: float,
    power: float = 2.8,
    num_points: int = 16,
) -> List[Vector]:
    """
    Generates a 2D squoval (superellipse) cross-section used in climbing frames
    (e.g. Cervelo R-Series / Aethos downtubes) combining round torsional stiffness
    with lateral box rigidity.
    """
    pts = []
    for i in range(num_points):
        angle = (i / float(num_points)) * 2.0 * math.pi
        cos_a = math.cos(angle)
        sin_a = math.sin(angle)

        sign_cos = 1.0 if cos_a >= 0.0 else -1.0
        sign_sin = 1.0 if sin_a >= 0.0 else -1.0

        x = radius_x * sign_cos * (abs(cos_a) ** (2.0 / power))
        y = radius_y * sign_sin * (abs(sin_a) ** (2.0 / power))
        pts.append(Vector((x, y, 0.0)))
    return pts


# =============================================================================
# BMESH LOFTING AND MESH TOPOLOGY UTILITIES
# =============================================================================

def loft_rings(
    bm: bmesh.types.BMesh,
    rings: List[List[bmesh.types.BMVert]],
    cap_start: bool = True,
    cap_end: bool = True,
    material_index: int = 0,
) -> List[bmesh.types.BMFace]:
    """
    Lofts a list of consecutive vertex rings into quad faces,
    capping start and end loops if specified.
    """
    created_faces = []
    for r_idx in range(len(rings) - 1):
        r1 = rings[r_idx]
        r2 = rings[r_idx + 1]
        n_pts = len(r1)
        for i in range(n_pts):
            i_next = (i + 1) % n_pts
            try:
                face = bm.faces.new([r1[i], r1[i_next], r2[i_next], r2[i]])
                face.material_index = material_index
                created_faces.append(face)
            except ValueError:
                pass

    if cap_start and len(rings) > 0:
        try:
            face_start = bm.faces.new(list(reversed(rings[0])))
            face_start.material_index = material_index
            created_faces.append(face_start)
        except ValueError:
            pass

    if cap_end and len(rings) > 0:
        try:
            face_end = bm.faces.new(rings[-1])
            face_end.material_index = material_index
            created_faces.append(face_end)
        except ValueError:
            pass

    return created_faces


def loft_slender_tube(
    bm: bmesh.types.BMesh,
    path_points: List[Vector],
    rx_func: Union[float, Callable[[float], float]],
    ry_func: Union[float, Callable[[float], float]],
    profile_type: str = "oval",
    lateral_hint: Vector = Vector((0.0, 1.0, 0.0)),
    num_profile_pts: int = 16,
    cap_start: bool = True,
    cap_end: bool = True,
    material_index: int = 0,
) -> List[List[bmesh.types.BMVert]]:
    """
    Lofts a slender organic climbing tube along a 3D path with Bishop/Frenet frames.
    """
    n_steps = len(path_points)
    if n_steps < 2:
        return []

    rings = []
    for s_idx, center in enumerate(path_points):
        t = s_idx / float(n_steps - 1)

        # Tangent vector
        if s_idx == 0:
            T = (path_points[1] - path_points[0]).normalized()
        elif s_idx == n_steps - 1:
            T = (path_points[-1] - path_points[-2]).normalized()
        else:
            T = (path_points[s_idx + 1] - path_points[s_idx - 1]).normalized()

        # Lateral binormal vector
        B = lateral_hint - (lateral_hint.dot(T)) * T
        if B.length < 1e-4:
            B = Vector((0.0, 0.0, 1.0)).cross(T)
        B.normalize()

        # Normal vector perpendicular to tangent and lateral
        N = T.cross(B).normalized()

        # Evaluate radii
        cur_rx = rx_func(t) if callable(rx_func) else rx_func
        cur_ry = ry_func(t) if callable(ry_func) else ry_func

        if profile_type == "squoval":
            pts_2d = generate_squoval_2d_points(cur_rx, cur_ry, num_points=num_profile_pts)
        else:
            pts_2d = generate_oval_2d_points(cur_rx, cur_ry, num_points=num_profile_pts)

        ring = []
        for p in pts_2d:
            v_world = center + p.x * N + p.y * B
            ring.append(bm.verts.new(v_world))
        rings.append(ring)

    loft_rings(bm, rings, cap_start=cap_start, cap_end=cap_end, material_index=material_index)
    return rings


# =============================================================================
# CLIMBING FRAME PROCEDURAL DETAILS (HEAD TUBE, BB, SEATPOST COLLAR, DROPOUTS)
# =============================================================================

def build_climbing_headtube(
    bm: bmesh.types.BMesh,
    p_bottom: Vector,
    p_top: Vector,
    r_bottom: float = 0.025,  # 50mm lower bearing race
    r_top: float = 0.022,     # 44mm upper race
    num_steps: int = 6,
    segments: int = 18,
    material_index: int = 0,
) -> None:
    """
    Constructs a slender, minimalist tapered round head tube.
    """
    rings = []
    axis = (p_top - p_bottom).normalized()
    lat = Vector((0.0, 1.0, 0.0))
    norm = axis.cross(lat).normalized()

    for i in range(num_steps + 1):
        t = i / float(num_steps)
        center = p_bottom.lerp(p_top, t)
        r = r_bottom + t * (r_top - r_bottom)
        ring = []
        for s in range(segments):
            angle = (s / float(segments)) * 2.0 * math.pi
            pos = center + (r * math.cos(angle)) * norm + (r * math.sin(angle)) * lat
            ring.append(bm.verts.new(pos))
        rings.append(ring)

    loft_rings(bm, rings, cap_start=True, cap_end=True, material_index=material_index)


def build_climbing_bb_shell(
    bm: bmesh.types.BMesh,
    center: Vector,
    width: float = 0.068,  # classic 68mm English / BB86 shell
    radius: float = 0.021,  # 42mm outer shell
    segments: int = 18,
    material_index: int = 0,
) -> None:
    """
    Constructs a compact, minimalist round bottom bracket shell.
    """
    half_w = width * 0.5
    rings = []
    for y_offset in [-half_w, 0.0, half_w]:
        c = center + Vector((0.0, y_offset, 0.0))
        ring = []
        for s in range(segments):
            angle = (s / float(segments)) * 2.0 * math.pi
            pos = c + Vector((radius * math.cos(angle), 0.0, radius * math.sin(angle)))
            ring.append(bm.verts.new(pos))
        rings.append(ring)

    loft_rings(bm, rings, cap_start=True, cap_end=True, material_index=material_index)


def build_seat_clamp_collar(
    bm: bmesh.types.BMesh,
    cluster_pos: Vector,
    height: float = 0.016,
    inner_radius: float = 0.0160,
    outer_radius: float = 0.0185,
    segments: int = 16,
    material_index: int = 1,
) -> None:
    """
    Constructs a classic external CNC aluminum / carbon seat collar clamp with bolt tab.
    """
    p_base = cluster_pos + Vector((0.0, 0.0, -0.002))
    axis = Vector((-0.038, 0.0, 0.135)).normalized()
    lat = Vector((0.0, 1.0, 0.0))
    norm = axis.cross(lat).normalized()

    rings = []
    for h in [0.0, height]:
        c = p_base + axis * h
        ring = []
        for s in range(segments):
            angle = (s / float(segments)) * 2.0 * math.pi
            # Subtle rear bolt protrusion
            bolt_bulge = 1.25 if math.cos(angle) < -0.7 else 1.0
            r = outer_radius * bolt_bulge
            pos = c + (r * math.cos(angle)) * norm + (r * math.sin(angle)) * lat
            ring.append(bm.verts.new(pos))
        rings.append(ring)

    loft_rings(bm, rings, cap_start=True, cap_end=True, material_index=material_index)


def build_saddle_cradle(
    bm: bmesh.types.BMesh,
    clamp_top: Vector,
    material_index: int = 1,
) -> None:
    """
    Constructs minimalist carbon saddle clamp hardware for 27.2mm round seatpost.
    """
    pts = [
        Vector((-0.028, -0.020, 0.0)),
        Vector((0.028, -0.020, 0.0)),
        Vector((0.028, 0.020, 0.0)),
        Vector((-0.028, 0.020, 0.0)),
    ]
    r1 = [bm.verts.new(clamp_top + p) for p in pts]
    r2 = [bm.verts.new(clamp_top + p + Vector((0.0, 0.0, 0.014))) for p in pts]
    loft_rings(bm, [r1, r2], cap_start=True, cap_end=True, material_index=material_index)

    # Saddle rail channels
    for y_rail in [-0.019, 0.019]:
        p1 = clamp_top + Vector((-0.025, y_rail, 0.014))
        p2 = clamp_top + Vector((0.025, y_rail, 0.014))
        box1 = [
            bm.verts.new(p1 + Vector((0.0, -0.0035, 0.0))),
            bm.verts.new(p1 + Vector((0.0, 0.0035, 0.0))),
            bm.verts.new(p1 + Vector((0.0, 0.0035, 0.007))),
            bm.verts.new(p1 + Vector((0.0, -0.0035, 0.007))),
        ]
        box2 = [
            bm.verts.new(p2 + Vector((0.0, -0.0035, 0.0))),
            bm.verts.new(p2 + Vector((0.0, 0.0035, 0.0))),
            bm.verts.new(p2 + Vector((0.0, 0.0035, 0.007))),
            bm.verts.new(p2 + Vector((0.0, -0.0035, 0.007))),
        ]
        loft_rings(bm, [box1, box2], cap_start=True, cap_end=True, material_index=material_index)


def build_thru_axle_boss(
    bm: bmesh.types.BMesh,
    position: Vector,
    is_left: bool = True,
    material_index: int = 1,
) -> None:
    """
    Constructs minimalist 12mm thru-axle dropouts.
    """
    radius = 0.011  # 22mm lightweight dropout boss
    width = 0.014
    y_dir = -1.0 if is_left else 1.0
    p1 = position
    p2 = position + Vector((0.0, y_dir * width, 0.0))

    rings = []
    for p in [p1, p2]:
        ring = []
        for s in range(12):
            angle = (s / 12.0) * 2.0 * math.pi
            pos = p + Vector((radius * math.cos(angle), 0.0, radius * math.sin(angle)))
            ring.append(bm.verts.new(pos))
        rings.append(ring)

    loft_rings(bm, rings, cap_start=True, cap_end=True, material_index=material_index)


def build_flat_mount_tabs(
    bm: bmesh.types.BMesh,
    base_pos: Vector,
    direction: Vector,
    material_index: int = 1,
) -> None:
    """
    Constructs minimalist flat-mount disc brake caliper mounting tabs.
    """
    dir_norm = direction.normalized()
    lat = Vector((0.0, -1.0, 0.0))

    for offset in [-0.017, 0.017]:
        boss_center = base_pos + dir_norm * offset + lat * 0.007
        rings = []
        for h in [0.0, 0.010]:
            ring = []
            c = boss_center + Vector((0.0, 0.0, h))
            for s in range(8):
                a = (s / 8.0) * 2.0 * math.pi
                pos = c + Vector((0.005 * math.cos(a), 0.005 * math.sin(a), 0.0))
                ring.append(bm.verts.new(pos))
            rings.append(ring)
        loft_rings(bm, rings, cap_start=True, cap_end=True, material_index=material_index)


# =============================================================================
# MAIN PROCEDURAL CLIMBING FRAME GENERATOR
# =============================================================================

def create_climbing_frame_mesh(
    name: str = "Bike_Frame_Climbing",
    hex_color: str = "#0284C7",  # Alpine Sky Blue
) -> bpy.types.Object:
    """
    Procedurally creates an ultra-lightweight climbing road bicycle frame:
      - Slender, organic rounded/squoval Down Tube (38-48mm)
      - Slender round/oval Top Tube (34-26mm)
      - Compact Round Tapered Head Tube
      - Traditional straight Seat Tube with Round 27.2mm Seatpost & CNC Collar
      - Classic Lightweight Rear Triangle: pencil-thin seatstays (10-12mm)
        connecting directly to the high seat cluster (non-dropped)
      - Lightweight Chainstays & Compact BB Shell
    """
    bm = bmesh.new()

    # Geometry Reference Points (Meters)
    P_BB = Vector((0.000, 0.000, 0.270))
    P_HT_BOTTOM = Vector((0.480, 0.000, 0.505))
    P_HT_TOP = Vector((0.440, 0.000, 0.650))
    P_SEAT_CLUSTER = Vector((-0.160, 0.000, 0.755))
    P_SEATPOST_TOP = Vector((-0.200, 0.000, 0.895))
    P_REAR_AXLE_L = Vector((-0.410, -0.071, 0.340))
    P_REAR_AXLE_R = Vector((-0.410, 0.071, 0.340))

    # 1. DOWN TUBE (Slender Organic Squoval/Round Profile)
    # -------------------------------------------------------------------------
    dt_path = [P_HT_BOTTOM.lerp(P_BB, s / 6.0) for s in range(7)]
    loft_slender_tube(
        bm,
        dt_path,
        rx_func=lambda t: 0.019 + t * 0.005,  # 38mm at top to 48mm at BB
        ry_func=lambda t: 0.019 + t * 0.005,  # circular / squoval
        profile_type="squoval",
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_profile_pts=16,
        material_index=0,
    )

    # 2. TOP TUBE (Slender Organic Round-Oval)
    # -------------------------------------------------------------------------
    tt_path = [P_HT_TOP.lerp(P_SEAT_CLUSTER, s / 6.0) for s in range(7)]
    loft_slender_tube(
        bm,
        tt_path,
        rx_func=lambda t: 0.017 - t * 0.004,  # 34mm at front tapering to 26mm at rear
        ry_func=lambda t: 0.016 - t * 0.003,
        profile_type="oval",
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_profile_pts=16,
        material_index=0,
    )

    # 3. HEAD TUBE (Compact Minimalist Round Tapered Cylinder)
    # -------------------------------------------------------------------------
    build_climbing_headtube(bm, P_HT_BOTTOM, P_HT_TOP, material_index=0)

    # 4. SEAT TUBE & ROUND 27.2mm SEATPOST
    # -------------------------------------------------------------------------
    # Main Seat Tube (from BB to Seat Cluster)
    st_path = [P_BB.lerp(P_SEAT_CLUSTER, s / 5.0) for s in range(6)]
    loft_slender_tube(
        bm,
        st_path,
        rx_func=0.0159,  # 31.8mm round seat tube
        ry_func=0.0159,
        profile_type="oval",
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_profile_pts=16,
        material_index=0,
    )

    # Classic External CNC Seat Collar Clamp
    build_seat_clamp_collar(bm, P_SEAT_CLUSTER, material_index=1)

    # Round 27.2mm Lightweight Carbon Seatpost
    sp_path = [P_SEAT_CLUSTER, P_SEATPOST_TOP]
    loft_slender_tube(
        bm,
        sp_path,
        rx_func=0.0136,  # 27.2mm outer seatpost
        ry_func=0.0136,
        profile_type="oval",
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_profile_pts=16,
        material_index=1,  # Matte Carbon
    )

    # Minimalist Saddle Rail Clamp on Top of Seatpost
    build_saddle_cradle(bm, P_SEATPOST_TOP, material_index=1)

    # 5. CLASSIC LIGHTWEIGHT REAR TRIANGLE (Pencil-Thin Seatstays)
    # -------------------------------------------------------------------------
    # Seatstays meet DIRECTLY at the high seat cluster (P_SEAT_CLUSTER)
    p_stay_l_start = P_SEAT_CLUSTER + Vector((0.0, -0.016, -0.005))
    stay_l_path = [p_stay_l_start.lerp(P_REAR_AXLE_L, s / 6.0) for s in range(7)]
    loft_slender_tube(
        bm,
        stay_l_path,
        rx_func=lambda t: 0.007 - t * 0.002,  # 14mm tapering to 10mm pencil thin!
        ry_func=lambda t: 0.007 - t * 0.002,
        profile_type="oval",
        lateral_hint=Vector((0.0, -1.0, 0.0)),
        num_profile_pts=12,
        material_index=0,
    )

    p_stay_r_start = P_SEAT_CLUSTER + Vector((0.0, 0.016, -0.005))
    stay_r_path = [p_stay_r_start.lerp(P_REAR_AXLE_R, s / 6.0) for s in range(7)]
    loft_slender_tube(
        bm,
        stay_r_path,
        rx_func=lambda t: 0.007 - t * 0.002,  # 14mm tapering to 10mm pencil thin!
        ry_func=lambda t: 0.007 - t * 0.002,
        profile_type="oval",
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_profile_pts=12,
        material_index=0,
    )

    # 6. LIGHTWEIGHT CHAINSTAYS
    # -------------------------------------------------------------------------
    cs_l_start = P_BB + Vector((0.0, -0.034, 0.0))
    cs_l_path = [cs_l_start.lerp(P_REAR_AXLE_L, s / 5.0) for s in range(6)]
    loft_slender_tube(
        bm,
        cs_l_path,
        rx_func=lambda t: 0.013 - t * 0.004,  # 26mm tapering to 18mm
        ry_func=lambda t: 0.009 - t * 0.003,  # 18mm tapering to 12mm
        profile_type="oval",
        lateral_hint=Vector((0.0, -1.0, 0.0)),
        num_profile_pts=12,
        material_index=0,
    )

    cs_r_start = P_BB + Vector((0.0, 0.034, 0.0))
    cs_r_path = [cs_r_start.lerp(P_REAR_AXLE_R, s / 5.0) for s in range(6)]
    loft_slender_tube(
        bm,
        cs_r_path,
        rx_func=lambda t: 0.013 - t * 0.004,
        ry_func=lambda t: 0.009 - t * 0.003,
        profile_type="oval",
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_profile_pts=12,
        material_index=0,
    )

    # 7. COMPACT BB SHELL & REAR DROPOUTS
    # -------------------------------------------------------------------------
    build_climbing_bb_shell(bm, P_BB, material_index=0)

    # Rear thru-axle dropouts
    build_thru_axle_boss(bm, P_REAR_AXLE_L, is_left=True, material_index=1)
    build_thru_axle_boss(bm, P_REAR_AXLE_R, is_left=False, material_index=1)

    # Flat-mount rear disc caliper tabs on left chainstay
    build_flat_mount_tabs(
        bm,
        P_REAR_AXLE_L + Vector((0.045, 0.005, 0.012)),
        Vector((0.410, 0.0, -0.070)),
        material_index=1,
    )

    # Finalize BMesh and construct Blender Object
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)

    # Assign PBR materials matching visual style
    mat_glossy = sm.create_glossy_frame_paint_material(hex_color)
    mat_carbon = sm.create_carbon_matte_material()
    mat_metal = sm.create_metal_rotor_material()

    sm.assign_material(obj, mat_glossy, slot_index=0)
    sm.assign_material(obj, mat_carbon, slot_index=1)
    sm.assign_material(obj, mat_metal, slot_index=2)

    # Apply Zwift-style smooth shading and clean geometry
    sm.apply_zwift_style(obj, auto_smooth_angle_deg=35.0)
    sm.clean_zwift_mesh(obj)

    return obj


# =============================================================================
# SLENDER CLIMBING DISC BRAKE FORK GENERATOR
# =============================================================================

def create_climbing_fork_mesh(
    name: str = "Bike_Fork_Climbing",
    hex_color: str = "#0284C7",
) -> bpy.types.Object:
    """
    Procedurally creates a slender, lightweight climbing road disc fork:
      - Slender tapered round-oval crown
      - Straight, agile, slender fork blades (24mm down to 14mm)
      - Minimalist flat-mount disc brake tabs
      - 12x100mm lightweight thru-axle dropouts
    """
    bm = bmesh.new()

    P_CROWN = Vector((0.480, 0.000, 0.505))
    P_FRONT_AXLE_L = Vector((0.580, -0.050, 0.340))
    P_FRONT_AXLE_R = Vector((0.580, 0.050, 0.340))

    # 1. MINIMALIST SLENDER FORK CROWN
    # -------------------------------------------------------------------------
    crown_rings = []
    for h in [0.000, 0.016, 0.030]:
        c = P_CROWN + Vector((-h * 0.25, 0.0, h))
        r = 0.025 - h * 0.06
        ring = []
        for s in range(16):
            a = (s / 16.0) * 2.0 * math.pi
            pos = c + Vector((r * math.cos(a), r * math.sin(a), 0.0))
            ring.append(bm.verts.new(pos))
        crown_rings.append(ring)

    loft_rings(bm, crown_rings, cap_start=True, cap_end=True, material_index=0)

    # 2. LEFT FORK BLADE (Slender Tapered Straight Blade)
    # -------------------------------------------------------------------------
    p_blade_l_start = P_CROWN + Vector((0.005, -0.022, 0.005))
    blade_l_path = [p_blade_l_start.lerp(P_FRONT_AXLE_L, s / 6.0) for s in range(7)]

    loft_slender_tube(
        bm,
        blade_l_path,
        rx_func=lambda t: 0.014 - t * 0.005,  # 28mm tapering to 18mm
        ry_func=lambda t: 0.010 - t * 0.003,  # 20mm tapering to 14mm
        profile_type="oval",
        lateral_hint=Vector((0.0, -1.0, 0.0)),
        num_profile_pts=14,
        material_index=0,
    )

    # Flat-mount disc caliper bosses on left blade
    build_flat_mount_tabs(
        bm,
        P_FRONT_AXLE_L + Vector((-0.032, -0.003, 0.042)),
        Vector((-0.100, 0.0, 0.165)),
        material_index=1,
    )

    # 3. RIGHT FORK BLADE
    # -------------------------------------------------------------------------
    p_blade_r_start = P_CROWN + Vector((0.005, 0.022, 0.005))
    blade_r_path = [p_blade_r_start.lerp(P_FRONT_AXLE_R, s / 6.0) for s in range(7)]

    loft_slender_tube(
        bm,
        blade_r_path,
        rx_func=lambda t: 0.014 - t * 0.005,
        ry_func=lambda t: 0.010 - t * 0.003,
        profile_type="oval",
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_profile_pts=14,
        material_index=0,
    )

    # 4. FRONT 12x100mm THRU-AXLE DROPOUTS
    # -------------------------------------------------------------------------
    build_thru_axle_boss(bm, P_FRONT_AXLE_L, is_left=True, material_index=1)
    build_thru_axle_boss(bm, P_FRONT_AXLE_R, is_left=False, material_index=1)

    # Finalize BMesh and construct Blender Object
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)

    # Material Slot Setup
    mat_glossy = sm.create_glossy_frame_paint_material(hex_color)
    mat_carbon = sm.create_carbon_matte_material()
    mat_metal = sm.create_metal_rotor_material()

    sm.assign_material(obj, mat_glossy, slot_index=0)
    sm.assign_material(obj, mat_carbon, slot_index=1)
    sm.assign_material(obj, mat_metal, slot_index=2)

    # Apply Zwift-style smooth shading and clean geometry
    sm.apply_zwift_style(obj, auto_smooth_angle_deg=35.0)
    sm.clean_zwift_mesh(obj)

    return obj


# =============================================================================
# ASSEMBLY & GLTF EXPORT PIPELINE
# =============================================================================

def assemble_climbing_bicycle_frame(
    hex_color: str = "#0284C7",
    output_glb_path: str = "assets/3d/bikes/frame_climbing.glb",
    join_components: bool = True,
) -> Tuple[bpy.types.Object, str]:
    """
    Builds the complete ultra-lightweight climbing road bicycle frame set (frame + fork),
    assigns PBR materials, applies transformations, and exports to .glb.
    """
    # Clear existing mesh objects from scene
    for obj in [o for o in bpy.context.scene.objects if o.type == "MESH"]:
        bpy.data.objects.remove(obj, do_unlink=True)

    print(f"[CLIMBING_FRAME] Generating ultra-lightweight climbing frame in '{hex_color}'...")
    frame_obj = create_climbing_frame_mesh("Bike_Frame_Climbing", hex_color=hex_color)
    fork_obj = create_climbing_fork_mesh("Bike_Fork_Climbing", hex_color=hex_color)

    if join_components:
        context = bpy.context
        context.view_layer.objects.active = frame_obj
        fork_obj.select_set(True)
        frame_obj.select_set(True)
        bpy.ops.object.join()
        main_obj = frame_obj
        main_obj.name = "Bike_Climbing_Frameset"
    else:
        fork_obj.parent = frame_obj
        main_obj = frame_obj

    # Select target object for export
    bpy.ops.object.select_all(action="DESELECT")
    main_obj.select_set(True)
    bpy.context.view_layer.objects.active = main_obj

    # Ensure output directory exists
    abs_output_path = os.path.abspath(output_glb_path)
    os.makedirs(os.path.dirname(abs_output_path), exist_ok=True)

    print(f"[CLIMBING_FRAME] Exporting binary glTF model to '{abs_output_path}'...")
    export_kwargs = {
        "filepath": abs_output_path,
        "export_format": "GLB",
        "use_selection": True,
        "export_apply": True,
        "export_materials": "EXPORT",
    }

    rna_props = {p.identifier for p in bpy.ops.export_scene.gltf.get_rna_type().properties}
    if "export_normals" in rna_props:
        export_kwargs["export_normals"] = True

    bpy.ops.export_scene.gltf(**export_kwargs)

    if not os.path.exists(abs_output_path):
        raise RuntimeError(f"Failed to export glTF: file not found at '{abs_output_path}'")

    file_size_kb = os.path.getsize(abs_output_path) / 1024.0
    print(f"[CLIMBING_FRAME] Export successful! File size: {file_size_kb:.1f} KB")

    return main_obj, abs_output_path


# =============================================================================
# CLI EXECUTION ENTRY POINT
# =============================================================================

if __name__ == "__main__":
    print("\n" + "=" * 75)
    print("PRO PELOTON MANAGER: PROCEDURAL CLIMBING ROAD BICYCLE FRAME BUILDER")
    print("=" * 75)
    print(f"Blender Version: {bpy.app.version_string}")

    # Parse optional CLI hex color or default to #0284C7 (Alpine Sky Blue)
    color = "#0284C7"
    for idx, arg in enumerate(sys.argv):
        if arg in ["--color", "-c"] and idx + 1 < len(sys.argv):
            color = sys.argv[idx + 1]

    output_path = "assets/3d/bikes/frame_climbing.glb"
    for idx, arg in enumerate(sys.argv):
        if arg in ["--output", "-o"] and idx + 1 < len(sys.argv):
            output_path = sys.argv[idx + 1]

    frame_asset, glb_file = assemble_climbing_bicycle_frame(
        hex_color=color, output_glb_path=output_path
    )

    # Set up studio lighting for live viewing if Blender GUI is open
    sm.setup_zwift_studio_lighting()

    print("\n[OK] Climbing frame generated and exported successfully:")
    print(f"     - Model Object : '{frame_asset.name}'")
    print(f"     - Vertex Count : {len(frame_asset.data.vertices)}")
    print(f"     - Polygon Count: {len(frame_asset.data.polygons)}")
    print(f"     - Material Slots: {[m.name for m in frame_asset.data.materials]}")
    print(f"     - Exported GLB : '{glb_file}'")
    print("=" * 75 + "\n")

