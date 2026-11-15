"""
===============================================================================
PRO PELOTON MANAGER - HELMETS & GLASSES GENERATOR UNIT TESTS
===============================================================================
Automated unit test suite verifying procedural 3D generation of pro cycling
headwear:
  1. Przewiewny kask szosowy z otworami wentylacyjnymi (`helmet_vented.glb`)
  2. Zabudowany kask aerodynamiczny (`helmet_aero.glb`)
  3. Kask kroplowy do jazdy na czas z wizjerem (`helmet_tt.glb`)
  4. Szerokie okulary kolarskie z pojedynczą soczewką (`glasses_pro.glb`)

Run via:
  blender --background --python blender_scripts/test_generate_helmets_and_glasses.py
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

import generate_helmets_and_glasses as ghg
import style_and_materials as sm


class TestGenerateHelmetsAndGlasses(unittest.TestCase):
    """Test suite for procedural cycling helmets and eyewear generator."""

    def setUp(self):
        """Clear all mesh objects before each test."""
        for obj in [o for o in bpy.context.scene.objects if o.type == "MESH"]:
            bpy.data.objects.remove(obj, do_unlink=True)

    def test_materials(self):
        """Verifies that all specialized PBR materials are instantiated correctly."""
        eps = ghg.create_eps_foam_material("Test_EPS")
        self.assertIsNotNone(eps.node_tree)
        bsdf_eps = eps.node_tree.nodes.get("Principled BSDF")
        self.assertIsNotNone(bsdf_eps)

        frame = ghg.create_glasses_frame_material("#0F172A", "Test_Frame")
        self.assertIsNotNone(frame.node_tree)

        rubber = ghg.create_grip_rubber_material("#18181B", "Test_Rubber")
        self.assertIsNotNone(rubber.node_tree)

        strap = ghg.create_nylon_strap_material("#111827", "Test_Strap")
        self.assertIsNotNone(strap.node_tree)

    def test_generate_vented_helmet_mesh(self):
        """Verifies vented road helmet geometry, ribs, EPS liner, and straps."""
        obj = ghg.generate_vented_helmet_mesh(name="Test_Vented", shell_color_hex="#E10600")
        self.assertEqual(obj.type, "MESH")
        self.assertEqual(len(obj.data.materials), 5)
        self.assertGreater(len(obj.data.polygons), 150)

        # Check height span (sits on cranium apex Z ≈ 1.06m)
        max_z = max(v.co.z for v in obj.data.vertices)
        self.assertGreater(max_z, 1.04)

        # Verify retention cradle sits at rear of head (X < 0.30)
        min_x = min(v.co.x for v in obj.data.vertices)
        self.assertLess(min_x, 0.30)

    def test_generate_aero_helmet_mesh(self):
        """Verifies enclosed aero helmet crown, Kamm-tail rear diffuser, and NACA scoops."""
        obj = ghg.generate_aero_helmet_mesh(name="Test_Aero", shell_color_hex="#0284C7")
        self.assertEqual(obj.type, "MESH")
        self.assertEqual(len(obj.data.materials), 5)
        self.assertGreater(len(obj.data.polygons), 120)

        # Kamm-tail rear exhaust should extend rearward (min X < 0.25)
        min_x = min(v.co.x for v in obj.data.vertices)
        self.assertLess(min_x, 0.25)

        # Transverse width should be streamlined (lateral span around ~170mm)
        max_y = max(v.co.y for v in obj.data.vertices)
        self.assertAlmostEqual(max_y, 0.086, delta=0.02)

    def test_generate_tt_helmet_mesh(self):
        """Verifies extreme TT teardrop fairing tail, panoramic visor, and ear skirts."""
        obj = ghg.generate_tt_helmet_mesh(name="Test_TT", shell_color_hex="#1E293B", visor_tint_hex="#FF4500")
        self.assertEqual(obj.type, "MESH")
        self.assertEqual(len(obj.data.materials), 5)
        self.assertGreater(len(obj.data.polygons), 120)

        # Extended aerodynamic tail should reach X ≈ 0.10m (260mm teardrop fairing)
        min_x = min(v.co.x for v in obj.data.vertices)
        self.assertLess(min_x, 0.15)

        # Front visor extends forward to brow/cheeks
        max_x = max(v.co.x for v in obj.data.vertices)
        self.assertGreater(max_x, 0.42)

    def test_generate_pro_glasses_mesh(self):
        """Verifies oversized cylindrical toric shield eyewear, TR90 brow frame, and temple arms."""
        obj = ghg.generate_pro_glasses_mesh(name="Test_Glasses", frame_color_hex="#0F172A", lens_tint_hex="#FF4500")
        self.assertEqual(obj.type, "MESH")
        self.assertEqual(len(obj.data.materials), 3)
        self.assertGreater(len(obj.data.polygons), 100)

        # Lens curvature radius R=68mm centered near nose bridge (max X ≈ 0.41m)
        max_x = max(v.co.x for v in obj.data.vertices)
        self.assertGreater(max_x, 0.40)

        # Temple arms extend rearward around head (min X < 0.30m)
        min_x = min(v.co.x for v in obj.data.vertices)
        self.assertLess(min_x, 0.30)

        # Lens vertical height (Z span ~55mm)
        max_z = max(v.co.z for v in obj.data.vertices)
        min_z = min(v.co.z for v in obj.data.vertices)
        self.assertGreater(max_z - min_z, 0.045)

    def test_head_reference_alignment(self):
        """Verifies that all 4 models align with the cyclist cranium center (0.360, 0.0, 0.985)."""
        obj_vented = ghg.generate_vented_helmet_mesh()
        obj_aero = ghg.generate_aero_helmet_mesh()
        obj_tt = ghg.generate_tt_helmet_mesh()
        obj_glasses = ghg.generate_pro_glasses_mesh()

        for obj in [obj_vented, obj_aero, obj_tt, obj_glasses]:
            # Centroid X should be within head zone [0.25, 0.42]
            avg_x = sum(v.co.x for v in obj.data.vertices) / len(obj.data.vertices)
            self.assertGreater(avg_x, 0.25)
            self.assertLess(avg_x, 0.42)

            # Bilaterally symmetrical (average Y ≈ 0.0)
            avg_y = sum(v.co.y for v in obj.data.vertices) / len(obj.data.vertices)
            self.assertAlmostEqual(avg_y, 0.0, delta=0.01)

            # Centroid Z should be at head height [0.95, 1.05]
            avg_z = sum(v.co.z for v in obj.data.vertices) / len(obj.data.vertices)
            self.assertGreater(avg_z, 0.95)
            self.assertLess(avg_z, 1.05)

    def test_export_all_helmets_and_glasses(self):
        """Verifies export of all 4 headwear assets to binary glTF (.glb) files."""
        temp_dir = "assets/3d/cyclists/test_headwear_export"
        try:
            exported = ghg.export_all_helmets_and_glasses(output_dir=temp_dir)
            self.assertEqual(len(exported), 4)

            expected_keys = ["vented", "aero", "tt", "glasses"]
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
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(TestGenerateHelmetsAndGlasses)
    result = runner.run(suite)
    sys.exit(0 if result.wasSuccessful() else 1)

