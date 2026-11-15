"""
===============================================================================
PRO PELOTON MANAGER - ENVIRONMENT & ROADSIDE SCENERY ASSETS GENERATOR
===============================================================================
Blender Python API (bpy) script that procedurally generates optimized (Low/Mid-Poly)
roadside scenery and terrain environment assets designed for real-time mobile
rendering without CPU/GPU bottlenecks in Flutter 3D:

  1. Drzewa (Trees):
     - Sosna Alpejska (`Tree_Alpine_Pine`): Tiered evergreen conifer for Alpine/Pyrenean stages
     - Cyprys Włoski (`Tree_Italian_Cypress`): Slender columnar cypress for Italian/Tuscan stages
     - Drzewo Liściaste (`Tree_Deciduous_Oak`): Volumetric lush green canopy for classic stages
  2. Skały Górskie (`Rock_Mountain_Boulder`):
     - Angular faceted alpine granite boulder with fractured crystalline planes
  3. Ośnieżone Szczyty w Tle (`Mountain_Snow_Peak`):
     - Dramatic craggy alpine mountain range with rock base and glistening white snowpack
  4. Budynki Europejskich Miasteczek (`Building_European_Townhouse`):
     - 2-story Provençal/Flemish townhouse with warm stucco, terracotta roof, and shuttered windows
  5. Kibice Szosowi przy Barierkach (`Spectators_Barrier_Cluster`):
     - Modular cluster of 4 passionate fans (arms raised cheering, waving cycling flag, filming)

Master Output: `assets/3d/environment/env_pack.glb`
Standalone Props: `tree_pine.glb`, `tree_cypress.glb`, `tree_deciduous.glb`,
                  `rock_boulder.glb`, `mountain_peak.glb`, `building_townhouse.glb`,
                  `spectators_cheering.glb`

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
    print("        blender --background --python blender_scripts/generate_environment_assets.py")
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


def add_cone_mesh(
    bm: bmesh.types.BMesh,
    base_center: Tuple[float, float, float],
    radius: float,
    height: float,
    segments: int = 8,
    mat_index: int = 0,
    cap_base: bool = True,
    smooth: bool = True,
) -> List[bmesh.types.BMFace]:
    """Builds a conical frustum or pointed cone."""
    bx, by, bz = base_center
    apex = bm.verts.new((bx, by, bz + height))
    base_ring: List[bmesh.types.BMVert] = []

    for i in range(segments):
        angle = 2.0 * math.pi * i / segments
        vx = bx + radius * math.cos(angle)
        vy = by + radius * math.sin(angle)
        base_ring.append(bm.verts.new((vx, vy, bz)))

    faces: List[bmesh.types.BMFace] = []
    for i in range(segments):
        next_i = (i + 1) % segments
        f = bm.faces.new((base_ring[i], base_ring[next_i], apex))
        f.material_index = mat_index
        f.smooth = smooth
        faces.append(f)

    if cap_base:
        f_base = bm.faces.new(list(reversed(base_ring)))
        f_base.material_index = mat_index
        f_base.smooth = False
        faces.append(f_base)

    return faces


# =============================================================================
# PBR MATERIAL FACTORIES FOR ENVIRONMENT ASSETS
# =============================================================================

def create_pine_foliage_material(name: str = "M_Foliage_Alpine_Pine") -> bpy.types.Material:
    """Deep forest evergreen pine needles material with organic roughness."""
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)
    sm._set_bsdf_socket(bsdf, ["Base Color"], sm.hex_to_linear_rgb("#166534"))
    sm._set_bsdf_socket(bsdf, ["Metallic"], 0.0)
    sm._set_bsdf_socket(bsdf, ["Roughness"], 0.55)
    return mat


def create_cypress_foliage_material(name: str = "M_Foliage_Italian_Cypress") -> bpy.types.Material:
    """Rich emerald Mediterranean columnar cypress foliage."""
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)
    sm._set_bsdf_socket(bsdf, ["Base Color"], sm.hex_to_linear_rgb("#064E3B"))
    sm._set_bsdf_socket(bsdf, ["Metallic"], 0.0)
    sm._set_bsdf_socket(bsdf, ["Roughness"], 0.50)
    return mat


def create_deciduous_foliage_material(name: str = "M_Foliage_Deciduous_Lush") -> bpy.types.Material:
    """Vibrant summer deciduous leaf canopy."""
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)
    sm._set_bsdf_socket(bsdf, ["Base Color"], sm.hex_to_linear_rgb("#22C55E"))
    sm._set_bsdf_socket(bsdf, ["Metallic"], 0.0)
    sm._set_bsdf_socket(bsdf, ["Roughness"], 0.52)
    return mat


def create_wood_bark_material(name: str = "M_Wood_Trunk_Bark") -> bpy.types.Material:
    """Weathered organic tree trunk bark material."""
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)
    sm._set_bsdf_socket(bsdf, ["Base Color"], sm.hex_to_linear_rgb("#582F0E"))
    sm._set_bsdf_socket(bsdf, ["Metallic"], 0.0)
    sm._set_bsdf_socket(bsdf, ["Roughness"], 0.85)
    return mat


def create_granite_rock_material(name: str = "M_Granite_Rock_Alpine") -> bpy.types.Material:
    """Faceted alpine granite rock face with crystalline roughness."""
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)
    sm._set_bsdf_socket(bsdf, ["Base Color"], sm.hex_to_linear_rgb("#64748B"))
    sm._set_bsdf_socket(bsdf, ["Metallic"], 0.05)
    sm._set_bsdf_socket(bsdf, ["Roughness"], 0.78)
    return mat


def create_mountain_snow_material(name: str = "M_Mountain_Snow_Glist") -> bpy.types.Material:
    """High-altitude glistening snowpack material."""
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)
    sm._set_bsdf_socket(bsdf, ["Base Color"], sm.hex_to_linear_rgb("#F8FAFC"))
    sm._set_bsdf_socket(bsdf, ["Metallic"], 0.0)
    sm._set_bsdf_socket(bsdf, ["Roughness"], 0.25)
    sm._set_bsdf_socket(bsdf, ["Specular IOR Level", "Specular"], 0.85)
    return mat


def create_townhouse_wall_material(name: str = "M_Townhouse_Stucco_Warm") -> bpy.types.Material:
    """Warm European Provençal stucco plaster wall."""
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)
    sm._set_bsdf_socket(bsdf, ["Base Color"], sm.hex_to_linear_rgb("#FEF3C7"))
    sm._set_bsdf_socket(bsdf, ["Metallic"], 0.0)
    sm._set_bsdf_socket(bsdf, ["Roughness"], 0.82)
    return mat


def create_terracotta_roof_material(name: str = "M_Roof_Terracotta_Clay") -> bpy.types.Material:
    """Mediterranean baked clay terracotta roof tiles."""
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)
    sm._set_bsdf_socket(bsdf, ["Base Color"], sm.hex_to_linear_rgb("#C2410C"))
    sm._set_bsdf_socket(bsdf, ["Metallic"], 0.0)
    sm._set_bsdf_socket(bsdf, ["Roughness"], 0.70)
    return mat


def create_spectator_color_material(hex_color: str, name: str) -> bpy.types.Material:
    """Casual fabric material for spectator clothing and caps."""
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)
    sm._set_bsdf_socket(bsdf, ["Base Color"], sm.hex_to_linear_rgb(hex_color))
    sm._set_bsdf_socket(bsdf, ["Metallic"], 0.0)
    sm._set_bsdf_socket(bsdf, ["Roughness"], 0.65)
    return mat


# =============================================================================
# 1. GENERATE PROCEDURAL TREES (ALPINE PINE, CYPRESS, DECIDUOUS)
# =============================================================================

def generate_pine_tree_mesh(name: str = "Tree_Alpine_Pine") -> bpy.types.Object:
    """
    Procedurally constructs an optimized Low/Mid-Poly Alpine Pine Tree:
      - 7.8m height, tapered wooden trunk
      - 4 tiered conical needle skirts with organic fluting
    """
    mesh = bpy.data.meshes.new(f"{name}_Data")
    obj = bpy.data.objects.new(name, mesh)
    if obj.name not in bpy.context.scene.collection.objects:
        bpy.context.scene.collection.objects.link(obj)
    bm = bmesh.new()

    mat_trunk = create_wood_bark_material()
    mat_pine = create_pine_foliage_material()
    obj.data.materials.append(mat_trunk)  # Index 0
    obj.data.materials.append(mat_pine)   # Index 1

    # 1. Wooden Trunk
    add_cylinder_between(bm, (0.0, 0.0, 0.0), (0.0, 0.0, 6.5), 0.22, 6, mat_index=0)

    # 2. Four Tiered Conical Foliage Skirts
    # Tier 1 (bottom): Z = 1.8m, radius 2.2m, height 2.2m
    add_cone_mesh(bm, base_center=(0.0, 0.0, 1.8), radius=2.20, height=2.20, segments=10, mat_index=1, cap_base=True, smooth=True)
    # Tier 2: Z = 3.2m, radius 1.75m, height 2.0m
    add_cone_mesh(bm, base_center=(0.0, 0.0, 3.2), radius=1.75, height=2.00, segments=10, mat_index=1, cap_base=True, smooth=True)
    # Tier 3: Z = 4.6m, radius 1.30m, height 1.8m
    add_cone_mesh(bm, base_center=(0.0, 0.0, 4.6), radius=1.30, height=1.80, segments=9, mat_index=1, cap_base=True, smooth=True)
    # Tier 4 (apex): Z = 5.8m, radius 0.85m, height 2.0m (tip at 7.8m)
    add_cone_mesh(bm, base_center=(0.0, 0.0, 5.8), radius=0.85, height=2.00, segments=8, mat_index=1, cap_base=True, smooth=True)

    bm.to_mesh(mesh)
    bm.free()
    sm.apply_zwift_style(obj, auto_smooth_angle_deg=35.0)
    return obj


def generate_cypress_tree_mesh(name: str = "Tree_Italian_Cypress") -> bpy.types.Object:
    """
    Procedurally constructs a slender Italian/Tuscan Columnar Cypress Tree:
      - 9.2m height, 1.2m max width
      - Slender flame-shaped columnar silhouette
    """
    mesh = bpy.data.meshes.new(f"{name}_Data")
    obj = bpy.data.objects.new(name, mesh)
    if obj.name not in bpy.context.scene.collection.objects:
        bpy.context.scene.collection.objects.link(obj)
    bm = bmesh.new()

    mat_trunk = create_wood_bark_material()
    mat_cypress = create_cypress_foliage_material()
    obj.data.materials.append(mat_trunk)    # Index 0
    obj.data.materials.append(mat_cypress)  # Index 1

    # 1. Exposed Trunk Base
    add_cylinder_between(bm, (0.0, 0.0, 0.0), (0.0, 0.0, 1.2), 0.16, 6, mat_index=0)

    # 2. Slender Columnar Flame-Shaped Foliage Loft
    # Lofted rings along height: (Z, radius)
    profile = [
        (1.0, 0.28),
        (2.0, 0.48),
        (3.5, 0.62),
        (5.2, 0.60),
        (7.0, 0.48),
        (8.2, 0.30),
        (9.2, 0.02),  # Tapered apex tip
    ]
    rings: List[List[bmesh.types.BMVert]] = []
    segments = 8
    for pz, pr in profile:
        ring: List[bmesh.types.BMVert] = []
        for s in range(segments):
            angle = 2.0 * math.pi * s / segments
            vx = pr * math.cos(angle)
            vy = pr * math.sin(angle)
            ring.append(bm.verts.new((vx, vy, pz)))
        rings.append(ring)

    # Loft rings
    for r in range(len(rings) - 1):
        r1 = rings[r]
        r2 = rings[r + 1]
        for s in range(segments):
            next_s = (s + 1) % segments
            f = bm.faces.new((r1[s], r2[s], r2[next_s], r1[next_s]))
            f.material_index = 1
            f.smooth = True

    # Cap bottom ring
    f_bot = bm.faces.new(list(reversed(rings[0])))
    f_bot.material_index = 1
    f_bot.smooth = False

    bm.to_mesh(mesh)
    bm.free()
    sm.apply_zwift_style(obj, auto_smooth_angle_deg=35.0)
    return obj


def generate_deciduous_tree_mesh(name: str = "Tree_Deciduous_Oak") -> bpy.types.Object:
    """
    Procedurally constructs a lush summer European Deciduous Tree:
      - 7.2m height, 5.4m canopy spread
      - Branching wooden trunk and 3 organic volumetric canopy clusters
    """
    mesh = bpy.data.meshes.new(f"{name}_Data")
    obj = bpy.data.objects.new(name, mesh)
    if obj.name not in bpy.context.scene.collection.objects:
        bpy.context.scene.collection.objects.link(obj)
    bm = bmesh.new()

    mat_trunk = create_wood_bark_material()
    mat_leaves = create_deciduous_foliage_material()
    obj.data.materials.append(mat_trunk)   # Index 0
    obj.data.materials.append(mat_leaves)  # Index 1

    # 1. Branching Wooden Trunk
    # Main trunk
    add_cylinder_between(bm, (0.0, 0.0, 0.0), (0.0, 0.0, 2.6), 0.28, 6, mat_index=0)
    # Left branch
    add_cylinder_between(bm, (0.0, 0.0, 2.4), (-0.8, 0.3, 4.2), 0.16, 6, mat_index=0)
    # Right branch
    add_cylinder_between(bm, (0.0, 0.0, 2.4), (0.8, -0.2, 4.4), 0.16, 6, mat_index=0)
    # Center upper stem
    add_cylinder_between(bm, (0.0, 0.0, 2.4), (0.0, 0.0, 4.6), 0.18, 6, mat_index=0)

    # 2. Three Volumetric Puffy Canopy Clusters (Low-poly dodecahedrons/boxes)
    # Main Center Crown
    add_box(bm, center=(0.0, 0.0, 5.4), size=(3.4, 3.4, 2.8), mat_index=1)
    # Left Canopy Flank
    add_box(bm, center=(-1.2, 0.4, 4.5), size=(2.4, 2.4, 2.2), mat_index=1)
    # Right Canopy Flank
    add_box(bm, center=(1.2, -0.3, 4.6), size=(2.4, 2.4, 2.2), mat_index=1)

    bm.to_mesh(mesh)
    bm.free()
    sm.apply_zwift_style(obj, auto_smooth_angle_deg=40.0)
    return obj


# =============================================================================
# 2. GENERATE MOUNTAIN BOULDER & DISTANT SNOW-CAPPED PEAK
# =============================================================================

def generate_mountain_boulder_mesh(name: str = "Rock_Mountain_Boulder") -> bpy.types.Object:
    """
    Procedurally constructs an angular, faceted alpine granite rock boulder:
      - 3.2m width, 2.4m depth, 1.85m height
      - Fractured crystalline joint planes catching sharp sunlight
    """
    mesh = bpy.data.meshes.new(f"{name}_Data")
    obj = bpy.data.objects.new(name, mesh)
    if obj.name not in bpy.context.scene.collection.objects:
        bpy.context.scene.collection.objects.link(obj)
    bm = bmesh.new()

    mat_rock = create_granite_rock_material()
    obj.data.materials.append(mat_rock)  # Index 0

    # Low-poly faceted rock vertices (10 vertices creating 16 planar facets)
    verts_data = [
        # Base ring (Z = 0.0)
        (-1.50, -1.00, 0.0),  # v0
        (0.40, -1.15, 0.0),   # v1
        (1.55, -0.40, 0.0),   # v2
        (1.25, 0.95, 0.0),    # v3
        (-0.35, 1.15, 0.0),   # v4
        (-1.45, 0.65, 0.0),   # v5
        # Mid-level facet vertices (Z = 1.0m to 1.3m)
        (-1.20, -0.65, 1.10), # v6
        (0.60, -0.85, 1.25),  # v7
        (1.05, 0.55, 1.15),   # v8
        (-0.55, 0.75, 1.30),  # v9
        # Top apex ridge vertices (Z = 1.85m)
        (-0.25, -0.20, 1.85), # v10
        (0.35, 0.15, 1.75),   # v11
    ]
    bm_v = [bm.verts.new(v) for v in verts_data]

    # Rock facets
    facets = [
        # Bottom face
        (bm_v[5], bm_v[4], bm_v[3], bm_v[2], bm_v[1], bm_v[0]),
        # Lower side walls
        (bm_v[0], bm_v[1], bm_v[7], bm_v[6]),
        (bm_v[1], bm_v[2], bm_v[8], bm_v[7]),
        (bm_v[2], bm_v[3], bm_v[8]),
        (bm_v[3], bm_v[4], bm_v[9], bm_v[8]),
        (bm_v[4], bm_v[5], bm_v[9]),
        (bm_v[5], bm_v[0], bm_v[6], bm_v[9]),
        # Upper facets towards apex ridge
        (bm_v[6], bm_v[7], bm_v[10]),
        (bm_v[7], bm_v[8], bm_v[11], bm_v[10]),
        (bm_v[8], bm_v[9], bm_v[11]),
        (bm_v[9], bm_v[6], bm_v[10]),
        # Top cap
        (bm_v[10], bm_v[11], bm_v[8]),
    ]
    for face_verts in facets:
        f = bm.faces.new(face_verts)
        f.material_index = 0
        f.smooth = False  # Crisp, faceted rock planes

    bm.to_mesh(mesh)
    bm.free()
    sm.apply_zwift_style(obj, auto_smooth_angle_deg=25.0)
    return obj


def generate_mountain_snow_peak_mesh(name: str = "Mountain_Snow_Peak") -> bpy.types.Object:
    """
    Procedurally constructs a majestic distant alpine mountain peak with snowpack:
      - 75.0m width, 40.0m depth, 32.0m height
      - Lower slate rock scree slopes and glistening white snowcapped horns
    """
    mesh = bpy.data.meshes.new(f"{name}_Data")
    obj = bpy.data.objects.new(name, mesh)
    if obj.name not in bpy.context.scene.collection.objects:
        bpy.context.scene.collection.objects.link(obj)
    bm = bmesh.new()

    mat_rock = sm._get_or_create_material("M_Mountain_Slate_Rock")
    sm._set_bsdf_socket(sm._get_or_create_output_nodes(mat_rock)[0], ["Base Color"], sm.hex_to_linear_rgb("#334155"))
    sm._set_bsdf_socket(sm._get_or_create_output_nodes(mat_rock)[0], ["Roughness"], 0.85)

    mat_snow = create_mountain_snow_material()

    obj.data.materials.append(mat_rock)  # Index 0
    obj.data.materials.append(mat_snow)  # Index 1

    # Mountain Vertices:
    # Base perimeter (Z = 0.0m)
    v_b1 = bm.verts.new((-38.0, -20.0, 0.0))
    v_b2 = bm.verts.new((0.0, -22.0, 0.0))
    v_b3 = bm.verts.new((38.0, -18.0, 0.0))
    v_b4 = bm.verts.new((35.0, 18.0, 0.0))
    v_b5 = bm.verts.new((0.0, 20.0, 0.0))
    v_b6 = bm.verts.new((-36.0, 18.0, 0.0))

    # Snowline mid-ridge vertices (Z = 16.0m to 19.0m)
    v_s1 = bm.verts.new((-16.0, -8.0, 16.5))
    v_s2 = bm.verts.new((0.0, -10.0, 18.5))
    v_s3 = bm.verts.new((15.0, -7.0, 16.0))
    v_s4 = bm.verts.new((12.0, 9.0, 16.5))
    v_s5 = bm.verts.new((0.0, 10.0, 18.0))
    v_s6 = bm.verts.new((-14.0, 8.0, 16.0))

    # Horn Peaks (Z = 24.0m to 32.0m)
    v_horn_main = bm.verts.new((0.0, 0.0, 32.0))      # Central summit
    v_horn_left = bm.verts.new((-18.0, 2.0, 22.0))    # Left sub-peak
    v_horn_right = bm.verts.new((20.0, -2.0, 21.0))   # Right sub-peak

    # 1. Lower Rock Faces (Material Index 0: M_Mountain_Slate_Rock)
    rock_faces = [
        (v_b1, v_b2, v_s2, v_s1),
        (v_b2, v_b3, v_s3, v_s2),
        (v_b3, v_b4, v_s4, v_s3),
        (v_b4, v_b5, v_s5, v_s4),
        (v_b5, v_b6, v_s6, v_s5),
        (v_b6, v_b1, v_s1, v_s6),
        # Flank ridge rock connectors
        (v_b1, v_s1, v_horn_left),
        (v_b6, v_horn_left, v_s6),
        (v_b3, v_horn_right, v_s3),
        (v_b4, v_s4, v_horn_right),
    ]
    for rf in rock_faces:
        f = bm.faces.new(rf)
        f.material_index = 0
        f.smooth = True

    # 2. Upper Snow-Capped Peak Faces (Material Index 1: M_Mountain_Snow)
    snow_faces = [
        (v_s1, v_s2, v_horn_main),
        (v_s2, v_s3, v_horn_main),
        (v_s3, v_s4, v_horn_main),
        (v_s4, v_s5, v_horn_main),
        (v_s5, v_s6, v_horn_main),
        (v_s6, v_s1, v_horn_main),
        # Connecting horns
        (v_s1, v_horn_main, v_horn_left),
        (v_s6, v_horn_left, v_horn_main),
        (v_s3, v_horn_right, v_horn_main),
        (v_s4, v_horn_main, v_horn_right),
    ]
    for sf in snow_faces:
        f = bm.faces.new(sf)
        f.material_index = 1
        f.smooth = True

    bm.to_mesh(mesh)
    bm.free()
    sm.apply_zwift_style(obj, auto_smooth_angle_deg=35.0)
    return obj


# =============================================================================
# 3. GENERATE EUROPEAN VILLAGE TOWNHOUSE
# =============================================================================

def generate_european_townhouse_mesh(name: str = "Building_European_Townhouse") -> bpy.types.Object:
    """
    Procedurally constructs a charming European roadside village townhouse:
      - 6.2m wide, 7.2m deep, 8.8m total roof ridge height
      - Warm Provençal stucco, terracotta clay tile pitched roof, chimney
      - Ground floor front door, shopfront windows, shuttered 2nd floor windows
    """
    mesh = bpy.data.meshes.new(f"{name}_Data")
    obj = bpy.data.objects.new(name, mesh)
    if obj.name not in bpy.context.scene.collection.objects:
        bpy.context.scene.collection.objects.link(obj)
    bm = bmesh.new()

    # Materials:
    # 0: Stucco Plaster Warm (#FEF3C7)
    # 1: Terracotta Roof Clay (#C2410C)
    # 2: Wooden Door & Window Frames (#582F0E)
    # 3: Window Shutters Pastel Blue (#38BDF8)
    # 4: Tinted Window Glass (#0F172A)
    # 5: Sidewalk Plinth Concrete (#94A3B8)
    mat_stucco = create_townhouse_wall_material()
    mat_roof = create_terracotta_roof_material()
    mat_wood = create_wood_bark_material()
    mat_shutters = sm._get_or_create_material("M_Window_Shutters_Blue")
    sm._set_bsdf_socket(sm._get_or_create_output_nodes(mat_shutters)[0], ["Base Color"], sm.hex_to_linear_rgb("#38BDF8"))
    sm._set_bsdf_socket(sm._get_or_create_output_nodes(mat_shutters)[0], ["Roughness"], 0.40)

    mat_glass = sm._get_or_create_material("M_Town_Window_Glass")
    sm._set_bsdf_socket(sm._get_or_create_output_nodes(mat_glass)[0], ["Base Color"], sm.hex_to_linear_rgb("#0F172A"))
    sm._set_bsdf_socket(sm._get_or_create_output_nodes(mat_glass)[0], ["Roughness"], 0.10)

    mat_concrete = sm._get_or_create_material("M_Sidewalk_Concrete")
    sm._set_bsdf_socket(sm._get_or_create_output_nodes(mat_concrete)[0], ["Base Color"], sm.hex_to_linear_rgb("#94A3B8"))
    sm._set_bsdf_socket(sm._get_or_create_output_nodes(mat_concrete)[0], ["Roughness"], 0.75)

    for m in [mat_stucco, mat_roof, mat_wood, mat_shutters, mat_glass, mat_concrete]:
        obj.data.materials.append(m)

    house_w = 6.20
    house_d = 7.20
    wall_h = 6.40

    # 1. Sidewalk Foundation Plinth (Z = 0.0 to 0.18m)
    add_box(bm, center=(0.0, 0.0, 0.09), size=(house_w + 0.80, house_d + 0.80, 0.18), mat_index=5)

    # 2. Main 2-Story Building Stucco Body (Z = 0.18m to 6.40m)
    add_box(bm, center=(0.0, 0.0, wall_h * 0.5 + 0.09), size=(house_w, house_d, wall_h), mat_index=0)

    # 3. Pitched Terracotta Roof with Overhanging Eaves (Ridge along Y axis)
    roof_w = house_w + 0.60
    roof_d = house_d + 0.60
    ridge_h = 2.40  # Total height = 6.4 + 2.4 = 8.8m
    # Left roof slope
    add_box(bm, center=(-roof_w * 0.25, 0.0, wall_h + ridge_h * 0.45), size=(roof_w * 0.55, roof_d, 0.16), mat_index=1)
    # Right roof slope
    add_box(bm, center=(roof_w * 0.25, 0.0, wall_h + ridge_h * 0.45), size=(roof_w * 0.55, roof_d, 0.16), mat_index=1)
    # Roof ridge cap
    add_box(bm, center=(0.0, 0.0, wall_h + ridge_h - 0.02), size=(0.28, roof_d, 0.14), mat_index=1)

    # Chimney stack
    add_box(bm, center=(1.60, 1.20, wall_h + 1.80), size=(0.75, 0.75, 1.40), mat_index=1)

    # 4. Ground Floor (Front Door & Windows on front face Y = -house_d * 0.5)
    front_y = -house_d * 0.5 - 0.01
    # Wooden front entrance door
    add_box(bm, center=(0.0, front_y, 1.25), size=(1.15, 0.04, 2.15), mat_index=2)
    # Ground floor flanking windows
    for wx in [-1.90, 1.90]:
        add_box(bm, center=(wx, front_y, 1.40), size=(1.20, 0.03, 1.50), mat_index=4)
        # Wooden window lintel & frame
        add_box(bm, center=(wx, front_y - 0.02, 2.22), size=(1.35, 0.06, 0.14), mat_index=2)

    # 5. Upper Floor (3 Shuttered Windows on front face)
    for wx in [-1.90, 0.0, 1.90]:
        # Window glass
        add_box(bm, center=(wx, front_y, 4.40), size=(0.95, 0.03, 1.35), mat_index=4)
        # Left shutter (Pastel Blue)
        add_box(bm, center=(wx - 0.62, front_y - 0.02, 4.40), size=(0.42, 0.03, 1.40), mat_index=3)
        # Right shutter
        add_box(bm, center=(wx + 0.62, front_y - 0.02, 4.40), size=(0.42, 0.03, 1.40), mat_index=3)
        # Flower window box
        add_box(bm, center=(wx, front_y - 0.08, 3.65), size=(1.10, 0.20, 0.18), mat_index=1)

    bm.to_mesh(mesh)
    bm.free()
    sm.apply_zwift_style(obj, auto_smooth_angle_deg=35.0)
    return obj


# =============================================================================
# 4. GENERATE SPECTATORS CHEERING AT BARRIERS (`Spectators_Barrier_Cluster`)
# =============================================================================

def add_stylized_spectator(
    bm: bmesh.types.BMesh,
    origin: Tuple[float, float, float],
    mat_shirt: int = 0,
    mat_skin: int = 1,
    mat_shorts: int = 2,
    mat_cap: int = 3,
    pose: str = "cheer_arms_up",
) -> List[bmesh.types.BMFace]:
    """
    Constructs a stylized low/mid-poly spectator mesh (~140 polys) in an energetic
    cheering pose suitable for lining the barriers and roadsides.
    """
    ox, oy, oz = origin
    faces: List[bmesh.types.BMFace] = []

    # Shoes (left & right)
    faces.extend(add_box(bm, center=(ox - 0.12, oy, oz + 0.05), size=(0.11, 0.22, 0.09), mat_index=mat_shorts))
    faces.extend(add_box(bm, center=(ox + 0.12, oy, oz + 0.05), size=(0.11, 0.22, 0.09), mat_index=mat_shorts))

    # Legs (shorts & skin)
    faces.extend(add_cylinder_between(bm, (ox - 0.12, oy, oz + 0.10), (ox - 0.12, oy, oz + 0.50), 0.065, 6, mat_skin))
    faces.extend(add_cylinder_between(bm, (ox + 0.12, oy, oz + 0.10), (ox + 0.12, oy, oz + 0.50), 0.065, 6, mat_skin))
    # Shorts
    faces.extend(add_box(bm, center=(ox, oy, oz + 0.62), size=(0.34, 0.24, 0.26), mat_index=mat_shorts))

    # Torso (T-shirt / jersey)
    faces.extend(add_box(bm, center=(ox, oy, oz + 0.98), size=(0.38, 0.25, 0.46), mat_index=mat_shirt))

    # Head (skin & cap)
    faces.extend(add_box(bm, center=(ox, oy, oz + 1.34), size=(0.20, 0.20, 0.22), mat_index=mat_skin))
    # Cycling cap with peak brim
    faces.extend(add_box(bm, center=(ox, oy, oz + 1.44), size=(0.22, 0.22, 0.08), mat_index=mat_cap))
    faces.extend(add_box(bm, center=(ox, oy - 0.14, oz + 1.42), size=(0.20, 0.12, 0.02), mat_index=mat_cap))

    # Arms and Props based on Pose
    if pose == "cheer_arms_up":
        # Both arms raised high V-shape pumping fists
        faces.extend(add_cylinder_between(bm, (ox - 0.19, oy, oz + 1.15), (ox - 0.32, oy - 0.05, oz + 1.62), 0.045, 6, mat_shirt))
        faces.extend(add_cylinder_between(bm, (ox + 0.19, oy, oz + 1.15), (ox + 0.32, oy - 0.05, oz + 1.62), 0.045, 6, mat_shirt))
        # Fists (skin)
        faces.extend(add_box(bm, center=(ox - 0.33, oy - 0.05, oz + 1.66), size=(0.07, 0.07, 0.07), mat_index=mat_skin))
        faces.extend(add_box(bm, center=(ox + 0.33, oy - 0.05, oz + 1.66), size=(0.07, 0.07, 0.07), mat_index=mat_skin))

    elif pose == "flag_waver":
        # Right arm holding tall flagpole waving flag
        faces.extend(add_cylinder_between(bm, (ox + 0.19, oy, oz + 1.15), (ox + 0.28, oy - 0.18, oz + 1.45), 0.045, 6, mat_shirt))
        faces.extend(add_cylinder_between(bm, (ox - 0.19, oy, oz + 1.15), (ox - 0.24, oy - 0.10, oz + 0.95), 0.045, 6, mat_shirt))
        # Wooden flagpole (2.4m tall)
        faces.extend(add_cylinder_between(bm, (ox + 0.28, oy - 0.18, oz + 0.50), (ox + 0.28, oy - 0.28, oz + 2.70), 0.016, 6, mat_cap))
        # Large wavy flag banner (1.1m x 0.7m)
        faces.extend(add_box(bm, center=(ox + 0.78, oy - 0.28, oz + 2.25), size=(1.00, 0.015, 0.65), mat_index=mat_shirt))

    elif pose == "filming_phone":
        # Both hands forward holding smartphone filming the riders
        faces.extend(add_cylinder_between(bm, (ox - 0.19, oy, oz + 1.15), (ox - 0.08, oy - 0.35, oz + 1.25), 0.045, 6, mat_shirt))
        faces.extend(add_cylinder_between(bm, (ox + 0.19, oy, oz + 1.15), (ox + 0.08, oy - 0.35, oz + 1.25), 0.045, 6, mat_shirt))
        # Smartphone device
        faces.extend(add_box(bm, center=(ox, oy - 0.38, oz + 1.25), size=(0.14, 0.015, 0.08), mat_index=mat_shorts))

    else:
        # Lean on barrier, clapping
        faces.extend(add_cylinder_between(bm, (ox - 0.19, oy, oz + 1.15), (ox - 0.10, oy - 0.28, oz + 1.05), 0.045, 6, mat_shirt))
        faces.extend(add_cylinder_between(bm, (ox + 0.19, oy, oz + 1.15), (ox + 0.10, oy - 0.28, oz + 1.05), 0.045, 6, mat_shirt))

    return faces


def generate_spectators_cluster_mesh(name: str = "Spectators_Barrier_Cluster") -> bpy.types.Object:
    """
    Procedurally constructs an optimized cluster of 4 enthusiastic cycling fans
    lining the course:
      - Fan 1: Yellow Tour Jersey waving both arms in the air
      - Fan 2: Passionate fan waving a large cycling flag on a tall pole
      - Fan 3: Fan holding up a smartphone filming the peloton
      - Fan 4: Fan leaning forward cheering and shouting
    """
    mesh = bpy.data.meshes.new(f"{name}_Data")
    obj = bpy.data.objects.new(name, mesh)
    if obj.name not in bpy.context.scene.collection.objects:
        bpy.context.scene.collection.objects.link(obj)
    bm = bmesh.new()

    # Materials:
    # 0: Fan Yellow (Tour Jersey #FACC15)
    # 1: Skin Tone (#E0A899)
    # 2: Denim Shorts / Navy (#1E3A8A)
    # 3: Cycling Cap / Flagpole Wood (#DC2626)
    # 4: Fan Red (#DC2626)
    # 5: Fan Cyan/Blue (#0284C7)
    # 6: Fan Green (#16A34A)
    mat_yellow = create_spectator_color_material("#FACC15", "M_Spectator_Yellow")
    mat_skin = create_spectator_color_material("#E0A899", "M_Spectator_Skin")
    mat_navy = create_spectator_color_material("#1E3A8A", "M_Spectator_Navy")
    mat_red = create_spectator_color_material("#DC2626", "M_Spectator_Red")
    mat_cyan = create_spectator_color_material("#0284C7", "M_Spectator_Cyan")
    mat_green = create_spectator_color_material("#16A34A", "M_Spectator_Green")

    for m in [mat_yellow, mat_skin, mat_navy, mat_red, mat_cyan, mat_green]:
        obj.data.materials.append(m)

    # Fan 1 (Left): Yellow Jersey, Arms Raised Up Cheering
    add_stylized_spectator(bm, origin=(-1.05, 0.0, 0.0), mat_shirt=0, mat_skin=1, mat_shorts=2, mat_cap=3, pose="cheer_arms_up")

    # Fan 2 (Center-Left): Red Shirt, Waving Big Flag
    add_stylized_spectator(bm, origin=(-0.35, 0.12, 0.0), mat_shirt=3, mat_skin=1, mat_shorts=2, mat_cap=0, pose="flag_waver")

    # Fan 3 (Center-Right): Cyan Shirt, Filming with Smartphone
    add_stylized_spectator(bm, origin=(0.35, -0.05, 0.0), mat_shirt=4, mat_skin=1, mat_shorts=2, mat_cap=5, pose="filming_phone")

    # Fan 4 (Right): Green Jersey, Leaning and Cheering
    add_stylized_spectator(bm, origin=(1.05, 0.05, 0.0), mat_shirt=5, mat_skin=1, mat_shorts=2, mat_cap=3, pose="cheer_arms_up")

    bm.to_mesh(mesh)
    bm.free()
    sm.apply_zwift_style(obj, auto_smooth_angle_deg=40.0)
    return obj


# =============================================================================
# EXPORT PIPELINE (GLTF 2.0 BINARY)
# =============================================================================

def export_environment_asset(
    objects: Union[bpy.types.Object, List[bpy.types.Object]],
    filepath: str,
) -> str:
    """Exports single or multiple environment objects to an optimized glTF 2.0 binary file."""
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


def export_all_environment_assets(output_dir: str = "assets/3d/environment") -> Dict[str, str]:
    """
    Procedurally models and exports the full suite of roadside environment assets:
      1. `env_pack.glb`: Complete master pack containing all 7 environment props.
      2. `tree_pine.glb`: Standalone Alpine Pine Tree.
      3. `tree_cypress.glb`: Standalone Italian Columnar Cypress Tree.
      4. `tree_deciduous.glb`: Standalone Lush Deciduous Oak Tree.
      5. `rock_boulder.glb`: Standalone Alpine Granite Boulder.
      6. `mountain_peak.glb`: Standalone Distant Snow-Capped Mountain Peak.
      7. `building_townhouse.glb`: Standalone European Village Townhouse.
      8. `spectators_cheering.glb`: Standalone Cluster of Cheering Fans.
    """
    # Clean active scene mesh objects
    for obj in list(bpy.context.scene.objects):
        if obj.type == "MESH":
            bpy.data.objects.remove(obj, do_unlink=True)

    print("\n" + "=" * 75)
    print("PRO PELOTON MANAGER: GENERATING ROADSIDE ENVIRONMENT ASSETS")
    print("=" * 75)

    os.makedirs(output_dir, exist_ok=True)
    exported_files: Dict[str, str] = {}

    # 1. Alpine Pine Tree
    obj_pine = generate_pine_tree_mesh(name="Tree_Alpine_Pine")
    p_pine = os.path.join(output_dir, "tree_pine.glb")
    exported_files["tree_pine"] = export_environment_asset(obj_pine, p_pine)

    # 2. Italian Cypress Tree
    obj_cypress = generate_cypress_tree_mesh(name="Tree_Italian_Cypress")
    p_cyp = os.path.join(output_dir, "tree_cypress.glb")
    exported_files["tree_cypress"] = export_environment_asset(obj_cypress, p_cyp)

    # 3. Deciduous Tree
    obj_decid = generate_deciduous_tree_mesh(name="Tree_Deciduous_Oak")
    p_dec = os.path.join(output_dir, "tree_deciduous.glb")
    exported_files["tree_deciduous"] = export_environment_asset(obj_decid, p_dec)

    # 4. Mountain Boulder
    obj_rock = generate_mountain_boulder_mesh(name="Rock_Mountain_Boulder")
    p_rock = os.path.join(output_dir, "rock_boulder.glb")
    exported_files["rock_boulder"] = export_environment_asset(obj_rock, p_rock)

    # 5. Distant Snow Peak
    obj_peak = generate_mountain_snow_peak_mesh(name="Mountain_Snow_Peak")
    p_peak = os.path.join(output_dir, "mountain_peak.glb")
    exported_files["mountain_peak"] = export_environment_asset(obj_peak, p_peak)

    # 6. European Townhouse
    obj_house = generate_european_townhouse_mesh(name="Building_European_Townhouse")
    p_house = os.path.join(output_dir, "building_townhouse.glb")
    exported_files["building_townhouse"] = export_environment_asset(obj_house, p_house)

    # 7. Spectators Cluster
    obj_fans = generate_spectators_cluster_mesh(name="Spectators_Barrier_Cluster")
    p_fans = os.path.join(output_dir, "spectators_cheering.glb")
    exported_files["spectators_cheering"] = export_environment_asset(obj_fans, p_fans)

    # -------------------------------------------------------------------------
    # 8. MASTER ENVIRONMENT PACK (`env_pack.glb`)
    # Combines all 7 environment models positioned at organized coordinate offsets
    # -------------------------------------------------------------------------
    obj_pine.location = (-15.0, 0.0, 0.0)
    obj_cypress.location = (-10.0, 0.0, 0.0)
    obj_decid.location = (-5.0, 0.0, 0.0)
    obj_rock.location = (0.0, 0.0, 0.0)
    obj_fans.location = (5.0, 0.0, 0.0)
    obj_house.location = (15.0, 0.0, 0.0)
    obj_peak.location = (0.0, 60.0, 0.0)  # In background

    p_pack = os.path.join(output_dir, "env_pack.glb")
    pack_objects = [obj_pine, obj_cypress, obj_decid, obj_rock, obj_fans, obj_house, obj_peak]
    exported_files["env_pack"] = export_environment_asset(pack_objects, p_pack)

    # Cleanup scene
    for obj in pack_objects:
        bpy.data.objects.remove(obj, do_unlink=True)

    print("=" * 75 + "\n")
    return exported_files


# =============================================================================
# CLI EXECUTION ENTRY POINT
# =============================================================================

if __name__ == "__main__":
    out_dir = "assets/3d/environment"
    for idx, arg in enumerate(sys.argv):
        if arg in ["--output-dir", "-o"] and idx + 1 < len(sys.argv):
            out_dir = sys.argv[idx + 1]

    files = export_all_environment_assets(output_dir=out_dir)
    sm.setup_zwift_studio_lighting()
    print(f"[SUCCESS] All environment assets generated: {files}")

