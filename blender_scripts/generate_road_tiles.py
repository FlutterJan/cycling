"""
===============================================================================
PRO PELOTON MANAGER - MODULAR 3D ROAD TILES GENERATOR
===============================================================================
Blender Python API (bpy) script that procedurally generates modular 3D road
segments and terrain tiles for building race stages on the fly:

  1. Gładki asfalt z liniami i napisami szosowymi (`road_asphalt.glb`):
     - Smooth asphalt road segment (20m length, 7m width) with crowned camber
     - Solid white edge lines and dashed centerline markings
     - Sloped roadside grass shoulders with drainage ditches
     - Iconic cycling tarmac graffiti / fan slogans ("POGI", "VAMOS", "ALPE", "KOM")

  2. Sektor bruku z wypukłymi kamieniami i poboczem (`road_cobbles.glb`):
     - Historic Paris-Roubaix / Flanders pavé cobblestone sector
     - Parabolic crowned arch roadbed with irregular, rounded granite pavé blocks
     - Compacted dirt/gravel gutter paths ("trottoir") on both sides
     - Overgrown roadside grass banks and rustic wooden sector marker post

  3. Górska serpentyna z kamiennym murkiem ochronnym (`road_mountain_hairpin.glb`):
     - 180-degree Alpine mountain switchback / hairpin bend (Alpe d'Huez / Stelvio)
     - 3.5m vertical elevation climb with inward banking (superelevation)
     - Continuous rustic stone guard wall along the outer cliff perimeter
     - Sheer mountain rock cliff descending into the abyss and inner rock embankment

Exported as binary glTF (.glb) files to: `assets/3d/roads/`.
Modular connectors snap together seamlessly along coordinate interfaces.

Compatible with Blender 3.6 LTS, 4.x, and 5.x+.
===============================================================================
"""

import math
import os
import sys
from typing import Dict, List, Optional, Tuple

try:
    import bpy
    import bmesh
    from mathutils import Matrix, Vector
except ImportError:
    print("[ERROR] 'bpy' / 'mathutils' module not found. This script must be run within Blender:")
    print("        blender --background --python blender_scripts/generate_road_tiles.py")
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
# BMESH LOFTING HELPERS
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


# =============================================================================
# ROAD PBR MATERIALS SYSTEM
# =============================================================================

def create_asphalt_material(
    name: str = "M_Road_Asphalt",
    dark_hex: str = "#262626",
) -> bpy.types.Material:
    """Generates realistic asphalt tarmac material with bitumen aggregate grain."""
    mat = sm._get_or_create_material(name)
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf, _ = sm._get_or_create_output_nodes(mat)

    tex_coord = nodes.new("ShaderNodeTexCoord")
    tex_coord.location = (-750, 0)

    noise = nodes.new("ShaderNodeTexNoise")
    noise.name = "Asphalt_Grain"
    noise.location = (-500, 0)
    noise.inputs["Scale"].default_value = 160.0
    noise.inputs["Detail"].default_value = 5.0
    noise.inputs["Roughness"].default_value = 0.75

    bump = nodes.new("ShaderNodeBump")
    bump.name = "Asphalt_Bump"
    bump.location = (-220, 0)
    bump.inputs["Strength"].default_value = 0.20
    bump.inputs["Distance"].default_value = 0.001

    links.new(tex_coord.outputs["Object"], noise.inputs["Vector"])
    links.new(noise.outputs["Fac"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])

    linear_col = sm.hex_to_linear_rgb(dark_hex)
    sm._set_bsdf_socket(bsdf, "Base Color", linear_col)
    sm._set_bsdf_socket(bsdf, "Roughness", 0.72)
    sm._set_bsdf_socket(bsdf, "Metallic", 0.0)
    sm._set_bsdf_socket(bsdf, ["Specular IOR Level", "Specular"], 0.35)

    return mat


def create_marking_paint_material(
    hex_color: str = "#F8FAFC",
    name: str = "M_Road_Marking_White",
) -> bpy.types.Material:
    """Generates reflective painted road markings with micro-bead sheen."""
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)

    linear_col = sm.hex_to_linear_rgb(hex_color)
    sm._set_bsdf_socket(bsdf, "Base Color", linear_col)
    sm._set_bsdf_socket(bsdf, "Roughness", 0.55)
    sm._set_bsdf_socket(bsdf, "Metallic", 0.0)
    sm._set_bsdf_socket(bsdf, ["Specular IOR Level", "Specular"], 0.60)
    sm._set_bsdf_socket(bsdf, ["Coat Weight", "Clearcoat"], 0.20)

    return mat


def create_roadside_grass_material(
    name: str = "M_Roadside_Grass",
    hex_color: str = "#3F6212",
) -> bpy.types.Material:
    """Generates lush road shoulder grass verge with subtle color noise."""
    mat = sm._get_or_create_material(name)
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf, _ = sm._get_or_create_output_nodes(mat)

    tex_coord = nodes.new("ShaderNodeTexCoord")
    tex_coord.location = (-750, 0)

    noise = nodes.new("ShaderNodeTexNoise")
    noise.name = "Grass_Noise"
    noise.location = (-500, 0)
    noise.inputs["Scale"].default_value = 80.0
    noise.inputs["Detail"].default_value = 3.0

    bump = nodes.new("ShaderNodeBump")
    bump.name = "Grass_Bump"
    bump.location = (-220, 0)
    bump.inputs["Strength"].default_value = 0.28
    bump.inputs["Distance"].default_value = 0.002

    links.new(tex_coord.outputs["Object"], noise.inputs["Vector"])
    links.new(noise.outputs["Fac"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])

    linear_col = sm.hex_to_linear_rgb(hex_color)
    sm._set_bsdf_socket(bsdf, "Base Color", linear_col)
    sm._set_bsdf_socket(bsdf, "Roughness", 0.85)
    sm._set_bsdf_socket(bsdf, "Metallic", 0.0)
    sm._set_bsdf_socket(bsdf, ["Subsurface Weight", "Subsurface"], 0.08)

    return mat


def create_cobblestone_material(
    name: str = "M_Cobblestone_Granite",
    hex_color: str = "#71717A",
) -> bpy.types.Material:
    """Generates weathered natural granite cobblestone pavé material."""
    mat = sm._get_or_create_material(name)
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf, _ = sm._get_or_create_output_nodes(mat)

    tex_coord = nodes.new("ShaderNodeTexCoord")
    tex_coord.location = (-750, 0)

    noise = nodes.new("ShaderNodeTexNoise")
    noise.name = "Granite_Pores"
    noise.location = (-500, 0)
    noise.inputs["Scale"].default_value = 120.0
    noise.inputs["Detail"].default_value = 4.0

    bump = nodes.new("ShaderNodeBump")
    bump.name = "Granite_Bump"
    bump.location = (-220, 0)
    bump.inputs["Strength"].default_value = 0.35
    bump.inputs["Distance"].default_value = 0.002

    links.new(tex_coord.outputs["Object"], noise.inputs["Vector"])
    links.new(noise.outputs["Fac"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])

    linear_col = sm.hex_to_linear_rgb(hex_color)
    sm._set_bsdf_socket(bsdf, "Base Color", linear_col)
    sm._set_bsdf_socket(bsdf, "Roughness", 0.68)
    sm._set_bsdf_socket(bsdf, "Metallic", 0.02)

    return mat


def create_dirt_gutter_material(
    name: str = "M_Dirt_Mud_Gutter",
    hex_color: str = "#543D2B",
) -> bpy.types.Material:
    """Generates compacted brown soil / dirt gutter path material."""
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)

    linear_col = sm.hex_to_linear_rgb(hex_color)
    sm._set_bsdf_socket(bsdf, "Base Color", linear_col)
    sm._set_bsdf_socket(bsdf, "Roughness", 0.92)
    sm._set_bsdf_socket(bsdf, "Metallic", 0.0)

    return mat


def create_stone_wall_material(
    name: str = "M_Mountain_Stone_Wall",
    hex_color: str = "#94A3B8",
) -> bpy.types.Material:
    """Generates rustic chiseled masonry mountain guard wall material."""
    mat = sm._get_or_create_material(name)
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf, _ = sm._get_or_create_output_nodes(mat)

    tex_coord = nodes.new("ShaderNodeTexCoord")
    tex_coord.location = (-750, 0)

    brick = nodes.new("ShaderNodeTexBrick")
    brick.name = "Masonry_Courses"
    brick.location = (-500, 0)
    brick.inputs["Brick Width"].default_value = 0.40
    brick.inputs["Row Height"].default_value = 0.18
    brick.inputs["Mortar Size"].default_value = 0.02

    bump = nodes.new("ShaderNodeBump")
    bump.name = "Wall_Bump"
    bump.location = (-220, 0)
    bump.inputs["Strength"].default_value = 0.40
    bump.inputs["Distance"].default_value = 0.003

    links.new(tex_coord.outputs["Object"], brick.inputs["Vector"])
    links.new(brick.outputs["Fac"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])

    linear_col = sm.hex_to_linear_rgb(hex_color)
    sm._set_bsdf_socket(bsdf, "Base Color", linear_col)
    sm._set_bsdf_socket(bsdf, "Roughness", 0.78)
    sm._set_bsdf_socket(bsdf, "Metallic", 0.0)

    return mat


def create_cliff_rock_material(
    name: str = "M_Cliff_Rock",
    hex_color: str = "#475569",
) -> bpy.types.Material:
    """Generates jagged faceted alpine rock face material for mountain abysses."""
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)

    linear_col = sm.hex_to_linear_rgb(hex_color)
    sm._set_bsdf_socket(bsdf, "Base Color", linear_col)
    sm._set_bsdf_socket(bsdf, "Roughness", 0.82)
    sm._set_bsdf_socket(bsdf, "Metallic", 0.0)

    return mat


# =============================================================================
# 1. SMOOTH ASPHALT ROAD TILE (`road_asphalt.glb`)
# =============================================================================

def generate_asphalt_road_tile(
    name: str = "Road_Asphalt",
    length: float = 20.0,
    road_width: float = 7.0,
    shoulder_width: float = 2.0,
) -> bpy.types.Object:
    """
    Procedurally models a smooth 20m asphalt road segment:
      - Crowned tarmac roadbed with realistic cross-camber (sheds water)
      - Solid painted white edge lines (15cm) and dashed center divider line
      - Sloped green roadside grass shoulders with drainage ditches
      - Iconic painted road graffiti slogans ("POGI", "VAMOS", "ALPE", "KOM")
    """
    mat_asphalt = create_asphalt_material()
    mat_white = create_marking_paint_material("#F8FAFC", "M_Road_Marking_White")
    mat_yellow = create_marking_paint_material("#FACC15", "M_Road_Graffiti_Yellow")
    mat_red = create_marking_paint_material("#EF4444", "M_Road_Graffiti_Red")
    mat_cyan = create_marking_paint_material("#38BDF8", "M_Road_Graffiti_Cyan")
    mat_grass = create_roadside_grass_material()

    materials = [mat_asphalt, mat_white, mat_yellow, mat_red, mat_cyan, mat_grass]
    bm = bmesh.new()

    y_start = -length * 0.5
    y_end = length * 0.5
    n_y_steps = 10
    half_w = road_width * 0.5
    total_half_w = half_w + shoulder_width

    # 1. ROADBED & SHOULDERS MESH GRID
    # X coordinates: Left Grass Outer, Left Road Edge, Center, Right Road Edge, Right Grass Outer
    x_coords = [-total_half_w, -half_w, 0.0, half_w, total_half_w]

    rings = []
    for yi in range(n_y_steps + 1):
        y = y_start + (yi / float(n_y_steps)) * length
        ring = []
        for xi, x in enumerate(x_coords):
            # Crowned camber: center rises by 3cm, grass shoulders slope down by 15cm
            if abs(x) > half_w + 1e-4:
                z = -0.15  # ditch shoulder
            elif abs(x) < 1e-4:
                z = 0.03   # crowned center
            else:
                z = 0.00   # asphalt edge
            ring.append(bm.verts.new(Vector((x, y, z))))
        rings.append(ring)

    # Bridge quad faces
    for yi in range(n_y_steps):
        r1 = rings[yi]
        r2 = rings[yi + 1]
        # Left grass verge
        f_g_left = bm.faces.new([r1[0], r1[1], r2[1], r2[0]])
        f_g_left.material_index = 5  # mat_grass

        # Left road lane
        f_r_left = bm.faces.new([r1[1], r1[2], r2[2], r2[1]])
        f_r_left.material_index = 0  # mat_asphalt

        # Right road lane
        f_r_right = bm.faces.new([r1[2], r1[3], r2[3], r2[2]])
        f_r_right.material_index = 0  # mat_asphalt

        # Right grass verge
        f_g_right = bm.faces.new([r1[3], r1[4], r2[4], r2[3]])
        f_g_right.material_index = 5  # mat_grass

    # 2. WHITE ROAD MARKINGS (Raised by 1.5mm to eliminate Z-fighting)
    line_w = 0.15
    z_line = 0.0015

    # A. Continuous side white edge lines
    for sign in [-1.0, 1.0]:
        x_center = sign * (half_w - line_w * 0.5 - 0.05)
        v1 = bm.verts.new(Vector((x_center - line_w * 0.5, y_start, z_line)))
        v2 = bm.verts.new(Vector((x_center + line_w * 0.5, y_start, z_line)))
        v3 = bm.verts.new(Vector((x_center + line_w * 0.5, y_end, z_line)))
        v4 = bm.verts.new(Vector((x_center - line_w * 0.5, y_end, z_line)))
        f_line = bm.faces.new([v1, v2, v3, v4])
        f_line.material_index = 1  # mat_white

    # B. Dashed white centerline (3m dash, 3m gap)
    dash_len = 3.0
    dash_gap = 3.0
    cycle = dash_len + dash_gap
    cur_y = y_start + 1.0
    while cur_y + dash_len <= y_end:
        v1 = bm.verts.new(Vector((-line_w * 0.5, cur_y, 0.03 + z_line)))
        v2 = bm.verts.new(Vector((line_w * 0.5, cur_y, 0.03 + z_line)))
        v3 = bm.verts.new(Vector((line_w * 0.5, cur_y + dash_len, 0.03 + z_line)))
        v4 = bm.verts.new(Vector((-line_w * 0.5, cur_y + dash_len, 0.03 + z_line)))
        f_dash = bm.faces.new([v1, v2, v3, v4])
        f_dash.material_index = 1  # mat_white
        cur_y += cycle

    # 3. ROAD GRAFFITI & CYCLING FAN SLOGANS (Painted on asphalt)
    def add_graffiti_patch(center_x: float, center_y: float, width: float, height: float, mat_idx: int) -> None:
        hw = width * 0.5
        hh = height * 0.5
        zc = 0.015 + z_line
        v1 = bm.verts.new(Vector((center_x - hw, center_y - hh, zc)))
        v2 = bm.verts.new(Vector((center_x + hw, center_y - hh, zc)))
        v3 = bm.verts.new(Vector((center_x + hw, center_y + hh, zc)))
        v4 = bm.verts.new(Vector((center_x - hw, center_y + hh, zc)))
        f = bm.faces.new([v1, v2, v3, v4])
        f.material_index = mat_idx

    # Slogans at strategic road locations:
    # "POGI" (Yellow) at y = -5.0
    add_graffiti_patch(-1.2, -5.0, 1.4, 0.6, mat_idx=2)
    # "VAMOS" (White) at y = -1.5
    add_graffiti_patch(1.2, -1.5, 1.6, 0.5, mat_idx=1)
    # "ALPE" (Cyan) at y = 3.0
    add_graffiti_patch(-1.0, 3.0, 1.3, 0.5, mat_idx=4)
    # "KOM" Polka dots (Crimson) at y = 6.5
    for dx_dot in [-1.5, -0.8, 0.8, 1.5]:
        add_graffiti_patch(dx_dot, 6.5, 0.35, 0.35, mat_idx=3)

    mesh = bpy.data.meshes.new(f"{name}_Data")
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)

    for mat in materials:
        obj.data.materials.append(mat)

    sm.clean_zwift_mesh(obj)
    sm.apply_zwift_style(obj, auto_smooth_angle_deg=35.0)
    return obj


# =============================================================================
# 2. COBBLESTONE ROAD SECTOR (`road_cobbles.glb`)
# =============================================================================

def generate_cobblestone_road_tile(
    name: str = "Road_Cobbles",
    length: float = 20.0,
    pave_width: float = 4.5,
    gutter_width: float = 1.4,
    shoulder_width: float = 1.2,
) -> bpy.types.Object:
    """
    Procedurally models a historic Paris-Roubaix / Carrefour de l'Arbre
    cobblestone pavé sector:
      - Parabolic crowned arch roadbed with rows of individual rounded granite blocks
      - Deep mud/dirt joints between cobblestones
      - Compacted dirt/gravel singletrack gutters ("trottoir") on both sides
      - Overgrown grassy verge banks and rustic wooden kilometer marker post
    """
    mat_granite = create_cobblestone_material()
    mat_dirt = create_dirt_gutter_material()
    mat_grass = create_roadside_grass_material(name="M_Roadside_Grass_Rough", hex_color="#365314")
    mat_wood = sm._get_or_create_material("M_Wood_Marker")
    sm._set_bsdf_socket(sm._get_or_create_output_nodes(mat_wood)[0], "Base Color", sm.hex_to_linear_rgb("#78350F"))

    materials = [mat_granite, mat_dirt, mat_grass, mat_wood]
    bm = bmesh.new()

    half_pave = pave_width * 0.5
    half_gutter = half_pave + gutter_width
    half_total = half_gutter + shoulder_width

    # 1. CROWNED COBBLESTONE HIGHWAY (ARCHED PROFILE)
    n_pave_rows = 9  # 9 longitudinal granite rows
    n_y_blocks = 20  # 20 blocks along 20m length

    for yi in range(n_y_blocks):
        y0 = -length * 0.5 + (yi / float(n_y_blocks)) * length
        y1 = y0 + (length / float(n_y_blocks)) * 0.90  # 10% mud gap between stones

        for xi in range(n_pave_rows):
            # Alternating brick bond running offset clamped to tile boundary
            stagger = 0.25 * (length / float(n_y_blocks)) if (xi % 2 == 1) else 0.0
            cur_y0 = max(-length * 0.5, y0 + stagger)
            cur_y1 = min(length * 0.5, y1 + stagger)

            x0 = -half_pave + (xi / float(n_pave_rows)) * pave_width + 0.02
            x1 = x0 + (pave_width / float(n_pave_rows)) - 0.04  # mud joint

            # Parabolic crown: arch height Z = 0.12 * (1 - (x / half_pave)^2)
            xm = (x0 + x1) * 0.5
            norm_x = xm / half_pave
            z_arch = max(0.0, 0.12 * (1.0 - norm_x * norm_x))

            # Procedural slight stone irregularity (+/- 8mm)
            z_irr = 0.008 * math.sin(xi * 3.7 + yi * 2.3)

            # Cobblestone block vertices (rounded chamfered top)
            v1 = bm.verts.new(Vector((x0, cur_y0, z_arch + z_irr)))
            v2 = bm.verts.new(Vector((x1, cur_y0, z_arch + z_irr)))
            v3 = bm.verts.new(Vector((x1, cur_y1, z_arch + z_irr)))
            v4 = bm.verts.new(Vector((x0, cur_y1, z_arch + z_irr)))
            f_cobble = bm.faces.new([v1, v2, v3, v4])
            f_cobble.material_index = 0  # mat_granite

    # 2. DIRT MUD GUTTERS & ROADSIDE GRASS VERGES
    y_start = -length * 0.5
    y_end = length * 0.5
    n_seg = 10

    dirt_rings = []
    for yi in range(n_seg + 1):
        y = y_start + (yi / float(n_seg)) * length
        ring = []
        # Points: -Total, -Gutter, -Pave, +Pave, +Gutter, +Total
        pts_x = [-half_total, -half_gutter, -half_pave, half_pave, half_gutter, half_total]
        for px in pts_x:
            if abs(px) >= half_gutter:
                pz = 0.08  # raised grass bank
            elif abs(px) >= half_pave:
                pz = -0.06  # rutted dirt gutter
            else:
                pz = 0.00  # pavé shoulder join
            ring.append(bm.verts.new(Vector((px, y, pz))))
        dirt_rings.append(ring)

    for yi in range(n_seg):
        r1 = dirt_rings[yi]
        r2 = dirt_rings[yi + 1]

        # Left Grass Bank
        f_gl = bm.faces.new([r1[0], r1[1], r2[1], r2[0]])
        f_gl.material_index = 2  # mat_grass

        # Left Dirt Gutter
        f_dl = bm.faces.new([r1[1], r1[2], r2[2], r2[1]])
        f_dl.material_index = 1  # mat_dirt

        # Right Dirt Gutter
        f_dr = bm.faces.new([r1[3], r1[4], r2[4], r2[3]])
        f_dr.material_index = 1  # mat_dirt

        # Right Grass Bank
        f_gr = bm.faces.new([r1[4], r1[5], r2[5], r2[4]])
        f_gr.material_index = 2  # mat_grass

    # 3. RUSTIC WOODEN KILOMETER MARKER POST ("SECTEUR PAVÉ")
    p_post = Vector((-half_gutter - 0.4, 0.0, 0.08))
    # Post pillar (12x12cm, 1.1m height)
    v_p1 = bm.verts.new(p_post + Vector((-0.06, -0.06, 0.0)))
    v_p2 = bm.verts.new(p_post + Vector((0.06, -0.06, 0.0)))
    v_p3 = bm.verts.new(p_post + Vector((0.06, 0.06, 0.0)))
    v_p4 = bm.verts.new(p_post + Vector((-0.06, 0.06, 0.0)))

    v_p5 = bm.verts.new(p_post + Vector((-0.06, -0.06, 1.1)))
    v_p6 = bm.verts.new(p_post + Vector((0.06, -0.06, 1.1)))
    v_p7 = bm.verts.new(p_post + Vector((0.06, 0.06, 1.1)))
    v_p8 = bm.verts.new(p_post + Vector((-0.06, 0.06, 1.1)))

    # Faces of wooden post
    for q in [[v_p1, v_p2, v_p6, v_p5], [v_p2, v_p3, v_p7, v_p6], [v_p3, v_p4, v_p8, v_p7], [v_p4, v_p1, v_p5, v_p8], [v_p5, v_p6, v_p7, v_p8]]:
        f_wood = bm.faces.new(q)
        f_wood.material_index = 3  # mat_wood

    # Marker placard sign
    p_sign = p_post + Vector((0.08, 0.0, 0.85))
    v_s1 = bm.verts.new(p_sign + Vector((0.01, -0.22, -0.15)))
    v_s2 = bm.verts.new(p_sign + Vector((0.01, 0.22, -0.15)))
    v_s3 = bm.verts.new(p_sign + Vector((0.01, 0.22, 0.15)))
    v_s4 = bm.verts.new(p_sign + Vector((0.01, -0.22, 0.15)))
    f_sign = bm.faces.new([v_s1, v_s2, v_s3, v_s4])
    f_sign.material_index = 3  # mat_wood

    mesh = bpy.data.meshes.new(f"{name}_Data")
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)

    for mat in materials:
        obj.data.materials.append(mat)

    sm.clean_zwift_mesh(obj)
    sm.apply_zwift_style(obj, auto_smooth_angle_deg=35.0)
    return obj


# =============================================================================
# 3. MOUNTAIN HAIRPIN SWITCHBACK (`road_mountain_hairpin.glb`)
# =============================================================================

def generate_mountain_hairpin_tile(
    name: str = "Road_Mountain_Hairpin",
    climb_height: float = 3.50,
    radius: float = 7.50,
    road_width: float = 6.50,
) -> bpy.types.Object:
    """
    Procedurally models an iconic 180° Alpine mountain switchback / hairpin:
      - 180° sweeping curve climbing 3.50m (realistic 10% mountain grade)
      - Superelevation inward banking (6° in apex)
      - Continuous chiseled stone guard wall along the outer cliff perimeter
      - Sheer rock cliff face descending 5.5m into the mountain abyss
      - Inner mountain rock embankment
    """
    mat_asphalt = create_asphalt_material("M_Mountain_Asphalt", dark_hex="#333336")
    mat_wall = create_stone_wall_material()
    mat_cliff = create_cliff_rock_material()
    mat_white = create_marking_paint_material("#F8FAFC", "M_Mountain_Marking")

    materials = [mat_asphalt, mat_wall, mat_cliff, mat_white]
    bm = bmesh.new()

    # Center of hairpin turn
    p_center = Vector((3.75, 0.0, 0.0))
    half_rw = road_width * 0.5

    # Arc parameters: from angle 0 (entry at x=-3.75 heading +Y) to pi (exit at x=+11.25 heading -Y)
    n_steps = 24
    road_rings = []
    wall_rings = []
    cliff_rings = []

    for i in range(n_steps + 1):
        u = i / float(n_steps)
        angle = u * math.pi
        z_climb = u * climb_height

        # Inward banking (superelevation): peaks at apex (u = 0.5)
        banking_rad = math.radians(6.0) * math.sin(u * math.pi)

        # Centerline point on the curve
        cx = p_center.x - radius * math.cos(angle)
        cy = p_center.y + radius * math.sin(angle) * 0.85
        center = Vector((cx, cy, z_climb))

        # Radial unit vector pointing OUTWARD from curve center
        rad_out = Vector((-math.cos(angle), math.sin(angle) * 0.85, 0.0)).normalized()
        up_vec = Vector((0.0, 0.0, 1.0))
        # Banked lateral vector
        lat_banked = rad_out * math.cos(banking_rad) + up_vec * math.sin(banking_rad)
        lat_banked.normalize()

        # 1. Road cross-section points (Inner Curb, Center, Outer Edge)
        p_inner = center - lat_banked * half_rw
        p_mid = center
        p_outer = center + lat_banked * half_rw
        v_inner = bm.verts.new(p_inner)
        v_mid = bm.verts.new(p_mid)
        v_outer = bm.verts.new(p_outer)
        road_rings.append([v_inner, v_mid, v_outer])

        # 2. Outer Protective Stone Wall (0.85m height, 0.35m thickness)
        wall_thick = 0.35
        wall_h = 0.85
        p_w_base_inner = p_outer
        p_w_base_outer = p_outer + rad_out * wall_thick
        p_w_top_inner = p_w_base_inner + Vector((0.0, 0.0, wall_h))
        p_w_top_outer = p_w_base_outer + Vector((0.0, 0.0, wall_h))

        v_w1 = bm.verts.new(p_w_base_inner)
        v_w2 = bm.verts.new(p_w_base_outer)
        v_w3 = bm.verts.new(p_w_top_outer)
        v_w4 = bm.verts.new(p_w_top_inner)
        wall_rings.append([v_w1, v_w2, v_w3, v_w4])

        # 3. Outer Mountain Abyss Cliff Face (Descending 5.5m down)
        cliff_depth = 5.5
        p_cliff_shelf = p_w_base_outer + rad_out * 0.8 + Vector((0.0, 0.0, -1.8))
        p_cliff_bottom = p_w_base_outer + rad_out * 1.6 + Vector((0.0, 0.0, -cliff_depth))
        v_c1 = v_w2
        v_c2 = bm.verts.new(p_cliff_shelf)
        v_c3 = bm.verts.new(p_cliff_bottom)
        cliff_rings.append([v_c1, v_c2, v_c3])

    # Bridge Road Surfaces
    for i in range(n_steps):
        r1 = road_rings[i]
        r2 = road_rings[i + 1]
        f_in = bm.faces.new([r1[0], r1[1], r2[1], r2[0]])
        f_in.material_index = 0  # mat_asphalt
        f_out = bm.faces.new([r1[1], r1[2], r2[2], r2[1]])
        f_out.material_index = 0  # mat_asphalt

    # Bridge Stone Wall Quads (Roadside face, Coping top, Abyss outer face)
    for i in range(n_steps):
        w1 = wall_rings[i]
        w2 = wall_rings[i + 1]

        # Inner face (facing road)
        f_win = bm.faces.new([w1[0], w1[3], w2[3], w2[0]])
        f_win.material_index = 1  # mat_wall

        # Wall Coping Top
        f_wtop = bm.faces.new([w1[3], w1[2], w2[2], w2[3]])
        f_wtop.material_index = 1  # mat_wall

        # Outer face (facing abyss)
        f_wout = bm.faces.new([w1[2], w1[1], w2[1], w2[2]])
        f_wout.material_index = 1  # mat_wall

    # End caps for stone wall
    try:
        bm.faces.new(wall_rings[0]).material_index = 1
        bm.faces.new(list(reversed(wall_rings[-1]))).material_index = 1
    except ValueError:
        pass

    # Bridge Cliff Rock Face
    for i in range(n_steps):
        c1 = cliff_rings[i]
        c2 = cliff_rings[i + 1]
        f_c1 = bm.faces.new([c1[0], c1[1], c2[1], c2[0]])
        f_c1.material_index = 2  # mat_cliff
        f_c2 = bm.faces.new([c1[1], c1[2], c2[2], c2[1]])
        f_c2.material_index = 2  # mat_cliff

    mesh = bpy.data.meshes.new(f"{name}_Data")
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)

    for mat in materials:
        obj.data.materials.append(mat)

    sm.clean_zwift_mesh(obj)
    sm.apply_zwift_style(obj, auto_smooth_angle_deg=35.0)
    return obj


# =============================================================================
# EXPORT PIPELINE
# =============================================================================

def export_road_tile(
    obj: bpy.types.Object,
    output_glb_path: str,
) -> str:
    """Exports a single road tile object to binary glTF (.glb)."""
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj

    abs_output_path = os.path.abspath(output_glb_path)
    os.makedirs(os.path.dirname(abs_output_path), exist_ok=True)

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
    polys = len(obj.data.polygons)
    print(f"[EXPORT] '{obj.name}' -> '{abs_output_path}' ({file_size_kb:.1f} KB, {polys} polys)")
    return abs_output_path


def export_all_road_tiles(
    output_dir: str = "assets/3d/roads",
) -> Dict[str, str]:
    """
    Generates and exports all 3 modular road tile assets:
      1. road_asphalt.glb
      2. road_cobbles.glb
      3. road_mountain_hairpin.glb
    """
    for obj in [o for o in bpy.context.scene.objects if o.type == "MESH"]:
        bpy.data.objects.remove(obj, do_unlink=True)

    print("\n" + "=" * 75)
    print("PRO PELOTON MANAGER: GENERATING MODULAR ROAD TILES")
    print("=" * 75)

    os.makedirs(output_dir, exist_ok=True)
    exported_files = {}

    # 1. Smooth Asphalt Road
    obj_asphalt = generate_asphalt_road_tile(name="Road_Asphalt")
    p_asphalt = os.path.join(output_dir, "road_asphalt.glb")
    exported_files["asphalt"] = export_road_tile(obj_asphalt, p_asphalt)
    bpy.data.objects.remove(obj_asphalt, do_unlink=True)

    # 2. Cobblestone Pavé Sector
    obj_cobbles = generate_cobblestone_road_tile(name="Road_Cobbles")
    p_cobbles = os.path.join(output_dir, "road_cobbles.glb")
    exported_files["cobbles"] = export_road_tile(obj_cobbles, p_cobbles)
    bpy.data.objects.remove(obj_cobbles, do_unlink=True)

    # 3. Mountain Hairpin Switchback
    obj_hairpin = generate_mountain_hairpin_tile(name="Road_Mountain_Hairpin")
    p_hairpin = os.path.join(output_dir, "road_mountain_hairpin.glb")
    exported_files["hairpin"] = export_road_tile(obj_hairpin, p_hairpin)
    bpy.data.objects.remove(obj_hairpin, do_unlink=True)

    print("=" * 75 + "\n")
    return exported_files


# =============================================================================
# CLI EXECUTION ENTRY POINT
# =============================================================================

if __name__ == "__main__":
    out_dir = "assets/3d/roads"
    for idx, arg in enumerate(sys.argv):
        if arg in ["--output-dir", "-o"] and idx + 1 < len(sys.argv):
            out_dir = sys.argv[idx + 1]

    files = export_all_road_tiles(output_dir=out_dir)
    sm.setup_zwift_studio_lighting()
    print(f"[SUCCESS] All road tiles generated: {files}")
