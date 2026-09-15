"""Result-modal text recognition using Vision's normalized bottom-left bounds."""

from typing import TypedDict


class OCRRecord(TypedDict):
    text: str
    x: float
    y: float
    width: float
    height: float


def center_y(record: OCRRecord) -> float:
    return record["y"] + record["height"] / 2


def modal_lines(records: list[OCRRecord]) -> list[str]:
    modal = [
        record for record in records
        if 0.2 <= record["x"] + record["width"] / 2 <= 0.8
        and 0.42 <= center_y(record) <= 0.70
    ]
    rows: list[list[OCRRecord]] = []
    for record in sorted(modal, key=lambda item: (-center_y(item), item["x"])):
        row = next((
            row for row in rows
            if abs(center_y(record) - center_y(row[0]))
            <= min(record["height"], row[0]["height"]) / 2
        ), None)
        if row is None:
            rows.append([record])
        else:
            row.append(record)

    lines = []
    for row in rows:
        words = sorted(row, key=lambda item: item["x"])
        line = words[0]["text"]
        for left, right in zip(words, words[1:]):
            gap = right["x"] - left["x"] - left["width"]
            if gap > 3 * max(left["height"], right["height"]):
                lines.append(" ".join(line.upper().split()))
                line = right["text"]
            else:
                line += " " + right["text"]
        lines.append(" ".join(line.upper().split()))
    return lines


def result_matches(records: list[OCRRecord], winner: str) -> bool:
    lines = modal_lines(records)
    expected = ["CROWN CLAIMED", winner.upper(), "REMATCH"]
    positions = [lines.index(text) for text in expected if text in lines]
    return len(positions) == 3 and positions[0] < positions[1] < positions[2]
