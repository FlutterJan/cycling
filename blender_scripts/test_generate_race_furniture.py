"""
===============================================================================
PRO PELOTON MANAGER - RACE FURNITURE GENERATOR UNIT TESTS
===============================================================================
Automated test suite verifying the procedural generation and glTF 2.0 binary
export of cycling race infrastructure (crowd barriers, finish gantry, Flamme Rouge,
and KOM/Sprint arches).
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
    print("        blender --background --python blender_scripts/test_generate_race_furniture.py")
    sys.exit(1)

# Ensure script dir in path
script_dir = os.path.dirname(os.path.abspath(__file__))
if script_dir not in sys.path:
    sys.path.insert(0, script_dir)

import generate_race_furniture as grf
import style_and_materials as sm


class TestRaceFurnitureGeneration(unittest.TestCase):
    """Test suite for procedural race furniture geometry, materials, and exports."""

    def setUp(self):
        """Clean mesh objects before each test."""
        for obj in list(bpy.context.scene.objects):
            if obj.type == "MESH":
                bpy.data.objects.remove(obj, do_unlink=True)

    def test_materials_creation(self):
        """Verifies that all race infrastructure PBR materials are created properly."""
        mat_truss = grf.create_aluminum_truss_material()
        self.assertIsNotNone(mat_truss)
        self.assertEqual(mat_truss.name, "M_Truss_Aluminum")

        mat_steel = grf.create_galvanized_steel_material()
        self.assertIsNotNone(mat_steel)

        mat_blue = grf.create_sponsor_banner_material("finish_blue")
        self.assertIsNotNone(mat_blue)

        mat_pvc = grf.create_inflatable_pvc_material("#DC2626")
        self.assertIsNotNone(mat_pvc)

        mat_led = grf.create_digital_clock_led_material("#22C55E")
        self.assertIsNotNone(mat_led)
        # Check emission socket exists and has strength
        nodes = mat_led.node_tree.nodes
        bsdf = next(n for n in nodes if n.type == "BSDF_PRINCIPLED")
        self.assertIsNotNone(bsdf)

        mat_foam = grf.create_safety_padding_material("#FACC15")
        self.assertIsNotNone(mat_foam)

        mat_rubber = grf.create_rubber_boot_material()
        self.assertIsNotNone(mat_rubber)

        mat_polka = grf.create_polka_dot_material()
        self.assertIsNotNone(mat_polka)

    def test_finish_barrier_geometry(self):
        """Validates the crowd control barrier dimensions, components, and materials."""
        obj = grf.generate_finish_barrier_mesh(name="Test_Barrier")
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
        depth_y = max_y - min_y
        height_z = max_z - min_z

        # Standard crowd barrier: ~2.0m width (with side latches ~2.09m), ~1.05m height, ~0.50m foot depth
        self.assertAlmostEqual(width_x, 2.09, delta=0.15, msg=f"Barrier width {width_x:.2f}m unexpected")
        self.assertAlmostEqual(height_z, 1.06, delta=0.10, msg=f"Barrier height {height_z:.2f}m unexpected")
        self.assertAlmostEqual(depth_y, 0.50, delta=0.08, msg=f"Barrier foot depth {depth_y:.2f}m unexpected")

        # Check vertex & polygon count
        mesh = obj.data
        self.assertGreater(len(mesh.vertices), 200, "Barrier mesh should have detailed pickets & frame")
        self.assertGreater(len(mesh.polygons), 100, "Barrier mesh face count too low")

        # Check 5 materials assigned (Steel, Banner Navy, Banner Gold, Safety Foam, Rubber)
        self.assertEqual(len(mesh.materials), 5)
        mat_names = [m.name for m in mesh.materials]
        self.assertIn("M_Barrier_Galvanized", mat_names)
        self.assertIn("M_Sponsor_Finish_blue", mat_names)
        self.assertIn("M_Safety_Foam_Yellow", mat_names)

        bpy.data.objects.remove(obj, do_unlink=True)

    def test_finish_arch_gantry_geometry(self):
        """Validates the Finish Line Gantry truss, timing clock, and finish line decal."""
        obj = grf.generate_finish_arch_mesh(name="Test_Finish_Gantry")
        self.assertIsNotNone(obj)

        bbox = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
        min_x = min(v.x for v in bbox)
        max_x = max(v.x for v in bbox)
        min_z = min(v.z for v in bbox)
        max_z = max(v.z for v in bbox)

        span_x = max_x - min_x
        height_z = max_z - min_z

        # Gantry span: spans the 7m road + verges (towers at +/-4.55m -> total width ~10.4m)
        self.assertGreater(span_x, 9.0, f"Finish gantry span {span_x:.2f}m too narrow for 7m roadbed")
        # Gantry height: clearance 4.8m, gantry top 6.2m
        self.assertGreater(height_z, 6.0, f"Finish gantry height {height_z:.2f}m too low")

        mesh = obj.data
        self.assertGreater(len(mesh.vertices), 1000, "Gantry should have rich truss lacing & clock digits")
        self.assertGreater(len(mesh.polygons), 500, "Gantry polygon count too low")

        # Check that material slots include Truss, LED Clock, Checkered Decal
        mat_names = [m.name for m in mesh.materials]
        self.assertIn("M_Truss_Aluminum", mat_names)
        self.assertIn("M_LED_Clock_Glow", mat_names)
        self.assertIn("M_Floodlight_White", mat_names)

        bpy.data.objects.remove(obj, do_unlink=True)

    def test_flamme_rouge_arch_geometry(self):
        """Validates the 1 KM Flamme Rouge inflatable arch and suspended red pennant."""
        obj = grf.generate_flamme_rouge_arch_mesh(name="Test_Flamme_Rouge")
        self.assertIsNotNone(obj)

        bbox = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
        min_x = min(v.x for v in bbox)
        max_x = max(v.x for v in bbox)
        max_z = max(v.z for v in bbox)

        span_x = max_x - min_x
        # Span should be ~8.2m to 9.5m (accounting for base footings)
        self.assertGreater(span_x, 8.5, f"Flamme Rouge span {span_x:.2f}m too narrow")
        self.assertGreater(max_z, 5.0, f"Flamme Rouge apex {max_z:.2f}m too low")

        mesh = obj.data
        self.assertGreater(len(mesh.vertices), 300, "Inflatable arch should be smoothly lofted")

        # Check materials: Red PVC, White Decal, Gold Fringe, Rubber Base
        mat_names = [m.name for m in mesh.materials]
        self.assertIn("M_Inflatable_PVC", mat_names)
        self.assertIn("M_Sponsor_Kom_white", mat_names)

        bpy.data.objects.remove(obj, do_unlink=True)

    def test_kom_and_sprint_arches_geometry(self):
        """Validates the KOM mountain summit arch and Intermediate Sprint arch."""
        obj_kom = grf.generate_kom_arch_mesh(name="Test_Arch_KOM")
        self.assertIsNotNone(obj_kom)
        mat_kom = [m.name for m in obj_kom.data.materials]
        self.assertIn("M_KOM_Polka_Dot_Red", mat_kom)
        bpy.data.objects.remove(obj_kom, do_unlink=True)

        obj_sprint = grf.generate_sprint_arch_mesh(name="Test_Arch_Sprint")
        self.assertIsNotNone(obj_sprint)
        mat_sprint = [m.name for m in obj_sprint.data.materials]
        self.assertIn("M_Sponsor_Sprint_green", mat_sprint)
        self.assertIn("M_LED_Clock_Glow", mat_sprint)
        bpy.data.objects.remove(obj_sprint, do_unlink=True)

    def test_export_all_race_furniture(self):
        """Verifies the complete glTF 2.0 binary export pipeline and valid glTF headers."""
        with tempfile.TemporaryDirectory() as tmp_dir:
            exported = grf.export_all_race_furniture(output_dir=tmp_dir)

            required_keys = [
                "barrier_finish",
                "arch_finish",
                "arch_flamme_rouge",
                "arch_kom_sprint",
                "arch_kom",
                "arch_sprint",
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
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(TestRaceFurnitureGeneration)
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    sys.exit(0 if result.wasSuccessful() else 1)


if __name__ == "__main__":
    run_tests()

