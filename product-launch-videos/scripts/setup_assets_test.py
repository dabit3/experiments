import io
import unittest
import zipfile

from setup_assets import EXPECTED, validate_archive


class ArchiveValidationTest(unittest.TestCase):
    def archive(self, names):
        buffer = io.BytesIO()
        with zipfile.ZipFile(buffer, "w") as archive:
            for name in names:
                archive.writestr(name, b"test")
        buffer.seek(0)
        return zipfile.ZipFile(buffer)

    def test_exact_inventory_is_required(self):
        with self.archive(EXPECTED) as archive:
            validate_archive(archive)
        with self.archive(EXPECTED[:-1]) as archive:
            with self.assertRaisesRegex(ValueError, "Missing"):
                validate_archive(archive)

    def test_path_traversal_and_unexpected_entries_are_rejected(self):
        for name in ["../escape.png", "/absolute.png", "nested/asset.png"]:
            with self.archive(EXPECTED + [name]) as archive:
                with self.assertRaises(ValueError):
                    validate_archive(archive)

    def test_symlinks_are_rejected(self):
        buffer = io.BytesIO()
        with zipfile.ZipFile(buffer, "w") as archive:
            for name in EXPECTED:
                info = zipfile.ZipInfo(name)
                info.external_attr = 0o120777 << 16
                archive.writestr(info, b"target")
        buffer.seek(0)
        with zipfile.ZipFile(buffer) as archive:
            with self.assertRaisesRegex(ValueError, "symlinks"):
                validate_archive(archive)
