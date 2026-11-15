"""
===============================================================================
UNIT TESTS: PROCEDURAL BICYCLE COMPONENTS & DRIVETRAIN GENERATOR
===============================================================================
Executes automated tests in Blender background mode to verify:
  - Integrated Aero Cockpit with Inward-Flared Hoods (Klamkomanetki)
  - Carbon Crankset with Integrated Power Meter Spider and Pedals
  - 12-Speed Stepped Cassette and Wireless Rear Derailleur
  - Continuous Drivetrain Chain Loop
  - Dual Bottle Cages and Pro Bidons
  - Short-Nose 3D-Printed Anatomic Saddle with Central Cutout
  - Binary glTF Export Pipeline and Material Mapping
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
import generate_cockpit_and_drivetrain as gcd


class TestGenerateCockpitAndDrivetrain(unittest.TestCase):

    def setUp(self):
        # Reset Blender to clean empty state
        bpy.ops.wm.read_factory_settings(use_empty=True)

    # -------------------------------------------------------------------------
    # Individual Component BMesh Tests
    # -------------------------------------------------------------------------

    def test_build_integrated_cockpit(self):
        bm = bmesh.new()
        gcd.build_integrated_cockpit(bm, p_headtube_top=bpy.context.scene.cursor.location)
        self.assertGreater(len(bm.verts), 150)
        self.assertGreater(len(bm.faces), 100)

        # Check lateral handlebar width (Y span ~0.38m)
        ys = [v.co.y for v in bm.verts]
        self.assertLess(min(ys), -0.17)
        self.assertGreater(max(ys), 0.17)
        bm.free()

    def test_build_carbon_crankset(self):
        bm = bmesh.new()
        gcd.build_carbon_crankset(bm, p_bb=bpy.context.scene.cursor.location)
        self.assertGreater(len(bm.faces), 150)

        # Check crank length (~172.5mm)
        pts = [v.co for v in bm.verts]
        max_dist_from_bb = max(math.hypot(p.x, p.z) for p in pts)
        self.assertGreaterEqual(max_dist_from_bb, 0.160)
        bm.free()

    def test_build_12speed_cassette(self):
        bm = bmesh.new()
        gcd.build_12speed_cassette(bm)
        self.assertGreater(len(bm.faces), 100)
        bm.free()

    def test_build_wireless_rear_derailleur(self):
        bm = bmesh.new()
        gcd.build_wireless_rear_derailleur(bm)
        self.assertGreater(len(bm.faces), 50)
        bm.free()

    def test_build_drivetrain_chain_loop(self):
        bm = bmesh.new()
        gcd.build_drivetrain_chain_loop(bm)
        self.assertGreater(len(bm.faces), 40)
        bm.free()

    def test_build_bottle_cages_and_bottles(self):
        bm = bmesh.new()
        gcd.build_bottle_cages_and_bottles(bm)
        self.assertGreater(len(bm.faces), 200)
        bm.free()

    def test_build_short_nose_3d_printed_saddle(self):
        bm = bmesh.new()
        gcd.build_short_nose_3d_printed_saddle(bm)
        self.assertGreater(len(bm.faces), 30)

        # Check saddle width ~145mm (half_w ~0.0725)
        ys = [v.co.y for v in bm.verts]
        self.assertAlmostEqual(max(ys), 0.0725, places=2)
        bm.free()

    # -------------------------------------------------------------------------
    # High-Level Assembly & glTF Export Tests
    # -------------------------------------------------------------------------

    def test_generate_components_pack_mesh(self):
        comp_obj = gcd.generate_components_pack_mesh("Test_Components_Pack")
        self.assertIsNotNone(comp_obj)
        self.assertEqual(comp_obj.type, "MESH")

        mesh = comp_obj.data
        self.assertGreater(len(mesh.vertices), 1200)
        self.assertGreater(len(mesh.polygons), 1000)

        # Verify all 4 material slots are present
        mat_names = [m.name for m in mesh.materials]
        self.assertEqual(len(mat_names), 4)
        self.assertIn("M_Components_Carbon", mat_names)
        self.assertIn("M_Components_Metal", mat_names)
        self.assertIn("M_Hoods_Rubber", mat_names)
        self.assertIn("M_Bottle_Glossy", mat_names)

    def test_export_components_pack_glb(self):
        test_glb_path = "assets/3d/bikes/test_components_export.glb"
        if os.path.exists(test_glb_path):
            os.remove(test_glb_path)

        comp_asset, glb_path = gcd.export_components_pack(output_glb_path=test_glb_path)
        self.assertIsNotNone(comp_asset)
        self.assertTrue(os.path.exists(glb_path))

        # Check binary glTF magic header
        with open(glb_path, "rb") as f:
            magic = f.read(4)
            self.assertEqual(magic, b"glTF")

        # Check reasonable file size (> 50 KB)
        size_kb = os.path.getsize(glb_path) / 1024.0
        self.assertGreater(size_kb, 50.0)

        if os.path.exists(test_glb_path):
            os.remove(test_glb_path)


if __name__ == "__main__":
    runner = unittest.TextTestRunner(verbosity=2)
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(TestGenerateCockpitAndDrivetrain)
    result = runner.run(suite)
    sys.exit(0 if result.wasSuccessful() else 1)

