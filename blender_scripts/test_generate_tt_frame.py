"""
===============================================================================
UNIT TESTS: PROCEDURAL TIME TRIAL (TT) BICYCLE FRAME GENERATOR
===============================================================================
Executes automated tests in Blender background mode to verify:
  - 2D Time Trial Profile Generators (Deep TT Head Tube, Wheel Cutout, Aero Wing)
  - Procedural TT Frame Mesh Construction (Deep Head Tube, Wheel Cutout, Integrated Cockpit)
  - Deep Bladed TT Disc Fork Construction
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
import generate_tt_frame as gtf


class TestGenerateTTFrame(unittest.TestCase):

    def setUp(self):
        # Reset Blender to clean empty state
        bpy.ops.wm.read_factory_settings(use_empty=True)

    # -------------------------------------------------------------------------
    # 2D Time Trial Profile Generators
    # -------------------------------------------------------------------------

    def test_generate_deep_tt_headtube_2d_points(self):
        pts = gtf.generate_deep_tt_headtube_2d_points(chord=0.115, width=0.046, num_points=20)
        self.assertGreaterEqual(len(pts), 16)
        xs = [p.x for p in pts]
        ys = [p.y for p in pts]
        self.assertAlmostEqual(max(xs), 0.115 * 0.5, places=3)
        self.assertAlmostEqual(min(xs), -0.115 * 0.5, places=3)
        self.assertAlmostEqual(max(ys), 0.023, places=3)
        self.assertAlmostEqual(min(ys), -0.023, places=3)

    def test_generate_cutout_seat_tube_2d_points(self):
        pts = gtf.generate_cutout_seat_tube_2d_points(chord=0.065, width=0.034, cutout_concavity=0.012, num_points=16)
        self.assertGreaterEqual(len(pts), 10)
        xs = [p.x for p in pts]
        self.assertAlmostEqual(max(xs), 0.065 * 0.5, places=3)
        self.assertAlmostEqual(min(xs), -0.065 * 0.5, places=3)

    def test_generate_aero_wing_2d_points(self):
        pts = gtf.generate_aero_wing_2d_points(chord=0.050, thickness=0.018, num_points=16)
        self.assertEqual(len(pts), 16)
        xs = [p.x for p in pts]
        ys = [p.y for p in pts]
        self.assertAlmostEqual(max(xs), 0.025, places=3)
        self.assertTrue(0.008 <= max(ys) <= 0.012)

    # -------------------------------------------------------------------------
    # 3D Mesh Geometry Tests
    # -------------------------------------------------------------------------

    def test_create_tt_frame_mesh(self):
        frame_obj = gtf.create_tt_frame_mesh("Test_TT_Frame", hex_color="#1E293B")
        self.assertIsNotNone(frame_obj)
        self.assertEqual(frame_obj.type, "MESH")

        mesh = frame_obj.data
        self.assertGreater(len(mesh.vertices), 800)
        self.assertGreater(len(mesh.polygons), 600)

        # Verify materials
        mat_names = [m.name for m in mesh.materials]
        self.assertIn("M_Frame_Glossy_1E293B", mat_names)
        self.assertIn("M_Carbon_Matte", mat_names)
        self.assertIn("M_Metal_Rotor", mat_names)

        # Check integrated cockpit dimensions
        verts = [v.co for v in mesh.vertices]
        min_x = min(v.x for v in verts)
        max_x = max(v.x for v in verts)
        min_y = min(v.y for v in verts)
        max_y = max(v.y for v in verts)

        # Rear axle ~ -0.405m, Aerobar extensions reach forward to X > 0.75m
        self.assertLess(min_x, -0.40)
        self.assertGreater(max_x, 0.75)

        # Basebar width reaches ~ +/-0.18m (360-400mm width)
        self.assertLess(min_y, -0.17)
        self.assertGreater(max_y, 0.17)

    def test_create_tt_fork_mesh(self):
        fork_obj = gtf.create_tt_fork_mesh("Test_TT_Fork", hex_color="#E10600")
        self.assertIsNotNone(fork_obj)
        self.assertEqual(fork_obj.type, "MESH")

        mesh = fork_obj.data
        self.assertGreater(len(mesh.vertices), 180)
        self.assertGreater(len(mesh.polygons), 140)

        # Front axle width ~ 100mm (between -0.05 and +0.05 along Y)
        ys = [v.co.y for v in mesh.vertices]
        self.assertLess(min(ys), -0.045)
        self.assertGreater(max(ys), 0.045)

    # -------------------------------------------------------------------------
    # Assembly & glTF Export Tests
    # -------------------------------------------------------------------------

    def test_assemble_and_export_tt_glb(self):
        test_glb_path = "assets/3d/bikes/test_tt_export.glb"
        if os.path.exists(test_glb_path):
            os.remove(test_glb_path)

        main_obj, exported_path = gtf.assemble_tt_bicycle_frame(
            hex_color="#1E293B",
            output_glb_path=test_glb_path,
            join_components=True,
        )

        self.assertIsNotNone(main_obj)
        self.assertTrue(os.path.exists(exported_path))

        # Check binary glTF magic header
        with open(exported_path, "rb") as f:
            magic = f.read(4)
            self.assertEqual(magic, b"glTF")

        # Check reasonable file size (> 25 KB)
        size_kb = os.path.getsize(exported_path) / 1024.0
        self.assertGreater(size_kb, 25.0)

        # Cleanup test file
        if os.path.exists(test_glb_path):
            os.remove(test_glb_path)


if __name__ == "__main__":
    runner = unittest.TextTestRunner(verbosity=2)
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(TestGenerateTTFrame)
    result = runner.run(suite)
    sys.exit(0 if result.wasSuccessful() else 1)
