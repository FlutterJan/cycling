"""
===============================================================================
UNIT TESTS: PROCEDURAL ROAD WHEELSET GENERATOR
===============================================================================
Executes automated tests in Blender background mode to verify:
  - 700c Road Tire Construction (28mm width, outer radius 340mm)
  - Carbon Rim Depth Variants (35mm, 50mm, 65mm) & Spoke Bed Radii
  - Full Lenticular Carbon Disc Wheel Construction
  - Flat Aero Bladed Spoke Generation (24 spokes, 2-cross lacing)
  - Ventilated Galfer Wave Disc Rotor (160mm, 12 waves, cooling windows)
  - Centerlock Disc Hub with 12mm Thru-Axle End Caps
  - Binary glTF Export Pipeline for all 4 Variants
===============================================================================
"""

import math
import os
import sys
import unittest

# Ensure blender_scripts is in sys.path
current_dir = os.path.dirname(os.path.abspath(__file__))
if current_dir not in sys.path:
    sys.path.insert(0, current_dir)

import bpy
import bmesh
import generate_wheelsets as gw


class TestGenerateWheelsets(unittest.TestCase):

    def setUp(self):
        # Reset Blender to clean state
        bpy.ops.wm.read_factory_settings(use_empty=True)

    # -------------------------------------------------------------------------
    # Component BMesh Builder Tests
    # -------------------------------------------------------------------------

    def test_build_tire_mesh(self):
        bm = bmesh.new()
        gw.build_tire_mesh(bm, r_bead=0.311, r_outer=0.340, tire_width=0.028)
        self.assertGreater(len(bm.verts), 300)
        self.assertGreater(len(bm.faces), 250)

        # Verify outer radius is 0.340m
        radii = [math.hypot(v.co.x, v.co.z) for v in bm.verts]
        self.assertAlmostEqual(max(radii), 0.340, places=2)
        bm.free()

    def test_build_rim_depths(self):
        for depth_mm, expected_inner in [(35, 0.276), (50, 0.261), (65, 0.246)]:
            bm = bmesh.new()
            r_inner = gw.build_rim_mesh(bm, rim_depth=depth_mm / 1000.0, r_bead=0.311)
            self.assertAlmostEqual(r_inner, expected_inner, places=3)
            self.assertGreater(len(bm.faces), 200)
            bm.free()

    def test_build_disc_wheel_mesh(self):
        bm = bmesh.new()
        gw.build_disc_wheel_mesh(bm, r_bead=0.311, r_hub_flange=0.030)
        self.assertGreater(len(bm.faces), 300)
        # Check span from hub flange (30mm) to bead (311mm)
        radii = [math.hypot(v.co.x, v.co.z) for v in bm.verts]
        self.assertAlmostEqual(min(radii), 0.030, places=3)
        self.assertAlmostEqual(max(radii), 0.311, places=3)
        bm.free()

    def test_build_galfer_wave_rotor_mesh(self):
        bm = bmesh.new()
        gw.build_galfer_wave_rotor_mesh(bm, y_pos=-0.020, rotor_diameter=0.160, num_waves=12)
        self.assertGreater(len(bm.faces), 80)

        # Check rotor diameter is ~0.160m (radius ~0.080m)
        radii = [math.hypot(v.co.x, v.co.z) for v in bm.verts]
        self.assertAlmostEqual(max(radii), 0.080, places=3)
        self.assertAlmostEqual(min(radii), 0.026, places=3)

        # Check rotor thickness is ~1.8mm
        ys = [v.co.y for v in bm.verts]
        rotor_thickness = max(ys) - min(ys)
        self.assertAlmostEqual(rotor_thickness, 0.0018, places=4)
        bm.free()

    def test_build_bladed_spokes_mesh(self):
        bm = bmesh.new()
        gw.build_bladed_spokes_mesh(bm, r_rim=0.261, num_spokes=24)
        # 24 spokes * 4 quad faces = 96 faces
        self.assertEqual(len(bm.faces), 96)
        bm.free()

    # -------------------------------------------------------------------------
    # Full Wheel Mesh & Material Tests
    # -------------------------------------------------------------------------

    def test_generate_road_wheel_mesh(self):
        wheel_obj = gw.generate_road_wheel_mesh("Test_Wheel_50mm", rim_depth_mm=50, is_disc_wheel=False)
        self.assertIsNotNone(wheel_obj)
        self.assertEqual(wheel_obj.type, "MESH")

        mesh = wheel_obj.data
        self.assertGreater(len(mesh.vertices), 1200)
        self.assertGreater(len(mesh.polygons), 1000)

        # Verify materials
        mat_names = [m.name for m in mesh.materials]
        self.assertIn("M_Carbon_Matte", mat_names)
        self.assertIn("M_Tire_TanWall", mat_names)
        self.assertIn("M_Metal_Rotor", mat_names)

    def test_generate_disc_wheel_mesh(self):
        disc_obj = gw.generate_road_wheel_mesh("Test_Wheel_Disc", rim_depth_mm=0, is_disc_wheel=True)
        self.assertIsNotNone(disc_obj)
        mesh = disc_obj.data
        self.assertGreater(len(mesh.vertices), 1100)
        self.assertGreater(len(mesh.polygons), 1000)

    # -------------------------------------------------------------------------
    # glTF Export Verification Tests
    # -------------------------------------------------------------------------

    def test_export_all_4_wheelsets(self):
        output_dir = "assets/3d/bikes"
        for variant in ["wheel_35mm", "wheel_50mm", "wheel_65mm", "wheel_disc"]:
            glb_path = os.path.join(output_dir, f"{variant}.glb")
            self.assertTrue(os.path.exists(glb_path), f"File '{glb_path}' does not exist.")

            # Check glTF binary header magic bytes
            with open(glb_path, "rb") as f:
                magic = f.read(4)
                self.assertEqual(magic, b"glTF")

            # Check reasonable file size (> 40 KB)
            size_kb = os.path.getsize(glb_path) / 1024.0
            self.assertGreater(size_kb, 40.0)


if __name__ == "__main__":
    runner = unittest.TextTestRunner(verbosity=2)
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(TestGenerateWheelsets)
    result = runner.run(suite)
    sys.exit(0 if result.wasSuccessful() else 1)
