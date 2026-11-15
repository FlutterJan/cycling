"""
===============================================================================
UNIT TESTS: PROCEDURAL CLIMBING ROAD BICYCLE FRAME GENERATOR
===============================================================================
Executes automated tests in Blender background mode to verify:
  - 2D Round / Oval / Squoval Profile Generators
  - Procedural Climbing Frame Mesh Construction (Classic Non-Dropped Rear Triangle)
  - Slender Climbing Disc Fork Construction
  - Material Assignment and Slot Mapping
  - Binary glTF (.glb) Export Pipeline and File Integrity
===============================================================================
"""

import os
import sys
import unittest

# Ensure blender_scripts is in sys.path
current_dir = os.path.dirname(os.path.abspath(__file__))
if current_dir not in sys.path:
    sys.path.insert(0, current_dir)

import bpy
import generate_climbing_frame as gcf


class TestGenerateClimbingFrame(unittest.TestCase):

    def setUp(self):
        # Reset Blender to clean state
        bpy.ops.wm.read_factory_settings(use_empty=True)

    # -------------------------------------------------------------------------
    # 2D Profile Generators
    # -------------------------------------------------------------------------

    def test_generate_oval_2d_points(self):
        pts = gcf.generate_oval_2d_points(radius_x=0.020, radius_y=0.015, num_points=16)
        self.assertEqual(len(pts), 16)
        xs = [p.x for p in pts]
        ys = [p.y for p in pts]
        self.assertAlmostEqual(max(xs), 0.020, places=3)
        self.assertAlmostEqual(min(xs), -0.020, places=3)
        self.assertAlmostEqual(max(ys), 0.015, places=3)
        self.assertAlmostEqual(min(ys), -0.015, places=3)

    def test_generate_squoval_2d_points(self):
        pts = gcf.generate_squoval_2d_points(radius_x=0.024, radius_y=0.022, power=2.8, num_points=16)
        self.assertEqual(len(pts), 16)
        xs = [p.x for p in pts]
        ys = [p.y for p in pts]
        self.assertAlmostEqual(max(xs), 0.024, places=3)
        self.assertAlmostEqual(max(ys), 0.022, places=3)

    # -------------------------------------------------------------------------
    # 3D Mesh Geometry Tests
    # -------------------------------------------------------------------------

    def test_create_climbing_frame_mesh(self):
        frame_obj = gcf.create_climbing_frame_mesh("Test_Climbing_Frame", hex_color="#0284C7")
        self.assertIsNotNone(frame_obj)
        self.assertEqual(frame_obj.type, "MESH")

        mesh = frame_obj.data
        self.assertGreater(len(mesh.vertices), 700)
        self.assertGreater(len(mesh.polygons), 500)

        # Verify materials
        mat_names = [m.name for m in mesh.materials]
        self.assertIn("M_Frame_Glossy_0284C7", mat_names)
        self.assertIn("M_Carbon_Matte", mat_names)
        self.assertIn("M_Metal_Rotor", mat_names)

        # Check dimensions
        verts = [v.co for v in mesh.vertices]
        min_x = min(v.x for v in verts)
        max_x = max(v.x for v in verts)
        max_z = max(v.z for v in verts)

        # Rear axle to headtube span: ~0.9m
        self.assertLess(min_x, -0.40)
        self.assertGreater(max_x, 0.44)
        # Seatpost clamp height: ~0.895m
        self.assertGreater(max_z, 0.88)

    def test_create_climbing_fork_mesh(self):
        fork_obj = gcf.create_climbing_fork_mesh("Test_Climbing_Fork", hex_color="#10B981")
        self.assertIsNotNone(fork_obj)
        self.assertEqual(fork_obj.type, "MESH")

        mesh = fork_obj.data
        self.assertGreater(len(mesh.vertices), 200)
        self.assertGreater(len(mesh.polygons), 150)

        # Front axle width ~ 100mm (between -0.05 and +0.05 along Y)
        ys = [v.co.y for v in mesh.vertices]
        self.assertLess(min(ys), -0.045)
        self.assertGreater(max(ys), 0.045)

    # -------------------------------------------------------------------------
    # Assembly & glTF Export Tests
    # -------------------------------------------------------------------------

    def test_assemble_and_export_climbing_glb(self):
        test_glb_path = "assets/3d/bikes/test_climbing_export.glb"
        if os.path.exists(test_glb_path):
            os.remove(test_glb_path)

        main_obj, exported_path = gcf.assemble_climbing_bicycle_frame(
            hex_color="#0284C7",
            output_glb_path=test_glb_path,
            join_components=True,
        )

        self.assertIsNotNone(main_obj)
        self.assertTrue(os.path.exists(exported_path))

        # Check binary glTF magic header
        with open(exported_path, "rb") as f:
            magic = f.read(4)
            self.assertEqual(magic, b"glTF")

        # Check reasonable file size (> 15 KB)
        size_kb = os.path.getsize(exported_path) / 1024.0
        self.assertGreater(size_kb, 15.0)

        # Cleanup test file
        if os.path.exists(test_glb_path):
            os.remove(test_glb_path)


if __name__ == "__main__":
    runner = unittest.TextTestRunner(verbosity=2)
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(TestGenerateClimbingFrame)
    result = runner.run(suite)
    sys.exit(0 if result.wasSuccessful() else 1)

