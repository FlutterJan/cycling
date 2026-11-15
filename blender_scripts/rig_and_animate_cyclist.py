"""
===============================================================================
PRO PELOTON MANAGER - PROCEDURAL CYCLIST RIGGING & ANIMATION SYSTEM
===============================================================================
Blender Python API (bpy) script that creates a humanoid cycling armature,
skins the 3D cyclist mesh with smooth normalized vertex weights, and
procedurally keyframes 6 looped and situational cycling animations with
analytical inverse kinematics (IK):

  1. `Pedal_Seated_Hoods`:
     - Standard in-peloton cruising tempo (90 RPM cadence, 30 frames)
     - Hands on hoods, relaxed road spine angle, smooth circular pedaling
  2. `Pedal_Seated_Drops_Aero`:
     - Aggressive flat aerodynamic tuck (driving breakaway pace)
     - Hands in drops (lower by 75mm), flat back, tucked elbows
  3. `Pedal_Standing_Climb`:
     - Out of the saddle climbing ("taniec na pedałach" / dancing on pedals)
     - Hips raised and swaying laterally over downstrokes with counter-roll
  4. `Pedal_Sprint_Max`:
     - 1600W violent bunch sprint in drops
     - Explosive cadence, intense upper-body bar pulling and lateral whip
  5. `Drink_Bidon`:
     - Reaching down to bottle cage, lifting bidon to mouth, tilting head to drink
     - Steady pedaling with left hand anchored on hood
  6. `Victory_Salute`:
     - Crossing finish line: coasting pedals, upright torso, triumphant V-arms

Exported as binary glTF (.glb) to: `assets/3d/riders/cyclist_animated.glb`.
Retains all 9 PBR materials and 3 morph target shape keys (Climber, AllRounder, Sprinter).

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
    from mathutils import Matrix, Quaternion, Vector
except ImportError:
    print("[ERROR] 'bpy' / 'mathutils' module not found. This script must be run within Blender:")
    print("        blender --background --python blender_scripts/rig_and_animate_cyclist.py")
    sys.exit(1)

# Ensure local script directory is in sys.path
script_dir = os.path.dirname(os.path.abspath(__file__))
if script_dir not in sys.path:
    sys.path.insert(0, script_dir)

try:
    import generate_cyclist_mesh as gcm
    import style_and_materials as sm
except ImportError:
    print(f"[ERROR] Could not import 'generate_cyclist_mesh' or 'style_and_materials' from '{script_dir}'.")
    sys.exit(1)


# =============================================================================
# ARMATURE CONSTRUCTION (HUMANOID CYCLING SKELETON)
# =============================================================================

DEFORM_BONES = [
    "hips",
    "spine",
    "chest",
    "neck",
    "head",
    "shoulder.L", "upper_arm.L", "forearm.L", "hand.L",
    "shoulder.R", "upper_arm.R", "forearm.R", "hand.R",
    "thigh.L", "shin.L", "foot.L",
    "thigh.R", "shin.R", "foot.R",
]


def build_cyclist_armature(
    name: str = "Cyclist_Armature",
) -> bpy.types.Object:
    """
    Constructs a 19-bone humanoid cycling armature perfectly aligned with
    the rest pose of the 3D cyclist mesh:
      - Pelvis / Hips resting above saddle at (-0.160, 0.0, 0.900)
      - Spine and chest arched forward into road cycling stance
      - Arms reaching to the brake hoods at (0.525, ±0.168, 0.695)
      - Right leg extended forward-down, Left leg flexed up-rear
    """
    arm_data = bpy.data.armatures.new(f"{name}_Data")
    arm_obj = bpy.data.objects.new(name, arm_data)
    bpy.context.scene.collection.objects.link(arm_obj)
    bpy.context.view_layer.objects.active = arm_obj

    bpy.ops.object.mode_set(mode="EDIT")
    eb = arm_data.edit_bones

    # 1. ROOT & CORE SPINE
    b_root = eb.new("root")
    b_root.head = Vector((0.000, 0.000, 0.270))
    b_root.tail = Vector((0.000, 0.000, 0.380))

    b_hips = eb.new("hips")
    b_hips.parent = b_root
    b_hips.head = Vector((-0.160, 0.000, 0.900))
    b_hips.tail = Vector((-0.060, 0.000, 0.940))

    b_spine = eb.new("spine")
    b_spine.parent = b_hips
    b_spine.head = Vector((-0.060, 0.000, 0.940))
    b_spine.tail = Vector((0.080, 0.000, 0.920))

    b_chest = eb.new("chest")
    b_chest.parent = b_spine
    b_chest.head = Vector((0.080, 0.000, 0.920))
    b_chest.tail = Vector((0.240, 0.000, 0.880))

    b_neck = eb.new("neck")
    b_neck.parent = b_chest
    b_neck.head = Vector((0.240, 0.000, 0.880))
    b_neck.tail = Vector((0.320, 0.000, 0.940))

    b_head = eb.new("head")
    b_head.parent = b_neck
    b_head.head = Vector((0.320, 0.000, 0.940))
    b_head.tail = Vector((0.420, 0.000, 1.020))

    # 2. UPPER LIMBS (LEFT & RIGHT ARMS)
    for is_left in [True, False]:
        side = 1.0 if is_left else -1.0
        suffix = "L" if is_left else "R"

        b_shoulder = eb.new(f"shoulder.{suffix}")
        b_shoulder.parent = b_chest
        b_shoulder.head = Vector((0.200, side * 0.040, 0.880))
        b_shoulder.tail = Vector((0.230, side * 0.165, 0.860))

        b_upper = eb.new(f"upper_arm.{suffix}")
        b_upper.parent = b_shoulder
        b_upper.head = Vector((0.230, side * 0.165, 0.860))
        b_upper.tail = Vector((0.340, side * 0.200, 0.730))

        b_forearm = eb.new(f"forearm.{suffix}")
        b_forearm.parent = b_upper
        b_forearm.head = Vector((0.340, side * 0.200, 0.730))
        b_forearm.tail = Vector((0.470, side * 0.170, 0.705))

        b_hand = eb.new(f"hand.{suffix}")
        b_hand.parent = b_forearm
        b_hand.head = Vector((0.470, side * 0.170, 0.705))
        b_hand.tail = Vector((0.530, side * 0.168, 0.695))

    # 3. LOWER LIMBS (LEGS)
    # Left leg in flexed recovery rest pose
    b_thigh_l = eb.new("thigh.L")
    b_thigh_l.parent = b_hips
    b_thigh_l.head = Vector((-0.160, 0.095, 0.900))
    b_thigh_l.tail = Vector((0.184, 0.126, 0.697))

    b_shin_l = eb.new("shin.L")
    b_shin_l.parent = b_thigh_l
    b_shin_l.head = Vector((0.184, 0.126, 0.697))
    b_shin_l.tail = Vector((-0.122, 0.096, 0.440))

    b_foot_l = eb.new("foot.L")
    b_foot_l.parent = b_shin_l
    b_foot_l.head = Vector((-0.122, 0.096, 0.440))
    b_foot_l.tail = Vector((-0.060, 0.096, 0.360))

    # Right leg in extended downstroke rest pose
    b_thigh_r = eb.new("thigh.R")
    b_thigh_r.parent = b_hips
    b_thigh_r.head = Vector((-0.160, -0.095, 0.900))
    b_thigh_r.tail = Vector((0.105, -0.121, 0.600))

    b_shin_r = eb.new("shin.R")
    b_shin_r.parent = b_thigh_r
    b_shin_r.head = Vector((0.105, -0.121, 0.600))
    b_shin_r.tail = Vector((0.110, -0.096, 0.200))

    b_foot_r = eb.new("foot.R")
    b_foot_r.parent = b_shin_r
    b_foot_r.head = Vector((0.110, -0.096, 0.200))
    b_foot_r.tail = Vector((0.180, -0.096, 0.130))

    bpy.ops.object.mode_set(mode="OBJECT")
    return arm_obj


# =============================================================================
# AUTOMATIC MESH SKINNING & VERTEX WEIGHT GENERATION
# =============================================================================

def bind_and_skin_cyclist_mesh(
    cyclist_obj: bpy.types.Object,
    arm_obj: bpy.types.Object,
) -> None:
    """
    Parents the cyclist mesh to the armature, creates an Armature modifier,
    and computes smooth, normalized vertex weights based on anatomical domains
    and perpendicular distance to bone line segments.
    """
    # Parent mesh to armature
    cyclist_obj.parent = arm_obj

    # Armature modifier
    mod = cyclist_obj.modifiers.new(name="Armature", type="ARMATURE")
    mod.object = arm_obj
    mod.use_vertex_groups = True

    # Pre-calculate bone segments in rest pose
    arm_data = arm_obj.data
    bone_segments: Dict[str, Tuple[Vector, Vector, float]] = {}
    for b_name in DEFORM_BONES:
        bone = arm_data.bones.get(b_name)
        if bone:
            h = bone.head_local
            t = bone.tail_local
            bone_segments[b_name] = (h, t, (t - h).length)

    # Create vertex groups on mesh
    vgroups: Dict[str, bpy.types.VertexGroup] = {}
    for b_name in DEFORM_BONES:
        vg = cyclist_obj.vertex_groups.get(b_name)
        if not vg:
            vg = cyclist_obj.vertex_groups.new(name=b_name)
        vgroups[b_name] = vg

    # Distance to line segment helper
    def dist_to_segment(p: Vector, h: Vector, t: Vector) -> float:
        v = t - h
        l2 = v.length_squared
        if l2 < 1e-8:
            return (p - h).length
        proj = max(0.0, min(1.0, (p - h).dot(v) / l2))
        closest = h + v * proj
        return (p - closest).length

    # Calculate weights per vertex
    mesh = cyclist_obj.data
    for v in mesh.vertices:
        p = v.co
        weights: Dict[str, float] = {}

        # 1. Anatomical filtering to prevent cross-lateral bleeding
        is_left_zone = p.y > 0.015
        is_right_zone = p.y < -0.015

        # Head / Helmet / Visor
        if p.z > 0.94 and p.x > 0.27:
            weights["head"] = 1.0
        # Shoes & Ankle Dials
        elif is_left_zone and p.z < 0.46 and p.x < 0.02:
            weights["foot.L"] = 1.0
        elif is_right_zone and p.z < 0.25 and p.x > 0.02:
            weights["foot.R"] = 1.0
        else:
            # Multi-bone weighted distance falloff
            for b_name, (h, t, _) in bone_segments.items():
                # Skip opposite lateral limbs
                if is_left_zone and b_name.endswith(".R"):
                    continue
                if is_right_zone and b_name.endswith(".L"):
                    continue

                d = dist_to_segment(p, h, t)
                # Weight falloff
                if d < 0.22:
                    w = 1.0 / (d * d + 0.004)
                    weights[b_name] = w

        # Normalize weights
        total_w = sum(weights.values())
        if total_w < 1e-6:
            # Default fallback to nearest core bone
            weights["hips"] = 1.0
            total_w = 1.0

        for b_name, w in weights.items():
            norm_w = w / total_w
            if norm_w > 0.02:  # 2% weight threshold
                vgroups[b_name].add([v.index], norm_w, "REPLACE")


# =============================================================================
# ANALYTICAL INVERSE KINEMATICS (IK) PEDALING & LIMB SOLVER
# =============================================================================

def solve_pedal_stroke_ik(
    crank_angle_rad: float,
    is_left: bool,
    p_bb: Vector = Vector((0.000, 0.000, 0.270)),
    crank_length: float = 0.1725,
    q_factor_half: float = 0.096,
) -> Tuple[Vector, Vector, float]:
    """
    Computes exact 3D coordinates of the pedal spindle and ankle joint,
    along with the sagittal ankling tilt angle across 360° crank rotation.
    """
    ang = crank_angle_rad + (math.pi if is_left else 0.0)
    side = 1.0 if is_left else -1.0

    # Pedal spindle position on the crank circle
    pedal_x = p_bb.x + crank_length * math.sin(ang)
    pedal_y = side * q_factor_half
    pedal_z = p_bb.z + crank_length * math.cos(ang)
    p_pedal = Vector((pedal_x, pedal_y, pedal_z))

    # Dynamic ankling biomechanics (heel drops on power stroke, toe dips on recovery)
    ankle_pitch_rad = -0.15 * math.sin(ang)  # ~8.5 degrees ankling oscillation
    ankle_offset_x = -0.015 * math.sin(ang)
    ankle_offset_z = 0.052 + 0.008 * math.cos(ang)

    p_ankle = p_pedal + Vector((ankle_offset_x, 0.0, ankle_offset_z))
    return p_pedal, p_ankle, ankle_pitch_rad


def solve_leg_joint_positions(
    p_hip: Vector,
    p_ankle: Vector,
    femur_len: float = 0.400,
    tibia_len: float = 0.400,
    lateral_flare: float = 0.025,
) -> Vector:
    """
    Computes knee joint position using analytical 2-link spatial inverse
    kinematics, ensuring smooth forward patella tracking without snapping.
    """
    d_vec = p_ankle - p_hip
    d = max(0.10, min(femur_len + tibia_len - 0.005, d_vec.length))

    # Midpoint of hip-ankle line
    m = p_hip.lerp(p_ankle, 0.5)

    # Knee height perpendicular to hip-ankle vector
    h = math.sqrt(max(0.0, femur_len * femur_len - (d * 0.5) * (d * 0.5)))

    # Sagittal forward unit vector
    d_norm = d_vec.normalized()
    fwd = Vector((-d_norm.z, 0.0, d_norm.x))
    if fwd.x < 0.0:
        fwd = -fwd
    if fwd.length > 1e-4:
        fwd.normalize()
    else:
        fwd = Vector((1.0, 0.0, 0.0))

    # Lateral clearance
    lat = Vector((0.0, math.copysign(lateral_flare, p_hip.y), 0.0))
    p_knee = m + fwd * h + lat
    return p_knee


def solve_arm_joint_positions(
    p_shoulder: Vector,
    p_hand: Vector,
    upper_arm_len: float = 0.230,
    forearm_len: float = 0.230,
    elbow_flare: float = 0.035,
) -> Vector:
    """Computes elbow joint position tucked aerodynamically."""
    d_vec = p_hand - p_shoulder
    d = max(0.08, min(upper_arm_len + forearm_len - 0.005, d_vec.length))
    m = p_shoulder.lerp(p_hand, 0.5)
    h = math.sqrt(max(0.0, upper_arm_len * upper_arm_len - (d * 0.5) * (d * 0.5)))

    d_norm = d_vec.normalized()
    down = Vector((0.0, 0.0, -1.0))
    elbow_dir = down - (down.dot(d_norm)) * d_norm
    if elbow_dir.length > 1e-4:
        elbow_dir.normalize()
    else:
        elbow_dir = Vector((0.0, 0.0, -1.0))

    lat = Vector((0.0, math.copysign(elbow_flare, p_shoulder.y), 0.0))
    p_elbow = m + elbow_dir * h + lat
    return p_elbow


# =============================================================================
# BONE ORIENTATION MATRIX HELPERS
# =============================================================================

def set_bone_endpoints(
    pbone: bpy.types.PoseBone,
    p_head: Vector,
    p_tail: Vector,
    up_hint: Vector = Vector((0.0, 0.0, 1.0)),
) -> None:
    """Sets a pose bone's world transform matrix from desired head and tail endpoints."""
    v_dir = p_tail - p_head
    if v_dir.length < 1e-6:
        return
    v_dir.normalize()

    # In Blender, bone rest direction is along the local +Y axis
    rot = Vector((0.0, 1.0, 0.0)).rotation_difference(v_dir)
    mat = Matrix.Translation(p_head) @ rot.to_matrix().to_4x4()
    pbone.matrix = mat


# =============================================================================
# ACTION GENERATORS (6 CYCLING ANIMATIONS)
# =============================================================================

def create_animation_action(
    arm_obj: bpy.types.Object,
    action_name: str,
) -> bpy.types.Action:
    """Creates a new Action, creates its NLA track, and enables fake user."""
    act = bpy.data.actions.new(action_name)
    act.use_fake_user = True
    if not arm_obj.animation_data:
        arm_obj.animation_data_create()
    arm_obj.animation_data.action = act
    return act


def push_action_to_nla(
    arm_obj: bpy.types.Object,
    action: bpy.types.Action,
    start_frame: int = 1,
) -> None:
    """Pushes an Action onto an NLA track so glTF exporter bakes all actions."""
    track = arm_obj.animation_data.nla_tracks.new()
    track.name = action.name
    track.strips.new(action.name, start_frame, action)


# -----------------------------------------------------------------------------
# 1. PEDAL_SEATED_HOODS (Normal peloton cruising tempo, 90 RPM)
# -----------------------------------------------------------------------------
def animate_pedal_seated_hoods(arm_obj: bpy.types.Object, n_frames: int = 30) -> bpy.types.Action:
    act = create_animation_action(arm_obj, "Pedal_Seated_Hoods")
    pb = arm_obj.pose.bones

    p_saddle = Vector((-0.160, 0.000, 0.900))
    p_hand_l = Vector((0.525, 0.168, 0.695))
    p_hand_r = Vector((0.525, -0.168, 0.695))

    for frame in range(1, n_frames + 1):
        t = (frame - 1) / float(n_frames)
        theta = t * 2.0 * math.pi

        # Pelvic cadence sway
        p_hip = p_saddle + Vector((0.0, 0.006 * math.sin(theta), 0.003 * math.cos(2.0 * theta)))
        p_hip_l = p_hip + Vector((0.0, 0.095, 0.0))
        p_hip_r = p_hip + Vector((0.0, -0.095, 0.0))

        # Core spine
        set_bone_endpoints(pb["hips"], p_hip, p_hip + Vector((0.100, 0.0, 0.040)))
        set_bone_endpoints(pb["spine"], p_hip + Vector((0.100, 0.0, 0.040)), Vector((0.080, 0.0, 0.920)))
        set_bone_endpoints(pb["chest"], Vector((0.080, 0.0, 0.920)), Vector((0.240, 0.0, 0.880)))
        set_bone_endpoints(pb["neck"], Vector((0.240, 0.0, 0.880)), Vector((0.320, 0.0, 0.940)))
        set_bone_endpoints(pb["head"], Vector((0.320, 0.0, 0.940)), Vector((0.420, 0.0, 1.020)))

        # Legs IK
        _, p_ank_l, _ = solve_pedal_stroke_ik(theta, is_left=True)
        _, p_ank_r, _ = solve_pedal_stroke_ik(theta, is_left=False)
        p_knee_l = solve_leg_joint_positions(p_hip_l, p_ank_l)
        p_knee_r = solve_leg_joint_positions(p_hip_r, p_ank_r)

        set_bone_endpoints(pb["thigh.L"], p_hip_l, p_knee_l)
        set_bone_endpoints(pb["shin.L"], p_knee_l, p_ank_l)
        set_bone_endpoints(pb["foot.L"], p_ank_l, p_ank_l + Vector((0.060, 0.0, -0.070)))

        set_bone_endpoints(pb["thigh.R"], p_hip_r, p_knee_r)
        set_bone_endpoints(pb["shin.R"], p_knee_r, p_ank_r)
        set_bone_endpoints(pb["foot.R"], p_ank_r, p_ank_r + Vector((0.060, 0.0, -0.070)))

        # Arms IK (hands on hoods)
        p_shld_l = Vector((0.230, 0.165, 0.860))
        p_shld_r = Vector((0.230, -0.165, 0.860))
        p_elb_l = solve_arm_joint_positions(p_shld_l, p_hand_l)
        p_elb_r = solve_arm_joint_positions(p_shld_r, p_hand_r)

        set_bone_endpoints(pb["upper_arm.L"], p_shld_l, p_elb_l)
        set_bone_endpoints(pb["forearm.L"], p_elb_l, p_hand_l)
        set_bone_endpoints(pb["hand.L"], p_hand_l, p_hand_l + Vector((0.040, 0.0, -0.010)))

        set_bone_endpoints(pb["upper_arm.R"], p_shld_r, p_elb_r)
        set_bone_endpoints(pb["forearm.R"], p_elb_r, p_hand_r)
        set_bone_endpoints(pb["hand.R"], p_hand_r, p_hand_r + Vector((0.040, 0.0, -0.010)))

        for b_name in DEFORM_BONES:
            pb[b_name].keyframe_insert("location", frame=frame)
            pb[b_name].keyframe_insert("rotation_quaternion", frame=frame)

    push_action_to_nla(arm_obj, act)
    return act


# -----------------------------------------------------------------------------
# 2. PEDAL_SEATED_DROPS_AERO (Aggressive breakaway pace, 100 RPM)
# -----------------------------------------------------------------------------
def animate_pedal_seated_drops_aero(arm_obj: bpy.types.Object, n_frames: int = 30) -> bpy.types.Action:
    act = create_animation_action(arm_obj, "Pedal_Seated_Drops_Aero")
    pb = arm_obj.pose.bones

    # Seated forward on saddle nose, hands down in drops
    p_saddle = Vector((-0.130, 0.000, 0.885))
    p_hand_l = Vector((0.510, 0.185, 0.620))
    p_hand_r = Vector((0.510, -0.185, 0.620))

    for frame in range(1, n_frames + 1):
        t = (frame - 1) / float(n_frames)
        theta = t * 2.0 * math.pi

        p_hip = p_saddle + Vector((0.0, 0.007 * math.sin(theta), 0.003 * math.cos(2.0 * theta)))
        p_hip_l = p_hip + Vector((0.0, 0.095, 0.0))
        p_hip_r = p_hip + Vector((0.0, -0.095, 0.0))

        # Flat aerodynamic back
        set_bone_endpoints(pb["hips"], p_hip, p_hip + Vector((0.110, 0.0, 0.020)))
        set_bone_endpoints(pb["spine"], p_hip + Vector((0.110, 0.0, 0.020)), Vector((0.100, 0.0, 0.880)))
        set_bone_endpoints(pb["chest"], Vector((0.100, 0.0, 0.880)), Vector((0.260, 0.0, 0.820)))
        set_bone_endpoints(pb["neck"], Vector((0.260, 0.0, 0.820)), Vector((0.340, 0.0, 0.870)))
        set_bone_endpoints(pb["head"], Vector((0.340, 0.0, 0.870)), Vector((0.440, 0.0, 0.940)))

        # Legs IK
        _, p_ank_l, _ = solve_pedal_stroke_ik(theta, is_left=True)
        _, p_ank_r, _ = solve_pedal_stroke_ik(theta, is_left=False)
        p_knee_l = solve_leg_joint_positions(p_hip_l, p_ank_l)
        p_knee_r = solve_leg_joint_positions(p_hip_r, p_ank_r)

        set_bone_endpoints(pb["thigh.L"], p_hip_l, p_knee_l)
        set_bone_endpoints(pb["shin.L"], p_knee_l, p_ank_l)
        set_bone_endpoints(pb["foot.L"], p_ank_l, p_ank_l + Vector((0.060, 0.0, -0.070)))

        set_bone_endpoints(pb["thigh.R"], p_hip_r, p_knee_r)
        set_bone_endpoints(pb["shin.R"], p_knee_r, p_ank_r)
        set_bone_endpoints(pb["foot.R"], p_ank_r, p_ank_r + Vector((0.060, 0.0, -0.070)))

        # Arms in drops
        p_shld_l = Vector((0.250, 0.165, 0.810))
        p_shld_r = Vector((0.250, -0.165, 0.810))
        p_elb_l = solve_arm_joint_positions(p_shld_l, p_hand_l, elbow_flare=0.020)
        p_elb_r = solve_arm_joint_positions(p_shld_r, p_hand_r, elbow_flare=0.020)

        set_bone_endpoints(pb["upper_arm.L"], p_shld_l, p_elb_l)
        set_bone_endpoints(pb["forearm.L"], p_elb_l, p_hand_l)
        set_bone_endpoints(pb["hand.L"], p_hand_l, p_hand_l + Vector((0.040, 0.0, -0.010)))

        set_bone_endpoints(pb["upper_arm.R"], p_shld_r, p_elb_r)
        set_bone_endpoints(pb["forearm.R"], p_elb_r, p_hand_r)
        set_bone_endpoints(pb["hand.R"], p_hand_r, p_hand_r + Vector((0.040, 0.0, -0.010)))

        for b_name in DEFORM_BONES:
            pb[b_name].keyframe_insert("location", frame=frame)
            pb[b_name].keyframe_insert("rotation_quaternion", frame=frame)

    push_action_to_nla(arm_obj, act)
    return act


# -----------------------------------------------------------------------------
# 3. PEDAL_STANDING_CLIMB (Out-of-the-saddle climbing dance, 70 RPM)
# -----------------------------------------------------------------------------
def animate_pedal_standing_climb(arm_obj: bpy.types.Object, n_frames: int = 30) -> bpy.types.Action:
    act = create_animation_action(arm_obj, "Pedal_Standing_Climb")
    pb = arm_obj.pose.bones

    p_standing_base = Vector((-0.060, 0.000, 1.010))

    for frame in range(1, n_frames + 1):
        t = (frame - 1) / float(n_frames)
        theta = t * 2.0 * math.pi

        # Heavy lateral sway over downstroke pedal
        sway_y = 0.038 * math.sin(theta)
        bounce_z = 0.015 * math.cos(2.0 * theta)
        p_hip = p_standing_base + Vector((0.0, sway_y, bounce_z))
        p_hip_l = p_hip + Vector((0.0, 0.095, 0.0))
        p_hip_r = p_hip + Vector((0.0, -0.095, 0.0))

        # Counter-balancing torso roll
        roll_dy = -0.035 * math.sin(theta)
        set_bone_endpoints(pb["hips"], p_hip, p_hip + Vector((0.080, roll_dy * 0.4, 0.030)))
        set_bone_endpoints(pb["spine"], p_hip + Vector((0.080, roll_dy * 0.4, 0.030)), Vector((0.100, roll_dy * 0.7, 0.980)))
        set_bone_endpoints(pb["chest"], Vector((0.100, roll_dy * 0.7, 0.980)), Vector((0.240, roll_dy, 0.940)))
        set_bone_endpoints(pb["neck"], Vector((0.240, roll_dy, 0.940)), Vector((0.310, roll_dy * 0.9, 0.990)))
        set_bone_endpoints(pb["head"], Vector((0.310, roll_dy * 0.9, 0.990)), Vector((0.400, roll_dy * 0.8, 1.060)))

        # Legs IK
        _, p_ank_l, _ = solve_pedal_stroke_ik(theta, is_left=True)
        _, p_ank_r, _ = solve_pedal_stroke_ik(theta, is_left=False)
        p_knee_l = solve_leg_joint_positions(p_hip_l, p_ank_l)
        p_knee_r = solve_leg_joint_positions(p_hip_r, p_ank_r)

        set_bone_endpoints(pb["thigh.L"], p_hip_l, p_knee_l)
        set_bone_endpoints(pb["shin.L"], p_knee_l, p_ank_l)
        set_bone_endpoints(pb["foot.L"], p_ank_l, p_ank_l + Vector((0.060, 0.0, -0.070)))

        set_bone_endpoints(pb["thigh.R"], p_hip_r, p_knee_r)
        set_bone_endpoints(pb["shin.R"], p_knee_r, p_ank_r)
        set_bone_endpoints(pb["foot.R"], p_ank_r, p_ank_r + Vector((0.060, 0.0, -0.070)))

        # Rhythmic bar pulling on hoods
        pull_l = 0.020 * math.sin(theta)
        pull_r = -0.020 * math.sin(theta)
        p_hand_l = Vector((0.525, 0.168, 0.695 + pull_l))
        p_hand_r = Vector((0.525, -0.168, 0.695 + pull_r))

        p_shld_l = Vector((0.230, 0.165 + roll_dy, 0.920))
        p_shld_r = Vector((0.230, -0.165 + roll_dy, 0.920))
        p_elb_l = solve_arm_joint_positions(p_shld_l, p_hand_l, elbow_flare=0.045)
        p_elb_r = solve_arm_joint_positions(p_shld_r, p_hand_r, elbow_flare=0.045)

        set_bone_endpoints(pb["upper_arm.L"], p_shld_l, p_elb_l)
        set_bone_endpoints(pb["forearm.L"], p_elb_l, p_hand_l)
        set_bone_endpoints(pb["hand.L"], p_hand_l, p_hand_l + Vector((0.040, 0.0, -0.010)))

        set_bone_endpoints(pb["upper_arm.R"], p_shld_r, p_elb_r)
        set_bone_endpoints(pb["forearm.R"], p_elb_r, p_hand_r)
        set_bone_endpoints(pb["hand.R"], p_hand_r, p_hand_r + Vector((0.040, 0.0, -0.010)))

        for b_name in DEFORM_BONES:
            pb[b_name].keyframe_insert("location", frame=frame)
            pb[b_name].keyframe_insert("rotation_quaternion", frame=frame)

    push_action_to_nla(arm_obj, act)
    return act


# -----------------------------------------------------------------------------
# 4. PEDAL_SPRINT_MAX (1600W violent sprint in drops, 120 RPM, 24 frames)
# -----------------------------------------------------------------------------
def animate_pedal_sprint_max(arm_obj: bpy.types.Object, n_frames: int = 24) -> bpy.types.Action:
    act = create_animation_action(arm_obj, "Pedal_Sprint_Max")
    pb = arm_obj.pose.bones

    p_sprint_base = Vector((-0.040, 0.000, 0.960))
    p_hand_l = Vector((0.520, 0.190, 0.615))
    p_hand_r = Vector((0.520, -0.190, 0.615))

    for frame in range(1, n_frames + 1):
        t = (frame - 1) / float(n_frames)
        theta = t * 2.0 * math.pi

        # Violent lateral body whip
        sway_y = 0.045 * math.sin(theta)
        p_hip = p_sprint_base + Vector((0.0, sway_y, 0.010 * math.cos(2.0 * theta)))
        p_hip_l = p_hip + Vector((0.0, 0.095, 0.0))
        p_hip_r = p_hip + Vector((0.0, -0.095, 0.0))

        roll_dy = -0.050 * math.sin(theta)
        set_bone_endpoints(pb["hips"], p_hip, p_hip + Vector((0.090, roll_dy * 0.4, 0.010)))
        set_bone_endpoints(pb["spine"], p_hip + Vector((0.090, roll_dy * 0.4, 0.010)), Vector((0.110, roll_dy * 0.7, 0.920)))
        set_bone_endpoints(pb["chest"], Vector((0.110, roll_dy * 0.7, 0.920)), Vector((0.260, roll_dy, 0.850)))
        set_bone_endpoints(pb["neck"], Vector((0.260, roll_dy, 0.850)), Vector((0.340, roll_dy * 0.9, 0.890)))
        set_bone_endpoints(pb["head"], Vector((0.340, roll_dy * 0.9, 0.890)), Vector((0.440, roll_dy * 0.8, 0.950)))

        # Explosive cadence legs IK
        _, p_ank_l, _ = solve_pedal_stroke_ik(theta, is_left=True)
        _, p_ank_r, _ = solve_pedal_stroke_ik(theta, is_left=False)
        p_knee_l = solve_leg_joint_positions(p_hip_l, p_ank_l)
        p_knee_r = solve_leg_joint_positions(p_hip_r, p_ank_r)

        set_bone_endpoints(pb["thigh.L"], p_hip_l, p_knee_l)
        set_bone_endpoints(pb["shin.L"], p_knee_l, p_ank_l)
        set_bone_endpoints(pb["foot.L"], p_ank_l, p_ank_l + Vector((0.060, 0.0, -0.070)))

        set_bone_endpoints(pb["thigh.R"], p_hip_r, p_knee_r)
        set_bone_endpoints(pb["shin.R"], p_knee_r, p_ank_r)
        set_bone_endpoints(pb["foot.R"], p_ank_r, p_ank_r + Vector((0.060, 0.0, -0.070)))

        # Maximal bar pulling in drops
        p_shld_l = Vector((0.250, 0.165 + roll_dy, 0.840))
        p_shld_r = Vector((0.250, -0.165 + roll_dy, 0.840))
        p_elb_l = solve_arm_joint_positions(p_shld_l, p_hand_l, elbow_flare=0.035)
        p_elb_r = solve_arm_joint_positions(p_shld_r, p_hand_r, elbow_flare=0.035)

        set_bone_endpoints(pb["upper_arm.L"], p_shld_l, p_elb_l)
        set_bone_endpoints(pb["forearm.L"], p_elb_l, p_hand_l)
        set_bone_endpoints(pb["hand.L"], p_hand_l, p_hand_l + Vector((0.040, 0.0, -0.010)))

        set_bone_endpoints(pb["upper_arm.R"], p_shld_r, p_elb_r)
        set_bone_endpoints(pb["forearm.R"], p_elb_r, p_hand_r)
        set_bone_endpoints(pb["hand.R"], p_hand_r, p_hand_r + Vector((0.040, 0.0, -0.010)))

        for b_name in DEFORM_BONES:
            pb[b_name].keyframe_insert("location", frame=frame)
            pb[b_name].keyframe_insert("rotation_quaternion", frame=frame)

    push_action_to_nla(arm_obj, act)
    return act


# -----------------------------------------------------------------------------
# 5. DRINK_BIDON (Reaching down for bottle, drinking, steady pedaling, 60 frames)
# -----------------------------------------------------------------------------
def animate_drink_bidon(arm_obj: bpy.types.Object, n_frames: int = 60) -> bpy.types.Action:
    act = create_animation_action(arm_obj, "Drink_Bidon")
    pb = arm_obj.pose.bones

    p_saddle = Vector((-0.160, 0.000, 0.900))
    p_hand_l = Vector((0.525, 0.168, 0.695))

    p_cage = Vector((0.180, 0.020, 0.520))    # Downtube bottle cage
    p_mouth = Vector((0.360, 0.030, 0.940))   # Mouth / chin

    for frame in range(1, n_frames + 1):
        # 2 pedal revolutions in 60 frames
        theta = (frame - 1) / 30.0 * 2.0 * math.pi

        p_hip = p_saddle + Vector((0.0, 0.005 * math.sin(theta), 0.002 * math.cos(2.0 * theta)))
        p_hip_l = p_hip + Vector((0.0, 0.095, 0.0))
        p_hip_r = p_hip + Vector((0.0, -0.095, 0.0))

        # Right arm trajectory
        head_tilt_z = 0.0
        if frame <= 15:  # Reach down
            s = frame / 15.0
            p_hand_r = Vector((0.525, -0.168, 0.695)).lerp(p_cage, s)
        elif frame <= 28:  # Bring to mouth
            s = (frame - 15) / 13.0
            p_hand_r = p_cage.lerp(p_mouth, s)
        elif frame <= 44:  # Drink (head tilted back)
            p_hand_r = p_mouth
            head_tilt_z = 0.015 * math.sin((frame - 28) / 16.0 * math.pi)
        elif frame <= 54:  # Put bottle back
            s = (frame - 44) / 10.0
            p_hand_r = p_mouth.lerp(p_cage, s)
        else:  # Return to hood
            s = (frame - 54) / 6.0
            p_hand_r = p_cage.lerp(Vector((0.525, -0.168, 0.695)), s)

        # Core spine
        set_bone_endpoints(pb["hips"], p_hip, p_hip + Vector((0.100, 0.0, 0.040)))
        set_bone_endpoints(pb["spine"], p_hip + Vector((0.100, 0.0, 0.040)), Vector((0.080, 0.0, 0.920)))
        set_bone_endpoints(pb["chest"], Vector((0.080, 0.0, 0.920)), Vector((0.240, 0.0, 0.880)))
        set_bone_endpoints(pb["neck"], Vector((0.240, 0.0, 0.880)), Vector((0.320, 0.0, 0.940 + head_tilt_z * 0.5)))
        set_bone_endpoints(pb["head"], Vector((0.320, 0.0, 0.940 + head_tilt_z * 0.5)), Vector((0.420, 0.0, 1.020 + head_tilt_z)))

        # Steady pedaling legs IK
        _, p_ank_l, _ = solve_pedal_stroke_ik(theta, is_left=True)
        _, p_ank_r, _ = solve_pedal_stroke_ik(theta, is_left=False)
        p_knee_l = solve_leg_joint_positions(p_hip_l, p_ank_l)
        p_knee_r = solve_leg_joint_positions(p_hip_r, p_ank_r)

        set_bone_endpoints(pb["thigh.L"], p_hip_l, p_knee_l)
        set_bone_endpoints(pb["shin.L"], p_knee_l, p_ank_l)
        set_bone_endpoints(pb["foot.L"], p_ank_l, p_ank_l + Vector((0.060, 0.0, -0.070)))

        set_bone_endpoints(pb["thigh.R"], p_hip_r, p_knee_r)
        set_bone_endpoints(pb["shin.R"], p_knee_r, p_ank_r)
        set_bone_endpoints(pb["foot.R"], p_ank_r, p_ank_r + Vector((0.060, 0.0, -0.070)))

        # Left hand on hood
        p_shld_l = Vector((0.230, 0.165, 0.860))
        p_elb_l = solve_arm_joint_positions(p_shld_l, p_hand_l)
        set_bone_endpoints(pb["upper_arm.L"], p_shld_l, p_elb_l)
        set_bone_endpoints(pb["forearm.L"], p_elb_l, p_hand_l)
        set_bone_endpoints(pb["hand.L"], p_hand_l, p_hand_l + Vector((0.040, 0.0, -0.010)))

        # Right arm drinking
        p_shld_r = Vector((0.230, -0.165, 0.860))
        p_elb_r = solve_arm_joint_positions(p_shld_r, p_hand_r, elbow_flare=-0.040)
        set_bone_endpoints(pb["upper_arm.R"], p_shld_r, p_elb_r)
        set_bone_endpoints(pb["forearm.R"], p_elb_r, p_hand_r)
        set_bone_endpoints(pb["hand.R"], p_hand_r, p_hand_r + Vector((0.020, 0.0, -0.030)))

        for b_name in DEFORM_BONES:
            pb[b_name].keyframe_insert("location", frame=frame)
            pb[b_name].keyframe_insert("rotation_quaternion", frame=frame)

    push_action_to_nla(arm_obj, act)
    return act


# -----------------------------------------------------------------------------
# 6. VICTORY_SALUTE (Stage win celebration, upright torso, V-arms, 60 frames)
# -----------------------------------------------------------------------------
def animate_victory_salute(arm_obj: bpy.types.Object, n_frames: int = 60) -> bpy.types.Action:
    act = create_animation_action(arm_obj, "Victory_Salute")
    pb = arm_obj.pose.bones

    # Coasting pedals (horizontal: right forward at 90°, left rear at 270°)
    theta = math.pi * 0.5
    _, p_ank_l, _ = solve_pedal_stroke_ik(theta, is_left=True)
    _, p_ank_r, _ = solve_pedal_stroke_ik(theta, is_left=False)

    for frame in range(1, n_frames + 1):
        # Progress from riding posture (frame 1) to upright victory celebration (frame 30..60)
        u = min(1.0, (frame - 1) / 30.0)
        # Smooth hermite ease-in-out
        s = u * u * (3.0 - 2.0 * u)

        # Torso straightens upright from 35° to 75°
        p_hip = Vector((-0.160, 0.0, 0.900))
        p_hip_l = p_hip + Vector((0.0, 0.095, 0.0))
        p_hip_r = p_hip + Vector((0.0, -0.095, 0.0))

        p_spine = p_hip + Vector((0.100 - s * 0.080, 0.0, 0.040 + s * 0.080))
        p_chest = Vector((0.080 - s * 0.140, 0.0, 0.920 + s * 0.160))
        p_neck = Vector((0.240 - s * 0.200, 0.0, 0.880 + s * 0.280))
        p_head = Vector((0.320 - s * 0.220, 0.0, 0.940 + s * 0.320))

        set_bone_endpoints(pb["hips"], p_hip, p_spine)
        set_bone_endpoints(pb["spine"], p_spine, p_chest)
        set_bone_endpoints(pb["chest"], p_chest, p_neck)
        set_bone_endpoints(pb["neck"], p_neck, p_head)
        set_bone_endpoints(pb["head"], p_head, p_head + Vector((0.060, 0.0, 0.100)))

        # Legs in steady coasting
        p_knee_l = solve_leg_joint_positions(p_hip_l, p_ank_l)
        p_knee_r = solve_leg_joint_positions(p_hip_r, p_ank_r)

        set_bone_endpoints(pb["thigh.L"], p_hip_l, p_knee_l)
        set_bone_endpoints(pb["shin.L"], p_knee_l, p_ank_l)
        set_bone_endpoints(pb["foot.L"], p_ank_l, p_ank_l + Vector((0.060, 0.0, -0.070)))

        set_bone_endpoints(pb["thigh.R"], p_hip_r, p_knee_r)
        set_bone_endpoints(pb["shin.R"], p_knee_r, p_ank_r)
        set_bone_endpoints(pb["foot.R"], p_ank_r, p_ank_r + Vector((0.060, 0.0, -0.070)))

        # Arms transition from hoods to triumphant V-sign high in the air
        p_hand_l_start = Vector((0.525, 0.168, 0.695))
        p_hand_r_start = Vector((0.525, -0.168, 0.695))
        p_hand_l_victory = Vector((0.040, 0.280, 1.280))
        p_hand_r_victory = Vector((0.040, -0.280, 1.280))

        p_hand_l = p_hand_l_start.lerp(p_hand_l_victory, s)
        p_hand_r = p_hand_r_start.lerp(p_hand_r_victory, s)

        p_shld_l = p_neck + Vector((-0.020, 0.165, -0.020))
        p_shld_r = p_neck + Vector((-0.020, -0.165, -0.020))
        p_elb_l = solve_arm_joint_positions(p_shld_l, p_hand_l, elbow_flare=0.040 + s * 0.060)
        p_elb_r = solve_arm_joint_positions(p_shld_r, p_hand_r, elbow_flare=0.040 + s * 0.060)

        set_bone_endpoints(pb["upper_arm.L"], p_shld_l, p_elb_l)
        set_bone_endpoints(pb["forearm.L"], p_elb_l, p_hand_l)
        set_bone_endpoints(pb["hand.L"], p_hand_l, p_hand_l + Vector((0.020, 0.040, 0.040)))

        set_bone_endpoints(pb["upper_arm.R"], p_shld_r, p_elb_r)
        set_bone_endpoints(pb["forearm.R"], p_elb_r, p_hand_r)
        set_bone_endpoints(pb["hand.R"], p_hand_r, p_hand_r + Vector((0.020, -0.040, 0.040)))

        for b_name in DEFORM_BONES:
            pb[b_name].keyframe_insert("location", frame=frame)
            pb[b_name].keyframe_insert("rotation_quaternion", frame=frame)

    push_action_to_nla(arm_obj, act)
    return act


# =============================================================================
# MASTER RIGGING & EXPORT PIPELINE
# =============================================================================

def rig_and_animate_cyclist(
    output_glb_path: str = "assets/3d/riders/cyclist_animated.glb",
    jersey_color_hex: str = "#2563EB",
) -> Tuple[bpy.types.Object, bpy.types.Object, str]:
    """
    Builds the complete rigged and animated cyclist asset:
      1. Generates 3D cyclist mesh with fitted kit, materials, and morph targets
      2. Creates humanoid cycling armature and applies Armature modifier
      3. Binds mesh with smooth normalized vertex weights
      4. Keyframes 6 pro cycling animations with inverse kinematics
      5. Exports to binary glTF (.glb)
    """
    # Clear existing mesh and armature objects
    for obj in [o for o in bpy.context.scene.objects if o.type in ["MESH", "ARMATURE"]]:
        bpy.data.objects.remove(obj, do_unlink=True)

    print("\n" + "=" * 75)
    print("PRO PELOTON MANAGER: RIGGING & ANIMATING 3D CYCLIST")
    print("=" * 75)

    # 1. Generate cyclist mesh
    cyclist_obj = gcm.generate_cyclist_mesh(
        name="Cyclist_Mesh",
        jersey_color_hex=jersey_color_hex,
    )

    # 2. Build Armature
    arm_obj = build_cyclist_armature(name="Cyclist_Armature")

    # 3. Bind and Skin Mesh
    bind_and_skin_cyclist_mesh(cyclist_obj, arm_obj)

    # 4. Generate All 6 Actions
    print("[ANIMATION] Keyframing 'Pedal_Seated_Hoods' (30 frames)...")
    animate_pedal_seated_hoods(arm_obj, n_frames=30)

    print("[ANIMATION] Keyframing 'Pedal_Seated_Drops_Aero' (30 frames)...")
    animate_pedal_seated_drops_aero(arm_obj, n_frames=30)

    print("[ANIMATION] Keyframing 'Pedal_Standing_Climb' (30 frames)...")
    animate_pedal_standing_climb(arm_obj, n_frames=30)

    print("[ANIMATION] Keyframing 'Pedal_Sprint_Max' (24 frames)...")
    animate_pedal_sprint_max(arm_obj, n_frames=24)

    print("[ANIMATION] Keyframing 'Drink_Bidon' (60 frames)...")
    animate_drink_bidon(arm_obj, n_frames=60)

    print("[ANIMATION] Keyframing 'Victory_Salute' (60 frames)...")
    animate_victory_salute(arm_obj, n_frames=60)

    # Restore default action to Seated Hoods
    arm_obj.animation_data.action = bpy.data.actions["Pedal_Seated_Hoods"]

    # 5. Export to binary glTF (.glb)
    bpy.ops.object.select_all(action="DESELECT")
    arm_obj.select_set(True)
    cyclist_obj.select_set(True)
    bpy.context.view_layer.objects.active = arm_obj

    abs_output_path = os.path.abspath(output_glb_path)
    os.makedirs(os.path.dirname(abs_output_path), exist_ok=True)

    print(f"[EXPORT] Exporting rigged & animated cyclist to '{abs_output_path}'...")
    export_kwargs = {
        "filepath": abs_output_path,
        "export_format": "GLB",
        "use_selection": True,
        "export_apply": False,
        "export_morph": True,
        "export_animations": True,
        "export_bake_animation": True,
        "export_animation_mode": "ACTIONS",
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
    print(f"[EXPORT] Success! File size: {file_size_kb:.1f} KB")
    print(f"[EXPORT] Exported Actions: {[a.name for a in bpy.data.actions]}")
    print("=" * 75 + "\n")

    return cyclist_obj, arm_obj, abs_output_path


# =============================================================================
# CLI EXECUTION ENTRY POINT
# =============================================================================

if __name__ == "__main__":
    out_path = "assets/3d/riders/cyclist_animated.glb"
    for idx, arg in enumerate(sys.argv):
        if arg in ["--output", "-o"] and idx + 1 < len(sys.argv):
            out_path = sys.argv[idx + 1]

    jersey_col = "#2563EB"
    for idx, arg in enumerate(sys.argv):
        if arg in ["--jersey-color", "-j"] and idx + 1 < len(sys.argv):
            jersey_col = sys.argv[idx + 1]

    c_obj, a_obj, glb_file = rig_and_animate_cyclist(
        output_glb_path=out_path,
        jersey_color_hex=jersey_col,
    )

    sm.setup_zwift_studio_lighting()
    print(f"[SUCCESS] Rigged & animated cyclist generated: '{glb_file}'")

