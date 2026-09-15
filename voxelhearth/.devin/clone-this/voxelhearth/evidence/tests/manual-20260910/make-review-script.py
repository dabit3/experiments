"""Build a review-video.mjs script from the computer-use testing artifacts:
markers.json (main pass), the two fix-round annotation files, and the
PASS/FAIL tables of the three REPORT*.md files."""
import json
import re
import sys

EV = '/Users/devin/repos/experiments/voxelhearth/.devin/clone-this/voxelhearth/evidence/tests/manual-20260910'
SC = '/Users/devin/screencasts'
MAIN_LEN = float(sys.argv[1])   # raw manual recording length (s)
R1_LEN = float(sys.argv[2])     # round-1 clean recording length (s)
R2_LEN = float(sys.argv[3])     # round-2 clean recording length (s)
CLIP = 9.0                      # max seconds shown per marker

markers = json.load(open(f'{EV}/markers.json'))
chapters = []
for i, m in enumerate(markers):
    nxt = markers[i + 1]['t'] if i + 1 < len(markers) else MAIN_LEN
    to = min(nxt, m['t'] + CLIP, MAIN_LEN)
    if to - m['t'] < 1.5:
        continue
    chapters.append({
        'title': m['title'],
        'caption': m['caption'],
        'notes': [f"platform: {m.get('platform', 'both')}", f"raw t={m['t']:.1f}s"],
        'from': round(m['t'], 2),
        'to': round(to, 2),
    })


def round_chapters(path, offset, length, label):
    ann = json.load(open(path))['annotations']
    starts = [a for a in ann if a['type'] == 'test_start']
    results = {a['test']: a for a in ann if a['type'] == 'assertion'}
    out = []
    for i, a in enumerate(starts):
        t0 = a['edited_time_s']
        t1 = min(starts[i + 1]['edited_time_s'] if i + 1 < len(starts) else length, t0 + 2 * CLIP)
        r = results.get(a['test'])
        verdict = (r.get('test_result') or '').upper() if r else ''
        cap = r.get('assertion') if r else a['test']
        out.append({
            'title': f"{label}: {a['test'].replace('It should ', '')}"[:60],
            'caption': f"{verdict + ' — ' if verdict else ''}{cap}"[:110],
            'notes': [label, 'real UI, no director channel'],
            'from': round(offset + t0, 2),
            'to': round(offset + min(t1, length), 2),
        })
    return out


chapters += round_chapters(f'{SC}/vh-pixel-fixes/vh-pixel-fixes-annotations.json', MAIN_LEN, R1_LEN, 'Fix round 1')
chapters += round_chapters(f'{SC}/vh-pixel-fixes-round3/vh-pixel-fixes-round3-annotations.json',
                           MAIN_LEN + R1_LEN, R2_LEN, 'Fix round 2')

# checks: main report rows, then the fix-round rows
checks = []
untested = 0
row = re.compile(r'^\|\s*(?P<name>[^|]+?)\s*\|\s*\**(?P<res>[^|*]+?)\**\s*\|')
for f, prefix in (('REPORT.md', ''), ('REPORT-fixes.md', 'Fix 1 · '), ('REPORT-fixes-2.md', 'Fix 2 · ')):
    for line in open(f'{EV}/{f}'):
        m = row.match(line)
        if not m or m['name'] in ('Check', 'Item') or set(m['name']) <= set('-: '):
            continue
        res = m['res'].strip()
        if res.upper().startswith('UNTESTED'):
            untested += 1
            continue
        if not (res.upper().startswith('PASS') or res.upper().startswith('FAIL')):
            continue
        name = re.sub(r'^\d+[ab]?\.\s*', '', m['name'])
        checks.append({'name': f"{prefix}{name}", 'ok': res.upper().startswith('PASS')})

passed = sum(c['ok'] for c in checks)
script = {
    'title': 'Voxelhearth · Web × iOS computer-use review',
    'subtitle': 'Real UI on Chrome + iPhone 17 Simulator, one room · 2026-09-10',
    'footer': f'{passed}/{len(checks)} checks passed across 3 rounds · {untested} untested · manual-20260910',
    'sources': {'both': {'video': '/Users/devin/vh-review/computer-use-all.mp4',
                         'label': 'Web (left) · iOS Simulator (right) — same room'}},
    'chapters': chapters,
    'checks': checks,
}
json.dump(script, open('/Users/devin/vh-review/computer-use-review.json', 'w'), indent=1)
print(len(chapters), 'chapters', len(checks), 'checks', passed, 'passed', untested, 'untested',
      'runtime ~%.0fs' % sum(c['to'] - c['from'] for c in chapters))
