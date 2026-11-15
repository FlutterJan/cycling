"""
===============================================================================
PRO PELOTON MANAGER - PROCEDURAL ROAD WHEELSET GENERATOR
===============================================================================
Blender Python API (bpy) script that procedurally generates 4 distinct variants
of high-performance 700c carbon road racing wheels:
  1. wheel_35mm.glb  - Low-profile climbing wheelset (35mm rim depth)
  2. wheel_50mm.glb  - All-round versatile aerodynamic wheelset (50mm rim depth)
  3. wheel_65mm.glb  - Deep-section sprint/breakaway wheelset (65mm rim depth)
  4. wheel_disc.glb  - Full TT lenticular aerodynamic solid disc wheel

Every wheel includes:
  - 700c x 28mm road tire with dual-tone tan-wall cotton casing
  - Aerodynamic U-shaped carbon rim (or lenticular carbon disc shell)
  - Straight-pull / 2-cross flat bladed aero spokes (Sapim CX-Ray style, 24 spokes)
  - Disc brake hub with 12mm thru-axle end caps
  - Ventilated Galfer Wave-style disc brake rotor (160mm) with laser-cut cooling windows
  - PBR material assignments from `style_and_materials.py`

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
    print("        blender --background --python blender_scripts/generate_wheelsets.py")
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
# WHEEL PROCEDURAL COMPONENT BUILDERS (TIRE, RIM, HUB, ROTOR, SPOKES, DISC)
# =============================================================================

def build_tire_mesh(
    bm: bmesh.types.BMesh,
    r_bead: float = 0.311,
    r_outer: float = 0.340,
    tire_width: float = 0.028,
    num_circum: int = 40,
    num_cross: int = 10,
    material_index: int = 1,
) -> None:
    """
    Constructs a 700c x 28mm road racing tire wrapping over the rim bead.
    """
    half_w = tire_width * 0.5
    r_center = (r_bead + r_outer) * 0.5
    h_radius = (r_outer - r_bead) * 0.5

    # 2D cross-section points in (R, Y) plane
    pts_cross = []
    # Semi-elliptical outer tread crown and sidewalls down to rim bead
    for i in range(num_cross):
        # Angle from -pi/2 (left bead) up through crown to +pi/2 (right bead)
        t = i / float(num_cross - 1)
        angle = -math.pi * 0.5 + t * math.pi
        r_val = r_center + h_radius * math.cos(angle)
        y_val = half_w * math.sin(angle)
        pts_cross.append((r_val, y_val))

    # Inner bead closure points
    pts_cross.append((r_bead - 0.002, half_w * 0.70))
    pts_cross.append((r_bead - 0.002, -half_w * 0.70))

    n_cross = len(pts_cross)

    # Revolve around lateral Y axis
    rings = []
    for k in range(num_circum):
        theta = (k / float(num_circum)) * 2.0 * math.pi
        cos_t = math.cos(theta)
        sin_t = math.sin(theta)
        ring = []
        for (r_val, y_val) in pts_cross:
            pos = Vector((r_val * cos_t, y_val, r_val * sin_t))
            ring.append(bm.verts.new(pos))
        rings.append(ring)

    # Connect quad faces
    for k in range(num_circum):
        k_next = (k + 1) % num_circum
        r1 = rings[k]
        r2 = rings[k_next]
        for i in range(n_cross):
            i_next = (i + 1) % n_cross
            try:
                f = bm.faces.new([r1[i], r1[i_next], r2[i_next], r2[i]])
                f.material_index = material_index
            except ValueError:
                pass


def build_rim_mesh(
    bm: bmesh.types.BMesh,
    rim_depth: float,
    r_bead: float = 0.311,
    rim_outer_width: float = 0.028,
    num_circum: int = 40,
    material_index: int = 0,
) -> float:
    """
    Constructs an aerodynamic toroidal U-shaped carbon fiber rim.
    Returns the inner spoke bed radius (r_inner).
    """
    r_inner = r_bead - rim_depth
    half_w_bead = rim_outer_width * 0.5
    half_w_max = half_w_bead * 1.08  # subtle toroidal aero bulge

    # 2D cross section along the U-shaped rim flank
    # From left bead -> left brake track -> max bulge -> nose -> right bulge -> right bead
    r_mid = r_inner + rim_depth * 0.55
    r_nose = r_inner

    pts_rim = [
        # Left bead hook
        (r_bead, -half_w_bead),
        (r_bead - 0.010, -half_w_bead * 1.02),
        (r_mid, -half_w_max),
        (r_inner + 0.008, -half_w_bead * 0.55),
        # Blunt aerodynamic U-nose at spoke bed
        (r_nose, -0.006),
        (r_nose, 0.006),
        # Right flank
        (r_inner + 0.008, half_w_bead * 0.55),
        (r_mid, half_w_max),
        (r_bead - 0.010, half_w_bead * 1.02),
        (r_bead, half_w_bead),
    ]

    n_pts = len(pts_rim)
    rings = []

    for k in range(num_circum):
        theta = (k / float(num_circum)) * 2.0 * math.pi
        cos_t = math.cos(theta)
        sin_t = math.sin(theta)
        ring = []
        for (r_val, y_val) in pts_rim:
            pos = Vector((r_val * cos_t, y_val, r_val * sin_t))
            ring.append(bm.verts.new(pos))
        rings.append(ring)

    for k in range(num_circum):
        k_next = (k + 1) % num_circum
        r1 = rings[k]
        r2 = rings[k_next]
        for i in range(n_pts - 1):
            try:
                f = bm.faces.new([r1[i], r1[i + 1], r2[i + 1], r2[i]])
                f.material_index = material_index
            except ValueError:
                pass

    return r_inner


def build_disc_wheel_mesh(
    bm: bmesh.types.BMesh,
    r_bead: float = 0.311,
    r_hub_flange: float = 0.030,
    num_circum: int = 40,
    material_index: int = 0,
) -> None:
    """
    Constructs a full carbon fiber aerodynamic lenticular disc wheel.
    Continuous carbon shell from rim bead to hub with subtle lentoid bulge.
    """
    radii = [r_bead, 0.270, 0.200, 0.130, 0.070, r_hub_flange]
    # Widths creating the lentoid convex aerodynamic sail profile
    widths = [0.014, 0.015, 0.018, 0.022, 0.026, 0.030]

    rings_l = []
    rings_r = []

    for r_val, w_val in zip(radii, widths):
        ring_l = []
        ring_r = []
        for k in range(num_circum):
            theta = (k / float(num_circum)) * 2.0 * math.pi
            cos_t = math.cos(theta)
            sin_t = math.sin(theta)
            ring_l.append(bm.verts.new(Vector((r_val * cos_t, -w_val, r_val * sin_t))))
            ring_r.append(bm.verts.new(Vector((r_val * cos_t, w_val, r_val * sin_t))))
        rings_l.append(ring_l)
        rings_r.append(ring_r)

    # Bridge concentric rings on both left and right disc faces
    for r_idx in range(len(radii) - 1):
        for k in range(num_circum):
            k_next = (k + 1) % num_circum
            try:
                # Left face
                f_l = bm.faces.new([
                    rings_l[r_idx][k],
                    rings_l[r_idx + 1][k],
                    rings_l[r_idx + 1][k_next],
                    rings_l[r_idx][k_next],
                ])
                f_l.material_index = material_index
            except ValueError:
                pass

            try:
                # Right face
                f_r = bm.faces.new([
                    rings_r[r_idx][k],
                    rings_r[r_idx][k_next],
                    rings_r[r_idx + 1][k_next],
                    rings_r[r_idx + 1][k],
                ])
                f_r.material_index = material_index
            except ValueError:
                pass


def build_hub_mesh(
    bm: bmesh.types.BMesh,
    num_circum: int = 24,
    material_index: int = 2,
) -> None:
    """
    Constructs a straight-pull centerlock disc brake hub with 12mm thru-axle end caps.
    """
    # Key stations along Y axis: (y_pos, radius)
    hub_profile = [
        (-0.050, 0.010),  # left axle end cap
        (-0.035, 0.012),
        (-0.028, 0.028),  # left spoke / rotor flange
        (-0.024, 0.028),
        (-0.018, 0.016),  # center barrel
        (0.018, 0.016),
        (0.024, 0.028),   # right flange
        (0.028, 0.028),
        (0.035, 0.012),
        (0.050, 0.010),   # right axle end cap
    ]

    rings = []
    for (y_val, r_val) in hub_profile:
        ring = []
        for s in range(num_circum):
            angle = (s / float(num_circum)) * 2.0 * math.pi
            pos = Vector((r_val * math.cos(angle), y_val, r_val * math.sin(angle)))
            ring.append(bm.verts.new(pos))
        rings.append(ring)

    for r_idx in range(len(rings) - 1):
        r1 = rings[r_idx]
        r2 = rings[r_idx + 1]
        for s in range(num_circum):
            s_next = (s + 1) % num_circum
            try:
                f = bm.faces.new([r1[s], r1[s_next], r2[s_next], r2[s]])
                f.material_index = material_index
            except ValueError:
                pass

    # Cap axle end holes
    try:
        f_left = bm.faces.new(list(reversed(rings[0])))
        f_left.material_index = material_index
        f_right = bm.faces.new(rings[-1])
        f_right.material_index = material_index
    except ValueError:
        pass


def build_galfer_wave_rotor_mesh(
    bm: bmesh.types.BMesh,
    y_pos: float = -0.020,
    rotor_diameter: float = 0.160,
    num_waves: int = 12,
    num_pts: int = 48,
    thickness: float = 0.0018,
    material_index: int = 2,
) -> None:
    """
    Constructs a ventilated Galfer Wave-style disc brake rotor (160mm)
    with scalloped wave outer perimeter and laser-cut cooling windows.
    """
    half_th = thickness * 0.5
    r_base = rotor_diameter * 0.5
    r_track_in = 0.063
    r_mount = 0.026

    # 1. BRAKING TRACK WITH SCALLOPED WAVES & VENTILATION SLOTS
    # -------------------------------------------------------------------------
    pts_track_outer = []
    pts_track_inner = []

    for i in range(num_pts):
        angle = (i / float(num_pts)) * 2.0 * math.pi
        # Wave modulation: peaks at 80mm, troughs at 73mm
        r_out = (r_base - 0.0035) + 0.0035 * math.cos(num_waves * angle)
        r_in = r_track_in + 0.0015 * math.cos(num_waves * angle)
        pts_track_outer.append((r_out * math.cos(angle), r_out * math.sin(angle)))
        pts_track_inner.append((r_in * math.cos(angle), r_in * math.sin(angle)))

    # Extrude track across front and back thickness layers
    verts_out_l = [bm.verts.new(Vector((p[0], y_pos - half_th, p[1]))) for p in pts_track_outer]
    verts_out_r = [bm.verts.new(Vector((p[0], y_pos + half_th, p[1]))) for p in pts_track_outer]
    verts_in_l = [bm.verts.new(Vector((p[0], y_pos - half_th, p[1]))) for p in pts_track_inner]
    verts_in_r = [bm.verts.new(Vector((p[0], y_pos + half_th, p[1]))) for p in pts_track_inner]

    for i in range(num_pts):
        i_next = (i + 1) % num_pts
        # Skip every 4th segment to form laser-cut radial ventilation windows
        if (i % 4) == 2:
            continue

        try:
            # Front track face
            f_front = bm.faces.new([verts_in_l[i], verts_out_l[i], verts_out_l[i_next], verts_in_l[i_next]])
            f_front.material_index = material_index
            # Back track face
            f_back = bm.faces.new([verts_in_r[i], verts_in_r[i_next], verts_out_r[i_next], verts_out_r[i]])
            f_back.material_index = material_index
            # Outer perimeter wave edge
            f_edge = bm.faces.new([verts_out_l[i], verts_out_r[i], verts_out_r[i_next], verts_out_l[i_next]])
            f_edge.material_index = material_index
        except ValueError:
            pass

    # 2. 6-ARM SPIDER CONNECTING TO CENTERLOCK / 6-BOLT MOUNT
    # -------------------------------------------------------------------------
    num_arms = 6
    for a_idx in range(num_arms):
        arm_angle = (a_idx / float(num_arms)) * 2.0 * math.pi
        cos_a = math.cos(arm_angle)
        sin_a = math.sin(arm_angle)
        perp_x = -sin_a
        perp_z = cos_a

        half_arm_w = 0.004

        # Arm root at mount
        p1 = Vector((r_mount * cos_a - half_arm_w * perp_x, y_pos, r_mount * sin_a - half_arm_w * perp_z))
        p2 = Vector((r_mount * cos_a + half_arm_w * perp_x, y_pos, r_mount * sin_a + half_arm_w * perp_z))
        # Arm tip at track
        p3 = Vector((r_track_in * cos_a + half_arm_w * 0.7 * perp_x, y_pos, r_track_in * sin_a + half_arm_w * 0.7 * perp_z))
        p4 = Vector((r_track_in * cos_a - half_arm_w * 0.7 * perp_x, y_pos, r_track_in * sin_a - half_arm_w * 0.7 * perp_z))

        v_l = [
            bm.verts.new(p1 + Vector((0.0, -half_th, 0.0))),
            bm.verts.new(p2 + Vector((0.0, -half_th, 0.0))),
            bm.verts.new(p3 + Vector((0.0, -half_th, 0.0))),
            bm.verts.new(p4 + Vector((0.0, -half_th, 0.0))),
        ]
        v_r = [
            bm.verts.new(p1 + Vector((0.0, half_th, 0.0))),
            bm.verts.new(p2 + Vector((0.0, half_th, 0.0))),
            bm.verts.new(p3 + Vector((0.0, half_th, 0.0))),
            bm.verts.new(p4 + Vector((0.0, half_th, 0.0))),
        ]

        try:
            f1 = bm.faces.new([v_l[0], v_l[1], v_l[2], v_l[3]])
            f1.material_index = material_index
            f2 = bm.faces.new([v_r[0], v_r[3], v_r[2], v_r[1]])
            f2.material_index = material_index
        except ValueError:
            pass

    # 3. CENTRAL MOUNTING RING
    # -------------------------------------------------------------------------
    mount_rings_l = []
    mount_rings_r = []
    for s in range(24):
        a = (s / 24.0) * 2.0 * math.pi
        mount_rings_l.append(bm.verts.new(Vector((r_mount * math.cos(a), y_pos - half_th, r_mount * math.sin(a)))))
        mount_rings_r.append(bm.verts.new(Vector((r_mount * math.cos(a), y_pos + half_th, r_mount * math.sin(a)))))

    for s in range(24):
        s_next = (s + 1) % 24
        try:
            f_m = bm.faces.new([mount_rings_l[s], mount_rings_r[s], mount_rings_r[s_next], mount_rings_l[s_next]])
            f_m.material_index = material_index
        except ValueError:
            pass


def build_bladed_spokes_mesh(
    bm: bmesh.types.BMesh,
    r_rim: float,
    num_spokes: int = 24,
    spoke_width: float = 0.0022,  # 2.2mm bladed aero width in rotation plane
    spoke_thick: float = 0.0009,  # 0.9mm aero thickness
    material_index: int = 2,
) -> None:
    """
    Constructs 24 flat aero bladed spokes (Sapim CX-Ray style) laced 2-cross
    from hub flanges to rim spoke bed.
    """
    half_sp = num_spokes // 2
    r_hub = 0.028

    half_w = spoke_width * 0.5
    half_t = spoke_thick * 0.5

    for side_idx, y_flange in enumerate([-0.028, 0.028]):
        for sp_idx in range(half_sp):
            # Base angle at hub
            base_angle = (sp_idx / float(half_sp)) * 2.0 * math.pi
            # 2-cross tangential angle offset alternating +/-
            cross_dir = 1.0 if (sp_idx % 2 == 0) else -1.0
            lacing_offset = cross_dir * (math.pi / float(half_sp)) * 1.6

            # Hub attachment point
            p_hub = Vector((r_hub * math.cos(base_angle), y_flange, r_hub * math.sin(base_angle)))

            # Rim attachment point
            rim_angle = base_angle + lacing_offset
            p_rim = Vector((r_rim * math.cos(rim_angle), 0.0, r_rim * math.sin(rim_angle)))

            # Spoke vector and coordinate frame
            sp_dir = (p_rim - p_hub).normalized()
            # Spoke blade width lies in wheel rotation plane (perpendicular to Y)
            sp_blade_norm = Vector((0.0, 1.0, 0.0)).cross(sp_dir).normalized()

            # 4 vertices at hub end
            v_h1 = bm.verts.new(p_hub - sp_blade_norm * half_w - Vector((0.0, half_t, 0.0)))
            v_h2 = bm.verts.new(p_hub + sp_blade_norm * half_w - Vector((0.0, half_t, 0.0)))
            v_h3 = bm.verts.new(p_hub + sp_blade_norm * half_w + Vector((0.0, half_t, 0.0)))
            v_h4 = bm.verts.new(p_hub - sp_blade_norm * half_w + Vector((0.0, half_t, 0.0)))

            # 4 vertices at rim end
            v_r1 = bm.verts.new(p_rim - sp_blade_norm * half_w - Vector((0.0, half_t, 0.0)))
            v_r2 = bm.verts.new(p_rim + sp_blade_norm * half_w - Vector((0.0, half_t, 0.0)))
            v_r3 = bm.verts.new(p_rim + sp_blade_norm * half_w + Vector((0.0, half_t, 0.0)))
            v_r4 = bm.verts.new(p_rim - sp_blade_norm * half_w + Vector((0.0, half_t, 0.0)))

            # Quad tube bridging spoke
            try:
                f1 = bm.faces.new([v_h1, v_h2, v_r2, v_r1])
                f1.material_index = material_index
                f2 = bm.faces.new([v_h2, v_h3, v_r3, v_r2])
                f2.material_index = material_index
                f3 = bm.faces.new([v_h3, v_h4, v_r4, v_r3])
                f3.material_index = material_index
                f4 = bm.faces.new([v_h4, v_h1, v_r1, v_r4])
                f4.material_index = material_index
            except ValueError:
                pass


# =============================================================================
# HIGH-LEVEL WHEEL VARIANT GENERATOR
# =============================================================================

def generate_road_wheel_mesh(
    name: str = "Wheel_50mm",
    rim_depth_mm: int = 50,
    is_disc_wheel: bool = False,
    tan_wall: bool = True,
) -> bpy.types.Object:
    """
    Procedurally creates a complete 700c road bicycle wheel:
      - 28mm tan-wall cotton casing racing tire
      - Carbon rim (or full solid lenticular disc)
      - Flat aero bladed spokes (unless disc wheel)
      - Straight-pull centerlock disc brake hub
      - 160mm Galfer Wave-style ventilated brake rotor
    """
    bm = bmesh.new()

    # 1. BUILD TIRE (700c x 28mm)
    build_tire_mesh(bm, r_bead=0.311, r_outer=0.340, tire_width=0.028, material_index=1)

    # 2. BUILD CARBON RIM OR FULL LENTICULAR DISC
    if is_disc_wheel:
        build_disc_wheel_mesh(bm, r_bead=0.311, r_hub_flange=0.030, material_index=0)
    else:
        depth_m = rim_depth_mm / 1000.0
        r_inner = build_rim_mesh(bm, rim_depth=depth_m, r_bead=0.311, material_index=0)
        # 3. BUILD BLADED AERO SPOKES (24 spokes)
        build_bladed_spokes_mesh(bm, r_rim=r_inner, num_spokes=24, material_index=2)

    # 4. BUILD DISC BRAKE HUB
    build_hub_mesh(bm, material_index=2)

    # 5. BUILD GALFER WAVE VENTILATED BRAKE ROTOR (160mm)
    build_galfer_wave_rotor_mesh(bm, y_pos=-0.020, rotor_diameter=0.160, material_index=2)

    # Finalize BMesh and create Blender Object
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)

    # Material Slot Setup
    mat_carbon = sm.create_carbon_matte_material()
    mat_tire = sm.create_tire_rubber_material(tan_wall=tan_wall)
    mat_rotor = sm.create_metal_rotor_material()

    sm.assign_material(obj, mat_carbon, slot_index=0)
    sm.assign_material(obj, mat_tire, slot_index=1)
    sm.assign_material(obj, mat_rotor, slot_index=2)

    # Apply Zwift-style smooth shading and clean geometry
    sm.apply_zwift_style(obj, auto_smooth_angle_deg=35.0)
    sm.clean_zwift_mesh(obj)

    return obj


# =============================================================================
# EXPORT PIPELINE FOR ALL 4 WHEELSET VARIANTS
# =============================================================================

def export_wheel_variant(
    variant_name: str,
    rim_depth_mm: int,
    is_disc: bool = False,
    output_dir: str = "assets/3d/bikes",
) -> Tuple[bpy.types.Object, str]:
    """
    Builds a single wheel variant and exports it to binary glTF (.glb).
    """
    # Clear existing mesh objects from scene
    for obj in [o for o in bpy.context.scene.objects if o.type == "MESH"]:
        bpy.data.objects.remove(obj, do_unlink=True)

    obj = generate_road_wheel_mesh(
        name=variant_name,
        rim_depth_mm=rim_depth_mm,
        is_disc_wheel=is_disc,
        tan_wall=True,
    )

    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj

    os.makedirs(output_dir, exist_ok=True)
    glb_filename = f"{variant_name}.glb"
    abs_output_path = os.path.abspath(os.path.join(output_dir, glb_filename))

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
    print(f"     [OK] '{glb_filename}' exported successfully ({file_size_kb:.1f} KB, {len(obj.data.polygons)} polys)")

    return obj, abs_output_path


def generate_all_wheelsets(output_dir: str = "assets/3d/bikes") -> Dict[str, str]:
    """
    Generates all 4 standard road wheelset variants:
      1. wheel_35mm.glb (Climbing Low Profile)
      2. wheel_50mm.glb (All-Round Versatile Aero)
      3. wheel_65mm.glb (Deep Sprint / Breakaway)
      4. wheel_disc.glb (Full Time Trial Lenticular Disc)
    """
    print("\n" + "=" * 75)
    print("PRO PELOTON MANAGER: GENERATING 4 3D ROAD WHEELSET VARIANTS")
    print("=" * 75)
    print(f"Output Directory: '{os.path.abspath(output_dir)}'")

    variants = [
        ("wheel_35mm", 35, False),
        ("wheel_50mm", 50, False),
        ("wheel_65mm", 65, False),
        ("wheel_disc", 0, True),
    ]

    exported_files = {}
    for var_name, depth_mm, is_disc in variants:
        _, file_path = export_wheel_variant(var_name, depth_mm, is_disc=is_disc, output_dir=output_dir)
        exported_files[var_name] = file_path

    print("=" * 75 + "\n")
    return exported_files


# =============================================================================
# CLI EXECUTION ENTRY POINT
# =============================================================================

if __name__ == "__main__":
    out_dir = "assets/3d/bikes"
    for idx, arg in enumerate(sys.argv):
        if arg in ["--output", "-o"] and idx + 1 < len(sys.argv):
            out_dir = sys.argv[idx + 1]

    results = generate_all_wheelsets(output_dir=out_dir)
    print(f"[SUCCESS] All {len(results)} wheelset models generated and exported to '{out_dir}'.")

