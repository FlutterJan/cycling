"""
===============================================================================
PRO PELOTON MANAGER - HORS CATEGORIE ALPINE SUMMIT SCENERY GENERATOR
===============================================================================
Blender 5.3 Python API (bpy) script that procedurally models a 3D Hors
Categorie alpine summit scenery pack (`assets/3d/environment/alpine_summit_pack.glb`):

  1. Meteorological Observatory & Red-White Relay Tower
     (inspired by Mont Ventoux / Pic du Midi):
     - Stepped rocky alpine concrete plinth & main octagonal observatory block
     - Recessed panoramic observation windows with mullions, entrance vestibule
     - Hemispherical meteorological radome on the roof deck
     - Tall tapered red-and-white striped broadcast/relay tower with
       maintenance platforms, microwave dish antennas, and aviation beacon

  2. 3-Meter-High Snow Walls (inspired by Passo dello Stelvio / Gavia in May):
     - Left and right 3.0m-tall sculpted snow-plow banks flanking the road
     - Organic drift undulations, snow-plow cut striations, and top cornices
     - Cool, slightly bluish alpine snow PBR material

  3. Set of 3 Stylized Fan Camper Vans (RVs) for Hairpin Switchbacks:
     - RV 01 (Classic Alcove Motorhome) with burgundy stripe, awning & KOM flag
     - RV 02 (European Sprinter Camper) with gold stripe, awning & yellow flag
     - RV 03 (Integrated Expedition RV) with emerald stripe, awning & green flag

Usage:
  blender --background --python blender_scripts/generate_alpine_summit_scenery.py
  blender --background --python blender_scripts/generate_alpine_summit_scenery.py -- --output-dir assets/3d/environment

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
    from mathutils import Matrix, Vector
except ImportError:
    print("[ERROR] 'bpy' / 'mathutils' module not found. Run within Blender:")
    print("        blender --background --python blender_scripts/generate_alpine_summit_scenery.py")
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
    emission_color: Optional[str] = None,
    emission_strength: float = 0.0,
) -> bpy.types.Material:
    """Creates a clean Principled BSDF PBR material compatible with Blender 5.3 and glTF 2.0."""
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)
    sm._set_bsdf_socket(bsdf, ["Base Color"], sm.hex_to_linear_rgb(hex_color))
    sm._set_bsdf_socket(bsdf, ["Roughness"], roughness)
    sm._set_bsdf_socket(bsdf, ["Metallic"], metallic)
    sm._set_bsdf_socket(bsdf, ["Specular IOR Level", "Specular"], specular_ior)
    sm._set_bsdf_socket(bsdf, ["IOR"], ior)
    if emission_color is not None and emission_strength > 0.0:
        sm._set_bsdf_socket(bsdf, ["Emission Color", "Emission"], sm.hex_to_linear_rgb(emission_color))
        sm._set_bsdf_socket(bsdf, ["Emission Strength"], emission_strength)
    return mat


def create_observatory_materials() -> List[bpy.types.Material]:
    """Builds the ordered material palette for the Alpine Summit Observatory & Relay Tower."""
    return [
        # 0: Weathered alpine concrete & stone plinth
        _make_pbr_material("Mat_Obs_Alpine_Concrete", "#8A8F98", roughness=0.82, metallic=0.0),
        # 1: Dark slate foundation rock / buttress trim
        _make_pbr_material("Mat_Obs_Foundation_Rock", "#4B525C", roughness=0.88, metallic=0.0),
        # 2: White tower & radome composite cladding
        _make_pbr_material("Mat_Obs_Tower_White", "#F3F4F6", roughness=0.38, metallic=0.05),
        # 3: Signal red tower bands & beacon housing
        _make_pbr_material("Mat_Obs_Tower_Red", "#DC2626", roughness=0.36, metallic=0.08),
        # 4: Observation window tinted glass
        _make_pbr_material(
            "Mat_Obs_Window_Glass",
            "#111B27",
            roughness=0.10,
            metallic=0.15,
            specular_ior=0.85,
            ior=1.52,
        ),
        # 5: Galvanized steel lattice, railings, and antenna dishes
        _make_pbr_material("Mat_Obs_Galvanized_Steel", "#94A3B8", roughness=0.35, metallic=0.85),
        # 6: Aviation warning beacon emission
        _make_pbr_material(
            "Mat_Obs_Beacon_Glow",
            "#EF4444",
            roughness=0.20,
            metallic=0.0,
            emission_color="#FF2A2A",
            emission_strength=3.5,
        ),
    ]


def create_snow_wall_materials() -> List[bpy.types.Material]:
    """Builds the cool, slightly bluish snow material palette for Stelvio/Gavia snow walls."""
    return [
        # 0: Primary cool bluish alpine snow
        _make_pbr_material(
            "Mat_Alpine_Snow_Cool",
            "#DCEEFF",
            roughness=0.74,
            metallic=0.0,
            specular_ior=0.45,
            ior=1.31,
        ),
        # 1: Compressed glacial-blue snow-plow cut lower strata
        _make_pbr_material(
            "Mat_Alpine_Snow_Glacial_Shadow",
            "#BBD8F6",
            roughness=0.64,
            metallic=0.0,
            specular_ior=0.52,
            ior=1.31,
        ),
        # 2: Dark alpine road shoulder gravel/asphalt edge
        _make_pbr_material("Mat_Alpine_Road_Edge", "#32363E", roughness=0.86, metallic=0.0),
    ]


def create_rv_materials(
    prefix: str,
    body_hex: str,
    stripe_hex: str,
    awning_a_hex: str,
    awning_b_hex: str,
    flag_primary_hex: str,
    flag_secondary_hex: str,
) -> List[bpy.types.Material]:
    """Builds the ordered material palette for a stylized cycling fan camper van (RV)."""
    return [
        # 0: Primary RV body paint
        _make_pbr_material(f"Mat_{prefix}_Body", body_hex, roughness=0.32, metallic=0.10),
        # 1: Racing / livery accent stripe
        _make_pbr_material(f"Mat_{prefix}_Stripe", stripe_hex, roughness=0.35, metallic=0.08),
        # 2: Dark bumper & lower trim
        _make_pbr_material(f"Mat_{prefix}_Trim", "#1F2937", roughness=0.68, metallic=0.05),
        # 3: Tinted cabin & living-area windows
        _make_pbr_material(
            f"Mat_{prefix}_Glass",
            "#0F172A",
            roughness=0.08,
            metallic=0.12,
            specular_ior=0.88,
            ior=1.52,
        ),
        # 4: Rubber tires
        _make_pbr_material(f"Mat_{prefix}_Rubber", "#141619", roughness=0.86, metallic=0.0),
        # 5: Alloy wheel rims & awning poles / flagpole
        _make_pbr_material(f"Mat_{prefix}_Alloy", "#CBD5E1", roughness=0.28, metallic=0.88),
        # 6: Awning fabric stripe A
        _make_pbr_material(f"Mat_{prefix}_Awning_A", awning_a_hex, roughness=0.82, metallic=0.0),
        # 7: Awning fabric stripe B
        _make_pbr_material(f"Mat_{prefix}_Awning_B", awning_b_hex, roughness=0.82, metallic=0.0),
        # 8: Cycling fan flag primary color
        _make_pbr_material(f"Mat_{prefix}_Flag_Primary", flag_primary_hex, roughness=0.72, metallic=0.0),
        # 9: Cycling fan flag secondary / polka-dot or stripe color
        _make_pbr_material(f"Mat_{prefix}_Flag_Secondary", flag_secondary_hex, roughness=0.72, metallic=0.0),
        # 10: Headlight / taillight accent
        _make_pbr_material(
            f"Mat_{prefix}_Headlight",
            "#FEF3C7",
            roughness=0.15,
            metallic=0.0,
            emission_color="#FDE68A",
            emission_strength=1.5,
        ),
    ]


# =============================================================================
# BMESH GEOMETRY HELPERS
# =============================================================================

def _assign_mat(faces: List[bmesh.types.BMFace], mat_index: int, smooth: bool = False) -> None:
    """Assigns material index and shading mode to a list of BMesh faces."""
    for face in faces:
        face.material_index = mat_index
        face.smooth = smooth


def _add_box(
    bm: bmesh.types.BMesh,
    center: Tuple[float, float, float],
    size: Tuple[float, float, float],
    mat_index: int = 0,
    smooth: bool = False,
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
    _assign_mat(faces, mat_index, smooth=smooth)
    return faces


def _add_tapered_cylinder(
    bm: bmesh.types.BMesh,
    center_xy: Tuple[float, float],
    z_bottom: float,
    z_top: float,
    radius_bottom: float,
    radius_top: float,
    segments: int = 16,
    mat_index: int = 0,
    cap_bottom: bool = True,
    cap_top: bool = True,
    smooth: bool = True,
) -> List[bmesh.types.BMFace]:
    """Creates a vertical tapered cylinder or frustum along Z."""
    cx, cy = center_xy
    bot_ring: List[bmesh.types.BMVert] = []
    top_ring: List[bmesh.types.BMVert] = []

    for i in range(segments):
        angle = (2.0 * math.pi * i) / segments
        ca, sa = math.cos(angle), math.sin(angle)
        bot_ring.append(bm.verts.new((cx + radius_bottom * ca, cy + radius_bottom * sa, z_bottom)))
        top_ring.append(bm.verts.new((cx + radius_top * ca, cy + radius_top * sa, z_top)))

    faces: List[bmesh.types.BMFace] = []
    for i in range(segments):
        ni = (i + 1) % segments
        f_side = bm.faces.new((bot_ring[i], bot_ring[ni], top_ring[ni], top_ring[i]))
        f_side.material_index = mat_index
        f_side.smooth = smooth
        faces.append(f_side)

    if cap_bottom and radius_bottom > 1e-5:
        f_bot = bm.faces.new(tuple(reversed(bot_ring)))
        f_bot.material_index = mat_index
        f_bot.smooth = False
        faces.append(f_bot)

    if cap_top and radius_top > 1e-5:
        f_top = bm.faces.new(tuple(top_ring))
        f_top.material_index = mat_index
        f_top.smooth = False
        faces.append(f_top)

    return faces


def _add_cylinder_along_x(
    bm: bmesh.types.BMesh,
    center_yz: Tuple[float, float],
    x_min: float,
    x_max: float,
    radius: float,
    segments: int = 16,
    mat_index: int = 0,
    smooth: bool = True,
) -> List[bmesh.types.BMFace]:
    """Creates a horizontal cylinder oriented along the X axis (ideal for wheels/axles)."""
    cy, cz = center_yz
    left_ring: List[bmesh.types.BMVert] = []
    right_ring: List[bmesh.types.BMVert] = []

    for i in range(segments):
        angle = (2.0 * math.pi * i) / segments
        ca, sa = math.cos(angle), math.sin(angle)
        left_ring.append(bm.verts.new((x_min, cy + radius * ca, cz + radius * sa)))
        right_ring.append(bm.verts.new((x_max, cy + radius * ca, cz + radius * sa)))

    faces: List[bmesh.types.BMFace] = []
    for i in range(segments):
        ni = (i + 1) % segments
        f_side = bm.faces.new((left_ring[i], right_ring[i], right_ring[ni], left_ring[ni]))
        f_side.material_index = mat_index
        f_side.smooth = smooth
        faces.append(f_side)

    f_l = bm.faces.new(tuple(reversed(left_ring)))
    f_l.material_index = mat_index
    f_r = bm.faces.new(tuple(right_ring))
    f_r.material_index = mat_index
    faces.extend([f_l, f_r])
    return faces


def _add_oriented_strut(
    bm: bmesh.types.BMesh,
    p0: Tuple[float, float, float],
    p1: Tuple[float, float, float],
    thickness: float,
    mat_index: int = 0,
) -> None:
    """Creates a 4-sided structural strut between two 3D points."""
    v0 = Vector(p0)
    v1 = Vector(p1)
    axis = v1 - v0
    length = axis.length
    if length < 1e-5:
        return

    z_dir = axis.normalized()
    ref = Vector((0.0, 0.0, 1.0)) if abs(z_dir.z) < 0.9 else Vector((1.0, 0.0, 0.0))
    x_dir = z_dir.cross(ref).normalized()
    y_dir = z_dir.cross(x_dir).normalized()

    half = thickness * 0.5
    offsets = [
        (-half, -half),
        (half, -half),
        (half, half),
        (-half, half),
    ]

    ring0 = [bm.verts.new(v0 + x_dir * ox + y_dir * oy) for ox, oy in offsets]
    ring1 = [bm.verts.new(v1 + x_dir * ox + y_dir * oy) for ox, oy in offsets]

    for i in range(4):
        ni = (i + 1) % 4
        f = bm.faces.new((ring0[i], ring0[ni], ring1[ni], ring1[i]))
        f.material_index = mat_index
        f.smooth = False


def _add_hemisphere_dome(
    bm: bmesh.types.BMesh,
    center: Tuple[float, float, float],
    radius: float,
    rings: int = 8,
    segments: int = 20,
    mat_index: int = 2,
) -> None:
    """Creates an upper hemispherical meteorological radome."""
    cx, cy, cz = center
    ring_verts: List[List[bmesh.types.BMVert]] = []

    for r_idx in range(rings):
        phi = (math.pi * 0.5) * (r_idx / rings)
        ring_r = radius * math.cos(phi)
        ring_z = cz + radius * math.sin(phi)
        verts: List[bmesh.types.BMVert] = []
        for s_idx in range(segments):
            theta = (2.0 * math.pi * s_idx) / segments
            verts.append(bm.verts.new((cx + ring_r * math.cos(theta), cy + ring_r * math.sin(theta), ring_z)))
        ring_verts.append(verts)

    apex = bm.verts.new((cx, cy, cz + radius))

    for r_idx in range(rings - 1):
        for s_idx in range(segments):
            ns = (s_idx + 1) % segments
            f = bm.faces.new((
                ring_verts[r_idx][s_idx],
                ring_verts[r_idx][ns],
                ring_verts[r_idx + 1][ns],
                ring_verts[r_idx + 1][s_idx],
            ))
            f.material_index = mat_index
            f.smooth = True

    top_ring = ring_verts[-1]
    for s_idx in range(segments):
        ns = (s_idx + 1) % segments
        f = bm.faces.new((top_ring[s_idx], top_ring[ns], apex))
        f.material_index = mat_index
        f.smooth = True

    f_base = bm.faces.new(tuple(reversed(ring_verts[0])))
    f_base.material_index = mat_index


# =============================================================================
# 1. METEOROLOGICAL OBSERVATORY & RED-WHITE RELAY TOWER
# =============================================================================

def generate_alpine_observatory_mesh(
    name: str = "Alpine_Summit_Observatory",
    location: Tuple[float, float, float] = (0.0, 14.0, 0.0),
) -> bpy.types.Object:
    """
    Generates an iconic Hors Categorie meteorological observatory with a tall
    red-and-white striped broadcast/relay tower (inspired by Mont Ventoux / Pic du Midi).
    """
    mesh = bpy.data.meshes.new(f"{name}_Mesh")
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)

    for mat in create_observatory_materials():
        obj.data.materials.append(mat)

    bm = bmesh.new()

    # --- A. Stepped Alpine Stone & Concrete Plinth ---
    _add_tapered_cylinder(
        bm,
        center_xy=(0.0, 0.0),
        z_bottom=0.0,
        z_top=1.1,
        radius_bottom=7.4,
        radius_top=6.6,
        segments=8,
        mat_index=1,  # Foundation rock
        smooth=False,
    )
    _add_tapered_cylinder(
        bm,
        center_xy=(0.0, 0.0),
        z_bottom=1.1,
        z_top=1.8,
        radius_bottom=6.3,
        radius_top=6.1,
        segments=8,
        mat_index=0,  # Concrete
        smooth=False,
    )

    # --- B. Main Observatory Building (Octagonal + Panoramic Observation Deck) ---
    _add_tapered_cylinder(
        bm,
        center_xy=(0.0, 0.0),
        z_bottom=1.8,
        z_top=5.2,
        radius_bottom=5.3,
        radius_top=5.1,
        segments=8,
        mat_index=0,
        smooth=False,
    )

    # Recessed panoramic observation window band (z = 3.2..4.4)
    _add_tapered_cylinder(
        bm,
        center_xy=(0.0, 0.0),
        z_bottom=3.25,
        z_top=4.45,
        radius_bottom=5.26,
        radius_top=5.20,
        segments=8,
        mat_index=4,  # Tinted glass
        cap_bottom=False,
        cap_top=False,
        smooth=False,
    )

    # Vertical structural concrete buttresses around the 8 corners
    for i in range(8):
        angle = (2.0 * math.pi * i) / 8.0 + (math.pi / 8.0)
        bx = 5.25 * math.cos(angle)
        by = 5.25 * math.sin(angle)
        _add_box(bm, center=(bx, by, 3.5), size=(0.55, 0.55, 3.5), mat_index=1)

    # Roof cornice & parapet ring
    _add_tapered_cylinder(
        bm,
        center_xy=(0.0, 0.0),
        z_bottom=5.2,
        z_top=5.7,
        radius_bottom=5.55,
        radius_top=5.55,
        segments=8,
        mat_index=0,
        smooth=False,
    )

    # Entrance vestibule & access stairs facing -Y (toward the road)
    _add_box(bm, center=(0.0, -5.6, 2.8), size=(2.6, 1.8, 2.1), mat_index=0)
    _add_box(bm, center=(0.0, -6.52, 2.65), size=(1.3, 0.12, 1.7), mat_index=4)
    for step in range(4):
        sz = 0.25 + step * 0.35
        sy = -7.6 + step * 0.45
        _add_box(bm, center=(0.0, sy, sz), size=(2.4, 0.55, 0.35), mat_index=1)

    # --- C. Side Meteorological Radome Wing ---
    _add_box(bm, center=(-3.2, 2.1, 6.2), size=(2.8, 2.8, 1.1), mat_index=0)
    _add_tapered_cylinder(
        bm,
        center_xy=(-3.2, 2.1),
        z_bottom=6.75,
        z_top=7.35,
        radius_bottom=1.35,
        radius_top=1.35,
        segments=16,
        mat_index=5,
        smooth=True,
    )
    _add_hemisphere_dome(
        bm,
        center=(-3.2, 2.1, 7.35),
        radius=1.35,
        rings=7,
        segments=16,
        mat_index=2,  # White radome
    )

    # --- D. Iconic Mont Ventoux Red-and-White Relay Tower ---
    tower_xy = (1.3, 0.4)
    # Concrete tower collar base
    _add_tapered_cylinder(
        bm,
        center_xy=tower_xy,
        z_bottom=5.7,
        z_top=7.0,
        radius_bottom=2.3,
        radius_top=2.0,
        segments=16,
        mat_index=0,
        smooth=True,
    )

    # Alternating white (2) and signal-red (3) tower shaft bands
    band_specs = [
        (7.0, 9.6, 1.85, 1.68, 2),
        (9.6, 12.2, 1.68, 1.50, 3),
        (12.2, 14.8, 1.50, 1.34, 2),
        (14.8, 17.2, 1.34, 1.18, 3),
        (17.2, 19.4, 1.18, 1.02, 2),
        (19.4, 21.4, 1.02, 0.86, 3),
    ]
    for zb, zt, rb, rt, mat_idx in band_specs:
        _add_tapered_cylinder(
            bm,
            center_xy=tower_xy,
            z_bottom=zb,
            z_top=zt,
            radius_bottom=rb,
            radius_top=rt,
            segments=16,
            mat_index=mat_idx,
            cap_bottom=False,
            cap_top=(zb == 19.4),
            smooth=True,
        )

    # Steel maintenance gallery platforms at z=12.2 and z=17.2
    for plat_z, plat_r in [(12.2, 2.05), (17.2, 1.65)]:
        _add_tapered_cylinder(
            bm,
            center_xy=tower_xy,
            z_bottom=plat_z - 0.12,
            z_top=plat_z + 0.12,
            radius_bottom=plat_r,
            radius_top=plat_r,
            segments=16,
            mat_index=5,
            smooth=False,
        )
        # Perimeter guardrail posts
        for p_idx in range(8):
            ang = (2.0 * math.pi * p_idx) / 8.0
            px = tower_xy[0] + (plat_r - 0.08) * math.cos(ang)
            py = tower_xy[1] + (plat_r - 0.08) * math.sin(ang)
            _add_box(bm, center=(px, py, plat_z + 0.45), size=(0.08, 0.08, 0.75), mat_index=5)

    # Microwave telemetry dish antennas mounted on the tower
    for dish_z, dish_ang, dish_r in [(13.5, -0.7, 0.72), (15.8, 2.1, 0.60), (18.2, 0.5, 0.52)]:
        dx = tower_xy[0] + 1.45 * math.cos(dish_ang)
        dy = tower_xy[1] + 1.45 * math.sin(dish_ang)
        _add_oriented_strut(
            bm,
            (tower_xy[0], tower_xy[1], dish_z),
            (dx, dy, dish_z),
            thickness=0.14,
            mat_index=5,
        )
        _add_box(bm, center=(dx, dy, dish_z), size=(dish_r * 0.35, dish_r * 1.4, dish_r * 1.4), mat_index=2)

    # Upper antenna spire (red/white striped needle + glowing aviation beacon)
    spire_segments = [
        (21.4, 23.2, 0.34, 0.24, 2),
        (23.2, 25.0, 0.24, 0.15, 3),
        (25.0, 26.8, 0.15, 0.08, 2),
    ]
    for zb, zt, rb, rt, mat_idx in spire_segments:
        _add_tapered_cylinder(
            bm,
            center_xy=tower_xy,
            z_bottom=zb,
            z_top=zt,
            radius_bottom=rb,
            radius_top=rt,
            segments=12,
            mat_index=mat_idx,
            cap_bottom=False,
            cap_top=True,
            smooth=True,
        )

    # Glowing aviation beacon at the apex (z = 26.8..27.15)
    _add_tapered_cylinder(
        bm,
        center_xy=tower_xy,
        z_bottom=26.8,
        z_top=27.15,
        radius_bottom=0.14,
        radius_top=0.10,
        segments=12,
        mat_index=6,  # Glowing red beacon
        smooth=True,
    )

    bm.to_mesh(mesh)
    bm.free()

    obj.location = location
    sm.clean_zwift_mesh(obj, merge_distance=0.0005)
    sm.apply_zwift_style(obj, auto_smooth_angle_deg=35.0)
    return obj


# =============================================================================
# 2. 3-METER-HIGH SNOW WALLS (STELVIO / GAVIA IN MAY)
# =============================================================================

def _build_snow_bank_side(
    bm: bmesh.types.BMesh,
    side_sign: float,
    road_half_width: float = 3.6,
    length_y: float = 22.0,
    wall_height: float = 3.0,
    bank_depth: float = 3.8,
    y_segments: int = 28,
) -> None:
    """
    Sculpts a 3.0-meter-high snow-plow wall along one side of the alpine road.
    side_sign = -1.0 for left bank (-X), +1.0 for right bank (+X).
    """
    y_start = -length_y * 0.5
    dy = length_y / y_segments

    profiles: List[List[bmesh.types.BMVert]] = []

    for iy in range(y_segments + 1):
        y = y_start + iy * dy
        # Subtle organic drift variation along the road
        drift_h = 0.14 * math.sin(y * 0.42 + side_sign * 1.1) + 0.08 * math.cos(y * 0.95)
        drift_x = 0.10 * math.sin(y * 0.55 - side_sign * 0.7)
        h_top = wall_height + drift_h

        x_inner_base = side_sign * (road_half_width + drift_x * 0.35)
        x_inner_mid = side_sign * (road_half_width + 0.18 + drift_x * 0.5)
        x_inner_top = side_sign * (road_half_width + 0.45 + drift_x)
        x_crest = side_sign * (road_half_width + 1.25 + drift_x * 0.8)
        x_outer_mid = side_sign * (road_half_width + bank_depth * 0.72)
        x_outer_base = side_sign * (road_half_width + bank_depth)

        # Cross-section profile from inner road edge -> 3m vertical cut -> rounded crest -> outer slope
        pts = [
            (x_inner_base, y, 0.0),
            (x_inner_mid, y, 1.15),
            (x_inner_top, y, h_top - 0.12),
            (x_crest, y, h_top + 0.16),
            (x_outer_mid, y, h_top * 0.52),
            (x_outer_base, y, 0.0),
        ]
        profiles.append([bm.verts.new(p) for p in pts])

    n_pts = len(profiles[0])
    for iy in range(y_segments):
        p0 = profiles[iy]
        p1 = profiles[iy + 1]
        for k in range(n_pts - 1):
            if side_sign > 0:
                f = bm.faces.new((p0[k], p0[k + 1], p1[k + 1], p1[k]))
            else:
                f = bm.faces.new((p0[k], p1[k], p1[k + 1], p0[k + 1]))
            # Lower snow-plow cut band gets slightly deeper glacial-blue tint
            f.material_index = 1 if k == 0 else 0
            f.smooth = True

        # Close underside
        if side_sign > 0:
            f_bot = bm.faces.new((p0[-1], p0[0], p1[0], p1[-1]))
        else:
            f_bot = bm.faces.new((p0[-1], p1[-1], p1[0], p0[0]))
        f_bot.material_index = 2
        f_bot.smooth = False

    # Cap both ends (y_start and y_end)
    for end_idx, reverse_order in [(0, side_sign < 0), (y_segments, side_sign > 0)]:
        ring = profiles[end_idx]
        ordered = list(reversed(ring)) if reverse_order else ring
        f_end = bm.faces.new(tuple(ordered))
        f_end.material_index = 0
        f_end.smooth = False


def generate_alpine_snow_walls_mesh(
    name: str = "Alpine_Snow_Walls_Corridor",
    location: Tuple[float, float, float] = (0.0, 0.0, 0.0),
) -> bpy.types.Object:
    """
    Generates 3-meter-high Stelvio/Gavia-style snow walls flanking both sides
    of the summit road corridor with cool, slightly bluish snow material.
    """
    mesh = bpy.data.meshes.new(f"{name}_Mesh")
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)

    for mat in create_snow_wall_materials():
        obj.data.materials.append(mat)

    bm = bmesh.new()

    # Left (-X) and Right (+X) 3.0m snow walls
    _build_snow_bank_side(bm, side_sign=-1.0, road_half_width=3.6, length_y=22.0, wall_height=3.0)
    _build_snow_bank_side(bm, side_sign=1.0, road_half_width=3.6, length_y=22.0, wall_height=3.0)

    # Subtle asphalt road shoulder strips at the base of each snow wall
    _add_box(bm, center=(-3.35, 0.0, 0.03), size=(0.55, 22.0, 0.06), mat_index=2)
    _add_box(bm, center=(3.35, 0.0, 0.03), size=(0.55, 22.0, 0.06), mat_index=2)

    bm.to_mesh(mesh)
    bm.free()

    obj.location = location
    sm.clean_zwift_mesh(obj, merge_distance=0.0005)
    sm.apply_zwift_style(obj, auto_smooth_angle_deg=40.0)
    return obj


# =============================================================================
# 3. STYLIZED FAN CAMPER VANS (RVs) WITH AWNINGS & CYCLING FLAGS
# =============================================================================

def _add_rv_wheels(bm: bmesh.types.BMesh, half_track_x: float, wheel_ys: List[float], radius: float) -> None:
    """Adds four wheels with alloy rims along the left and right sides of an RV."""
    tire_w = 0.24
    for wy in wheel_ys:
        for side in (-1.0, 1.0):
            x_in = side * (half_track_x - tire_w * 0.5)
            x_out = side * (half_track_x + tire_w * 0.5)
            x0, x1 = min(x_in, x_out), max(x_in, x_out)
            _add_cylinder_along_x(
                bm,
                center_yz=(wy, radius),
                x_min=x0,
                x_max=x1,
                radius=radius,
                segments=16,
                mat_index=4,  # Rubber
                smooth=True,
            )
            # Alloy hubcap slightly protruding on outer face
            hub_x0 = side * (half_track_x + tire_w * 0.42)
            hub_x1 = side * (half_track_x + tire_w * 0.54)
            _add_cylinder_along_x(
                bm,
                center_yz=(wy, radius),
                x_min=min(hub_x0, hub_x1),
                x_max=max(hub_x0, hub_x1),
                radius=radius * 0.56,
                segments=12,
                mat_index=5,  # Alloy
                smooth=True,
            )


def _add_rv_awning(
    bm: bmesh.types.BMesh,
    mount_x: float,
    y_center: float,
    z_mount: float,
    awning_length: float,
    awning_reach: float,
    drop_z: float,
    segments: int = 6,
) -> None:
    """Adds a striped roll-out RV awning with support legs."""
    # Awning cassette housing on the RV wall
    _add_box(bm, center=(mount_x + 0.06, y_center, z_mount + 0.05), size=(0.14, awning_length + 0.16, 0.14), mat_index=5)

    # Striped fabric canopy
    seg_y = awning_length / segments
    y0 = y_center - awning_length * 0.5
    for idx in range(segments):
        sy0 = y0 + idx * seg_y
        sy1 = sy0 + seg_y
        mat_idx = 6 if (idx % 2 == 0) else 7

        v_in_a = bm.verts.new((mount_x + 0.08, sy0, z_mount))
        v_in_b = bm.verts.new((mount_x + 0.08, sy1, z_mount))
        v_out_a = bm.verts.new((mount_x + awning_reach, sy0, z_mount - drop_z))
        v_out_b = bm.verts.new((mount_x + awning_reach, sy1, z_mount - drop_z))

        f = bm.faces.new((v_in_a, v_out_a, v_out_b, v_in_b))
        f.material_index = mat_idx
        f.smooth = False

    # Support legs down to ground
    for leg_y in (y_center - awning_length * 0.45, y_center + awning_length * 0.45):
        _add_oriented_strut(
            bm,
            (mount_x + awning_reach - 0.05, leg_y, z_mount - drop_z),
            (mount_x + awning_reach - 0.05, leg_y, 0.0),
            thickness=0.05,
            mat_index=5,
        )


def _add_cycling_flag(
    bm: bmesh.types.BMesh,
    base_pos: Tuple[float, float, float],
    pole_height: float = 3.2,
    flag_width: float = 1.25,
    flag_height: float = 0.78,
    polka_dot_pattern: bool = False,
) -> None:
    """Adds a tall flexible flagpole with a waving two-tone cycling fan flag."""
    bx, by, bz = base_pos
    _add_tapered_cylinder(
        bm,
        center_xy=(bx, by),
        z_bottom=bz,
        z_top=bz + pole_height,
        radius_bottom=0.032,
        radius_top=0.018,
        segments=8,
        mat_index=5,
        smooth=True,
    )

    # Waving flag grid (4x3 quads)
    cols, rows = 4, 3
    z_top = bz + pole_height - 0.06
    z_bot = z_top - flag_height
    dx = flag_width / cols
    dz = flag_height / rows

    grid: List[List[bmesh.types.BMVert]] = []
    for r in range(rows + 1):
        row_verts: List[bmesh.types.BMVert] = []
        fz = z_bot + r * dz
        for c in range(cols + 1):
            fx = bx + c * dx
            wave_y = by + 0.10 * math.sin((c / cols) * math.pi * 1.6) * (c / cols)
            row_verts.append(bm.verts.new((fx, wave_y, fz)))
        grid.append(row_verts)

    for r in range(rows):
        for c in range(cols):
            f = bm.faces.new((grid[r][c], grid[r][c + 1], grid[r + 1][c + 1], grid[r + 1][c]))
            if polka_dot_pattern:
                # Checker/polka-style alternating KOM pattern
                f.material_index = 9 if ((r + c) % 2 == 1) else 8
            else:
                # Bold horizontal cycling jersey band
                f.material_index = 9 if (r == 1) else 8
            f.smooth = True


def generate_stylized_rv_mesh(
    name: str,
    variant: str,
    location: Tuple[float, float, float],
    rotation_z_deg: float = 0.0,
) -> bpy.types.Object:
    """
    Generates one of 3 stylized cycling fan RVs with awning and cycling flag:
      - 'classic_alcove': Classic over-cab motorhome + KOM polka-dot flag
      - 'sprinter_camper': Compact European campervan + Maillot Jaune flag
      - 'expedition_aclass': Sleek A-Class integrated RV + Green Sprinter flag
    """
    mesh = bpy.data.meshes.new(f"{name}_Mesh")
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)

    if variant == "classic_alcove":
        mats = create_rv_materials(
            prefix="RV1",
            body_hex="#F4F3EE",
            stripe_hex="#8E4A49",
            awning_a_hex="#8E4A49",
            awning_b_hex="#F3F4F6",
            flag_primary_hex="#F8FAFC",
            flag_secondary_hex="#DC2626",
        )
    elif variant == "sprinter_camper":
        mats = create_rv_materials(
            prefix="RV2",
            body_hex="#1E40AF",
            stripe_hex="#D4AF37",
            awning_a_hex="#D4AF37",
            awning_b_hex="#1E293B",
            flag_primary_hex="#FACC15",
            flag_secondary_hex="#111827",
        )
    else:
        mats = create_rv_materials(
            prefix="RV3",
            body_hex="#374151",
            stripe_hex="#10B981",
            awning_a_hex="#10B981",
            awning_b_hex="#E5E7EB",
            flag_primary_hex="#10B981",
            flag_secondary_hex="#F3F4F6",
        )

    for mat in mats:
        obj.data.materials.append(mat)

    bm = bmesh.new()

    if variant == "classic_alcove":
        # Chassis & bumpers
        _add_box(bm, center=(0.0, 0.0, 0.42), size=(2.20, 6.20, 0.24), mat_index=2)
        # Main habitation box
        _add_box(bm, center=(0.0, -0.55, 1.65), size=(2.24, 4.75, 2.22), mat_index=0)
        # Over-cab alcove sleeper overhang
        _add_box(bm, center=(0.0, 2.05, 2.38), size=(2.18, 1.35, 0.76), mat_index=0)
        # Cab hood & cabin
        _add_box(bm, center=(0.0, 2.35, 1.05), size=(2.02, 1.35, 1.05), mat_index=0)
        _add_box(bm, center=(0.0, 2.55, 1.52), size=(1.94, 0.42, 0.65), mat_index=3)  # Windshield
        # Livery stripe along both sides
        _add_box(bm, center=(0.0, -0.55, 1.25), size=(2.28, 4.76, 0.34), mat_index=1)
        # Side habitation windows
        _add_box(bm, center=(-1.13, -0.20, 1.85), size=(0.04, 1.40, 0.62), mat_index=3)
        _add_box(bm, center=(1.13, -0.80, 1.85), size=(0.04, 1.25, 0.62), mat_index=3)
        # Roof AC unit
        _add_box(bm, center=(0.0, -0.8, 2.88), size=(0.88, 1.05, 0.24), mat_index=5)
        # Headlights
        _add_box(bm, center=(-0.72, 3.04, 0.78), size=(0.34, 0.05, 0.18), mat_index=10)
        _add_box(bm, center=(0.72, 3.04, 0.78), size=(0.34, 0.05, 0.18), mat_index=10)

        _add_rv_wheels(bm, half_track_x=1.02, wheel_ys=[-1.75, 2.05], radius=0.38)
        _add_rv_awning(bm, mount_x=1.12, y_center=-0.45, z_mount=2.45, awning_length=3.4, awning_reach=1.85, drop_z=0.35)
        _add_cycling_flag(bm, base_pos=(-1.05, -2.85, 2.75), pole_height=2.8, polka_dot_pattern=True)

    elif variant == "sprinter_camper":
        # Compact high-roof European campervan
        _add_box(bm, center=(0.0, 0.0, 0.38), size=(1.98, 5.45, 0.22), mat_index=2)
        _add_box(bm, center=(0.0, -0.25, 1.42), size=(2.02, 4.70, 1.86), mat_index=0)
        # High-roof aerodynamic cap
        _add_box(bm, center=(0.0, -0.35, 2.48), size=(1.86, 4.25, 0.34), mat_index=0)
        # Front cab nose
        _add_box(bm, center=(0.0, 2.38, 0.96), size=(1.92, 0.85, 0.94), mat_index=0)
        _add_box(bm, center=(0.0, 2.15, 1.62), size=(1.88, 0.35, 0.68), mat_index=3)  # Windshield
        # Gold livery stripe
        _add_box(bm, center=(0.0, -0.25, 1.05), size=(2.06, 4.72, 0.26), mat_index=1)
        # Side windows
        _add_box(bm, center=(-1.02, 0.35, 1.68), size=(0.04, 1.35, 0.56), mat_index=3)
        _add_box(bm, center=(1.02, 0.35, 1.68), size=(0.04, 1.35, 0.56), mat_index=3)
        # Roof cargo box
        _add_box(bm, center=(-0.32, -0.60, 2.78), size=(0.78, 1.85, 0.28), mat_index=2)
        # Headlights
        _add_box(bm, center=(-0.68, 2.82, 0.72), size=(0.30, 0.05, 0.16), mat_index=10)
        _add_box(bm, center=(0.68, 2.82, 0.72), size=(0.30, 0.05, 0.16), mat_index=10)

        _add_rv_wheels(bm, half_track_x=0.94, wheel_ys=[-1.55, 1.85], radius=0.35)
        _add_rv_awning(bm, mount_x=1.01, y_center=-0.25, z_mount=2.22, awning_length=3.1, awning_reach=1.65, drop_z=0.30)
        _add_cycling_flag(bm, base_pos=(-0.92, -2.55, 2.35), pole_height=2.9, polka_dot_pattern=False)

    else:
        # Integrated A-Class Alpine Expedition RV
        _add_box(bm, center=(0.0, 0.0, 0.44), size=(2.28, 6.75, 0.26), mat_index=2)
        _add_box(bm, center=(0.0, 0.0, 1.72), size=(2.32, 6.55, 2.30), mat_index=0)
        # Wide panoramic A-Class windshield
        _add_box(bm, center=(0.0, 3.29, 1.86), size=(2.12, 0.06, 1.15), mat_index=3)
        # Emerald livery stripe
        _add_box(bm, center=(0.0, 0.0, 1.18), size=(2.36, 6.56, 0.32), mat_index=1)
        # Side windows
        _add_box(bm, center=(-1.17, 1.45, 1.88), size=(0.04, 1.55, 0.68), mat_index=3)
        _add_box(bm, center=(-1.17, -1.25, 1.88), size=(0.04, 1.35, 0.68), mat_index=3)
        _add_box(bm, center=(1.17, 1.45, 1.88), size=(0.04, 1.55, 0.68), mat_index=3)
        # Roof solar panels & expedition rack
        _add_box(bm, center=(0.0, 0.2, 2.91), size=(1.65, 2.40, 0.08), mat_index=3)
        # Headlights
        _add_box(bm, center=(-0.78, 3.29, 0.78), size=(0.38, 0.05, 0.18), mat_index=10)
        _add_box(bm, center=(0.78, 3.29, 0.78), size=(0.38, 0.05, 0.18), mat_index=10)

        _add_rv_wheels(bm, half_track_x=1.06, wheel_ys=[-1.95, 2.15], radius=0.40)
        _add_rv_awning(bm, mount_x=1.16, y_center=-0.30, z_mount=2.55, awning_length=3.8, awning_reach=2.05, drop_z=0.38)
        _add_cycling_flag(bm, base_pos=(-1.08, -3.20, 2.86), pole_height=2.9, polka_dot_pattern=False)

    bm.to_mesh(mesh)
    bm.free()

    obj.location = location
    obj.rotation_euler = (0.0, 0.0, math.radians(rotation_z_deg))
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


def export_alpine_summit_pack(
    output_dir: str = "assets/3d/environment",
) -> Dict[str, str]:
    """
    Generates and exports the complete Hors Categorie Alpine Summit Pack
    into `assets/3d/environment/alpine_summit_pack.glb`.
    """
    for obj in list(bpy.context.scene.objects):
        if obj.type == "MESH":
            bpy.data.objects.remove(obj, do_unlink=True)

    os.makedirs(output_dir, exist_ok=True)

    observatory_obj = generate_alpine_observatory_mesh(location=(0.0, 18.0, 0.0))
    snow_walls_obj = generate_alpine_snow_walls_mesh(location=(0.0, 0.0, 0.0))
    rv1_obj = generate_stylized_rv_mesh(
        name="Alpine_RV_Camper_01_Classic",
        variant="classic_alcove",
        location=(-13.0, -4.0, 0.0),
        rotation_z_deg=-25.0,
    )
    rv2_obj = generate_stylized_rv_mesh(
        name="Alpine_RV_Camper_02_Sprinter",
        variant="sprinter_camper",
        location=(13.0, -4.0, 0.0),
        rotation_z_deg=25.0,
    )
    rv3_obj = generate_stylized_rv_mesh(
        name="Alpine_RV_Camper_03_Expedition",
        variant="expedition_aclass",
        location=(0.0, -17.0, 0.0),
        rotation_z_deg=90.0,
    )

    pack_objects = [observatory_obj, snow_walls_obj, rv1_obj, rv2_obj, rv3_obj]
    pack_path = os.path.join(output_dir, "alpine_summit_pack.glb")
    exported_path = export_glb(pack_objects, pack_path)

    for obj in pack_objects:
        bpy.data.objects.remove(obj, do_unlink=True)

    return {"alpine_summit_pack": exported_path}


# =============================================================================
# CLI EXECUTION ENTRY POINT
# =============================================================================

if __name__ == "__main__":
    out_dir = "assets/3d/environment"
    for idx, arg in enumerate(sys.argv):
        if arg in ["--output-dir", "-o"] and idx + 1 < len(sys.argv):
            out_dir = sys.argv[idx + 1]

    files = export_alpine_summit_pack(output_dir=out_dir)
    sm.setup_zwift_studio_lighting()
    print(f"[SUCCESS] Alpine Summit 3D scenery pack generated: {files}")
