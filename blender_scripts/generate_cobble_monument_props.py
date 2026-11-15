"""
===============================================================================
PRO PELOTON MANAGER - SPRING CLASSICS & COBBLED MONUMENTS PROPS GENERATOR
===============================================================================
Blender 5.3 Python API (bpy) script that procedurally builds iconic 3D assets
for Spring Classics and Cobbled Monuments:

  1. Concrete Velodrome Finish Arena (`assets/3d/environment/velodrome_finish_arena.glb`):
     - Oval cycling track basin with 31-degree banked turns and smooth transitions
     - Inner blue Côte d'Azur safety apron, measurement/sprinter/stayer lines
     - Lush grass infield, finish line strip & timing posts
     - Covered historic grandstand with tiered seating, columns, and pitched roof

  2. Cobble Sector Props Pack (`assets/3d/environment/cobble_sector_props.glb`):
     - Wooden sector entrance gate with 5-star difficulty rating (*****)
     - Roadside stone monument with stepped plinth, bronze plaque, and pavé emblem
     - Geometric mud patches and reflective water puddles (Roughness = 0.08)

Usage:
  blender --background --python blender_scripts/generate_cobble_monument_props.py
  blender --background --python blender_scripts/generate_cobble_monument_props.py -- --output-dir assets/3d/environment

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
    from mathutils import Vector
except ImportError:
    print("[ERROR] 'bpy' / 'mathutils' module not found. Run within Blender:")
    print("        blender --background --python blender_scripts/generate_cobble_monument_props.py")
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
# PBR MATERIAL FACTORIES
# =============================================================================

def _make_pbr_material(
    name: str,
    hex_color: str,
    roughness: float = 0.5,
    metallic: float = 0.0,
    specular_ior: float = 0.5,
    ior: float = 1.45,
) -> bpy.types.Material:
    """Creates a clean Principled BSDF PBR material compatible with Blender 5.3 and glTF 2.0."""
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)
    sm._set_bsdf_socket(bsdf, ["Base Color"], sm.hex_to_linear_rgb(hex_color))
    sm._set_bsdf_socket(bsdf, ["Roughness"], roughness)
    sm._set_bsdf_socket(bsdf, ["Metallic"], metallic)
    sm._set_bsdf_socket(bsdf, ["Specular IOR Level", "Specular"], specular_ior)
    sm._set_bsdf_socket(bsdf, ["IOR"], ior)
    return mat


def create_velodrome_materials() -> List[bpy.types.Material]:
    """Builds the ordered material palette for the Concrete Velodrome Finish Arena."""
    return [
        # 0: Weathered concrete track surface
        _make_pbr_material("Mat_Velo_Concrete_Track", "#9CA3AF", roughness=0.72, metallic=0.0),
        # 1: Cote d'Azur inner safety apron (iconic Roubaix blue)
        _make_pbr_material("Mat_Velo_Cote_Azur", "#1D4ED8", roughness=0.55, metallic=0.0),
        # 2: Infield grass
        _make_pbr_material("Mat_Velo_Infield_Grass", "#2E6F3E", roughness=0.88, metallic=0.0),
        # 3: Track dark concrete wall & outer skirt
        _make_pbr_material("Mat_Velo_Outer_Concrete", "#4B5563", roughness=0.82, metallic=0.0),
        # 4: Finish line & white markings
        _make_pbr_material("Mat_Velo_Line_White", "#F3F4F6", roughness=0.45, metallic=0.0),
        # 5: Measurement line & timing black
        _make_pbr_material("Mat_Velo_Line_Black", "#111827", roughness=0.50, metallic=0.0),
        # 6: Sprinter line red
        _make_pbr_material("Mat_Velo_Line_Red", "#DC2626", roughness=0.45, metallic=0.0),
        # 7: Historic grandstand timber seating
        _make_pbr_material("Mat_Velo_Grandstand_Wood", "#6B4423", roughness=0.78, metallic=0.0),
        # 8: Historic grandstand painted iron pillars & trusses
        _make_pbr_material("Mat_Velo_Historic_Iron", "#1F2937", roughness=0.42, metallic=0.85),
        # 9: Historic grandstand zinc/slate roof
        _make_pbr_material("Mat_Velo_Roof_Slate", "#374151", roughness=0.62, metallic=0.25),
        # 10: Gold/burgundy classic banner accent
        _make_pbr_material("Mat_Velo_Banner_Burgundy", "#8E4A49", roughness=0.50, metallic=0.05),
    ]


def create_cobble_props_materials() -> List[bpy.types.Material]:
    """Builds the ordered material palette for the Cobble Sector Props Pack."""
    return [
        # 0: Aged oak timber for sector gate
        _make_pbr_material("Mat_Cobble_Timber_Oak", "#5C3D28", roughness=0.80, metallic=0.0),
        # 1: Dark painted wood signboard
        _make_pbr_material("Mat_Cobble_Signboard_Dark", "#1C1F26", roughness=0.55, metallic=0.05),
        # 2: 5-Star difficulty gold emblem
        _make_pbr_material("Mat_Cobble_Star_Gold", "#D4AF37", roughness=0.28, metallic=0.85),
        # 3: Carved granite / limestone monument stone
        _make_pbr_material("Mat_Cobble_Monument_Stone", "#78716C", roughness=0.84, metallic=0.0),
        # 4: Monument bronze plaque
        _make_pbr_material("Mat_Cobble_Monument_Bronze", "#7C5832", roughness=0.35, metallic=0.90),
        # 5: Wet mud patch
        _make_pbr_material("Mat_Cobble_Wet_Mud", "#3B2818", roughness=0.68, metallic=0.0, specular_ior=0.45),
        # 6: Water puddle mirror (explicit Roughness = 0.08)
        _make_pbr_material(
            "Mat_Cobble_Puddle_Water",
            "#182226",
            roughness=0.08,
            metallic=0.0,
            specular_ior=0.85,
            ior=1.333,
        ),
    ]


# =============================================================================
# BMESH GEOMETRY HELPERS
# =============================================================================

def _add_box(
    bm: bmesh.types.BMesh,
    center: Tuple[float, float, float],
    size: Tuple[float, float, float],
    mat_index: int = 0,
) -> List[bmesh.types.BMFace]:
    """Creates an axis-aligned box with specified center, dimensions, and material index."""
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
        bm.faces.new((v0, v3, v2, v1)),
        bm.faces.new((v4, v5, v6, v7)),
        bm.faces.new((v0, v1, v5, v4)),
        bm.faces.new((v2, v3, v7, v6)),
        bm.faces.new((v0, v4, v7, v3)),
        bm.faces.new((v1, v2, v6, v5)),
    ]
    for f in faces:
        f.material_index = mat_index
        f.smooth = False
    return faces


def _add_tapered_prism(
    bm: bmesh.types.BMesh,
    center_xy: Tuple[float, float],
    z_bottom: float,
    z_top: float,
    bottom_size: Tuple[float, float],
    top_size: Tuple[float, float],
    mat_index: int = 0,
) -> List[bmesh.types.BMFace]:
    """Creates a tapered rectangular frustum (ideal for obelisks and monument bases)."""
    cx, cy = center_xy
    bhx, bhy = bottom_size[0] * 0.5, bottom_size[1] * 0.5
    thx, thy = top_size[0] * 0.5, top_size[1] * 0.5

    b0 = bm.verts.new((cx - bhx, cy - bhy, z_bottom))
    b1 = bm.verts.new((cx + bhx, cy - bhy, z_bottom))
    b2 = bm.verts.new((cx + bhx, cy + bhy, z_bottom))
    b3 = bm.verts.new((cx - bhx, cy + bhy, z_bottom))

    t0 = bm.verts.new((cx - thx, cy - thy, z_top))
    t1 = bm.verts.new((cx + thx, cy - thy, z_top))
    t2 = bm.verts.new((cx + thx, cy + thy, z_top))
    t3 = bm.verts.new((cx - thx, cy + thy, z_top))

    faces = [
        bm.faces.new((b0, b3, b2, b1)),
        bm.faces.new((t0, t1, t2, t3)),
        bm.faces.new((b0, b1, t1, t0)),
        bm.faces.new((b1, b2, t2, t1)),
        bm.faces.new((b2, b3, t3, t2)),
        bm.faces.new((b3, b0, t0, t3)),
    ]
    for f in faces:
        f.material_index = mat_index
        f.smooth = False
    return faces


def _add_beam_between(
    bm: bmesh.types.BMesh,
    p1: Tuple[float, float, float],
    p2: Tuple[float, float, float],
    width: float,
    height: float,
    mat_index: int = 0,
) -> List[bmesh.types.BMFace]:
    """Creates a rectangular timber or steel beam connecting two 3D points."""
    v1 = Vector(p1)
    v2 = Vector(p2)
    axis = v2 - v1
    if axis.length < 1e-6:
        return []
    axis_n = axis.normalized()
    up_ref = Vector((0.0, 0.0, 1.0)) if abs(axis_n.z) < 0.92 else Vector((0.0, 1.0, 0.0))
    side = axis_n.cross(up_ref).normalized() * (width * 0.5)
    up = side.cross(axis_n).normalized() * (height * 0.5)

    c1 = [bm.verts.new(v1 - side - up), bm.verts.new(v1 + side - up), bm.verts.new(v1 + side + up), bm.verts.new(v1 - side + up)]
    c2 = [bm.verts.new(v2 - side - up), bm.verts.new(v2 + side - up), bm.verts.new(v2 + side + up), bm.verts.new(v2 - side + up)]

    faces = [
        bm.faces.new((c1[0], c1[3], c1[2], c1[1])),
        bm.faces.new((c2[0], c2[1], c2[2], c2[3])),
    ]
    for i in range(4):
        ni = (i + 1) % 4
        faces.append(bm.faces.new((c1[i], c2[i], c2[ni], c1[ni])))

    for f in faces:
        f.material_index = mat_index
        f.smooth = False
    return faces


def _add_star_mesh(
    bm: bmesh.types.BMesh,
    center: Tuple[float, float, float],
    outer_radius: float,
    inner_radius: float,
    thickness: float,
    facing_y_sign: float = -1.0,
    mat_index: int = 0,
) -> List[bmesh.types.BMFace]:
    """Builds a crisp 5-pointed 3D star extruded along the Y axis."""
    cx, cy, cz = center
    hy = (thickness * 0.5) * facing_y_sign
    front_verts: List[bmesh.types.BMVert] = []
    back_verts: List[bmesh.types.BMVert] = []

    for i in range(10):
        angle = math.pi * 0.5 + i * (math.pi / 5.0)
        r = outer_radius if i % 2 == 0 else inner_radius
        px = cx + r * math.cos(angle)
        pz = cz + r * math.sin(angle)
        front_verts.append(bm.verts.new((px, cy + hy, pz)))
        back_verts.append(bm.verts.new((px, cy - hy, pz)))

    center_front = bm.verts.new((cx, cy + hy, cz))
    center_back = bm.verts.new((cx, cy - hy, cz))

    faces: List[bmesh.types.BMFace] = []
    for i in range(10):
        ni = (i + 1) % 10
        if facing_y_sign < 0:
            faces.append(bm.faces.new((center_front, front_verts[i], front_verts[ni])))
            faces.append(bm.faces.new((center_back, back_verts[ni], back_verts[i])))
            faces.append(bm.faces.new((front_verts[i], back_verts[i], back_verts[ni], front_verts[ni])))
        else:
            faces.append(bm.faces.new((center_front, front_verts[ni], front_verts[i])))
            faces.append(bm.faces.new((center_back, back_verts[i], back_verts[ni])))
            faces.append(bm.faces.new((front_verts[ni], back_verts[ni], back_verts[i], front_verts[i])))

    for f in faces:
        f.material_index = mat_index
        f.smooth = False
    return faces


# =============================================================================
# 1. CONCRETE VELODROME FINISH ARENA
# =============================================================================

def _sample_velodrome_oval(
    half_straight: float,
    inner_radius: float,
    straight_steps: int,
    turn_steps: int,
) -> List[Tuple[Vector, Vector, float]]:
    """
    Samples the closed velodrome inner-track perimeter as a list of
    (inner_point, outward_normal_xy, banking_angle_rad).
    Turns have 31-degree banking; straights transition smoothly to 12 degrees.
    """
    bank_turn = math.radians(31.0)
    bank_straight = math.radians(12.0)
    samples: List[Tuple[Vector, Vector, float]] = []

    def _straight_bank(t: float) -> float:
        # Smoothly blend from 31 deg at turn exit/entry to 12 deg along middle of straight
        edge = 0.28
        if t < edge:
            u = t / edge
            w = 0.5 * (1.0 + math.cos(math.pi * u))
            return bank_straight + (bank_turn - bank_straight) * w
        if t > 1.0 - edge:
            u = (1.0 - t) / edge
            w = 0.5 * (1.0 + math.cos(math.pi * u))
            return bank_straight + (bank_turn - bank_straight) * w
        return bank_straight

    # 1. Home straight (-X to +X, Y = -inner_radius)
    for i in range(straight_steps):
        t = i / straight_steps
        x = -half_straight + t * (2.0 * half_straight)
        samples.append((Vector((x, -inner_radius, 0.0)), Vector((0.0, -1.0, 0.0)), _straight_bank(t)))

    # 2. East banked turn (31 deg)
    for i in range(turn_steps):
        phi = -0.5 * math.pi + (i / turn_steps) * math.pi
        nx, ny = math.cos(phi), math.sin(phi)
        p = Vector((half_straight + inner_radius * nx, inner_radius * ny, 0.0))
        samples.append((p, Vector((nx, ny, 0.0)), bank_turn))

    # 3. Back straight (+X to -X, Y = +inner_radius)
    for i in range(straight_steps):
        t = i / straight_steps
        x = half_straight - t * (2.0 * half_straight)
        samples.append((Vector((x, inner_radius, 0.0)), Vector((0.0, 1.0, 0.0)), _straight_bank(t)))

    # 4. West banked turn (31 deg)
    for i in range(turn_steps):
        phi = 0.5 * math.pi + (i / turn_steps) * math.pi
        nx, ny = math.cos(phi), math.sin(phi)
        p = Vector((-half_straight + inner_radius * nx, inner_radius * ny, 0.0))
        samples.append((p, Vector((nx, ny, 0.0)), bank_turn))

    return samples


def _build_track_surface_and_infield(bm: bmesh.types.BMesh) -> None:
    """Builds the banked concrete track bowl, Côte d'Azur apron, racing lines, and grass infield."""
    half_straight = 22.0
    inner_radius = 18.0
    apron_width = 2.0
    track_width = 7.5
    wall_height = 0.95
    wall_thick = 0.45

    samples = _sample_velodrome_oval(
        half_straight=half_straight,
        inner_radius=inner_radius,
        straight_steps=16,
        turn_steps=32,
    )
    n = len(samples)

    ring_infield: List[bmesh.types.BMVert] = []
    ring_apron_out: List[bmesh.types.BMVert] = []
    ring_track_out: List[bmesh.types.BMVert] = []
    ring_wall_top_in: List[bmesh.types.BMVert] = []
    ring_wall_top_out: List[bmesh.types.BMVert] = []
    ring_wall_base_out: List[bmesh.types.BMVert] = []

    for p_in, n_out, alpha in samples:
        v_infield = p_in - n_out * apron_width
        v_infield.z = 0.0

        v_apron = p_in.copy()
        v_apron.z = 0.02

        horiz = track_width * math.cos(alpha)
        vert = track_width * math.sin(alpha)
        v_track_out = p_in + n_out * horiz + Vector((0.0, 0.0, 0.02 + vert))

        v_w_top_in = v_track_out + Vector((0.0, 0.0, wall_height))
        v_w_top_out = v_w_top_in + n_out * wall_thick
        v_w_base_out = Vector((v_w_top_out.x, v_w_top_out.y, 0.0))

        ring_infield.append(bm.verts.new(v_infield))
        ring_apron_out.append(bm.verts.new(v_apron))
        ring_track_out.append(bm.verts.new(v_track_out))
        ring_wall_top_in.append(bm.verts.new(v_w_top_in))
        ring_wall_top_out.append(bm.verts.new(v_w_top_out))
        ring_wall_base_out.append(bm.verts.new(v_w_base_out))

    # Grass infield (center fan)
    center_vert = bm.verts.new((0.0, 0.0, 0.0))
    for i in range(n):
        ni = (i + 1) % n
        f_grass = bm.faces.new((center_vert, ring_infield[i], ring_infield[ni]))
        f_grass.material_index = 2  # Mat_Velo_Infield_Grass
        f_grass.smooth = False

        # Côte d'Azur blue apron
        f_apron = bm.faces.new((ring_infield[i], ring_apron_out[i], ring_apron_out[ni], ring_infield[ni]))
        f_apron.material_index = 1  # Mat_Velo_Cote_Azur
        f_apron.smooth = True

        # Concrete banked track
        f_track = bm.faces.new((ring_apron_out[i], ring_track_out[i], ring_track_out[ni], ring_apron_out[ni]))
        f_track.material_index = 0  # Mat_Velo_Concrete_Track
        f_track.smooth = True

        # Inner safety wall
        f_wall_in = bm.faces.new((ring_track_out[i], ring_wall_top_in[i], ring_wall_top_in[ni], ring_track_out[ni]))
        f_wall_in.material_index = 3  # Mat_Velo_Outer_Concrete
        f_wall_in.smooth = True

        # Wall top cap
        f_wall_top = bm.faces.new((ring_wall_top_in[i], ring_wall_top_out[i], ring_wall_top_out[ni], ring_wall_top_in[ni]))
        f_wall_top.material_index = 3
        f_wall_top.smooth = False

        # Outer concrete skirt
        f_wall_out = bm.faces.new((ring_wall_top_out[i], ring_wall_base_out[i], ring_wall_base_out[ni], ring_wall_top_out[ni]))
        f_wall_out.material_index = 3
        f_wall_out.smooth = True

    # Racing regulation lines (Black measurement, Red sprinter, Blue stayer)
    line_specs = [
        (0.20, 0.28, 5),  # Black measurement line
        (0.85, 0.93, 6),  # Red sprinter line
        (2.45, 2.53, 1),  # Blue stayer line
    ]
    for r_start, r_end, mat_idx in line_specs:
        l_in: List[bmesh.types.BMVert] = []
        l_out: List[bmesh.types.BMVert] = []
        for p_in, n_out, alpha in samples:
            surf_n = Vector((-n_out.x * math.sin(alpha), -n_out.y * math.sin(alpha), math.cos(alpha))) * 0.008
            dir_s = Vector((n_out.x * math.cos(alpha), n_out.y * math.cos(alpha), math.sin(alpha)))
            base = p_in + Vector((0.0, 0.0, 0.02)) + surf_n
            l_in.append(bm.verts.new(base + dir_s * r_start))
            l_out.append(bm.verts.new(base + dir_s * r_end))
        for i in range(n):
            ni = (i + 1) % n
            f_line = bm.faces.new((l_in[i], l_out[i], l_out[ni], l_in[ni]))
            f_line.material_index = mat_idx
            f_line.smooth = True

    # Finish line strip at x = 0 on home straight (y < 0, alpha = 12 deg)
    alpha_finish = math.radians(12.0)
    dir_f = Vector((0.0, -math.cos(alpha_finish), math.sin(alpha_finish)))
    surf_nf = Vector((0.0, math.sin(alpha_finish), math.cos(alpha_finish))) * 0.014
    p_base = Vector((0.0, -inner_radius, 0.02)) + surf_nf

    def _add_finish_band(x_half: float, mat_idx: int, z_lift: float = 0.0) -> None:
        v0 = bm.verts.new(p_base + Vector((-x_half, 0.0, z_lift)))
        v1 = bm.verts.new(p_base + Vector((x_half, 0.0, z_lift)))
        v2 = bm.verts.new(p_base + dir_f * track_width + Vector((x_half, 0.0, z_lift)))
        v3 = bm.verts.new(p_base + dir_f * track_width + Vector((-x_half, 0.0, z_lift)))
        f = bm.faces.new((v0, v1, v2, v3))
        f.material_index = mat_idx
        f.smooth = False

    _add_finish_band(0.36, mat_idx=4, z_lift=0.0)     # White finish band
    _add_finish_band(0.04, mat_idx=5, z_lift=0.005)   # Black timing center line

    # Finish line timing posts on inner apron & outer wall
    _add_box(bm, center=(0.0, -inner_radius - 0.15, 0.65), size=(0.14, 0.14, 1.3), mat_index=4)
    _add_box(bm, center=(0.0, -inner_radius - 0.15, 1.35), size=(0.24, 0.24, 0.22), mat_index=5)


def _build_historic_grandstand(bm: bmesh.types.BMesh) -> None:
    """Builds the covered historic Roubaix-style grandstand along the home straight."""
    stand_len = 36.0
    y_front = -28.0
    tiers = 6
    tier_depth = 0.85
    tier_rise = 0.58
    base_z = 0.65

    # Concrete foundation & stepped seating tiers
    _add_box(
        bm,
        center=(0.0, y_front - (tiers * tier_depth) * 0.5, base_z * 0.5),
        size=(stand_len, tiers * tier_depth + 1.2, base_z),
        mat_index=3,
    )
    for t in range(tiers):
        ty = y_front - t * tier_depth - tier_depth * 0.5
        tz = base_z + t * tier_rise
        _add_box(
            bm,
            center=(0.0, ty, tz + tier_rise * 0.5),
            size=(stand_len - 0.6, tier_depth, tier_rise),
            mat_index=3,
        )
        # Wooden bench plank on top of each concrete tier
        _add_box(
            bm,
            center=(0.0, ty + 0.08, tz + tier_rise + 0.05),
            size=(stand_len - 1.0, 0.42, 0.08),
            mat_index=7,
        )

    # Rear & side masonry/concrete walls
    y_back = y_front - tiers * tier_depth - 0.5
    wall_top_z = base_z + tiers * tier_rise + 2.8
    _add_box(
        bm,
        center=(0.0, y_back, wall_top_z * 0.5),
        size=(stand_len, 0.40, wall_top_z),
        mat_index=3,
    )
    for sx in (-stand_len * 0.5 + 0.2, stand_len * 0.5 - 0.2):
        _add_box(
            bm,
            center=(sx, (y_front + y_back) * 0.5, wall_top_z * 0.5),
            size=(0.40, abs(y_front - y_back), wall_top_z),
            mat_index=3,
        )

    # Historic cast-iron columns & roof trusses
    num_bays = 6
    roof_front_z = wall_top_z + 0.9
    roof_back_z = wall_top_z + 0.1
    roof_front_y = y_front + 0.8
    roof_back_y = y_back - 0.4

    for i in range(num_bays + 1):
        px = -stand_len * 0.5 + 0.4 + i * ((stand_len - 0.8) / num_bays)
        # Front slim iron pillar
        _add_beam_between(
            bm,
            (px, y_front + 0.35, base_z),
            (px, y_front + 0.35, roof_front_z),
            width=0.18,
            height=0.18,
            mat_index=8,
        )
        # Sloped roof truss beam
        _add_beam_between(
            bm,
            (px, roof_front_y, roof_front_z),
            (px, roof_back_y, roof_back_z),
            width=0.16,
            height=0.22,
            mat_index=8,
        )

    # Sloped historic slate/zinc roof slab
    r0 = bm.verts.new((-stand_len * 0.5 - 0.5, roof_front_y, roof_front_z + 0.12))
    r1 = bm.verts.new((stand_len * 0.5 + 0.5, roof_front_y, roof_front_z + 0.12))
    r2 = bm.verts.new((stand_len * 0.5 + 0.5, roof_back_y, roof_back_z + 0.12))
    r3 = bm.verts.new((-stand_len * 0.5 - 0.5, roof_back_y, roof_back_z + 0.12))

    b0 = bm.verts.new((-stand_len * 0.5 - 0.5, roof_front_y, roof_front_z))
    b1 = bm.verts.new((stand_len * 0.5 + 0.5, roof_front_y, roof_front_z))
    b2 = bm.verts.new((stand_len * 0.5 + 0.5, roof_back_y, roof_back_z))
    b3 = bm.verts.new((-stand_len * 0.5 - 0.5, roof_back_y, roof_back_z))

    for quad in [
        (r0, r1, r2, r3),
        (b0, b3, b2, b1),
        (b0, b1, r1, r0),
        (b2, b3, r3, r2),
        (b0, r0, r3, b3),
        (b1, b2, r2, r1),
    ]:
        f = bm.faces.new(quad)
        f.material_index = 9
        f.smooth = False

    # Classic burgundy fascia banner along front roof edge
    _add_box(
        bm,
        center=(0.0, roof_front_y + 0.06, roof_front_z - 0.25),
        size=(stand_len + 0.4, 0.10, 0.55),
        mat_index=10,
    )


def generate_velodrome_finish_arena_mesh(
    name: str = "Velodrome_Finish_Arena",
) -> bpy.types.Object:
    """Generates the complete Concrete Velodrome Finish Arena mesh object."""
    mesh = bpy.data.meshes.new(f"{name}_Mesh")
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)

    for mat in create_velodrome_materials():
        obj.data.materials.append(mat)

    bm = bmesh.new()
    _build_track_surface_and_infield(bm)
    _build_historic_grandstand(bm)
    bm.to_mesh(mesh)
    bm.free()

    sm.clean_zwift_mesh(obj, merge_distance=0.001)
    sm.apply_zwift_style(obj, auto_smooth_angle_deg=35.0)
    return obj


# =============================================================================
# 2. COBBLE SECTOR PROPS PACK
# =============================================================================

def generate_cobble_sector_gate_mesh(
    name: str = "Cobble_Sector_Gate_5Star",
    location: Tuple[float, float, float] = (-6.0, 0.0, 0.0),
) -> bpy.types.Object:
    """
    Generates a wooden entrance gate for a cobbled sector with a 5-star (*****)
    difficulty plaque mounted on both faces of the overhead signboard.
    """
    mesh = bpy.data.meshes.new(f"{name}_Mesh")
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)

    for mat in create_cobble_props_materials():
        obj.data.materials.append(mat)

    bm = bmesh.new()
    span_half = 3.2
    post_height = 4.0
    beam_z = 3.55

    # Stone footings and vertical oak posts
    for sx in (-span_half, span_half):
        _add_box(bm, center=(sx, 0.0, 0.18), size=(0.44, 0.44, 0.36), mat_index=3)
        _add_box(bm, center=(sx, 0.0, 0.36 + (post_height - 0.36) * 0.5), size=(0.24, 0.24, post_height - 0.36), mat_index=0)
        # Diagonal knee braces
        brace_dir = -1.0 if sx > 0 else 1.0
        _add_beam_between(
            bm,
            (sx, 0.0, 2.55),
            (sx + brace_dir * 0.95, 0.0, beam_z),
            width=0.14,
            height=0.14,
            mat_index=0,
        )

    # Main horizontal crossbeam
    _add_box(bm, center=(0.0, 0.0, beam_z), size=(span_half * 2.0 + 0.9, 0.22, 0.26), mat_index=0)

    # Top protective wooden eave cap
    _add_box(bm, center=(0.0, 0.0, post_height + 0.10), size=(span_half * 2.0 + 1.1, 0.48, 0.14), mat_index=0)

    # Central dark signboard & timber trim frame
    board_w, board_d, board_h = 3.6, 0.14, 1.05
    board_z = beam_z + 0.05
    _add_box(bm, center=(0.0, 0.0, board_z), size=(board_w, board_d, board_h), mat_index=1)
    _add_box(bm, center=(0.0, 0.0, board_z + board_h * 0.5 + 0.04), size=(board_w + 0.16, board_d + 0.06, 0.08), mat_index=0)
    _add_box(bm, center=(0.0, 0.0, board_z - board_h * 0.5 - 0.04), size=(board_w + 0.16, board_d + 0.06, 0.08), mat_index=0)

    # Five sculpted 3D difficulty stars (*****) on both front (-Y) and back (+Y)
    star_spacing = 0.62
    for idx in range(5):
        sx = (idx - 2.0) * star_spacing
        for side_y, sign in ((-board_d * 0.5 - 0.025, -1.0), (board_d * 0.5 + 0.025, 1.0)):
            _add_star_mesh(
                bm,
                center=(sx, side_y, board_z),
                outer_radius=0.22,
                inner_radius=0.09,
                thickness=0.05,
                facing_y_sign=sign,
                mat_index=2,
            )

    bm.to_mesh(mesh)
    bm.free()

    obj.location = location
    sm.clean_zwift_mesh(obj, merge_distance=0.0005)
    sm.apply_zwift_style(obj, auto_smooth_angle_deg=35.0)
    return obj


def generate_cobble_monument_mesh(
    name: str = "Cobble_Roadside_Monument",
    location: Tuple[float, float, float] = (0.0, 0.0, 0.0),
) -> bpy.types.Object:
    """
    Generates a roadside stone monument commemorating a cobbled sector,
    featuring a stepped plinth, tapered granite stele, bronze plaque, and pavé crown.
    """
    mesh = bpy.data.meshes.new(f"{name}_Mesh")
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)

    for mat in create_cobble_props_materials():
        obj.data.materials.append(mat)

    bm = bmesh.new()

    # Stepped granite plinth
    _add_box(bm, center=(0.0, 0.0, 0.14), size=(1.60, 1.60, 0.28), mat_index=3)
    _add_box(bm, center=(0.0, 0.0, 0.40), size=(1.20, 1.20, 0.24), mat_index=3)

    # Tapered stone stele
    _add_tapered_prism(
        bm,
        center_xy=(0.0, 0.0),
        z_bottom=0.52,
        z_top=2.30,
        bottom_size=(0.84, 0.84),
        top_size=(0.56, 0.56),
        mat_index=3,
    )

    # Chamfered capstone
    _add_tapered_prism(
        bm,
        center_xy=(0.0, 0.0),
        z_bottom=2.30,
        z_top=2.52,
        bottom_size=(0.64, 0.64),
        top_size=(0.44, 0.44),
        mat_index=3,
    )

    # Sculpted cobblestone pavé trophy block at the apex
    _add_tapered_prism(
        bm,
        center_xy=(0.0, 0.0),
        z_bottom=2.52,
        z_top=2.84,
        bottom_size=(0.30, 0.24),
        top_size=(0.26, 0.20),
        mat_index=3,
    )

    # Front bronze commemorative plaque
    _add_box(bm, center=(0.0, -0.37, 1.48), size=(0.52, 0.05, 0.72), mat_index=4)

    bm.to_mesh(mesh)
    bm.free()

    obj.location = location
    sm.clean_zwift_mesh(obj, merge_distance=0.0005)
    sm.apply_zwift_style(obj, auto_smooth_angle_deg=35.0)
    return obj


def _add_mud_and_puddle_cluster(
    bm: bmesh.types.BMesh,
    center_xy: Tuple[float, float],
    radius_x: float,
    radius_y: float,
    seed_phase: float,
    segments: int = 18,
) -> None:
    """
    Builds a geometric mud basin with slightly raised outer mud lip and a flat
    mirror-like water puddle sheet (Roughness = 0.08) seated inside.
    """
    cx, cy = center_xy
    outer_ring: List[bmesh.types.BMVert] = []
    rim_ring: List[bmesh.types.BMVert] = []
    basin_ring: List[bmesh.types.BMVert] = []
    water_ring: List[bmesh.types.BMVert] = []

    for i in range(segments):
        ang = 2.0 * math.pi * i / segments
        wobble = 1.0 + 0.18 * math.sin(3.0 * ang + seed_phase) + 0.10 * math.cos(5.0 * ang - seed_phase)
        ux = math.cos(ang) * wobble
        uy = math.sin(ang) * wobble

        outer_ring.append(bm.verts.new((cx + ux * radius_x, cy + uy * radius_y, 0.0)))
        rim_ring.append(bm.verts.new((cx + ux * radius_x * 0.82, cy + uy * radius_y * 0.82, 0.032)))
        basin_ring.append(bm.verts.new((cx + ux * radius_x * 0.64, cy + uy * radius_y * 0.64, 0.004)))
        water_ring.append(bm.verts.new((cx + ux * radius_x * 0.72, cy + uy * radius_y * 0.72, 0.020)))

    mud_center = bm.verts.new((cx, cy, 0.002))
    water_center = bm.verts.new((cx, cy, 0.020))

    for i in range(segments):
        ni = (i + 1) % segments
        f_outer = bm.faces.new((outer_ring[i], rim_ring[i], rim_ring[ni], outer_ring[ni]))
        f_outer.material_index = 5  # Mat_Cobble_Wet_Mud
        f_outer.smooth = True

        f_slope = bm.faces.new((rim_ring[i], basin_ring[i], basin_ring[ni], rim_ring[ni]))
        f_slope.material_index = 5
        f_slope.smooth = True

        f_floor = bm.faces.new((mud_center, basin_ring[i], basin_ring[ni]))
        f_floor.material_index = 5
        f_floor.smooth = True

        f_water = bm.faces.new((water_center, water_ring[i], water_ring[ni]))
        f_water.material_index = 6  # Mat_Cobble_Puddle_Water (Roughness = 0.08)
        f_water.smooth = False


def generate_cobble_mud_puddles_mesh(
    name: str = "Cobble_Mud_Puddles_Set",
    location: Tuple[float, float, float] = (6.0, 0.0, 0.0),
) -> bpy.types.Object:
    """
    Generates a set of geometric mud sheets and reflective water puddles
    with Roughness = 0.08 for a mirror-like water surface.
    """
    mesh = bpy.data.meshes.new(f"{name}_Mesh")
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)

    for mat in create_cobble_props_materials():
        obj.data.materials.append(mat)

    bm = bmesh.new()
    # Main wide sector puddle + two tire-rut puddles
    _add_mud_and_puddle_cluster(bm, center_xy=(0.0, 0.0), radius_x=1.85, radius_y=1.15, seed_phase=0.4, segments=20)
    _add_mud_and_puddle_cluster(bm, center_xy=(-1.45, 1.35), radius_x=1.05, radius_y=0.65, seed_phase=1.7, segments=16)
    _add_mud_and_puddle_cluster(bm, center_xy=(1.50, -1.25), radius_x=1.15, radius_y=0.72, seed_phase=2.9, segments=16)

    bm.to_mesh(mesh)
    bm.free()

    obj.location = location
    sm.clean_zwift_mesh(obj, merge_distance=0.0005)
    sm.apply_zwift_style(obj, auto_smooth_angle_deg=35.0)
    return obj


# =============================================================================
# EXPORT PIPELINE (GLTF 2.0 BINARY)
# =============================================================================

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


def export_all_cobble_monument_props(
    output_dir: str = "assets/3d/environment",
) -> Dict[str, str]:
    """
    Generates and exports:
      1. `velodrome_finish_arena.glb`
      2. `cobble_sector_props.glb`
    """
    for obj in list(bpy.context.scene.objects):
        if obj.type == "MESH":
            bpy.data.objects.remove(obj, do_unlink=True)

    os.makedirs(output_dir, exist_ok=True)
    exported: Dict[str, str] = {}

    # 1. Concrete Velodrome Finish Arena
    velodrome_obj = generate_velodrome_finish_arena_mesh()
    velodrome_path = os.path.join(output_dir, "velodrome_finish_arena.glb")
    exported["velodrome_finish_arena"] = export_glb(velodrome_obj, velodrome_path)
    bpy.data.objects.remove(velodrome_obj, do_unlink=True)

    # 2. Cobble Sector Props Pack
    gate_obj = generate_cobble_sector_gate_mesh(location=(-6.0, 0.0, 0.0))
    monument_obj = generate_cobble_monument_mesh(location=(0.0, 0.0, 0.0))
    puddles_obj = generate_cobble_mud_puddles_mesh(location=(6.0, 0.0, 0.0))

    props_path = os.path.join(output_dir, "cobble_sector_props.glb")
    cobble_pack = [gate_obj, monument_obj, puddles_obj]
    exported["cobble_sector_props"] = export_glb(cobble_pack, props_path)

    for obj in cobble_pack:
        bpy.data.objects.remove(obj, do_unlink=True)

    return exported


# =============================================================================
# CLI EXECUTION ENTRY POINT
# =============================================================================

if __name__ == "__main__":
    out_dir = "assets/3d/environment"
    for idx, arg in enumerate(sys.argv):
        if arg in ["--output-dir", "-o"] and idx + 1 < len(sys.argv):
            out_dir = sys.argv[idx + 1]

    files = export_all_cobble_monument_props(output_dir=out_dir)
    sm.setup_zwift_studio_lighting()
    print(f"[SUCCESS] Cobble & Monument 3D assets generated: {files}")
