import argparse
import json
import re
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlsplit


ROOT = Path(__file__).resolve().parent
VOID_TAGS = {
    "area",
    "base",
    "br",
    "col",
    "embed",
    "hr",
    "img",
    "input",
    "link",
    "meta",
    "param",
    "source",
    "track",
    "wbr",
}


class CatalogParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.stack: list[str] = []
        self.articles: list[str] = []
        self.images: list[str] = []
        self.links: list[str] = []

    def handle_starttag(self, tag, attrs):
        attributes = dict(attrs)
        if tag not in VOID_TAGS:
            self.stack.append(tag)
        if tag == "article":
            self.articles.append(attributes["id"])
        if tag == "img":
            if not attributes.get("alt"):
                raise ValueError("Image is missing alternative text.")
            self.images.append(attributes["src"])
        if tag == "a":
            self.links.append(attributes["href"])

    def handle_endtag(self, tag):
        if tag in VOID_TAGS or not self.stack or self.stack.pop() != tag:
            raise ValueError(f"Unbalanced HTML end tag: {tag}")


def external_url(value):
    parsed = urlsplit(value)
    if (
        parsed.scheme != "https"
        or not parsed.hostname
        or parsed.username
        or parsed.password
        or parsed.query
        or "git-manager" in parsed.netloc
        or "presigned_proxy" in parsed.path
    ):
        raise ValueError("Unsafe external URL.")


def local_image(value):
    path = (ROOT / value).resolve()
    if ROOT not in path.parents or not path.is_file():
        raise ValueError("Missing or invalid local image.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--allow-incomplete", action="store_true")
    args = parser.parse_args()
    apps = json.loads((ROOT / "collection.json").read_text())
    if len(apps) != 20:
        raise ValueError("Expected twenty applications.")
    for key in ("slug", "session_id", "session_url"):
        if len({app[key] for app in apps}) != 20:
            raise ValueError(f"Duplicate {key}.")
    prs = set()
    accepted = 0
    for app in apps:
        result, review = app["result"], app["review"]
        external_url(app["session_url"])
        if result.get("pr_url"):
            url = result["pr_url"]
            if not re.fullmatch(r"https://github.com/dabit3/experiments/pull/\d+", url):
                raise ValueError("Invalid source PR.")
            if url in prs:
                raise ValueError("Duplicate source PR.")
            prs.add(url)
        ready = (
            result.get("status") == "complete"
            and review.get("accepted")
            and review.get("reviewed_commit") == result.get("commit")
        )
        if ready:
            if not re.fullmatch(r"[a-f0-9]{40}", result["commit"]):
                raise ValueError("Invalid source revision.")
            if result["session_url"] != app["session_url"]:
                raise ValueError("Result belongs to another session.")
            local_image(review["hero_asset"])
            for key in ("video_url", "report_url", "hero_url"):
                external_url(result[key])
            if len(result["screenshot_urls"]) < 3:
                raise ValueError("Expected at least three screenshots.")
            for url in result["screenshot_urls"]:
                external_url(url)
            accepted += 1
        elif not args.allow_incomplete:
            raise ValueError(f"{app['slug']} has not passed revision-matched review.")
    document = CatalogParser()
    markup = (ROOT / "index.html").read_text()
    document.feed(markup)
    document.close()
    if document.stack or document.articles != [app["slug"] for app in apps]:
        raise ValueError("HTML structure or app order does not match the manifest.")
    if markup.count('class="status">Reviewed V1') != accepted:
        raise ValueError("Review badges do not match the manifest.")
    if not args.allow_incomplete and (len(prs) != 20 or len(document.images) != 20):
        raise ValueError("Final catalog requires twenty source PRs and hero images.")
    for url in document.links:
        if url.startswith("#"):
            if url[1:] not in document.articles:
                raise ValueError("Broken app navigation link.")
        else:
            external_url(url)
    for image in document.images:
        if urlsplit(image).scheme:
            if not args.allow_incomplete:
                raise ValueError("Final hero images must be local.")
            external_url(image)
        else:
            local_image(image)
    print(f"Catalog passed: 20 apps, {accepted} reviewed, {len(document.links)} links.")


if __name__ == "__main__":
    main()
