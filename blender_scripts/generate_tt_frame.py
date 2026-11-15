"""
===============================================================================
PRO PELOTON MANAGER - PROCEDURAL TIME TRIAL (TT) BICYCLE FRAME GENERATOR
===============================================================================
Blender Python API (bpy) script that procedurally models an extreme aerodynamic
Time Trial / Chrono racing bicycle frameset (inspired by Pinarello Bolide F TT,
Canyon Speedmax CFR TT, Cervelo P5, Specialized S-Works Shiv TT, Colnago TT1).

Key TT Engineering Features:
  1. Ultra-Deep Head Tube & Integrated Nose Cone: extended 110-120mm chord aero
     fairing seamlessly integrating stem, fork crown, and front triangle.
  2. Rear Wheel Cutout Shroud: aggressive aerodynamic concave curve hugging the 700c
     rear wheel circumference with minimal clearance (~8mm) for turbulent air shielding.
  3. Fully Integrated Aero Cockpit:
     - Flat aero wing basebar with forward-swept brake horn grips.
     - Dual vertical aerobar riser towers.
     - Ergonomic curved elbow armrest cups with cushioning pads.
     - Dual ski-bend / J-bend aero extensions (lemondka) with electronic shifter tips.
  4. Steep TT Seat Angle & Deep Aero Seatpost: aggressive forward aerodynamic tuck geometry.
  5. Dropped Horizontal TT Seatstays & Oversized BB Junction.
  6. Deep Bladed TT Disc Fork with Flat-Mount brake tabs.
  7. Material Assignment: PBR materials from `style_and_materials.py`
     (High-Gloss Frame Paint, Carbon Matte, Metal Inserts).
  8. Export to GLB format at `assets/3d/bikes/frame_tt.glb`.

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
    print("        blender --background --python blender_scripts/generate_tt_frame.py")
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
# 2D TIME TRIAL AERODYNAMIC PROFILE GENERATORS
# =============================================================================

def generate_deep_tt_headtube_2d_points(
    chord: float = 0.115,
    width: float = 0.046,
    num_points: int = 20,
) -> List[Vector]:
    """
    Generates a 2D ultra-deep TT head tube profile with an aerodynamic nose cone
    fairing extending forward (+X) and a truncated flat/tapered back (-X).
    """
    half_c = chord * 0.5
    half_w = width * 0.5
    x_nose = half_c - half_w
    x_rear = -half_c
    rear_w = half_w * 0.40

    pts = []
    # Rear top
    pts.append(Vector((x_rear, rear_w, 0.0)))

    # Flank to nose
    n_flank = max(3, num_points // 4)
    for i in range(1, n_flank):
        t = i / float(n_flank)
        x = x_rear + t * (x_nose - x_rear)
        y = rear_w + (half_w - rear_w) * math.sin(t * math.pi * 0.5)
        pts.append(Vector((x, y, 0.0)))

    # Leading edge nose semicircle
    n_nose = max(6, num_points // 2)
    for i in range(n_nose + 1):
        angle = math.pi * 0.5 - (i / float(n_nose)) * math.pi
        x = x_nose + half_w * math.cos(angle)
        y = half_w * math.sin(angle)
        pts.append(Vector((x, y, 0.0)))

    # Lower flank to rear bottom
    for i in range(1, n_flank):
        t = i / float(n_flank)
        x = x_nose - t * (x_nose - x_rear)
        y = -(half_w - (half_w - rear_w) * (1.0 - math.cos(t * math.pi * 0.5)))
        pts.append(Vector((x, y, 0.0)))

    # Rear bottom
    pts.append(Vector((x_rear, -rear_w, 0.0)))
    return pts


def generate_cutout_seat_tube_2d_points(
    chord: float,
    width: float,
    cutout_concavity: float = 0.012,
    num_points: int = 16,
) -> List[Vector]:
    """
    Generates a 2D TT seat tube cross-section with an aerodynamic concave curve
    on the trailing edge (-X) designed to hug the front of the rear tire.
    """
    half_c = chord * 0.5
    half_w = width * 0.5
    x_nose = half_c - half_w
    x_rear = -half_c

    pts = []
    # Rear top
    pts.append(Vector((x_rear, half_w * 0.85, 0.0)))

    # Semicircular front nose
    n_nose = max(6, num_points // 2)
    for i in range(n_nose + 1):
        angle = math.pi * 0.5 - (i / float(n_nose)) * math.pi
        x = x_nose + half_w * math.cos(angle)
        y = half_w * math.sin(angle)
        pts.append(Vector((x, y, 0.0)))

    # Rear bottom
    pts.append(Vector((x_rear, -half_w * 0.85, 0.0)))

    # Concave rear cutout point (inwards toward center)
    if cutout_concavity > 0.0:
        pts.append(Vector((x_rear + cutout_concavity, 0.0, 0.0)))

    return pts


def generate_aero_wing_2d_points(
    chord: float,
    thickness: float,
    num_points: int = 16,
) -> List[Vector]:
    """
    Generates a symmetrical NACA 0012-style aerodynamic wing profile for the basebar.
    """
    half_c = chord * 0.5
    half_t = thickness * 0.5
    pts = []
    for i in range(num_points):
        angle = (i / float(num_points)) * 2.0 * math.pi
        # Standard airfoil thickness distribution
        x = half_c * math.cos(angle)
        # Squeeze trailing edge
        t_mult = 1.0 - 0.45 * (x / half_c)
        y = half_t * math.sin(angle) * max(0.2, t_mult)
        pts.append(Vector((x, y, 0.0)))
    return pts


def generate_circle_2d_points(radius: float, num_points: int = 12) -> List[Vector]:
    """Generates a 2D circular cross-section for aerobar extension poles."""
    pts = []
    for i in range(num_points):
        angle = (i / float(num_points)) * 2.0 * math.pi
        pts.append(Vector((radius * math.cos(angle), radius * math.sin(angle), 0.0)))
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
    """Lofts consecutive rings of vertices into quad faces."""
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


def loft_tt_tube(
    bm: bmesh.types.BMesh,
    path_points: List[Vector],
    chord_func: Union[float, Callable[[float], float]],
    width_func: Union[float, Callable[[float], float]],
    profile_type: str = "kammtail",
    nose_forward: bool = True,
    lateral_hint: Vector = Vector((0.0, 1.0, 0.0)),
    cutout_depth: float = 0.012,
    num_profile_pts: int = 16,
    cap_start: bool = True,
    cap_end: bool = True,
    material_index: int = 0,
) -> List[List[bmesh.types.BMVert]]:
    """Lofts an aerodynamic TT tube along a 3D guide path."""
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

        # Normal vector perpendicular to tangent and lateral
        N = T.cross(B).normalized()
        if nose_forward and N.x < 0.0:
            N = -N
            B = -B

        cur_chord = chord_func(t) if callable(chord_func) else chord_func
        cur_width = width_func(t) if callable(width_func) else width_func

        if profile_type == "tt_headtube":
            pts_2d = generate_deep_tt_headtube_2d_points(cur_chord, cur_width, num_points=num_profile_pts)
        elif profile_type == "cutout_seat_tube":
            pts_2d = generate_cutout_seat_tube_2d_points(cur_chord, cur_width, cutout_concavity=cutout_depth, num_points=num_profile_pts)
        elif profile_type == "aero_wing":
            pts_2d = generate_aero_wing_2d_points(cur_chord, cur_width, num_points=num_profile_pts)
        elif profile_type == "circle":
            pts_2d = generate_circle_2d_points(cur_width * 0.5, num_points=num_profile_pts)
        else:
            half_c = cur_chord * 0.5
            half_w = cur_width * 0.5
            pts_2d = [
                Vector((half_c, 0.0, 0.0)),
                Vector((half_c * 0.5, half_w, 0.0)),
                Vector((-half_c, half_w * 0.5, 0.0)),
                Vector((-half_c, -half_w * 0.5, 0.0)),
                Vector((half_c * 0.5, -half_w, 0.0)),
            ]

        ring = []
        for p in pts_2d:
            v_world = center + p.x * N + p.y * B
            ring.append(bm.verts.new(v_world))
        rings.append(ring)

    loft_rings(bm, rings, cap_start=cap_start, cap_end=cap_end, material_index=material_index)
    return rings


# =============================================================================
# INTEGRATED AERO TT COCKPIT (BASEBAR, LEMONDKA, ARMRESTS)
# =============================================================================

def build_integrated_tt_cockpit(
    bm: bmesh.types.BMesh,
    p_stem: Vector,
    material_frame: int = 0,
    material_carbon: int = 1,
    material_metal: int = 2,
) -> None:
    """
    Constructs the fully integrated Time Trial cockpit:
      - Aerodynamic base bar wing spanning 400mm with forward brake horns
      - Vertical aerobar riser towers
      - Ergonomic curved elbow armrest cups with cushioning pads
      - Dual ski-bend / J-bend aero extensions (lemondka) with electronic Di2/eTap shifters
    """
    # 1. INTEGRATED STEM & BASEBAR WING
    # -------------------------------------------------------------------------
    # Basebar wing spans from Y = -0.200 to Y = +0.200 (400mm width)
    p_center = p_stem + Vector((0.025, 0.000, 0.000))
    p_wing_l = p_center + Vector((0.000, -0.165, 0.000))
    p_wing_r = p_center + Vector((0.000, 0.165, 0.000))

    # Center to Left Wing
    wing_l_path = [p_center.lerp(p_wing_l, s / 4.0) for s in range(5)]
    loft_tt_tube(
        bm,
        wing_l_path,
        chord_func=lambda t: 0.052 - t * 0.012,  # 52mm at stem tapering to 40mm at horn
        width_func=lambda t: 0.018 - t * 0.004,  # 18mm to 14mm
        profile_type="aero_wing",
        nose_forward=True,
        lateral_hint=Vector((1.0, 0.0, 0.0)),
        num_profile_pts=14,
        material_index=material_carbon,
    )

    # Center to Right Wing
    wing_r_path = [p_center.lerp(p_wing_r, s / 4.0) for s in range(5)]
    loft_tt_tube(
        bm,
        wing_r_path,
        chord_func=lambda t: 0.052 - t * 0.012,
        width_func=lambda t: 0.018 - t * 0.004,
        profile_type="aero_wing",
        nose_forward=True,
        lateral_hint=Vector((1.0, 0.0, 0.0)),
        num_profile_pts=14,
        material_index=material_carbon,
    )

    # Forward-swept brake horn grips
    p_horn_l_end = p_wing_l + Vector((0.065, -0.025, 0.008))
    p_horn_r_end = p_wing_r + Vector((0.065, 0.025, 0.008))

    horn_l_path = [p_wing_l, p_wing_l + Vector((0.035, -0.012, 0.004)), p_horn_l_end]
    loft_tt_tube(
        bm,
        horn_l_path,
        chord_func=0.032,
        width_func=0.022,
        profile_type="aero_wing",
        nose_forward=True,
        lateral_hint=Vector((0.0, 0.0, 1.0)),
        num_profile_pts=12,
        material_index=material_carbon,
    )

    horn_r_path = [p_wing_r, p_wing_r + Vector((0.035, 0.012, 0.004)), p_horn_r_end]
    loft_tt_tube(
        bm,
        horn_r_path,
        chord_func=0.032,
        width_func=0.022,
        profile_type="aero_wing",
        nose_forward=True,
        lateral_hint=Vector((0.0, 0.0, 1.0)),
        num_profile_pts=12,
        material_index=material_carbon,
    )

    # 2. VERTICAL RISER TOWERS (50mm rise)
    # -------------------------------------------------------------------------
    z_tower_base = p_center.z
    z_tower_top = z_tower_base + 0.055

    for y_pos in [-0.045, 0.045]:
        p_t_bot = Vector((p_center.x + 0.005, y_pos, z_tower_base))
        p_t_top = Vector((p_center.x + 0.005, y_pos, z_tower_top))
        tower_path = [p_t_bot, p_t_top]
        loft_tt_tube(
            bm,
            tower_path,
            chord_func=0.036,
            width_func=0.018,
            profile_type="aero_wing",
            nose_forward=True,
            lateral_hint=Vector((0.0, 1.0, 0.0)),
            num_profile_pts=12,
            material_index=material_carbon,
        )

    # 3. ERGONOMIC CURVED ELBOW ARMREST CUPS & PADS (Podłokietniki)
    # -------------------------------------------------------------------------
    pad_length = 0.130  # 130mm forearm support
    pad_width = 0.075   # 75mm cradle width
    cup_depth = 0.016   # 16mm deep ergonomic concave curvature

    for y_center in [-0.075, 0.075]:
        c_cup = Vector((p_center.x - 0.020, y_center, z_tower_top + 0.004))
        num_x = 4
        num_y = 6
        grid_verts = []

        for ix in range(num_x + 1):
            tx = ix / float(num_x)
            x_pos = c_cup.x - pad_length * 0.5 + tx * pad_length
            row = []
            for iy in range(num_y + 1):
                ty = iy / float(num_y)
                y_rel = -pad_width * 0.5 + ty * pad_width
                # Parabolic curve cradling rider's arm
                z_rel = ((y_rel / (pad_width * 0.5)) ** 2) * cup_depth
                pos = Vector((x_pos, c_cup.y + y_rel, c_cup.z + z_rel))
                row.append(bm.verts.new(pos))
            grid_verts.append(row)

        for ix in range(num_x):
            for iy in range(num_y):
                v1 = grid_verts[ix][iy]
                v2 = grid_verts[ix + 1][iy]
                v3 = grid_verts[ix + 1][iy + 1]
                v4 = grid_verts[ix][iy + 1]
                try:
                    f = bm.faces.new([v1, v2, v3, v4])
                    f.material_index = material_carbon
                except ValueError:
                    pass

    # 4. SKI-BEND / J-BEND AEROBAR EXTENSIONS (Lemondka)
    # -------------------------------------------------------------------------
    ext_radius = 0.0111  # 22.2mm standard aerobar outer diameter

    for y_ext in [-0.045, 0.045]:
        p_e1 = Vector((p_center.x - 0.060, y_ext, z_tower_top))
        p_e2 = Vector((p_center.x + 0.120, y_ext, z_tower_top))
        p_e3 = Vector((p_center.x + 0.220, y_ext, z_tower_top + 0.005))
        p_e4 = Vector((p_center.x + 0.280, y_ext, z_tower_top + 0.035))  # ski-bend rise
        p_e5 = Vector((p_center.x + 0.315, y_ext, z_tower_top + 0.065))  # tip with shifters

        ext_path = [p_e1, p_e2, p_e3, p_e4, p_e5]
        loft_tt_tube(
            bm,
            ext_path,
            chord_func=ext_radius * 2.0,
            width_func=ext_radius * 2.0,
            profile_type="circle",
            nose_forward=True,
            lateral_hint=Vector((0.0, 1.0, 0.0)),
            num_profile_pts=12,
            material_index=material_carbon,
        )

        # Di2 / eTap electronic shifter satellite button tip
        p_shifter_base = p_e5
        p_shifter_tip = p_e5 + Vector((0.015, 0.000, 0.015))
        shifter_path = [p_shifter_base, p_shifter_tip]
        loft_tt_tube(
            bm,
            shifter_path,
            chord_func=0.014,
            width_func=0.014,
            profile_type="circle",
            nose_forward=True,
            lateral_hint=Vector((0.0, 1.0, 0.0)),
            num_profile_pts=8,
            material_index=material_metal,
        )


# =============================================================================
# MAIN PROCEDURAL TT FRAME GENERATOR
# =============================================================================

def create_tt_frame_mesh(
    name: str = "Bike_Frame_TT",
    hex_color: str = "#1E293B",  # Chrono Stealth Slate
) -> bpy.types.Object:
    """
    Procedurally creates an extreme Time Trial aerodynamic bicycle frame:
      - Ultra-deep TT head tube (115mm chord) with aerodynamic nose cone fairing
      - Flat horizontal aero top tube
      - Deep Kammtail down tube (85mm chord)
      - Curved rear wheel cutout seat tube tightly wrapping the rear tire
      - Integrated aero cockpit (Basebar, Lemondka, Armrests)
      - Dropped horizontal TT seatstays and stiffened box chainstays
    """
    bm = bmesh.new()

    # Geometry Reference Points (Meters)
    P_BB = Vector((0.000, 0.000, 0.270))
    P_HT_BOTTOM = Vector((0.495, 0.000, 0.505))
    P_HT_TOP = Vector((0.465, 0.000, 0.635))
    P_STEM = Vector((0.480, 0.000, 0.640))
    P_SEAT_CLUSTER = Vector((-0.130, 0.000, 0.745))  # steep 76° TT seat angle
    P_SEATPOST_TOP = Vector((-0.155, 0.000, 0.880))
    P_REAR_AXLE = Vector((-0.405, 0.000, 0.340))
    P_REAR_AXLE_L = Vector((-0.405, -0.071, 0.340))
    P_REAR_AXLE_R = Vector((-0.405, 0.071, 0.340))

    # 1. ULTRA-DEEP TT HEAD TUBE & NOSE CONE (115mm Chord)
    # -------------------------------------------------------------------------
    ht_path = [P_HT_BOTTOM, P_HT_BOTTOM.lerp(P_HT_TOP, 0.5), P_HT_TOP]
    loft_tt_tube(
        bm,
        ht_path,
        chord_func=lambda t: 0.118 - t * 0.012,  # 118mm at bottom to 106mm at stem
        width_func=lambda t: 0.046 - t * 0.006,  # 46mm to 40mm
        profile_type="tt_headtube",
        nose_forward=True,
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_profile_pts=18,
        material_index=0,
    )

    # 2. HORIZONTAL AERO TOP TUBE
    # -------------------------------------------------------------------------
    tt_path = [P_HT_TOP.lerp(P_SEAT_CLUSTER, s / 6.0) for s in range(7)]
    loft_tt_tube(
        bm,
        tt_path,
        chord_func=lambda t: 0.052 - t * 0.014,  # 52mm front to 38mm rear
        width_func=lambda t: 0.038 - t * 0.010,  # 38mm to 28mm
        profile_type="aero_wing",
        nose_forward=False,  # nose points upward/forward
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_profile_pts=16,
        material_index=0,
    )

    # 3. MASSIVE KAMMTAIL DOWN TUBE (85mm Deep Aero Profile)
    # -------------------------------------------------------------------------
    dt_path = [P_HT_BOTTOM.lerp(P_BB, s / 6.0) for s in range(7)]
    loft_tt_tube(
        bm,
        dt_path,
        chord_func=lambda t: 0.075 + t * 0.015,  # 75mm top to 90mm at BB
        width_func=lambda t: 0.038 + t * 0.018,  # 38mm to 56mm flaring at BB
        profile_type="kammtail",
        nose_forward=True,
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_profile_pts=16,
        material_index=0,
    )

    # 4. SEAT TUBE WITH REAR WHEEL CUTOUT SHROUD & DEEP TT SEATPOST
    # -------------------------------------------------------------------------
    # Cutout curve wrapping around the 700c wheel (radius 0.348m from rear axle)
    st_path = [
        P_BB,
        Vector((-0.057, 0.000, 0.340)),  # horizontal front of tire
        Vector((-0.075, 0.000, 0.430)),  # wheel cutout arc
        Vector((-0.105, 0.000, 0.515)),
        Vector((-0.145, 0.000, 0.600)),
        P_SEAT_CLUSTER,                  # top tube junction (Z=0.745)
        P_SEATPOST_TOP,                  # TT forward saddle clamp (Z=0.880)
    ]

    loft_tt_tube(
        bm,
        st_path,
        chord_func=lambda t: 0.065 - t * 0.012,  # 65mm shroud tapering to 53mm
        width_func=lambda t: 0.034 - t * 0.006,  # 34mm to 28mm
        profile_type="cutout_seat_tube",
        nose_forward=True,
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        cutout_depth=0.014,
        num_profile_pts=16,
        material_index=0,
    )

    # TT Saddle clamp hardware
    c_pts = [
        Vector((-0.036, -0.022, 0.0)),
        Vector((0.036, -0.022, 0.0)),
        Vector((0.036, 0.022, 0.0)),
        Vector((-0.036, 0.022, 0.0)),
    ]
    r1 = [bm.verts.new(P_SEATPOST_TOP + p) for p in c_pts]
    r2 = [bm.verts.new(P_SEATPOST_TOP + p + Vector((0.0, 0.0, 0.015))) for p in c_pts]
    loft_rings(bm, [r1, r2], cap_start=True, cap_end=True, material_index=1)

    # 5. DROPPED HORIZONTAL TT SEATSTAYS (Ultra-Low Drag)
    # -------------------------------------------------------------------------
    p_tt_stay_junction = Vector((-0.130, 0.000, 0.620))  # 125mm dropped junction!

    p_stay_l_start = p_tt_stay_junction + Vector((0.0, -0.022, 0.0))
    stay_l_path = [p_stay_l_start.lerp(P_REAR_AXLE_L, s / 5.0) for s in range(6)]
    loft_tt_tube(
        bm,
        stay_l_path,
        chord_func=lambda t: 0.034 - t * 0.008,
        width_func=lambda t: 0.015 - t * 0.003,
        profile_type="aero_wing",
        nose_forward=True,
        lateral_hint=Vector((0.0, -1.0, 0.0)),
        num_profile_pts=12,
        material_index=0,
    )

    p_stay_r_start = p_tt_stay_junction + Vector((0.0, 0.022, 0.0))
    stay_r_path = [p_stay_r_start.lerp(P_REAR_AXLE_R, s / 5.0) for s in range(6)]
    loft_tt_tube(
        bm,
        stay_r_path,
        chord_func=lambda t: 0.034 - t * 0.008,
        width_func=lambda t: 0.015 - t * 0.003,
        profile_type="aero_wing",
        nose_forward=True,
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_profile_pts=12,
        material_index=0,
    )

    # 6. BOX-SECTION AERO CHAINSTAYS & OVERSIZED BB
    # -------------------------------------------------------------------------
    cs_l_start = P_BB + Vector((0.0, -0.040, 0.0))
    cs_l_path = [cs_l_start.lerp(P_REAR_AXLE_L, s / 5.0) for s in range(6)]
    loft_tt_tube(
        bm,
        cs_l_path,
        chord_func=lambda t: 0.035 - t * 0.008,
        width_func=lambda t: 0.022 - t * 0.004,
        profile_type="aero_wing",
        nose_forward=True,
        lateral_hint=Vector((0.0, -1.0, 0.0)),
        num_profile_pts=12,
        material_index=0,
    )

    cs_r_start = P_BB + Vector((0.0, 0.040, 0.0))
    cs_r_path = [cs_r_start.lerp(P_REAR_AXLE_R, s / 5.0) for s in range(6)]
    loft_tt_tube(
        bm,
        cs_r_path,
        chord_func=lambda t: 0.035 - t * 0.008,
        width_func=lambda t: 0.022 - t * 0.004,
        profile_type="aero_wing",
        nose_forward=True,
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_profile_pts=12,
        material_index=0,
    )

    # Oversized TT Bottom Bracket Shell
    bb_rings = []
    for y_val in [-0.044, 0.0, 0.044]:
        c = P_BB + Vector((0.0, y_val, 0.0))
        ring = []
        for s in range(16):
            a = (s / 16.0) * 2.0 * math.pi
            pos = c + Vector((0.028 * math.cos(a), 0.0, 0.028 * math.sin(a)))
            ring.append(bm.verts.new(pos))
        bb_rings.append(ring)
    loft_rings(bm, bb_rings, cap_start=True, cap_end=True, material_index=0)

    # 7. REAR 12x142mm THRU-AXLE DROPOUTS & FLAT-MOUNT TABS
    # -------------------------------------------------------------------------
    for is_l, p_axle in [(True, P_REAR_AXLE_L), (False, P_REAR_AXLE_R)]:
        y_dir = -1.0 if is_l else 1.0
        r_rings = []
        for dy in [0.0, y_dir * 0.015]:
            c = p_axle + Vector((0.0, dy, 0.0))
            ring = []
            for s in range(12):
                a = (s / 12.0) * 2.0 * math.pi
                pos = c + Vector((0.012 * math.cos(a), 0.0, 0.012 * math.sin(a)))
                ring.append(bm.verts.new(pos))
            r_rings.append(ring)
        loft_rings(bm, r_rings, cap_start=True, cap_end=True, material_index=1)

    # Flat-mount rear disc caliper tabs on left chainstay
    fm_base = P_REAR_AXLE_L + Vector((0.050, 0.006, 0.014))
    for offset in [-0.017, 0.017]:
        boss_center = fm_base + Vector((offset * 0.95, 0.007, -offset * 0.25))
        b_rings = []
        for h in [0.0, 0.011]:
            c = boss_center + Vector((0.0, 0.0, h))
            ring = []
            for s in range(8):
                a = (s / 8.0) * 2.0 * math.pi
                pos = c + Vector((0.005 * math.cos(a), 0.005 * math.sin(a), 0.0))
                ring.append(bm.verts.new(pos))
            b_rings.append(ring)
        loft_rings(bm, b_rings, cap_start=True, cap_end=True, material_index=1)

    # 8. INTEGRATED TIME TRIAL COCKPIT (BASEBAR + LEMONDKA + ARMRESTS)
    # -------------------------------------------------------------------------
    build_integrated_tt_cockpit(
        bm,
        P_STEM,
        material_frame=0,
        material_carbon=1,
        material_metal=2,
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
# DEEP TIME TRIAL DISC BRAKE FORK GENERATOR
# =============================================================================

def create_tt_fork_mesh(
    name: str = "Bike_Fork_TT",
    hex_color: str = "#1E293B",
) -> bpy.types.Object:
    """
    Procedurally creates the aerodynamic Time Trial disc brake fork:
      - Deep integrated aero crown blending into the headtube fairing
      - Extreme Kammtail bladed legs (55mm chord at crown, 34mm at axle)
      - Flat-mount disc brake caliper tabs on the left blade
      - 12x100mm thru-axle dropouts
    """
    bm = bmesh.new()

    P_CROWN = Vector((0.495, 0.000, 0.505))
    P_FRONT_AXLE_L = Vector((0.595, -0.050, 0.340))
    P_FRONT_AXLE_R = Vector((0.595, 0.050, 0.340))

    # 1. INTEGRATED DEEP TT FORK CROWN
    # -------------------------------------------------------------------------
    crown_rings = []
    for h in [0.000, 0.018, 0.038]:
        c = P_CROWN + Vector((-h * 0.28, 0.0, h))
        chord_len = 0.075 - h * 0.12
        width_len = 0.038 - h * 0.08
        pts_2d = generate_deep_tt_headtube_2d_points(chord_len, width_len, num_points=14)
        ring = []
        for p in pts_2d:
            pos = c + Vector((p.x, p.y, 0.0))
            ring.append(bm.verts.new(pos))
        crown_rings.append(ring)

    loft_rings(bm, crown_rings, cap_start=True, cap_end=True, material_index=0)

    # 2. LEFT DEEP TT FORK BLADE (Non-Drive Side with Flat-Mount Caliper Tabs)
    # -------------------------------------------------------------------------
    p_blade_l_start = P_CROWN + Vector((0.010, -0.026, 0.005))
    blade_l_path = [p_blade_l_start.lerp(P_FRONT_AXLE_L, s / 6.0) for s in range(7)]

    loft_tt_tube(
        bm,
        blade_l_path,
        chord_func=lambda t: 0.052 - t * 0.018,  # 52mm at crown to 34mm at dropouts
        width_func=lambda t: 0.020 - t * 0.006,  # 20mm to 14mm
        profile_type="kammtail",
        nose_forward=True,
        lateral_hint=Vector((0.0, -1.0, 0.0)),
        num_profile_pts=16,
        material_index=0,
    )

    # Flat-mount road disc caliper tabs on left blade
    fm_base_fork = P_FRONT_AXLE_L + Vector((-0.035, -0.004, 0.045))
    for offset in [-0.017, 0.017]:
        boss_center = fm_base_fork + Vector((offset * 0.50, -0.006, offset * 0.85))
        b_rings = []
        for h in [0.0, 0.010]:
            c = boss_center + Vector((0.0, 0.0, h))
            ring = []
            for s in range(8):
                a = (s / 8.0) * 2.0 * math.pi
                pos = c + Vector((0.005 * math.cos(a), 0.005 * math.sin(a), 0.0))
                ring.append(bm.verts.new(pos))
            b_rings.append(ring)
        loft_rings(bm, b_rings, cap_start=True, cap_end=True, material_index=1)

    # 3. RIGHT DEEP TT FORK BLADE
    # -------------------------------------------------------------------------
    p_blade_r_start = P_CROWN + Vector((0.010, 0.026, 0.005))
    blade_r_path = [p_blade_r_start.lerp(P_FRONT_AXLE_R, s / 6.0) for s in range(7)]

    loft_tt_tube(
        bm,
        blade_r_path,
        chord_func=lambda t: 0.052 - t * 0.018,
        width_func=lambda t: 0.020 - t * 0.006,
        profile_type="kammtail",
        nose_forward=True,
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_profile_pts=16,
        material_index=0,
    )

    # 4. FRONT 12x100mm THRU-AXLE DROPOUTS
    # -------------------------------------------------------------------------
    for is_l, p_axle in [(True, P_FRONT_AXLE_L), (False, P_FRONT_AXLE_R)]:
        y_dir = -1.0 if is_l else 1.0
        r_rings = []
        for dy in [0.0, y_dir * 0.015]:
            c = p_axle + Vector((0.0, dy, 0.0))
            ring = []
            for s in range(12):
                a = (s / 12.0) * 2.0 * math.pi
                pos = c + Vector((0.012 * math.cos(a), 0.0, 0.012 * math.sin(a)))
                ring.append(bm.verts.new(pos))
            r_rings.append(ring)
        loft_rings(bm, r_rings, cap_start=True, cap_end=True, material_index=1)

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

def assemble_tt_bicycle_frame(
    hex_color: str = "#1E293B",
    output_glb_path: str = "assets/3d/bikes/frame_tt.glb",
    join_components: bool = True,
) -> Tuple[bpy.types.Object, str]:
    """
    Builds the complete aerodynamic Time Trial bicycle frameset (frame + fork + cockpit),
    assigns PBR materials, applies transformations, and exports to .glb.
    """
    # Clear existing mesh objects from scene
    for obj in [o for o in bpy.context.scene.objects if o.type == "MESH"]:
        bpy.data.objects.remove(obj, do_unlink=True)

    print(f"[TT_FRAME] Generating extreme Time Trial aerodynamic frame in '{hex_color}'...")
    frame_obj = create_tt_frame_mesh("Bike_Frame_TT", hex_color=hex_color)
    fork_obj = create_tt_fork_mesh("Bike_Fork_TT", hex_color=hex_color)

    if join_components:
        context = bpy.context
        context.view_layer.objects.active = frame_obj
        fork_obj.select_set(True)
        frame_obj.select_set(True)
        bpy.ops.object.join()
        main_obj = frame_obj
        main_obj.name = "Bike_TT_Frameset"
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

    print(f"[TT_FRAME] Exporting binary glTF model to '{abs_output_path}'...")
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
    print(f"[TT_FRAME] Export successful! File size: {file_size_kb:.1f} KB")

    return main_obj, abs_output_path


# =============================================================================
# CLI EXECUTION ENTRY POINT
# =============================================================================

if __name__ == "__main__":
    print("\n" + "=" * 75)
    print("PRO PELOTON MANAGER: PROCEDURAL TIME TRIAL (TT) BICYCLE FRAME BUILDER")
    print("=" * 75)
    print(f"Blender Version: {bpy.app.version_string}")

    # Parse optional CLI hex color or default to #1E293B (Chrono Stealth)
    color = "#1E293B"
    for idx, arg in enumerate(sys.argv):
        if arg in ["--color", "-c"] and idx + 1 < len(sys.argv):
            color = sys.argv[idx + 1]

    output_path = "assets/3d/bikes/frame_tt.glb"
    for idx, arg in enumerate(sys.argv):
        if arg in ["--output", "-o"] and idx + 1 < len(sys.argv):
            output_path = sys.argv[idx + 1]

    frame_asset, glb_file = assemble_tt_bicycle_frame(
        hex_color=color, output_glb_path=output_path
    )

    # Set up studio lighting for live viewing if Blender GUI is open
    sm.setup_zwift_studio_lighting()

    print("\n[OK] TT frame generated and exported successfully:")
    print(f"     - Model Object : '{frame_asset.name}'")
    print(f"     - Vertex Count : {len(frame_asset.data.vertices)}")
    print(f"     - Polygon Count: {len(frame_asset.data.polygons)}")
    print(f"     - Material Slots: {[m.name for m in frame_asset.data.materials]}")
    print(f"     - Exported GLB : '{glb_file}'")
    print("=" * 75 + "\n")

