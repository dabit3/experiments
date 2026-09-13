#!/usr/bin/env python3
"""External native GUI driver. Reads passive logs; NEVER sends network inputs."""
import argparse, json, pathlib, subprocess, threading, time

B=pathlib.Path(__file__).resolve().parent
p=argparse.ArgumentParser(description=__doc__)
p.add_argument("--repo",type=pathlib.Path,required=True)
p.add_argument("--out",type=pathlib.Path,required=True)
p.add_argument("--config",type=pathlib.Path,required=True)
p.add_argument("--phase",choices=["all","lobby","rounds","preflight"],default="all")
a=p.parse_args(); O=a.out.resolve()
cfg=json.loads(a.config.read_text())
def rows(name):
    if not (O/name).exists(): return []
    result=[]
    for s in (O/name).read_text().splitlines():
        try: result.append(json.loads(s))
        except ValueError: pass # trailing in-flight write
    return result
def wait_for(fn,timeout=20):
    end=time.monotonic()+timeout
    while time.monotonic()<end:
        value=fn()
        if value: return value
        time.sleep(.05)
    raise RuntimeError("Expected state not reached; stop, never fall back to autoplay")
def mark(label,**kw):
    with (O/"driver.jsonl").open("a") as f:
        f.write(json.dumps(dict(at=time.time(),label=label,**kw))+"\n")
    print(label,kw,flush=True)
def shot(label): subprocess.run(["screencapture","-x",str(O/(label+".png"))],check=True)
def pos(player,fx,fy):
    x,y,w,h=cfg["displays"][player]; return x+w*fx,y+h*fy
def dispatch(events,label):
    file=O/(label+"-events.json"); file.write_text(json.dumps(events,indent=2))
    with (O/"native-cgevents.jsonl").open("a") as f:
        subprocess.run([str(B/"gestures"),str(file)],stdout=f,check=True)
def click(player,control):
    x,y=pos(player,*cfg["controls"][control]); t=time.time()+.05
    dispatch([dict(at=t,action="down",x=x,y=y,label=player+"-"+control),
              dict(at=t+.08,action="up",x=x,y=y,label=player+"-"+control)],
             player+"-"+control+"-"+str(time.time_ns()))
    time.sleep(.25)
def states():
    return [r["message"] for r in rows("wire.jsonl") if r["message"]["type"]=="state"]
def latest(): return states()[-1] if states() else {}
def results(rd): return latest().get("phase")=="results" and latest().get("round")==rd
def lobby():
    shot("01-offline"); click("ARIA","create")
    joined=wait_for(lambda: next((r["message"] for r in rows("wire.jsonl")
                                  if r["message"]["type"]=="joined"),None))
    code=joined["room"]
    click("NOVA","room")
    # Real macOS keyboard events, NOT app state injection or websocket messages.
    subprocess.run(["osascript","-e",'tell application "System Events" to keystroke "'+code+'"'],check=True)
    time.sleep(1.0) # native typing is asynchronous relative to click events
    shot("02-code-entered"); click("NOVA","join")
    wait_for(lambda: len(latest().get("players",[]))==2)
    mark("joined",room=code,players=latest()["players"])
    shot("03-lobby"); time.sleep(1)

chart=next(c for c in json.loads((a.repo/"Assets/charts.json").read_text()) if c["id"]=="neon")
def round_gestures(rd,start,dry=False):
    special={0:"ARIA",1:"NOVA",3:"ARIA",4:"ARIA",9:"ARIA",11:"NOVA",12:"NOVA",20:"NOVA"}
    chosen=[]; busy=-1; owner=0
    for n in chart["notes"]:
        begin=n["time"]-(.10 if n["kind"]=="air" else 0)
        end=n["time"]+(n["duration"]+.04 if n["duration"] else .07)
        if n["id"]<=20 and n["id"] not in special: continue
        if begin<busy+.05: continue
        who=special.get(n["id"],["ARIA","NOVA"][owner%2])
        owner+=1; busy=end; chosen.append(dict(player=who,note=n))
    assert all({q["note"]["kind"] for q in chosen if q["player"]==who}=={"tap","hold","slide","air"} for who in ["ARIA","NOVA"])
    events=[]
    def add(who,n,t,action,lane,y):
        x,yy=pos(who,.275+.7*lane/16,y)
        events.append(dict(at=start+t,action=action,x=x,y=yy,
                           label=f'{who}-round{rd}-{n["kind"]}-note{n["id"]}'))
    for q in chosen:
        who,n=q["player"],q["note"]; t=n["time"]; lane=n["lane"]+n["width"]/2
        if n["kind"]=="air":
            add(who,n,t-.1,"down",lane,.9)
            for i in range(1,7): add(who,n,t-.1+i*.015,"move",lane,.9-.2*i/6)
            add(who,n,t+.01,"up",lane,.7)
        elif n["duration"]:
            add(who,n,t,"down",lane,.9); steps=round(n["duration"]*60)
            for i in range(1,steps+1):
                f=i/steps
                add(who,n,t+n["duration"]*f,"move",lane+(n["endLane"]-n["lane"])*f,.9)
            add(who,n,t+n["duration"]+.04,"up",n["endLane"]+n["width"]/2,.9)
        else:
            add(who,n,t,"down",lane,.9); add(who,n,t+.07,"up",lane,.9)
    events.sort(key=lambda e:e["at"])
    held=False
    for e in events:
        if e["action"]=="down": assert not held; held=True
        if e["action"]=="up": assert held; held=False
    assert not held
    if dry:
        print("Native schedule preflight:",len(chosen),"non-overlapping gestures",flush=True)
        return
    (O/f"round{rd}-selection.json").write_text(json.dumps(chosen,indent=2))
    def timed_shot(offset,label):
        time.sleep(max(0,start+offset-time.time())); shot(f"round{rd}-"+label)
    for offset,label in [(-1.5,"countdown"),(4.2,"ARIA-hold-held"),(6.3,"ARIA-slide-held"),
                         (7.95,"NOVA-hold-held"),(11,"NOVA-slide-held"),(23,"live-scores")]:
        threading.Thread(target=timed_shot,args=(offset,label),daemon=True).start()
    mark("gestures-start",round=rd,startAt=start,selected=len(chosen))
    dispatch(events,f"round{rd}-gameplay")
    mark("gestures-end",round=rd)
def rounds():
    for rd in (1,2):
        if rd==1:
            click("ARIA","ready"); click("NOVA","ready")
        else:
            click("ARIA","rematch"); time.sleep(2)
            state=latest()
            assert results(1) and sum(p["ready"] for p in state["players"])==1,state
            mark("single-rematch-waits",state=state); shot("05-one-rematch-waits")
            click("NOVA","rematch")
        start=wait_for(lambda: next((r for r in rows("server.jsonl")
                         if r.get("type")=="start" and r["round"]==rd),None))
        state=wait_for(lambda: latest() if latest().get("round")==rd else None)
        assert len(state["players"])==2 and all(p["score"]==0 for p in state["players"])
        mark("countdown",round=rd,state=state)
        round_gestures(rd,start["startAt"]/1000)
        wait_for(lambda: results(rd),15); time.sleep(1)
        shot(f"round{rd}-results"); mark("results",state=latest())
        assert all(p["score"]>50000 for p in latest()["players"]),latest()
        time.sleep(2)
    before=latest()
    for who in ["ARIA","NOVA"]:
        count=sum(r["message"]["type"]=="joined" for r in rows("wire.jsonl"))
        click(who,"reconnect")
        wait_for(lambda: sum(r["message"]["type"]=="joined" for r in rows("wire.jsonl"))>count)
    time.sleep(1); after=latest()
    assert {(p["id"],p["score"]) for p in before["players"]}=={(p["id"],p["score"]) for p in after["players"]}
    assert len(after["players"])==2 and all(p["connected"] for p in after["players"])
    shot("06-reconnected"); mark("complete",state=after); time.sleep(2)
round_gestures(0,0,dry=True) # must reject invalid schedules BEFORE any UI actions
if a.phase in ("all","lobby"): lobby()
if a.phase in ("all","rounds"): rounds()
