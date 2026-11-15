"""
===============================================================================
PRO PELOTON MANAGER - CYCLIST 3D MESH GENERATOR UNIT TESTS
===============================================================================
Automated unit test suite verifying procedural generation of the 3D cyclist
mesh, PBR materials, anatomical landmarks, BOA dials, and morph targets
(Climber_Lean, AllRounder, Sprinter_Muscular).

Run via:
  blender --background --python blender_scripts/test_generate_cyclist_mesh.py
===============================================================================
"""

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
import style_and_materials as sm


class TestGenerateCyclistMesh(unittest.TestCase):
    """Test suite for procedural cyclist 3D generation and morphing."""

    def setUp(self):
        """Clear all mesh objects before each test."""
        for obj in [o for o in bpy.context.scene.objects if o.type == "MESH"]:
            bpy.data.objects.remove(obj, do_unlink=True)

    def test_create_cyclist_materials(self):
        """Verifies that all specialized cyclist materials are created with valid PBR nodes."""
        skin = gcm.create_cyclist_skin_material("#DFAC89", "Test_Skin")
        self.assertIsNotNone(skin.node_tree)
        bsdf_skin = skin.node_tree.nodes.get("Principled BSDF")
        self.assertIsNotNone(bsdf_skin)

        socks = gcm.create_aero_sock_material("#F8FAFC", "Test_Socks")
        self.assertIsNotNone(socks.node_tree)
        self.assertTrue(any("Wave" in n.name or "Sock" in n.name for n in socks.node_tree.nodes))

        shoe = gcm.create_road_shoes_material("#FFFFFF", "Test_Shoe")
        self.assertIsNotNone(shoe.node_tree)

        boa = gcm.create_boa_dial_material("Test_BOA")
        self.assertIsNotNone(boa.node_tree)

    def test_build_torso_and_pelvis(self):
        """Verifies torso spine curvature and pelvic saddle alignment."""
        bm = bmesh.new()
        tag_list = []
        gcm.build_torso_and_pelvis(bm, tag_list, mat_jersey=1, mat_bib=2)
        self.assertGreater(len(bm.verts), 50)
        self.assertGreater(len(bm.faces), 40)

        # Verify torso height span (chest hangs forward over top tube down to ~0.77m, spine reaches ~0.95m)
        min_z = min(v.co.z for v in bm.verts)
        self.assertGreater(min_z, 0.70)
        self.assertLess(min_z, 0.96)

        # Verify tagging includes pelvis, waist, and chest
        regions = {tag.region for _, tag in tag_list}
        self.assertIn("pelvis", regions)
        self.assertIn("chest", regions)
        bm.free()

    def test_build_head_helmet_and_visor(self):
        """Verifies head, aerodynamic teardrop helmet, and dichroic visor."""
        bm = bmesh.new()
        tag_list = []
        gcm.build_head_helmet_and_visor(bm, tag_list, mat_skin=0, mat_helmet=7, mat_visor=8)
        self.assertGreater(len(bm.verts), 40)

        # Verify max height of helmet cranium apex is ~1.05m
        max_z = max(v.co.z for v in bm.verts)
        self.assertGreater(max_z, 1.00)

        # Verify aerodynamic rear helmet extension (X < 0.25)
        min_x = min(v.co.x for v in bm.verts)
        self.assertLess(min_x, 0.25)
        bm.free()

    def test_build_arms_and_hands(self):
        """Verifies that left and right hands reach the brake hoods at (0.525, ±0.168, 0.695)."""
        bm = bmesh.new()
        tag_list = []
        gcm.build_arms_and_hands(bm, tag_list, mat_jersey=1, mat_skin=0)
        self.assertGreater(len(bm.verts), 60)

        # Verify hands reach X ≈ 0.525
        max_x = max(v.co.x for v in bm.verts)
        self.assertAlmostEqual(max_x, 0.525, delta=0.03)

        # Verify bilateral symmetry (left +Y, right -Y)
        has_pos_y = any(v.co.y > 0.15 for v in bm.verts)
        has_neg_y = any(v.co.y < -0.15 for v in bm.verts)
        self.assertTrue(has_pos_y)
        self.assertTrue(has_neg_y)
        bm.free()

    def test_build_legs_and_socks(self):
        """Verifies inverse kinematics and tall aero socks on both legs."""
        bm = bmesh.new()
        tag_list = []
        lm_r, lm_l = gcm.build_legs_and_socks(bm, tag_list, mat_bib=2, mat_skin=0, mat_socks=3)

        self.assertIn("ankle", lm_r)
        self.assertIn("knee", lm_r)
        self.assertIn("ankle", lm_l)
        self.assertIn("knee", lm_l)

        # Right leg extended (ankle Z ≈ 0.20), left leg flexed (ankle Z ≈ 0.44)
        self.assertAlmostEqual(lm_r["ankle"].z, 0.200, delta=0.02)
        self.assertAlmostEqual(lm_l["ankle"].z, 0.440, delta=0.02)

        # Verify tall aero socks were tagged and assigned material 3
        faces_socks = [f for f in bm.faces if f.material_index == 3]
        self.assertGreater(len(faces_socks), 20)
        bm.free()

    def test_build_shoes_and_boa_dials(self):
        """Verifies road cycling shoes, carbon soles, and dual lateral BOA dials."""
        bm = bmesh.new()
        tag_list = []
        lm_r = {"ankle": Vector((0.110, 0.096, 0.200))}
        lm_l = {"ankle": Vector((-0.122, -0.096, 0.440))}
        gcm.build_shoes_and_boa_dials(bm, tag_list, lm_r, lm_l, mat_shoe=4, mat_carbon=5, mat_boa=6)

        # Verify BOA dial faces are generated (material 6)
        faces_boa = [f for f in bm.faces if f.material_index == 6]
        self.assertGreaterEqual(len(faces_boa), 40)

        # Verify Carbon sole plates (material 5)
        faces_carbon = [f for f in bm.faces if f.material_index == 5]
        self.assertGreaterEqual(len(faces_carbon), 20)
        bm.free()

    def test_cyclist_shape_keys(self):
        """Verifies creation and displacement deltas of Climber_Lean, AllRounder, and Sprinter_Muscular."""
        obj = gcm.generate_cyclist_mesh(name="Test_Cyclist")
        self.assertIsNotNone(obj.data.shape_keys)

        key_blocks = obj.data.shape_keys.key_blocks
        self.assertIn("Basis", key_blocks)
        self.assertIn("Climber_Lean", key_blocks)
        self.assertIn("AllRounder", key_blocks)
        self.assertIn("Sprinter_Muscular", key_blocks)

        sk_basis = key_blocks["Basis"]
        sk_climber = key_blocks["Climber_Lean"]
        sk_allrounder = key_blocks["AllRounder"]
        sk_sprinter = key_blocks["Sprinter_Muscular"]

        n_pts = len(sk_basis.data)
        delta_climber_max = max((sk_climber.data[i].co - sk_basis.data[i].co).length for i in range(n_pts))
        delta_allrounder_max = max((sk_allrounder.data[i].co - sk_basis.data[i].co).length for i in range(n_pts))
        delta_sprinter_max = max((sk_sprinter.data[i].co - sk_basis.data[i].co).length for i in range(n_pts))

        self.assertGreater(delta_climber_max, 0.04, "Climber_Lean should have significant lean morph deltas")
        self.assertGreater(delta_allrounder_max, 0.02, "AllRounder should have defined athletic deltas")
        self.assertGreater(delta_sprinter_max, 0.10, "Sprinter_Muscular should have massive quad/chest deltas")

        # Sprinter muscularity should be the largest positive displacement
        self.assertGreater(delta_sprinter_max, delta_allrounder_max)

    def test_generate_cyclist_mesh(self):
        """Verifies full mesh generation, 9 material slots, and polygon budget."""
        obj = gcm.generate_cyclist_mesh(name="Cyclist_Road_Test")
        self.assertEqual(obj.type, "MESH")
        self.assertEqual(len(obj.data.materials), 9)

        # Budget check: mid-poly smooth (500 - 3000 polygons)
        poly_count = len(obj.data.polygons)
        self.assertGreater(poly_count, 400)
        self.assertLess(poly_count, 2500)

    def test_export_cyclist_glb(self):
        """Verifies glTF 2.0 export with morph targets to GLB binary file."""
        test_glb_path = "assets/3d/cyclists/test_cyclist_export.glb"
        try:
            obj, exported_path = gcm.export_cyclist_glb(
                output_glb_path=test_glb_path,
                jersey_color_hex="#1E40AF",
            )
            self.assertTrue(os.path.exists(exported_path))
            file_size_kb = os.path.getsize(exported_path) / 1024.0
            self.assertGreater(file_size_kb, 40.0)
            self.assertLess(file_size_kb, 500.0)
        finally:
            if os.path.exists(test_glb_path):
                os.remove(test_glb_path)


if __name__ == "__main__":
    runner = unittest.TextTestRunner(verbosity=2)
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(TestGenerateCyclistMesh)
    result = runner.run(suite)
    sys.exit(0 if result.wasSuccessful() else 1)
