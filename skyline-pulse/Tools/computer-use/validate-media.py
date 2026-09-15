#!/usr/bin/env python3
"""Validate actual stored CAF/source PTS, then create a conservative aligned mux."""
import argparse,array,hashlib,json,math,pathlib,subprocess
p=argparse.ArgumentParser()
p.add_argument("--out",type=pathlib.Path,required=True)
p.add_argument("--crop",help="Optional ffmpeg crop width:height:left:top in video pixels")
a=p.parse_args(); O=a.out.resolve(); checks=[]
def rows(name):
    return [json.loads(s) for s in (O/name).read_text().splitlines() if s.startswith("{")]
def check(name,expected,actual,ok):
    checks.append(dict(name=name,expected=expected,actual=actual,result="passed" if ok else "failed"))
    (O/"media-assertions.json").write_text(json.dumps(checks,indent=2))
    print(checks[-1],flush=True)
    if not ok:raise RuntimeError(name)
def run(args,log=None):
    r=subprocess.run(args,cwd=O,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    if log:(O/log).write_bytes(r.stdout+r.stderr)
    if r.returncode:raise RuntimeError(f"{args[0]} exit {r.returncode}: {r.stderr.decode()}")
    return r.stdout
def probe(path):
    return json.loads(run(["ffprobe","-v","error","-show_streams","-show_format","-of","json",path]))
def frameprobe(path):
    return json.loads(run(["ffprobe","-v","error","-select_streams","v:0","-show_frames",
                          "-show_entries","frame=pts_time","-of","json",path]))["frames"]
finish=json.loads((O/"capture-finish.json").read_text())
check("Both bounded capture helpers exited",0,finish,
      finish["videoExit"]==finish["audioExit"]==0)
audio=rows("native-audio-buffers.jsonl"); video=rows("screen-raw-frames.jsonl")
frames=[r for r in video if r["type"]=="frame" and r["accepted"]]
anchors=[r for r in video if r["type"]=="anchor"]; summary=video[-1]
check("SCK writer completed","status2 and accepted frames",summary,
      summary["type"]=="summary" and summary["writerStatus"]==2 and bool(frames))
check("Shared host-clock anchors","CM time inside mach bracket",anchors,
      bool(anchors) and all(r["machBefore"]<=r["cmHostSeconds"]<=r["machAfter"] for r in anchors))
check("Audio timestamps valid","all valid, stereo48kHz",
      dict(buffers=len(audio),rates=sorted({r["sampleRate"] for r in audio})),
      bool(audio) and all(r["hostValid"] and r["sampleValid"] and r["sampleRate"]==48000 for r in audio))
gaps=sum(y["sampleTime"]!=x["sampleTime"]+x["frames"] for x,y in zip(audio,audio[1:]))
residual=max(abs(y["hostSeconds"]-x["hostSeconds"]-x["frames"]/48000) for x,y in zip(audio,audio[1:]))
check("Sample/host continuity","0 gaps; host residual<=1us",
      dict(gaps=gaps,maxHostResidualSeconds=residual),gaps==0 and residual<=1e-6)
ap=probe("native-audio.caf")["streams"][0]
check("Stored CAF format","2 channels at48000Hz",ap,
      ap["channels"]==2 and int(ap["sample_rate"])==48000)
raw=run(["ffmpeg","-v","error","-i","native-audio.caf","-f","f32le","-acodec","pcm_f32le","-"])
stored=len(raw)//8; logged=sum(r["frames"] for r in audio)
check("Stored CAF frames","stored<=logged; unstored tail<1 buffer",
      dict(stored=stored,logged=logged,unstoredTail=logged-stored),
      len(raw)%8==0 and 0<=logged-stored<max(r["frames"] for r in audio))
pcm=array.array("f");pcm.frombytes(raw)
fp=frameprobe("screen-raw.mov")
(O/"raw-frame-probe.json").write_text(json.dumps(fp))
first=frames[0]["ptsSeconds"]; last=frames[-1]["ptsSeconds"]
errors=[abs(float(y["pts_time"])-(x["ptsSeconds"]-first)) for x,y in zip(frames,fp)]
check("Raw video preserves source PTS","same count; max printed error<=1us",
      dict(source=len(frames),decoded=len(fp),maxError=max(errors)),
      len(frames)==len(fp) and max(errors)<=1e-6)
run(["ffmpeg","-v","error","-i","screen-raw.mov","-f","null","-"],"raw-decode.log")
check("Raw full decode","no errors",(O/"raw-decode.log").read_text(),
      not (O/"raw-decode.log").read_text())
trim=round((first-audio[0]["hostSeconds"])*48000)
alignmentError=audio[0]["hostSeconds"]+trim/48000-first
# Wall clock only labels app lifecycle, NEVER establishes A/V alignment.
wallMinusHost=anchors[0]["wallUnix"]-anchors[0]["cmHostSeconds"]
complete=next(r for r in rows("driver.jsonl") if r["label"]=="complete")
completeVideo=complete["at"]-wallMinusHost-first
duration=min(math.ceil(completeVideo+1),math.floor(last-first),math.floor((stored-trim)/48000))
count=duration*48000
alignment=dict(audioFirstHostSeconds=audio[0]["hostSeconds"],videoFirstSourcePTS=first,
               audioTrimStartSample=trim,audioTrimEndSample=trim+count,storedCAFFrames=stored,
               alignmentErrorSeconds=alignmentError,finalDurationSeconds=duration,
               completeVideoSeconds=completeVideo,videoLastSourcePTS=last,
               method="Original source PTS and CAF host time, not launch times")
(O/"alignment.json").write_text(json.dumps(alignment,indent=2))
check("Aligned interval covers reconnect with stored samples","within both sources; <=1sample residual",
      alignment,trim>=0 and trim+count<=stored and duration>completeVideo and
      first+duration<=last and abs(alignmentError)<=1/48000)
for start in [r for r in rows("server.jsonl") if r["type"]=="start"]:
    begin=round((start["startAt"]/1000-wallMinusHost-audio[0]["hostSeconds"])*48000)
    bins=[]
    for sec in range(1,47):
        chunk=pcm[2*(begin+sec*48000):2*(begin+(sec+1)*48000)]
        bins.append(math.sqrt(sum(s*s for s in chunk)/len(chunk)))
    song=pcm[2*begin:2*(begin+round(48.75*48000))]
    rms=math.sqrt(sum(s*s for s in song)/len(song));peak=max(map(abs,song))
    levels=dict(round=start["round"],rmsDB=20*math.log10(rms) if rms else -999,
                peakDB=20*math.log10(peak) if peak else -999,
                minimumInteriorSecondRMSDB=20*math.log10(min(bins)) if min(bins) else -999)
    check(f"Round{start['round']} actual native song audio","all interior bins>-60dB, no clipping",
          levels,min(bins)>.001 and peak<1)
included=[f for f in fp if float(f["pts_time"])<duration]
lastTick=round(float(included[-1]["pts_time"])*60000)
lastDuration=duration*60000-lastTick
vf=f"trim=end={duration}"+(f",crop={a.crop},scale=1920:-2" if a.crop else "")
af=f"atrim=start_sample={trim}:end_sample={trim+count},asetpts=PTS-STARTPTS"
cmd=["ffmpeg","-y","-v","warning","-i","screen-raw.mov","-i","native-audio.caf",
     "-filter_complex",f"[0:v]{vf}[v];[1:a]{af}[a]","-map","[v]","-map","[a]",
     "-c:v","libx264","-preset","fast","-crf","19","-bf","0","-fps_mode:v","passthrough",
     "-enc_time_base:v","1/60000","-video_track_timescale","60000",
     "-bsf:v",f"setts=duration=if(eq(N\\,{len(included)-1})\\,{lastDuration}\\,DURATION)",
     "-c:a","aac","-b:a","192k","-t",str(duration),"-movflags","+faststart","verified-primary.mp4"]
(O/"mux-command.json").write_text(json.dumps(cmd,indent=2));run(cmd,"verified-mux.log")
run(["ffmpeg","-y","-v","error","-i","native-audio.caf","-af",af,
     "-c:a","pcm_f32le","verified-aligned-audio.caf"])
aligned=run(["ffmpeg","-v","error","-i","verified-aligned-audio.caf","-f","f32le","-"])
check("Lossless aligned audio matches stored source","identical selected samples",
      dict(frames=len(aligned)//8,sha256=hashlib.sha256(aligned).hexdigest()),
      aligned==raw[trim*8:(trim+count)*8])
pr=probe("verified-primary.mp4");(O/"verified-probe.json").write_text(json.dumps(pr,indent=2))
check("Final stream durations","both equal selected duration",
      [s["duration"] for s in pr["streams"]],
      all(abs(float(s["duration"])-duration)<=1/48000 for s in pr["streams"]))
final=frameprobe("verified-primary.mp4")
err=[abs(float(x["pts_time"])-float(y["pts_time"])) for x,y in zip(included,final)]
check("Final frame PTS unchanged","same count, <=1us printed precision",
      dict(frames=len(final),maxError=max(err)),len(final)==len(included) and max(err)<=1e-6)
run(["ffmpeg","-v","error","-i","verified-primary.mp4","-f","null","-"],"verified-decode.log")
check("Final full decode","no errors",(O/"verified-decode.log").read_text(),
      not (O/"verified-decode.log").read_text())
