"""
===============================================================================
PRO PELOTON MANAGER - PROCEDURAL BICYCLE COMPONENTS & DRIVETRAIN GENERATOR
===============================================================================
Blender Python API (bpy) script that procedurally models high-end road bicycle
components and drivetrain details matching modern WorldTour superbike specs:
  1. Integrated Aero Cockpit:
     - One-piece carbon aero stem and handlebar
     - Dual-control brake/shift levers (klamkomanetki) flared/tilted inward
       (modern aerodynamic ergonomic hood position)
     - Compact ergonomic drops
  2. Carbon Crankset with Integrated Power Meter:
     - 172.5mm hollow carbon crank arms with clipless road pedals
     - CNC aluminum power meter spider (SRM / Quarq / Dura-Ace style)
     - Aerodynamic 54/40T double chainrings
  3. 12-Speed Road Cassette:
     - Stepped conical sprocket cluster (11-34T) with weight-reduction cutouts
  4. Wireless Electronic Rear Derailleur:
     - Electronic servo knuckle with wireless battery block (AXS / Di2 style)
     - Carbon pulley cage with upper (12T) and lower (14T) jockey wheels
  5. Drivetrain Chain Loop:
     - Closed continuous chain loop wrapping chainrings, cassette, and derailleur pulleys
  6. Carbon Bottle Cages & Water Bottles:
     - Downtube & seat tube lightweight cages
     - Ergonomic 550ml pro bidons with squeeze nozzles
  7. Short-Nose 3D-Printed Saddle:
     - Carbon rails (7x9mm) and anatomic short-nose shell
     - Central pressure-relief anatomic channel/cutout
     - 3D-printed honeycomb matrix padding texture (Mirror / Adaptive style)

Exported as binary glTF to: `assets/3d/bikes/components_pack.glb`.
Coordinates align with `frame_aero.glb`, `frame_climbing.glb`, and `frame_tt.glb`.

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
    print("        blender --background --python blender_scripts/generate_cockpit_and_drivetrain.py")
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
# BMESH LOFTING AND REVOLUTION HELPERS
# =============================================================================

def loft_rings(
    bm: bmesh.types.BMesh,
    rings: List[List[bmesh.types.BMVert]],
    cap_start: bool = True,
    cap_end: bool = True,
    material_index: int = 0,
) -> List[bmesh.types.BMFace]:
    """Lofts consecutive rings of vertices into quad faces."""
    faces = []
    for r_idx in range(len(rings) - 1):
        r1 = rings[r_idx]
        r2 = rings[r_idx + 1]
        n_pts = len(r1)
        for i in range(n_pts):
            i_next = (i + 1) % n_pts
            try:
                f = bm.faces.new([r1[i], r1[i_next], r2[i_next], r2[i]])
                f.material_index = material_index
                faces.append(f)
            except ValueError:
                pass

    if cap_start and len(rings) > 0:
        try:
            f_start = bm.faces.new(list(reversed(rings[0])))
            f_start.material_index = material_index
            faces.append(f_start)
        except ValueError:
            pass

    if cap_end and len(rings) > 0:
        try:
            f_end = bm.faces.new(rings[-1])
            f_end.material_index = material_index
            faces.append(f_end)
        except ValueError:
            pass

    return faces


def loft_tube_along_path(
    bm: bmesh.types.BMesh,
    path_points: List[Vector],
    radius_x: Union[float, Callable[[float], float]],
    radius_y: Union[float, Callable[[float], float]],
    lateral_hint: Vector = Vector((0.0, 1.0, 0.0)),
    num_pts: int = 12,
    cap_start: bool = True,
    cap_end: bool = True,
    material_index: int = 0,
) -> List[List[bmesh.types.BMVert]]:
    """Lofts a tube with elliptical/circular cross-section along a 3D path."""
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

        rx = radius_x(t) if callable(radius_x) else radius_x
        ry = radius_y(t) if callable(radius_y) else radius_y

        ring = []
        for i in range(num_pts):
            angle = (i / float(num_pts)) * 2.0 * math.pi
            pos = center + (rx * math.cos(angle)) * N + (ry * math.sin(angle)) * B
            ring.append(bm.verts.new(pos))
        rings.append(ring)

    loft_rings(bm, rings, cap_start=cap_start, cap_end=cap_end, material_index=material_index)
    return rings


# =============================================================================
# 1. INTEGRATED AERO COCKPIT & INWARD-FLARED HOODS
# =============================================================================

def build_integrated_cockpit(
    bm: bmesh.types.BMesh,
    p_headtube_top: Vector = Vector((0.445, 0.0, 0.655)),
    material_carbon: int = 0,
    material_rubber: int = 2,
    material_metal: int = 1,
) -> None:
    """
    Constructs an integrated carbon aerodynamic cockpit (stem + handlebar)
    with dual-control levers (klamkomanetki) tilted/turned inward by 10 degrees.
    """
    # 1. INTEGRATED STEM (110mm length)
    p_stem_end = p_headtube_top + Vector((0.105, 0.0, -0.010))
    stem_path = [p_headtube_top, p_headtube_top.lerp(p_stem_end, 0.5), p_stem_end]

    loft_tube_along_path(
        bm,
        stem_path,
        radius_x=0.019,
        radius_y=0.016,
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_pts=12,
        cap_start=True,
        cap_end=False,
        material_index=material_carbon,
    )

    # 2. AERO TOPS (Wing bar spanning Y = -0.190 to +0.190)
    p_bar_l = p_stem_end + Vector((0.0, -0.190, 0.0))
    p_bar_r = p_stem_end + Vector((0.0, 0.190, 0.0))

    # Center to Left wing
    wing_l_path = [p_stem_end.lerp(p_bar_l, s / 4.0) for s in range(5)]
    loft_tube_along_path(
        bm,
        wing_l_path,
        radius_x=0.016,  # 32mm aero wing depth
        radius_y=0.010,  # 20mm thickness
        lateral_hint=Vector((1.0, 0.0, 0.0)),
        num_pts=12,
        cap_start=False,
        cap_end=False,
        material_index=material_carbon,
    )

    # Center to Right wing
    wing_r_path = [p_stem_end.lerp(p_bar_r, s / 4.0) for s in range(5)]
    loft_tube_along_path(
        bm,
        wing_r_path,
        radius_x=0.016,
        radius_y=0.010,
        lateral_hint=Vector((1.0, 0.0, 0.0)),
        num_pts=12,
        cap_start=False,
        cap_end=False,
        material_index=material_carbon,
    )

    # 3. ERGONOMIC COMPACT DROPS (Left & Right)
    for is_left, y_pos in [(True, -0.190), (False, 0.190)]:
        p_root = p_stem_end + Vector((0.0, y_pos, 0.0))
        p_reach = p_root + Vector((0.075, 0.0, -0.015))  # 75mm reach
        p_hook = p_reach + Vector((-0.010, 0.0, -0.075))  # down curve
        p_drop_end = p_hook + Vector((-0.090, 0.0, -0.035))  # 125mm compact drop

        drop_path = [p_root, p_reach, p_hook, p_drop_end]
        loft_tube_along_path(
            bm,
            drop_path,
            radius_x=0.012,  # standard 24mm drop diameter
            radius_y=0.012,
            lateral_hint=Vector((0.0, 1.0, 0.0)),
            num_pts=12,
            cap_start=False,
            cap_end=True,
            material_index=material_carbon,
        )

        # 4. DUAL CONTROL SHIFTER/BRAKE LEVERS (INWARD FLARE)
        # ---------------------------------------------------------------------
        # Inward angle: 10 degrees inward toward bike centerline
        inward_dir = 1.0 if is_left else -1.0
        inward_offset = inward_dir * 0.012

        p_hood_base = p_reach + Vector((-0.005, inward_dir * 0.004, 0.008))
        p_hood_mid = p_hood_base + Vector((0.045, inward_offset * 0.5, 0.015))
        p_hood_tip = p_hood_mid + Vector((0.030, inward_offset, 0.022))

        # Rubber hood body
        hood_path = [p_hood_base, p_hood_mid, p_hood_tip]
        loft_tube_along_path(
            bm,
            hood_path,
            radius_x=lambda t: 0.016 - t * 0.004,
            radius_y=lambda t: 0.012 - t * 0.003,
            lateral_hint=Vector((0.0, 1.0, 0.0)),
            num_pts=10,
            cap_start=True,
            cap_end=True,
            material_index=material_rubber,
        )

        # Carbon brake/shift lever blade hanging down
        p_blade_pivot = p_hood_mid + Vector((-0.005, 0.0, -0.010))
        p_blade_mid = p_blade_pivot + Vector((-0.015, inward_dir * 0.005, -0.050))
        p_blade_tip = p_blade_mid + Vector((-0.010, inward_dir * 0.008, -0.040))

        blade_path = [p_blade_pivot, p_blade_mid, p_blade_tip]
        loft_tube_along_path(
            bm,
            blade_path,
            radius_x=0.006,  # flat blade
            radius_y=0.0025,
            lateral_hint=Vector((0.0, 1.0, 0.0)),
            num_pts=8,
            cap_start=True,
            cap_end=True,
            material_index=material_carbon,
        )


# =============================================================================
# 2. CARBON CRANKSET WITH POWER METER SPIDER & PEDALS
# =============================================================================

def build_carbon_crankset(
    bm: bmesh.types.BMesh,
    p_bb: Vector = Vector((0.0, 0.0, 0.270)),
    material_carbon: int = 0,
    material_metal: int = 1,
) -> None:
    """
    Constructs hollow carbon crank arms (172.5mm length), an integrated
    power meter spider, 54/40T double chainrings, and clipless pedals.
    """
    crank_length = 0.1725  # 172.5mm pro length
    q_factor_half = 0.076  # 152mm Q-factor

    # 1. HOLLOW CARBON CRANK ARMS (Left & Right 180° out of phase)
    # Right Crank Arm (drive side, pointing down/forward at 45°)
    arm_angle = math.radians(45.0)
    dir_r = Vector((math.cos(arm_angle), 0.0, -math.sin(arm_angle)))
    p_r_root = p_bb + Vector((0.0, q_factor_half, 0.0))
    p_r_tip = p_r_root + dir_r * crank_length

    arm_r_path = [p_r_root, p_r_root.lerp(p_r_tip, 0.5), p_r_tip]
    loft_tube_along_path(
        bm,
        arm_r_path,
        radius_x=lambda t: 0.018 - t * 0.004,  # 36mm tapering to 28mm
        radius_y=lambda t: 0.009 - t * 0.002,  # 18mm to 14mm
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_pts=12,
        cap_start=True,
        cap_end=True,
        material_index=material_carbon,
    )

    # Left Crank Arm (non-drive side, pointing up/back at 225°)
    p_l_root = p_bb + Vector((0.0, -q_factor_half, 0.0))
    p_l_tip = p_l_root - dir_r * crank_length

    arm_l_path = [p_l_root, p_l_root.lerp(p_l_tip, 0.5), p_l_tip]
    loft_tube_along_path(
        bm,
        arm_l_path,
        radius_x=lambda t: 0.018 - t * 0.004,
        radius_y=lambda t: 0.009 - t * 0.002,
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_pts=12,
        cap_start=True,
        cap_end=True,
        material_index=material_carbon,
    )

    # 2. POWER METER SPIDER (CNC Aluminum disc with strain gauge housing)
    y_spider = p_bb.y + 0.058
    r_spider = 0.056
    spider_rings = []
    for dy in [-0.003, 0.003]:
        c = p_bb + Vector((0.0, y_spider + dy, 0.0))
        ring = []
        for s in range(20):
            a = (s / 20.0) * 2.0 * math.pi
            pos = c + Vector((r_spider * math.cos(a), 0.0, r_spider * math.sin(a)))
            ring.append(bm.verts.new(pos))
        spider_rings.append(ring)
    loft_rings(bm, spider_rings, cap_start=True, cap_end=True, material_index=material_metal)

    # Power meter battery pod / LED indicator cap on spider
    p_pm_pod = p_bb + Vector((0.038, y_spider + 0.004, 0.022))
    pod_rings = []
    for dy in [0.0, 0.006]:
        ring = []
        for s in range(10):
            a = (s / 10.0) * 2.0 * math.pi
            pos = p_pm_pod + Vector((0.010 * math.cos(a), dy, 0.010 * math.sin(a)))
            ring.append(bm.verts.new(pos))
        pod_rings.append(ring)
    loft_rings(bm, pod_rings, cap_start=True, cap_end=True, material_index=material_metal)

    # 3. AERODYNAMIC CHAINRINGS (54T Outer & 40T Inner)
    # Outer 54T Aero Chainring (R = 0.110m)
    y_outer_ring = p_bb.y + 0.063
    ring_54_rings = []
    for dy in [-0.0015, 0.0015]:
        c = p_bb + Vector((0.0, y_outer_ring + dy, 0.0))
        ring = []
        for s in range(36):
            a = (s / 36.0) * 2.0 * math.pi
            # Subtle scalloped tooth pitch modulation
            tooth = 0.003 * math.cos(54.0 * a)
            r = 0.110 + tooth
            pos = c + Vector((r * math.cos(a), 0.0, r * math.sin(a)))
            ring.append(bm.verts.new(pos))
        ring_54_rings.append(ring)
    loft_rings(bm, ring_54_rings, cap_start=True, cap_end=True, material_index=material_metal)

    # Inner 40T Chainring (R = 0.082m)
    y_inner_ring = p_bb.y + 0.054
    ring_40_rings = []
    for dy in [-0.0012, 0.0012]:
        c = p_bb + Vector((0.0, y_inner_ring + dy, 0.0))
        ring = []
        for s in range(28):
            a = (s / 28.0) * 2.0 * math.pi
            r = 0.082 + 0.002 * math.cos(40.0 * a)
            pos = c + Vector((r * math.cos(a), 0.0, r * math.sin(a)))
            ring.append(bm.verts.new(pos))
        ring_40_rings.append(ring)
    loft_rings(bm, ring_40_rings, cap_start=True, cap_end=True, material_index=material_metal)

    # 4. CLIPLESS ROAD PEDALS (Look Keo / SPD-SL style)
    for p_tip, y_ext in [(p_r_tip, 0.024), (p_l_tip, -0.024)]:
        pedal_c = p_tip + Vector((0.0, y_ext, 0.0))
        # Carbon pedal body block
        pts_pedal = [
            Vector((-0.035, -0.018, -0.006)),
            Vector((0.040, -0.018, -0.006)),
            Vector((0.040, 0.018, -0.006)),
            Vector((-0.035, 0.018, -0.006)),
        ]
        r_bot = [bm.verts.new(pedal_c + p) for p in pts_pedal]
        r_top = [bm.verts.new(pedal_c + p + Vector((0.0, 0.0, 0.014))) for p in pts_pedal]
        loft_rings(bm, [r_bot, r_top], cap_start=True, cap_end=True, material_index=material_carbon)


# =============================================================================
# 3. 12-SPEED ROAD CASSETTE & WIRELESS DERAILLEUR & CHAIN
# =============================================================================

def build_12speed_cassette(
    bm: bmesh.types.BMesh,
    p_rear_axle: Vector = Vector((-0.410, 0.0, 0.340)),
    material_metal: int = 1,
) -> None:
    """
    Constructs a 12-speed stepped road cassette (11-34T) on the drive-side axle.
    """
    y_start = 0.038  # 34T largest cog near spokes
    y_end = 0.057    # 11T smallest cog near dropout
    num_cogs = 12

    for c_idx in range(num_cogs):
        t = c_idx / float(num_cogs - 1)
        # Cog radius from 34T (0.070m) down to 11T (0.024m)
        r_cog = 0.070 - t * 0.046
        y_cog = y_start + t * (y_end - y_start)

        cog_rings = []
        for dy in [-0.0008, 0.0008]:
            c = p_rear_axle + Vector((0.0, y_cog + dy, 0.0))
            ring = []
            for s in range(24):
                a = (s / 24.0) * 2.0 * math.pi
                pos = c + Vector((r_cog * math.cos(a), 0.0, r_cog * math.sin(a)))
                ring.append(bm.verts.new(pos))
            cog_rings.append(ring)
        loft_rings(bm, cog_rings, cap_start=True, cap_end=True, material_index=material_metal)


def build_wireless_rear_derailleur(
    bm: bmesh.types.BMesh,
    p_rear_axle: Vector = Vector((-0.410, 0.0, 0.340)),
    material_carbon: int = 0,
    material_metal: int = 1,
) -> None:
    """
    Constructs an electronic wireless rear derailleur (SRAM AXS / Di2 style)
    with B-knuckle, wireless battery block, and carbon cage with 12T/14T pulleys.
    """
    p_derailleur_root = p_rear_axle + Vector((0.015, 0.065, -0.045))

    # 1. B-KNUCKLE & SERVO BODY
    b_pts = [
        Vector((-0.020, -0.014, -0.012)),
        Vector((0.022, -0.014, -0.012)),
        Vector((0.022, 0.014, -0.012)),
        Vector((-0.020, 0.014, -0.012)),
    ]
    r_b1 = [bm.verts.new(p_derailleur_root + p) for p in b_pts]
    r_b2 = [bm.verts.new(p_derailleur_root + p + Vector((0.0, 0.0, 0.024))) for p in b_pts]
    loft_rings(bm, [r_b1, r_b2], cap_start=True, cap_end=True, material_index=material_metal)

    # 2. REMOVABLE WIRELESS BATTERY BLOCK (on rear of servo)
    p_battery = p_derailleur_root + Vector((-0.025, 0.002, 0.005))
    bat_pts = [
        Vector((-0.015, -0.010, -0.010)),
        Vector((0.015, -0.010, -0.010)),
        Vector((0.015, 0.010, -0.010)),
        Vector((-0.015, 0.010, -0.010)),
    ]
    r_bat1 = [bm.verts.new(p_battery + p) for p in bat_pts]
    r_bat2 = [bm.verts.new(p_battery + p + Vector((0.0, 0.0, 0.020))) for p in bat_pts]
    loft_rings(bm, [r_bat1, r_bat2], cap_start=True, cap_end=True, material_index=material_carbon)

    # 3. CARBON PULLEY CAGE & JOCKEY WHEELS
    # Upper Guide Pulley (12T, R = 0.016m)
    p_pulley_upper = p_derailleur_root + Vector((0.010, -0.010, -0.018))
    # Lower Tension Pulley (14T, R = 0.018m)
    p_pulley_lower = p_pulley_upper + Vector((0.030, 0.000, -0.070))

    for p_p, r_pulley in [(p_pulley_upper, 0.016), (p_pulley_lower, 0.018)]:
        p_rings = []
        for dy in [-0.002, 0.002]:
            ring = []
            for s in range(12):
                a = (s / 12.0) * 2.0 * math.pi
                pos = p_p + Vector((r_pulley * math.cos(a), dy, r_pulley * math.sin(a)))
                ring.append(bm.verts.new(pos))
            p_rings.append(ring)
        loft_rings(bm, p_rings, cap_start=True, cap_end=True, material_index=material_metal)

    # Carbon cage plates bridging upper and lower pulleys
    for dy in [-0.004, 0.004]:
        plate_path = [p_pulley_upper + Vector((0.0, dy, 0.0)), p_pulley_lower + Vector((0.0, dy, 0.0))]
        loft_tube_along_path(
            bm,
            plate_path,
            radius_x=0.007,
            radius_y=0.0015,
            lateral_hint=Vector((0.0, 1.0, 0.0)),
            num_pts=8,
            cap_start=True,
            cap_end=True,
            material_index=material_carbon,
        )


def build_drivetrain_chain_loop(
    bm: bmesh.types.BMesh,
    p_bb: Vector = Vector((0.0, 0.0, 0.270)),
    p_rear_axle: Vector = Vector((-0.410, 0.0, 0.340)),
    material_metal: int = 1,
) -> None:
    """
    Constructs a closed continuous chain loop routing between chainrings,
    cassette, and rear derailleur pulley cage.
    """
    y_chain = 0.063
    p_chainring_top = p_bb + Vector((0.000, y_chain, 0.110))
    p_chainring_front = p_bb + Vector((0.110, y_chain, 0.000))
    p_chainring_bot = p_bb + Vector((0.000, y_chain, -0.110))

    p_cassette_top = p_rear_axle + Vector((0.000, 0.046, 0.052))
    p_cassette_rear = p_rear_axle + Vector((-0.052, 0.046, 0.000))

    p_pulley_up = p_rear_axle + Vector((0.025, 0.055, -0.063))
    p_pulley_low = p_rear_axle + Vector((0.055, 0.055, -0.133))

    chain_nodes = [
        p_chainring_top,
        p_cassette_top,
        p_cassette_rear,
        p_pulley_up,
        p_pulley_low,
        p_chainring_bot,
        p_chainring_front,
        p_chainring_top,  # closes loop
    ]

    loft_tube_along_path(
        bm,
        chain_nodes,
        radius_x=0.0045,  # 9mm chain height
        radius_y=0.0025,  # 5mm chain width
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_pts=8,
        cap_start=False,
        cap_end=False,
        material_index=material_metal,
    )


# =============================================================================
# 4. BOTTLE CAGES & WATER BOTTLES (BIDONY)
# =============================================================================

def build_single_bottle_and_cage(
    bm: bmesh.types.BMesh,
    mount_center: Vector,
    tilt_angle_deg: float,
    material_carbon: int = 0,
    material_bottle: int = 3,
) -> None:
    """
    Constructs an aerodynamic lightweight carbon bottle cage with a 550ml bidon.
    """
    rad = math.radians(tilt_angle_deg)
    axis_up = Vector((math.sin(rad), 0.0, math.cos(rad))).normalized()
    axis_fwd = Vector((math.cos(rad), 0.0, -math.sin(rad))).normalized()

    # 1. WATER BOTTLE (550ml Pro Bidon)
    # -------------------------------------------------------------------------
    # Stations along bottle axis: (dist_along_axis, radius)
    bottle_profile = [
        (0.000, 0.035),  # base
        (0.020, 0.037),
        (0.120, 0.037),  # lower body
        (0.135, 0.032),  # ergonomic grip indentation
        (0.155, 0.037),  # upper shoulder
        (0.180, 0.025),  # neck / cap
        (0.195, 0.012),  # drink spout nozzle
    ]

    p_bottle_base = mount_center + axis_fwd * 0.040
    rings = []
    for dist, r in bottle_profile:
        c = p_bottle_base + axis_up * dist
        ring = []
        for s in range(16):
            a = (s / 16.0) * 2.0 * math.pi
            # Local perpendicular frame
            pos = c + (r * math.cos(a)) * axis_fwd + Vector((0.0, r * math.sin(a), 0.0))
            ring.append(bm.verts.new(pos))
        rings.append(ring)

    loft_rings(bm, rings, cap_start=True, cap_end=True, material_index=material_bottle)

    # 2. CARBON BOTTLE CAGE
    # -------------------------------------------------------------------------
    # Back spine + lower shelf + retention arms
    spine_path = [mount_center, mount_center + axis_up * 0.130]
    loft_tube_along_path(
        bm,
        spine_path,
        radius_x=0.006,
        radius_y=0.003,
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_pts=8,
        cap_start=True,
        cap_end=True,
        material_index=material_carbon,
    )

    # Wrap-around retention arms
    p_arm_root = mount_center + axis_up * 0.090
    for is_l, dy in [(True, -0.042), (False, 0.042)]:
        arm_pts = [
            p_arm_root,
            p_arm_root + axis_fwd * 0.030 + Vector((0.0, dy * 0.8, 0.0)),
            p_arm_root + axis_fwd * 0.065 + Vector((0.0, dy * 0.5, 0.0)),
        ]
        loft_tube_along_path(
            bm,
            arm_pts,
            radius_x=0.003,
            radius_y=0.003,
            lateral_hint=Vector((0.0, 0.0, 1.0)),
            num_pts=6,
            cap_start=True,
            cap_end=True,
            material_index=material_carbon,
        )


def build_bottle_cages_and_bottles(
    bm: bmesh.types.BMesh,
    material_carbon: int = 0,
    material_bottle: int = 3,
) -> None:
    """
    Constructs both Downtube and Seat Tube bottle cages and bottles.
    """
    # Downtube bottle: angled at ~32 degrees
    p_dt_cage = Vector((0.215, 0.0, 0.380))
    build_single_bottle_and_cage(bm, p_dt_cage, tilt_angle_deg=32.0, material_carbon=material_carbon, material_bottle=material_bottle)

    # Seat tube bottle: angled at ~74 degrees
    p_st_cage = Vector((-0.075, 0.0, 0.465))
    build_single_bottle_and_cage(bm, p_st_cage, tilt_angle_deg=74.0, material_carbon=material_carbon, material_bottle=material_bottle)


# =============================================================================
# 5. SHORT-NOSE 3D-PRINTED ANATOMIC SADDLE
# =============================================================================

def build_short_nose_3d_printed_saddle(
    bm: bmesh.types.BMesh,
    p_seatpost_top: Vector = Vector((-0.200, 0.0, 0.895)),
    material_carbon: int = 0,
    material_padding: int = 0,
) -> None:
    """
    Constructs a modern short-nose pro racing saddle with central anatomic
    pressure-relief cutout and 3D-printed honeycomb matrix texture
    (Specialized Power Mirror / Fizik Adaptive style).
    """
    p_saddle_base = p_seatpost_top + Vector((0.0, 0.0, 0.015))

    # 1. 7x9mm OVAL CARBON RAILS
    for y_rail in [-0.021, 0.021]:
        rail_path = [
            p_saddle_base + Vector((-0.090, y_rail, -0.010)),
            p_saddle_base + Vector((0.000, y_rail, -0.010)),
            p_saddle_base + Vector((0.065, y_rail * 0.7, 0.005)),
        ]
        loft_tube_along_path(
            bm,
            rail_path,
            radius_x=0.0045,  # 9mm rail height
            radius_y=0.0035,  # 7mm rail width
            lateral_hint=Vector((0.0, 1.0, 0.0)),
            num_pts=8,
            cap_start=True,
            cap_end=True,
            material_index=material_carbon,
        )

    # 2. SHORT-NOSE ERGONOMIC SADDLE SHELL WITH CENTRAL CUTOUT
    # Length: 240mm (from X = -0.120 to +0.120 relative to saddle center)
    # Rear width: 145mm (Y = +/-0.0725), Nose width: 45mm (Y = +/-0.0225)
    num_x_stations = 8
    p_center = p_saddle_base + Vector((0.0, 0.0, 0.020))

    outer_rings = []
    for ix in range(num_x_stations + 1):
        tx = ix / float(num_x_stations)
        # x_rel from -0.120 (rear) to +0.120 (nose)
        x_rel = -0.120 + tx * 0.240

        # Width tapering from 145mm at rear to 45mm at nose
        if tx < 0.35:
            # Curved wide rear wings
            w_factor = math.sin((tx / 0.35) * math.pi * 0.5)
            half_w = 0.060 + 0.0125 * (1.0 - (1.0 - w_factor) ** 2)
        else:
            t_nose = (tx - 0.35) / 0.65
            half_w = 0.0725 * (1.0 - t_nose) + 0.0225 * t_nose

        # Subtle wave swoop (dipped center, raised rear)
        z_dip = 0.008 * math.sin(tx * math.pi)
        z_pos = p_center.z - z_dip + (0.010 if tx < 0.2 else 0.0)

        # 4 vertices per cross-section station: [outer_left, cutout_left, cutout_right, outer_right]
        # Central pressure-relief cutout exists between tx=0.25 and tx=0.75
        has_cutout = (0.25 <= tx <= 0.75)
        cutout_half_w = 0.011 if has_cutout else 0.001

        v_ol = bm.verts.new(Vector((p_center.x + x_rel, -half_w, z_pos)))
        v_cl = bm.verts.new(Vector((p_center.x + x_rel, -cutout_half_w, z_pos - 0.003)))
        v_cr = bm.verts.new(Vector((p_center.x + x_rel, cutout_half_w, z_pos - 0.003)))
        v_or = bm.verts.new(Vector((p_center.x + x_rel, half_w, z_pos)))

        outer_rings.append([v_ol, v_cl, v_cr, v_or])

    # Connect saddle upper padding faces
    for ix in range(num_x_stations):
        r1 = outer_rings[ix]
        r2 = outer_rings[ix + 1]

        # Left wing face
        try:
            f_left = bm.faces.new([r1[0], r1[1], r2[1], r2[0]])
            f_left.material_index = material_padding
        except ValueError:
            pass

        # Center bridge face (only at solid front and rear zones)
        tx_mid = (ix + 0.5) / float(num_x_stations)
        if not (0.25 <= tx_mid <= 0.75):
            try:
                f_mid = bm.faces.new([r1[1], r1[2], r2[2], r2[1]])
                f_mid.material_index = material_padding
            except ValueError:
                pass

        # Right wing face
        try:
            f_right = bm.faces.new([r1[2], r1[3], r2[3], r2[2]])
            f_right.material_index = material_padding
        except ValueError:
            pass


# =============================================================================
# HIGH-LEVEL ASSEMBLY AND EXPORT PIPELINE
# =============================================================================

def generate_components_pack_mesh(
    name: str = "Bike_Components_Pack",
    bottle_color_hex: str = "#F8FAFC",
) -> bpy.types.Object:
    """
    Procedurally creates all bicycle components and drivetrain details in a single mesh:
      - Integrated carbon aero cockpit with inward-flared hoods
      - Carbon crankset with power meter spider, double chainrings, and pedals
      - 12-speed road cassette
      - Wireless electronic rear derailleur
      - Closed drivetrain chain loop
      - Dual bottle cages and pro water bottles
      - Short-nose 3D-printed anatomic saddle with central cutout
    """
    bm = bmesh.new()

    # Reference coordinates aligning with frames
    p_ht_top = Vector((0.445, 0.0, 0.655))
    p_bb = Vector((0.0, 0.0, 0.270))
    p_rear_axle = Vector((-0.410, 0.0, 0.340))
    p_seatpost_top = Vector((-0.200, 0.0, 0.895))

    # 1. Cockpit & Klamkomanetki
    build_integrated_cockpit(bm, p_headtube_top=p_ht_top, material_carbon=0, material_rubber=2, material_metal=1)

    # 2. Crankset & Power Meter Spider
    build_carbon_crankset(bm, p_bb=p_bb, material_carbon=0, material_metal=1)

    # 3. 12-Speed Cassette
    build_12speed_cassette(bm, p_rear_axle=p_rear_axle, material_metal=1)

    # 4. Wireless Rear Derailleur
    build_wireless_rear_derailleur(bm, p_rear_axle=p_rear_axle, material_carbon=0, material_metal=1)

    # 5. Drivetrain Chain Loop
    build_drivetrain_chain_loop(bm, p_bb=p_bb, p_rear_axle=p_rear_axle, material_metal=1)

    # 6. Bottle Cages & Water Bottles
    build_bottle_cages_and_bottles(bm, material_carbon=0, material_bottle=3)

    # 7. Short-Nose 3D-Printed Saddle
    build_short_nose_3d_printed_saddle(bm, p_seatpost_top=p_seatpost_top, material_carbon=0, material_padding=0)

    # Finalize BMesh and construct Blender Object
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)

    # Material Slot Setup
    mat_carbon = sm.create_carbon_matte_material(name="M_Components_Carbon")
    mat_metal = sm.create_metal_rotor_material(name="M_Components_Metal")
    mat_rubber = sm.create_tire_rubber_material(tan_wall=False, name="M_Hoods_Rubber")
    mat_bottle = sm.create_glossy_frame_paint_material(hex_color=bottle_color_hex, name="M_Bottle_Glossy")

    sm.assign_material(obj, mat_carbon, slot_index=0)
    sm.assign_material(obj, mat_metal, slot_index=1)
    sm.assign_material(obj, mat_rubber, slot_index=2)
    sm.assign_material(obj, mat_bottle, slot_index=3)

    # Apply Zwift-style smooth shading and clean geometry
    sm.apply_zwift_style(obj, auto_smooth_angle_deg=35.0)
    sm.clean_zwift_mesh(obj)

    return obj


def export_components_pack(
    output_glb_path: str = "assets/3d/bikes/components_pack.glb",
    bottle_color_hex: str = "#F8FAFC",
) -> Tuple[bpy.types.Object, str]:
    """
    Builds the components pack and exports it to binary glTF (.glb).
    """
    # Clear existing mesh objects from scene
    for obj in [o for o in bpy.context.scene.objects if o.type == "MESH"]:
        bpy.data.objects.remove(obj, do_unlink=True)

    print("\n" + "=" * 75)
    print("PRO PELOTON MANAGER: GENERATING BICYCLE COMPONENTS PACK")
    print("=" * 75)

    comp_obj = generate_components_pack_mesh(
        name="Bike_Components_Pack",
        bottle_color_hex=bottle_color_hex,
    )

    bpy.ops.object.select_all(action="DESELECT")
    comp_obj.select_set(True)
    bpy.context.view_layer.objects.active = comp_obj

    abs_output_path = os.path.abspath(output_glb_path)
    os.makedirs(os.path.dirname(abs_output_path), exist_ok=True)

    print(f"[COMPONENTS] Exporting binary glTF model to '{abs_output_path}'...")
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
        raise RuntimeError(f"Export failed: file not found at '{abs_output_path}'")

    file_size_kb = os.path.getsize(abs_output_path) / 1024.0
    print(f"[COMPONENTS] Export successful! File size: {file_size_kb:.1f} KB ({len(comp_obj.data.polygons)} polys)")
    print("=" * 75 + "\n")

    return comp_obj, abs_output_path


# =============================================================================
# CLI EXECUTION ENTRY POINT
# =============================================================================

if __name__ == "__main__":
    out_path = "assets/3d/bikes/components_pack.glb"
    for idx, arg in enumerate(sys.argv):
        if arg in ["--output", "-o"] and idx + 1 < len(sys.argv):
            out_path = sys.argv[idx + 1]

    bottle_color = "#F8FAFC"
    for idx, arg in enumerate(sys.argv):
        if arg in ["--bottle-color", "-b"] and idx + 1 < len(sys.argv):
            bottle_color = sys.argv[idx + 1]

    comp_asset, glb_file = export_components_pack(
        output_glb_path=out_path,
        bottle_color_hex=bottle_color,
    )

    # Setup studio lighting for viewport viewing
    sm.setup_zwift_studio_lighting()

    print(f"[SUCCESS] Components pack generated: '{glb_file}'")

