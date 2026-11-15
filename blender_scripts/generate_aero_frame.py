"""
===============================================================================
PRO PELOTON MANAGER - PROCEDURAL AERO ROAD BICYCLE FRAME GENERATOR
===============================================================================
Blender Python API (bpy) script that procedurally models a modern high-performance
aerodynamic road racing bicycle frame (inspired by Canyon Aeroad CFR, Specialized
S-Works Tarmac SL8 / Venge, Pinarello Dogma F, Cervelo S5).

Key Aero Engineering Features:
  1. Truncated Airfoil (Kammtail) Down Tube: massive 75-85mm deep aero profile
     optimizing laminar airflow and shielding water bottles and BB shell.
  2. Dropped Seatstays: seatstays junction lowered ~100mm down the seat tube,
     reducing frontal drag area and stiffening the rear power triangle.
  3. Integrated Aero Seatpost & Wheel Cutout: D-shaped aero profile with a sculpted
     rear wheel cutout closely wrapping around the 700c wheel circumference.
  4. Aerodynamic Disc Brake Fork: Kammtail bladed legs, flat-mount disc brake
     caliper mounting bosses, and 12x100mm thru-axle dropouts.
  5. Asymmetric Aero Chainstays & Oversized BB86/T47 Bottom Bracket Shell.
  6. Material Assignment: PBR materials from `style_and_materials.py`
     (High-Gloss Frame Paint, Carbon Matte, Metal Inserts).
  7. Export to GLB format at `assets/3d/bikes/frame_aero.glb`.

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
    print("        blender --background --python blender_scripts/generate_aero_frame.py")
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
# 2D AERODYNAMIC PROFILE GENERATORS (KAMMTAIL, D-SHAPE, AERO OVAL)
# =============================================================================

def generate_kammtail_2d_points(
    chord: float,
    width: float,
    truncation_factor: float = 0.72,
    num_points: int = 16,
) -> List[Vector]:
    """
    Generates a 2D Kammtail (truncated teardrop airfoil) closed polygon in the XY plane.
    Leading edge (rounded nose) points toward (+X), flat cut-off trailing edge at (-X).
    """
    half_c = chord * 0.5
    half_w = width * 0.5
    x_nose_center = half_c - half_w
    x_rear = -half_c
    rear_width = half_w * (1.0 - truncation_factor * 0.75)

    pts = []
    # 1. Top rear cut-off corner
    pts.append(Vector((x_rear, rear_width, 0.0)))

    # 2. Upper flank curving toward nose
    n_flank = max(2, num_points // 4)
    for i in range(1, n_flank):
        t = i / float(n_flank)
        x = x_rear + t * (x_nose_center - x_rear)
        # Sine ease for aerodynamic curvature
        y = rear_width + (half_w - rear_width) * math.sin(t * math.pi * 0.5)
        pts.append(Vector((x, y, 0.0)))

    # 3. Leading edge nose semicircle
    n_nose = max(4, num_points // 2)
    for i in range(n_nose + 1):
        angle = math.pi * 0.5 - (i / float(n_nose)) * math.pi
        x = x_nose_center + half_w * math.cos(angle)
        y = half_w * math.sin(angle)
        pts.append(Vector((x, y, 0.0)))

    # 4. Lower flank curving toward rear
    for i in range(1, n_flank):
        t = i / float(n_flank)
        x = x_nose_center - t * (x_nose_center - x_rear)
        y = -(half_w - (half_w - rear_width) * (1.0 - math.cos(t * math.pi * 0.5)))
        pts.append(Vector((x, y, 0.0)))

    # 5. Bottom rear cut-off corner
    pts.append(Vector((x_rear, -rear_width, 0.0)))
    return pts


def generate_d_shape_2d_points(
    chord: float,
    width: float,
    num_points: int = 16,
) -> List[Vector]:
    """
    Generates a 2D D-shaped aerodynamic profile for seat tubes and integrated seatposts.
    Curved front facing (+X) to slice the wind, flat/concave aerodynamic back facing (-X).
    """
    half_c = chord * 0.5
    half_w = width * 0.5
    x_nose = half_c - half_w
    x_rear = -half_c

    pts = []
    # Rear flat edge
    pts.append(Vector((x_rear, half_w * 0.85, 0.0)))

    # Semicircular front nose
    n_nose = max(6, num_points // 2)
    for i in range(n_nose + 1):
        angle = math.pi * 0.5 - (i / float(n_nose)) * math.pi
        x = x_nose + half_w * math.cos(angle)
        y = half_w * math.sin(angle)
        pts.append(Vector((x, y, 0.0)))

    # Rear bottom edge
    pts.append(Vector((x_rear, -half_w * 0.85, 0.0)))
    return pts


def generate_aero_oval_2d_points(
    chord: float,
    width: float,
    num_points: int = 16,
) -> List[Vector]:
    """
    Generates a streamlined aerodynamic ellipse/oval profile for stays and fork blades.
    """
    pts = []
    half_c = chord * 0.5
    half_w = width * 0.5
    for i in range(num_points):
        angle = (i / float(num_points)) * 2.0 * math.pi
        x = half_c * math.cos(angle)
        y = half_w * math.sin(angle)
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
                pass  # Avoid duplicate face creation if vertices coincide

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


def loft_tube_along_path(
    bm: bmesh.types.BMesh,
    path_points: List[Vector],
    chord_func: Union[float, Callable[[float], float]],
    width_func: Union[float, Callable[[float], float]],
    profile_type: str = "kammtail",
    nose_forward: bool = True,
    lateral_hint: Vector = Vector((0.0, 1.0, 0.0)),
    num_profile_pts: int = 16,
    cap_start: bool = True,
    cap_end: bool = True,
    material_index: int = 0,
) -> List[List[bmesh.types.BMVert]]:
    """
    Lofts a procedural aerodynamic tube along a polyline 3D guide path.
    Calculates dynamic Frenet-Serret/Bishop reference frames to prevent twisting.
    """
    n_steps = len(path_points)
    if n_steps < 2:
        return []

    rings = []
    for s_idx, center in enumerate(path_points):
        t = s_idx / float(n_steps - 1)

        # Tangent vector calculation
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

        # Chord normal vector
        N = T.cross(B).normalized()
        if nose_forward and N.x < 0.0:
            N = -N
            B = -B  # maintain right-handed system

        # Calculate local tube dimensions
        cur_chord = chord_func(t) if callable(chord_func) else chord_func
        cur_width = width_func(t) if callable(width_func) else width_func

        # Generate 2D cross-section
        if profile_type == "kammtail":
            pts_2d = generate_kammtail_2d_points(cur_chord, cur_width, num_points=num_profile_pts)
        elif profile_type == "d_shape":
            pts_2d = generate_d_shape_2d_points(cur_chord, cur_width, num_points=num_profile_pts)
        elif profile_type == "aero_oval":
            pts_2d = generate_aero_oval_2d_points(cur_chord, cur_width, num_points=num_profile_pts)
        else:
            pts_2d = generate_kammtail_2d_points(cur_chord, cur_width, num_points=num_profile_pts)

        # Transform 2D profile into 3D world coordinates
        ring_verts = []
        for p in pts_2d:
            v_world = center + p.x * N + p.y * B
            ring_verts.append(bm.verts.new(v_world))
        rings.append(ring_verts)

    loft_rings(bm, rings, cap_start=cap_start, cap_end=cap_end, material_index=material_index)
    return rings


# =============================================================================
# PROCEDURAL COMPONENT BUILDERS (FRAME TRIANGLE, FORK, STAYS, DROPOUTS)
# =============================================================================

def build_headtube(
    bm: bmesh.types.BMesh,
    p_bottom: Vector,
    p_top: Vector,
    num_steps: int = 8,
    segments: int = 20,
    material_index: int = 0,
) -> None:
    """
    Constructs an aerodynamic tapered hourglass head tube (1-1/2" lower to 1-1/8" upper).
    """
    rings = []
    for i in range(num_steps + 1):
        t = i / float(num_steps)
        center = p_bottom.lerp(p_top, t)
        axis = (p_top - p_bottom).normalized()

        # Hourglass radius profile: wider at top and bottom bearing seats, slender waist
        if t < 0.15:
            r = 0.028  # 56mm lower crown race for 1.5" bearing
        elif t > 0.85:
            r = 0.024  # 48mm upper headset race for 1.125" bearing
        else:
            waist_t = (t - 0.15) / 0.70
            r = 0.024 + (0.028 - 0.024) * (1.0 - math.sin(waist_t * math.pi))

        # Local coordinate frame
        lat = Vector((0.0, 1.0, 0.0))
        n = axis.cross(lat).normalized()

        ring = []
        for seg in range(segments):
            angle = (seg / float(segments)) * 2.0 * math.pi
            # Slight aerodynamic elongation forward
            aero_mult = 1.15 if math.cos(angle) > 0.0 else 1.0
            x_offset = r * math.cos(angle) * aero_mult
            y_offset = r * math.sin(angle)
            pos = center + x_offset * n + y_offset * lat
            ring.append(bm.verts.new(pos))
        rings.append(ring)

    loft_rings(bm, rings, cap_start=True, cap_end=True, material_index=material_index)


def build_bb_shell(
    bm: bmesh.types.BMesh,
    center: Vector,
    width: float = 0.0865,
    radius: float = 0.026,
    segments: int = 20,
    material_index: int = 0,
) -> None:
    """
    Constructs an oversized BB86 / T47 cylindrical bottom bracket shell.
    """
    half_w = width * 0.5
    rings = []
    for step in [-half_w, -half_w * 0.5, 0.0, half_w * 0.5, half_w]:
        ring = []
        c = center + Vector((0.0, step, 0.0))
        for seg in range(segments):
            angle = (seg / float(segments)) * 2.0 * math.pi
            pos = c + Vector((radius * math.cos(angle), 0.0, radius * math.sin(angle)))
            ring.append(bm.verts.new(pos))
        rings.append(ring)

    loft_rings(bm, rings, cap_start=True, cap_end=True, material_index=material_index)


def build_thru_axle_boss(
    bm: bmesh.types.BMesh,
    position: Vector,
    is_front: bool = False,
    is_left: bool = True,
    material_index: int = 1,
) -> None:
    """
    Constructs 12mm thru-axle dropout bosses and hardware inserts.
    """
    axle_radius = 0.012  # outer boss radius 24mm
    boss_width = 0.016
    segments = 14

    y_dir = -1.0 if is_left else 1.0
    p1 = position
    p2 = position + Vector((0.0, y_dir * boss_width, 0.0))

    rings = []
    for p in [p1, p2]:
        ring = []
        for s in range(segments):
            angle = (s / float(segments)) * 2.0 * math.pi
            pos = p + Vector((axle_radius * math.cos(angle), 0.0, axle_radius * math.sin(angle)))
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
    Constructs flat-mount road disc brake caliper mounting tabs (34mm spacing).
    """
    dir_norm = direction.normalized()
    lat = Vector((0.0, -1.0, 0.0))

    # Two threaded cylindrical bosses at 34mm spacing
    for offset in [-0.017, 0.017]:
        boss_center = base_pos + dir_norm * offset + lat * 0.008
        rings = []
        for h in [0.0, 0.012]:
            ring = []
            c = boss_center + Vector((0.0, 0.0, h))
            for s in range(10):
                a = (s / 10.0) * 2.0 * math.pi
                pos = c + Vector((0.0055 * math.cos(a), 0.0055 * math.sin(a), 0.0))
                ring.append(bm.verts.new(pos))
            rings.append(ring)
        loft_rings(bm, rings, cap_start=True, cap_end=True, material_index=material_index)


def build_saddle_clamp(
    bm: bmesh.types.BMesh,
    clamp_top: Vector,
    material_index: int = 1,
) -> None:
    """
    Constructs the integrated aerodynamic seatpost saddle clamp cradle hardware.
    """
    # Carbon cradle block
    c_pts = [
        Vector((-0.035, -0.022, 0.0)),
        Vector((0.035, -0.022, 0.0)),
        Vector((0.035, 0.022, 0.0)),
        Vector((-0.035, 0.022, 0.0)),
    ]
    ring_bottom = [bm.verts.new(clamp_top + p) for p in c_pts]
    ring_top = [bm.verts.new(clamp_top + p + Vector((0.0, 0.0, 0.016))) for p in c_pts]
    loft_rings(bm, [ring_bottom, ring_top], cap_start=True, cap_end=True, material_index=material_index)

    # 7x9mm carbon saddle rail channels (left and right)
    for y_rail in [-0.022, 0.022]:
        p_start = clamp_top + Vector((-0.032, y_rail, 0.016))
        p_end = clamp_top + Vector((0.032, y_rail, 0.016))
        r1 = [
            bm.verts.new(p_start + Vector((0.0, -0.004, 0.0))),
            bm.verts.new(p_start + Vector((0.0, 0.004, 0.0))),
            bm.verts.new(p_start + Vector((0.0, 0.004, 0.008))),
            bm.verts.new(p_start + Vector((0.0, -0.004, 0.008))),
        ]
        r2 = [
            bm.verts.new(p_end + Vector((0.0, -0.004, 0.0))),
            bm.verts.new(p_end + Vector((0.0, 0.004, 0.0))),
            bm.verts.new(p_end + Vector((0.0, 0.004, 0.008))),
            bm.verts.new(p_end + Vector((0.0, -0.004, 0.008))),
        ]
        loft_rings(bm, [r1, r2], cap_start=True, cap_end=True, material_index=material_index)


# =============================================================================
# MAIN PROCEDURAL AERO FRAME GENERATOR
# =============================================================================

def create_aero_frame_mesh(
    name: str = "Bike_Frame_Aero",
    hex_color: str = "#E10600",
) -> bpy.types.Object:
    """
    Procedurally creates the complete aerodynamic road bicycle frame:
      - Deep Kammtail Down Tube (78mm chord)
      - Aero Top Tube
      - Tapered Hourglass Head Tube
      - Seat Tube with Rear Wheel Cutout & Integrated Aero Seatpost
      - Dropped Aero Seatstays (~100mm drop) with Wishbone
      - Asymmetric Box-Section Chainstays
      - Oversized BB Shell & Rear Thru-Axle Dropouts with Flat-Mount Brake Tabs
    """
    bm = bmesh.new()

    # Key Geometry Reference Points (Meters)
    P_BB = Vector((0.000, 0.000, 0.270))
    P_HT_BOTTOM = Vector((0.485, 0.000, 0.505))
    P_HT_TOP = Vector((0.445, 0.000, 0.655))
    P_SEAT_CLUSTER = Vector((-0.165, 0.000, 0.760))
    P_DROPPED_STAYS = Vector((-0.138, 0.000, 0.660))  # ~100mm dropped junction!
    P_SEATPOST_TOP = Vector((-0.205, 0.000, 0.900))
    P_REAR_AXLE_L = Vector((-0.415, -0.071, 0.340))
    P_REAR_AXLE_R = Vector((-0.415, 0.071, 0.340))

    # 1. DOWN TUBE (Massive Kammtail Profile)
    # -------------------------------------------------------------------------
    # Path with 8 steps tapering from Head Tube to BB
    dt_path = []
    for s in range(8):
        t = s / 7.0
        # Subtle aero curvature transitioning into bottom bracket shell
        pt = P_HT_BOTTOM.lerp(P_BB, t)
        if 0.15 < t < 0.85:
            pt += Vector((-0.008, 0.0, -0.006)) * math.sin(t * math.pi)
        dt_path.append(pt)

    loft_tube_along_path(
        bm,
        dt_path,
        chord_func=lambda t: 0.065 + t * 0.017,  # 65mm at top to 82mm at BB
        width_func=lambda t: 0.038 + t * 0.016,  # 38mm at top to 54mm at BB
        profile_type="kammtail",
        nose_forward=True,
        num_profile_pts=16,
        material_index=0,
    )

    # 2. TOP TUBE (Horizontal / Sloping Kammtail Profile)
    # -------------------------------------------------------------------------
    tt_path = [P_HT_TOP.lerp(P_SEAT_CLUSTER, s / 6.0) for s in range(7)]
    loft_tube_along_path(
        bm,
        tt_path,
        chord_func=lambda t: 0.046 - t * 0.012,  # 46mm at front to 34mm at seat cluster
        width_func=lambda t: 0.038 - t * 0.010,  # 38mm to 28mm
        profile_type="kammtail",
        nose_forward=False,  # nose points upward/forward
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_profile_pts=16,
        material_index=0,
    )

    # 3. HEAD TUBE (Tapered Hourglass Aero Cylinder)
    # -------------------------------------------------------------------------
    build_headtube(bm, P_HT_BOTTOM, P_HT_TOP, material_index=0)

    # 4. SEAT TUBE & INTEGRATED SEATPOST (D-Shape with Rear Wheel Cutout)
    # -------------------------------------------------------------------------
    st_path = [
        P_BB,
        Vector((-0.045, 0.000, 0.350)),  # wheel cutout starts
        Vector((-0.088, 0.000, 0.450)),  # wheel cutout apex
        Vector((-0.120, 0.000, 0.550)),
        P_DROPPED_STAYS,                 # dropped seatstay junction (Z=0.660)
        P_SEAT_CLUSTER,                  # top tube junction (Z=0.760)
        Vector((-0.185, 0.000, 0.830)),  # integrated seatpost mid
        P_SEATPOST_TOP,                  # saddle clamp height (Z=0.900)
    ]

    loft_tube_along_path(
        bm,
        st_path,
        chord_func=lambda t: 0.055 - t * 0.010,
        width_func=lambda t: 0.034 - t * 0.006,
        profile_type="d_shape",
        nose_forward=True,
        num_profile_pts=16,
        material_index=0,
    )

    # Saddle clamp hardware on top of integrated seatpost
    build_saddle_clamp(bm, P_SEATPOST_TOP, material_index=1)

    # 5. DROPPED SEATSTAYS (Aero Bladed Stays with Wishbone Transition)
    # -------------------------------------------------------------------------
    p_wishbone_end = P_DROPPED_STAYS + Vector((-0.045, 0.0, -0.040))

    # Central wishbone neck
    wishbone_path = [P_DROPPED_STAYS, p_wishbone_end]
    loft_tube_along_path(
        bm,
        wishbone_path,
        chord_func=0.034,
        width_func=0.028,
        profile_type="kammtail",
        nose_forward=True,
        material_index=0,
    )

    # Left Dropped Seatstay
    p_stay_l_start = p_wishbone_end + Vector((0.0, -0.018, 0.0))
    stay_l_path = [p_stay_l_start.lerp(P_REAR_AXLE_L, s / 6.0) for s in range(7)]
    loft_tube_along_path(
        bm,
        stay_l_path,
        chord_func=lambda t: 0.028 - t * 0.008,
        width_func=lambda t: 0.014 - t * 0.003,
        profile_type="aero_oval",
        nose_forward=True,
        lateral_hint=Vector((0.0, -1.0, 0.0)),
        num_profile_pts=14,
        material_index=0,
    )

    # Right Dropped Seatstay
    p_stay_r_start = p_wishbone_end + Vector((0.0, 0.018, 0.0))
    stay_r_path = [p_stay_r_start.lerp(P_REAR_AXLE_R, s / 6.0) for s in range(7)]
    loft_tube_along_path(
        bm,
        stay_r_path,
        chord_func=lambda t: 0.028 - t * 0.008,
        width_func=lambda t: 0.014 - t * 0.003,
        profile_type="aero_oval",
        nose_forward=True,
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_profile_pts=14,
        material_index=0,
    )

    # 6. ASYMMETRIC AERO CHAINSTAYS (Sprint Rigidity)
    # -------------------------------------------------------------------------
    # Left Chainstay (Non-Drive Side with Flat-Mount brake mounting)
    cs_l_start = P_BB + Vector((0.0, -0.038, 0.0))
    cs_l_path = [cs_l_start.lerp(P_REAR_AXLE_L, s / 6.0) for s in range(7)]
    loft_tube_along_path(
        bm,
        cs_l_path,
        chord_func=lambda t: 0.032 - t * 0.008,
        width_func=lambda t: 0.020 - t * 0.004,
        profile_type="aero_oval",
        nose_forward=True,
        lateral_hint=Vector((0.0, -1.0, 0.0)),
        num_profile_pts=14,
        material_index=0,
    )

    # Right Chainstay (Dropped drive-side stay for 54/40T chainring clearance)
    cs_r_start = P_BB + Vector((0.0, 0.038, 0.0))
    cs_r_path = [
        cs_r_start,
        cs_r_start + Vector((-0.070, 0.005, -0.012)),  # dropped section
        cs_r_start + Vector((-0.160, 0.012, -0.006)),
        cs_r_start.lerp(P_REAR_AXLE_R, 0.65),
        P_REAR_AXLE_R,
    ]
    loft_tube_along_path(
        bm,
        cs_r_path,
        chord_func=lambda t: 0.032 - t * 0.008,
        width_func=lambda t: 0.020 - t * 0.004,
        profile_type="aero_oval",
        nose_forward=True,
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_profile_pts=14,
        material_index=0,
    )

    # 7. BOTTOM BRACKET SHELL & DROPOUTS HARDWARE
    # -------------------------------------------------------------------------
    build_bb_shell(bm, P_BB, material_index=0)

    # Rear thru-axle bosses
    build_thru_axle_boss(bm, P_REAR_AXLE_L, is_front=False, is_left=True, material_index=1)
    build_thru_axle_boss(bm, P_REAR_AXLE_R, is_front=False, is_left=False, material_index=1)

    # Flat-mount rear disc caliper tabs on left chainstay
    build_flat_mount_tabs(
        bm,
        P_REAR_AXLE_L + Vector((0.050, 0.006, 0.015)),
        Vector((0.415, 0.0, -0.070)),
        material_index=1,
    )

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
# FRONT AERO DISC BRAKE FORK GENERATOR
# =============================================================================

def create_aero_fork_mesh(
    name: str = "Bike_Fork_Aero",
    hex_color: str = "#E10600",
) -> bpy.types.Object:
    """
    Procedurally creates the aerodynamic road disc brake fork:
      - Integrated aero fork crown fitting cleanly into the headtube/downtube junction
      - Bladed Kammtail fork legs slicing oncoming air
      - Flat-mount disc brake tabs on the left blade (140/160mm caliper)
      - 12x100mm thru-axle dropouts
    """
    bm = bmesh.new()

    P_CROWN = Vector((0.485, 0.000, 0.505))
    P_FRONT_AXLE_L = Vector((0.585, -0.050, 0.340))
    P_FRONT_AXLE_R = Vector((0.585, 0.050, 0.340))

    # 1. INTEGRATED AERO FORK CROWN
    # -------------------------------------------------------------------------
    crown_rings = []
    for h in [0.000, 0.018, 0.035]:
        ring = []
        c = P_CROWN + Vector((-h * 0.28, 0.0, h))
        r_outer = 0.029 - h * 0.08
        for s in range(16):
            a = (s / 16.0) * 2.0 * math.pi
            # Kammtail aero elongation forward
            aero_scale = 1.25 if math.cos(a) > 0.0 else 0.95
            pos = c + Vector((r_outer * math.cos(a) * aero_scale, r_outer * math.sin(a), 0.0))
            ring.append(bm.verts.new(pos))
        crown_rings.append(ring)

    loft_rings(bm, crown_rings, cap_start=True, cap_end=True, material_index=0)

    # 2. LEFT FORK BLADE (Bladed Kammtail with Flat-Mount Disc Bosses)
    # -------------------------------------------------------------------------
    p_blade_l_start = P_CROWN + Vector((0.008, -0.025, 0.005))
    blade_l_path = [p_blade_l_start.lerp(P_FRONT_AXLE_L, s / 6.0) for s in range(7)]

    loft_tube_along_path(
        bm,
        blade_l_path,
        chord_func=lambda t: 0.040 - t * 0.014,  # 40mm at crown to 26mm at axle
        width_func=lambda t: 0.018 - t * 0.005,  # 18mm to 13mm
        profile_type="kammtail",
        nose_forward=True,
        lateral_hint=Vector((0.0, -1.0, 0.0)),
        num_profile_pts=16,
        material_index=0,
    )

    # Flat-mount disc caliper bosses on left blade (non-drive side)
    build_flat_mount_tabs(
        bm,
        P_FRONT_AXLE_L + Vector((-0.035, -0.004, 0.045)),
        Vector((-0.100, 0.0, 0.165)),
        material_index=1,
    )

    # 3. RIGHT FORK BLADE
    # -------------------------------------------------------------------------
    p_blade_r_start = P_CROWN + Vector((0.008, 0.025, 0.005))
    blade_r_path = [p_blade_r_start.lerp(P_FRONT_AXLE_R, s / 6.0) for s in range(7)]

    loft_tube_along_path(
        bm,
        blade_r_path,
        chord_func=lambda t: 0.040 - t * 0.014,
        width_func=lambda t: 0.018 - t * 0.005,
        profile_type="kammtail",
        nose_forward=True,
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_profile_pts=16,
        material_index=0,
    )

    # 4. FRONT 12x100mm THRU-AXLE DROPOUTS
    # -------------------------------------------------------------------------
    build_thru_axle_boss(bm, P_FRONT_AXLE_L, is_front=True, is_left=True, material_index=1)
    build_thru_axle_boss(bm, P_FRONT_AXLE_R, is_front=True, is_left=False, material_index=1)

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

def assemble_aero_bicycle_frame(
    hex_color: str = "#E10600",
    output_glb_path: str = "assets/3d/bikes/frame_aero.glb",
    join_components: bool = True,
) -> Tuple[bpy.types.Object, str]:
    """
    Builds the complete aerodynamic road bicycle frame set (frame + fork),
    assigns PBR materials, applies transformations, and exports to .glb.
    """
    # Clear existing mesh objects from scene
    for obj in [o for o in bpy.context.scene.objects if o.type == "MESH"]:
        bpy.data.objects.remove(obj, do_unlink=True)

    print(f"[AERO_FRAME] Generating modern road aerodynamic frame in '{hex_color}'...")
    frame_obj = create_aero_frame_mesh("Bike_Frame_Aero", hex_color=hex_color)
    fork_obj = create_aero_fork_mesh("Bike_Fork_Aero", hex_color=hex_color)

    if join_components:
        # Join into single unified bike frame asset
        context = bpy.context
        context.view_layer.objects.active = frame_obj
        fork_obj.select_set(True)
        frame_obj.select_set(True)
        bpy.ops.object.join()
        main_obj = frame_obj
        main_obj.name = "Bike_Aero_Frameset"
    else:
        # Parent fork to frame
        fork_obj.parent = frame_obj
        main_obj = frame_obj

    # Select target object for export
    bpy.ops.object.select_all(action="DESELECT")
    main_obj.select_set(True)
    bpy.context.view_layer.objects.active = main_obj

    # Ensure output directory exists
    abs_output_path = os.path.abspath(output_glb_path)
    os.makedirs(os.path.dirname(abs_output_path), exist_ok=True)

    print(f"[AERO_FRAME] Exporting binary glTF model to '{abs_output_path}'...")
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
    print(f"[AERO_FRAME] Export successful! File size: {file_size_kb:.1f} KB")

    return main_obj, abs_output_path


# =============================================================================
# CLI EXECUTION ENTRY POINT
# =============================================================================

if __name__ == "__main__":
    print("\n" + "=" * 75)
    print("PRO PELOTON MANAGER: PROCEDURAL AERO ROAD BICYCLE FRAME BUILDER")
    print("=" * 75)
    print(f"Blender Version: {bpy.app.version_string}")

    # Parse optional CLI hex color or default to #E10600 (Racing Red)
    color = "#E10600"
    for idx, arg in enumerate(sys.argv):
        if arg in ["--color", "-c"] and idx + 1 < len(sys.argv):
            color = sys.argv[idx + 1]

    output_path = "assets/3d/bikes/frame_aero.glb"
    for idx, arg in enumerate(sys.argv):
        if arg in ["--output", "-o"] and idx + 1 < len(sys.argv):
            output_path = sys.argv[idx + 1]

    frame_asset, glb_file = assemble_aero_bicycle_frame(
        hex_color=color, output_glb_path=output_path
    )

    # Set up studio lighting for live viewing if Blender GUI is open
    sm.setup_zwift_studio_lighting()

    print("\n[OK] Aero frame generated and exported successfully:")
    print(f"     - Model Object : '{frame_asset.name}'")
    print(f"     - Vertex Count : {len(frame_asset.data.vertices)}")
    print(f"     - Polygon Count: {len(frame_asset.data.polygons)}")
    print(f"     - Material Slots: {[m.name for m in frame_asset.data.materials]}")
    print(f"     - Exported GLB : '{glb_file}'")
    print("=" * 75 + "\n")
