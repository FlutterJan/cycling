"""
===============================================================================
PRO PELOTON MANAGER - MODULAR ROAD TILES GENERATOR UNIT TESTS
===============================================================================
Automated unit test suite verifying procedural 3D generation of modular
road segments and terrain tiles:
  1. Gładki asfalt z liniami i napisami szosowymi (`road_asphalt.glb`)
  2. Sektor bruku z wypukłymi kamieniami i poboczem (`road_cobbles.glb`)
  3. Górska serpentyna z kamiennym murkiem ochronnym (`road_mountain_hairpin.glb`)

Run via:
  blender --background --python blender_scripts/test_generate_road_tiles.py
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

import generate_road_tiles as grt
import style_and_materials as sm


class TestGenerateRoadTiles(unittest.TestCase):
    """Test suite for modular road tiles and race terrain generator."""

    def setUp(self):
        """Clear all mesh objects before each test."""
        for obj in [o for o in bpy.context.scene.objects if o.type == "MESH"]:
            bpy.data.objects.remove(obj, do_unlink=True)

    def test_road_materials(self):
        """Verifies that all specialized road and terrain materials are instantiated correctly."""
        asphalt = grt.create_asphalt_material("Test_Asphalt")
        self.assertIsNotNone(asphalt.node_tree)
        self.assertTrue(any("Asphalt" in n.name or "Grain" in n.name for n in asphalt.node_tree.nodes))

        paint = grt.create_marking_paint_material("#F8FAFC", "Test_Paint")
        self.assertIsNotNone(paint.node_tree)

        grass = grt.create_roadside_grass_material("Test_Grass")
        self.assertIsNotNone(grass.node_tree)

        cobble = grt.create_cobblestone_material("Test_Cobble")
        self.assertIsNotNone(cobble.node_tree)

        dirt = grt.create_dirt_gutter_material("Test_Dirt")
        self.assertIsNotNone(dirt.node_tree)

        wall = grt.create_stone_wall_material("Test_Wall")
        self.assertIsNotNone(wall.node_tree)

        cliff = grt.create_cliff_rock_material("Test_Cliff")
        self.assertIsNotNone(cliff.node_tree)

    def test_generate_asphalt_road_tile(self):
        """Verifies smooth asphalt road dimensions, crowned camber, markings, and graffiti."""
        obj = grt.generate_asphalt_road_tile(name="Test_Asphalt_Tile", length=20.0, road_width=7.0)
        self.assertEqual(obj.type, "MESH")
        self.assertEqual(len(obj.data.materials), 6)
        self.assertGreater(len(obj.data.polygons), 40)

        # Length check along Y: -10.0 to +10.0
        min_y = min(v.co.y for v in obj.data.vertices)
        max_y = max(v.co.y for v in obj.data.vertices)
        self.assertAlmostEqual(min_y, -10.0, delta=0.01)
        self.assertAlmostEqual(max_y, 10.0, delta=0.01)

        # Crowned camber: center (x=0) should be higher than asphalt edge (x=3.5)
        verts_center = [v for v in obj.data.vertices if abs(v.co.x) < 0.05 and abs(v.co.z) < 0.05]
        verts_edge = [v for v in obj.data.vertices if abs(abs(v.co.x) - 3.5) < 0.05 and abs(v.co.z) < 0.05]
        self.assertTrue(len(verts_center) > 0)
        self.assertTrue(len(verts_edge) > 0)
        self.assertGreater(verts_center[0].co.z, verts_edge[0].co.z)

    def test_generate_cobblestone_road_tile(self):
        """Verifies pavé sector dimensions, arched crown, mud gutters, and wooden marker post."""
        obj = grt.generate_cobblestone_road_tile(name="Test_Cobbles_Tile", length=20.0, pave_width=4.5)
        self.assertEqual(obj.type, "MESH")
        self.assertEqual(len(obj.data.materials), 4)
        self.assertGreater(len(obj.data.polygons), 150)

        # Parabolic crown arch check: maximum Z on pavé blocks should reach ~0.12m
        max_pave_z = max(v.co.z for v in obj.data.vertices if abs(v.co.x) < 2.25 and v.co.z < 0.5)
        self.assertGreater(max_pave_z, 0.10)

        # Wooden marker post should stand upright (max Z > 1.0m)
        max_z = max(v.co.z for v in obj.data.vertices)
        self.assertGreater(max_z, 1.0)

    def test_generate_mountain_hairpin_tile(self):
        """Verifies 180° switchback curve, 3.5m vertical climb, stone guard wall, and cliff face."""
        obj = grt.generate_mountain_hairpin_tile(name="Test_Hairpin_Tile", climb_height=3.50, radius=7.50)
        self.assertEqual(obj.type, "MESH")
        self.assertEqual(len(obj.data.materials), 4)
        self.assertGreater(len(obj.data.polygons), 100)

        # Vertical elevation gain check: road should climb 3.5m
        road_verts = [v for v in obj.data.vertices if v.co.z >= 0.0]
        min_road_z = min(v.co.z for v in road_verts)
        max_road_z = max(v.co.z for v in road_verts)
        self.assertAlmostEqual(min_road_z, 0.0, delta=0.05)
        self.assertGreaterEqual(max_road_z, 3.50)

        # Deep mountain abyss drop check: cliff should descend to Z < -4.0m
        min_cliff_z = min(v.co.z for v in obj.data.vertices)
        self.assertLess(min_cliff_z, -4.0)

        # 180 degree lateral sweep span: X should span across curve diameter (~18m)
        min_x = min(v.co.x for v in obj.data.vertices)
        max_x = max(v.co.x for v in obj.data.vertices)
        self.assertGreater(max_x - min_x, 15.0)

    def test_modular_connectivity(self):
        """Verifies modular alignment and connection interfaces of road tiles."""
        obj_asphalt = grt.generate_asphalt_road_tile()
        obj_cobbles = grt.generate_cobblestone_road_tile()
        obj_hairpin = grt.generate_mountain_hairpin_tile()

        # Asphalt tile connects at Y = -10.0 and Y = +10.0
        asphalt_y_min = min(v.co.y for v in obj_asphalt.data.vertices)
        asphalt_y_max = max(v.co.y for v in obj_asphalt.data.vertices)
        self.assertAlmostEqual(asphalt_y_min, -10.0, delta=0.01)
        self.assertAlmostEqual(asphalt_y_max, 10.0, delta=0.01)

        # Cobblestone tile connects at Y = -10.0 and Y = +10.0
        cobbles_y_min = min(v.co.y for v in obj_cobbles.data.vertices)
        cobbles_y_max = max(v.co.y for v in obj_cobbles.data.vertices)
        self.assertAlmostEqual(cobbles_y_min, -10.0, delta=0.01)
        self.assertAlmostEqual(cobbles_y_max, 10.0, delta=0.01)

        # Hairpin apex wraps smoothly: entry is negative X (-3.75), exit is positive X (+11.25)
        entry_verts = [v for v in obj_hairpin.data.vertices if abs(v.co.y) < 1.0 and v.co.x < 0.0]
        exit_verts = [v for v in obj_hairpin.data.vertices if abs(v.co.y) < 1.0 and v.co.x > 5.0]
        self.assertTrue(len(entry_verts) > 0)
        self.assertTrue(len(exit_verts) > 0)

    def test_export_all_road_tiles(self):
        """Verifies export of all 3 modular road tile assets to binary glTF (.glb) files."""
        temp_dir = "assets/3d/roads/test_roads_export"
        try:
            exported = grt.export_all_road_tiles(output_dir=temp_dir)
            self.assertEqual(len(exported), 3)

            expected_keys = ["asphalt", "cobbles", "hairpin"]
            for k in expected_keys:
                self.assertIn(k, exported)
                path = exported[k]
                self.assertTrue(os.path.exists(path), f"File {path} does not exist")
                size_kb = os.path.getsize(path) / 1024.0
                self.assertGreater(size_kb, 5.0, f"File {path} too small: {size_kb} KB")

                # Verify valid glTF 2.0 binary header
                with open(path, "rb") as f:
                    magic = f.read(4)
                    self.assertEqual(magic, b"glTF")
        finally:
            if os.path.exists(temp_dir):
                import shutil
                shutil.rmtree(temp_dir, ignore_errors=True)


if __name__ == "__main__":
    runner = unittest.TextTestRunner(verbosity=2)
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(TestGenerateRoadTiles)
    result = runner.run(suite)
    sys.exit(0 if result.wasSuccessful() else 1)

