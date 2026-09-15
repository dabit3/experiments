import argparse
import json
import re
from collections import Counter
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlsplit


ROOT = Path(__file__).resolve().parent


class CatalogParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.ids = []
        self.cards = []
        self.links = []
        self.images = []

    def handle_starttag(self, tag, attrs):
        attributes = dict(attrs)
        if attributes.get("id"):
            self.ids.append(attributes["id"])
        if tag == "article":
            self.cards.append(attributes["id"])
        if tag == "a":
            self.links.append(attributes["href"])
        if tag == "img":
            assert attributes.get("alt"), "Missing image description"
            self.images.append(attributes["src"])


def validate(complete=False):
    entries = json.loads((ROOT / "catalog.json").read_text())
    page = (ROOT / "index.html").read_text()
    parser = CatalogParser()
    parser.feed(page)
    assert len(entries) == 30
    assert Counter(entry["app"]["platform"] for entry in entries) == {
        "ios": 10,
        "ipad": 10,
        "macos": 10,
    }
    assert len({entry["app"]["session_id"] for entry in entries}) == 30
    assert len(parser.cards) == 30
    assert len(parser.ids) == len(set(parser.ids)), "Duplicate HTML IDs"
    assert set(parser.cards) == {entry["app"]["slug"] for entry in entries}
    assert all("_evidence" not in entry["result"] for entry in entries)
    manifest_urls = re.findall(r'https?://[^"\s]+', json.dumps(entries))
    for url in manifest_urls:
        parts = urlsplit(url)
        assert parts.scheme == "https"
        assert not parts.username and not parts.password
        assert "git-manager.devin.ai" not in url
        assert "[REDACTED" not in url
        assert not re.search(r"[?&][^=&]*(?:token|signature)[^=&]*=", url, re.I)
    for url in parser.links + parser.images:
        parts = urlsplit(url)
        assert not parts.username and not parts.password
        assert "git-manager.devin.ai" not in url
        assert "[REDACTED" not in url
        assert not re.search(r"[?&](?:token|access_token)=", url, re.I)
        if parts.scheme:
            assert parts.scheme == "https"
            assert parts.hostname
        elif url.startswith("#"):
            assert parts.fragment in parser.ids
        else:
            target = (ROOT / parts.path).resolve()
            assert target.is_relative_to(ROOT)
            assert target.is_file(), f"Missing catalog asset: {url}"
    pr_urls = [
        entry["result"]["pr_url"] for entry in entries if entry["result"].get("pr_url")
    ]
    assert len(pr_urls) == len(set(pr_urls)), "Duplicate app PR"
    assert all(
        re.fullmatch(r"https://github\.com/dabit3/experiments/pull/\d+", url)
        for url in pr_urls
    )
    if complete:
        assert all(entry["review_state"] == "Ready" for entry in entries)
        assert len(parser.images) == 30
        assert len(pr_urls) == 30
        for entry in entries:
            app, result = entry["app"], entry["result"]
            assert result["status"] == "complete"
            assert result["build_passed"] is True
            assert result["ui_tests_passed"] is True
            assert result["_review"]["accepted"] is True
            assert re.fullmatch(r"[0-9a-f]{40}", result["commit"])
            assert result["platform"] == app["platform"]
            assert result["session_url"] == app["session_url"]
            assert result["native_environment"]
            assert result["recording_urls"] and result["annotated_recording_urls"]
            assert result["test_report_url"] in parser.links
            directory = f"native-demos/{app['platform']}/{app['slug']}"
            assert result["app_directory"] == directory
            guide = (
                "https://github.com/dabit3/experiments/blob/"
                f"{result['commit']}/{directory}/README.md"
            )
            assert guide in parser.links, f"Missing build guide for {app['name']}"
        assert all(entry["result"].get("artifact_urls") for entry in entries), (
            "Missing native build/export artifact"
        )
    print(
        f"Validated 30 apps, {len(parser.images)} screenshots, "
        f"{len(pr_urls)} distinct PRs and {len(parser.links)} links."
    )


if __name__ == "__main__":
    arguments = argparse.ArgumentParser()
    arguments.add_argument("--complete", action="store_true")
    arguments.add_argument("--directory", type=Path, default=ROOT)
    options = arguments.parse_args()
    ROOT = options.directory.resolve()
    validate(options.complete)
