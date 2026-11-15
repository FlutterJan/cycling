"""
===============================================================================
PRO PELOTON MANAGER - RACE SUPPORT VEHICLES UNIT TESTS
===============================================================================
Automated test suite verifying the procedural generation and glTF 2.0 binary
export of professional cycling convoy support vehicles (Directeur Sportif
Team Car kombi with 6 roof-mounted bikes & spare wheels, TV camera moto,
and Commissaire moto).
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
    print("        blender --background --python blender_scripts/test_generate_support_vehicles.py")
    sys.exit(1)

# Ensure script dir in path
script_dir = os.path.dirname(os.path.abspath(__file__))
if script_dir not in sys.path:
    sys.path.insert(0, script_dir)

import generate_support_vehicles as gsv
import style_and_materials as sm


class TestSupportVehiclesGeneration(unittest.TestCase):
    """Test suite for procedural support vehicle geometry, materials, and exports."""

    def setUp(self):
        """Clean mesh objects before each test."""
        for obj in list(bpy.context.scene.objects):
            if obj.type == "MESH":
                bpy.data.objects.remove(obj, do_unlink=True)

    def test_materials_creation(self):
        """Verifies that all vehicle PBR materials are created properly."""
        mat_paint = gsv.create_car_paint_material("#1E3A8A")
        self.assertIsNotNone(mat_paint)
        self.assertEqual(mat_paint.name, "M_Car_Paint_Team")

        mat_glass = gsv.create_vehicle_glass_material()
        self.assertIsNotNone(mat_glass)

        mat_trim = gsv.create_vehicle_trim_black_material()
        self.assertIsNotNone(mat_trim)

        mat_headlight = gsv.create_headlight_material()
        self.assertIsNotNone(mat_headlight)

        mat_taillight = gsv.create_taillight_material()
        self.assertIsNotNone(mat_taillight)

        mat_beacon = gsv.create_strobe_beacon_material("#F59E0B")
        self.assertIsNotNone(mat_beacon)

        mat_chrome = gsv.create_chrome_alloy_material()
        self.assertIsNotNone(mat_chrome)

        mat_vest = gsv.create_pilot_vest_material("#FACC15")
        self.assertIsNotNone(mat_vest)

    def test_team_car_geometry(self):
        """Validates the Directeur Sportif team car kombi, roof rack, and 6 spare bikes."""
        obj = gsv.generate_team_car_mesh(name="Test_Team_Car", team_color_hex="#1E3A8A")
        self.assertIsNotNone(obj)
        self.assertEqual(obj.type, "MESH")

        # Bounding box check
        bbox = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
        min_x = min(v.x for v in bbox)
        max_x = max(v.x for v in bbox)
        min_y = min(v.y for v in bbox)
        max_y = max(v.y for v in bbox)
        min_z = min(v.z for v in bbox)
        max_z = max(v.z for v in bbox)

        width_x = max_x - min_x
        length_y = max_y - min_y
        height_z = max_z - min_z

        # Station wagon dimensions: ~4.80m length, ~1.84m (with mirrors ~2.06m) width
        self.assertAlmostEqual(length_y, 4.88, delta=0.25, msg=f"Car length {length_y:.2f}m unexpected")
        self.assertAlmostEqual(width_x, 2.06, delta=0.20, msg=f"Car width {width_x:.2f}m unexpected")
        # Total height with roof rack + 6 bikes + antennas: ~2.40m to ~2.65m
        self.assertGreater(height_z, 2.20, f"Car height with bikes {height_z:.2f}m too low")
        self.assertLess(height_z, 2.80, f"Car height with bikes {height_z:.2f}m exceeds realistic profile")

        mesh = obj.data
        self.assertGreater(len(mesh.vertices), 1200, "Team car should have rich geometry for 6 bikes & wheels")
        self.assertGreater(len(mesh.polygons), 600, "Team car face count too low")

        # 9 material slots assigned
        self.assertEqual(len(mesh.materials), 9)
        mat_names = [m.name for m in mesh.materials]
        self.assertIn("M_Car_Paint_Team", mat_names)
        self.assertIn("M_Vehicle_Glass_Tinted", mat_names)
        self.assertIn("M_Headlight_LED", mat_names)
        self.assertIn("M_Taillight_Red", mat_names)

        bpy.data.objects.remove(obj, do_unlink=True)

    def test_moto_tv_geometry(self):
        """Validates the TV broadcast motorcycle, pilot, cameraman, and ENG camera."""
        obj = gsv.generate_moto_tv_mesh(name="Test_Moto_TV", is_commissaire=False)
        self.assertIsNotNone(obj)

        bbox = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
        min_x = min(v.x for v in bbox)
        max_x = max(v.x for v in bbox)
        min_y = min(v.y for v in bbox)
        max_y = max(v.y for v in bbox)
        min_z = min(v.z for v in bbox)
        max_z = max(v.z for v in bbox)

        width_x = max_x - min_x
        length_y = max_y - min_y
        height_z = max_z - min_z

        # Motorcycle dimensions: ~2.20m length, ~0.80m width, ~1.85m height (antenna)
        self.assertAlmostEqual(length_y, 2.15, delta=0.30, msg=f"Moto length {length_y:.2f}m unexpected")
        self.assertGreater(width_x, 0.70, f"Moto width {width_x:.2f}m too narrow")
        self.assertGreater(height_z, 1.70, f"Moto height with relay antenna {height_z:.2f}m too low")

        mesh = obj.data
        self.assertGreater(len(mesh.vertices), 500, "Moto TV mesh should have pilot, cameraman, and camera")
        self.assertGreater(len(mesh.polygons), 250, "Moto TV polygon count too low")

        # Check materials: High-Vis vest, Camera Gear, Headlights
        mat_names = [m.name for m in mesh.materials]
        self.assertIn("M_Pilot_HighVis_Vest", mat_names)
        self.assertIn("M_Camera_Gear", mat_names)

        bpy.data.objects.remove(obj, do_unlink=True)

    def test_moto_commissaire_geometry(self):
        """Validates the Commissaire motorcycle, official time board, and strobe."""
        obj = gsv.generate_moto_tv_mesh(name="Test_Moto_Commissaire", is_commissaire=True)
        self.assertIsNotNone(obj)

        mesh = obj.data
        self.assertGreater(len(mesh.vertices), 400, "Commissaire moto should have pilot, official, and timeboard")
        mat_names = [m.name for m in mesh.materials]
        self.assertIn("M_Pilot_HighVis_Vest", mat_names)
        self.assertIn("M_Moto_Accent_Red", mat_names)

        bpy.data.objects.remove(obj, do_unlink=True)

    def test_export_all_support_vehicles(self):
        """Verifies the complete glTF 2.0 binary export pipeline and valid glTF headers."""
        with tempfile.TemporaryDirectory() as tmp_dir:
            exported = gsv.export_all_support_vehicles(output_dir=tmp_dir)

            required_keys = ["team_car", "moto_tv", "moto_commissaire"]
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
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(TestSupportVehiclesGeneration)
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    sys.exit(0 if result.wasSuccessful() else 1)


if __name__ == "__main__":
    run_tests()

