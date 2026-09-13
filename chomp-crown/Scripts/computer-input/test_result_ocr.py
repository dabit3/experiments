import unittest

from result_ocr import modal_lines, result_matches


def text(value, x, y, width, height=0.012):
    return {"text": value, "x": x, "y": y, "width": width, "height": height}


class ResultOCRTests(unittest.TestCase):
    def setUp(self):
        self.records = [
            text("CROWN", 0.365875, 0.604548, 0.101058, 0.011835),
            text("CLAIMED", 0.470032, 0.606105, 0.154574, 0.010174),
            text("ROSE", 0.397188, 0.556234, 0.202469, 0.028521),
            text("REMATCH", 0.429022, 0.481105, 0.135647),
        ]

    def test_split_actual_vision_heading(self):
        self.assertTrue(result_matches(self.records, "Rose"))
        self.assertEqual(modal_lines(self.records), ["CROWN CLAIMED", "ROSE", "REMATCH"])

    def test_merged_heading(self):
        self.records[:2] = [text("CROWN CLAIMED", 0.353312, 0.614798, 0.283912)]
        self.assertTrue(result_matches(self.records, "ROSE"))

    def test_record_order_does_not_change_result(self):
        self.assertTrue(result_matches(self.records[::-1], "Rose"))

    def test_wrong_modal_winner_with_correct_hud_name(self):
        self.records[2]["text"] = "GOLD"
        self.records.append(text("ROSE", 0.586717, 0.854611, 0.066313))
        self.assertFalse(result_matches(self.records, "Rose"))

    def test_hud_only(self):
        self.assertFalse(result_matches(
            [text("ROSE", 0.586717, 0.854611, 0.066313)], "Rose"))

    def test_missing_rematch(self):
        self.assertFalse(result_matches(self.records[:-1], "Rose"))

    def test_heading_words_on_different_rows(self):
        self.records[1]["y"] -= 0.05
        self.assertFalse(result_matches(self.records, "Rose"))

    def test_heading_words_too_far_apart(self):
        self.records[0]["x"] = 0.2
        self.records[1]["x"] = 0.7
        self.assertFalse(result_matches(self.records, "Rose"))

    def test_title_below_winner(self):
        self.records[2]["y"] = 0.65
        self.assertFalse(result_matches(self.records, "Rose"))


if __name__ == "__main__":
    unittest.main()
