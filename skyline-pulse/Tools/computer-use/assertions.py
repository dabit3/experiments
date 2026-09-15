#!/usr/bin/env python3
"""Read-only runtime evidence assertions. No network calls and no game simulation."""
import argparse,collections,json,pathlib
p=argparse.ArgumentParser();p.add_argument("--out",required=True,type=pathlib.Path);a=p.parse_args();O=a.out
def rows(name): return [json.loads(s) for s in (O/name).read_text().splitlines() if s.startswith("{")]
checks=[]
def check(name,expected,actual,ok):
    checks.append(dict(name=name,expected=expected,actual=actual,result="passed" if ok else "failed"))
wire=rows("wire.jsonl"); server=rows("server.jsonl"); driver=rows("driver.jsonl")
joined=[r for r in wire if r["message"]["type"]=="joined"]
original=joined[:2]; peers={r["peer"] for r in original}; ids={r["message"]["id"] for r in original}
check("Two native identities",2,sorted(ids),len(ids)==2)
processes=json.loads((O/"processes.json").read_text())
apps=[r for r in processes if "simctl" in r["argv"]]
check("Both autoplay launch flags absent",2,[r["argv"] for r in apps],
      len(apps)==2 and all("--autoplay" not in r["argv"] for r in apps))
inputs=[r for r in wire if r["message"]["type"]=="input"]
check("Native UITouch pointers only","all touch-, no auto-",
      collections.Counter("touch" if r["message"]["pointer"].startswith("touch-") else "other" for r in inputs),
      bool(inputs) and all(r["message"]["pointer"].startswith("touch-") for r in inputs))
errors=[r["message"] for r in wire if r["message"]["type"]=="error"]
check("No protocol errors",[],errors,not errors)
starts=[r for r in server if r["type"]=="start"]
results=[r for r in server if r.get("phase")=="results"]
check("Two complete rounds",[1,2],[r["round"] for r in results],[r["round"] for r in results]==[1,2])
states=[r for r in wire if r["message"]["type"]=="state"]
for rd in (1,2):
    result=next(r for r in results if r["round"]==rd)
    start=next(r for r in starts if r["round"]==rd)
    observed={r["peer"] for r in states if r["message"]["round"]==rd and
              r["message"]["phase"]=="results" and r["message"]["players"]==result["players"]}
    check(f"Round{rd} common authoritative result",sorted(peers),sorted(observed),peers<=observed)
    zero={r["peer"] for r in states if r["message"]["round"]==rd and
          r["message"]["now"]<start["startAt"] and all(p["score"]==0 for p in r["message"]["players"])}
    check(f"Round{rd} shared zero-score countdown",sorted(peers),sorted(zero),peers<=zero)
    selection=json.loads((O/f"round{rd}-selection.json").read_text())
    for player in result["players"]:
        name=player["name"]; pid=player["id"]
        peer=next(r["peer"] for r in original if r["message"]["id"]==pid)
        ev=[r["message"] for r in inputs if r["peer"]==peer and start["startAt"]<=r["at"]<=result["at"]]
        downs=[r for r in ev if r["action"]=="down"]; ups=[r for r in ev if r["action"]=="up"]
        expected=sum(q["player"]==name for q in selection)
        check(f"Round{rd} {name} native down/up count",expected,
              dict(down=len(downs),up=len(ups)),len(downs)==len(ups)==expected)
        check(f"Round{rd} {name} meaningful score",">50000",player["score"],player["score"]>50000)
        jud={}
        for r in states:
            if r["message"]["round"]!=rd: continue
            for p in r["message"]["players"]:
                if p["id"]==pid and p.get("last") and p["last"]["judgment"]!="miss":
                    jud[p["last"]["id"]]=p["last"]["judgment"]
        required={"ARIA":{0:1,3:1,4:5,9:7},"NOVA":{1:1,11:1,12:5,20:7}}[name]
        for note,count in required.items():
            observed={k:v for k,v in jud.items() if k.split(":")[0]==str(note)}
            check(f"Round{rd} {name} note{note} nonmiss ticks",count,observed,len(observed)==count)
        moves=[r for r in ev if r["action"]=="move"]
        check(f"Round{rd} {name} native drag/air motion","horizontal range>2 lanes; y<.75",
              dict(xRange=max(r["x"] for r in moves)-min(r["x"] for r in moves),minY=min(r["y"] for r in moves)),
              max(r["x"] for r in moves)-min(r["x"] for r in moves)>2 and min(r["y"] for r in moves)<.75)
for name in ["ARIA","NOVA"]:
    log=(O/(name+"-app.log")).read_text()
    expected=sum(sum(q["player"]==name for q in json.loads((O/f"round{rd}-selection.json").read_text())) for rd in [1,2])
    actual=log.count("EVIDENCE manual down lane=")
    check(name+" real touchesBegan stdout callbacks",expected,actual,actual==expected)
waiting=[r for r in driver if r["label"]=="single-rematch-waits"]
check("One rematch waits on results",True,bool(waiting),
      bool(waiting) and waiting[0]["state"]["round"]==1 and sum(p["ready"] for p in waiting[0]["state"]["players"])==1)
rejoins=joined[2:]
check("Both reconnect with same IDs",sorted(ids),[r["message"]["id"] for r in rejoins],
      len(rejoins)==2 and {r["message"]["id"] for r in rejoins}==ids)
last=states[-1]["message"]
check("No phantom peer after reconnect",2,len(last["players"]),
      len(last["players"])==2 and all(p["connected"] for p in last["players"]) and last["round"]==2)
check("External driver completed",0,json.loads((O/"driver-exit.json").read_text()),
      json.loads((O/"driver-exit.json").read_text())["returncode"]==0)
(O/"assertions.json").write_text(json.dumps(checks,indent=2))
for c in checks: print(c["result"],c["name"],c["actual"])
raise SystemExit(any(c["result"]=="failed" for c in checks))
