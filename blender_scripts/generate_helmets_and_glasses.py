"""
===============================================================================
PRO PELOTON MANAGER - PROCEDURAL CYCLING HELMETS & GLASSES GENERATOR
===============================================================================
Blender Python API (bpy) script that procedurally models high-performance
road cycling headwear and pro eyewear matching WorldTour racing specs:

  1. Przewiewny kask szosowy z otworami wentylacyjnymi (`helmet_vented.glb`):
     - High-ventilation climbing & hot-weather road helmet (Prevail / Valegro style)
     - Longitudinal aerodynamic ribs with deep ventilation channels
     - Exposed shock-absorbing EPS foam liner and internal carbon bridges
     - Occipital retention cradle dial and lightweight Y-straps with chin buckle

  2. Zabudowany kask aerodynamiczny (`helmet_aero.glb`):
     - Closed-shell aerodynamic sprinter / classics helmet (Evade / Utopia style)
     - Smooth drag-reduction aerodynamic crown with strategic frontal NACA scoops
     - Truncated Kamm-tail rear exhaust spoiler for clean airflow detachment
     - Sculpted lateral temple channels and contrast EPS undertray

  3. Kask kroplowy do jazdy na czas z wizjerem (`helmet_tt.glb`):
     - Extreme aero time trial teardrop helmet (Bambino Pro / Aerohead style)
     - Extended aerodynamic teardrop fairing smoothly bridging onto rider's back
     - Full-coverage integrated dichroic iridium magnetic visor
     - Enclosed ear covers (side skirts) eliminating ear turbulence

  4. Szerokie okulary kolarskie z pojedynczą soczewką (`glasses_pro.glb`):
     - Oversized cylindrical toric shield eyewear (Sutro / Speedcraft style)
     - Wide cylindrical single-piece lens (140mm width, 55mm height) with brow vents
     - Semi-rimless lightweight TR90 brow frame with ergonomic temple arms
     - Hydrophilic rubber nose pads and ear socks

All models are authored in head reference coordinates matching `cyclist_road.glb`
(cranium center at X=0.360, Y=0.0, Z=0.985) for zero-gap modular snapping,
and exported as binary glTF (.glb) files to `assets/3d/cyclists/`.

Compatible with Blender 3.6 LTS, 4.x, and 5.x+.
===============================================================================
"""

import math
import os
import sys
from typing import Callable, Dict, List, Optional, Tuple, Union

try:
    import bpy
    import bmesh
    from mathutils import Matrix, Vector
except ImportError:
    print("[ERROR] 'bpy' / 'mathutils' module not found. This script must be run within Blender:")
    print("        blender --background --python blender_scripts/generate_helmets_and_glasses.py")
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
    """Lofts a tube with elliptical cross-section along a 3D path."""
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
            ring.append(bm.verts.new(v_pos))

        rings.append(ring)

    loft_rings(bm, rings, cap_start=cap_start, cap_end=cap_end, material_index=material_index)
    return rings


# =============================================================================
# SPECIALIZED PBR MATERIALS FOR HELMETS & EYEWEAR
# =============================================================================

def create_eps_foam_material(
    name: str = "M_EPS_Foam",
    hex_color: str = "#18181B",
) -> bpy.types.Material:
    """
    Generates an authentic matte expanded polystyrene (EPS) shock-absorbing
    liner material with granular micro-pore surface texture.
    """
    mat = sm._get_or_create_material(name)
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf, _ = sm._get_or_create_output_nodes(mat)

    # Procedural micro-pore foam texture
    tex_coord = nodes.new("ShaderNodeTexCoord")
    tex_coord.location = (-750, 0)

    noise = nodes.new("ShaderNodeTexNoise")
    noise.name = "EPS_Grain"
    noise.location = (-500, 0)
    noise.inputs["Scale"].default_value = 220.0
    noise.inputs["Detail"].default_value = 5.0
    noise.inputs["Roughness"].default_value = 0.85

    bump = nodes.new("ShaderNodeBump")
    bump.name = "EPS_Bump"
    bump.location = (-220, 0)
    bump.inputs["Strength"].default_value = 0.18
    bump.inputs["Distance"].default_value = 0.0006

    links.new(tex_coord.outputs["Object"], noise.inputs["Vector"])
    links.new(noise.outputs["Fac"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])

    linear_col = sm.hex_to_linear_rgb(hex_color)
    sm._set_bsdf_socket(bsdf, "Base Color", linear_col)
    sm._set_bsdf_socket(bsdf, "Roughness", 0.88)
    sm._set_bsdf_socket(bsdf, "Metallic", 0.0)
    sm._set_bsdf_socket(bsdf, ["Specular IOR Level", "Specular"], 0.25)
    sm._set_bsdf_socket(bsdf, ["Coat Weight", "Clearcoat"], 0.0)

    return mat


def create_glasses_frame_material(
    hex_color: str = "#0F172A",
    name: str = "M_Glasses_Frame",
) -> bpy.types.Material:
    """
    Generates a durable, lightweight Grilamid TR90 composite sports eyewear
    frame material with a high-end satin lacquer finish.
    """
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)

    linear_col = sm.hex_to_linear_rgb(hex_color)
    sm._set_bsdf_socket(bsdf, "Base Color", linear_col)
    sm._set_bsdf_socket(bsdf, "Roughness", 0.28)
    sm._set_bsdf_socket(bsdf, "Metallic", 0.05)
    sm._set_bsdf_socket(bsdf, ["Coat Weight", "Clearcoat"], 0.40)
    sm._set_bsdf_socket(bsdf, ["Coat Roughness", "Clearcoat Roughness"], 0.06)

    return mat


def create_grip_rubber_material(
    hex_color: str = "#18181B",
    name: str = "M_Grip_Rubber",
) -> bpy.types.Material:
    """
    Generates a soft hydrophilic elastomer rubber material for cycling
    sunglasses nose pads, ear socks, and helmet dial grippers.
    """
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)

    linear_col = sm.hex_to_linear_rgb(hex_color)
    sm._set_bsdf_socket(bsdf, "Base Color", linear_col)
    sm._set_bsdf_socket(bsdf, "Roughness", 0.74)
    sm._set_bsdf_socket(bsdf, "Metallic", 0.0)
    sm._set_bsdf_socket(bsdf, ["Specular IOR Level", "Specular"], 0.35)

    return mat


def create_nylon_strap_material(
    hex_color: str = "#111827",
    name: str = "M_Nylon_Strap",
) -> bpy.types.Material:
    """
    Generates an ultralight woven nylon webbing strap material for helmet
    retention harnesses and chin clips.
    """
    mat = sm._get_or_create_material(name)
    bsdf, _ = sm._get_or_create_output_nodes(mat)

    linear_col = sm.hex_to_linear_rgb(hex_color)
    sm._set_bsdf_socket(bsdf, "Base Color", linear_col)
    sm._set_bsdf_socket(bsdf, "Roughness", 0.70)
    sm._set_bsdf_socket(bsdf, "Metallic", 0.0)
    sm._set_bsdf_socket(bsdf, ["Sheen Weight", "Sheen"], 0.6)

    return mat


# =============================================================================
# 1. VENTED ROAD HELMET MODEL GENERATOR (`helmet_vented.glb`)
# =============================================================================

def generate_vented_helmet_mesh(
    name: str = "Helmet_Vented",
    shell_color_hex: str = "#E10600",
) -> bpy.types.Object:
    """
    Procedurally models a lightweight, highly ventilated pro road helmet
    (Specialized S-Works Prevail 3 / Kask Valegro style):
      - Carved longitudinal aerodynamic ribs with deep airflow intake ports
      - Shock-absorbing internal EPS foam liner
      - Occipital micro-retention cradle dial at rear of head
      - Lightweight Y-straps with chin buckle
    """
    mat_shell = sm.create_glossy_frame_paint_material(shell_color_hex, name=f"M_Helmet_Shell_{shell_color_hex.lstrip('#')}")
    mat_eps = create_eps_foam_material()
    mat_carbon = sm.create_carbon_matte_material()
    mat_rubber = create_grip_rubber_material()
    mat_strap = create_nylon_strap_material()

    materials = [mat_shell, mat_eps, mat_carbon, mat_rubber, mat_strap]

    bm = bmesh.new()

    # Reference head coordinates: Cranium center at (0.360, 0.0, 0.985)
    p_head = Vector((0.360, 0.0, 0.985))
    p_brow = p_head + Vector((0.075, 0.0, 0.015))
    p_apex = p_head + Vector((0.000, 0.0, 0.078))
    p_occipital = p_head + Vector((-0.095, 0.0, -0.010))
    p_spoiler = p_head + Vector((-0.155, 0.0, 0.010))

    # 1. INTERNAL EPS FOAM LINER BASE
    # Ergonomic inner dome conforming to rider cranium
    eps_path = [p_brow + Vector((-0.010, 0.0, -0.005)), p_apex + Vector((0.0, 0.0, -0.015)), p_occipital]
    loft_tube_along_path(
        bm,
        eps_path,
        radius_x=lambda t: 0.072 - t * 0.006,
        radius_y=lambda t: 0.076 - t * 0.004,
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_pts=12,
        cap_start=True,
        cap_end=True,
        material_index=1,  # mat_eps
    )

    # 2. LONGITUDINAL AERODYNAMIC RIBS (CENTRAL & LATERAL RIBS)
    # Central spine rib running from brow over apex to rear spoiler
    central_rib_path = [
        p_brow,
        p_brow.lerp(p_apex, 0.5) + Vector((0.005, 0.0, 0.008)),
        p_apex + Vector((0.0, 0.0, 0.006)),
        p_apex.lerp(p_spoiler, 0.5) + Vector((-0.005, 0.0, 0.006)),
        p_spoiler,
    ]
    loft_tube_along_path(
        bm,
        central_rib_path,
        radius_x=lambda t: 0.016 if t < 0.8 else 0.008,
        radius_y=lambda t: 0.024 if t < 0.8 else 0.038,  # flares into rear spoiler
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_pts=10,
        cap_start=True,
        cap_end=True,
        material_index=0,  # mat_shell
    )

    # Lateral Left & Right Ribs (separated by open air channels)
    for side in [1.0, -1.0]:
        y_lat = side * 0.048
        p_lat_brow = p_brow + Vector((-0.015, y_lat * 0.8, -0.005))
        p_lat_apex = p_apex + Vector((-0.005, y_lat * 1.1, -0.002))
        p_lat_rear = p_spoiler + Vector((0.020, y_lat * 0.9, -0.015))

        lat_rib_path = [p_lat_brow, p_lat_apex, p_lat_rear]
        loft_tube_along_path(
            bm,
            lat_rib_path,
            radius_x=0.014,
            radius_y=0.016,
            lateral_hint=Vector((0.0, side, 0.0)),
            num_pts=10,
            cap_start=True,
            cap_end=True,
            material_index=0,  # mat_shell
        )

        # Outer Temple Rim Rib (Lower brow & ear clearance arch)
        p_rim_front = p_brow + Vector((-0.010, side * 0.065, -0.015))
        p_rim_temple = p_head + Vector((0.000, side * 0.082, -0.010))
        p_rim_rear = p_occipital + Vector((0.010, side * 0.055, -0.010))

        rim_path = [p_rim_front, p_rim_temple, p_rim_rear]
        loft_tube_along_path(
            bm,
            rim_path,
            radius_x=0.010,
            radius_y=0.012,
            lateral_hint=Vector((0.0, side, 0.0)),
            num_pts=8,
            cap_start=True,
            cap_end=True,
            material_index=0,  # mat_shell
        )

        # Transverse Carbon Reinforcement Aramid Arches (bridges spanning the vents)
        bridge_path = [
            p_apex + Vector((0.020, 0.0, 0.004)),
            p_lat_apex,
            p_rim_temple,
        ]
        loft_tube_along_path(
            bm,
            bridge_path,
            radius_x=0.005,
            radius_y=0.007,
            lateral_hint=Vector((0.0, side, 0.0)),
            num_pts=8,
            cap_start=True,
            cap_end=True,
            material_index=2,  # mat_carbon
        )

    # 3. OCCIPITAL RETENTION CRADLE & MICRO-DIAL
    p_cradle = p_occipital + Vector((-0.015, 0.0, -0.035))
    dial_rings = []
    for dx in [0.0, -0.006]:
        ring = []
        for s in range(10):
            ang = (s / 10.0) * 2.0 * math.pi
            dy = math.cos(ang) * 0.010
            dz = math.sin(ang) * 0.010
            ring.append(bm.verts.new(p_cradle + Vector((dx, dy, dz))))
        dial_rings.append(ring)
    loft_rings(bm, dial_rings, cap_start=True, cap_end=True, material_index=3)  # mat_rubber

    # 4. LIGHTWEIGHT RETENTION STRAPS & CHIN BUCKLE
    p_buckle = p_head + Vector((-0.030, 0.0, -0.095))
    for side in [1.0, -1.0]:
        p_strap_front = p_head + Vector((0.040, side * 0.075, -0.015))
        p_strap_rear = p_head + Vector((-0.050, side * 0.072, -0.015))

        # Y-strap front branch
        loft_tube_along_path(
            bm,
            [p_strap_front, p_buckle],
            radius_x=0.0012,
            radius_y=0.006,
            num_pts=6,
            material_index=4,  # mat_strap
        )
        # Y-strap rear branch
        loft_tube_along_path(
            bm,
            [p_strap_rear, p_buckle],
            radius_x=0.0012,
            radius_y=0.006,
            num_pts=6,
            material_index=4,  # mat_strap
        )

    # Assemble mesh object
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
# 2. AERO ROAD HELMET MODEL GENERATOR (`helmet_aero.glb`)
# =============================================================================

def generate_aero_helmet_mesh(
    name: str = "Helmet_Aero",
    shell_color_hex: str = "#0284C7",
) -> bpy.types.Object:
    """
    Procedurally models a modern aerodynamic road helmet for sprinters and
    flat classics (Specialized S-Works Evade 3 / Kask Utopia style):
      - Smooth enclosed drag-reduction crown
      - Strategic front NACA intake vents for guided cooling airflow
      - Kamm-tail truncated rear exhaust diffuser and spoiler
      - Sleek temple channels and contrast EPS undertray
    """
    mat_shell = sm.create_glossy_frame_paint_material(shell_color_hex, name=f"M_Helmet_Aero_{shell_color_hex.lstrip('#')}")
    mat_eps = create_eps_foam_material()
    mat_carbon = sm.create_carbon_matte_material()
    mat_rubber = create_grip_rubber_material()
    mat_strap = create_nylon_strap_material()

    materials = [mat_shell, mat_eps, mat_carbon, mat_rubber, mat_strap]

    bm = bmesh.new()

    p_head = Vector((0.360, 0.0, 0.985))
    p_brow = p_head + Vector((0.082, 0.0, 0.020))
    p_apex = p_head + Vector((0.005, 0.0, 0.076))
    p_kamm_top = p_head + Vector((-0.130, 0.0, 0.035))
    p_kamm_bot = p_head + Vector((-0.165, 0.0, 0.010))

    # 1. ENCLOSED AERODYNAMIC SHELL (TEARDROP TELESCOPING PROFILE)
    shell_path = [p_brow, p_brow.lerp(p_apex, 0.5), p_apex, p_apex.lerp(p_kamm_top, 0.5), p_kamm_top, p_kamm_bot]
    loft_tube_along_path(
        bm,
        shell_path,
        radius_x=lambda t: 0.078 if t < 0.45 else (0.078 - (t - 0.45) * 0.065),
        radius_y=lambda t: 0.086 if t < 0.45 else (0.086 - (t - 0.45) * 0.060),
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_pts=14,
        cap_start=True,
        cap_end=True,
        material_index=0,  # mat_shell
    )

    # 2. FRONTAL STRATEGIC NACA SCOOPS (Air Intakes)
    for side in [1.0, -1.0]:
        p_naca_start = p_brow + Vector((-0.015, side * 0.035, -0.005))
        p_naca_end = p_naca_start + Vector((-0.040, side * 0.010, 0.012))

        naca_path = [p_naca_start, p_naca_end]
        loft_tube_along_path(
            bm,
            naca_path,
            radius_x=0.006,
            radius_y=0.012,
            lateral_hint=Vector((0.0, side, 0.0)),
            num_pts=8,
            cap_start=True,
            cap_end=True,
            material_index=1,  # mat_eps (reveals dark intake cavity)
        )

    # 3. KAMM-TAIL REAR EXHAUST DIFFUSER (Truncated flat spoiler)
    p_diffuser_center = p_kamm_bot + Vector((-0.005, 0.0, 0.005))
    diffuser_rings = []
    for dx in [0.0, -0.008]:
        ring = []
        for s in range(12):
            ang = (s / 12.0) * 2.0 * math.pi
            dy = math.cos(ang) * 0.032
            dz = math.sin(ang) * 0.022
            ring.append(bm.verts.new(p_diffuser_center + Vector((dx, dy, dz))))
        diffuser_rings.append(ring)
    loft_rings(bm, diffuser_rings, cap_start=True, cap_end=True, material_index=2)  # mat_carbon

    # 4. LOWER EPS UNDERTRAY & EAR APERTURE RIM
    for side in [1.0, -1.0]:
        p_rim_start = p_brow + Vector((-0.008, side * 0.070, -0.018))
        p_rim_temple = p_head + Vector((0.000, side * 0.084, -0.012))
        p_rim_rear = p_kamm_bot + Vector((0.030, side * 0.045, -0.012))

        undertray_path = [p_rim_start, p_rim_temple, p_rim_rear]
        loft_tube_along_path(
            bm,
            undertray_path,
            radius_x=0.008,
            radius_y=0.010,
            lateral_hint=Vector((0.0, side, 0.0)),
            num_pts=8,
            cap_start=True,
            cap_end=True,
            material_index=1,  # mat_eps
        )

    # 5. RETENTION DIAL & NYLON STRAPS
    p_cradle = p_kamm_bot + Vector((0.040, 0.0, -0.040))
    dial_rings = []
    for dx in [0.0, -0.006]:
        ring = []
        for s in range(10):
            ang = (s / 10.0) * 2.0 * math.pi
            dy = math.cos(ang) * 0.009
            dz = math.sin(ang) * 0.009
            ring.append(bm.verts.new(p_cradle + Vector((dx, dy, dz))))
        dial_rings.append(ring)
    loft_rings(bm, dial_rings, cap_start=True, cap_end=True, material_index=3)  # mat_rubber

    p_buckle = p_head + Vector((-0.030, 0.0, -0.095))
    for side in [1.0, -1.0]:
        p_strap_front = p_head + Vector((0.040, side * 0.075, -0.015))
        p_strap_rear = p_head + Vector((-0.050, side * 0.072, -0.015))
        loft_tube_along_path(bm, [p_strap_front, p_buckle], radius_x=0.0012, radius_y=0.006, num_pts=6, material_index=4)
        loft_tube_along_path(bm, [p_strap_rear, p_buckle], radius_x=0.0012, radius_y=0.006, num_pts=6, material_index=4)

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
# 3. TIME TRIAL TEARDROP HELMET WITH VISOR (`helmet_tt.glb`)
# =============================================================================

def generate_tt_helmet_mesh(
    name: str = "Helmet_TT",
    shell_color_hex: str = "#1E293B",
    visor_tint_hex: str = "#FF4500",
) -> bpy.types.Object:
    """
    Procedurally models an extreme aerodynamic Time Trial teardrop helmet
    (Kask Bambino Pro / Giro Aerohead style):
      - Extended aerodynamic teardrop fairing tail resting towards rider's back
      - Integrated dichroic iridium magnetic aero shield visor
      - Lateral ear covers / side skirts eliminating turbulent vortex drag
      - Minimalist front micro-intake scoop
    """
    mat_shell = sm.create_glossy_frame_paint_material(shell_color_hex, name=f"M_Helmet_TT_{shell_color_hex.lstrip('#')}")
    mat_visor = sm.create_visor_iridium_material(tint_color=visor_tint_hex, name="M_TT_Visor_Iridium")
    mat_eps = create_eps_foam_material()
    mat_carbon = sm.create_carbon_matte_material()
    mat_rubber = create_grip_rubber_material()

    materials = [mat_shell, mat_visor, mat_eps, mat_carbon, mat_rubber]

    bm = bmesh.new()

    p_head = Vector((0.360, 0.0, 0.985))
    p_brow = p_head + Vector((0.085, 0.0, 0.015))
    p_apex = p_head + Vector((0.000, 0.0, 0.075))
    p_mid_tail = p_head + Vector((-0.140, 0.0, 0.025))
    p_tip_tail = p_head + Vector((-0.260, 0.0, -0.015))  # elongated 260mm teardrop fairing!

    # 1. ELONGATED TEARDROP FAIRING SHELL
    tail_path = [p_brow, p_brow.lerp(p_apex, 0.5), p_apex, p_apex.lerp(p_mid_tail, 0.5), p_mid_tail, p_mid_tail.lerp(p_tip_tail, 0.5), p_tip_tail]
    loft_tube_along_path(
        bm,
        tail_path,
        radius_x=lambda t: 0.080 if t < 0.35 else (0.080 - (t - 0.35) * 0.105),
        radius_y=lambda t: 0.088 if t < 0.35 else (0.088 - (t - 0.35) * 0.120),
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_pts=14,
        cap_start=True,
        cap_end=True,
        material_index=0,  # mat_shell
    )

    # 2. INTEGRATED PANORAMIC MAGNETIC DICHROIC VISOR
    # Visor curves across forehead, cheeks, and blends into ear covers
    p_visor_apex = p_brow + Vector((-0.010, 0.0, -0.015))
    visor_rings = []
    # 4 vertical bands from brow down to lower cheekline
    for dz_step in [0.015, -0.010, -0.035, -0.055]:
        ring = []
        for a_deg in range(-75, 80, 15):
            ang = math.radians(a_deg)
            # Toric cylindrical curvature
            vx = p_visor_apex.x + 0.050 * math.cos(ang) - 0.012 * (1.0 - math.cos(ang))
            vy = p_visor_apex.y + 0.074 * math.sin(ang)
            vz = p_visor_apex.z + dz_step - 0.008 * math.cos(ang)
            ring.append(bm.verts.new(Vector((vx, vy, vz))))
        visor_rings.append(ring)
    loft_rings(bm, visor_rings, cap_start=False, cap_end=False, material_index=1)  # mat_visor

    # 3. ENCLOSED EAR COVERS / LATERAL AERO SKIRTS
    for side in [1.0, -1.0]:
        p_skirt_top = p_head + Vector((-0.010, side * 0.082, 0.010))
        p_skirt_mid = p_head + Vector((-0.010, side * 0.076, -0.035))
        p_skirt_bot = p_head + Vector((-0.020, side * 0.068, -0.060))

        skirt_path = [p_skirt_top, p_skirt_mid, p_skirt_bot]
        loft_tube_along_path(
            bm,
            skirt_path,
            radius_x=0.035,
            radius_y=0.008,
            lateral_hint=Vector((0.0, side, 0.0)),
            num_pts=8,
            cap_start=True,
            cap_end=True,
            material_index=0,  # mat_shell
        )

    # 4. LOWER CARBON FAIRING LIP
    p_lip_start = p_mid_tail + Vector((0.0, 0.0, -0.025))
    p_lip_end = p_tip_tail + Vector((0.0, 0.0, -0.005))
    loft_tube_along_path(
        bm,
        [p_lip_start, p_lip_end],
        radius_x=0.006,
        radius_y=0.018,
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_pts=8,
        cap_start=True,
        cap_end=True,
        material_index=3,  # mat_carbon
    )

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
# 4. PRO CYCLING EYEWEAR (`glasses_pro.glb`)
# =============================================================================

def generate_pro_glasses_mesh(
    name: str = "Glasses_Pro",
    frame_color_hex: str = "#0F172A",
    lens_tint_hex: str = "#FF4500",
) -> bpy.types.Object:
    """
    Procedurally models oversized pro cycling shield sunglasses
    (Oakley Sutro Lite / 100% Speedcraft style):
      - Wide single cylindrical toric shield lens (140mm width, 55mm height)
      - Lightweight TR90 upper brow frame with aerodynamic brow vents
      - Semi-rimless frameless lower edge for maximum drops field of view
      - Ergonomic temple arms with hydrophilic rubber ear socks
      - Adjustable rubber nose pad bridge
    """
    mat_lens = sm.create_visor_iridium_material(tint_color=lens_tint_hex, name=f"M_Glasses_Lens_{lens_tint_hex.lstrip('#')}")
    mat_frame = create_glasses_frame_material(hex_color=frame_color_hex, name=f"M_Glasses_Frame_{frame_color_hex.lstrip('#')}")
    mat_rubber = create_grip_rubber_material()

    materials = [mat_lens, mat_frame, mat_rubber]

    bm = bmesh.new()

    # Center of cylindrical lens curvature (relative to head origin)
    p_lens_origin = Vector((0.340, 0.0, 0.980))
    r_cyl = 0.068  # 68mm optical cylinder radius

    # 1. OVERSIZED CYLINDRICAL TORIC SHIELD LENS
    # 4 height bands: top brow (Z=+0.025) down to lower cheek clearance (Z=-0.030)
    lens_rings = []
    for dz in [0.025, 0.008, -0.012, -0.030]:
        ring = []
        for a_deg in range(-65, 70, 15):
            ang = math.radians(a_deg)
            # Toric cylindrical curvature (R=68mm) with aerodynamic rake angle (8°)
            vx = p_lens_origin.x + r_cyl * math.cos(ang) + dz * 0.12
            vy = p_lens_origin.y + (r_cyl + 0.004) * math.sin(ang)
            vz = p_lens_origin.z + dz
            ring.append(bm.verts.new(Vector((vx, vy, vz))))
        lens_rings.append(ring)
    loft_rings(bm, lens_rings, cap_start=False, cap_end=False, material_index=0)  # mat_lens

    # 2. UPPER BROW FRAME (TR90 Composite Top Bar)
    # Follows top curve of the lens
    brow_pts = []
    for a_deg in range(-68, 73, 12):
        ang = math.radians(a_deg)
        vx = p_lens_origin.x + r_cyl * math.cos(ang) + 0.025 * 0.12
        vy = p_lens_origin.y + (r_cyl + 0.004) * math.sin(ang)
        vz = p_lens_origin.z + 0.027
        brow_pts.append(Vector((vx, vy, vz)))

    loft_tube_along_path(
        bm,
        brow_pts,
        radius_x=0.0040,
        radius_y=0.0035,
        lateral_hint=Vector((0.0, 1.0, 0.0)),
        num_pts=8,
        cap_start=True,
        cap_end=True,
        material_index=1,  # mat_frame
    )

    # 3. ERGONOMIC TEMPLE ARMS WITH RUBBER EAR SOCKS
    for is_left in [True, False]:
        side = 1.0 if is_left else -1.0
        p_hinge = brow_pts[-1] if is_left else brow_pts[0]
        p_temple_mid = p_hinge + Vector((-0.045, side * 0.004, -0.002))
        p_temple_end = p_temple_mid + Vector((-0.040, -side * 0.008, -0.005))

        # Composite upper arm
        arm_path = [p_hinge, p_temple_mid]
        loft_tube_along_path(
            bm,
            arm_path,
            radius_x=0.0035,
            radius_y=0.0025,
            lateral_hint=Vector((0.0, side, 0.0)),
            num_pts=6,
            cap_start=True,
            cap_end=False,
            material_index=1,  # mat_frame
        )

        # Hydrophilic rubber ear sock (rear half)
        ear_sock_path = [p_temple_mid, p_temple_end]
        loft_tube_along_path(
            bm,
            ear_sock_path,
            radius_x=0.0042,
            radius_y=0.0032,
            lateral_hint=Vector((0.0, side, 0.0)),
            num_pts=8,
            cap_start=False,
            cap_end=True,
            material_index=2,  # mat_rubber
        )

    # 4. ADJUSTABLE RUBBER NOSE PAD BRIDGE
    p_nose_center = p_lens_origin + Vector((r_cyl, 0.0, -0.012))
    for side in [1.0, -1.0]:
        p_pad_root = p_nose_center + Vector((-0.004, side * 0.006, 0.008))
        p_pad_tip = p_pad_root + Vector((-0.008, side * 0.008, -0.015))

        pad_path = [p_pad_root, p_pad_tip]
        loft_tube_along_path(
            bm,
            pad_path,
            radius_x=0.0040,
            radius_y=0.0035,
            lateral_hint=Vector((0.0, side, 0.0)),
            num_pts=6,
            cap_start=True,
            cap_end=True,
            material_index=2,  # mat_rubber
        )

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

def export_headwear_model(
    obj: bpy.types.Object,
    output_glb_path: str,
) -> str:
    """Exports a single headwear object to binary glTF (.glb)."""
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


def export_all_helmets_and_glasses(
    output_dir: str = "assets/3d/cyclists",
    helmet_color_hex: str = "#E10600",
    glasses_color_hex: str = "#0F172A",
) -> Dict[str, str]:
    """
    Generates and exports all 4 pro cycling headwear assets:
      1. helmet_vented.glb
      2. helmet_aero.glb
      3. helmet_tt.glb
      4. glasses_pro.glb
    """
    # Clear existing mesh objects from scene
    for obj in [o for o in bpy.context.scene.objects if o.type == "MESH"]:
        bpy.data.objects.remove(obj, do_unlink=True)

    print("\n" + "=" * 75)
    print("PRO PELOTON MANAGER: GENERATING PRO CYCLING HELMETS & GLASSES")
    print("=" * 75)

    os.makedirs(output_dir, exist_ok=True)
    exported_files = {}

    # 1. Vented Helmet
    obj_vented = generate_vented_helmet_mesh(name="Helmet_Vented", shell_color_hex=helmet_color_hex)
    p_vented = os.path.join(output_dir, "helmet_vented.glb")
    exported_files["vented"] = export_headwear_model(obj_vented, p_vented)
    bpy.data.objects.remove(obj_vented, do_unlink=True)

    # 2. Aero Helmet
    obj_aero = generate_aero_helmet_mesh(name="Helmet_Aero", shell_color_hex=helmet_color_hex)
    p_aero = os.path.join(output_dir, "helmet_aero.glb")
    exported_files["aero"] = export_headwear_model(obj_aero, p_aero)
    bpy.data.objects.remove(obj_aero, do_unlink=True)

    # 3. TT Teardrop Helmet
    obj_tt = generate_tt_helmet_mesh(name="Helmet_TT", shell_color_hex=helmet_color_hex)
    p_tt = os.path.join(output_dir, "helmet_tt.glb")
    exported_files["tt"] = export_headwear_model(obj_tt, p_tt)
    bpy.data.objects.remove(obj_tt, do_unlink=True)

    # 4. Pro Glasses
    obj_glasses = generate_pro_glasses_mesh(name="Glasses_Pro", frame_color_hex=glasses_color_hex)
    p_glasses = os.path.join(output_dir, "glasses_pro.glb")
    exported_files["glasses"] = export_headwear_model(obj_glasses, p_glasses)
    bpy.data.objects.remove(obj_glasses, do_unlink=True)

    print("=" * 75 + "\n")
    return exported_files


# =============================================================================
# CLI EXECUTION ENTRY POINT
# =============================================================================

if __name__ == "__main__":
    out_dir = "assets/3d/cyclists"
    for idx, arg in enumerate(sys.argv):
        if arg in ["--output-dir", "-o"] and idx + 1 < len(sys.argv):
            out_dir = sys.argv[idx + 1]

    color = "#E10600"
    for idx, arg in enumerate(sys.argv):
        if arg in ["--color", "-c"] and idx + 1 < len(sys.argv):
            color = sys.argv[idx + 1]

    files = export_all_helmets_and_glasses(
        output_dir=out_dir,
        helmet_color_hex=color,
    )

    sm.setup_zwift_studio_lighting()
    print(f"[SUCCESS] All 4 headwear assets generated: {files}")

