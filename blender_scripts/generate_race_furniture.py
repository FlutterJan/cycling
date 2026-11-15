"""
===============================================================================
PRO PELOTON MANAGER - RACE FURNITURE & GRAND TOUR INFRASTRUCTURE GENERATOR
===============================================================================
Blender Python API (bpy) script that procedurally generates 3D race furniture
and Grand Tour course infrastructure building the authentic atmosphere of the
world's greatest cycling races (Tour de France, Giro d'Italia, Vuelta a España):

  1. Metalowe barierki ochronne ze znakami sponsorów (`barrier_finish.glb`):
     - Heavy-duty crowd control barrier (Barrière Vauban / UCI Finish Straight barrier)
     - Modular 2.0m width, 1.05m height, tubular steel frame with rounded corners
     - Splayed stabilizing feet with anti-slip rubber shoes
     - 10 vertical pickets / safety bars with interlocking male/female side latches
     - Double-sided advertising sponsor panel (Bâche publicitaire) with grommets & zip-ties
     - High-visibility safety foam bumper padding along the top rail

  2. Dmuchana brama "Flamme Rouge - 1 KM" oraz brama mety z zegarem (`arch_finish.glb`):
     - Finish Gantry (Brama mety):
       * Heavy-duty 4-chord aluminum box-truss gantry spanning the 7.0m roadbed (8.4m clear span)
       * Diagonal zigzag lattice bracing, ground ballast footing blocks with hazard stripes
       * Official digital timing clock with glowing emissive LED 7-segment display (04:19:32)
       * Overhead photo-finish camera housing pod pointing directly down at the line
       * Double-sided overhead finish banner ("ARRIVÉE / FINISH LINE") with checkered flags
       * Tower jumbotron LED video wall, overhead floodlights, and ground checkered finish line
     - Flamme Rouge (Dmuchana brama 1 KM):
       * Inflatable curved red PVC arch with arched lettering ("1 KM", "FLAMME ROUGE")
       * Legendary suspended red triangular pennant / kite ("1 KM") hanging under the apex
     - Exported combined as `arch_finish.glb` and standalone as `arch_flamme_rouge.glb`.

  3. Bramy premii górskich i lotnych finiszy (`arch_kom_sprint.glb`):
     - Brama Premii Górskiej (KOM - King of the Mountains):
       * Alpine summit arch with iconic red polka dots (pois rouges) on white PVC
       * Summit altitude & category milestone plaque ("COL DU TOURMALET - 2115m - HC")
       * Climber classification points distribution plaque and summit timing transponders
     - Brama Lotnego Finiszu (Intermediate Sprint):
       * Tour sprint green livery (#16A34A) with directional chevron arrows (>>> SPRINT >>>)
       * High-tech speed radar box with glowing LED speed readout ("RADAR 68 KM/H")
       * Points classification breakdown sign
     - Exported combined as `arch_kom_sprint.glb` and standalone as `arch_kom.glb` & `arch_sprint.glb`.

All models conform to the clean, vibrant Zwift/MyWhoosh visual aesthetic (PBR materials,
smooth shading, optimized mid-poly geometry).

Output Directory: `assets/3d/furniture/`
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
    print("        blender --background --python blender_scripts/generate_race_furniture.py")
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

    # 8 corner vertices
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
    # Choose arbitrary orthogonal vector
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


def add_inflatable_arch_mesh(
    bm: bmesh.types.BMesh,
    span: float = 8.0,
    shoulder_height: float = 2.8,
    apex_height: float = 5.0,
    tube_radius: float = 0.34,
    radial_segments: int = 12,
    curve_segments: int = 20,
    mat_index: int = 0,
) -> List[bmesh.types.BMFace]:
    """
    Constructs a smooth, continuous inflatable curved arch spanning between
    -span/2 and +span/2 with vertical legs and a circular/elliptical crown.
    """
    half_span = span * 0.5
    rings: List[List[bmesh.types.BMVert]] = []

    # Construct center-line path of the arch:
    # 1. Left leg (Z: 0.0 -> shoulder_height)
    # 2. Crown curve (from -half_span to +half_span, Z rising to apex_height)
    # 3. Right leg (Z: shoulder_height -> 0.0)
    leg_steps = max(3, int(shoulder_height / 0.8))
    path_points: List[Vector] = []
    path_tangents: List[Vector] = []

    # Left leg points (going up from bottom)
    for i in range(leg_steps):
        t = i / float(leg_steps)
        path_points.append(Vector((-half_span, 0.0, shoulder_height * t)))
        path_tangents.append(Vector((0.0, 0.0, 1.0)))

    # Crown curve (from angle pi to 0)
    crown_radius_x = half_span
    crown_rise_z = apex_height - shoulder_height
    for i in range(curve_segments + 1):
        angle = math.pi - (math.pi * i / curve_segments)
        px = crown_radius_x * math.cos(angle)
        pz = shoulder_height + crown_rise_z * math.sin(angle)
        path_points.append(Vector((px, 0.0, pz)))

        # Tangent vector (derivative of path)
        tx = -crown_radius_x * math.sin(angle)
        tz = crown_rise_z * math.cos(angle)
        path_tangents.append(Vector((tx, 0.0, tz)).normalized())

    # Right leg points (going down to bottom)
    for i in range(1, leg_steps + 1):
        t = 1.0 - (i / float(leg_steps))
        path_points.append(Vector((half_span, 0.0, shoulder_height * t)))
        path_tangents.append(Vector((0.0, 0.0, -1.0)))

    # Generate rings along path
    for p, tang in zip(path_points, path_tangents):
        # Local coordinate system at point
        binormal = Vector((0.0, 1.0, 0.0))  # along Y
        normal = tang.cross(binormal).normalized()
        binormal = normal.cross(tang).normalized()

        ring: List[bmesh.types.BMVert] = []
        for j in range(radial_segments):
            theta = 2.0 * math.pi * j / radial_segments
            offset = (normal * math.cos(theta) + binormal * math.sin(theta)) * tube_radius
            ring.append(bm.verts.new(p + offset))
        rings.append(ring)

    faces: List[bmesh.types.BMFace] = []
    # Loft consecutive rings
    for r in range(len(rings) - 1):
        r1 = rings[r]
        r2 = rings[r + 1]
        for s in range(radial_segments):
            next_s = (s + 1) % radial_segments
            f = bm.faces.new((r1[s], r2[s], r2[next_s], r1[next_s]))
            f.material_index = mat_index
            f.smooth = True
            faces.append(f)

    # Cap bottom rings
    f_bottom_left = bm.faces.new(list(reversed(rings[0])))
    f_bottom_left.material_index = mat_index
    f_bottom_left.smooth = False
    faces.append(f_bottom_left)

    f_bottom_right = bm.faces.new(rings[-1])
    f_bottom_right.material_index = mat_index
    f_bottom_right.smooth = False
    faces.append(f_bottom_right)

    return faces


def add_flamme_rouge_pennant(
    bm: bmesh.types.BMesh,
    apex_center: Tuple[float, float, float] = (0.0, 0.0, 4.6),
    top_width: float = 0.85,
    height: float = 1.05,
    thickness: float = 0.012,
    mat_index: int = 0,
) -> List[bmesh.types.BMFace]:
    """
    Constructs the iconic triangular Flamme Rouge (Red Kite) pennant hanging
    down from the apex of the 1 KM inflatable arch.
    """
    cx, cy, cz = apex_center
    hw = top_width * 0.5
    ht = thickness * 0.5

    # Front triangle vertices
    v_f_tl = bm.verts.new((cx - hw, cy - ht, cz))
    v_f_tr = bm.verts.new((cx + hw, cy - ht, cz))
    v_f_tip = bm.verts.new((cx, cy - ht, cz - height))

    # Back triangle vertices
    v_b_tl = bm.verts.new((cx - hw, cy + ht, cz))
    v_b_tr = bm.verts.new((cx + hw, cy + ht, cz))
    v_b_tip = bm.verts.new((cx, cy + ht, cz - height))

    faces = [
        bm.faces.new((v_f_tl, v_f_tip, v_f_tr)),  # Front face
        bm.faces.new((v_b_tl, v_b_tr, v_b_tip)),  # Back face
        bm.faces.new((v_f_tl, v_f_tr, v_b_tr, v_b_tl)),  # Top edge
        bm.faces.new((v_f_tr, v_f_tip, v_b_tip, v_b_tr)),  # Right edge
        bm.faces.new((v_f_tip, v_f_tl, v_b_tl, v_b_tip)),  # Left edge
    ]
    for f in faces:
        f.material_index = mat_index
        f.smooth = False
    return faces


def add_7segment_digit(
    bm: bmesh.types.BMesh,
    char: str,
    origin: Tuple[float, float, float],
    width: float = 0.16,
    height: float = 0.28,
    depth: float = 0.015,
    thickness: float = 0.028,
    mat_index: int = 0,
) -> List[bmesh.types.BMFace]:
    """
    Builds clean geometric 3D LED segments for digital clock readout characters
    ('0'-'9', ':', '-').
    """
    ox, oy, oz = origin
    faces: List[bmesh.types.BMFace] = []

    # Segment definitions:
    # a: top horizontal
    # b: top-right vertical
    # c: bottom-right vertical
    # d: bottom horizontal
    # e: bottom-left vertical
    # f: top-left vertical
    # g: middle horizontal
    hw = width
    hh = height
    mid_z = oz + hh * 0.5
    top_z = oz + hh
    bot_z = oz
    left_x = ox
    right_x = ox + hw
    mid_x = ox + hw * 0.5

    seg_map = {
        '0': ['a', 'b', 'c', 'd', 'e', 'f'],
        '1': ['b', 'c'],
        '2': ['a', 'b', 'g', 'e', 'd'],
        '3': ['a', 'b', 'g', 'c', 'd'],
        '4': ['f', 'g', 'b', 'c'],
        '5': ['a', 'f', 'g', 'c', 'd'],
        '6': ['a', 'f', 'g', 'e', 'c', 'd'],
        '7': ['a', 'b', 'c'],
        '8': ['a', 'b', 'c', 'd', 'e', 'f', 'g'],
        '9': ['a', 'b', 'c', 'd', 'f', 'g'],
        '-': ['g'],
        ':': ['colon'],
    }

    active_segs = seg_map.get(char, ['g'])

    if 'colon' in active_segs:
        # Dual colon dots
        dot_sz = thickness * 1.1
        f1 = add_box(bm, center=(mid_x, oy, oz + hh * 0.3), size=(dot_sz, depth, dot_sz), mat_index=mat_index)
        f2 = add_box(bm, center=(mid_x, oy, oz + hh * 0.7), size=(dot_sz, depth, dot_sz), mat_index=mat_index)
        return f1 + f2

    seg_boxes = {
        'a': ((mid_x, oy, top_z - thickness * 0.5), (hw, depth, thickness)),
        'b': ((right_x - thickness * 0.5, oy, oz + hh * 0.75), (thickness, depth, hh * 0.5 - thickness)),
        'c': ((right_x - thickness * 0.5, oy, oz + hh * 0.25), (thickness, depth, hh * 0.5 - thickness)),
        'd': ((mid_x, oy, bot_z + thickness * 0.5), (hw, depth, thickness)),
        'e': ((left_x + thickness * 0.5, oy, oz + hh * 0.25), (thickness, depth, hh * 0.5 - thickness)),
        'f': ((left_x + thickness * 0.5, oy, oz + hh * 0.75), (thickness, depth, hh * 0.5 - thickness)),
        'g': ((mid_x, oy, mid_z), (hw, depth, thickness)),
    }

    for seg_key in active_segs:
        if seg_key in seg_boxes:
            c, s = seg_boxes[seg_key]
            faces.extend(add_box(bm, center=c, size=s, mat_index=mat_index))

    return faces


# =============================================================================
# PBR MATERIAL FACTORIES FOR RACE INFRASTRUCTURE
# =============================================================================

def create_aluminum_truss_material(name: str = "M_Truss_Aluminum") -> bpy.types.Material:
    """Semi-matte aluminum alloy truss material with anisotropic metallic luster."""
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)
    sm._set_bsdf_socket(bsdf, ["Base Color"], sm.hex_to_linear_rgb("#CBD5E1"))
    sm._set_bsdf_socket(bsdf, ["Metallic"], 0.90)
    sm._set_bsdf_socket(bsdf, ["Roughness"], 0.26)
    return mat


def create_galvanized_steel_material(name: str = "M_Barrier_Galvanized") -> bpy.types.Material:
    """Galvanized tubular steel crowd barrier material with industrial zinc sheen."""
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)
    sm._set_bsdf_socket(bsdf, ["Base Color"], sm.hex_to_linear_rgb("#94A3B8"))
    sm._set_bsdf_socket(bsdf, ["Metallic"], 0.85)
    sm._set_bsdf_socket(bsdf, ["Roughness"], 0.32)
    return mat


def create_sponsor_banner_material(
    theme: str = "finish_blue",
    name: Optional[str] = None,
) -> bpy.types.Material:
    """
    Creates durable PVC tarpaulin sponsor banner material.
    Themes: 'finish_blue', 'tour_yellow', 'kom_white', 'sprint_green', 'hazard_stripe'.
    """
    colors = {
        "finish_blue": "#1E3A8A",    # Official Tour Navy Blue
        "tour_yellow": "#FACC15",    # Grand Tour Leader Jersey Yellow
        "kom_white": "#F8FAFC",      # Summit Polka Dot Base White
        "sprint_green": "#16A34A",   # Points Classification Sprint Green
        "racing_red": "#DC2626",     # High-contrast Racing Red
        "hazard_stripe": "#EAB308",  # Caution Hazard Yellow
        "screen_black": "#0F172A",   # Display Enclosure Charcoal Black
    }
    hex_col = colors.get(theme, "#1E3A8A")
    mat_name = name or f"M_Sponsor_{theme.capitalize()}"
    mat = sm._get_or_create_material(mat_name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)
    sm._set_bsdf_socket(bsdf, ["Base Color"], sm.hex_to_linear_rgb(hex_col))
    sm._set_bsdf_socket(bsdf, ["Metallic"], 0.0)
    sm._set_bsdf_socket(bsdf, ["Roughness"], 0.42)
    return mat


def create_inflatable_pvc_material(
    hex_color: str = "#DC2626",
    name: str = "M_Inflatable_PVC",
) -> bpy.types.Material:
    """Glossy reinforced PVC vinyl material for inflatable event arches."""
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)
    sm._set_bsdf_socket(bsdf, ["Base Color"], sm.hex_to_linear_rgb(hex_color))
    sm._set_bsdf_socket(bsdf, ["Metallic"], 0.0)
    sm._set_bsdf_socket(bsdf, ["Roughness"], 0.22)
    sm._set_bsdf_socket(bsdf, ["Specular IOR Level", "Specular"], 0.65)
    return mat


def create_digital_clock_led_material(
    hex_color: str = "#22C55E",
    name: str = "M_LED_Clock_Glow",
) -> bpy.types.Material:
    """Emissive LED digital readout material glowing brightly in race broadcast."""
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)
    sm._set_bsdf_socket(bsdf, ["Base Color"], (0.05, 0.05, 0.05, 1.0))
    sm._set_bsdf_socket(bsdf, ["Metallic"], 0.0)
    sm._set_bsdf_socket(bsdf, ["Roughness"], 0.20)
    # Emission sockets (Blender 3.6/4.x/5.x compatibility)
    sm._set_bsdf_socket(bsdf, ["Emission Color", "Emission"], sm.hex_to_linear_rgb(hex_color))
    sm._set_bsdf_socket(bsdf, ["Emission Strength"], 4.5)
    return mat


def create_safety_padding_material(
    hex_color: str = "#FACC15",
    name: str = "M_Safety_Foam_Yellow",
) -> bpy.types.Material:
    """Soft impact-absorbing foam padding for crowd barrier top rails."""
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)
    sm._set_bsdf_socket(bsdf, ["Base Color"], sm.hex_to_linear_rgb(hex_color))
    sm._set_bsdf_socket(bsdf, ["Metallic"], 0.0)
    sm._set_bsdf_socket(bsdf, ["Roughness"], 0.60)
    return mat


def create_rubber_boot_material(name: str = "M_Rubber_Base_Pad") -> bpy.types.Material:
    """Dark matte non-slip rubber boots for barrier feet and footing ballast."""
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)
    sm._set_bsdf_socket(bsdf, ["Base Color"], sm.hex_to_linear_rgb("#1F2937"))
    sm._set_bsdf_socket(bsdf, ["Metallic"], 0.0)
    sm._set_bsdf_socket(bsdf, ["Roughness"], 0.85)
    return mat


def create_polka_dot_material(name: str = "M_KOM_Polka_Dot_Red") -> bpy.types.Material:
    """High-saturation King of the Mountains polka dot red material."""
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)
    sm._set_bsdf_socket(bsdf, ["Base Color"], sm.hex_to_linear_rgb("#DC2626"))
    sm._set_bsdf_socket(bsdf, ["Metallic"], 0.0)
    sm._set_bsdf_socket(bsdf, ["Roughness"], 0.35)
    return mat


# =============================================================================
# 1. GENERATE FINISH CROWD BARRIER (`barrier_finish.glb`)
# =============================================================================

def generate_finish_barrier_mesh(name: str = "Barrier_Finish") -> bpy.types.Object:
    """
    Procedurally constructs a professional UCI Grand Tour crowd safety barrier:
      - 2.0m width along X, 1.05m height along Z, 0.50m foot depth along Y
      - Galvanized tubular perimeter steel frame with rounded corners
      - Two splayed stabilizer feet with anti-slip rubber shoes
      - 10 vertical pickets / safety bars
      - Interlocking side hooks (male pin on left, female loop on right)
      - Double-sided advertising sponsor panel with corner eyelets & zip-ties
      - High-vis protective safety foam bumper padding along the top rail
    """
    mesh = bpy.data.meshes.new(f"{name}_Data")
    obj = bpy.data.objects.new(name, mesh)
    if obj.name not in bpy.context.scene.collection.objects:
        bpy.context.scene.collection.objects.link(obj)
    bm = bmesh.new()

    # Materials:
    # 0: Galvanized Steel
    # 1: Sponsor Banner Navy
    # 2: Sponsor Accent Yellow
    # 3: Safety Foam Yellow
    # 4: Rubber Base Pad
    mat_steel = create_galvanized_steel_material()
    mat_banner_navy = create_sponsor_banner_material("finish_blue")
    mat_banner_gold = create_sponsor_banner_material("tour_yellow")
    mat_foam = create_safety_padding_material("#FACC15")
    mat_rubber = create_rubber_boot_material()

    obj.data.materials.append(mat_steel)        # Index 0
    obj.data.materials.append(mat_banner_navy)  # Index 1
    obj.data.materials.append(mat_banner_gold)  # Index 2
    obj.data.materials.append(mat_foam)         # Index 3
    obj.data.materials.append(mat_rubber)       # Index 4

    # Dimensions
    barrier_w = 2.0
    barrier_h = 1.05
    half_w = barrier_w * 0.5
    tube_r = 0.019  # ~38mm outer diameter pipe
    bot_rail_z = 0.16
    top_rail_z = 1.03
    picket_r = 0.008

    # 1. Outer perimeter tubular frame
    # Bottom rail
    add_cylinder_between(bm, (-half_w + 0.06, 0.0, bot_rail_z), (half_w - 0.06, 0.0, bot_rail_z), tube_r, 8, 0)
    # Top rail
    add_cylinder_between(bm, (-half_w + 0.08, 0.0, top_rail_z), (half_w - 0.08, 0.0, top_rail_z), tube_r, 8, 0)
    # Left upright
    add_cylinder_between(bm, (-half_w, 0.0, 0.05), (-half_w, 0.0, top_rail_z - 0.08), tube_r, 8, 0)
    # Right upright
    add_cylinder_between(bm, (half_w, 0.0, 0.05), (half_w, 0.0, top_rail_z - 0.08), tube_r, 8, 0)
    # Top corner rounded fillets (chamfered diagonals)
    add_cylinder_between(bm, (-half_w, 0.0, top_rail_z - 0.08), (-half_w + 0.08, 0.0, top_rail_z), tube_r, 8, 0)
    add_cylinder_between(bm, (half_w, 0.0, top_rail_z - 0.08), (half_w - 0.08, 0.0, top_rail_z), tube_r, 8, 0)

    # 2. Splayed stabilizer feet (at X = -0.70m and X = +0.70m)
    for fx in [-0.70, 0.70]:
        # Vertical riser from base to bottom rail
        add_cylinder_between(bm, (fx, 0.0, 0.02), (fx, 0.0, bot_rail_z), tube_r * 1.1, 8, 0)
        # Horizontal cross-foot along Y (-0.25 to +0.25m)
        add_cylinder_between(bm, (fx, -0.25, 0.02), (fx, 0.25, 0.02), tube_r, 8, 0)
        # Rubber anti-slip end shoes
        add_box(bm, center=(fx, -0.24, 0.02), size=(0.06, 0.07, 0.045), mat_index=4)
        add_box(bm, center=(fx, 0.24, 0.02), size=(0.06, 0.07, 0.045), mat_index=4)

    # 3. Vertical safety pickets (10 bars)
    num_pickets = 10
    picket_start_x = -0.78
    picket_end_x = 0.78
    step_x = (picket_end_x - picket_start_x) / (num_pickets - 1)
    for i in range(num_pickets):
        px = picket_start_x + i * step_x
        add_cylinder_between(bm, (px, 0.0, bot_rail_z), (px, 0.0, top_rail_z - 0.02), picket_r, 6, 0)

    # 4. Interlocking side latches (male hook left, female loop right)
    # Male hooks (left, X = -half_w)
    for hz in [0.38, 0.85]:
        add_cylinder_between(bm, (-half_w, 0.0, hz), (-half_w - 0.045, 0.0, hz), 0.009, 6, 0)
        add_cylinder_between(bm, (-half_w - 0.045, 0.0, hz), (-half_w - 0.045, 0.0, hz - 0.05), 0.009, 6, 0)
    # Female loops (right, X = +half_w)
    for hz in [0.38, 0.85]:
        add_box(bm, center=(half_w + 0.025, 0.0, hz), size=(0.045, 0.035, 0.025), mat_index=0)

    # 5. Top rail protective safety foam padding bumper
    foam_len = barrier_w - 0.16
    add_box(bm, center=(0.0, 0.0, top_rail_z + 0.015), size=(foam_len, 0.065, 0.065), mat_index=3)

    # 6. Double-sided advertising sponsor panel
    panel_w = 1.76
    panel_h = 0.70
    panel_z = (bot_rail_z + top_rail_z) * 0.5 - 0.02
    add_box(bm, center=(0.0, 0.0, panel_z), size=(panel_w, 0.014, panel_h), mat_index=1)
    # Central gold sponsor brand badge plate
    add_box(bm, center=(0.0, 0.0, panel_z), size=(0.85, 0.018, 0.28), mat_index=2)
    # Corner zip-tie fastening bands
    for ex in [-panel_w * 0.46, panel_w * 0.46]:
        for ez in [panel_z - panel_h * 0.44, panel_z + panel_h * 0.44]:
            add_box(bm, center=(ex, 0.0, ez), size=(0.03, 0.03, 0.03), mat_index=4)

    bm.to_mesh(mesh)
    bm.free()
    sm.apply_zwift_style(obj, auto_smooth_angle_deg=40.0)
    return obj


# =============================================================================
# 2. GENERATE FINISH GANTRY WITH CLOCK (`arch_finish.glb`)
# =============================================================================

def generate_finish_arch_mesh(name: str = "Arch_Finish_Gantry") -> bpy.types.Object:
    """
    Procedurally constructs a professional Grand Tour Finish Gantry truss structure:
      - 8.4m inner clear span (accommodating 7.0m roadbed + roadside barriers)
      - 4.8m vertical clearance under the overhead bridge beam, 6.2m total height
      - 4-chord aluminum box-truss towers with zigzag diagonal cross-lacing
      - Heavy-duty ballast footing blocks with hazard warning chevrons
      - Central official digital race timing clock box with glowing 7-segment LEDs
      - Overhead high-speed photo-finish camera housing pointing at the finish line
      - Overhead fascia finish banner ("ARRIVÉE / FINISH LINE") with checkered ribbons
      - Tower jumbotron video screen, overhead lighting fixtures, and ground checkered strip
    """
    mesh = bpy.data.meshes.new(f"{name}_Data")
    obj = bpy.data.objects.new(name, mesh)
    if obj.name not in bpy.context.scene.collection.objects:
        bpy.context.scene.collection.objects.link(obj)
    bm = bmesh.new()

    # Materials:
    # 0: Aluminum Truss
    # 1: Finish Banner Navy
    # 2: Accent Gold / Yellow
    # 3: LED Digital Clock Glow (Green)
    # 4: Hazard Stripe Yellow
    # 5: Screen / Clock Enclosure Black
    # 6: Finish Checkered White
    # 7: Finish Checkered Black
    # 8: Floodlight Emissive White
    mat_truss = create_aluminum_truss_material()
    mat_banner_navy = create_sponsor_banner_material("finish_blue")
    mat_gold = create_sponsor_banner_material("tour_yellow")
    mat_led_green = create_digital_clock_led_material("#22C55E")
    mat_hazard = create_sponsor_banner_material("hazard_stripe")
    mat_black = create_sponsor_banner_material("screen_black")
    mat_white = create_sponsor_banner_material("kom_white")
    mat_light = create_digital_clock_led_material("#FFFFFF", name="M_Floodlight_White")

    mat_rubber = create_rubber_boot_material()

    for m in [
        mat_truss, mat_banner_navy, mat_gold, mat_led_green,
        mat_hazard, mat_black, mat_white, mat_rubber, mat_light,
    ]:
        obj.data.materials.append(m)

    # Gantry Dimensions
    tower_x = 4.55  # Left tower at -4.55, right at +4.55 (inner span = 8.4m)
    tower_w = 0.65  # 0.65m x 0.65m square box truss
    gantry_h = 6.20
    beam_bot_z = 4.80
    beam_top_z = 5.70
    chord_r = 0.028
    strut_r = 0.014

    # 1. Left and Right 4-Chord Vertical Box Truss Towers
    for side_x in [-tower_x, tower_x]:
        # Ground ballast footing block
        add_box(bm, center=(side_x, 0.0, 0.22), size=(1.20, 1.60, 0.44), mat_index=4)
        add_box(bm, center=(side_x, 0.0, 0.46), size=(1.00, 1.40, 0.05), mat_index=7)

        # 4 vertical corner chords
        hx, hy = tower_w * 0.5, tower_w * 0.5
        chord_coords = [
            (side_x - hx, -hy),
            (side_x + hx, -hy),
            (side_x + hx, hy),
            (side_x - hx, hy),
        ]
        for cx, cy in chord_coords:
            add_cylinder_between(bm, (cx, cy, 0.45), (cx, cy, gantry_h), chord_r, 8, 0)

        # Horizontal rings & diagonal cross-lacing along tower height
        num_bays = 5
        bay_step = (gantry_h - 0.45) / num_bays
        for b in range(num_bays):
            z0 = 0.45 + b * bay_step
            z1 = z0 + bay_step
            # Perimeter horizontal struts at z1
            for k in range(4):
                next_k = (k + 1) % 4
                add_cylinder_between(bm, (chord_coords[k][0], chord_coords[k][1], z1),
                                     (chord_coords[next_k][0], chord_coords[next_k][1], z1), strut_r, 6, 0)
                # Diagonal lacing
                add_cylinder_between(bm, (chord_coords[k][0], chord_coords[k][1], z0),
                                     (chord_coords[next_k][0], chord_coords[next_k][1], z1), strut_r, 6, 0)

    # 2. Horizontal Overhead Box Truss Bridge
    beam_len = tower_x * 2 + tower_w
    half_bl = beam_len * 0.5
    hy = tower_w * 0.5
    bridge_chords = [
        (-hy, beam_bot_z),
        (-hy, beam_top_z),
        (hy, beam_top_z),
        (hy, beam_bot_z),
    ]
    for cy, cz in bridge_chords:
        add_cylinder_between(bm, (-half_bl, cy, cz), (half_bl, cy, cz), chord_r, 8, 0)

    # Horizontal bridge cross-lacing bays
    bridge_bays = 9
    b_step = (beam_len - tower_w) / bridge_bays
    start_bx = -half_bl + tower_w * 0.5
    for b in range(bridge_bays):
        bx0 = start_bx + b * b_step
        bx1 = bx0 + b_step
        # Vertical and transverse struts at bx1
        for k in range(4):
            next_k = (k + 1) % 4
            add_cylinder_between(bm, (bx1, bridge_chords[k][0], bridge_chords[k][1]),
                                 (bx1, bridge_chords[next_k][0], bridge_chords[next_k][1]), strut_r, 6, 0)
            # Diagonal lacing
            add_cylinder_between(bm, (bx0, bridge_chords[k][0], bridge_chords[k][1]),
                                 (bx1, bridge_chords[next_k][0], bridge_chords[next_k][1]), strut_r, 6, 0)

    # 3. Official Digital Race Timing Clock (Center Gantry, Z = 5.25m)
    clock_w, clock_h, clock_d = 2.40, 0.76, 0.28
    clock_z = (beam_bot_z + beam_top_z) * 0.5
    # Clock casing box
    add_box(bm, center=(0.0, 0.0, clock_z), size=(clock_w, clock_d, clock_h), mat_index=5)
    # Clock front display face recess
    add_box(bm, center=(0.0, -clock_d * 0.5 - 0.005, clock_z), size=(clock_w - 0.10, 0.015, clock_h - 0.12), mat_index=7)
    # Top header plaque ("OFFICIAL TIMEKEEPER")
    add_box(bm, center=(0.0, -clock_d * 0.5 - 0.012, clock_z + clock_h * 0.32), size=(1.40, 0.015, 0.12), mat_index=2)

    # Emissive 7-Segment LED Digits: "04:19:32"
    # Digits layout across X
    digits_text = "04:19:32"
    dig_w = 0.15
    dig_h = 0.26
    dig_spacing = 0.23
    total_text_w = len(digits_text) * dig_spacing
    start_dx = -total_text_w * 0.5 + dig_w * 0.5
    for idx, ch in enumerate(digits_text):
        cur_dx = start_dx + idx * dig_spacing
        add_7segment_digit(
            bm,
            char=ch,
            origin=(cur_dx, -clock_d * 0.5 - 0.018, clock_z - dig_h * 0.58),
            width=dig_w,
            height=dig_h,
            depth=0.012,
            thickness=0.024,
            mat_index=3,  # Emissive LED Green
        )

    # 4. Photo-Finish High-Speed Camera Housing Pod
    cam_z = beam_top_z + 0.22
    add_box(bm, center=(0.0, 0.0, cam_z), size=(0.48, 0.56, 0.26), mat_index=5)
    # Dual downward optical lens cones
    add_cylinder_between(bm, (0.08, 0.0, cam_z - 0.13), (0.08, 0.0, cam_z - 0.25), 0.045, 8, 7)
    add_cylinder_between(bm, (-0.08, 0.0, cam_z - 0.13), (-0.08, 0.0, cam_z - 0.25), 0.045, 8, 7)
    # Red recording indicator lamp
    add_box(bm, center=(0.0, -0.29, cam_z), size=(0.05, 0.02, 0.05), mat_index=3)

    # 5. Overhead Finish Banner ("ARRIVÉE / FINISH LINE")
    banner_w = 8.20
    banner_h = 1.05
    banner_y = -hy - 0.06
    add_box(bm, center=(0.0, banner_y, clock_z), size=(banner_w, 0.02, banner_h), mat_index=1)
    # Checkered flag ribbons on flanks
    add_box(bm, center=(-banner_w * 0.44, banner_y - 0.012, clock_z), size=(0.80, 0.015, banner_h * 0.85), mat_index=6)
    add_box(bm, center=(banner_w * 0.44, banner_y - 0.012, clock_z), size=(0.80, 0.015, banner_h * 0.85), mat_index=6)
    # Central finish crest plaque
    add_box(bm, center=(0.0, banner_y - 0.012, clock_z), size=(3.20, 0.015, 0.45), mat_index=2)

    # 6. Tower Jumbotron LED Video Wall (on Right Tower)
    jumbo_x = tower_x + 0.15
    jumbo_z = 2.80
    add_box(bm, center=(jumbo_x, 0.0, jumbo_z), size=(0.20, 1.80, 1.50), mat_index=5)
    add_box(bm, center=(jumbo_x - 0.11, 0.0, jumbo_z), size=(0.015, 1.65, 1.35), mat_index=3)  # Emissive screen

    # 7. Overhead Floodlights (4 lamps pointing at the line)
    for lx in [-2.80, -1.10, 1.10, 2.80]:
        add_box(bm, center=(lx, -hy - 0.10, beam_bot_z - 0.10), size=(0.24, 0.24, 0.18), mat_index=5)
        add_box(bm, center=(lx, -hy - 0.10, beam_bot_z - 0.20), size=(0.20, 0.20, 0.02), mat_index=8)  # Light

    # 8. Ground Checkered Finish Line Decal Strip
    # 7.4m width spanning across the 7.0m road, 0.40m longitudinal depth, at Z = 0.003m
    fl_w = 7.40
    fl_d = 0.40
    num_chk_x = 24
    sq_w = fl_w / num_chk_x
    sq_d = fl_d * 0.5
    for ix in range(num_chk_x):
        cx = -fl_w * 0.5 + ix * sq_w + sq_w * 0.5
        # Row 1 (Y: -0.20 to 0.0)
        mat_sq1 = 6 if (ix % 2 == 0) else 7
        add_box(bm, center=(cx, -sq_d * 0.5, 0.003), size=(sq_w, sq_d, 0.003), mat_index=mat_sq1)
        # Row 2 (Y: 0.0 to +0.20)
        mat_sq2 = 7 if (ix % 2 == 0) else 6
        add_box(bm, center=(cx, sq_d * 0.5, 0.003), size=(sq_w, sq_d, 0.003), mat_index=mat_sq2)

    # Timing transponder loops (black sensor strips crossing the road)
    add_box(bm, center=(0.0, -fl_d * 0.5 - 0.06, 0.004), size=(fl_w, 0.025, 0.004), mat_index=7)
    add_box(bm, center=(0.0, fl_d * 0.5 + 0.06, 0.004), size=(fl_w, 0.025, 0.004), mat_index=7)

    bm.to_mesh(mesh)
    bm.free()
    sm.apply_zwift_style(obj, auto_smooth_angle_deg=35.0)
    return obj


# =============================================================================
# 3. GENERATE FLAMME ROUGE 1 KM INFLATABLE ARCH (`arch_flamme_rouge.glb`)
# =============================================================================

def generate_flamme_rouge_arch_mesh(name: str = "Arch_Flamme_Rouge") -> bpy.types.Object:
    """
    Procedurally constructs the legendary inflatable "Flamme Rouge - 1 KM" arch:
      - 8.0m clear span, 4.6m vertical clearance under crown, 5.35m apex height
      - Continuous tubular red inflatable PVC arch with smooth lofted geometry
      - Two rectangular inflatable ballast footing bases with blower vents
      - Suspended iconic triangular red pennant / kite ("1 KM") with gold fringe
      - Arched white vinyl lettering ("1 KM", "FLAMME ROUGE", "DERNIER KILOMÈTRE")
    """
    mesh = bpy.data.meshes.new(f"{name}_Data")
    obj = bpy.data.objects.new(name, mesh)
    if obj.name not in bpy.context.scene.collection.objects:
        bpy.context.scene.collection.objects.link(obj)
    bm = bmesh.new()

    # Materials:
    # 0: Inflatable PVC Red
    # 1: White Decal / Banner
    # 2: Accent Gold / Yellow
    # 3: Rubber Base / Blower Pad
    mat_pvc_red = create_inflatable_pvc_material("#DC2626")
    mat_white = create_sponsor_banner_material("kom_white")
    mat_gold = create_sponsor_banner_material("tour_yellow")
    mat_rubber = create_rubber_boot_material()

    obj.data.materials.append(mat_pvc_red)  # Index 0
    obj.data.materials.append(mat_white)    # Index 1
    obj.data.materials.append(mat_gold)     # Index 2
    obj.data.materials.append(mat_rubber)   # Index 3

    # 1. Main Inflatable Curved Arch Tube
    span = 8.20
    shoulder_h = 2.80
    apex_h = 5.00
    tube_r = 0.35
    add_inflatable_arch_mesh(
        bm,
        span=span,
        shoulder_height=shoulder_h,
        apex_height=apex_h,
        tube_radius=tube_r,
        radial_segments=16,
        curve_segments=24,
        mat_index=0,
    )

    # 2. Inflatable Ballast Footing Bases (Left & Right)
    for side_x in [-span * 0.5, span * 0.5]:
        add_box(bm, center=(side_x, 0.0, 0.22), size=(1.35, 1.35, 0.44), mat_index=0)
        # Blower vent pipe on outside
        blow_x = side_x + (0.75 if side_x > 0 else -0.75)
        add_cylinder_between(bm, (side_x, 0.0, 0.20), (blow_x, 0.0, 0.20), 0.12, 8, 3)

    # 3. Suspended Triangular "Flamme Rouge" Red Kite Pennant
    # Hanging down from apex center (X = 0, Z = 4.65m)
    pennant_top_z = apex_h - tube_r - 0.02
    add_flamme_rouge_pennant(
        bm,
        apex_center=(0.0, 0.0, pennant_top_z),
        top_width=0.88,
        height=1.05,
        thickness=0.014,
        mat_index=0,  # Red fabric
    )
    # Suspension steel cables attaching pennant to crown
    cable_r = 0.005
    add_cylinder_between(bm, (-0.42, 0.0, pennant_top_z), (-0.42, 0.0, pennant_top_z + 0.15), cable_r, 6, 2)
    add_cylinder_between(bm, (0.42, 0.0, pennant_top_z), (0.42, 0.0, pennant_top_z + 0.15), cable_r, 6, 2)
    # Gold fringe border at pennant top
    add_box(bm, center=(0.0, 0.0, pennant_top_z), size=(0.92, 0.022, 0.045), mat_index=2)
    # Bold white "1 KM" badge decal on pennant face
    add_box(bm, center=(0.0, 0.0, pennant_top_z - 0.35), size=(0.42, 0.022, 0.25), mat_index=1)

    # 4. White Lettering Banner Decals on Arch Tube Face
    # Apex "FLAMME ROUGE" sign
    add_box(bm, center=(0.0, -tube_r - 0.015, apex_h - 0.05), size=(1.80, 0.02, 0.35), mat_index=1)
    # Left leg "1 KM" & "DERNIER KILOMÈTRE" banner
    add_box(bm, center=(-span * 0.5, -tube_r - 0.015, shoulder_h * 0.7), size=(0.55, 0.02, 1.20), mat_index=1)
    # Right leg "1 KM" banner
    add_box(bm, center=(span * 0.5, -tube_r - 0.015, shoulder_h * 0.7), size=(0.55, 0.02, 1.20), mat_index=1)

    bm.to_mesh(mesh)
    bm.free()
    sm.apply_zwift_style(obj, auto_smooth_angle_deg=45.0)
    return obj


# =============================================================================
# 4. GENERATE KOM & SPRINT ARCHES (`arch_kom_sprint.glb`)
# =============================================================================

def generate_kom_arch_mesh(name: str = "Arch_KOM") -> bpy.types.Object:
    """
    Procedurally constructs the King of the Mountains (KOM / Grand Prix de la
    Montagne) summit arch:
      - 8.0m clear span, 4.6m vertical clearance under crown
      - Crisp alpine white inflatable arch tube with iconic red polka dots
      - Summit altitude & category milestone sign ("COL DU TOURMALET - 2115m - HC")
      - Climber classification points breakdown plaque ("PTS: 20-15-12-10...")
      - Mountain pass timing transponder sensor antenna
    """
    mesh = bpy.data.meshes.new(f"{name}_Data")
    obj = bpy.data.objects.new(name, mesh)
    if obj.name not in bpy.context.scene.collection.objects:
        bpy.context.scene.collection.objects.link(obj)
    bm = bmesh.new()

    # Materials:
    # 0: White Inflatable Tube
    # 1: Polka Dot Red
    # 2: Accent Gold / Border
    # 3: Rubber Base
    # 4: Blue Header / Banner
    mat_white = create_sponsor_banner_material("kom_white")
    mat_polka_red = create_polka_dot_material()
    mat_gold = create_sponsor_banner_material("tour_yellow")
    mat_rubber = create_rubber_boot_material()
    mat_blue = create_sponsor_banner_material("finish_blue")

    obj.data.materials.append(mat_white)      # Index 0
    obj.data.materials.append(mat_polka_red)  # Index 1
    obj.data.materials.append(mat_gold)       # Index 2
    obj.data.materials.append(mat_rubber)     # Index 3
    obj.data.materials.append(mat_blue)       # Index 4

    span = 8.00
    shoulder_h = 2.80
    apex_h = 4.90
    tube_r = 0.35

    # 1. Main Inflatable White Arch
    add_inflatable_arch_mesh(
        bm,
        span=span,
        shoulder_height=shoulder_h,
        apex_height=apex_h,
        tube_radius=tube_r,
        radial_segments=16,
        curve_segments=24,
        mat_index=0,
    )

    # 2. Inflatable Ballast Footing Pads
    for side_x in [-span * 0.5, span * 0.5]:
        add_box(bm, center=(side_x, 0.0, 0.22), size=(1.30, 1.30, 0.44), mat_index=0)
        # Red polka dot accent band on base
        add_box(bm, center=(side_x, 0.0, 0.45), size=(1.32, 1.32, 0.08), mat_index=1)

    # 3. 3D Polka Dot Circles Scattered Across Arch Face
    # Systematically placed decorative red circular button plates
    dot_r = 0.10
    # Left leg dots
    for dz in [0.8, 1.4, 2.0, 2.6]:
        add_cylinder_between(bm, (-span * 0.5, -tube_r, dz), (-span * 0.5, -tube_r - 0.015, dz), dot_r, 8, 1)
    # Right leg dots
    for dz in [0.8, 1.4, 2.0, 2.6]:
        add_cylinder_between(bm, (span * 0.5, -tube_r, dz), (span * 0.5, -tube_r - 0.015, dz), dot_r, 8, 1)
    # Crown dots
    for angle_deg in [30, 60, 120, 150]:
        rad = math.radians(angle_deg)
        dot_x = (span * 0.5) * math.cos(rad)
        dot_z = shoulder_h + (apex_h - shoulder_h) * math.sin(rad)
        add_cylinder_between(bm, (dot_x, -tube_r, dot_z), (dot_x, -tube_r - 0.015, dot_z), dot_r, 8, 1)

    # 4. Overhead Summit Milestone Banner ("COL DU TOURMALET - 2115m - HC")
    banner_w = 6.20
    banner_h = 0.85
    banner_z = apex_h - 0.15
    add_box(bm, center=(0.0, -tube_r - 0.02, banner_z), size=(banner_w, 0.02, banner_h), mat_index=4)
    # Red polka dot framing stripes on banner
    add_box(bm, center=(-banner_w * 0.42, -tube_r - 0.025, banner_z), size=(0.60, 0.02, banner_h * 0.85), mat_index=1)
    add_box(bm, center=(banner_w * 0.42, -tube_r - 0.025, banner_z), size=(0.60, 0.02, banner_h * 0.85), mat_index=1)
    # Central summit badge plate ("MEILLEUR GRIMPEUR")
    add_box(bm, center=(0.0, -tube_r - 0.025, banner_z), size=(3.20, 0.02, 0.45), mat_index=2)

    # 5. Points Distribution Plaque ("PTS: 20-15-12-10...") on Left Leg
    add_box(bm, center=(-span * 0.5, -tube_r - 0.02, 1.60), size=(0.60, 0.02, 0.90), mat_index=2)
    # Summit timing transponder loop strip across road
    add_box(bm, center=(0.0, 0.0, 0.003), size=(7.40, 0.08, 0.003), mat_index=1)

    bm.to_mesh(mesh)
    bm.free()
    sm.apply_zwift_style(obj, auto_smooth_angle_deg=45.0)
    return obj


def generate_sprint_arch_mesh(name: str = "Arch_Sprint") -> bpy.types.Object:
    """
    Procedurally constructs the Intermediate Sprint (Sprint Intermédiaire /
    Maillot Vert) arch:
      - 8.0m clear span, 4.6m vertical clearance under crown
      - Tour sprint green (#16A34A) livery with white directional chevron arrows
      - Digital speed radar display box with glowing green LED readout ("RADAR 68 KM/H")
      - Points classification distribution sign and sprint line timing strip
    """
    mesh = bpy.data.meshes.new(f"{name}_Data")
    obj = bpy.data.objects.new(name, mesh)
    if obj.name not in bpy.context.scene.collection.objects:
        bpy.context.scene.collection.objects.link(obj)
    bm = bmesh.new()

    # Materials:
    # 0: Sprint Green
    # 1: White Arrow / Decal
    # 2: Accent Gold / Yellow
    # 3: LED Radar Glow (Green)
    # 4: Screen / Enclosure Black
    # 5: Rubber Base
    mat_green = create_sponsor_banner_material("sprint_green")
    mat_white = create_sponsor_banner_material("kom_white")
    mat_gold = create_sponsor_banner_material("tour_yellow")
    mat_led_green = create_digital_clock_led_material("#22C55E")
    mat_black = create_sponsor_banner_material("screen_black")
    mat_rubber = create_rubber_boot_material()

    obj.data.materials.append(mat_green)      # Index 0
    obj.data.materials.append(mat_white)      # Index 1
    obj.data.materials.append(mat_gold)       # Index 2
    obj.data.materials.append(mat_led_green)  # Index 3
    obj.data.materials.append(mat_black)      # Index 4
    obj.data.materials.append(mat_rubber)     # Index 5

    span = 8.00
    shoulder_h = 2.80
    apex_h = 4.90
    tube_r = 0.35

    # 1. Main Inflatable Sprint Green Arch
    add_inflatable_arch_mesh(
        bm,
        span=span,
        shoulder_height=shoulder_h,
        apex_height=apex_h,
        tube_radius=tube_r,
        radial_segments=16,
        curve_segments=24,
        mat_index=0,
    )

    # 2. Inflatable Ballast Footing Pads
    for side_x in [-span * 0.5, span * 0.5]:
        add_box(bm, center=(side_x, 0.0, 0.22), size=(1.30, 1.30, 0.44), mat_index=0)
        add_box(bm, center=(side_x, 0.0, 0.45), size=(1.32, 1.32, 0.08), mat_index=1)

    # 3. Overhead Sprint Fascia Banner ("SPRINT INTERMÉDIAIRE")
    banner_w = 6.40
    banner_h = 0.85
    banner_z = apex_h - 0.15
    add_box(bm, center=(0.0, -tube_r - 0.02, banner_z), size=(banner_w, 0.02, banner_h), mat_index=0)
    # Directional sprint chevron arrows: `>>> SPRINT >>>`
    add_box(bm, center=(-banner_w * 0.38, -tube_r - 0.025, banner_z), size=(0.75, 0.02, 0.35), mat_index=1)
    add_box(bm, center=(banner_w * 0.38, -tube_r - 0.025, banner_z), size=(0.75, 0.02, 0.35), mat_index=1)
    # Central sprint badge ("MAILLOT VERT - SPRINT")
    add_box(bm, center=(0.0, -tube_r - 0.025, banner_z), size=(3.20, 0.02, 0.45), mat_index=2)

    # 4. Digital Speed Radar Display Box (Suspended on Right Tower)
    radar_x = span * 0.5
    radar_z = 2.40
    add_box(bm, center=(radar_x, -tube_r - 0.12, radar_z), size=(0.80, 0.22, 0.55), mat_index=4)
    # Glowing radar speed readout: "68 KM/H"
    add_box(bm, center=(radar_x, -tube_r - 0.24, radar_z), size=(0.68, 0.015, 0.40), mat_index=3)

    # 5. Points Classification Distribution Plaque on Left Leg
    add_box(bm, center=(-span * 0.5, -tube_r - 0.02, 1.60), size=(0.60, 0.02, 0.90), mat_index=1)
    # Green sprint line decal across the road
    add_box(bm, center=(0.0, 0.0, 0.003), size=(7.40, 0.15, 0.003), mat_index=0)

    bm.to_mesh(mesh)
    bm.free()
    sm.apply_zwift_style(obj, auto_smooth_angle_deg=45.0)
    return obj


# =============================================================================
# EXPORT PIPELINE (GLTF 2.0 BINARY)
# =============================================================================

def export_race_furniture_asset(
    objects: Union[bpy.types.Object, List[bpy.types.Object]],
    filepath: str,
) -> str:
    """
    Exports single or multiple Blender objects to an optimized glTF 2.0
    binary (.glb) file.
    """
    if isinstance(objects, bpy.types.Object):
        objects = [objects]

    os.makedirs(os.path.dirname(os.path.abspath(filepath)), exist_ok=True)

    # Deselect all, then select target objects
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

    # Draco mesh compression if supported
    if hasattr(bpy.types, "GLTF_OT_export"):
        export_kwargs["export_draco_mesh_compression_enable"] = False

    try:
        bpy.ops.export_scene.gltf(**export_kwargs)
    except TypeError:
        # Fallback for earlier Blender versions
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


def export_all_race_furniture(output_dir: str = "assets/3d/furniture") -> Dict[str, str]:
    """
    Procedurally models and exports the complete suite of race infrastructure
    assets to glTF 2.0 binary (.glb) files in `output_dir`:

      1. `barrier_finish.glb`: Metal crowd barrier with sponsor panels.
      2. `arch_finish.glb`: Grand Tour Finish Gantry with digital clock + Flamme Rouge.
      3. `arch_flamme_rouge.glb`: Standalone inflatable 1 KM Flamme Rouge arch.
      4. `arch_kom_sprint.glb`: Combined KOM mountain pass & Intermediate Sprint arches.
      5. `arch_kom.glb`: Standalone KOM summit arch.
      6. `arch_sprint.glb`: Standalone Intermediate Sprint arch.
    """
    # Clean active scene mesh objects
    for obj in list(bpy.context.scene.objects):
        if obj.type == "MESH":
            bpy.data.objects.remove(obj, do_unlink=True)

    print("\n" + "=" * 75)
    print("PRO PELOTON MANAGER: GENERATING GRAND TOUR RACE FURNITURE")
    print("=" * 75)

    os.makedirs(output_dir, exist_ok=True)
    exported_files: Dict[str, str] = {}

    # -------------------------------------------------------------------------
    # 1. Metal Crowd Barrier (`barrier_finish.glb`)
    # -------------------------------------------------------------------------
    obj_barrier = generate_finish_barrier_mesh(name="Barrier_Finish")
    p_barrier = os.path.join(output_dir, "barrier_finish.glb")
    exported_files["barrier_finish"] = export_race_furniture_asset(obj_barrier, p_barrier)
    bpy.data.objects.remove(obj_barrier, do_unlink=True)

    # -------------------------------------------------------------------------
    # 2. Standalone Flamme Rouge 1 KM Arch (`arch_flamme_rouge.glb`)
    # -------------------------------------------------------------------------
    obj_flamme_rouge = generate_flamme_rouge_arch_mesh(name="Arch_Flamme_Rouge")
    p_flamme = os.path.join(output_dir, "arch_flamme_rouge.glb")
    exported_files["arch_flamme_rouge"] = export_race_furniture_asset(obj_flamme_rouge, p_flamme)
    bpy.data.objects.remove(obj_flamme_rouge, do_unlink=True)

    # -------------------------------------------------------------------------
    # 3. Finish Gantry Arch (`arch_finish.glb`)
    # Contains the Finish Gantry at Y = 0.0, plus Flamme Rouge at Y = -25.0m
    # -------------------------------------------------------------------------
    obj_finish_gantry = generate_finish_arch_mesh(name="Arch_Finish_Gantry")
    obj_flamme_in_finish = generate_flamme_rouge_arch_mesh(name="Arch_Flamme_Rouge_Preview")
    obj_flamme_in_finish.location = (0.0, -25.0, 0.0)

    p_finish = os.path.join(output_dir, "arch_finish.glb")
    exported_files["arch_finish"] = export_race_furniture_asset(
        [obj_finish_gantry, obj_flamme_in_finish], p_finish
    )
    bpy.data.objects.remove(obj_finish_gantry, do_unlink=True)
    bpy.data.objects.remove(obj_flamme_in_finish, do_unlink=True)

    # -------------------------------------------------------------------------
    # 4. Standalone KOM Arch (`arch_kom.glb`)
    # -------------------------------------------------------------------------
    obj_kom = generate_kom_arch_mesh(name="Arch_KOM")
    p_kom = os.path.join(output_dir, "arch_kom.glb")
    exported_files["arch_kom"] = export_race_furniture_asset(obj_kom, p_kom)
    bpy.data.objects.remove(obj_kom, do_unlink=True)

    # -------------------------------------------------------------------------
    # 5. Standalone Intermediate Sprint Arch (`arch_sprint.glb`)
    # -------------------------------------------------------------------------
    obj_sprint = generate_sprint_arch_mesh(name="Arch_Sprint")
    p_sprint = os.path.join(output_dir, "arch_sprint.glb")
    exported_files["arch_sprint"] = export_race_furniture_asset(obj_sprint, p_sprint)
    bpy.data.objects.remove(obj_sprint, do_unlink=True)

    # -------------------------------------------------------------------------
    # 6. Combined KOM & Sprint Arch (`arch_kom_sprint.glb`)
    # Contains Arch_KOM at Y = -15.0m and Arch_Sprint at Y = +15.0m
    # -------------------------------------------------------------------------
    obj_kom_comb = generate_kom_arch_mesh(name="Arch_KOM")
    obj_kom_comb.location = (0.0, -15.0, 0.0)
    obj_sprint_comb = generate_sprint_arch_mesh(name="Arch_Sprint")
    obj_sprint_comb.location = (0.0, 15.0, 0.0)

    p_kom_sprint = os.path.join(output_dir, "arch_kom_sprint.glb")
    exported_files["arch_kom_sprint"] = export_race_furniture_asset(
        [obj_kom_comb, obj_sprint_comb], p_kom_sprint
    )
    bpy.data.objects.remove(obj_kom_comb, do_unlink=True)
    bpy.data.objects.remove(obj_sprint_comb, do_unlink=True)

    print("=" * 75 + "\n")
    return exported_files


# =============================================================================
# CLI EXECUTION ENTRY POINT
# =============================================================================

if __name__ == "__main__":
    out_dir = "assets/3d/furniture"
    for idx, arg in enumerate(sys.argv):
        if arg in ["--output-dir", "-o"] and idx + 1 < len(sys.argv):
            out_dir = sys.argv[idx + 1]

    files = export_all_race_furniture(output_dir=out_dir)
    sm.setup_zwift_studio_lighting()
    print(f"[SUCCESS] All race furniture assets generated: {files}")
