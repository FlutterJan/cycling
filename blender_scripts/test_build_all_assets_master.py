"""
===============================================================================
PRO PELOTON MANAGER - MASTER BUILD PIPELINE UNIT TESTS
===============================================================================
Unit tests verifying the master build script configuration, step catalogue,
directory setup, Blender detection, and glTF binary validation.
===============================================================================
"""

import os
import sys
import tempfile
import unittest

script_dir = os.path.dirname(os.path.abspath(__file__))
if script_dir not in sys.path:
    sys.path.insert(0, script_dir)

import build_all_assets_master as bam


class TestMasterBuildPipeline(unittest.TestCase):
    """Test suite for master build pipeline logic and validation."""

    def test_pipeline_steps_registration(self):
        """Verifies that all 13 pipeline steps (#086 - #098) are registered and exist."""
        self.assertEqual(len(bam.PIPELINE_STEPS), 13, "Pipeline must register exactly 13 steps (#086 - #098)")

        task_ids = [s.task_id for s in bam.PIPELINE_STEPS]
        expected_tasks = [f"#{num:03d}" for num in range(86, 99)]
        self.assertEqual(task_ids, expected_tasks)

        # Check that all script files exist in blender_scripts/
        for step in bam.PIPELINE_STEPS:
            script_full = os.path.join(script_dir, step.script_name)
            self.assertTrue(
                os.path.isfile(script_full),
                f"Step {step.task_id} script '{step.script_name}' does not exist on disk"
            )

    def test_directory_structure_creation(self):
        """Verifies that ensure_directory_structure creates all target directories."""
        with tempfile.TemporaryDirectory() as tmp_dir:
            bam.ensure_directory_structure(base_dir=tmp_dir)
            for req in bam.REQUIRED_DIRECTORIES:
                full_req = os.path.join(tmp_dir, req)
                self.assertTrue(os.path.isdir(full_req), f"Directory '{req}' was not created")

    def test_find_blender_binary(self):
        """Validates that find_blender_binary finds a valid executable on this system."""
        blender_bin = bam.find_blender_binary()
        self.assertIsNotNone(blender_bin)
        self.assertTrue(os.path.isfile(blender_bin), f"Blender binary '{blender_bin}' is not a valid file")

    def test_validate_gltf_binary_on_existing_asset(self):
        """Verifies binary glTF inspection on a landed 3D model."""
        sample_path = os.path.join(os.path.dirname(script_dir), "assets", "3d", "bikes", "frame_aero.glb")
        if os.path.isfile(sample_path):
            is_valid, msg = bam.validate_gltf_binary(sample_path)
            self.assertTrue(is_valid, f"Validation of '{sample_path}' failed: {msg}")
            self.assertIn("OK", msg)

        # Verify on non-existent file
        is_valid_fake, _ = bam.validate_gltf_binary("non_existent_file.glb")
        self.assertFalse(is_valid_fake)

        # Verify on corrupt file (wrong magic)
        with tempfile.NamedTemporaryFile(delete=False) as f:
            f.write(b"NOT_A_GLTF_FILE_JUST_SOME_DUMMY_DATA_HERE")
            tmp_corrupt = f.name
        try:
            is_valid_corrupt, _ = bam.validate_gltf_binary(tmp_corrupt)
            self.assertFalse(is_valid_corrupt)
        finally:
            if os.path.exists(tmp_corrupt):
                os.remove(tmp_corrupt)


if __name__ == "__main__":
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(TestMasterBuildPipeline)
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    sys.exit(0 if result.wasSuccessful() else 1)
