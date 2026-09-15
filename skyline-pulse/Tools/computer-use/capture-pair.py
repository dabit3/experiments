#!/usr/bin/env python3
"""Unmodified supplied CAF audio + original-PTS SCK video, bounded duration."""
import argparse,json,pathlib,subprocess,time,sys
B=pathlib.Path(__file__).resolve().parent
p=argparse.ArgumentParser(); p.add_argument("--out",type=pathlib.Path,required=True)
p.add_argument("--duration",type=int,default=180); a=p.parse_args(); O=a.out
for helper in ("capture-video","capture-audio"):
    running=subprocess.run(["pgrep","-x",helper],capture_output=True,text=True)
    if running.returncode==0:
        raise RuntimeError(f"Concurrent {helper} PID(s): {running.stdout.strip()}; wait for completion")
audio=subprocess.Popen([str(B/"capture-audio"),str(O/"native-audio"),str(a.duration)],
                       stdout=open(O/"audio-capture.log","w"),stderr=subprocess.STDOUT)
end=time.monotonic()+10
while "CAPTURE READY" not in (O/"audio-capture.log").read_text():
    if audio.poll() is not None or time.monotonic()>end:
        audio.terminate(); raise RuntimeError("Supplied audio helper unavailable")
    time.sleep(.1)
video=subprocess.Popen([str(B/"capture-video"),str(O/"screen-raw"),str(a.duration-2)],
                       stdout=open(O/"video-capture.log","w"),stderr=subprocess.STDOUT)
meta=dict(audioPID=audio.pid,videoPID=video.pid,wallStart=time.time(),duration=a.duration)
(O/"capture-start.json").write_text(json.dumps(meta,indent=2)); print(meta,flush=True)
meta.update(videoExit=video.wait(),audioExit=audio.wait(),wallFinish=time.time())
(O/"capture-finish.json").write_text(json.dumps(meta,indent=2)); print(meta,flush=True)
sys.exit(0 if meta["videoExit"]==0 and meta["audioExit"]==0 else 1)
