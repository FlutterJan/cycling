"""
===============================================================================
UNIT TESTS: PROCEDURAL AERO ROAD BICYCLE FRAME GENERATOR
===============================================================================
Executes automated tests in Blender background mode to verify:
  - 2D Aerodynamic Profile Generators (Kammtail, D-shape, Aero Oval)
  - Procedural Aero Frame Mesh Construction
  - Front Disc Brake Aero Fork Construction
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
import generate_aero_frame as gaf


class TestGenerateAeroFrame(unittest.TestCase):

    def setUp(self):
        # Reset Blender to clean state
        bpy.ops.wm.read_factory_settings(use_empty=True)

    # -------------------------------------------------------------------------
    # 2D Aerodynamic Profile Tests
    # -------------------------------------------------------------------------

    def test_generate_kammtail_2d_points(self):
        pts = gaf.generate_kammtail_2d_points(chord=0.080, width=0.040, num_points=16)
        self.assertGreaterEqual(len(pts), 16)

        # Leading edge nose should be at positive X
        xs = [p.x for p in pts]
        ys = [p.y for p in pts]
        self.assertAlmostEqual(max(xs), 0.040, places=3)
        self.assertAlmostEqual(min(xs), -0.040, places=3)

        # Symmetric width around Y=0
        self.assertAlmostEqual(max(ys), 0.020, places=3)
        self.assertAlmostEqual(min(ys), -0.020, places=3)

    def test_generate_d_shape_2d_points(self):
        pts = gaf.generate_d_shape_2d_points(chord=0.055, width=0.030, num_points=16)
        self.assertGreaterEqual(len(pts), 10)
        xs = [p.x for p in pts]
        self.assertAlmostEqual(max(xs), 0.055 * 0.5, places=3)
        self.assertAlmostEqual(min(xs), -0.055 * 0.5, places=3)

    def test_generate_aero_oval_2d_points(self):
        pts = gaf.generate_aero_oval_2d_points(chord=0.030, width=0.015, num_points=16)
        self.assertEqual(len(pts), 16)
        xs = [p.x for p in pts]
        ys = [p.y for p in pts]
        self.assertAlmostEqual(max(xs), 0.015, places=3)
        self.assertAlmostEqual(max(ys), 0.0075, places=3)

    # -------------------------------------------------------------------------
    # 3D Frame & Fork Mesh Tests
    # -------------------------------------------------------------------------

    def test_create_aero_frame_mesh(self):
        frame_obj = gaf.create_aero_frame_mesh("Test_Frame", hex_color="#E10600")
        self.assertIsNotNone(frame_obj)
        self.assertEqual(frame_obj.type, "MESH")

        mesh = frame_obj.data
        self.assertGreater(len(mesh.vertices), 800)
        self.assertGreater(len(mesh.polygons), 600)

        # Verify materials
        mat_names = [m.name for m in mesh.materials]
        self.assertIn("M_Frame_Glossy_E10600", mat_names)
        self.assertIn("M_Carbon_Matte", mat_names)
        self.assertIn("M_Metal_Rotor", mat_names)

        # Check dimensions
        verts = [v.co for v in mesh.vertices]
        min_x = min(v.x for v in verts)
        max_x = max(v.x for v in verts)
        max_z = max(v.z for v in verts)

        # Rear axle to headtube span: ~0.9m
        self.assertLess(min_x, -0.40)
        self.assertGreater(max_x, 0.45)
        # Integrated seatpost top reaches ~0.90m
        self.assertGreater(max_z, 0.88)

    def test_create_aero_fork_mesh(self):
        fork_obj = gaf.create_aero_fork_mesh("Test_Fork", hex_color="#0055FF")
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

    def test_assemble_and_export_glb(self):
        test_glb_path = "assets/3d/bikes/test_export.glb"
        if os.path.exists(test_glb_path):
            os.remove(test_glb_path)

        main_obj, exported_path = gaf.assemble_aero_bicycle_frame(
            hex_color="#E10600",
            output_glb_path=test_glb_path,
            join_components=True,
        )

        self.assertIsNotNone(main_obj)
        self.assertTrue(os.path.exists(exported_path))

        # Check glTF binary header magic bytes ("glTF")
        with open(exported_path, "rb") as f:
            magic = f.read(4)
            self.assertEqual(magic, b"glTF")

        # Check reasonable file size (> 20 KB)
        size_kb = os.path.getsize(exported_path) / 1024.0
        self.assertGreater(size_kb, 20.0)

        # Cleanup test file
        if os.path.exists(test_glb_path):
            os.remove(test_glb_path)


if __name__ == "__main__":
    runner = unittest.TextTestRunner(verbosity=2)
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(TestGenerateAeroFrame)
    result = runner.run(suite)
    sys.exit(0 if result.wasSuccessful() else 1)

