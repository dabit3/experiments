import json,pathlib,shutil
root=pathlib.Path(__file__).resolve().parent
rec=pathlib.Path('/Users/devin/screencasts/vh-arcade-af9795d')
old=root.parent/'arcade-manual-a13736f'
for name in ['server.log','web-server.log']:
 shutil.copy2(old/name,root/name)
shutil.copy2(rec/'vh-arcade-af9795d-annotations.json',root/'recording-annotations.json')
backup=root/'markers-capture-clock.json'
if not backup.exists(): shutil.copy2(root/'markers.json',backup)
start=float((root/'recording-start.txt').read_text())
birth=(rec/'vh-arcade-af9795d-raw-000.mkv').stat().st_birthtime
offset=start-birth
markers=json.loads(backup.read_text())
for m in markers:
 m['capture_elapsed_seconds']=m['t']
 m['t']=round(m['t']+offset,2)
(root/'markers.json').write_text(json.dumps(markers,indent=2))
(root/'timeline-notes.json').write_text(json.dumps({
 'raw_file':'raw-footage.mkv',
 'raw_duration_seconds':1008.466,
 'marker_offset_seconds':offset,
 'method':'Capture clock normalized to first raw chunk filesystem birth time; raw seconds approximate, allow chunk-boundary/frame latency.',
 'editor_source':'Recorder clean MP4 with idle time shortened; review-script uses that source timeline, not raw marker seconds.',
 'post_recording_cleanup':'Verified phone Sound ON; restored Web Sound ON and returned both to lobby after recording.'
},indent=2))
