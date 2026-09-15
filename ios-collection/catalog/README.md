# Twenty native iOS apps

Open `index.html` directly, or serve this directory with:

```sh
python3 -m http.server 8080
```

The catalog links each app's native demo, source PR, builder session, screenshots
and QA/design report. Expand a card to see its reviewed source revision and
specific validation limits. Images are included locally; videos and original
evidence use authenticated Devin attachment links.

Each application has a separate Xcode project in its own source PR. These PRs
remain independent and unmerged; this catalog does not combine their histories.
The collection's downloadable source archive freezes every app at its reviewed
commit. Open an individual project's README for its Xcode, Simulator and testing
instructions.

This is native macOS and iOS Simulator evidence. Physical-device validation,
distribution signing and App Store submission remain separate release steps.

## Catalog verification

```sh
python3 validate_catalog.py
```

The dependency-free check verifies the twenty-app inventory, unique source PRs
and sessions, matching accepted revisions, local hero assets, HTML structure,
internal navigation and safe external links. During collection assembly only,
`--allow-incomplete` permits cards that have not passed review.

`collection.json` is the portable delivery manifest. Original build briefs are
preserved alongside results and the coordinator's evidence review.
