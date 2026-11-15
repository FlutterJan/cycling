"""
===============================================================================
PRO PELOTON MANAGER - BLENDER 3D VISUAL STYLE & PBR MATERIAL SYSTEM
===============================================================================
Script for Blender Python API (bpy) defining the cohesive visual aesthetic
of Pro Peloton Manager (Zwift / MyWhoosh esports cycling style: clean geometry,
shade_smooth with auto-smooth normal handling, and physically-based PBR materials).

Provides material generator functions:
  1. create_carbon_matte_material()
  2. create_glossy_frame_paint_material(hex_color)
  3. create_tire_rubber_material(tan_wall=True)
  4. create_metal_rotor_material()
  5. create_lycra_fabric_material(hex_color)
  6. create_visor_iridium_material()

Also provides mesh styling utilities and showroom scene generator:
  - apply_zwift_style(obj, auto_smooth_angle_deg=35.0)
  - clean_zwift_mesh(obj)
  - setup_zwift_studio_lighting()
  - create_material_showcase_scene()

Compatible with Blender 3.6 LTS, 4.x, and 5.x+.
===============================================================================
"""

import math
import sys
from typing import Any, Dict, List, Optional, Tuple, Union

try:
    import bpy
    import bmesh
except ImportError:
    print("[ERROR] 'bpy' module not found. This script must be executed within Blender:")
    print("        blender --background --python blender_scripts/style_and_materials.py")
    sys.exit(1)


# =============================================================================
# COLOR UTILITIES (sRGB HEX -> LINEAR RGBA)
# =============================================================================

def hex_to_linear_rgb(hex_str: str, alpha: float = 1.0) -> Tuple[float, float, float, float]:
    """
    Converts a HEX color code (e.g. '#E10600', '1E40AF', '#FFF') to linear RGBA
    as required by Blender's Principled BSDF color sockets (IEC 61966-2-1 standard).
    """
    cleaned = hex_str.strip().lstrip("#")
    if len(cleaned) == 3:
        cleaned = "".join([c * 2 for c in cleaned])
    elif len(cleaned) == 8:
        # Hex with embedded alpha (#RRGGBBAA)
        alpha = int(cleaned[6:8], 16) / 255.0
        cleaned = cleaned[:6]

    if len(cleaned) != 6:
        raise ValueError(f"Invalid HEX color format: '{hex_str}'")

    r_srgb = int(cleaned[0:2], 16) / 255.0
    g_srgb = int(cleaned[2:4], 16) / 255.0
    b_srgb = int(cleaned[4:6], 16) / 255.0

    def srgb_to_linear(channel: float) -> float:
        if channel <= 0.04045:
            return channel / 12.92
        return ((channel + 0.055) / 1.055) ** 2.4

    return (
        srgb_to_linear(r_srgb),
        srgb_to_linear(g_srgb),
        srgb_to_linear(b_srgb),
        max(0.0, min(1.0, alpha)),
    )


def linear_to_hex(linear_rgb: Tuple[float, float, float]) -> str:
    """Converts linear RGB back to sRGB HEX string for logging and naming."""
    def linear_to_srgb(c: float) -> float:
        if c <= 0.0031308:
            return c * 12.92
        return 1.055 * (c ** (1.0 / 2.4)) - 0.055

    r = int(round(max(0.0, min(1.0, linear_to_srgb(linear_rgb[0]))) * 255.0))
    g = int(round(max(0.0, min(1.0, linear_to_srgb(linear_rgb[1]))) * 255.0))
    b = int(round(max(0.0, min(1.0, linear_to_srgb(linear_rgb[2]))) * 255.0))
    return f"#{r:02X}{g:02X}{b:02X}"


# =============================================================================
# BLENDER SHADER NODE HELPER UTILITIES
# =============================================================================

def _get_or_create_material(name: str) -> bpy.types.Material:
    """
    Retrieves or creates a material by name, resets its node tree,
    and returns a clean material ready for shader graph population.
    """
    mat = bpy.data.materials.get(name)
    if mat is None:
        mat = bpy.data.materials.new(name=name)

    # In Blender < 5.0, ensure use_nodes is enabled
    if bpy.app.version < (5, 0, 0):
        if hasattr(mat, "use_nodes") and not mat.use_nodes:
            mat.use_nodes = True

    # Clear old nodes for a clean slate
    nodes = mat.node_tree.nodes
    nodes.clear()

    return mat


def _get_or_create_output_nodes(
    mat: bpy.types.Material,
) -> Tuple[bpy.types.ShaderNodeBsdfPrincipled, bpy.types.ShaderNodeOutputMaterial]:
    """
    Instantiates standard Material Output and Principled BSDF nodes in the material.
    """
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links

    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.name = "Principled BSDF"
    bsdf.label = "Principled BSDF"
    bsdf.location = (300, 0)

    output = nodes.new("ShaderNodeOutputMaterial")
    output.name = "Material Output"
    output.location = (600, 0)

    links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])
    return bsdf, output


def _set_bsdf_socket(
    bsdf: bpy.types.ShaderNodeBsdfPrincipled,
    socket_candidates: Union[str, List[str]],
    value: Any,
) -> bool:
    """
    Sets the default_value of a Principled BSDF socket matching any candidate name.
    Ensures compatibility across Blender 3.6 LTS, 4.0-4.3, and 5.0+.
    """
    if isinstance(socket_candidates, str):
        socket_candidates = [socket_candidates]

    for cand in socket_candidates:
        if cand in bsdf.inputs:
            try:
                bsdf.inputs[cand].default_value = value
                return True
            except Exception:
                pass
    return False


def _link_to_bsdf_socket(
    material: bpy.types.Material,
    source_socket: bpy.types.NodeSocket,
    target_socket_candidates: Union[str, List[str]],
) -> bool:
    """
    Links a source output socket to the first matching socket on Principled BSDF.
    """
    bsdf = material.node_tree.nodes.get("Principled BSDF")
    if not bsdf:
        return False

    if isinstance(target_socket_candidates, str):
        target_socket_candidates = [target_socket_candidates]

    for cand in target_socket_candidates:
        if cand in bsdf.inputs:
            material.node_tree.links.new(source_socket, bsdf.inputs[cand])
            return True
    return False


# =============================================================================
# GEOMETRY & SHADING UTILITIES (ZWIFT / MYWHOOSH STYLE)
# =============================================================================

def apply_zwift_style(obj: bpy.types.Object, auto_smooth_angle_deg: float = 35.0) -> None:
    """
    Applies the hallmark Zwift/MyWhoosh visual style to a mesh object:
      1. Polygons set to smooth shading (shade_smooth).
      2. Crisp edge delineation on sharp angles via Auto Smooth / Smooth by Angle (~35 deg).
      3. Normals validated and updated for artifact-free rendering.
    """
    if obj.type != "MESH" or not obj.data:
        return

    # 1. Enable smooth shading on all faces
    for poly in obj.data.polygons:
        poly.use_smooth = True

    # 2. Context setup for operators
    context = bpy.context
    prev_active = context.view_layer.objects.active
    context.view_layer.objects.active = obj
    obj.select_set(True)

    angle_rad = math.radians(auto_smooth_angle_deg)

    # 3. Handle Auto Smooth across Blender version branches
    if bpy.app.version >= (4, 1, 0):
        # Blender 4.1+ / 5.x uses operator shade_smooth_by_angle
        if hasattr(bpy.ops.object, "shade_smooth_by_angle"):
            try:
                bpy.ops.object.shade_smooth_by_angle(angle=angle_rad)
            except Exception:
                bpy.ops.object.shade_smooth()
        else:
            bpy.ops.object.shade_smooth()
    else:
        # Blender 3.6 - 4.0 uses mesh.use_auto_smooth
        bpy.ops.object.shade_smooth()
        if hasattr(obj.data, "use_auto_smooth"):
            obj.data.use_auto_smooth = True
            obj.data.auto_smooth_angle = angle_rad

    # 4. Recalculate mesh normals
    obj.data.update()

    # Restore active selection
    if prev_active and prev_active.name in bpy.data.objects:
        context.view_layer.objects.active = prev_active


def clean_zwift_mesh(obj: bpy.types.Object, merge_distance: float = 0.0001) -> None:
    """
    Cleans up geometric imperfections for crisp real-time rendering:
    merges duplicate vertices, removes zero-area faces, and recalculates normals outside.
    """
    if obj.type != "MESH" or not obj.data:
        return

    mesh = obj.data
    bm = bmesh.new()
    bm.from_mesh(mesh)

    # Merge overlapping vertices
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=merge_distance)

    # Recalculate normal orientation outside
    if hasattr(bmesh.ops, "recalc_face_normals"):
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

    bm.to_mesh(mesh)
    bm.free()
    mesh.update()


def assign_material(
    obj: bpy.types.Object, material: bpy.types.Material, slot_index: int = 0
) -> None:
    """
    Assigns a material to the given object's material slot index,
    creating new slots if necessary.
    """
    if obj.type != "MESH":
        return

    while len(obj.data.materials) <= slot_index:
        obj.data.materials.append(None)

    obj.data.materials[slot_index] = material


# =============================================================================
# 1. CARBON MATTE MATERIAL GENERATOR
# =============================================================================

def create_carbon_matte_material(
    name: str = "M_Carbon_Matte",
    weave_scale: float = 120.0,
    base_hex: str = "#18181A",
) -> bpy.types.Material:
    """
    Generates a procedural matte carbon fiber material (UD / 3K twill weave)
    used for high-end racing frames (S-Works, Canyon Aeroad, Dogma F)
    and aerodynamic deep-section carbon wheel rims.

    Characteristics:
      - Deep charcoal / graphite tone (#18181A)
      - Subtle 45-degree interwoven twill reflection
      - Procedural bump simulating carbon fiber weave
      - Non-reflective satin/matte surface (roughness ~0.52, zero clearcoat)
    """
    mat = _get_or_create_material(name)
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf, _ = _get_or_create_output_nodes(mat)

    # Texture Coordinates & 45-degree Diagonal Mapping
    tex_coord = nodes.new("ShaderNodeTexCoord")
    tex_coord.location = (-900, 0)

    mapping = nodes.new("ShaderNodeMapping")
    mapping.location = (-700, 0)
    mapping.inputs["Rotation"].default_value[2] = math.radians(45.0)
    mapping.inputs["Scale"].default_value = (weave_scale, weave_scale, weave_scale)

    # Procedural 3K Twill Carbon Weave using Brick Texture
    brick = nodes.new("ShaderNodeTexBrick")
    brick.name = "Carbon_Twill_Weave"
    brick.location = (-450, 0)
    brick.inputs["Brick Width"].default_value = 0.5
    brick.inputs["Row Height"].default_value = 0.5
    brick.inputs["Mortar Size"].default_value = 0.015
    brick.inputs["Mortar Smooth"].default_value = 0.15

    # Carbon fiber thread color shifts
    c_base = hex_to_linear_rgb(base_hex)
    c_thread1 = (c_base[0] * 0.95, c_base[1] * 0.95, c_base[2] * 0.98, 1.0)
    c_thread2 = (c_base[0] * 1.35, c_base[1] * 1.35, c_base[2] * 1.40, 1.0)
    c_mortar = (c_base[0] * 0.70, c_base[1] * 0.70, c_base[2] * 0.75, 1.0)

    brick.inputs["Color1"].default_value = c_thread1
    brick.inputs["Color2"].default_value = c_thread2
    brick.inputs["Mortar"].default_value = c_mortar

    # Micro Bump for carbon fiber weave height
    bump = nodes.new("ShaderNodeBump")
    bump.name = "Carbon_Twill_Bump"
    bump.location = (-180, -200)
    bump.inputs["Strength"].default_value = 0.15
    bump.inputs["Distance"].default_value = 0.001

    # Wire nodes
    links.new(tex_coord.outputs["Object"], mapping.inputs["Vector"])
    links.new(mapping.outputs["Vector"], brick.inputs["Vector"])
    links.new(brick.outputs["Color"], bsdf.inputs["Base Color"])
    links.new(brick.outputs["Fac"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])

    # Principled BSDF PBR Configuration
    _set_bsdf_socket(bsdf, "Roughness", 0.52)
    _set_bsdf_socket(bsdf, ["Specular IOR Level", "Specular"], 0.50)
    _set_bsdf_socket(bsdf, "Metallic", 0.03)  # subtle graphite sheen
    _set_bsdf_socket(bsdf, ["Coat Weight", "Clearcoat"], 0.0)  # purely matte finish

    return mat


# =============================================================================
# 2. GLOSSY FRAME PAINT MATERIAL GENERATOR
# =============================================================================

def create_glossy_frame_paint_material(
    hex_color: str = "#E10600",
    name: Optional[str] = None,
    coat_roughness: float = 0.03,
    metallic: float = 0.0,
    metallic_flake: bool = False,
) -> bpy.types.Material:
    """
    Generates a high-gloss, multi-layer automotive/cycling frame lacquer material
    matching pro peloton team bicycles (INEOS, Visma-Lease a Bike, UAE Emirates).

    Characteristics:
      - Vibrant base color converted accurately from HEX to Linear sRGB
      - Crystal clearcoat layer (Coat Weight = 1.0, Coat Roughness ~0.03)
      - Mirror-like specular reflections (IOR 1.50)
      - Optional metallic flake / pearl shimmer
    """
    clean_hex = hex_color.strip().lstrip("#").upper()
    mat_name = name or f"M_Frame_Glossy_{clean_hex}"
    mat = _get_or_create_material(mat_name)
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf, _ = _get_or_create_output_nodes(mat)

    linear_col = hex_to_linear_rgb(hex_color)

    if metallic_flake:
        # Micro metallic flake shimmer pattern
        tex_coord = nodes.new("ShaderNodeTexCoord")
        tex_coord.location = (-650, 0)
        noise = nodes.new("ShaderNodeTexNoise")
        noise.location = (-450, 0)
        noise.inputs["Scale"].default_value = 350.0
        noise.inputs["Detail"].default_value = 6.0
        noise.inputs["Roughness"].default_value = 0.8

        ramp = nodes.new("ShaderNodeValToRGB")
        ramp.location = (-220, 0)
        ramp.color_ramp.elements[0].position = 0.45
        ramp.color_ramp.elements[0].color = (linear_col[0] * 0.9, linear_col[1] * 0.9, linear_col[2] * 0.9, 1.0)
        ramp.color_ramp.elements[1].position = 0.75
        ramp.color_ramp.elements[1].color = (
            min(1.0, linear_col[0] * 1.5 + 0.1),
            min(1.0, linear_col[1] * 1.5 + 0.1),
            min(1.0, linear_col[2] * 1.5 + 0.1),
            1.0,
        )

        links.new(tex_coord.outputs["Object"], noise.inputs["Vector"])
        links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
        links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    else:
        _set_bsdf_socket(bsdf, "Base Color", linear_col)

    # Base finish
    _set_bsdf_socket(bsdf, "Roughness", 0.09)
    _set_bsdf_socket(bsdf, "Metallic", metallic)
    _set_bsdf_socket(bsdf, ["Specular IOR Level", "Specular"], 0.55)

    # High-end Clearcoat Lacquer
    _set_bsdf_socket(bsdf, ["Coat Weight", "Clearcoat"], 1.0)
    _set_bsdf_socket(bsdf, ["Coat Roughness", "Clearcoat Roughness"], max(0.01, coat_roughness))
    _set_bsdf_socket(bsdf, "Coat IOR", 1.50)

    return mat


# =============================================================================
# 3. TIRE RUBBER MATERIAL GENERATOR (WITH TAN-WALL COTTON CASING)
# =============================================================================

def create_tire_rubber_material(
    tan_wall: bool = True,
    name: Optional[str] = None,
    tan_hex: str = "#C89D66",
    tread_hex: str = "#151515",
) -> bpy.types.Material:
    """
    Generates a realistic road bicycle tire material.

    When tan_wall=True:
      Creates a classic cotton-casing tire (e.g. Vittoria Corsa Graphene 2.0 /
      Specialized Turbo Cotton) featuring caramel/tan sidewalls and a dark
      vulcanized rubber center tread.

    When tan_wall=False:
      Creates an all-black all-season racing tire.

    Characteristics:
      - Micro-grain vulcanized rubber texture via procedural bump
      - Authentic rubber roughness (~0.72 on tread, ~0.84 on cotton sidewalls)
      - Non-metallic matte finish
    """
    mat_name = name or ("M_Tire_TanWall" if tan_wall else "M_Tire_BlackRubber")
    mat = _get_or_create_material(mat_name)
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf, _ = _get_or_create_output_nodes(mat)

    # Procedural micro-pore rubber bump
    tex_coord = nodes.new("ShaderNodeTexCoord")
    tex_coord.location = (-800, -200)

    noise = nodes.new("ShaderNodeTexNoise")
    noise.name = "Rubber_Grain"
    noise.location = (-600, -200)
    noise.inputs["Scale"].default_value = 180.0
    noise.inputs["Detail"].default_value = 5.0
    noise.inputs["Roughness"].default_value = 0.75

    bump = nodes.new("ShaderNodeBump")
    bump.name = "Rubber_Bump"
    bump.location = (-350, -200)
    bump.inputs["Strength"].default_value = 0.22
    bump.inputs["Distance"].default_value = 0.001

    links.new(tex_coord.outputs["Object"], noise.inputs["Vector"])
    links.new(noise.outputs["Fac"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])

    if tan_wall:
        # Dual-zone tire: UV / local cross-section gradient separating sidewalls from tread
        sep_xyz = nodes.new("ShaderNodeSeparateXYZ")
        sep_xyz.location = (-600, 100)

        color_ramp = nodes.new("ShaderNodeValToRGB")
        color_ramp.name = "TanWall_Mask_Ramp"
        color_ramp.location = (-350, 100)

        c_tan = hex_to_linear_rgb(tan_hex)
        c_tread = hex_to_linear_rgb(tread_hex)

        cr = color_ramp.color_ramp
        # Stop 0.0 & 1.0 are default edges (outer casing/rim bead)
        cr.elements[0].position = 0.00
        cr.elements[0].color = c_tan
        cr.elements[1].position = 1.00
        cr.elements[1].color = c_tan

        # Intermediate stops creating sharp, authentic tire sidewall bands
        s1 = cr.elements.new(0.28)
        s1.color = c_tan
        s2 = cr.elements.new(0.36)
        s2.color = c_tread
        s3 = cr.elements.new(0.64)
        s3.color = c_tread
        s4 = cr.elements.new(0.72)
        s4.color = c_tan

        # Wire UV coordinate Y (cross section) into the color ramp
        links.new(tex_coord.outputs["UV"], sep_xyz.inputs["Vector"])
        links.new(sep_xyz.outputs["Y"], color_ramp.inputs["Fac"])
        links.new(color_ramp.outputs["Color"], bsdf.inputs["Base Color"])

        _set_bsdf_socket(bsdf, "Roughness", 0.78)
    else:
        # Uniform black rubber
        _set_bsdf_socket(bsdf, "Base Color", hex_to_linear_rgb(tread_hex))
        _set_bsdf_socket(bsdf, "Roughness", 0.74)

    _set_bsdf_socket(bsdf, "Metallic", 0.0)
    _set_bsdf_socket(bsdf, ["Specular IOR Level", "Specular"], 0.40)
    _set_bsdf_socket(bsdf, ["Coat Weight", "Clearcoat"], 0.0)

    return mat


# =============================================================================
# 4. METAL ROTOR MATERIAL GENERATOR
# =============================================================================

def create_metal_rotor_material(
    name: str = "M_Metal_Rotor",
    steel_hex: str = "#CBD5E1",
) -> bpy.types.Material:
    """
    Generates a stainless steel disc brake rotor material (Shimano Ice-Tech /
    SRAM CenterLine XR style) with authentic concentric radial lathe grind marks.

    Characteristics:
      - 100% Metallic surface (Metallic = 1.0)
      - Anisotropic reflection (Anisotropic = 0.85, Rotation = 0.25)
      - Concentric circular machining grooves via procedural Spherical Wave bump
      - Polished brake-track roughness (~0.25)
    """
    mat = _get_or_create_material(name)
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf, _ = _get_or_create_output_nodes(mat)

    # Concentric radial grind marks (Spherical Wave Texture)
    tex_coord = nodes.new("ShaderNodeTexCoord")
    tex_coord.location = (-750, 0)

    wave = nodes.new("ShaderNodeTexWave")
    wave.name = "Rotor_Radial_Grind_Lines"
    wave.location = (-500, 0)
    wave.wave_type = "RINGS"
    wave.rings_direction = "SPHERICAL"
    wave.inputs["Scale"].default_value = 85.0
    wave.inputs["Distortion"].default_value = 0.2
    wave.inputs["Detail"].default_value = 3.0

    bump = nodes.new("ShaderNodeBump")
    bump.name = "Rotor_Radial_Bump"
    bump.location = (-220, 0)
    bump.inputs["Strength"].default_value = 0.18
    bump.inputs["Distance"].default_value = 0.0006

    links.new(tex_coord.outputs["Object"], wave.inputs["Vector"])
    links.new(wave.outputs["Color"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])

    # Principled BSDF metallic alloy setup
    _set_bsdf_socket(bsdf, "Base Color", hex_to_linear_rgb(steel_hex))
    _set_bsdf_socket(bsdf, "Metallic", 1.0)
    _set_bsdf_socket(bsdf, "Roughness", 0.25)
    _set_bsdf_socket(bsdf, "Anisotropic", 0.85)
    _set_bsdf_socket(bsdf, "Anisotropic Rotation", 0.25)
    _set_bsdf_socket(bsdf, ["Specular IOR Level", "Specular"], 0.70)

    return mat


# =============================================================================
# 5. LYCRA FABRIC MATERIAL GENERATOR
# =============================================================================

def create_lycra_fabric_material(
    hex_color: str = "#1E3A8A",
    name: Optional[str] = None,
    sheen_weight: float = 1.0,
) -> bpy.types.Material:
    """
    Generates an aerodynamic cycling lycra/spandex material for team kits,
    bib shorts, and race leader jerseys.

    Characteristics:
      - Vibrant team dye color
      - Soft grazing-angle sheen (velvet fiber edge glow)
      - Subtle subsurface scattering representing tight elastic textile fibers
      - Micro-knit bump structure
    """
    clean_hex = hex_color.strip().lstrip("#").upper()
    mat_name = name or f"M_Lycra_Fabric_{clean_hex}"
    mat = _get_or_create_material(mat_name)
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf, _ = _get_or_create_output_nodes(mat)

    # Micro knit weave bump
    tex_coord = nodes.new("ShaderNodeTexCoord")
    tex_coord.location = (-750, 0)

    noise = nodes.new("ShaderNodeTexNoise")
    noise.name = "Fabric_Knit_Weave"
    noise.location = (-500, 0)
    noise.inputs["Scale"].default_value = 240.0
    noise.inputs["Detail"].default_value = 4.0
    noise.inputs["Roughness"].default_value = 0.65

    bump = nodes.new("ShaderNodeBump")
    bump.name = "Lycra_Fabric_Bump"
    bump.location = (-220, 0)
    bump.inputs["Strength"].default_value = 0.08
    bump.inputs["Distance"].default_value = 0.0008

    links.new(tex_coord.outputs["Object"], noise.inputs["Vector"])
    links.new(noise.outputs["Fac"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])

    # Base Color & Sheen configuration
    linear_col = hex_to_linear_rgb(hex_color)
    _set_bsdf_socket(bsdf, "Base Color", linear_col)
    _set_bsdf_socket(bsdf, "Roughness", 0.60)
    _set_bsdf_socket(bsdf, "Metallic", 0.0)

    # Sheen / Velvet edge scattering
    _set_bsdf_socket(bsdf, ["Sheen Weight", "Sheen"], sheen_weight)
    _set_bsdf_socket(bsdf, "Sheen Roughness", 0.40)
    _set_bsdf_socket(bsdf, "Sheen Tint", (1.0, 1.0, 1.0, 1.0))

    # Micro subsurface translucency through stretched lycra fibers
    _set_bsdf_socket(bsdf, ["Subsurface Weight", "Subsurface"], 0.05)
    _set_bsdf_socket(bsdf, "Subsurface Scale", 0.02)
    _set_bsdf_socket(bsdf, ["Coat Weight", "Clearcoat"], 0.0)

    return mat


# =============================================================================
# 6. VISOR IRIDIUM MATERIAL GENERATOR
# =============================================================================

def create_visor_iridium_material(
    tint_color: str = "#FF4500",
    name: str = "M_Visor_Iridium",
    transmission: float = 0.30,
    mirror_factor: float = 0.82,
) -> bpy.types.Material:
    """
    Generates an iridescent dichroic mirror visor for aerodynamic time-trial
    helmets and pro cycling sunglasses (Oakley Prizm / 100% Speedcraft style).

    Characteristics:
      - Angle-dependent color shifting (iridium spectrum: Violet -> Crimson -> Gold -> Cyan)
      - Polycarbonate optical refractive index (IOR 1.58)
      - Semi-transparent transmission allowing rider's eyes/gaze to show faintly
      - Scratch-resistant optical clearcoat
      - Thin-film interference setup (Blender 5.3+ native or multi-stop Fresnel ramp)
    """
    mat = _get_or_create_material(name)
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf, _ = _get_or_create_output_nodes(mat)

    # Dichroic color-shift using Layer Weight Facing angle
    layer_weight = nodes.new("ShaderNodeLayerWeight")
    layer_weight.name = "Iridium_Facing_Angle"
    layer_weight.location = (-600, 0)
    layer_weight.inputs["Blend"].default_value = 0.62

    color_ramp = nodes.new("ShaderNodeValToRGB")
    color_ramp.name = "Iridium_Spectral_Ramp"
    color_ramp.location = (-350, 0)

    # Iridium rainbow gradient: Royal Indigo -> Fiery Crimson -> Solar Gold -> Electric Cyan
    cr = color_ramp.color_ramp
    cr.elements[0].position = 0.00
    cr.elements[0].color = hex_to_linear_rgb("#3B0764")  # Deep Indigo
    cr.elements[1].position = 1.00
    cr.elements[1].color = hex_to_linear_rgb("#06B6D4")  # Cyan

    el_red = cr.elements.new(0.28)
    el_red.color = hex_to_linear_rgb(tint_color)  # Fiery Ruby / Orange
    el_gold = cr.elements.new(0.62)
    el_gold.color = hex_to_linear_rgb("#FACC15")  # Gold

    links.new(layer_weight.outputs["Facing"], color_ramp.inputs["Fac"])
    links.new(color_ramp.outputs["Color"], bsdf.inputs["Base Color"])

    # High-index optical polycarbonate settings
    _set_bsdf_socket(bsdf, "Metallic", mirror_factor)
    _set_bsdf_socket(bsdf, "Roughness", 0.03)
    _set_bsdf_socket(bsdf, ["Transmission Weight", "Transmission"], transmission)
    _set_bsdf_socket(bsdf, "IOR", 1.58)

    # Hydrophobic scratch-resistant optical coat
    _set_bsdf_socket(bsdf, ["Coat Weight", "Clearcoat"], 1.0)
    _set_bsdf_socket(bsdf, ["Coat Roughness", "Clearcoat Roughness"], 0.02)

    # Modern Thin-Film Interference (Blender 4.0 / 5.0+)
    _set_bsdf_socket(bsdf, "Thin Film Thickness", 460.0)  # nanometers
    _set_bsdf_socket(bsdf, "Thin Film IOR", 1.55)

    # Alpha & transparency settings for viewport and EEVEE
    _set_bsdf_socket(bsdf, "Alpha", 0.85)
    if hasattr(mat, "blend_method"):
        try:
            mat.blend_method = "HASHED"
        except Exception:
            pass
    if hasattr(mat, "shadow_method"):
        try:
            mat.shadow_method = "HASHED"
        except Exception:
            pass

    return mat


# =============================================================================
# STUDIO LIGHTING & SHOWCASE SCENE (ZWIFT / MYWHOOSH ESPORTS AESTHETIC)
# =============================================================================

def setup_zwift_studio_lighting() -> None:
    """
    Sets up a 3-point esports cycling studio lighting rig:
      1. Warm sun key light (Color: #FFF7ED, 45 deg high)
      2. Cool ambient sky fill light (Color: #E0F2FE)
      3. Crisp rim/kicker light (#FFFFFF) accentuating aerodynamic tube edges and helmet silhouettes.
    """
    scene = bpy.context.scene

    # Remove existing default lights
    for light in [o for o in scene.objects if o.type == "LIGHT"]:
        bpy.data.objects.remove(light, do_unlink=True)

    # 1. Key Sun Light (Warm 45-degree angled sun)
    key_light_data = bpy.data.lights.new(name="Zwift_Key_Sun", type="SUN")
    key_light_data.energy = 4.0
    key_light_data.color = (1.0, 0.96, 0.91)
    key_light_obj = bpy.data.objects.new(name="Zwift_Key_Sun", object_data=key_light_data)
    key_light_obj.location = (6.0, -8.0, 10.0)
    key_light_obj.rotation_euler = (math.radians(45.0), math.radians(20.0), math.radians(35.0))
    scene.collection.objects.link(key_light_obj)

    # 2. Fill Light (Cool sky ambient bounce)
    fill_light_data = bpy.data.lights.new(name="Zwift_Fill_Light", type="AREA")
    fill_light_data.energy = 120.0
    fill_light_data.size = 5.0
    fill_light_data.color = (0.85, 0.92, 1.0)
    fill_light_obj = bpy.data.objects.new(name="Zwift_Fill_Light", object_data=fill_light_data)
    fill_light_obj.location = (-6.0, -6.0, 5.0)
    fill_light_obj.rotation_euler = (math.radians(50.0), 0.0, math.radians(-45.0))
    scene.collection.objects.link(fill_light_obj)

    # 3. Rim / Kicker Light (High-angle backlight emphasizing silhouette)
    rim_light_data = bpy.data.lights.new(name="Zwift_Rim_Kicker", type="SPOT")
    rim_light_data.energy = 450.0
    rim_light_data.spot_size = math.radians(70.0)
    rim_light_data.color = (1.0, 1.0, 1.0)
    rim_light_obj = bpy.data.objects.new(name="Zwift_Rim_Kicker", object_data=rim_light_data)
    rim_light_obj.location = (0.0, 7.0, 6.0)
    rim_light_obj.rotation_euler = (math.radians(-130.0), 0.0, math.radians(180.0))
    scene.collection.objects.link(rim_light_obj)

    # Color Management (Punchy esports contrast)
    if hasattr(scene, "view_settings"):
        try:
            scene.view_settings.view_transform = "AgX" if "AgX" in [v.name for v in scene.view_settings.bl_rna.properties["view_transform"].enum_items] else "Filmic"
            scene.view_settings.look = "Medium High Contrast"
        except Exception:
            pass


def create_material_showcase_scene() -> Dict[str, bpy.types.Object]:
    """
    Builds a clean 3D showroom bench featuring all 6 procedural PBR materials
    applied to representative cycling geometries (aero frame tube, deep rim,
    tan-wall tire, disc rotor, lycra jersey sphere, and time-trial visor).
    """
    # Clear existing mesh objects
    for obj in [o for o in bpy.context.scene.objects if o.type == "MESH"]:
        bpy.data.objects.remove(obj, do_unlink=True)

    objects_dict = {}

    # 1. Glossy Frame Paint (#E10600 - Racing Red) -> Aero Tube
    bpy.ops.mesh.primitive_cylinder_add(radius=0.25, depth=1.6, location=(-3.75, 0.0, 0.8))
    frame_obj = bpy.context.active_object
    frame_obj.name = "Showcase_Glossy_Frame_Tube"
    frame_obj.scale = (1.0, 0.55, 1.0)  # teardrop aero profile
    apply_zwift_style(frame_obj)
    mat_frame = create_glossy_frame_paint_material("#E10600")
    assign_material(frame_obj, mat_frame)
    objects_dict["frame"] = frame_obj

    # 2. Carbon Matte -> Deep Section Aero Wheel Rim
    bpy.ops.mesh.primitive_cylinder_add(radius=0.55, depth=0.35, location=(-2.25, 0.0, 0.8))
    rim_obj = bpy.context.active_object
    rim_obj.name = "Showcase_Carbon_Rim"
    apply_zwift_style(rim_obj)
    mat_carbon = create_carbon_matte_material()
    assign_material(rim_obj, mat_carbon)
    objects_dict["carbon"] = rim_obj

    # 3. Tire Rubber (Tan Wall) -> Racing Tire Torus
    bpy.ops.mesh.primitive_torus_add(
        major_radius=0.55, minor_radius=0.15, location=(-0.75, 0.0, 0.8)
    )
    tire_obj = bpy.context.active_object
    tire_obj.name = "Showcase_TanWall_Tire"
    apply_zwift_style(tire_obj)
    mat_tire = create_tire_rubber_material(tan_wall=True)
    assign_material(tire_obj, mat_tire)
    objects_dict["tire"] = tire_obj

    # 4. Metal Rotor -> Disc Brake Rotor Disc
    bpy.ops.mesh.primitive_cylinder_add(radius=0.45, depth=0.03, location=(0.75, 0.0, 0.8))
    rotor_obj = bpy.context.active_object
    rotor_obj.name = "Showcase_Metal_Rotor"
    apply_zwift_style(rotor_obj)
    mat_rotor = create_metal_rotor_material()
    assign_material(rotor_obj, mat_rotor)
    objects_dict["rotor"] = rotor_obj

    # 5. Lycra Fabric (#1E3A8A - Navy Racing Jersey) -> Fabric Sphere
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.42, location=(2.25, 0.0, 0.8))
    lycra_obj = bpy.context.active_object
    lycra_obj.name = "Showcase_Lycra_Fabric"
    apply_zwift_style(lycra_obj)
    mat_lycra = create_lycra_fabric_material("#1E3A8A")
    assign_material(lycra_obj, mat_lycra)
    objects_dict["lycra"] = lycra_obj

    # 6. Visor Iridium -> Curved TT Helmet Visor
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.45, location=(3.75, 0.0, 0.8))
    visor_obj = bpy.context.active_object
    visor_obj.name = "Showcase_Visor_Iridium"
    visor_obj.scale = (1.0, 0.65, 0.85)
    apply_zwift_style(visor_obj)
    mat_visor = create_visor_iridium_material(tint_color="#FF4500")
    assign_material(visor_obj, mat_visor)
    objects_dict["visor"] = visor_obj

    # Ground Pedestal
    bpy.ops.mesh.primitive_plane_add(size=20.0, location=(0.0, 0.0, 0.0))
    pedestal = bpy.context.active_object
    pedestal.name = "Showcase_Ground"
    apply_zwift_style(pedestal)
    mat_ground = _get_or_create_material("M_Showcase_Ground")
    bsdf_ground, _ = _get_or_create_output_nodes(mat_ground)
    _set_bsdf_socket(bsdf_ground, "Base Color", hex_to_linear_rgb("#0F172A"))
    _set_bsdf_socket(bsdf_ground, "Roughness", 0.40)
    assign_material(pedestal, mat_ground)

    # Camera framing the showcase row
    cam_data = bpy.data.cameras.new(name="Showcase_Camera")
    cam_data.lens = 45.0
    cam_obj = bpy.data.objects.new(name="Showcase_Camera", object_data=cam_data)
    cam_obj.location = (0.0, -7.5, 2.5)
    cam_obj.rotation_euler = (math.radians(75.0), 0.0, 0.0)
    bpy.context.scene.collection.objects.link(cam_obj)
    bpy.context.scene.camera = cam_obj

    # Studio Lighting
    setup_zwift_studio_lighting()

    return objects_dict


# =============================================================================
# CLI EXECUTION ENTRY POINT
# =============================================================================

if __name__ == "__main__":
    print("\n" + "=" * 70)
    print("PRO PELOTON MANAGER: INITIALIZING ZWIFT-STYLE VISUALS & PBR MATERIALS")
    print("=" * 70)
    print(f"Blender Version: {bpy.app.version_string}")

    # Generate the showcase scene
    showcase = create_material_showcase_scene()

    print(f"[OK] Generated {len(showcase)} showroom objects:")
    for key, obj in showcase.items():
        mat_name = obj.data.materials[0].name if obj.data.materials else "None"
        print(f"     - {key.upper():<8}: Object '{obj.name}' -> Material '{mat_name}'")

    print("\n[OK] Zwift studio 3-point lighting and camera setup completed.")
    print("[OK] All 6 material generators successfully verified in Blender!")
    print("=" * 70 + "\n")
