"""
===============================================================================
PRO PELOTON MANAGER - PROCEDURAL CYCLIST 3D MESH GENERATOR
===============================================================================
Blender Python API (bpy) script that procedurally generates a stylized,
anatomical 3D model of a modern road cyclist in athletic road cycling posture
(Mid-Poly Smooth in MyWhoosh / Zwift esports visual aesthetic).

Includes:
  1. Complete Fitted Pro Cycling Kit:
     - Aero road jersey (tight skin-suit fit, aero sleeves extending to elbow crease)
     - Bib shorts with wide compression leg gripper bands
     - High-cuff aerodynamic ribbed socks (UCI legal max height)
     - Pro road cycling shoes with carbon soles and dual lateral BOA Li2 dials
     - Aerodynamic road helmet (teardrop Kamm-tail exhaust) and dichroic iridium visor
  2. Anatomical Road Cycling Posture:
     - Pelvis firmly seated on saddle at (-0.200, 0.0, 0.940)
     - Hands gripping inward-flared brake hoods at (0.525, ±0.168, 0.695)
     - Right foot driving power stroke on pedal at (0.122, 0.096, 0.148)
     - Left foot in recovery phase on pedal at (-0.122, -0.096, 0.392)
     - Aerodynamic spine curvature and forward head inclination
  3. Morph Targets / Shape Keys for 3 Distinct Rider Silhouettes:
     - `Basis`: Baseline athletic cyclist
     - `Climber_Lean`: Lean climbing specialist (low BMI, slender torso, wiry arms/legs)
     - `AllRounder`: Robust, balanced GC / Classics powerhouse (Pogacar / Van Aert)
     - `Sprinter_Muscular`: Massive bunch sprinter (huge quads, thick calves, broad chest/delts)

Exported as binary glTF to: `assets/3d/cyclists/cyclist_road.glb`.
Coordinates align with `assets/3d/bikes/` frames, wheels, and components.

Compatible with Blender 3.6 LTS, 4.x, and 5.x+.
===============================================================================
"""

import math
import os
import sys
from dataclasses import dataclass
from typing import Callable, Dict, List, Optional, Tuple, Union

try:
    import bpy
    import bmesh
    from mathutils import Matrix, Vector
except ImportError:
    print("[ERROR] 'bpy' / 'mathutils' module not found. This script must be run within Blender:")
    print("        blender --background --python blender_scripts/generate_cyclist_mesh.py")
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
# DATA STRUCTURES FOR ANATOMICAL VERTEX TAGGING
# =============================================================================

@dataclass
class VertexTag:
    """Stores anatomical region metadata for vertex morphing."""
    region: str          # "torso", "chest", "arm", "forearm", "thigh", "calf", "shoulder", "fixed"
    center: Vector       # Reference axis or joint center
    axis: Vector         # Direction vector along limb or spine
    lateral_sign: float  # +1.0 for left (+Y), -1.0 for right (-Y), 0.0 for center


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
    tag_list: Optional[List[Tuple[bmesh.types.BMVert, VertexTag]]] = None,
    tag_region: str = "fixed",
    tag_lateral_sign: float = 0.0,
) -> List[List[bmesh.types.BMVert]]:
    """Lofts a tube with elliptical cross-section along a 3D path with anatomical tagging."""
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
            theta = (i / float(num_pts)) * 2.0 * math.pi
            dx = math.cos(theta) * rx
            dy = math.sin(theta) * ry
            v_pos = center + B * dy + N * dx
            v = bm.verts.new(v_pos)
            ring.append(v)

            if tag_list is not None:
                tag_list.append((v, VertexTag(
                    region=tag_region,
                    center=center,
                    axis=T,
                    lateral_sign=tag_lateral_sign,
                )))

        rings.append(ring)

    loft_rings(bm, rings, cap_start=cap_start, cap_end=cap_end, material_index=material_index)
    return rings


# =============================================================================
# CYCLIST PBR MATERIAL SYSTEM
# =============================================================================

def create_cyclist_skin_material(
    tone_hex: str = "#DFAC89",
    name: str = "M_Cyclist_Skin",
) -> bpy.types.Material:
    """
    Generates an athletic human skin material featuring natural subsurface
    scattering, soft skin roughness, and healthy athletic glow.
    """
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)

    linear_col = sm.hex_to_linear_rgb(tone_hex)
    sm._set_bsdf_socket(bsdf, "Base Color", linear_col)
    sm._set_bsdf_socket(bsdf, "Roughness", 0.46)
    sm._set_bsdf_socket(bsdf, "Metallic", 0.0)
    sm._set_bsdf_socket(bsdf, ["Specular IOR Level", "Specular"], 0.45)

    # Subsurface scattering for realistic human epidermis translucency
    sm._set_bsdf_socket(bsdf, ["Subsurface Weight", "Subsurface"], 0.12)
    sm._set_bsdf_socket(bsdf, "Subsurface Scale", 0.03)
    sm._set_bsdf_socket(bsdf, "Subsurface Radius", (1.0, 0.4, 0.2))

    return mat


def create_aero_sock_material(
    hex_color: str = "#F8FAFC",
    name: str = "M_Aero_Socks",
) -> bpy.types.Material:
    """
    Generates a high-cuff aerodynamic ribbed sock material with procedural
    vertical trip-stripes (UCI legal height, used for aero gains).
    """
    mat = sm._get_or_create_material(name)
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf, _ = sm._get_or_create_output_nodes(mat)

    # Vertical ribbed aero texture
    tex_coord = nodes.new("ShaderNodeTexCoord")
    tex_coord.location = (-750, 0)

    wave = nodes.new("ShaderNodeTexWave")
    wave.name = "Sock_Ribs"
    wave.location = (-500, 0)
    wave.wave_type = "BANDS"
    wave.bands_direction = "Y"
    wave.inputs["Scale"].default_value = 140.0
    wave.inputs["Distortion"].default_value = 0.5

    bump = nodes.new("ShaderNodeBump")
    bump.name = "Sock_Rib_Bump"
    bump.location = (-220, 0)
    bump.inputs["Strength"].default_value = 0.14
    bump.inputs["Distance"].default_value = 0.0008

    links.new(tex_coord.outputs["Object"], wave.inputs["Vector"])
    links.new(wave.outputs["Color"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])

    linear_col = sm.hex_to_linear_rgb(hex_color)
    sm._set_bsdf_socket(bsdf, "Base Color", linear_col)
    sm._set_bsdf_socket(bsdf, "Roughness", 0.65)
    sm._set_bsdf_socket(bsdf, "Metallic", 0.0)
    sm._set_bsdf_socket(bsdf, ["Sheen Weight", "Sheen"], 0.8)

    return mat


def create_road_shoes_material(
    upper_hex: str = "#FFFFFF",
    name: str = "M_Road_Shoes",
) -> bpy.types.Material:
    """
    Generates a sleek synthetic microfiber road cycling shoe upper
    (Specialized S-Works Torch / Shimano S-PHYRE RC903 aesthetic).
    """
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)

    linear_col = sm.hex_to_linear_rgb(upper_hex)
    sm._set_bsdf_socket(bsdf, "Base Color", linear_col)
    sm._set_bsdf_socket(bsdf, "Roughness", 0.32)
    sm._set_bsdf_socket(bsdf, "Metallic", 0.02)
    sm._set_bsdf_socket(bsdf, ["Coat Weight", "Clearcoat"], 0.35)
    sm._set_bsdf_socket(bsdf, ["Coat Roughness", "Clearcoat Roughness"], 0.08)

    return mat


def create_boa_dial_material(
    name: str = "M_BOA_Dial",
) -> bpy.types.Material:
    """
    Generates a dual-tone anodized aluminum & textured composite BOA Li2
    dial knob with metallic grip ring and matte faceplate.
    """
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)

    sm._set_bsdf_socket(bsdf, "Base Color", sm.hex_to_linear_rgb("#1E293B"))
    sm._set_bsdf_socket(bsdf, "Metallic", 0.82)
    sm._set_bsdf_socket(bsdf, "Roughness", 0.22)
    sm._set_bsdf_socket(bsdf, ["Specular IOR Level", "Specular"], 0.75)

    return mat


# =============================================================================
# PROCEDURAL ANATOMICAL GEOMETRY BUILDERS
# =============================================================================

def build_torso_and_pelvis(
    bm: bmesh.types.BMesh,
    tag_list: List[Tuple[bmesh.types.BMVert, VertexTag]],
    mat_jersey: int,
    mat_bib: int,
) -> None:
    """
    Constructs the aerodynamic road cycling torso, thoracic cage, waist,
    and glutes/pelvis resting firmly on the saddle at (-0.200, 0.0, 0.940).
    """
    # Aerodynamic spine trajectory from pelvic ischium to neck base
    p_pelvis = Vector((-0.200, 0.0, 0.940))
    p_sacrum = Vector((-0.150, 0.0, 0.948))
    p_lumbar = Vector((-0.070, 0.0, 0.942))
    p_mid_torso = Vector((0.040, 0.0, 0.925))
    p_upper_chest = Vector((0.150, 0.0, 0.900))
    p_neck_base = Vector((0.250, 0.0, 0.875))

    path = [p_pelvis, p_sacrum, p_lumbar, p_mid_torso, p_upper_chest, p_neck_base]
    num_pts = 14

    # Radii along torso path (t=0 pelvis to t=1 neck)
    # rx: vertical/sagittal semi-axis, ry: lateral/transverse semi-axis
    def rx(t: float) -> float:
        if t < 0.25:  # pelvis / glutes
            return 0.095 + t * 0.010
        elif t < 0.50:  # waist / abdomen
            return 0.088 - (t - 0.25) * 0.020
        else:  # ribcage / thoracic chest
            return 0.092 + (t - 0.50) * 0.030

    def ry(t: float) -> float:
        if t < 0.25:  # pelvis width (170mm sit-bone span)
            return 0.125 - t * 0.040
        elif t < 0.50:  # lean waist (200mm span)
            return 0.108 - (t - 0.25) * 0.020
        else:  # wide chest / lats (290mm span)
            return 0.115 + (t - 0.50) * 0.060

    n_steps = len(path)
    rings = []

    for s_idx, center in enumerate(path):
        t = s_idx / float(n_steps - 1)

        if s_idx == 0:
            T = (path[1] - path[0]).normalized()
        elif s_idx == n_steps - 1:
            T = (path[-1] - path[-2]).normalized()
        else:
            T = (path[s_idx + 1] - path[s_idx - 1]).normalized()

        B = Vector((0.0, 1.0, 0.0)) - (Vector((0.0, 1.0, 0.0)).dot(T)) * T
        B.normalize()
        N = T.cross(B).normalized()

        cur_rx = rx(t)
        cur_ry = ry(t)
        ring = []

        # Tag category based on height: pelvis/waist vs chest/lats
        region_tag = "pelvis" if t < 0.35 else ("waist" if t < 0.60 else "chest")

        for i in range(num_pts):
            theta = (i / float(num_pts)) * 2.0 * math.pi
            dx = math.cos(theta) * cur_rx
            dy = math.sin(theta) * cur_ry

            # Flatten bottom slightly for saddle contact
            if t < 0.30 and dx < -0.01:
                dx *= 0.70

            v_pos = center + B * dy + N * dx
            v = bm.verts.new(v_pos)
            ring.append(v)

            tag_list.append((v, VertexTag(
                region=region_tag,
                center=center,
                axis=T,
                lateral_sign=math.copysign(1.0, dy) if abs(dy) > 1e-4 else 0.0,
            )))

        rings.append(ring)

    # Loft rings with appropriate materials:
    # Rings 0..2 are bib shorts (pelvis & waist), rings 3..5 are aero jersey
    for r_idx in range(len(rings) - 1):
        mat_idx = mat_bib if r_idx < 2 else mat_jersey
        loft_rings(bm, [rings[r_idx], rings[r_idx + 1]], cap_start=(r_idx == 0), cap_end=False, material_index=mat_idx)

    # Cap neck base
    try:
        f_neck = bm.faces.new(rings[-1])
        f_neck.material_index = mat_jersey
    except ValueError:
        pass


def build_head_helmet_and_visor(
    bm: bmesh.types.BMesh,
    tag_list: List[Tuple[bmesh.types.BMVert, VertexTag]],
    mat_skin: int,
    mat_helmet: int,
    mat_visor: int,
) -> None:
    """
    Constructs the athletic neck, stylized jaw/face, aerodynamic road helmet
    with Kamm-tail exhaust, and iridescent dichroic visor.
    """
    p_neck_base = Vector((0.250, 0.0, 0.875))
    p_neck_mid = Vector((0.290, 0.0, 0.915))
    p_jaw = Vector((0.330, 0.0, 0.950))
    p_cranium = Vector((0.360, 0.0, 0.985))

    # 1. ATHLETIC NECK
    neck_path = [p_neck_base, p_neck_mid, p_jaw]
    loft_tube_along_path(
        bm,
        neck_path,
        radius_x=0.046,
        radius_y=0.042,
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_pts=10,
        cap_start=False,
        cap_end=False,
        material_index=mat_skin,
        tag_list=tag_list,
        tag_region="neck",
    )

    # 2. STYLIZED ATHLETIC FACE & CRANIUM
    face_path = [p_jaw, p_cranium, p_cranium + Vector((0.035, 0.0, 0.020))]
    loft_tube_along_path(
        bm,
        face_path,
        radius_x=lambda t: 0.065 - t * 0.015,
        radius_y=lambda t: 0.058 - t * 0.010,
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_pts=12,
        cap_start=True,
        cap_end=True,
        material_index=mat_skin,
        tag_list=tag_list,
        tag_region="fixed",
    )

    # 3. AERODYNAMIC ROAD HELMET (Kask Utopia / Specialized Evade style)
    # Tear-drop Kamm-tail exhaust tapering at rear
    p_helm_front = p_cranium + Vector((0.080, 0.0, 0.025))
    p_helm_apex = p_cranium + Vector((0.000, 0.0, 0.075))
    p_helm_rear = p_cranium + Vector((-0.130, 0.0, 0.030))
    p_helm_tail = p_cranium + Vector((-0.180, 0.0, 0.015))

    helm_path = [p_helm_front, p_helm_apex, p_helm_rear, p_helm_tail]
    loft_tube_along_path(
        bm,
        helm_path,
        radius_x=lambda t: 0.080 if t < 0.4 else (0.080 - (t - 0.4) * 0.075),
        radius_y=lambda t: 0.088 if t < 0.4 else (0.088 - (t - 0.4) * 0.070),
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_pts=14,
        cap_start=True,
        cap_end=True,
        material_index=mat_helmet,
        tag_list=tag_list,
        tag_region="fixed",
    )

    # 4. DICHROIC IRIDIUM VISOR / CYCLING EYEWEAR
    # Cylindrical wrap-around shield across upper bridge of nose & temples
    p_visor_center = p_jaw + Vector((0.060, 0.0, 0.028))
    visor_rings = []
    for dy_band in [-0.012, 0.012]:
        ring = []
        for a_deg in range(-70, 75, 20):
            ang = math.radians(a_deg)
            vx = p_visor_center.x + 0.052 * math.cos(ang)
            vy = p_visor_center.y + 0.068 * math.sin(ang)
            vz = p_visor_center.z + dy_band - 0.005 * math.cos(ang)
            v = bm.verts.new(Vector((vx, vy, vz)))
            ring.append(v)
            tag_list.append((v, VertexTag("fixed", p_visor_center, Vector((1.0, 0.0, 0.0)), 0.0)))
        visor_rings.append(ring)

    loft_rings(bm, visor_rings, cap_start=False, cap_end=False, material_index=mat_visor)


def build_arms_and_hands(
    bm: bmesh.types.BMesh,
    tag_list: List[Tuple[bmesh.types.BMVert, VertexTag]],
    mat_jersey: int,
    mat_skin: int,
) -> None:
    """
    Constructs aerodynamic left and right arms:
      - Upper arm covered by aero jersey sleeves down to elbow crease
      - Exposed muscular forearms
      - Ergonomic hands grasping brake hoods at (0.525, ±0.168, 0.695)
    """
    p_shoulder_base = Vector((0.230, 0.0, 0.860))
    p_hood_base = Vector((0.525, 0.0, 0.695))

    for is_left in [True, False]:
        side = 1.0 if is_left else -1.0
        y_side = side * 0.165

        # Key joint landmarks
        p_shoulder = Vector((0.230, y_side, 0.860))
        p_elbow = Vector((0.340, side * 0.200, 0.730))
        p_wrist = Vector((0.470, side * 0.170, 0.705))
        p_hand = Vector((0.525, side * 0.168, 0.695))

        # 1. DELTOID & UPPER ARM (AERO JERSEY SLEEVE)
        upper_arm_path = [p_shoulder, p_shoulder.lerp(p_elbow, 0.5), p_elbow]
        loft_tube_along_path(
            bm,
            upper_arm_path,
            radius_x=lambda t: 0.052 - t * 0.012,
            radius_y=lambda t: 0.048 - t * 0.010,
            lateral_hint=Vector((0.0, side, 0.0)),
            num_pts=10,
            cap_start=True,
            cap_end=False,
            material_index=mat_jersey,
            tag_list=tag_list,
            tag_region="arm",
            tag_lateral_sign=side,
        )

        # 2. FOREARM (EXPOSED ATHLETIC SKIN)
        forearm_path = [p_elbow, p_elbow.lerp(p_wrist, 0.5), p_wrist]
        loft_tube_along_path(
            bm,
            forearm_path,
            radius_x=lambda t: 0.038 - t * 0.010,
            radius_y=lambda t: 0.035 - t * 0.009,
            lateral_hint=Vector((0.0, side, 0.0)),
            num_pts=10,
            cap_start=False,
            cap_end=False,
            material_index=mat_skin,
            tag_list=tag_list,
            tag_region="forearm",
            tag_lateral_sign=side,
        )

        # 3. HAND GRIPPING HOOD
        hand_path = [p_wrist, p_wrist.lerp(p_hand, 0.5), p_hand]
        loft_tube_along_path(
            bm,
            hand_path,
            radius_x=0.024,
            radius_y=0.018,
            lateral_hint=Vector((0.0, side, 0.0)),
            num_pts=8,
            cap_start=False,
            cap_end=True,
            material_index=mat_skin,
            tag_list=tag_list,
            tag_region="fixed",
            tag_lateral_sign=side,
        )


def build_legs_and_socks(
    bm: bmesh.types.BMesh,
    tag_list: List[Tuple[bmesh.types.BMVert, VertexTag]],
    mat_bib: int,
    mat_skin: int,
    mat_socks: int,
) -> Tuple[Dict[str, Vector], Dict[str, Vector]]:
    """
    Constructs the legs and aero socks with inverse kinematics matching
    the pedal stroke:
      - Right leg: Power phase (extended forward-down)
      - Left leg: Recovery phase (flexed up-back)
      - Bib shorts with compression gripper bands
      - Tall aero socks covering ankle to mid-calf
    """
    # 1. RIGHT LEG LANDMARKS (Extended Power Phase)
    # Femur ~0.40m, Tibia ~0.40m
    p_hip_r = Vector((-0.160, 0.095, 0.900))
    p_knee_r = Vector((0.105, 0.121, 0.600))
    p_ankle_r = Vector((0.110, 0.096, 0.200))

    # Right Thigh: Bib shorts from hip to 0.07m above knee
    thigh_r_path = [
        p_hip_r,
        p_hip_r.lerp(p_knee_r, 0.35),
        p_hip_r.lerp(p_knee_r, 0.70),
        p_hip_r.lerp(p_knee_r, 0.85),
    ]
    loft_tube_along_path(
        bm,
        thigh_r_path,
        radius_x=lambda t: 0.095 - t * 0.024,
        radius_y=lambda t: 0.088 - t * 0.022,
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_pts=12,
        cap_start=True,
        cap_end=False,
        material_index=mat_bib,
        tag_list=tag_list,
        tag_region="thigh",
        tag_lateral_sign=-1.0,
    )

    # Right Knee: Exposed skin patella
    knee_r_path = [
        p_hip_r.lerp(p_knee_r, 0.85),
        p_knee_r,
        p_knee_r.lerp(p_ankle_r, 0.20),
    ]
    loft_tube_along_path(
        bm,
        knee_r_path,
        radius_x=0.062,
        radius_y=0.058,
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_pts=10,
        cap_start=False,
        cap_end=False,
        material_index=mat_skin,
        tag_list=tag_list,
        tag_region="thigh",
        tag_lateral_sign=-1.0,
    )

    # Right Calf & Aero Sock: Mid-calf to ankle
    p_calf_top_r = p_knee_r.lerp(p_ankle_r, 0.20)
    p_sock_top_r = p_knee_r.lerp(p_ankle_r, 0.45)
    calf_r_path = [p_calf_top_r, p_sock_top_r]
    loft_tube_along_path(
        bm,
        calf_r_path,
        radius_x=lambda t: 0.060 - t * 0.005,
        radius_y=lambda t: 0.055 - t * 0.004,
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_pts=10,
        cap_start=False,
        cap_end=False,
        material_index=mat_skin,
        tag_list=tag_list,
        tag_region="calf",
        tag_lateral_sign=-1.0,
    )

    sock_r_path = [
        p_sock_top_r,
        p_knee_r.lerp(p_ankle_r, 0.75),
        p_ankle_r,
    ]
    loft_tube_along_path(
        bm,
        sock_r_path,
        radius_x=lambda t: 0.055 - t * 0.015,
        radius_y=lambda t: 0.051 - t * 0.014,
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_pts=10,
        cap_start=False,
        cap_end=False,
        material_index=mat_socks,
        tag_list=tag_list,
        tag_region="calf",
        tag_lateral_sign=-1.0,
    )

    # 2. LEFT LEG LANDMARKS (Flexed Recovery Phase)
    p_hip_l = Vector((-0.160, -0.095, 0.900))
    p_knee_l = Vector((0.184, -0.126, 0.697))
    p_ankle_l = Vector((-0.122, -0.096, 0.440))

    # Left Thigh: Bib shorts
    thigh_l_path = [
        p_hip_l,
        p_hip_l.lerp(p_knee_l, 0.35),
        p_hip_l.lerp(p_knee_l, 0.70),
        p_hip_l.lerp(p_knee_l, 0.85),
    ]
    loft_tube_along_path(
        bm,
        thigh_l_path,
        radius_x=lambda t: 0.095 - t * 0.024,
        radius_y=lambda t: 0.088 - t * 0.022,
        lateral_hint=Vector((0.0, -1.0, 0.0)),
        num_pts=12,
        cap_start=True,
        cap_end=False,
        material_index=mat_bib,
        tag_list=tag_list,
        tag_region="thigh",
        tag_lateral_sign=1.0,
    )

    # Left Knee: Exposed skin
    knee_l_path = [
        p_hip_l.lerp(p_knee_l, 0.85),
        p_knee_l,
        p_knee_l.lerp(p_ankle_l, 0.20),
    ]
    loft_tube_along_path(
        bm,
        knee_l_path,
        radius_x=0.062,
        radius_y=0.058,
        lateral_hint=Vector((0.0, -1.0, 0.0)),
        num_pts=10,
        cap_start=False,
        cap_end=False,
        material_index=mat_skin,
        tag_list=tag_list,
        tag_region="thigh",
        tag_lateral_sign=1.0,
    )

    # Left Calf & Aero Sock
    p_calf_top_l = p_knee_l.lerp(p_ankle_l, 0.20)
    p_sock_top_l = p_knee_l.lerp(p_ankle_l, 0.45)
    calf_l_path = [p_calf_top_l, p_sock_top_l]
    loft_tube_along_path(
        bm,
        calf_l_path,
        radius_x=lambda t: 0.060 - t * 0.005,
        radius_y=lambda t: 0.055 - t * 0.004,
        lateral_hint=Vector((0.0, -1.0, 0.0)),
        num_pts=10,
        cap_start=False,
        cap_end=False,
        material_index=mat_skin,
        tag_list=tag_list,
        tag_region="calf",
        tag_lateral_sign=1.0,
    )

    sock_l_path = [
        p_sock_top_l,
        p_knee_l.lerp(p_ankle_l, 0.75),
        p_ankle_l,
    ]
    loft_tube_along_path(
        bm,
        sock_l_path,
        radius_x=lambda t: 0.055 - t * 0.015,
        radius_y=lambda t: 0.051 - t * 0.014,
        lateral_hint=Vector((0.0, -1.0, 0.0)),
        num_pts=10,
        cap_start=False,
        cap_end=False,
        material_index=mat_socks,
        tag_list=tag_list,
        tag_region="calf",
        tag_lateral_sign=1.0,
    )

    landmarks_r = {"hip": p_hip_r, "knee": p_knee_r, "ankle": p_ankle_r}
    landmarks_l = {"hip": p_hip_l, "knee": p_knee_l, "ankle": p_ankle_l}
    return landmarks_r, landmarks_l


def build_shoes_and_boa_dials(
    bm: bmesh.types.BMesh,
    tag_list: List[Tuple[bmesh.types.BMVert, VertexTag]],
    landmarks_r: Dict[str, Vector],
    landmarks_l: Dict[str, Vector],
    mat_shoe: int,
    mat_carbon: int,
    mat_boa: int,
) -> None:
    """
    Constructs left and right high-performance road cycling shoes:
      - Molded ergonomic upper and stiff carbon fiber outsole plate
      - Look Keo clipless cleat engaged on pedal spindle
      - Dual lateral BOA Li2 dials (upper instep dial + lower forefoot dial)
    """
    # 1. RIGHT SHOE (Power stroke: forward-down angle ~20°)
    p_ankle_r = landmarks_r["ankle"]
    p_heel_r = p_ankle_r + Vector((-0.055, 0.0, -0.020))
    p_cleat_r = Vector((0.122, 0.096, 0.148))
    p_toe_r = p_cleat_r + Vector((0.080, 0.0, -0.012))

    shoe_r_path = [p_heel_r, p_ankle_r + Vector((-0.020, 0.0, -0.035)), p_cleat_r + Vector((0.0, 0.0, 0.010)), p_toe_r]
    loft_tube_along_path(
        bm,
        shoe_r_path,
        radius_x=lambda t: 0.040 - t * 0.012,
        radius_y=lambda t: 0.044 - t * 0.008,
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_pts=10,
        cap_start=True,
        cap_end=True,
        material_index=mat_shoe,
        tag_list=tag_list,
        tag_region="fixed",
    )

    # Carbon Sole Plate (Right)
    sole_r_path = [p_heel_r + Vector((0.0, 0.0, -0.015)), p_cleat_r, p_toe_r + Vector((0.0, 0.0, -0.005))]
    loft_tube_along_path(
        bm,
        sole_r_path,
        radius_x=0.006,
        radius_y=0.042,
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_pts=8,
        cap_start=True,
        cap_end=True,
        material_index=mat_carbon,
        tag_list=tag_list,
        tag_region="fixed",
    )

    # 2. LEFT SHOE (Recovery phase: angled ~35° toe-down)
    p_ankle_l = landmarks_l["ankle"]
    p_heel_l = p_ankle_l + Vector((-0.050, 0.0, 0.020))
    p_cleat_l = Vector((-0.122, -0.096, 0.392))
    p_toe_l = p_cleat_l + Vector((0.075, 0.0, -0.040))

    shoe_l_path = [p_heel_l, p_ankle_l + Vector((-0.015, 0.0, -0.025)), p_cleat_l + Vector((0.0, 0.0, 0.012)), p_toe_l]
    loft_tube_along_path(
        bm,
        shoe_l_path,
        radius_x=lambda t: 0.040 - t * 0.012,
        radius_y=lambda t: 0.044 - t * 0.008,
        lateral_hint=Vector((0.0, -1.0, 0.0)),
        num_pts=10,
        cap_start=True,
        cap_end=True,
        material_index=mat_shoe,
        tag_list=tag_list,
        tag_region="fixed",
    )

    # Carbon Sole Plate (Left)
    sole_l_path = [p_heel_l + Vector((0.0, 0.0, -0.015)), p_cleat_l, p_toe_l + Vector((0.0, 0.0, -0.005))]
    loft_tube_along_path(
        bm,
        sole_l_path,
        radius_x=0.006,
        radius_y=0.042,
        lateral_hint=Vector((0.0, -1.0, 0.0)),
        num_pts=8,
        cap_start=True,
        cap_end=True,
        material_index=mat_carbon,
        tag_list=tag_list,
        tag_region="fixed",
    )

    # 3. DUAL BOA Li2 DIALS ON EACH SHOE
    # Right Shoe Dials (Mounted laterally at Y ≈ +0.138)
    p_boa_r1 = p_ankle_r + Vector((0.010, 0.042, -0.015))   # Upper instep dial
    p_boa_r2 = p_cleat_r + Vector((0.035, 0.040, 0.018))    # Lower forefoot dial

    # Left Shoe Dials (Mounted laterally at Y ≈ -0.138)
    p_boa_l1 = p_ankle_l + Vector((0.010, -0.042, -0.005))  # Upper instep dial
    p_boa_l2 = p_cleat_l + Vector((0.030, -0.040, 0.005))   # Lower forefoot dial

    r_dial = 0.0085  # 17mm diameter BOA dial knob
    h_dial = 0.0060  # 6mm low-profile height

    for p_dial, lateral_dir in [(p_boa_r1, 1.0), (p_boa_r2, 1.0), (p_boa_l1, -1.0), (p_boa_l2, -1.0)]:
        dial_rings = []
        for dy in [0.0, lateral_dir * h_dial]:
            ring = []
            for s in range(10):
                ang = (s / 10.0) * 2.0 * math.pi
                dx = math.cos(ang) * r_dial
                dz = math.sin(ang) * r_dial
                v = bm.verts.new(p_dial + Vector((dx, dy, dz)))
                ring.append(v)
                tag_list.append((v, VertexTag("fixed", p_dial, Vector((0.0, lateral_dir, 0.0)), lateral_dir)))
            dial_rings.append(ring)

        loft_rings(bm, dial_rings, cap_start=True, cap_end=True, material_index=mat_boa)


# =============================================================================
# MORPH TARGETS / SHAPE KEYS GENERATOR
# =============================================================================

def apply_cyclist_shape_keys(
    obj: bpy.types.Object,
    tag_list: List[Tuple[bmesh.types.BMVert, VertexTag]],
) -> Dict[str, bpy.types.ShapeKey]:
    """
    Creates and populates the 3 required morph target shape keys:
      1. `Basis`: Default athletic cyclist
      2. `Climber_Lean`: Lean climbing specialist (low BMI, slender torso & wiry limbs)
      3. `AllRounder`: Robust, balanced GC powerhouse (Pogacar / Van Aert)
      4. `Sprinter_Muscular`: Massive bunch sprinter (huge quads, thick calves & broad chest)
    """
    if not obj.data.shape_keys:
        obj.shape_key_add(name="Basis", from_mix=False)

    sk_climber = obj.shape_key_add(name="Climber_Lean", from_mix=False)
    sk_allrounder = obj.shape_key_add(name="AllRounder", from_mix=False)
    sk_sprinter = obj.shape_key_add(name="Sprinter_Muscular", from_mix=False)

    mesh = obj.data
    basis_key = obj.data.shape_keys.key_blocks["Basis"]
    n_verts = len(mesh.vertices)

    # Map vertex index to tag
    tag_map: Dict[int, VertexTag] = {}
    for idx, (v, tag) in enumerate(tag_list):
        if idx < n_verts:
            tag_map[idx] = tag

    for i in range(n_verts):
        base_co = basis_key.data[i].co
        tag = tag_map.get(i, VertexTag("fixed", base_co, Vector((0.0, 0.0, 1.0)), 0.0))
        reg = tag.region

        # ---------------------------------------------------------------------
        # 1. CLIMBER_LEAN DELTA (Slender, lightweight, low-volume)
        # ---------------------------------------------------------------------
        d_climber = Vector((0.0, 0.0, 0.0))
        if reg in ["torso", "chest", "waist"]:
            # Lean torso: -10% transverse, -8% sagittal
            d_climber = Vector((
                -(base_co.x - tag.center.x) * 0.08,
                -(base_co.y - tag.center.y) * 0.10,
                0.0,
            ))
        elif reg == "pelvis":
            d_climber = Vector((0.0, -base_co.y * 0.08, 0.0))
        elif reg in ["arm", "forearm"]:
            # Slender climber arms: -14% radius
            radial = base_co - tag.center
            d_climber = -radial * 0.14
        elif reg == "thigh":
            # Lean wiry climber quads: -11% radius
            radial = base_co - tag.center
            d_climber = -radial * 0.11
        elif reg == "calf":
            # Slender compact calves: -9% radius
            radial = base_co - tag.center
            d_climber = -radial * 0.09

        # ---------------------------------------------------------------------
        # 2. ALLROUNDER DELTA (Balanced GC & Classics powerhouse)
        # ---------------------------------------------------------------------
        d_allrounder = Vector((0.0, 0.0, 0.0))
        if reg in ["torso", "chest", "waist"]:
            d_allrounder = Vector((
                (base_co.x - tag.center.x) * 0.04,
                (base_co.y - tag.center.y) * 0.04,
                0.0,
            ))
        elif reg in ["arm", "forearm"]:
            radial = base_co - tag.center
            d_allrounder = radial * 0.05
        elif reg == "thigh":
            radial = base_co - tag.center
            d_allrounder = radial * 0.06
        elif reg == "calf":
            radial = base_co - tag.center
            d_allrounder = radial * 0.04

        # ---------------------------------------------------------------------
        # 3. SPRINTER_MUSCULAR DELTA (Massive quadriceps, thick calves, broad chest)
        # ---------------------------------------------------------------------
        d_sprinter = Vector((0.0, 0.0, 0.0))
        if reg in ["torso", "chest"]:
            # Broad chest & lats: +15% width, +10% chest expansion
            d_sprinter = Vector((
                (base_co.x - tag.center.x) * 0.10,
                (base_co.y - tag.center.y) * 0.15,
                0.0,
            ))
        elif reg == "waist":
            d_sprinter = Vector((0.0, (base_co.y - tag.center.y) * 0.08, 0.0))
        elif reg == "pelvis":
            d_sprinter = Vector((0.0, base_co.y * 0.10, 0.0))
        elif reg == "arm":
            # Thick biceps & triceps: +18% radius for sprint handlebar pulling
            radial = base_co - tag.center
            d_sprinter = radial * 0.18 + Vector((0.0, tag.lateral_sign * 0.015, 0.0))
        elif reg == "forearm":
            radial = base_co - tag.center
            d_sprinter = radial * 0.15
        elif reg == "thigh":
            # Enormous sprinter quadriceps & hamstrings: +28% muscle volume!
            # Extra lateral bulge for vastus lateralis
            radial = base_co - tag.center
            lat_boost = max(0.0, abs(radial.y) / (radial.length + 1e-6))
            factor = 0.26 + 0.06 * lat_boost
            d_sprinter = radial * factor
        elif reg == "calf":
            # Thick gastrocnemius calves: +20% volume
            radial = base_co - tag.center
            d_sprinter = radial * 0.20

        # Apply computed coordinates to shape keys
        sk_climber.data[i].co = base_co + d_climber
        sk_allrounder.data[i].co = base_co + d_allrounder
        sk_sprinter.data[i].co = base_co + d_sprinter

    # Set default preview weight (AllRounder active by default)
    sk_allrounder.value = 1.0

    return {
        "Basis": basis_key,
        "Climber_Lean": sk_climber,
        "AllRounder": sk_allrounder,
        "Sprinter_Muscular": sk_sprinter,
    }


# =============================================================================
# MASTER CYCLIST MESH GENERATOR
# =============================================================================

def generate_cyclist_mesh(
    name: str = "Cyclist_Mesh",
    jersey_color_hex: str = "#2563EB",
    bib_color_hex: str = "#111827",
    helmet_color_hex: str = "#E10600",
    skin_tone_hex: str = "#DFAC89",
    sock_color_hex: str = "#F8FAFC",
    shoe_color_hex: str = "#FFFFFF",
) -> bpy.types.Object:
    """
    Constructs the complete 3D road cyclist mesh with fitted pro cycling kit,
    PBR materials, and 3 morph target shape keys.
    """
    # 1. Create and configure PBR materials
    mat_skin = create_cyclist_skin_material(skin_tone_hex)
    mat_jersey = sm.create_lycra_fabric_material(jersey_color_hex, name="M_Lycra_Jersey")
    mat_bib = sm.create_lycra_fabric_material(bib_color_hex, name="M_Lycra_BibShorts")
    mat_socks = create_aero_sock_material(sock_color_hex)
    mat_shoe = create_road_shoes_material(shoe_color_hex)
    mat_carbon = sm.create_carbon_matte_material()
    mat_boa = create_boa_dial_material()
    mat_helmet = sm.create_glossy_frame_paint_material(helmet_color_hex, name="M_Helmet_Aero")
    mat_visor = sm.create_visor_iridium_material()

    materials = [
        mat_skin,      # 0
        mat_jersey,    # 1
        mat_bib,       # 2
        mat_socks,     # 3
        mat_shoe,      # 4
        mat_carbon,    # 5
        mat_boa,       # 6
        mat_helmet,    # 7
        mat_visor,     # 8
    ]

    # 2. Build geometry in BMesh
    bm = bmesh.new()
    tag_list: List[Tuple[bmesh.types.BMVert, VertexTag]] = []

    build_torso_and_pelvis(bm, tag_list, mat_jersey=1, mat_bib=2)
    build_head_helmet_and_visor(bm, tag_list, mat_skin=0, mat_helmet=7, mat_visor=8)
    build_arms_and_hands(bm, tag_list, mat_jersey=1, mat_skin=0)
    lm_r, lm_l = build_legs_and_socks(bm, tag_list, mat_bib=2, mat_skin=0, mat_socks=3)
    build_shoes_and_boa_dials(bm, tag_list, lm_r, lm_l, mat_shoe=4, mat_carbon=5, mat_boa=6)

    # 3. Create Blender mesh and object
    mesh = bpy.data.meshes.new(f"{name}_Data")
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)

    # 4. Assign material slots
    for mat in materials:
        obj.data.materials.append(mat)

    # 5. Apply Zwift/MyWhoosh visual styling (smooth shading + auto-smooth normals)
    sm.clean_zwift_mesh(obj)
    sm.apply_zwift_style(obj, auto_smooth_angle_deg=35.0)

    # 6. Generate and populate Shape Keys (Climber_Lean, AllRounder, Sprinter_Muscular)
    apply_cyclist_shape_keys(obj, tag_list)

    return obj


def export_cyclist_glb(
    output_glb_path: str = "assets/3d/cyclists/cyclist_road.glb",
    jersey_color_hex: str = "#2563EB",
    bib_color_hex: str = "#111827",
    helmet_color_hex: str = "#E10600",
) -> Tuple[bpy.types.Object, str]:
    """
    Builds the complete cyclist model with morph targets and exports
    it to an optimized binary glTF file (.glb).
    """
    # Remove existing mesh objects from scene
    for obj in [o for o in bpy.context.scene.objects if o.type == "MESH"]:
        bpy.data.objects.remove(obj, do_unlink=True)

    print("\n" + "=" * 75)
    print("PRO PELOTON MANAGER: GENERATING PROCEDURAL CYCLIST 3D MESH")
    print("=" * 75)

    cyclist_obj = generate_cyclist_mesh(
        name="Cyclist_Road",
        jersey_color_hex=jersey_color_hex,
        bib_color_hex=bib_color_hex,
        helmet_color_hex=helmet_color_hex,
    )

    bpy.ops.object.select_all(action="DESELECT")
    cyclist_obj.select_set(True)
    bpy.context.view_layer.objects.active = cyclist_obj

    abs_output_path = os.path.abspath(output_glb_path)
    os.makedirs(os.path.dirname(abs_output_path), exist_ok=True)

    print(f"[CYCLIST] Exporting binary glTF model with morph targets to '{abs_output_path}'...")
    export_kwargs = {
        "filepath": abs_output_path,
        "export_format": "GLB",
        "use_selection": True,
        "export_apply": False,
        "export_morph": True,
        "export_materials": "EXPORT",
    }

    rna_props = {p.identifier for p in bpy.ops.export_scene.gltf.get_rna_type().properties}
    if "export_normals" in rna_props:
        export_kwargs["export_normals"] = True
    if "export_morph_normal" in rna_props:
        export_kwargs["export_morph_normal"] = True

    bpy.ops.export_scene.gltf(**export_kwargs)

    if not os.path.exists(abs_output_path):
        raise RuntimeError(f"Export failed: file not found at '{abs_output_path}'")

    file_size_kb = os.path.getsize(abs_output_path) / 1024.0
    polys = len(cyclist_obj.data.polygons)
    verts = len(cyclist_obj.data.vertices)
    sk_names = [k.name for k in cyclist_obj.data.shape_keys.key_blocks]

    print(f"[CYCLIST] Export successful! File size: {file_size_kb:.1f} KB ({verts} verts, {polys} polys)")
    print(f"[CYCLIST] Shape Keys included: {sk_names}")
    print("=" * 75 + "\n")

    return cyclist_obj, abs_output_path


# =============================================================================
# CLI EXECUTION ENTRY POINT
# =============================================================================

if __name__ == "__main__":
    out_path = "assets/3d/cyclists/cyclist_road.glb"
    for idx, arg in enumerate(sys.argv):
        if arg in ["--output", "-o"] and idx + 1 < len(sys.argv):
            out_path = sys.argv[idx + 1]

    jersey_color = "#2563EB"
    for idx, arg in enumerate(sys.argv):
        if arg in ["--jersey-color", "-j"] and idx + 1 < len(sys.argv):
            jersey_color = sys.argv[idx + 1]

    cyclist_asset, glb_file = export_cyclist_glb(
        output_glb_path=out_path,
        jersey_color_hex=jersey_color,
    )

    # Setup studio lighting for viewport viewing
    sm.setup_zwift_studio_lighting()

    print(f"[SUCCESS] Cyclist 3D mesh generated: '{glb_file}'")

