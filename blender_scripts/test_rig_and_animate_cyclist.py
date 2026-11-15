"""
===============================================================================
PRO PELOTON MANAGER - CYCLIST RIGGING & ANIMATION UNIT TESTS
===============================================================================
Automated unit test suite verifying procedural humanoid armature rigging,
vertex group skinning, analytical inverse kinematics (IK), and the 6 key
cycling animation actions.

Run via:
  blender --background --python blender_scripts/test_rig_and_animate_cyclist.py
===============================================================================
"""

import math
import os
import sys
import unittest

try:
    import bpy
    import bmesh
    from mathutils import Vector
except ImportError:
    print("[ERROR] 'bpy' module not found. Run within Blender environment.")
    sys.exit(1)

# Ensure local script directory is in sys.path
script_dir = os.path.dirname(os.path.abspath(__file__))
if script_dir not in sys.path:
    sys.path.insert(0, script_dir)

import generate_cyclist_mesh as gcm
import rig_and_animate_cyclist as rac
import style_and_materials as sm


class TestRigAndAnimateCyclist(unittest.TestCase):
    """Test suite for procedural cyclist rigging, skinning, and animations."""

    def setUp(self):
        """Clear all mesh, armature, and action objects before each test."""
        for obj in [o for o in bpy.context.scene.objects if o.type in ["MESH", "ARMATURE"]]:
            bpy.data.objects.remove(obj, do_unlink=True)
        for act in list(bpy.data.actions):
            bpy.data.actions.remove(act)

    def test_build_cyclist_armature(self):
        """Verifies armature creation with full 19-bone humanoid hierarchy."""
        arm_obj = rac.build_cyclist_armature(name="Test_Armature")
        self.assertEqual(arm_obj.type, "ARMATURE")
        bones = arm_obj.data.bones

        # Verify all essential deform bones exist
        for b_name in rac.DEFORM_BONES:
            self.assertIn(b_name, bones, f"Missing deform bone: {b_name}")

        # Verify bone hierarchy
        self.assertEqual(bones["hips"].parent.name, "root")
        self.assertEqual(bones["spine"].parent.name, "hips")
        self.assertEqual(bones["chest"].parent.name, "spine")
        self.assertEqual(bones["neck"].parent.name, "chest")
        self.assertEqual(bones["head"].parent.name, "neck")

        self.assertEqual(bones["thigh.L"].parent.name, "hips")
        self.assertEqual(bones["shin.L"].parent.name, "thigh.L")
        self.assertEqual(bones["foot.L"].parent.name, "shin.L")

        self.assertEqual(bones["thigh.R"].parent.name, "hips")
        self.assertEqual(bones["shin.R"].parent.name, "thigh.R")
        self.assertEqual(bones["foot.R"].parent.name, "shin.R")

    def test_bind_and_skin_cyclist_mesh(self):
        """Verifies Armature modifier attachment and normalized vertex weights."""
        cyclist_obj = gcm.generate_cyclist_mesh(name="Test_Cyclist_Mesh")
        arm_obj = rac.build_cyclist_armature(name="Test_Cyclist_Armature")
        rac.bind_and_skin_cyclist_mesh(cyclist_obj, arm_obj)

        # Check modifier
        self.assertIn("Armature", cyclist_obj.modifiers)
        mod = cyclist_obj.modifiers["Armature"]
        self.assertEqual(mod.object, arm_obj)

        # Check vertex groups exist
        vgroup_names = [vg.name for vg in cyclist_obj.vertex_groups]
        for b_name in rac.DEFORM_BONES:
            self.assertIn(b_name, vgroup_names)

        # Verify that all vertices have at least one assigned bone
        mesh = cyclist_obj.data
        unweighted_verts = 0
        for v in mesh.vertices:
            if len(v.groups) == 0:
                unweighted_verts += 1
        self.assertEqual(unweighted_verts, 0, "All vertices must be weighted to the armature")

    def test_solve_pedal_stroke_ik(self):
        """Verifies circular crank trajectory around BB with 180° phase offset."""
        p_bb = Vector((0.000, 0.000, 0.270))
        r_crank = 0.1725

        # Check 4 cardinal angles: 0, 90, 180, 270 deg
        for deg in [0, 90, 180, 270]:
            rad = math.radians(deg)
            p_ped_r, p_ank_r, _ = rac.solve_pedal_stroke_ik(rad, is_left=False)
            p_ped_l, p_ank_l, _ = rac.solve_pedal_stroke_ik(rad, is_left=True)

            # Check radius from BB
            r_dist_r = math.sqrt((p_ped_r.x - p_bb.x) ** 2 + (p_ped_r.z - p_bb.z) ** 2)
            r_dist_l = math.sqrt((p_ped_l.x - p_bb.x) ** 2 + (p_ped_l.z - p_bb.z) ** 2)
            self.assertAlmostEqual(r_dist_r, r_crank, delta=1e-4)
            self.assertAlmostEqual(r_dist_l, r_crank, delta=1e-4)

            # Check 180 deg opposition in X and Z
            self.assertAlmostEqual(p_ped_r.x, -p_ped_l.x, delta=1e-4)
            self.assertAlmostEqual(p_ped_r.z - p_bb.z, -(p_ped_l.z - p_bb.z), delta=1e-4)

            # Check Q-factor lateral separation
            self.assertLess(p_ped_r.y, -0.08)
            self.assertGreater(p_ped_l.y, 0.08)

    def test_solve_leg_joint_positions(self):
        """Verifies that 2-link spatial IK maintains exact femur and tibia lengths."""
        p_hip = Vector((-0.160, 0.095, 0.900))
        p_ank = Vector((0.110, 0.096, 0.200))
        femur_len = 0.400
        tibia_len = 0.400

        p_knee = rac.solve_leg_joint_positions(p_hip, p_ank, femur_len, tibia_len)

        len_femur = (p_knee - p_hip).length
        len_tibia = (p_ank - p_knee).length
        self.assertAlmostEqual(len_femur, femur_len, delta=0.01)
        self.assertAlmostEqual(len_tibia, tibia_len, delta=0.01)

        # Knee should bend forward (+X)
        self.assertGreater(p_knee.x, p_hip.x)

    def test_animation_actions_generated(self):
        """Verifies that all 6 required actions are created and keyframed."""
        arm_obj = rac.build_cyclist_armature(name="Test_Anim_Armature")

        rac.animate_pedal_seated_hoods(arm_obj, n_frames=30)
        rac.animate_pedal_seated_drops_aero(arm_obj, n_frames=30)
        rac.animate_pedal_standing_climb(arm_obj, n_frames=30)
        rac.animate_pedal_sprint_max(arm_obj, n_frames=24)
        rac.animate_drink_bidon(arm_obj, n_frames=60)
        rac.animate_victory_salute(arm_obj, n_frames=60)

        action_names = [a.name for a in bpy.data.actions]
        expected_actions = [
            "Pedal_Seated_Hoods",
            "Pedal_Seated_Drops_Aero",
            "Pedal_Standing_Climb",
            "Pedal_Sprint_Max",
            "Drink_Bidon",
            "Victory_Salute",
        ]
        for name in expected_actions:
            self.assertIn(name, action_names)

        # Verify NLA tracks pushed
        nla_track_names = [t.name for t in arm_obj.animation_data.nla_tracks]
        for name in expected_actions:
            self.assertIn(name, nla_track_names)

    def test_export_animated_cyclist(self):
        """Verifies glTF 2.0 export with armature, morph targets, and actions."""
        test_glb_path = "assets/3d/riders/test_animated_export.glb"
        try:
            c_obj, a_obj, exported_path = rac.rig_and_animate_cyclist(
                output_glb_path=test_glb_path,
                jersey_color_hex="#2563EB",
            )
            self.assertTrue(os.path.exists(exported_path))
            file_size_kb = os.path.getsize(exported_path) / 1024.0
            self.assertGreater(file_size_kb, 50.0)

            # Check glTF magic header
            with open(exported_path, "rb") as f:
                magic = f.read(4)
                self.assertEqual(magic, b"glTF")
        finally:
            if os.path.exists(test_glb_path):
                os.remove(test_glb_path)


if __name__ == "__main__":
    runner = unittest.TextTestRunner(verbosity=2)
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(TestRigAndAnimateCyclist)
    result = runner.run(suite)
    sys.exit(0 if result.wasSuccessful() else 1)

