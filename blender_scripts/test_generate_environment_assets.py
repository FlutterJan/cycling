"""
===============================================================================
PRO PELOTON MANAGER - ENVIRONMENT ASSETS GENERATOR UNIT TESTS
===============================================================================
Automated test suite verifying the procedural generation and glTF 2.0 binary
export of low/mid-poly roadside scenery, vegetation, geological terrain props,
buildings, and cheering spectators.
===============================================================================
"""

import math
import os
import struct
import sys
import tempfile
import unittest

try:
    import bpy
    import bmesh
    from mathutils import Vector
except ImportError:
    print("[ERROR] 'bpy' / 'mathutils' not found. Run within Blender:")
    print("        blender --background --python blender_scripts/test_generate_environment_assets.py")
    sys.exit(1)

# Ensure script dir in path
script_dir = os.path.dirname(os.path.abspath(__file__))
if script_dir not in sys.path:
    sys.path.insert(0, script_dir)

import generate_environment_assets as gea
import style_and_materials as sm


class TestEnvironmentAssetsGeneration(unittest.TestCase):
    """Test suite for procedural environment geometry, materials, and exports."""

    def setUp(self):
        """Clean mesh objects before each test."""
        for obj in list(bpy.context.scene.objects):
            if obj.type == "MESH":
                bpy.data.objects.remove(obj, do_unlink=True)

    def test_materials_creation(self):
        """Verifies that all environment PBR materials are created properly."""
        mat_pine = gea.create_pine_foliage_material()
        self.assertIsNotNone(mat_pine)

        mat_cypress = gea.create_cypress_foliage_material()
        self.assertIsNotNone(mat_cypress)

        mat_decid = gea.create_deciduous_foliage_material()
        self.assertIsNotNone(mat_decid)

        mat_bark = gea.create_wood_bark_material()
        self.assertIsNotNone(mat_bark)

        mat_rock = gea.create_granite_rock_material()
        self.assertIsNotNone(mat_rock)

        mat_snow = gea.create_mountain_snow_material()
        self.assertIsNotNone(mat_snow)

        mat_stucco = gea.create_townhouse_wall_material()
        self.assertIsNotNone(mat_stucco)

        mat_roof = gea.create_terracotta_roof_material()
        self.assertIsNotNone(mat_roof)

        mat_spec = gea.create_spectator_color_material("#FACC15", "M_Test_Spectator")
        self.assertIsNotNone(mat_spec)

    def test_trees_geometry(self):
        """Validates Alpine Pine, Italian Cypress, and Deciduous Oak tree meshes."""
        # 1. Pine Tree
        obj_pine = gea.generate_pine_tree_mesh(name="Test_Pine")
        self.assertIsNotNone(obj_pine)
        bbox = [obj_pine.matrix_world @ Vector(corner) for corner in obj_pine.bound_box]
        height_pine = max(v.z for v in bbox) - min(v.z for v in bbox)
        self.assertAlmostEqual(height_pine, 7.80, delta=0.50, msg=f"Pine height {height_pine:.2f}m unexpected")
        self.assertEqual(len(obj_pine.data.materials), 2)
        bpy.data.objects.remove(obj_pine, do_unlink=True)

        # 2. Cypress Tree
        obj_cyp = gea.generate_cypress_tree_mesh(name="Test_Cypress")
        self.assertIsNotNone(obj_cyp)
        bbox = [obj_cyp.matrix_world @ Vector(corner) for corner in obj_cyp.bound_box]
        height_cyp = max(v.z for v in bbox) - min(v.z for v in bbox)
        width_cyp = max(v.x for v in bbox) - min(v.x for v in bbox)
        self.assertAlmostEqual(height_cyp, 9.20, delta=0.50, msg=f"Cypress height {height_cyp:.2f}m unexpected")
        self.assertLess(width_cyp, 1.60, f"Cypress width {width_cyp:.2f}m too wide for slender column")
        bpy.data.objects.remove(obj_cyp, do_unlink=True)

        # 3. Deciduous Oak Tree
        obj_decid = gea.generate_deciduous_tree_mesh(name="Test_Deciduous")
        self.assertIsNotNone(obj_decid)
        bbox = [obj_decid.matrix_world @ Vector(corner) for corner in obj_decid.bound_box]
        height_dec = max(v.z for v in bbox) - min(v.z for v in bbox)
        width_dec = max(v.x for v in bbox) - min(v.x for v in bbox)
        self.assertAlmostEqual(height_dec, 7.20, delta=0.60, msg=f"Deciduous height {height_dec:.2f}m unexpected")
        self.assertGreater(width_dec, 4.0, f"Deciduous canopy {width_dec:.2f}m should spread widely")
        bpy.data.objects.remove(obj_decid, do_unlink=True)

    def test_mountain_boulder_and_peak_geometry(self):
        """Validates the mountain boulder and distant snow-capped peak."""
        # 1. Boulder
        obj_rock = gea.generate_mountain_boulder_mesh(name="Test_Boulder")
        self.assertIsNotNone(obj_rock)
        bbox = [obj_rock.matrix_world @ Vector(corner) for corner in obj_rock.bound_box]
        width_rock = max(v.x for v in bbox) - min(v.x for v in bbox)
        height_rock = max(v.z for v in bbox) - min(v.z for v in bbox)
        self.assertAlmostEqual(width_rock, 3.05, delta=0.30, msg=f"Rock width {width_rock:.2f}m unexpected")
        self.assertAlmostEqual(height_rock, 1.85, delta=0.20, msg=f"Rock height {height_rock:.2f}m unexpected")
        bpy.data.objects.remove(obj_rock, do_unlink=True)

        # 2. Snow Peak
        obj_peak = gea.generate_mountain_snow_peak_mesh(name="Test_Peak")
        self.assertIsNotNone(obj_peak)
        bbox = [obj_peak.matrix_world @ Vector(corner) for corner in obj_peak.bound_box]
        span_peak = max(v.x for v in bbox) - min(v.x for v in bbox)
        height_peak = max(v.z for v in bbox) - min(v.z for v in bbox)
        self.assertGreater(span_peak, 70.0, f"Mountain span {span_peak:.2f}m should form wide horizon ridge")
        self.assertGreater(height_peak, 30.0, f"Mountain peak {height_peak:.2f}m should tower on horizon")
        self.assertEqual(len(obj_peak.data.materials), 2, "Peak should have rock base and snowpack")
        bpy.data.objects.remove(obj_peak, do_unlink=True)

    def test_townhouse_geometry(self):
        """Validates the European village townhouse building."""
        obj_house = gea.generate_european_townhouse_mesh(name="Test_Townhouse")
        self.assertIsNotNone(obj_house)

        bbox = [obj_house.matrix_world @ Vector(corner) for corner in obj_house.bound_box]
        width_house = max(v.x for v in bbox) - min(v.x for v in bbox)
        depth_house = max(v.y for v in bbox) - min(v.y for v in bbox)
        height_house = max(v.z for v in bbox) - min(v.z for v in bbox)

        self.assertAlmostEqual(width_house, 7.00, delta=0.50, msg=f"Townhouse width {width_house:.2f}m unexpected")
        self.assertAlmostEqual(depth_house, 8.00, delta=0.50, msg=f"Townhouse depth {depth_house:.2f}m unexpected")
        self.assertAlmostEqual(height_house, 8.90, delta=0.50, msg=f"Townhouse height {height_house:.2f}m unexpected")

        mesh = obj_house.data
        self.assertEqual(len(mesh.materials), 6, "Townhouse should have 6 materials (stucco, roof, wood, shutters, glass, concrete)")
        bpy.data.objects.remove(obj_house, do_unlink=True)

    def test_spectators_geometry(self):
        """Validates the cluster of 4 cheering cycling fans with flag and camera."""
        obj_fans = gea.generate_spectators_cluster_mesh(name="Test_Spectators")
        self.assertIsNotNone(obj_fans)

        bbox = [obj_fans.matrix_world @ Vector(corner) for corner in obj_fans.bound_box]
        width_fans = max(v.x for v in bbox) - min(v.x for v in bbox)
        height_fans = max(v.z for v in bbox) - min(v.z for v in bbox)

        self.assertGreater(width_fans, 2.20, f"Spectator cluster width {width_fans:.2f}m too narrow for 4 fans")
        self.assertGreater(height_fans, 2.50, f"Spectator height with waving flagpole {height_fans:.2f}m too low")

        mesh = obj_fans.data
        self.assertGreater(len(mesh.vertices), 300, "Spectators cluster should have detailed limbs & caps")
        self.assertEqual(len(mesh.materials), 6, "Spectators should have 6 colorful fan materials")
        bpy.data.objects.remove(obj_fans, do_unlink=True)

    def test_export_all_environment_assets(self):
        """Verifies the complete glTF 2.0 binary export pipeline and valid glTF headers."""
        with tempfile.TemporaryDirectory() as tmp_dir:
            exported = gea.export_all_environment_assets(output_dir=tmp_dir)

            required_keys = [
                "env_pack",
                "tree_pine",
                "tree_cypress",
                "tree_deciduous",
                "rock_boulder",
                "mountain_peak",
                "building_townhouse",
                "spectators_cheering",
            ]
            for key in required_keys:
                self.assertIn(key, exported, f"Missing export key '{key}'")
                path = exported[key]
                self.assertTrue(os.path.isfile(path), f"Export file '{path}' was not created")
                fsize = os.path.getsize(path)
                self.assertGreater(fsize, 1024, f"File '{path}' size {fsize} bytes is suspiciously small")

                # Validate binary glTF header (magic 0x46546C67 = "glTF", version 2)
                with open(path, "rb") as f:
                    magic, version, length = struct.unpack("<4sII", f.read(12))
                    self.assertEqual(magic, b"glTF", f"File '{path}' is not a valid binary glTF file")
                    self.assertEqual(version, 2, f"File '{path}' glTF version is {version}, expected 2")
                    self.assertEqual(length, fsize, f"Header length {length} != file size {fsize}")


def run_tests():
    """Runs test suite within Blender's Python environment."""
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(TestEnvironmentAssetsGeneration)
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    sys.exit(0 if result.wasSuccessful() else 1)


if __name__ == "__main__":
    run_tests()
