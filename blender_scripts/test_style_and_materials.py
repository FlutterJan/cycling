"""
===============================================================================
UNIT TESTS: BLENDER 3D VISUAL STYLE & PBR MATERIAL SYSTEM
===============================================================================
Runs automated tests within Blender's Python runtime to verify:
  - Color conversions (sRGB HEX <-> Linear RGBA)
  - All 6 PBR material generators and their shader node graphs
  - Zwift-style smooth shading and mesh cleaning utilities
  - Studio lighting and showroom generation
===============================================================================
"""

import math
import os
import sys
import unittest

# Ensure the blender_scripts directory is in python module search path
current_dir = os.path.dirname(os.path.abspath(__file__))
if current_dir not in sys.path:
    sys.path.insert(0, current_dir)

import bpy
import style_and_materials as sm


class TestStyleAndMaterials(unittest.TestCase):

    def setUp(self):
        # Reset Blender to clean empty state before each test
        bpy.ops.wm.read_factory_settings(use_empty=True)

    # -------------------------------------------------------------------------
    # Color Conversion Tests
    # -------------------------------------------------------------------------

    def test_hex_to_linear_rgb_pure_colors(self):
        # Pure Black
        black = sm.hex_to_linear_rgb("#000000")
        self.assertAlmostEqual(black[0], 0.0, places=4)
        self.assertAlmostEqual(black[1], 0.0, places=4)
        self.assertAlmostEqual(black[2], 0.0, places=4)
        self.assertAlmostEqual(black[3], 1.0, places=4)

        # Pure White
        white = sm.hex_to_linear_rgb("#FFFFFF")
        self.assertAlmostEqual(white[0], 1.0, places=4)
        self.assertAlmostEqual(white[1], 1.0, places=4)
        self.assertAlmostEqual(white[2], 1.0, places=4)

        # Short 3-char HEX (#FFF)
        short_white = sm.hex_to_linear_rgb("#FFF")
        self.assertAlmostEqual(short_white[0], 1.0, places=4)

    def test_hex_to_linear_rgb_gamma_curve(self):
        # 50% sRGB gray (128/255 = ~0.50196) should be around ~0.214 in Linear RGB
        mid_gray = sm.hex_to_linear_rgb("#808080")
        self.assertTrue(0.21 < mid_gray[0] < 0.22)

    def test_hex_to_linear_rgb_invalid_format(self):
        with self.assertRaises(ValueError):
            sm.hex_to_linear_rgb("INVALID")

    def test_linear_to_hex_roundtrip(self):
        hex_input = "#E10600"
        linear_val = sm.hex_to_linear_rgb(hex_input)
        reconstructed_hex = sm.linear_to_hex((linear_val[0], linear_val[1], linear_val[2]))
        self.assertEqual(reconstructed_hex, hex_input)

    # -------------------------------------------------------------------------
    # Material Generator Tests
    # -------------------------------------------------------------------------

    def test_create_carbon_matte_material(self):
        mat = sm.create_carbon_matte_material(name="Test_Carbon")
        self.assertIsNotNone(mat)
        self.assertIsNotNone(mat.node_tree)

        nodes = mat.node_tree.nodes
        bsdf = nodes.get("Principled BSDF")
        self.assertIsNotNone(bsdf)

        # Verify weave bump and brick texture present
        self.assertIsNotNone(nodes.get("Carbon_Twill_Weave"))
        self.assertIsNotNone(nodes.get("Carbon_Twill_Bump"))

        # Matte specifications
        self.assertAlmostEqual(bsdf.inputs["Roughness"].default_value, 0.52, places=2)
        if "Coat Weight" in bsdf.inputs:
            self.assertAlmostEqual(bsdf.inputs["Coat Weight"].default_value, 0.0, places=2)

    def test_create_glossy_frame_paint_material(self):
        hex_red = "#E10600"
        mat = sm.create_glossy_frame_paint_material(hex_color=hex_red, coat_roughness=0.03)
        self.assertIsNotNone(mat)

        nodes = mat.node_tree.nodes
        bsdf = nodes.get("Principled BSDF")
        self.assertIsNotNone(bsdf)

        # Verify coat settings
        coat_socket = "Coat Weight" if "Coat Weight" in bsdf.inputs else "Clearcoat"
        self.assertAlmostEqual(bsdf.inputs[coat_socket].default_value, 1.0, places=2)

        coat_roughness_socket = (
            "Coat Roughness" if "Coat Roughness" in bsdf.inputs else "Clearcoat Roughness"
        )
        self.assertAlmostEqual(bsdf.inputs[coat_roughness_socket].default_value, 0.03, places=2)

    def test_create_tire_rubber_material_tan_wall(self):
        mat = sm.create_tire_rubber_material(tan_wall=True)
        self.assertIsNotNone(mat)

        nodes = mat.node_tree.nodes
        bsdf = nodes.get("Principled BSDF")
        self.assertIsNotNone(bsdf)

        # Tan-wall gradient ramp must exist
        ramp_node = nodes.get("TanWall_Mask_Ramp")
        self.assertIsNotNone(ramp_node)
        self.assertGreaterEqual(len(ramp_node.color_ramp.elements), 4)

        # Rubber grain bump node must exist
        self.assertIsNotNone(nodes.get("Rubber_Grain"))

    def test_create_tire_rubber_material_black(self):
        mat = sm.create_tire_rubber_material(tan_wall=False)
        self.assertIsNotNone(mat)

        nodes = mat.node_tree.nodes
        bsdf = nodes.get("Principled BSDF")
        self.assertIsNotNone(bsdf)
        self.assertAlmostEqual(bsdf.inputs["Roughness"].default_value, 0.74, places=2)

    def test_create_metal_rotor_material(self):
        mat = sm.create_metal_rotor_material()
        self.assertIsNotNone(mat)

        nodes = mat.node_tree.nodes
        bsdf = nodes.get("Principled BSDF")
        self.assertIsNotNone(bsdf)

        self.assertAlmostEqual(bsdf.inputs["Metallic"].default_value, 1.0, places=2)
        if "Anisotropic" in bsdf.inputs:
            self.assertAlmostEqual(bsdf.inputs["Anisotropic"].default_value, 0.85, places=2)

        # Concentric radial grind pattern wave node must exist
        wave_node = nodes.get("Rotor_Radial_Grind_Lines")
        self.assertIsNotNone(wave_node)
        self.assertEqual(wave_node.wave_type, "RINGS")
        self.assertEqual(wave_node.rings_direction, "SPHERICAL")

    def test_create_lycra_fabric_material(self):
        mat = sm.create_lycra_fabric_material(hex_color="#1E3A8A", sheen_weight=1.0)
        self.assertIsNotNone(mat)

        nodes = mat.node_tree.nodes
        bsdf = nodes.get("Principled BSDF")
        self.assertIsNotNone(bsdf)

        sheen_socket = "Sheen Weight" if "Sheen Weight" in bsdf.inputs else "Sheen"
        self.assertAlmostEqual(bsdf.inputs[sheen_socket].default_value, 1.0, places=2)
        self.assertIsNotNone(nodes.get("Fabric_Knit_Weave"))

    def test_create_visor_iridium_material(self):
        mat = sm.create_visor_iridium_material()
        self.assertIsNotNone(mat)

        nodes = mat.node_tree.nodes
        bsdf = nodes.get("Principled BSDF")
        self.assertIsNotNone(bsdf)

        # Multi-color iridium ramp & layer weight facing angle
        self.assertIsNotNone(nodes.get("Iridium_Facing_Angle"))
        self.assertIsNotNone(nodes.get("Iridium_Spectral_Ramp"))

        # Mirror & optical IOR properties
        self.assertAlmostEqual(bsdf.inputs["Roughness"].default_value, 0.03, places=2)
        self.assertAlmostEqual(bsdf.inputs["IOR"].default_value, 1.58, places=2)

    # -------------------------------------------------------------------------
    # Mesh Style & Utilities Tests
    # -------------------------------------------------------------------------

    def test_apply_zwift_style(self):
        bpy.ops.mesh.primitive_cylinder_add(radius=1.0, depth=2.0)
        obj = bpy.context.active_object

        sm.apply_zwift_style(obj, auto_smooth_angle_deg=35.0)

        # All polygons should be flagged smooth
        for poly in obj.data.polygons:
            self.assertTrue(poly.use_smooth)

    def test_clean_zwift_mesh(self):
        bpy.ops.mesh.primitive_cube_add()
        obj = bpy.context.active_object
        sm.clean_zwift_mesh(obj)
        self.assertEqual(len(obj.data.vertices), 8)

    def test_create_material_showcase_scene(self):
        showcase = sm.create_material_showcase_scene()
        self.assertEqual(len(showcase), 6)
        self.assertIn("frame", showcase)
        self.assertIn("carbon", showcase)
        self.assertIn("tire", showcase)
        self.assertIn("rotor", showcase)
        self.assertIn("lycra", showcase)
        self.assertIn("visor", showcase)

        # Verify studio lights exist
        lights = [o for o in bpy.context.scene.objects if o.type == "LIGHT"]
        self.assertEqual(len(lights), 3)

        # Verify camera exists
        self.assertIsNotNone(bpy.context.scene.camera)


if __name__ == "__main__":
    runner = unittest.TextTestRunner(verbosity=2)
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(TestStyleAndMaterials)
    result = runner.run(suite)
    sys.exit(0 if result.wasSuccessful() else 1)
