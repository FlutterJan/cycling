"""
===============================================================================
PRO PELOTON MANAGER - RACE SUPPORT VEHICLES GENERATOR
===============================================================================
Blender Python API (bpy) script that procedurally generates 3D race convoy
vehicles accompanying the professional peloton with authentic Grand Tour styling:

  1. Samochód Dyrektora Sportowego (Team Car - kombi) (`vehicle_team_car.glb`):
     - Modern European station wagon / estate car in glossy team livery
     - Aerodynamic raked greenhouse, tinted windows, LED headlights/taillights
     - Custom heavy-duty tubular aluminum roof rack
     - 6 complete spare racing bikes mounted on the roof rack
     - 4 spare carbon wheelsets mounted vertically on mast holders
     - Dual communication radio whip antennas and amber roof caution strobe beacon
     - Team sponsor door decals and official directeur sportif car number plaque

  2. Motocykl z Operatorem Kamery TV oraz Motocykl Sędziowski (`vehicle_moto_tv.glb`):
     - Broadcast TV Camera Moto:
       * Heavy touring motorcycle with front aerodynamic fairing and windscreen
       * Official pilot with helmet and high-visibility yellow vest at handlebars
       * Professional TV cameraman seated facing backwards holding an ENG broadcast
         shoulder camera pointing directly at the peloton / breakaways
       * High-gain microwave relay transmission antenna sending live HD pictures
     - Commissaire / Timekeeper Moto:
       * Touring motorcycle with official Commissaire / Ardoisier holding a time board
       * Official UCI race markings, safety strobe lights, and pennant flag
     - Exported combined as `vehicle_moto_tv.glb` and standalone as
       `vehicle_moto_commissaire.glb`.

All models conform to the clean, vibrant Zwift/MyWhoosh visual aesthetic (PBR materials,
smooth shading, optimized mid-poly geometry).

Output Directory: `assets/3d/vehicles/`
Compatible with Blender 3.6 LTS, 4.x, and 5.x+.
===============================================================================
"""

import math
import os
import sys
from typing import Dict, List, Optional, Tuple, Union

try:
    import bpy
    import bmesh
    from mathutils import Matrix, Vector
except ImportError:
    print("[ERROR] 'bpy' / 'mathutils' module not found. Run within Blender:")
    print("        blender --background --python blender_scripts/generate_support_vehicles.py")
    sys.exit(1)

# Ensure local script directory is in sys.path
script_dir = os.path.dirname(os.path.abspath(__file__))
if script_dir not in sys.path:
    sys.path.insert(0, script_dir)

try:
    import style_and_materials as sm
except ImportError:
    print(f"[ERROR] Could not import 'style_and_materials' from '{script_dir}'.")
    sys.exit(1)


# =============================================================================
# BMESH PROCEDURAL GEOMETRY BUILDERS
# =============================================================================

def add_box(
    bm: bmesh.types.BMesh,
    center: Tuple[float, float, float] = (0.0, 0.0, 0.0),
    size: Tuple[float, float, float] = (1.0, 1.0, 1.0),
    mat_index: int = 0,
) -> List[bmesh.types.BMFace]:
    """Creates an axis-aligned box with specified center and dimensions."""
    hx, hy, hz = size[0] * 0.5, size[1] * 0.5, size[2] * 0.5
    cx, cy, cz = center

    v0 = bm.verts.new((cx - hx, cy - hy, cz - hz))
    v1 = bm.verts.new((cx + hx, cy - hy, cz - hz))
    v2 = bm.verts.new((cx + hx, cy + hy, cz - hz))
    v3 = bm.verts.new((cx - hx, cy + hy, cz - hz))
    v4 = bm.verts.new((cx - hx, cy - hy, cz + hz))
    v5 = bm.verts.new((cx + hx, cy - hy, cz + hz))
    v6 = bm.verts.new((cx + hx, cy + hy, cz + hz))
    v7 = bm.verts.new((cx - hx, cy + hy, cz + hz))

    faces = [
        bm.faces.new((v0, v3, v2, v1)),  # Bottom (-Z)
        bm.faces.new((v4, v5, v6, v7)),  # Top (+Z)
        bm.faces.new((v0, v1, v5, v4)),  # Front (-Y)
        bm.faces.new((v2, v3, v7, v6)),  # Back (+Y)
        bm.faces.new((v0, v4, v7, v3)),  # Left (-X)
        bm.faces.new((v1, v2, v6, v5)),  # Right (+X)
    ]
    for f in faces:
        f.material_index = mat_index
        f.smooth = False
    return faces


def add_cylinder_between(
    bm: bmesh.types.BMesh,
    p1: Tuple[float, float, float],
    p2: Tuple[float, float, float],
    radius: float,
    segments: int = 8,
    mat_index: int = 0,
    cap_start: bool = True,
    cap_end: bool = True,
    smooth: bool = True,
) -> List[bmesh.types.BMFace]:
    """Generates a cylindrical tube connecting point p1 and point p2."""
    v1 = Vector(p1)
    v2 = Vector(p2)
    axis = v2 - v1
    length = axis.length
    if length < 1e-6:
        return []

    axis_norm = axis.normalized()
    up = Vector((0.0, 0.0, 1.0)) if abs(axis_norm.z) < 0.9 else Vector((0.0, 1.0, 0.0))
    radial_u = axis_norm.cross(up).normalized()
    radial_v = axis_norm.cross(radial_u).normalized()

    ring1: List[bmesh.types.BMVert] = []
    ring2: List[bmesh.types.BMVert] = []

    for i in range(segments):
        angle = 2.0 * math.pi * i / segments
        offset = (radial_u * math.cos(angle) + radial_v * math.sin(angle)) * radius
        ring1.append(bm.verts.new(v1 + offset))
        ring2.append(bm.verts.new(v2 + offset))

    faces: List[bmesh.types.BMFace] = []
    for i in range(segments):
        next_i = (i + 1) % segments
        f = bm.faces.new((ring1[i], ring2[i], ring2[next_i], ring1[next_i]))
        f.material_index = mat_index
        f.smooth = smooth
        faces.append(f)

    if cap_start:
        f_start = bm.faces.new(list(reversed(ring1)))
        f_start.material_index = mat_index
        f_start.smooth = False
        faces.append(f_start)

    if cap_end:
        f_end = bm.faces.new(ring2)
        f_end.material_index = mat_index
        f_end.smooth = False
        faces.append(f_end)

    return faces


def add_wheel_assembly(
    bm: bmesh.types.BMesh,
    center: Tuple[float, float, float],
    radius: float = 0.32,
    width: float = 0.22,
    mat_tire: int = 0,
    mat_rim: int = 1,
    segments: int = 12,
    axis_along_x: bool = True,
) -> List[bmesh.types.BMFace]:
    """
    Constructs a stylized vehicle wheel with rubber tire, alloy rim, and brake hub.
    """
    cx, cy, cz = center
    hw = width * 0.5
    rim_r = radius * 0.65
    faces: List[bmesh.types.BMFace] = []

    # Two circular rings for outer tire profile
    if axis_along_x:
        p1 = (cx - hw, cy, cz)
        p2 = (cx + hw, cy, cz)
    else:
        p1 = (cx, cy - hw, cz)
        p2 = (cx, cy + hw, cz)

    # Outer tire tread
    faces.extend(add_cylinder_between(bm, p1, p2, radius, segments, mat_tire, cap_start=True, cap_end=True, smooth=True))
    # Alloy rim insert (recessed slightly)
    if axis_along_x:
        p_rim1 = (cx - hw * 0.85, cy, cz)
        p_rim2 = (cx + hw * 0.85, cy, cz)
    else:
        p_rim1 = (cx, cy - hw * 0.85, cz)
        p_rim2 = (cx, cy + hw * 0.85, cz)
    faces.extend(add_cylinder_between(bm, p_rim1, p_rim2, rim_r, segments, mat_rim, cap_start=True, cap_end=True, smooth=False))

    return faces


def add_mini_bicycle_mesh(
    bm: bmesh.types.BMesh,
    origin: Tuple[float, float, float],
    scale: float = 1.0,
    mat_frame: int = 0,
    mat_components: int = 1,
    mat_wheels: int = 2,
    facing_forward: bool = True,
) -> List[bmesh.types.BMFace]:
    """
    Builds a clean mid-poly road racing bicycle mesh to mount on the team car roof rack:
    includes diamond aero frame, fork, wheels, drop handlebars, saddle, and crankset.
    """
    ox, oy, oz = origin
    dir_y = 1.0 if facing_forward else -1.0
    r_tube = 0.014 * scale
    faces: List[bmesh.types.BMFace] = []

    # Wheel centers (wheelbase ~1.0m, wheel radius ~0.33m)
    wb = 0.98 * scale
    r_wheel = 0.33 * scale
    rear_hub = (ox, oy - wb * 0.5 * dir_y, oz + r_wheel)
    front_hub = (ox, oy + wb * 0.5 * dir_y, oz + r_wheel)

    # Bottom bracket (BB)
    bb = (ox, oy - 0.08 * dir_y * scale, oz + 0.28 * scale)
    # Seat cluster (junction of top tube and seat tube)
    seat_cluster = (ox, oy - 0.20 * dir_y * scale, oz + 0.72 * scale)
    # Head tube bottom & top
    head_bot = (ox, oy + 0.35 * dir_y * scale, oz + 0.65 * scale)
    head_top = (ox, oy + 0.32 * dir_y * scale, oz + 0.76 * scale)

    # 1. Wheels (Rear & Front)
    faces.extend(add_cylinder_between(bm, (ox - 0.015, rear_hub[1], rear_hub[2]),
                                     (ox + 0.015, rear_hub[1], rear_hub[2]), r_wheel, 12, mat_wheels, True, True))
    faces.extend(add_cylinder_between(bm, (ox - 0.015, front_hub[1], front_hub[2]),
                                     (ox + 0.015, front_hub[1], front_hub[2]), r_wheel, 12, mat_wheels, True, True))

    # 2. Frame Tubes (Diamond Geometry)
    # Down tube: BB to head_bot
    faces.extend(add_cylinder_between(bm, bb, head_bot, r_tube * 1.2, 6, mat_frame))
    # Top tube: seat_cluster to head_top
    faces.extend(add_cylinder_between(bm, seat_cluster, head_top, r_tube, 6, mat_frame))
    # Seat tube: BB to seat_cluster
    faces.extend(add_cylinder_between(bm, bb, seat_cluster, r_tube, 6, mat_frame))
    # Seatstays: seat_cluster to rear_hub
    faces.extend(add_cylinder_between(bm, seat_cluster, (ox - 0.04, rear_hub[1], rear_hub[2]), r_tube * 0.8, 6, mat_frame))
    faces.extend(add_cylinder_between(bm, seat_cluster, (ox + 0.04, rear_hub[1], rear_hub[2]), r_tube * 0.8, 6, mat_frame))
    # Chainstays: BB to rear_hub
    faces.extend(add_cylinder_between(bm, bb, (ox - 0.04, rear_hub[1], rear_hub[2]), r_tube * 0.8, 6, mat_frame))
    faces.extend(add_cylinder_between(bm, bb, (ox + 0.04, rear_hub[1], rear_hub[2]), r_tube * 0.8, 6, mat_frame))
    # Head tube
    faces.extend(add_cylinder_between(bm, head_bot, head_top, r_tube * 1.3, 6, mat_frame))
    # Fork blades: head_bot to front_hub
    faces.extend(add_cylinder_between(bm, head_bot, (ox - 0.04, front_hub[1], front_hub[2]), r_tube * 0.8, 6, mat_frame))
    faces.extend(add_cylinder_between(bm, head_bot, (ox + 0.04, front_hub[1], front_hub[2]), r_tube * 0.8, 6, mat_frame))

    # 3. Cockpit & Saddle
    # Stem & Handlebars
    stem_end = (ox, head_top[1] + 0.08 * dir_y * scale, head_top[2] + 0.03 * scale)
    faces.extend(add_cylinder_between(bm, head_top, stem_end, r_tube, 6, mat_components))
    # Drop handlebar cross-bar
    faces.extend(add_cylinder_between(bm, (ox - 0.18 * scale, stem_end[1], stem_end[2]),
                                     (ox + 0.18 * scale, stem_end[1], stem_end[2]), r_tube * 0.9, 6, mat_components))
    # Seatpost & Saddle
    saddle_pos = (ox, seat_cluster[1] - 0.03 * dir_y * scale, seat_cluster[2] + 0.12 * scale)
    faces.extend(add_cylinder_between(bm, seat_cluster, saddle_pos, r_tube * 0.9, 6, mat_components))
    faces.extend(add_box(bm, center=(saddle_pos[0], saddle_pos[1], saddle_pos[2] + 0.02 * scale),
                         size=(0.10 * scale, 0.24 * scale, 0.035 * scale), mat_index=mat_components))

    # 4. Crankset (chainring box at BB)
    faces.extend(add_box(bm, center=(ox + 0.04 * scale, bb[1], bb[2]),
                         size=(0.02 * scale, 0.14 * scale, 0.14 * scale), mat_index=mat_components))

    return faces


# =============================================================================
# PBR MATERIAL FACTORIES FOR VEHICLES & GEAR
# =============================================================================

def create_car_paint_material(
    hex_color: str = "#1E3A8A",
    name: str = "M_Car_Paint_Team",
) -> bpy.types.Material:
    """High-gloss metallic automotive paint with deep clearcoat."""
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)
    sm._set_bsdf_socket(bsdf, ["Base Color"], sm.hex_to_linear_rgb(hex_color))
    sm._set_bsdf_socket(bsdf, ["Metallic"], 0.80)
    sm._set_bsdf_socket(bsdf, ["Roughness"], 0.18)
    sm._set_bsdf_socket(bsdf, ["Clearcoat", "Coat Weight"], 0.75)
    sm._set_bsdf_socket(bsdf, ["Clearcoat Roughness", "Coat Roughness"], 0.10)
    return mat


def create_vehicle_glass_material(
    name: str = "M_Vehicle_Glass_Tinted",
) -> bpy.types.Material:
    """Dark tinted automotive privacy glass with reflection."""
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)
    sm._set_bsdf_socket(bsdf, ["Base Color"], sm.hex_to_linear_rgb("#0F172A"))
    sm._set_bsdf_socket(bsdf, ["Metallic"], 0.15)
    sm._set_bsdf_socket(bsdf, ["Roughness"], 0.08)
    sm._set_bsdf_socket(bsdf, ["Specular IOR Level", "Specular"], 0.90)
    return mat


def create_vehicle_trim_black_material(
    name: str = "M_Vehicle_Trim_Black",
) -> bpy.types.Material:
    """Matte dark charcoal plastic for bumpers, sills, and motorcycle body."""
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)
    sm._set_bsdf_socket(bsdf, ["Base Color"], sm.hex_to_linear_rgb("#1F2937"))
    sm._set_bsdf_socket(bsdf, ["Metallic"], 0.0)
    sm._set_bsdf_socket(bsdf, ["Roughness"], 0.65)
    return mat


def create_headlight_material(
    name: str = "M_Headlight_LED",
) -> bpy.types.Material:
    """Bright emissive xenon/LED vehicle headlight material."""
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)
    sm._set_bsdf_socket(bsdf, ["Base Color"], (0.95, 0.98, 1.0, 1.0))
    sm._set_bsdf_socket(bsdf, ["Emission Color", "Emission"], (1.0, 1.0, 1.0, 1.0))
    sm._set_bsdf_socket(bsdf, ["Emission Strength"], 3.5)
    sm._set_bsdf_socket(bsdf, ["Roughness"], 0.10)
    return mat


def create_taillight_material(
    name: str = "M_Taillight_Red",
) -> bpy.types.Material:
    """Emissive ruby red automotive taillight material."""
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)
    sm._set_bsdf_socket(bsdf, ["Base Color"], sm.hex_to_linear_rgb("#DC2626"))
    sm._set_bsdf_socket(bsdf, ["Emission Color", "Emission"], sm.hex_to_linear_rgb("#DC2626"))
    sm._set_bsdf_socket(bsdf, ["Emission Strength"], 3.0)
    sm._set_bsdf_socket(bsdf, ["Roughness"], 0.15)
    return mat


def create_strobe_beacon_material(
    hex_color: str = "#F59E0B",
    name: str = "M_Strobe_Beacon_Amber",
) -> bpy.types.Material:
    """Glowing roof beacon caution strobe light."""
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)
    sm._set_bsdf_socket(bsdf, ["Base Color"], sm.hex_to_linear_rgb(hex_color))
    sm._set_bsdf_socket(bsdf, ["Emission Color", "Emission"], sm.hex_to_linear_rgb(hex_color))
    sm._set_bsdf_socket(bsdf, ["Emission Strength"], 4.5)
    sm._set_bsdf_socket(bsdf, ["Roughness"], 0.20)
    return mat


def create_chrome_alloy_material(
    name: str = "M_Chrome_Alloy",
) -> bpy.types.Material:
    """Mirror-like chrome alloy for wheel rims and exhaust tips."""
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)
    sm._set_bsdf_socket(bsdf, ["Base Color"], sm.hex_to_linear_rgb("#E2E8F0"))
    sm._set_bsdf_socket(bsdf, ["Metallic"], 0.95)
    sm._set_bsdf_socket(bsdf, ["Roughness"], 0.12)
    return mat


def create_pilot_vest_material(
    hex_color: str = "#FACC15",
    name: str = "M_Pilot_HighVis_Vest",
) -> bpy.types.Material:
    """Fluorescent official pilot safety vest with high reflectivity."""
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)
    sm._set_bsdf_socket(bsdf, ["Base Color"], sm.hex_to_linear_rgb(hex_color))
    sm._set_bsdf_socket(bsdf, ["Metallic"], 0.0)
    sm._set_bsdf_socket(bsdf, ["Roughness"], 0.50)
    return mat


# =============================================================================
# 1. GENERATE TEAM CAR (Kombi z 6 Rowerami) (`vehicle_team_car.glb`)
# =============================================================================

def generate_team_car_mesh(
    name: str = "Vehicle_Team_Car",
    team_color_hex: str = "#1E3A8A",
) -> bpy.types.Object:
    """
    Procedurally constructs a professional Grand Tour Directeur Sportif station
    wagon (Team Car) with:
      - 4.80m length, 1.84m width, 1.44m roof height (estate/kombi wagon body)
      - Front bumper, grille, hood, raked windshield, rear tailgate, tinted windows
      - 4 alloy wheels with disc brakes and rubber tires
      - Roof-mounted heavy-duty aluminum tubular bike rack platform
      - 6 complete road racing bicycles mounted in fork clamps (alternating orientation)
      - 4 vertical spare wheelset carriers holding carbon wheels with disc rotors
      - Amber caution strobe beacon, dual radio communication antennas, team door decals
    """
    mesh = bpy.data.meshes.new(f"{name}_Data")
    obj = bpy.data.objects.new(name, mesh)
    if obj.name not in bpy.context.scene.collection.objects:
        bpy.context.scene.collection.objects.link(obj)
    bm = bmesh.new()

    # Materials:
    # 0: Car Paint (Team Color, default Navy #1E3A8A)
    # 1: Vehicle Glass Tinted
    # 2: Vehicle Trim Black
    # 3: Headlight LED
    # 4: Taillight Red
    # 5: Strobe Beacon Amber
    # 6: Chrome Alloy / Silver Rack
    # 7: Tire Rubber
    # 8: Sponsor Accent Gold / White
    mat_paint = create_car_paint_material(team_color_hex)
    mat_glass = create_vehicle_glass_material()
    mat_trim = create_vehicle_trim_black_material()
    mat_headlight = create_headlight_material()
    mat_taillight = create_taillight_material()
    mat_beacon = create_strobe_beacon_material("#F59E0B")
    mat_chrome = create_chrome_alloy_material()
    mat_rubber = sm.create_tire_rubber_material(tan_wall=False)
    mat_sponsor = sm._get_or_create_material("M_Team_Sponsor_Gold")
    sm._set_bsdf_socket(sm._get_or_create_output_nodes(mat_sponsor)[0], ["Base Color"], sm.hex_to_linear_rgb("#FACC15"))

    for m in [
        mat_paint, mat_glass, mat_trim, mat_headlight,
        mat_taillight, mat_beacon, mat_chrome, mat_rubber, mat_sponsor,
    ]:
        obj.data.materials.append(m)

    # Dimensions
    car_len = 4.80
    car_wid = 1.84
    hw = car_wid * 0.5
    wheel_r = 0.32
    wheel_w = 0.22
    wb_half = 1.42  # Wheelbase 2.84m
    axle_z = wheel_r

    # 1. Lower Chassis & Floorpan
    add_box(bm, center=(0.0, 0.0, 0.28), size=(car_wid - 0.10, car_len - 0.20, 0.18), mat_index=2)

    # 2. Main Vehicle Body (Kombi / Estate Car Lower Beltline)
    # Lower body sill to window beltline (Z: 0.35 to 0.90m)
    add_box(bm, center=(0.0, 0.0, 0.62), size=(car_wid, car_len, 0.54), mat_index=0)

    # Front hood / bonnet (sloping down from windshield to front grille)
    add_box(bm, center=(0.0, 1.45, 0.80), size=(car_wid - 0.06, 1.60, 0.22), mat_index=0)
    # Front radiator grille & bumper
    add_box(bm, center=(0.0, 2.38, 0.54), size=(1.40, 0.08, 0.28), mat_index=2)
    # Front team number plaque / license plate ("DS 1")
    add_box(bm, center=(0.0, 2.42, 0.44), size=(0.55, 0.02, 0.14), mat_index=8)

    # Rear bumper & tailgate lip
    add_box(bm, center=(0.0, -2.38, 0.52), size=(car_wid - 0.04, 0.08, 0.32), mat_index=2)
    # Dual exhaust tips
    for ex_x in [-0.60, 0.60]:
        add_cylinder_between(bm, (ex_x, -2.36, 0.24), (ex_x, -2.44, 0.24), 0.04, 8, 6)

    # 3. Estate Wagon Greenhouse (Cabin, Windshield, Roof, Windows)
    # Cabin glass volume: raked windshield at front, flat roof, raked tailgate at rear
    cabin_w = car_wid - 0.14
    cabin_len = 2.85
    cabin_z = 1.18
    # Dark tinted glass cabin block
    add_box(bm, center=(0.0, -0.45, cabin_z), size=(cabin_w, cabin_len, 0.52), mat_index=1)
    # Metal roof panel above glass
    add_box(bm, center=(0.0, -0.55, 1.44), size=(cabin_w - 0.08, 2.65, 0.06), mat_index=0)
    # Raked front windshield glass slope
    add_box(bm, center=(0.0, 0.70, 1.10), size=(cabin_w - 0.04, 0.55, 0.42), mat_index=1)
    # Raked rear tailgate window slope
    add_box(bm, center=(0.0, -1.95, 1.12), size=(cabin_w - 0.04, 0.45, 0.40), mat_index=1)

    # Roof rails (silver tubular rails along roof sides)
    for rx in [-cabin_w * 0.44, cabin_w * 0.44]:
        add_cylinder_between(bm, (rx, -1.80, 1.48), (rx, 0.60, 1.48), 0.016, 8, 6)

    # 4. Headlights & Taillights
    # Front aerodynamic LED headlights
    for hx in [-hw + 0.18, hw - 0.18]:
        add_box(bm, center=(hx, 2.36, 0.76), size=(0.32, 0.08, 0.16), mat_index=3)
    # Rear wrap-around LED taillight clusters
    for tx in [-hw + 0.18, hw - 0.18]:
        add_box(bm, center=(tx, -2.37, 0.78), size=(0.32, 0.08, 0.18), mat_index=4)

    # 5. Side Mirrors & Door Decals
    for mx in [-hw - 0.10, hw + 0.10]:
        add_box(bm, center=(mx, 0.65, 0.96), size=(0.18, 0.12, 0.09), mat_index=0)
    # Team sponsor branding banners on side doors
    add_box(bm, center=(-hw - 0.005, -0.20, 0.68), size=(0.01, 1.60, 0.28), mat_index=8)
    add_box(bm, center=(hw + 0.005, -0.20, 0.68), size=(0.01, 1.60, 0.28), mat_index=8)

    # 6. 4 Wheels (Front & Rear)
    wheel_coords = [
        (-hw + 0.08, wb_half, axle_z),   # Front Left
        (hw - 0.08, wb_half, axle_z),    # Front Right
        (-hw + 0.08, -wb_half, axle_z),  # Rear Left
        (hw - 0.08, -wb_half, axle_z),   # Rear Right
    ]
    for wc in wheel_coords:
        add_wheel_assembly(bm, center=wc, radius=wheel_r, width=wheel_w, mat_tire=7, mat_rim=6, segments=12, axis_along_x=True)

    # =========================================================================
    # ROOF RACK & 6 COMPLETE SPARE BICYCLES + SPARE WHEELSETS
    # =========================================================================
    rack_z = 1.52
    rack_w = 1.38
    rack_l = 2.25
    hrw = rack_w * 0.5
    hrl = rack_l * 0.5
    r_rack_bar = 0.016

    # 1. Aluminum Tubular Roof Rack Platform
    # 4 cross-mount feet attaching rack to car roof rails
    for fx in [-hrw, hrw]:
        for fy in [-0.85, 0.50]:
            add_cylinder_between(bm, (fx, fy, 1.45), (fx, fy, rack_z), r_rack_bar, 6, 6)

    # Outer perimeter frame of the roof rack
    add_cylinder_between(bm, (-hrw, -hrl, rack_z), (hrw, -hrl, rack_z), r_rack_bar, 6, 6)
    add_cylinder_between(bm, (-hrw, hrl, rack_z), (hrw, hrl, rack_z), r_rack_bar, 6, 6)
    add_cylinder_between(bm, (-hrw, -hrl, rack_z), (-hrw, hrl, rack_z), r_rack_bar, 6, 6)
    add_cylinder_between(bm, (hrw, -hrl, rack_z), (hrw, hrl, rack_z), r_rack_bar, 6, 6)
    # Center longitudinal spine & transverse cross-bars
    add_cylinder_between(bm, (0.0, -hrl, rack_z), (0.0, hrl, rack_z), r_rack_bar, 6, 6)
    add_cylinder_between(bm, (-hrw, 0.0, rack_z), (hrw, 0.0, rack_z), r_rack_bar, 6, 6)

    # 2. Six Complete Spare Road Racing Bicycles
    # Positioned across the width of the rack at 6 distinct slots:
    # Slot X: -0.52, -0.31, -0.10, +0.10, +0.31, +0.52
    # Alternating facing forward / facing rearward to prevent handlebar entanglement
    bike_x_slots = [-0.52, -0.31, -0.10, 0.10, 0.31, 0.52]
    for idx, bx in enumerate(bike_x_slots):
        facing_fwd = (idx % 2 == 0)
        # Small stagger in Y for handlebars
        stag_y = 0.06 if facing_fwd else -0.06
        add_mini_bicycle_mesh(
            bm,
            origin=(bx, -0.55 + stag_y, rack_z + 0.02),
            scale=0.92,
            mat_frame=0,        # Team livery frame paint
            mat_components=2,   # Black matte carbon cockpit & saddle
            mat_wheels=7,       # Black rubber / carbon wheels
            facing_forward=facing_fwd,
        )

    # 3. Four Spare Carbon Wheelsets Mounted Vertically on Masts
    # Placed on outer wings (Front: X = +/-0.62, Y = 0.50; Rear: X = +/-0.62, Y = -1.00)
    spare_wheel_coords = [
        (-0.64, 0.45, rack_z + 0.38),
        (0.64, 0.45, rack_z + 0.38),
        (-0.64, -1.05, rack_z + 0.38),
        (0.64, -1.05, rack_z + 0.38),
    ]
    for sw in spare_wheel_coords:
        # Vertical mounting clamp mast
        add_cylinder_between(bm, (sw[0], sw[1], rack_z), (sw[0], sw[1], sw[2]), 0.012, 6, 6)
        # Spare 50mm carbon wheel with tire
        add_cylinder_between(bm, (sw[0] - 0.02, sw[1], sw[2]), (sw[0] + 0.02, sw[1], sw[2]), 0.32, 12, 7, True, True)
        # Disc brake rotor
        add_cylinder_between(bm, (sw[0] + 0.025, sw[1], sw[2]), (sw[0] + 0.035, sw[1], sw[2]), 0.08, 8, 6, True, True)

    # 4. Communications & Safety Gear
    # Amber caution roof strobe beacon light bar on front crossbar
    add_box(bm, center=(0.0, hrl - 0.10, rack_z + 0.08), size=(0.48, 0.12, 0.07), mat_index=5)
    # Dual flexible radio communication whip antennas
    for ant_x in [-0.25, 0.25]:
        add_cylinder_between(bm, (ant_x, -hrl + 0.10, rack_z), (ant_x, -hrl + 0.10, rack_z + 0.85), 0.005, 4, 6)

    bm.to_mesh(mesh)
    bm.free()
    sm.apply_zwift_style(obj, auto_smooth_angle_deg=35.0)
    return obj


# =============================================================================
# 2. GENERATE TV CAMERA MOTORCYCLE (`vehicle_moto_tv.glb`)
# =============================================================================

def generate_moto_tv_mesh(
    name: str = "Vehicle_Moto_TV",
    is_commissaire: bool = False,
) -> bpy.types.Object:
    """
    Procedurally constructs a professional Grand Tour Race Motorcycle:
      - Touring motorcycle chassis with aerodynamic fairing, engine, wheels, and panniers
      - Official pilot in helmet and high-visibility vest at the handlebars
      - If TV: professional TV cameraman seated facing backwards holding a broadcast
        shoulder camera with zoom lens & microphone blimp, plus microwave relay antenna
      - If Commissaire: race commissaire holding the official timekeeper chalkboard
        ("ÉCART: +1'45""), safety strobe light, and official race pennant flag
    """
    mesh = bpy.data.meshes.new(f"{name}_Data")
    obj = bpy.data.objects.new(name, mesh)
    if obj.name not in bpy.context.scene.collection.objects:
        bpy.context.scene.collection.objects.link(obj)
    bm = bmesh.new()

    # Materials:
    # 0: Moto Fairing Body (TV: Navy/Charcoal #1E293B, Commissaire: Tour White #F8FAFC)
    # 1: High-Vis Pilot Vest (Yellow #FACC15)
    # 2: Dark Trim / Engine Block Black (#1F2937)
    # 3: Headlight LED White
    # 4: Taillight / Strobe Red (#DC2626)
    # 5: Chrome Exhaust / Forks
    # 6: Tire Rubber
    # 7: Camera / Equipment Matte Black
    # 8: Accent Gold / Timeboard Chalk (#FACC15 / #FFFFFF)
    body_hex = "#F8FAFC" if is_commissaire else "#1E293B"
    mat_body = create_car_paint_material(body_hex, name="M_Moto_Body")
    mat_vest = create_pilot_vest_material("#FACC15")
    mat_trim = create_vehicle_trim_black_material()
    mat_headlight = create_headlight_material()
    mat_taillight = create_taillight_material()
    mat_chrome = create_chrome_alloy_material()
    mat_rubber = sm.create_tire_rubber_material(tan_wall=False)
    mat_cam = sm._get_or_create_material("M_Camera_Gear")
    sm._set_bsdf_socket(sm._get_or_create_output_nodes(mat_cam)[0], ["Base Color"], sm.hex_to_linear_rgb("#0F172A"))
    sm._set_bsdf_socket(sm._get_or_create_output_nodes(mat_cam)[0], ["Roughness"], 0.60)

    accent_hex = "#FACC15" if not is_commissaire else "#DC2626"
    mat_accent = sm._get_or_create_material(f"M_Moto_Accent_{'Yellow' if not is_commissaire else 'Red'}")
    sm._set_bsdf_socket(sm._get_or_create_output_nodes(mat_accent)[0], ["Base Color"], sm.hex_to_linear_rgb(accent_hex))
    sm._set_bsdf_socket(sm._get_or_create_output_nodes(mat_accent)[0], ["Roughness"], 0.35)

    for m in [
        mat_body, mat_vest, mat_trim, mat_headlight,
        mat_taillight, mat_chrome, mat_rubber, mat_cam, mat_accent,
    ]:
        obj.data.materials.append(m)

    # Motorcycle Dimensions
    wheel_r = 0.31
    tire_w = 0.14
    wb_half = 0.72  # Wheelbase 1.44m
    axle_z = wheel_r

    # 1. Front and Rear Wheels
    # Front wheel at Y = +wb_half, Rear wheel at Y = -wb_half
    add_wheel_assembly(bm, center=(0.0, wb_half, axle_z), radius=wheel_r, width=tire_w, mat_tire=6, mat_rim=5, segments=12, axis_along_x=True)
    add_wheel_assembly(bm, center=(0.0, -wb_half, axle_z), radius=wheel_r, width=tire_w, mat_tire=6, mat_rim=5, segments=12, axis_along_x=True)

    # 2. Telescopic Front Forks & Fender
    fork_r = 0.024
    head_pos = (0.0, 0.48, 0.88)
    for fx in [-0.11, 0.11]:
        add_cylinder_between(bm, (fx, wb_half, axle_z), (fx, head_pos[1], head_pos[2]), fork_r, 6, 5)
    # Front fender / mudguard
    add_box(bm, center=(0.0, wb_half + 0.05, axle_z + wheel_r + 0.03), size=(0.18, 0.40, 0.04), mat_index=0)

    # 3. Motorcycle Engine Block, Frame, and Chrome Exhaust
    # Boxer/Inline engine block under tank
    add_box(bm, center=(0.0, 0.05, 0.38), size=(0.42, 0.55, 0.35), mat_index=2)
    # Cylinders protruding horizontally
    for side_x in [-0.28, 0.28]:
        add_box(bm, center=(side_x, 0.05, 0.38), size=(0.18, 0.25, 0.22), mat_index=5)
    # Chrome exhaust header and muffler
    add_cylinder_between(bm, (0.18, 0.0, 0.28), (0.24, -wb_half - 0.20, 0.32), 0.045, 8, 5)

    # 4. Main Body Fairing, Fuel Tank, and Tinted Windscreen
    # Sculpted fuel tank
    add_box(bm, center=(0.0, 0.22, 0.76), size=(0.46, 0.58, 0.30), mat_index=0)
    # Front aerodynamic fairing
    add_box(bm, center=(0.0, 0.55, 0.85), size=(0.58, 0.42, 0.42), mat_index=0)
    # Dual LED headlights
    for hx in [-0.14, 0.14]:
        add_box(bm, center=(hx, 0.76, 0.85), size=(0.12, 0.04, 0.10), mat_index=3)
    # Tall touring windscreen
    add_box(bm, center=(0.0, 0.52, 1.15), size=(0.42, 0.12, 0.32), mat_index=0)

    # Handlebars & Handguards
    hb_z = 0.98
    add_cylinder_between(bm, (-0.38, 0.38, hb_z), (0.38, 0.38, hb_z), 0.016, 6, 5)
    for hbx in [-0.38, 0.38]:
        add_box(bm, center=(hbx, 0.42, hb_z), size=(0.08, 0.06, 0.06), mat_index=2)
        # Rearview mirror stems & mirrors
        add_cylinder_between(bm, (hbx, 0.38, hb_z), (hbx, 0.42, hb_z + 0.12), 0.008, 4, 5)
        add_box(bm, center=(hbx, 0.42, hb_z + 0.14), size=(0.09, 0.02, 0.06), mat_index=2)

    # Footpegs for rider and pillion passenger
    for side_x in [-0.26, 0.26]:
        # Pilot footpeg
        add_cylinder_between(bm, (side_x * 0.6, 0.05, 0.28), (side_x, 0.05, 0.28), 0.015, 6, 5)
        # Pillion passenger footpeg
        add_cylinder_between(bm, (side_x * 0.6, -0.45, 0.32), (side_x, -0.45, 0.32), 0.015, 6, 5)

    # 5. Dual Seat & Hard Side Panniers
    # Rider & pillion seat
    add_box(bm, center=(0.0, -0.22, 0.72), size=(0.34, 0.75, 0.12), mat_index=2)
    # Hard touring side panniers (saddlebags)
    for pan_x in [-0.32, 0.32]:
        add_box(bm, center=(pan_x, -wb_half + 0.10, 0.58), size=(0.20, 0.56, 0.36), mat_index=0)
        # Red reflector on rear of pannier
        add_box(bm, center=(pan_x, -wb_half - 0.19, 0.58), size=(0.12, 0.02, 0.08), mat_index=4)

    # =========================================================================
    # RIDERS (PILOT & PASSENGER)
    # =========================================================================

    # 1. Motorcycle Pilot (Sitting in front, hands on handlebars)
    # Pilot Torso (wearing high-vis safety vest)
    pilot_torso = (0.0, 0.05, 1.05)
    add_box(bm, center=pilot_torso, size=(0.38, 0.28, 0.44), mat_index=1)
    # Pilot Legs down to footpegs
    add_cylinder_between(bm, (-0.16, 0.05, 0.85), (-0.24, 0.05, 0.30), 0.055, 6, 2)
    add_cylinder_between(bm, (0.16, 0.05, 0.85), (0.24, 0.05, 0.30), 0.055, 6, 2)
    # Pilot Arms reaching to handlebars
    add_cylinder_between(bm, (-0.19, 0.05, 1.15), (-0.32, 0.38, hb_z), 0.045, 6, 1)
    add_cylinder_between(bm, (0.19, 0.05, 1.15), (0.32, 0.38, hb_z), 0.045, 6, 1)
    # Pilot Helmet (full face helmet)
    pilot_head = (0.0, 0.10, 1.38)
    add_box(bm, center=pilot_head, size=(0.24, 0.26, 0.26), mat_index=0)
    # Dark visor
    add_box(bm, center=(0.0, 0.24, 1.38), size=(0.22, 0.04, 0.09), mat_index=2)

    # 2. Pillion Passenger (TV Cameraman or Race Commissaire)
    if not is_commissaire:
        # ---------------------------------------------------------------------
        # TV CAMERAMAN: Facing backwards pointing camera at the peloton!
        # ---------------------------------------------------------------------
        cam_torso = (0.0, -0.42, 1.08)
        # Cameraman torso (facing -Y)
        add_box(bm, center=cam_torso, size=(0.38, 0.28, 0.44), mat_index=2)
        # Cameraman Legs down to rear footpegs
        add_cylinder_between(bm, (-0.16, -0.42, 0.85), (-0.24, -0.45, 0.34), 0.055, 6, 2)
        add_cylinder_between(bm, (0.16, -0.42, 0.85), (0.24, -0.45, 0.34), 0.055, 6, 2)
        # Cameraman Helmet
        cam_head = (0.0, -0.42, 1.40)
        add_box(bm, center=cam_head, size=(0.24, 0.26, 0.26), mat_index=2)
        add_box(bm, center=(0.0, -0.56, 1.40), size=(0.22, 0.04, 0.09), mat_index=0)

        # Cameraman Arms holding the camera
        add_cylinder_between(bm, (0.18, -0.42, 1.18), (0.14, -0.62, 1.28), 0.045, 6, 2)
        add_cylinder_between(bm, (-0.18, -0.42, 1.18), (0.06, -0.72, 1.30), 0.045, 6, 2)

        # Professional ENG Broadcast Shoulder Camera
        # Held on cameraman's shoulder pointing backwards towards -Y
        cam_body_pos = (0.12, -0.65, 1.32)
        add_box(bm, center=cam_body_pos, size=(0.22, 0.38, 0.18), mat_index=7)
        # Telephoto Zoom Lens pointing towards -Y
        add_cylinder_between(bm, (0.12, -0.84, 1.32), (0.12, -1.18, 1.32), 0.055, 8, 7)
        # Lens hood cone
        add_cylinder_between(bm, (0.12, -1.18, 1.32), (0.12, -1.24, 1.32), 0.075, 8, 7)
        # Camera top handle & viewfinder
        add_box(bm, center=(0.12, -0.65, 1.44), size=(0.06, 0.26, 0.05), mat_index=7)
        add_cylinder_between(bm, (0.03, -0.55, 1.35), (0.03, -0.45, 1.35), 0.025, 6, 7)
        # Shotgun microphone windshield blimp
        add_cylinder_between(bm, (0.22, -0.60, 1.42), (0.22, -0.92, 1.42), 0.035, 6, 2)

        # High-Gain Microwave Relay Transmission Antenna (on rear tail)
        ant_pos = (0.0, -wb_half - 0.25, 0.75)
        add_cylinder_between(bm, ant_pos, (0.0, ant_pos[1], 1.75), 0.018, 6, 5)
        # Omnidirectional Radome dome on top
        add_box(bm, center=(0.0, ant_pos[1], 1.82), size=(0.16, 0.16, 0.16), mat_index=0)
        # "TV" marker plate on front windscreen
        add_box(bm, center=(0.0, 0.58, 1.15), size=(0.28, 0.02, 0.14), mat_index=8)

    else:
        # ---------------------------------------------------------------------
        # RACE COMMISSAIRE / TIMEKEEPER (Ardoisier with Time Board)
        # ---------------------------------------------------------------------
        comm_torso = (0.0, -0.38, 1.08)
        add_box(bm, center=comm_torso, size=(0.38, 0.28, 0.44), mat_index=1)
        # Commissaire Legs down to footpegs
        add_cylinder_between(bm, (-0.16, -0.38, 0.85), (-0.24, -0.45, 0.34), 0.055, 6, 2)
        add_cylinder_between(bm, (0.16, -0.38, 0.85), (0.24, -0.45, 0.34), 0.055, 6, 2)
        comm_head = (0.0, -0.38, 1.40)
        add_box(bm, center=comm_head, size=(0.24, 0.26, 0.26), mat_index=0)

        # Commissaire Arms holding chalkboard
        add_cylinder_between(bm, (-0.18, -0.38, 1.18), (-0.22, -0.72, 1.12), 0.045, 6, 1)
        add_cylinder_between(bm, (0.18, -0.38, 1.18), (0.22, -0.72, 1.12), 0.045, 6, 1)

        # Official Time Gap Chalkboard ("ÉCART: +1'45"") held facing backwards
        board_pos = (0.0, -0.75, 1.12)
        add_box(bm, center=board_pos, size=(0.58, 0.03, 0.42), mat_index=7)
        # White time readout text plate on board
        add_box(bm, center=(0.0, -0.77, 1.12), size=(0.48, 0.015, 0.32), mat_index=8)

        # Red safety flashing strobe on tall rear mast
        strobe_mast = (0.18, -wb_half - 0.22, 0.75)
        add_cylinder_between(bm, strobe_mast, (0.18, strobe_mast[1], 1.65), 0.015, 6, 5)
        add_box(bm, center=(0.18, strobe_mast[1], 1.72), size=(0.12, 0.12, 0.14), mat_index=4)
        # Red/white official UCI pennant flag
        add_box(bm, center=(0.18, strobe_mast[1] - 0.12, 1.55), size=(0.01, 0.24, 0.16), mat_index=8)
        # "COMMISSAIRE" marker plaque on windscreen
        add_box(bm, center=(0.0, 0.58, 1.15), size=(0.35, 0.02, 0.14), mat_index=8)

    bm.to_mesh(mesh)
    bm.free()
    sm.apply_zwift_style(obj, auto_smooth_angle_deg=35.0)
    return obj


# =============================================================================
# EXPORT PIPELINE (GLTF 2.0 BINARY)
# =============================================================================

def export_vehicle_asset(
    objects: Union[bpy.types.Object, List[bpy.types.Object]],
    filepath: str,
) -> str:
    """Exports single or multiple vehicle objects to an optimized glTF 2.0 binary file."""
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
        fallback_kwargs = {
            "filepath": filepath,
            "export_format": "GLB",
            "use_selection": True,
            "export_apply": True,
        }
        bpy.ops.export_scene.gltf(**fallback_kwargs)

    size_kb = os.path.getsize(filepath) / 1024.0
    obj_names = [o.name for o in objects]
    print(f"\n[EXPORT] {obj_names} -> '{filepath}' ({size_kb:.1f} KB)")
    return filepath


def export_all_support_vehicles(output_dir: str = "assets/3d/vehicles") -> Dict[str, str]:
    """
    Procedurally models and exports the full suite of cycling race support vehicles
    to glTF 2.0 binary (.glb) files in `output_dir`:

      1. `vehicle_team_car.glb`: Team Car (kombi) with roof rack of 6 bikes & spare wheels.
      2. `vehicle_moto_tv.glb`: TV broadcast camera moto + Commissaire moto.
      3. `vehicle_moto_commissaire.glb`: Standalone official Commissaire / Timekeeper moto.
    """
    # Clean active scene mesh objects
    for obj in list(bpy.context.scene.objects):
        if obj.type == "MESH":
            bpy.data.objects.remove(obj, do_unlink=True)

    print("\n" + "=" * 75)
    print("PRO PELOTON MANAGER: GENERATING RACE SUPPORT VEHICLES")
    print("=" * 75)

    os.makedirs(output_dir, exist_ok=True)
    exported_files: Dict[str, str] = {}

    # -------------------------------------------------------------------------
    # 1. Team Car Kombi (`vehicle_team_car.glb`)
    # -------------------------------------------------------------------------
    obj_team_car = generate_team_car_mesh(name="Vehicle_Team_Car", team_color_hex="#1E3A8A")
    p_team_car = os.path.join(output_dir, "vehicle_team_car.glb")
    exported_files["team_car"] = export_vehicle_asset(obj_team_car, p_team_car)
    bpy.data.objects.remove(obj_team_car, do_unlink=True)

    # -------------------------------------------------------------------------
    # 2. Standalone Commissaire Moto (`vehicle_moto_commissaire.glb`)
    # -------------------------------------------------------------------------
    obj_commissaire = generate_moto_tv_mesh(name="Vehicle_Moto_Commissaire", is_commissaire=True)
    p_comm = os.path.join(output_dir, "vehicle_moto_commissaire.glb")
    exported_files["moto_commissaire"] = export_vehicle_asset(obj_commissaire, p_comm)
    bpy.data.objects.remove(obj_commissaire, do_unlink=True)

    # -------------------------------------------------------------------------
    # 3. TV Camera Moto & Combined Pack (`vehicle_moto_tv.glb`)
    # Contains Moto_TV at X = -1.2m, Moto_Commissaire at X = +1.2m
    # -------------------------------------------------------------------------
    obj_tv_moto = generate_moto_tv_mesh(name="Vehicle_Moto_TV", is_commissaire=False)
    obj_tv_moto.location = (-1.20, 0.0, 0.0)

    obj_comm_comb = generate_moto_tv_mesh(name="Vehicle_Moto_Commissaire_Companion", is_commissaire=True)
    obj_comm_comb.location = (1.20, 0.0, 0.0)

    p_tv = os.path.join(output_dir, "vehicle_moto_tv.glb")
    exported_files["moto_tv"] = export_vehicle_asset([obj_tv_moto, obj_comm_comb], p_tv)
    bpy.data.objects.remove(obj_tv_moto, do_unlink=True)
    bpy.data.objects.remove(obj_comm_comb, do_unlink=True)

    print("=" * 75 + "\n")
    return exported_files


# =============================================================================
# CLI EXECUTION ENTRY POINT
# =============================================================================

if __name__ == "__main__":
    out_dir = "assets/3d/vehicles"
    for idx, arg in enumerate(sys.argv):
        if arg in ["--output-dir", "-o"] and idx + 1 < len(sys.argv):
            out_dir = sys.argv[idx + 1]

    files = export_all_support_vehicles(output_dir=out_dir)
    sm.setup_zwift_studio_lighting()
    print(f"[SUCCESS] All support vehicles generated: {files}")
