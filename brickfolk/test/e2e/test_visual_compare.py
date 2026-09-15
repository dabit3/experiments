import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from visual_compare import encode_png, normalize_font_edges


class FontEdgeFilterTests(unittest.TestCase):
    def test_no_regions_preserves_every_byte(self):
        raw = bytes(range(180))
        self.assertEqual(normalize_font_edges(10, 6, raw, []), raw)

    def test_filter_cannot_read_or_write_outside_text_bounds(self):
        raw = bytearray([255] * (12 * 12 * 3))
        for y in range(3, 9):
            for x in range(3, 9):
                raw[(y * 12 + x) * 3:(y * 12 + x) * 3 + 3] = b"\x00" * 3
        self.assertEqual(normalize_font_edges(12, 12, bytes(raw), [(3, 3, 6, 6)]), raw)

    def test_filter_has_two_pixel_support_and_does_not_mutate_source(self):
        raw = bytearray(15 * 15 * 3)
        raw[(7 * 15 + 7) * 3:(7 * 15 + 7) * 3 + 3] = b"\xff" * 3
        original = bytes(raw)
        filtered = normalize_font_edges(15, 15, original, [(0, 0, 15, 15)])
        changed = {i // 3 for i, value in enumerate(filtered) if value}
        self.assertEqual(changed, {y * 15 + x for y in range(5, 10) for x in range(5, 10)})
        self.assertEqual(bytes(raw), original)

    def test_invalid_regions_fail_closed(self):
        for rect in [(-1, 0, 1, 1), (0, 0, 0, 1), (0, 0, 1, -1), (8, 8, 3, 3)]:
            with self.subTest(rect=rect), self.assertRaises(ValueError):
                normalize_font_edges(10, 10, bytes(300), [rect])


class ComparisonControlTests(unittest.TestCase):
    width = 256
    height = 96
    region = "28,20,116,52"

    def image(self, *, shift=0, colour=(240, 240, 240), missing=False, changed=False):
        raw = bytearray(bytes((13, 18, 38)) * self.width * self.height)
        glyph = ["11110", "10001", "10001", "11110", "10001", "10001", "11110"]
        if changed:
            glyph = ["11111", "10000", "10000", "11110", "10000", "10000", "10000"]
        for start in ([32] if missing else [32, 92]):
            for gy, row in enumerate(glyph):
                for gx, bit in enumerate(row):
                    if bit == "0":
                        continue
                    for y in range(24 + gy * 6, 30 + gy * 6):
                        for x in range(start + shift + gx * 6, start + shift + gx * 6 + 6):
                            offset = (y * self.width + x) * 3
                            raw[offset:offset + 3] = bytes(colour)
        return bytes(raw)

    def compare(self, reference, actual, *, region=None):
        with tempfile.TemporaryDirectory(prefix="brickfolk-visual-test-", dir=Path.home()) as directory:
            root = Path(directory)
            ref, act = root / "reference.png", root / "actual.png"
            ref.write_bytes(encode_png(self.width, self.height, reference))
            act.write_bytes(encode_png(self.width, self.height, actual))
            before = (ref.read_bytes(), act.read_bytes())
            result = subprocess.run([
                sys.executable, "-B", str(Path(__file__).with_name("visual_compare.py")),
                "--id", "control", "--reference", str(ref), "--actual", str(act),
                "--out-dir", str(root / "comparison"), "--scale", "4",
                "--tolerance", "48", "--shift", "1", "--edge-tolerance", "24",
                "--max-edge-cells", "56", "--max-cluster", "8",
                "--font-edge-region", region or self.region,
            ], capture_output=True, text=True)
            self.assertIn(result.returncode, (0, 1), result.stderr)
            self.assertEqual((ref.read_bytes(), act.read_bytes()), before)
            metrics = json.loads(result.stdout)
            self.assertEqual(result.returncode == 0, metrics["passed"])
            return metrics

    def test_identical_capture_passes_with_explicit_bounds(self):
        metrics = self.compare(self.image(), self.image())
        self.assertTrue(metrics["passed"])
        self.assertEqual(metrics["different_pixels"], 0)
        self.assertEqual(metrics["font_edge_normalization"]["regions"], [[28, 20, 116, 52]])

    def test_eight_pixel_text_shift_fails(self):
        self.assertFalse(self.compare(self.image(), self.image(shift=8))["passed"])

    def test_missing_glyph_fails(self):
        self.assertFalse(self.compare(self.image(), self.image(missing=True))["passed"])

    def test_changed_glyph_fails(self):
        self.assertFalse(self.compare(self.image(), self.image(changed=True))["passed"])

    def test_recoloured_text_fails(self):
        self.assertFalse(self.compare(self.image(), self.image(colour=(240, 40, 40)))["passed"])

    def test_change_outside_region_still_fails(self):
        self.assertFalse(self.compare(self.image(), self.image(missing=True), region="0,0,20,20")["passed"])


if __name__ == "__main__":
    unittest.main()
