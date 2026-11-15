"""
===============================================================================
PRO PELOTON MANAGER - POST-STAGE PODIUM & PRESTIGIOUS TROPHIES GENERATOR
===============================================================================
Blender 5.3 Python API (bpy) script that procedurally models:

  1. Post-Stage Ceremony Podium Scene (`assets/3d/environment/podium_stage.glb`):
     - Three-tier championship podium (1st center, 2nd left, 3rd right) on an
       elevated stage deck with burgundy carpet (#8E4A49), graphite steel frame
       (#181B22), gold championship trim (#D4AF37), and rank pedestals
     - Sponsor backdrop wall with structural ribs, framed media panels,
       header marquee arch, and side branding wings
     - Left and right access staircases with non-slip treads and brushed steel
       handrails
     - Overhead lighting truss gantry with articulated stage spotlights
       (PAR cans + emissive lenses) and floor-mounted uplights

  2. Prestigious Cycling Trophies Pack (`assets/3d/environment/trophies_pack.glb`):
     - Physically-based Gold (`Metallic = 1.0, Roughness = 0.15`), Granite,
       Crystal Glass, and Polished Walnut Wood materials
     - Four distinct cycling trophies:
       1. Cobblestone Monument on Wooden Plinth (`Trophy_Cobble_Monument`)
       2. Grand Tour Golden Cup (`Trophy_Grand_Tour_Cup`)
       3. Golden Infinity Spiral (`Trophy_Infinity_Spiral`)
       4. Tyrrhenian Sea Trident (`Trophy_Tyrrhenian_Trident`)

Usage:
  blender --background --python blender_scripts/generate_podium_and_trophies.py
  blender --background --python blender_scripts/generate_podium_and_trophies.py -- --output-dir assets/3d/environment

Compatible with Blender 3.6 LTS, 4.x, and 5.3+.
===============================================================================
"""

import math
import os
import sys
from typing import Dict, List, Optional, Sequence, Tuple, Union

try:
    import bpy
    import bmesh
    from mathutils import Euler, Matrix, Vector
except ImportError:
    print("[ERROR] 'bpy' / 'mathutils' module not found. Run within Blender:")
    print("        blender --background --python blender_scripts/generate_podium_and_trophies.py")
    sys.exit(1)

script_dir = os.path.dirname(os.path.abspath(__file__))
if script_dir not in sys.path:
    sys.path.insert(0, script_dir)

try:
    import style_and_materials as sm
except ImportError:
    print(f"[ERROR] Could not import 'style_and_materials' from '{script_dir}'.")
    sys.exit(1)


# =============================================================================
# MATERIAL INDICES
# =============================================================================

# Podium stage materials
PMAT_GRAPHITE = 0
PMAT_SURFACE_DARK = 1
PMAT_BURGUNDY = 2
PMAT_GOLD = 3
PMAT_SILVER = 4
PMAT_BRONZE = 5
PMAT_BRUSHED_STEEL = 6
PMAT_BACKDROP_PANEL = 7
PMAT_SPONSOR_ACCENT = 8
PMAT_LED_WHITE = 9
PMAT_LED_GOLD = 10
PMAT_STAGE_CARPET = 11

# Trophy pack materials
TMAT_GOLD = 0          # Metallic = 1.0, Roughness = 0.15
TMAT_GRANITE = 1       # Dark polished/honed granite stone
TMAT_GLASS = 2         # Crystal glass (translucent)
TMAT_WOOD_WALNUT = 3   # Polished dark walnut wood plinth
TMAT_SILVER = 4        # Accent silver / platinum
TMAT_PLAQUE_DARK = 5   # Engraved nameplate backing


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
    alpha: float = 1.0,
    transmission: float = 0.0,
    emission_color: Optional[str] = None,
    emission_strength: float = 0.0,
) -> bpy.types.Material:
    """Creates a Principled BSDF PBR material compatible with Blender 5.3 and glTF 2.0."""
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)

    sm._set_bsdf_socket(bsdf, ["Base Color"], sm.hex_to_linear_rgb(hex_color))
    sm._set_bsdf_socket(bsdf, ["Roughness"], roughness)
    sm._set_bsdf_socket(bsdf, ["Metallic"], metallic)
    sm._set_bsdf_socket(bsdf, ["Specular IOR Level", "Specular"], specular_ior)
    sm._set_bsdf_socket(bsdf, ["IOR"], ior)
    sm._set_bsdf_socket(bsdf, ["Alpha"], alpha)

    if transmission > 0.0:
        sm._set_bsdf_socket(bsdf, ["Transmission Weight", "Transmission"], transmission)

    if alpha < 1.0:
        if hasattr(mat, "blend_method"):
            try:
                mat.blend_method = "BLEND"
            except Exception:
                pass
        if hasattr(mat, "shadow_method"):
            try:
                mat.shadow_method = "NONE"
            except Exception:
                pass

    if emission_color is not None and emission_strength > 0.0:
        sm._set_bsdf_socket(bsdf, ["Emission Color", "Emission"], sm.hex_to_linear_rgb(emission_color))
        sm._set_bsdf_socket(bsdf, ["Emission Strength"], emission_strength)

    return mat


def create_podium_materials() -> List[bpy.types.Material]:
    """Builds the ordered PBR material palette for the post-stage podium scene."""
    return [
        # 0: Dark graphite structural frame (#181B22)
        _make_pbr_material("Mat_Podium_Graphite", "#181B22", roughness=0.40, metallic=0.72),
        # 1: Elevated surface / stage deck (#222630)
        _make_pbr_material("Mat_Podium_Surface_Dark", "#222630", roughness=0.58, metallic=0.15),
        # 2: Burgundy accent & carpet (#8E4A49)
        _make_pbr_material("Mat_Podium_Burgundy", "#8E4A49", roughness=0.38, metallic=0.22),
        # 3: Championship Gold trim & 1st place (#D4AF37)
        _make_pbr_material("Mat_Podium_Gold", "#D4AF37", roughness=0.15, metallic=1.0),
        # 4: 2nd place Silver
        _make_pbr_material("Mat_Podium_Silver", "#CBD5E1", roughness=0.18, metallic=1.0),
        # 5: 3rd place Bronze
        _make_pbr_material("Mat_Podium_Bronze", "#B4723C", roughness=0.22, metallic=0.95),
        # 6: Brushed steel trusses & handrails
        _make_pbr_material("Mat_Podium_Brushed_Steel", "#94A3B8", roughness=0.28, metallic=0.90),
        # 7: Sponsor backdrop matte panel (#0F1115)
        _make_pbr_material("Mat_Podium_Backdrop_Panel", "#0F1115", roughness=0.65, metallic=0.05),
        # 8: Sponsor cyan/blue graphic accent (#38BDF8)
        _make_pbr_material("Mat_Podium_Sponsor_Accent", "#38BDF8", roughness=0.35, metallic=0.10),
        # 9: Spotlight white LED lens
        _make_pbr_material(
            "Mat_Podium_LED_White",
            "#F8FAFC",
            roughness=0.12,
            metallic=0.0,
            emission_color="#F8FAFC",
            emission_strength=6.5,
        ),
        # 10: Warm gold LED strip
        _make_pbr_material(
            "Mat_Podium_LED_Gold",
            "#F59E0B",
            roughness=0.15,
            metallic=0.0,
            emission_color="#F59E0B",
            emission_strength=4.5,
        ),
        # 11: Stage walkway velvet carpet
        _make_pbr_material("Mat_Podium_Stage_Carpet", "#6B2D2C", roughness=0.88, metallic=0.0),
    ]


def create_trophy_materials() -> List[bpy.types.Material]:
    """Builds the ordered PBR material palette for the 4 cycling trophies."""
    return [
        # 0: Championship 24K Gold (Metallic = 1.0, Roughness = 0.15)
        _make_pbr_material(
            "Mat_Trophy_Gold",
            "#D4AF37",
            roughness=0.15,
            metallic=1.0,
            specular_ior=0.65,
        ),
        # 1: Honed Dark Granite Stone
        _make_pbr_material(
            "Mat_Trophy_Granite",
            "#2A2F3D",
            roughness=0.72,
            metallic=0.04,
            specular_ior=0.45,
        ),
        # 2: Crystal Glass
        _make_pbr_material(
            "Mat_Trophy_Glass",
            "#E0F2FE",
            roughness=0.05,
            metallic=0.0,
            specular_ior=0.92,
            ior=1.52,
            alpha=0.38,
            transmission=0.85,
        ),
        # 3: Polished Dark Walnut Wood
        _make_pbr_material(
            "Mat_Trophy_Wood_Walnut",
            "#4A2C18",
            roughness=0.32,
            metallic=0.0,
            specular_ior=0.52,
        ),
        # 4: Polished Platinum / Silver accent
        _make_pbr_material(
            "Mat_Trophy_Silver",
            "#E2E8F0",
            roughness=0.14,
            metallic=1.0,
        ),
        # 5: Dark Plaque Backing
        _make_pbr_material(
            "Mat_Trophy_Plaque_Dark",
            "#111318",
            roughness=0.45,
            metallic=0.25,
        ),
    ]


# =============================================================================
# BMESH GEOMETRY HELPERS
# =============================================================================

def _create_mesh_object(
    name: str,
    materials: Sequence[bpy.types.Material],
) -> Tuple[bpy.types.Object, bpy.types.Mesh, bmesh.types.BMesh]:
    """Creates a linked Blender mesh object with pre-assigned material slots."""
    mesh = bpy.data.meshes.new(name + "_Mesh")
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    for mat in materials:
        obj.data.materials.append(mat)
    return obj, mesh, bmesh.new()


def _assign_verts_mat(verts: Sequence[bmesh.types.BMVert], mat_index: int) -> None:
    """Assigns material index to all faces formed exclusively by the given vertices."""
    vert_set = set(verts)
    visited = set()
    for v in verts:
        for f in v.link_faces:
            if f not in visited and all(fv in vert_set for fv in f.verts):
                f.material_index = mat_index
                visited.add(f)


def _add_box(
    bm: bmesh.types.BMesh,
    center: Tuple[float, float, float],
    size: Tuple[float, float, float],
    mat_index: int,
    rot_euler_rad: Tuple[float, float, float] = (0.0, 0.0, 0.0),
) -> None:
    """Adds an oriented box into the BMesh."""
    rot_mat = Euler(rot_euler_rad, "XYZ").to_matrix().to_4x4()
    scale_mat = Matrix.Diagonal((size[0], size[1], size[2], 1.0))
    xform = Matrix.Translation(center) @ rot_mat @ scale_mat
    ret = bmesh.ops.create_cube(bm, size=1.0, matrix=xform)
    _assign_verts_mat(ret["verts"], mat_index)


def _add_cylinder(
    bm: bmesh.types.BMesh,
    center: Tuple[float, float, float],
    radius_bottom: float,
    radius_top: float,
    depth: float,
    mat_index: int,
    segments: int = 24,
    rot_euler_rad: Tuple[float, float, float] = (0.0, 0.0, 0.0),
) -> None:
    """Adds an oriented cylinder or frustum cone into the BMesh."""
    rot_mat = Euler(rot_euler_rad, "XYZ").to_matrix().to_4x4()
    xform = Matrix.Translation(center) @ rot_mat
    ret = bmesh.ops.create_cone(
        bm,
        cap_ends=True,
        cap_tris=False,
        segments=segments,
        radius1=radius_bottom,
        radius2=radius_top,
        depth=depth,
        matrix=xform,
    )
    _assign_verts_mat(ret["verts"], mat_index)


def _add_sphere(
    bm: bmesh.types.BMesh,
    center: Tuple[float, float, float],
    radius: float,
    mat_index: int,
    u_segments: int = 20,
    v_segments: int = 12,
    scale: Tuple[float, float, float] = (1.0, 1.0, 1.0),
) -> None:
    """Adds a UV sphere into the BMesh."""
    xform = Matrix.Translation(center) @ Matrix.Diagonal((scale[0], scale[1], scale[2], 1.0))
    ret = bmesh.ops.create_uvsphere(
        bm,
        u_segments=u_segments,
        v_segments=v_segments,
        radius=radius,
        matrix=xform,
    )
    _assign_verts_mat(ret["verts"], mat_index)


def _add_lathe_profile(
    bm: bmesh.types.BMesh,
    profile_rz: List[Tuple[float, float]],
    mat_index: int,
    segments: int = 36,
    center: Tuple[float, float, float] = (0.0, 0.0, 0.0),
    cap_bottom: bool = True,
    cap_top: bool = True,
) -> None:
    """Revolves a 2D (radius, z) profile around the Z axis to create cups/pedestals."""
    cx, cy, cz = center
    rings: List[List[bmesh.types.BMVert]] = []

    for r, z in profile_rz:
        ring: List[bmesh.types.BMVert] = []
        for s in range(segments):
            angle = (2.0 * math.pi * s) / segments
            vx = cx + r * math.cos(angle)
            vy = cy + r * math.sin(angle)
            vz = cz + z
            ring.append(bm.verts.new((vx, vy, vz)))
        rings.append(ring)

    new_faces: List[bmesh.types.BMFace] = []
    for i in range(len(rings) - 1):
        r0 = rings[i]
        r1 = rings[i + 1]
        for s in range(segments):
            s_next = (s + 1) % segments
            try:
                f = bm.faces.new((r0[s], r0[s_next], r1[s_next], r1[s]))
                f.material_index = mat_index
                new_faces.append(f)
            except ValueError:
                pass

    if cap_bottom and len(rings) > 0 and profile_rz[0][0] > 1e-4:
        try:
            f = bm.faces.new(list(reversed(rings[0])))
            f.material_index = mat_index
        except ValueError:
            pass

    if cap_top and len(rings) > 0 and profile_rz[-1][0] > 1e-4:
        try:
            f = bm.faces.new(rings[-1])
            f.material_index = mat_index
        except ValueError:
            pass


def _add_swept_tube(
    bm: bmesh.types.BMesh,
    points: List[Tuple[float, float, float]],
    radii: Union[float, List[float]],
    mat_index: int,
    ring_segments: int = 12,
    cap_ends: bool = True,
) -> None:
    """Sweeps a circular cross-section along a 3D polyline."""
    if len(points) < 2:
        return

    if isinstance(radii, (int, float)):
        radii_list = [float(radii)] * len(points)
    else:
        radii_list = radii

    rings: List[List[bmesh.types.BMVert]] = []
    prev_normal = Vector((0.0, 1.0, 0.0))

    for i, pt in enumerate(points):
        p = Vector(pt)
        if i == 0:
            tangent = (Vector(points[1]) - p).normalized()
        elif i == len(points) - 1:
            tangent = (p - Vector(points[i - 1])).normalized()
        else:
            tangent = (Vector(points[i + 1]) - Vector(points[i - 1])).normalized()

        if tangent.length < 1e-6:
            tangent = Vector((0.0, 0.0, 1.0))

        # Parallel transport frame to avoid twisting artifacts
        normal = prev_normal - tangent * prev_normal.dot(tangent)
        if normal.length < 1e-4:
            alt = Vector((1.0, 0.0, 0.0)) if abs(tangent.x) < 0.8 else Vector((0.0, 1.0, 0.0))
            normal = tangent.cross(alt).normalized()
        else:
            normal.normalize()
        binormal = tangent.cross(normal).normalized()
        prev_normal = normal

        r = radii_list[i]
        ring: List[bmesh.types.BMVert] = []
        for s in range(ring_segments):
            ang = (2.0 * math.pi * s) / ring_segments
            offset = (normal * math.cos(ang) + binormal * math.sin(ang)) * r
            ring.append(bm.verts.new(p + offset))
        rings.append(ring)

    for i in range(len(rings) - 1):
        r0 = rings[i]
        r1 = rings[i + 1]
        for s in range(ring_segments):
            s_next = (s + 1) % ring_segments
            try:
                f = bm.faces.new((r0[s], r0[s_next], r1[s_next], r1[s]))
                f.material_index = mat_index
            except ValueError:
                pass

    if cap_ends:
        try:
            f0 = bm.faces.new(list(reversed(rings[0])))
            f0.material_index = mat_index
        except ValueError:
            pass
        try:
            f1 = bm.faces.new(rings[-1])
            f1.material_index = mat_index
        except ValueError:
            pass


def _add_swept_ribbon(
    bm: bmesh.types.BMesh,
    points: List[Vector],
    widths: List[float],
    thicknesses: List[float],
    mat_index: int,
) -> None:
    """Sweeps a rectangular beveled ribbon along a 3D curve (used for Infinity Spiral)."""
    if len(points) < 2:
        return

    rings: List[List[bmesh.types.BMVert]] = []
    up_ref = Vector((0.0, 0.0, 1.0))

    for i, p in enumerate(points):
        if i == 0:
            tangent = (points[1] - p).normalized()
        elif i == len(points) - 1:
            tangent = (p - points[i - 1]).normalized()
        else:
            tangent = (points[i + 1] - points[i - 1]).normalized()

        radial = Vector((p.x, p.y, 0.0))
        if radial.length < 1e-4:
            radial = Vector((1.0, 0.0, 0.0))
        else:
            radial.normalize()

        side = tangent.cross(radial).normalized()
        if side.length < 1e-4:
            side = up_ref

        hw = widths[i] * 0.5
        ht = thicknesses[i] * 0.5

        # 4 corners of rectangular cross-section
        corners = [
            p + radial * ht + side * hw,
            p - radial * ht + side * hw,
            p - radial * ht - side * hw,
            p + radial * ht - side * hw,
        ]
        rings.append([bm.verts.new(c) for c in corners])

    for i in range(len(rings) - 1):
        r0 = rings[i]
        r1 = rings[i + 1]
        for s in range(4):
            s_next = (s + 1) % 4
            try:
                f = bm.faces.new((r0[s], r0[s_next], r1[s_next], r1[s]))
                f.material_index = mat_index
            except ValueError:
                pass

    try:
        f0 = bm.faces.new(list(reversed(rings[0])))
        f0.material_index = mat_index
        f1 = bm.faces.new(rings[-1])
        f1.material_index = mat_index
    except ValueError:
        pass


def _finalize_mesh_object(
    obj: bpy.types.Object,
    mesh: bpy.types.Mesh,
    bm: bmesh.types.BMesh,
    location: Tuple[float, float, float] = (0.0, 0.0, 0.0),
    auto_smooth_deg: float = 35.0,
) -> bpy.types.Object:
    """Recalculates normals, commits BMesh, cleans and applies Zwift shading style."""
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()

    obj.location = location
    sm.clean_zwift_mesh(obj, merge_distance=0.0003)
    sm.apply_zwift_style(obj, auto_smooth_angle_deg=auto_smooth_deg)
    return obj


# =============================================================================
# PART 1: POST-STAGE PODIUM SCENE (`podium_stage.glb`)
# =============================================================================

STAGE_DECK_Z = 0.45
STAGE_WIDTH = 7.40
STAGE_DEPTH = 3.60


def _build_podium_tiers_and_deck(bm: bmesh.types.BMesh) -> None:
    """Builds the main elevated stage deck, carpet, and 3-tier championship podium."""
    # Main stage deck base (Z = 0.0 to 0.45m)
    _add_box(bm, (0.0, 0.0, STAGE_DECK_Z * 0.5), (STAGE_WIDTH, STAGE_DEPTH, STAGE_DECK_Z), PMAT_GRAPHITE)
    # Top composite surface slab
    _add_box(bm, (0.0, 0.0, STAGE_DECK_Z - 0.02), (STAGE_WIDTH + 0.08, STAGE_DEPTH + 0.08, 0.04), PMAT_SURFACE_DARK)
    # Gold front fascia trim along stage edge
    _add_box(bm, (0.0, -STAGE_DEPTH * 0.5 - 0.045, STAGE_DECK_Z - 0.04), (STAGE_WIDTH + 0.10, 0.03, 0.06), PMAT_GOLD)
    # Burgundy carpet runner on stage front
    _add_box(bm, (0.0, -0.65, STAGE_DECK_Z + 0.006), (5.60, 1.90, 0.012), PMAT_STAGE_CARPET)

    # Three-tier podium blocks: (rank, center_x, width, depth, height, accent_mat)
    tiers = [
        (1, 0.0, 1.45, 1.15, 0.72, PMAT_GOLD),
        (2, -1.48, 1.35, 1.08, 0.48, PMAT_SILVER),
        (3, 1.48, 1.35, 1.08, 0.32, PMAT_BRONZE),
    ]
    podium_y = -0.15

    for rank, cx, w, d, h, accent_mat in tiers:
        # Main pedestal body
        _add_box(bm, (cx, podium_y, STAGE_DECK_Z + h * 0.5), (w, d, h), PMAT_GRAPHITE)
        # Top anti-slip platform cap
        _add_box(bm, (cx, podium_y, STAGE_DECK_Z + h + 0.015), (w + 0.04, d + 0.04, 0.03), PMAT_SURFACE_DARK)
        # Metallic championship trim ring around top edge
        _add_box(bm, (cx, podium_y - d * 0.5 - 0.015, STAGE_DECK_Z + h - 0.03), (w + 0.06, 0.025, 0.05), accent_mat)
        # Front rank medallion / plaque
        plaque_z = STAGE_DECK_Z + h * 0.52
        _add_box(bm, (cx, podium_y - d * 0.5 - 0.015, plaque_z), (0.42, 0.025, 0.28), PMAT_BACKDROP_PANEL)
        _add_box(bm, (cx, podium_y - d * 0.5 - 0.025, plaque_z), (0.36, 0.015, 0.22), accent_mat)

        # Rank numeral bars ("1", "2", "3" stylized geometric bars)
        bar_y = podium_y - d * 0.5 - 0.035
        if rank == 1:
            _add_box(bm, (cx, bar_y, plaque_z), (0.045, 0.018, 0.14), PMAT_GRAPHITE)
        elif rank == 2:
            _add_box(bm, (cx - 0.045, bar_y, plaque_z), (0.035, 0.018, 0.14), PMAT_GRAPHITE)
            _add_box(bm, (cx + 0.045, bar_y, plaque_z), (0.035, 0.018, 0.14), PMAT_GRAPHITE)
        else:
            for ox in (-0.075, 0.0, 0.075):
                _add_box(bm, (cx + ox, bar_y, plaque_z), (0.03, 0.018, 0.14), PMAT_GRAPHITE)

    # Trophy display plinths flanking the podium on the stage
    for tx in (-2.65, 2.65):
        _add_cylinder(bm, (tx, -0.55, STAGE_DECK_Z + 0.45), 0.24, 0.20, 0.90, PMAT_GRAPHITE, segments=24)
        _add_cylinder(bm, (tx, -0.55, STAGE_DECK_Z + 0.91), 0.25, 0.25, 0.03, PMAT_GOLD, segments=24)


def _build_sponsor_backdrop(bm: bmesh.types.BMesh) -> None:
    """Builds the architectural sponsor backdrop wall behind the podium."""
    wall_y = 0.85
    wall_h = 3.15
    wall_w = 6.20

    # Main backdrop backing wall
    _add_box(bm, (0.0, wall_y, STAGE_DECK_Z + wall_h * 0.5), (wall_w, 0.14, wall_h), PMAT_BACKDROP_PANEL)

    # Outer structural graphite frame
    _add_box(bm, (0.0, wall_y - 0.02, STAGE_DECK_Z + wall_h + 0.10), (wall_w + 0.30, 0.22, 0.20), PMAT_GRAPHITE)
    for sx in (-wall_w * 0.5 - 0.08, wall_w * 0.5 + 0.08):
        _add_box(bm, (sx, wall_y - 0.02, STAGE_DECK_Z + wall_h * 0.5), (0.16, 0.22, wall_h + 0.20), PMAT_GRAPHITE)

    # Angled side branding wings (20 degrees inward)
    for side_sign in (-1.0, 1.0):
        wing_x = side_sign * (wall_w * 0.5 + 0.58)
        wing_y = wall_y - 0.22
        rot_z = -side_sign * math.radians(22.0)
        _add_box(bm, (wing_x, wing_y, STAGE_DECK_Z + wall_h * 0.48), (1.05, 0.12, wall_h * 0.96), PMAT_GRAPHITE, (0.0, 0.0, rot_z))
        _add_box(bm, (wing_x, wing_y - 0.05, STAGE_DECK_Z + wall_h * 0.48), (0.85, 0.03, wall_h * 0.82), PMAT_BURGUNDY, (0.0, 0.0, rot_z))

    # Vertical architectural sponsor divider ribs
    for rx in (-2.05, -0.95, 0.95, 2.05):
        _add_box(bm, (rx, wall_y - 0.08, STAGE_DECK_Z + wall_h * 0.5), (0.08, 0.06, wall_h - 0.12), PMAT_GRAPHITE)

    # Horizontal burgundy & cyan sponsor logo bars across backdrop grid
    for row_z in (STAGE_DECK_Z + 1.05, STAGE_DECK_Z + 1.75, STAGE_DECK_Z + 2.45):
        _add_box(bm, (0.0, wall_y - 0.075, row_z), (wall_w - 0.30, 0.02, 0.34), PMAT_SURFACE_DARK)
        # Alternating sponsor brand blocks
        for bx, mat_i in ((-2.50, PMAT_BURGUNDY), (-1.50, PMAT_SPONSOR_ACCENT), (0.0, PMAT_GOLD), (1.50, PMAT_SPONSOR_ACCENT), (2.50, PMAT_BURGUNDY)):
            _add_box(bm, (bx, wall_y - 0.09, row_z), (0.72, 0.02, 0.16), mat_i)

    # Top header marquee crown with LED accent strip
    _add_box(bm, (0.0, wall_y - 0.14, STAGE_DECK_Z + wall_h + 0.12), (4.60, 0.18, 0.32), PMAT_BURGUNDY)
    _add_box(bm, (0.0, wall_y - 0.24, STAGE_DECK_Z + wall_h + 0.12), (4.20, 0.03, 0.06), PMAT_LED_GOLD)


def _build_access_stairs(bm: bmesh.types.BMesh) -> None:
    """Builds left and right stage access staircases with brushed steel handrails."""
    num_steps = 3
    step_rise = STAGE_DECK_Z / num_steps
    step_run = 0.34
    stair_width = 1.15

    for side_sign in (-1.0, 1.0):
        # Stairs attach to left/right sides of stage deck (X = +-STAGE_WIDTH/2)
        base_x = side_sign * (STAGE_WIDTH * 0.5)
        stair_y = -0.55

        for i in range(num_steps):
            # Step i goes outward from stage
            step_h = STAGE_DECK_Z - i * step_rise
            step_cx = base_x + side_sign * ((i + 0.5) * step_run)
            _add_box(bm, (step_cx, stair_y, step_h * 0.5), (step_run, stair_width, step_h), PMAT_GRAPHITE)
            # Non-slip burgundy tread top
            _add_box(bm, (step_cx, stair_y, step_h + 0.01), (step_run - 0.02, stair_width - 0.06, 0.02), PMAT_BURGUNDY)

        # Brushed steel handrails on both sides of each staircase
        for rail_y_off in (-stair_width * 0.46, stair_width * 0.46):
            ry = stair_y + rail_y_off
            top_x = base_x + side_sign * 0.08
            bot_x = base_x + side_sign * (num_steps * step_run - 0.08)
            top_z = STAGE_DECK_Z + 0.85
            bot_z = step_rise + 0.85

            # Vertical stanchions
            _add_cylinder(bm, (top_x, ry, STAGE_DECK_Z + 0.425), 0.022, 0.022, 0.85, PMAT_BRUSHED_STEEL, segments=12)
            _add_cylinder(bm, (bot_x, ry, step_rise + 0.425), 0.022, 0.022, 0.85, PMAT_BRUSHED_STEEL, segments=12)

            # Sloped top rail
            _add_swept_tube(
                bm,
                [(top_x, ry, top_z), (bot_x, ry, bot_z)],
                radii=0.024,
                mat_index=PMAT_BRUSHED_STEEL,
                ring_segments=12,
            )


def _build_stage_spotlights(bm: bmesh.types.BMesh) -> None:
    """Builds the overhead lighting truss gantry, PAR spotlights, and floor uplights."""
    truss_z = STAGE_DECK_Z + 3.65
    truss_y = -1.25
    truss_span = 6.60

    # Vertical truss towers at left & right front corners of stage
    for tx in (-truss_span * 0.5, truss_span * 0.5):
        # Base plate
        _add_box(bm, (tx, truss_y, STAGE_DECK_Z + 0.02), (0.42, 0.42, 0.04), PMAT_GRAPHITE)
        # 4-chord truss column
        for cx_off in (-0.11, 0.11):
            for cy_off in (-0.11, 0.11):
                _add_cylinder(bm, (tx + cx_off, truss_y + cy_off, (STAGE_DECK_Z + truss_z) * 0.5), 0.018, 0.018, truss_z - STAGE_DECK_Z, PMAT_BRUSHED_STEEL, segments=10)
        # Horizontal truss collar rings
        for rz in (STAGE_DECK_Z + 0.8, STAGE_DECK_Z + 1.6, STAGE_DECK_Z + 2.4, STAGE_DECK_Z + 3.2):
            _add_box(bm, (tx, truss_y, rz), (0.26, 0.26, 0.03), PMAT_BRUSHED_STEEL)

    # Overhead horizontal lighting truss beam
    for cz_off in (-0.11, 0.11):
        for cy_off in (-0.11, 0.11):
            _add_cylinder(
                bm,
                (0.0, truss_y + cy_off, truss_z + cz_off),
                0.020,
                0.020,
                truss_span + 0.24,
                PMAT_BRUSHED_STEEL,
                segments=10,
                rot_euler_rad=(0.0, math.pi * 0.5, 0.0),
            )
    # Cross braces along overhead truss
    for bx in (-2.8, -2.0, -1.2, -0.4, 0.4, 1.2, 2.0, 2.8):
        _add_box(bm, (bx, truss_y, truss_z), (0.03, 0.26, 0.26), PMAT_BRUSHED_STEEL)

    # 6 Articulated Stage Spotlights hanging from the overhead truss aimed at podium
    spot_positions = (-2.4, -1.45, -0.5, 0.5, 1.45, 2.4)
    for sx in spot_positions:
        # Mounting clamp & yoke
        _add_box(bm, (sx, truss_y, truss_z - 0.16), (0.06, 0.06, 0.14), PMAT_GRAPHITE)
        # PAR can housing tilted downward toward podium (pitch ~38 deg)
        tilt_x = math.radians(52.0)
        can_pos = (sx, truss_y + 0.05, truss_z - 0.30)
        _add_cylinder(
            bm,
            can_pos,
            0.095,
            0.125,
            0.28,
            PMAT_GRAPHITE,
            segments=18,
            rot_euler_rad=(tilt_x, 0.0, 0.0),
        )
        # Gold bezel ring & emissive LED lens at front of PAR can
        dir_y = math.sin(tilt_x)
        dir_z = -math.cos(tilt_x)
        lens_pos = (can_pos[0], can_pos[1] + dir_y * 0.145, can_pos[2] + dir_z * 0.145)
        _add_cylinder(
            bm,
            lens_pos,
            0.115,
            0.115,
            0.025,
            PMAT_LED_WHITE,
            segments=18,
            rot_euler_rad=(tilt_x, 0.0, 0.0),
        )

    # 4 Floor-mounted uplights along stage front edge aiming up at sponsor wall
    for ux in (-2.2, -0.8, 0.8, 2.2):
        uy = -1.45
        _add_box(bm, (ux, uy, STAGE_DECK_Z + 0.05), (0.20, 0.16, 0.10), PMAT_GRAPHITE)
        _add_cylinder(
            bm,
            (ux, uy + 0.02, STAGE_DECK_Z + 0.12),
            0.065,
            0.075,
            0.12,
            PMAT_GRAPHITE,
            segments=14,
            rot_euler_rad=(math.radians(-28.0), 0.0, 0.0),
        )
        _add_cylinder(
            bm,
            (ux, uy + 0.05, STAGE_DECK_Z + 0.17),
            0.062,
            0.062,
            0.015,
            PMAT_LED_GOLD,
            segments=14,
            rot_euler_rad=(math.radians(-28.0), 0.0, 0.0),
        )


def generate_podium_stage_objects() -> List[bpy.types.Object]:
    """Generates the complete post-stage podium scene objects."""
    materials = create_podium_materials()
    objects: List[bpy.types.Object] = []

    builders = [
        ("Podium_Stage_Main", _build_podium_tiers_and_deck),
        ("Podium_Sponsor_Backdrop", _build_sponsor_backdrop),
        ("Podium_Access_Stairs", _build_access_stairs),
        ("Podium_Stage_Spotlights", _build_stage_spotlights),
    ]

    for obj_name, builder_fn in builders:
        obj, mesh, bm = _create_mesh_object(obj_name, materials)
        builder_fn(bm)
        _finalize_mesh_object(obj, mesh, bm, location=(0.0, 0.0, 0.0))
        objects.append(obj)

    return objects


# =============================================================================
# PART 2: PRESTIGIOUS CYCLING TROPHIES (`trophies_pack.glb`)
# =============================================================================

def _build_cobble_monument_trophy(bm: bmesh.types.BMesh) -> None:
    """
    Trophy 1: Kostka Bruku na drewnianym postumencie (Paris-Roubaix inspired).
    - Stepped polished walnut wood plinth with gold corner trim & plaque
    - Golden cradle pedestal
    - Faceted granite cobblestone block with gold inlay band
    """
    # Stepped wooden plinth (Z = 0.0 to 0.15m)
    _add_box(bm, (0.0, 0.0, 0.025), (0.34, 0.34, 0.05), TMAT_WOOD_WALNUT)
    _add_box(bm, (0.0, 0.0, 0.080), (0.28, 0.28, 0.06), TMAT_WOOD_WALNUT)
    _add_box(bm, (0.0, 0.0, 0.125), (0.24, 0.24, 0.03), TMAT_GOLD)

    # Engraved front brass/gold nameplate
    _add_box(bm, (0.0, -0.145, 0.075), (0.17, 0.015, 0.042), TMAT_PLAQUE_DARK)
    _add_box(bm, (0.0, -0.151, 0.075), (0.15, 0.008, 0.032), TMAT_GOLD)

    # Golden cradle prongs supporting the cobblestone
    _add_cylinder(bm, (0.0, 0.0, 0.155), 0.085, 0.105, 0.03, TMAT_GOLD, segments=24)

    # Granite cobblestone block (slightly tilted/organic faceted stone)
    cobble_z = 0.265
    _add_box(bm, (0.0, 0.0, cobble_z), (0.175, 0.145, 0.19), TMAT_GRANITE, rot_euler_rad=(0.03, -0.02, 0.04))
    # Faceted crown cap on top of cobblestone for realistic hand-hewn stone silhouette
    _add_cylinder(
        bm,
        (0.0, 0.0, cobble_z + 0.102),
        0.095,
        0.068,
        0.028,
        TMAT_GRANITE,
        segments=8,
        rot_euler_rad=(0.03, -0.02, math.radians(22.5)),
    )
    # Gold commemorative collar band around cobblestone waist
    _add_box(bm, (0.0, 0.0, cobble_z - 0.055), (0.182, 0.152, 0.016), TMAT_GOLD, rot_euler_rad=(0.03, -0.02, 0.04))


def _build_grand_tour_cup_trophy(bm: bmesh.types.BMesh) -> None:
    """
    Trophy 2: Złoty Puchar Wielkiego Touru (Classic Grand Tour Chalice).
    - Granite & gold stepped circular base
    - Lathe-revolved 24k gold chalice body with flared rim
    - Twin sculpted S-curve handles & crystal glass collar accent
    """
    # Stepped granite base
    _add_cylinder(bm, (0.0, 0.0, 0.030), 0.145, 0.135, 0.060, TMAT_GRANITE, segments=32)
    _add_cylinder(bm, (0.0, 0.0, 0.080), 0.115, 0.105, 0.040, TMAT_GRANITE, segments=32)
    _add_box(bm, (0.0, -0.112, 0.045), (0.12, 0.016, 0.035), TMAT_GOLD)

    # Crystal glass decorative ring at stem base
    _add_cylinder(bm, (0.0, 0.0, 0.112), 0.092, 0.085, 0.024, TMAT_GLASS, segments=32)

    # Lathed golden stem & chalice bowl (Z = 0.124m to 0.52m)
    cup_profile = [
        (0.088, 0.124),
        (0.060, 0.145),
        (0.034, 0.185),
        (0.046, 0.220),  # decorative knop
        (0.032, 0.255),
        (0.055, 0.285),  # cup bottom flare
        (0.110, 0.340),
        (0.138, 0.420),
        (0.155, 0.485),
        (0.168, 0.515),  # flared lip
        (0.156, 0.520),  # inner rim
        (0.125, 0.450),
        (0.085, 0.350),
        (0.020, 0.300),
    ]
    _add_lathe_profile(bm, cup_profile, TMAT_GOLD, segments=40)

    # Twin sculpted S-curve golden handles
    for side in (-1.0, 1.0):
        handle_pts: List[Tuple[float, float, float]] = []
        steps = 16
        for i in range(steps + 1):
            t = i / steps
            # Smooth S-curve from cup waist (r=0.095, z=0.32) to upper rim (r=0.152, z=0.49)
            z = 0.32 + t * 0.17
            r = 0.12 + 0.095 * math.sin(t * math.pi) + 0.035 * t
            handle_pts.append((side * r, 0.0, z))
        _add_swept_tube(bm, handle_pts, radii=0.014, mat_index=TMAT_GOLD, ring_segments=12)


def _build_infinity_spiral_trophy(bm: bmesh.types.BMesh) -> None:
    """
    Trophy 3: Złota Spirala Nieskończoności (Giro d'Italia Trofeo Senza Fine inspired).
    - Granite & crystal glass cylindrical pedestal
    - Central crystal glass core column
    - Continuous rising golden helical infinity ribbon (2.5 full turns)
    """
    # Granite & gold stepped cylinder base
    _add_cylinder(bm, (0.0, 0.0, 0.035), 0.145, 0.140, 0.070, TMAT_GRANITE, segments=36)
    _add_cylinder(bm, (0.0, 0.0, 0.080), 0.125, 0.125, 0.020, TMAT_GOLD, segments=36)
    _add_cylinder(bm, (0.0, 0.0, 0.105), 0.115, 0.110, 0.030, TMAT_GRANITE, segments=36)
    _add_box(bm, (0.0, -0.140, 0.035), (0.11, 0.016, 0.032), TMAT_GOLD)

    # Inner crystal glass core column
    _add_cylinder(bm, (0.0, 0.0, 0.285), 0.036, 0.024, 0.33, TMAT_GLASS, segments=28)

    # Rising golden spiral ribbon
    spiral_pts: List[Vector] = []
    widths: List[float] = []
    thicknesses: List[float] = []

    num_samples = 96
    total_turns = 2.4
    z_start = 0.125
    z_end = 0.540

    for i in range(num_samples):
        t = i / (num_samples - 1)
        angle = t * total_turns * 2.0 * math.pi
        # Radius expands gracefully upward like a sculpted ribbon
        radius = 0.048 + 0.088 * (t ** 1.15)
        z = z_start + t * (z_end - z_start)
        spiral_pts.append(Vector((radius * math.cos(angle), radius * math.sin(angle), z)))
        widths.append(0.024 + 0.018 * math.sin(t * math.pi))
        thicknesses.append(0.010 + 0.004 * (1.0 - t))

    _add_swept_ribbon(bm, spiral_pts, widths, thicknesses, TMAT_GOLD)

    # Golden finial sphere crowning the top of the crystal core
    _add_sphere(bm, (0.0, 0.0, 0.465), radius=0.022, mat_index=TMAT_GOLD)


def _build_tyrrhenian_trident_trophy(bm: bmesh.types.BMesh) -> None:
    """
    Trophy 4: Trójząb Morza Tyrreńskiego (Tirreno-Adriatico Sea Trident inspired).
    - Layered wave-profile granite & crystal glass base
    - Ornate golden shaft with collar rings
    - Central spearhead prong & twin curved lateral trident tines
    """
    # Granite stepped base + translucent crystal sea-wave block
    _add_cylinder(bm, (0.0, 0.0, 0.030), 0.150, 0.142, 0.060, TMAT_GRANITE, segments=32)
    _add_cylinder(bm, (0.0, 0.0, 0.082), 0.118, 0.108, 0.044, TMAT_GLASS, segments=32)
    _add_cylinder(bm, (0.0, 0.0, 0.114), 0.088, 0.072, 0.022, TMAT_GOLD, segments=28)
    _add_box(bm, (0.0, -0.145, 0.030), (0.12, 0.016, 0.030), TMAT_GOLD)

    # Vertical golden trident shaft
    _add_cylinder(bm, (0.0, 0.0, 0.245), 0.022, 0.018, 0.250, TMAT_GOLD, segments=20)
    # Decorative shaft collar rings
    for cz in (0.175, 0.285, 0.365):
        _add_cylinder(bm, (0.0, 0.0, cz), 0.032, 0.032, 0.016, TMAT_GOLD, segments=24)

    # Trident crossbar crown at Z = 0.375m
    _add_box(bm, (0.0, 0.0, 0.375), (0.21, 0.026, 0.024), TMAT_GOLD)

    # Central spear prong (tallest)
    _add_cylinder(bm, (0.0, 0.0, 0.460), 0.016, 0.012, 0.165, TMAT_GOLD, segments=16)
    _add_cylinder(bm, (0.0, 0.0, 0.568), 0.026, 0.002, 0.056, TMAT_GOLD, segments=16)

    # Twin curved lateral trident tines
    for side in (-1.0, 1.0):
        tine_pts = [
            (side * 0.020, 0.0, 0.375),
            (side * 0.082, 0.0, 0.382),
            (side * 0.116, 0.0, 0.425),
            (side * 0.118, 0.0, 0.495),
            (side * 0.104, 0.0, 0.535),
        ]
        _add_swept_tube(bm, tine_pts, radii=[0.015, 0.014, 0.013, 0.011, 0.008], mat_index=TMAT_GOLD, ring_segments=14)
        # Spearhead tip on each lateral tine
        _add_cylinder(
            bm,
            (side * 0.098, 0.0, 0.550),
            0.019,
            0.002,
            0.044,
            TMAT_GOLD,
            segments=14,
            rot_euler_rad=(0.0, side * math.radians(15.0), 0.0),
        )


def generate_trophies_pack_objects() -> List[bpy.types.Object]:
    """Generates the 4 prestigious cycling trophy objects spaced cleanly along X."""
    materials = create_trophy_materials()
    objects: List[bpy.types.Object] = []

    trophy_specs = [
        ("Trophy_Cobble_Monument", _build_cobble_monument_trophy, (-1.35, 0.0, 0.0)),
        ("Trophy_Grand_Tour_Cup", _build_grand_tour_cup_trophy, (-0.45, 0.0, 0.0)),
        ("Trophy_Infinity_Spiral", _build_infinity_spiral_trophy, (0.45, 0.0, 0.0)),
        ("Trophy_Tyrrhenian_Trident", _build_tyrrhenian_trident_trophy, (1.35, 0.0, 0.0)),
    ]

    for obj_name, builder_fn, loc in trophy_specs:
        obj, mesh, bm = _create_mesh_object(obj_name, materials)
        builder_fn(bm)
        _finalize_mesh_object(obj, mesh, bm, location=loc)
        objects.append(obj)

    return objects


# =============================================================================
# GLB EXPORT & CLI ENTRYPOINT
# =============================================================================

def _clear_scene_meshes() -> None:
    """Removes all mesh objects from the current Blender scene."""
    for obj in list(bpy.context.scene.objects):
        if obj.type == "MESH":
            bpy.data.objects.remove(obj, do_unlink=True)


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


def export_podium_and_trophies(
    output_dir: str = "assets/3d/environment",
) -> Dict[str, str]:
    """Generates and exports both `podium_stage.glb` and `trophies_pack.glb`."""
    os.makedirs(output_dir, exist_ok=True)
    exported: Dict[str, str] = {}

    # 1. Post-stage podium scene
    _clear_scene_meshes()
    podium_objs = generate_podium_stage_objects()
    podium_path = os.path.join(output_dir, "podium_stage.glb")
    exported["podium_stage"] = export_glb(podium_objs, podium_path)
    for obj in podium_objs:
        bpy.data.objects.remove(obj, do_unlink=True)

    # 2. Prestigious cycling trophies pack
    _clear_scene_meshes()
    trophy_objs = generate_trophies_pack_objects()
    trophies_path = os.path.join(output_dir, "trophies_pack.glb")
    exported["trophies_pack"] = export_glb(trophy_objs, trophies_path)
    for obj in trophy_objs:
        bpy.data.objects.remove(obj, do_unlink=True)

    return exported


if __name__ == "__main__":
    out_dir = "assets/3d/environment"
    for idx, arg in enumerate(sys.argv):
        if arg in ["--output-dir", "-o"] and idx + 1 < len(sys.argv):
            out_dir = sys.argv[idx + 1]

    files = export_podium_and_trophies(output_dir=out_dir)
    sm.setup_zwift_studio_lighting()
    print(f"[SUCCESS] Podium & Trophies generated: {files}")
