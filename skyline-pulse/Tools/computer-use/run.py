#!/usr/bin/env python3
"""Run prepared native UI battle, then finish bounded raw capture. No app injection."""
import argparse,json,pathlib,subprocess,time
B=pathlib.Path(__file__).resolve().parent
p=argparse.ArgumentParser();p.add_argument("--repo",required=True,type=pathlib.Path)
p.add_argument("--out",required=True,type=pathlib.Path)
p.add_argument("--config",required=True,type=pathlib.Path);a=p.parse_args();O=a.out.resolve()
assert O.is_dir() and not (O/"capture-start.json").exists(),"Use fresh prepared output"
capture=subprocess.Popen(["python3",str(B/"capture-pair.py"),"--out",str(O),"--duration","155"],
                         stdout=open(O/"capture.log","w"),stderr=subprocess.STDOUT)
deadline=time.monotonic()+15
while True:
    frames=O/"screen-raw-frames.jsonl"; audio=O/"native-audio-buffers.jsonl"
    if frames.exists() and '"accepted":true' in frames.read_text() and audio.exists() and audio.stat().st_size>0: break
    if capture.poll() is not None or time.monotonic()>deadline: raise RuntimeError("Capture not ready; no UI actions")
    time.sleep(.1)
result=subprocess.run(["python3",str(B/"drive.py"),"--repo",str(a.repo.resolve()),"--out",str(O),
                       "--config",str(a.config.resolve())],
                      stdout=open(O/"drive.log","w"),stderr=subprocess.STDOUT)
(O/"driver-exit.json").write_text(json.dumps(dict(returncode=result.returncode,wall=time.time())))
print("UI driver exit",result.returncode,"; retaining bounded raw capture",flush=True)
assert capture.wait()==0,"capture failure"
raise SystemExit(result.returncode)
