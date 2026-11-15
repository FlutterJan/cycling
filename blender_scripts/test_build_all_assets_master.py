"""
===============================================================================
PRO PELOTON MANAGER - MASTER BUILD PIPELINE UNIT TESTS
===============================================================================
Unit tests verifying the master build script configuration, step catalogue
(#086 - #182), directory setup, Blender detection, glTF/PNG binary validation,
per-step exception isolation, and `asset_manifest.json` generation.
===============================================================================
"""

import json
import os
import sys
import tempfile
import unittest
from unittest.mock import patch

script_dir = os.path.dirname(os.path.abspath(__file__))
if script_dir not in sys.path:
    sys.path.insert(0, script_dir)

import build_all_assets_master as bam


class TestMasterBuildPipeline(unittest.TestCase):
    """Test suite for master build pipeline logic and validation."""

    def test_pipeline_steps_registration(self):
        """Verifies that all 20 pipeline steps (#086 - #098, #176 - #182) are registered and exist."""
        self.assertEqual(len(bam.PIPELINE_STEPS), 20, "Pipeline must register exactly 20 steps (#086 - #182)")

        task_ids = [s.task_id for s in bam.PIPELINE_STEPS]
        expected_tasks = [f"#{num:03d}" for num in range(86, 99)] + [f"#{num:03d}" for num in range(176, 183)]
        self.assertEqual(task_ids, expected_tasks)

        for step in bam.PIPELINE_STEPS:
            script_full = os.path.join(script_dir, step.script_name)
            self.assertTrue(
                os.path.isfile(script_full),
                f"Step {step.task_id} script '{step.script_name}' does not exist on disk",
            )

    def test_directory_structure_creation(self):
        """Verifies that ensure_directory_structure creates all target directories."""
        with tempfile.TemporaryDirectory() as tmp_dir:
            bam.ensure_directory_structure(base_dir=tmp_dir)
            for req in bam.REQUIRED_DIRECTORIES:
                full_req = os.path.normpath(os.path.join(tmp_dir, *req.split("/")))
                self.assertTrue(os.path.isdir(full_req), f"Directory '{req}' was not created")

    def test_find_blender_binary(self):
        """Validates that find_blender_binary finds a valid executable on this system."""
        blender_bin = bam.find_blender_binary()
        self.assertIsNotNone(blender_bin)
        self.assertTrue(os.path.isfile(blender_bin), f"Blender binary '{blender_bin}' is not a valid file")

    def test_validate_gltf_and_png_binary(self):
        """Verifies binary glTF and PNG inspection."""
        sample_path = os.path.join(os.path.dirname(script_dir), "assets", "3d", "bikes", "frame_aero.glb")
        if os.path.isfile(sample_path):
            is_valid, msg = bam.validate_asset_file(sample_path)
            self.assertTrue(is_valid, f"Validation of '{sample_path}' failed: {msg}")
            self.assertIn("OK", msg)

        is_valid_fake, _ = bam.validate_gltf_binary("non_existent_file.glb")
        self.assertFalse(is_valid_fake)

        with tempfile.NamedTemporaryFile(suffix=".glb", delete=False) as f:
            f.write(b"NOT_A_GLTF_FILE_JUST_SOME_DUMMY_DATA_HERE")
            tmp_corrupt = f.name
        try:
            is_valid_corrupt, _ = bam.validate_asset_file(tmp_corrupt)
            self.assertFalse(is_valid_corrupt)
        finally:
            if os.path.exists(tmp_corrupt):
                os.remove(tmp_corrupt)

        with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as f:
            f.write(b"\x89PNG\r\n\x1a\n" + b"\x00" * 300)
            tmp_png = f.name
        try:
            is_valid_png, msg_png = bam.validate_asset_file(tmp_png)
            self.assertTrue(is_valid_png, f"Valid PNG rejected: {msg_png}")
        finally:
            if os.path.exists(tmp_png):
                os.remove(tmp_png)

    def test_per_step_exception_isolation_and_manifest_generation(self):
        """Verifies that one step raising an exception does not abort subsequent steps and still writes asset_manifest.json."""
        with tempfile.TemporaryDirectory() as tmp_dir:
            dummy_steps = [
                bam.BuildStep("#086", "Raise Step", "style_and_materials.py", [], "Raises"),
                bam.BuildStep("#087", "Fail Step", "generate_aero_frame.py", ["assets/3d/bikes/frame_aero.glb"], "Fails"),
                bam.BuildStep("#182", "Pass Step", "generate_jersey_textures_baker.py", ["assets/textures/jerseys/jersey_gc_yellow.png"], "Passes"),
            ]

            def fake_execute(blender_bin, step, scripts_dir, base_dir="."):
                if step.task_id == "#086":
                    raise RuntimeError("Simulated Blender crash")
                if step.task_id == "#087":
                    return False, 0.1, [], "Simulated exit code 1"
                out_png = os.path.join(base_dir, "assets", "textures", "jerseys", "jersey_gc_yellow.png")
                with open(out_png, "wb") as pf:
                    pf.write(b"\x89PNG\r\n\x1a\n" + b"\x00" * 300)
                return True, 0.2, [out_png], "Success"

            with patch.object(bam, "PIPELINE_STEPS", dummy_steps), \
                 patch.object(bam, "execute_pipeline_step", side_effect=fake_execute), \
                 patch.object(bam, "detect_blender_version", return_value="5.3.0"):
                result = bam.build_all_assets_master(base_dir=tmp_dir, blender_path="C:\\Blender\\blender.exe")

            self.assertFalse(result)
            manifest_path = os.path.join(tmp_dir, "assets", "3d", "asset_manifest.json")
            self.assertTrue(os.path.isfile(manifest_path), "asset_manifest.json was not generated")

            with open(manifest_path, "r", encoding="utf-8") as mf:
                manifest = json.load(mf)

            self.assertEqual(manifest["blender"]["version"], "5.3.0")
            self.assertEqual(manifest["summary"]["total_steps"], 3)
            self.assertEqual(manifest["summary"]["passed_steps"], 1)
            self.assertEqual(manifest["summary"]["failed_steps"], 2)
            self.assertEqual(manifest["summary"]["valid_assets"], 1)
            self.assertEqual(manifest["summary"]["failed_assets"], 1)


if __name__ == "__main__":
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(TestMasterBuildPipeline)
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    sys.exit(0 if result.wasSuccessful() else 1)
