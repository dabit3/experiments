#!/usr/bin/env python3
"""Prepare local test processes. Requires installed, booted landscape iPads."""
import argparse,json,pathlib,socket,subprocess,time
B=pathlib.Path(__file__).resolve().parent
p=argparse.ArgumentParser(); p.add_argument("--repo",required=True,type=pathlib.Path)
p.add_argument("--out",required=True,type=pathlib.Path)
p.add_argument("--aria",required=True,help="First booted iPad UDID (no default)")
p.add_argument("--nova",required=True,help="Second booted iPad UDID (no default)")
p.add_argument("--config",type=pathlib.Path,required=True)
a=p.parse_args(); R=a.repo.resolve(); O=a.out.resolve()
cfg=json.loads(a.config.read_text())
assert a.aria!=a.nova,"Two independent devices are required"
assert O.parent.is_dir() and not O.exists(),"Use a NEW output directory below an existing parent"
for port in [8769,8770]:
    with socket.socket() as s:
        s.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1)
        s.bind(("127.0.0.1",port))
O.mkdir()
subprocess.run(["python3",str(B/"drive.py"),"--repo",str(R),"--out",str(O),
                "--config",str(a.config.resolve()),"--phase","preflight"],check=True)
processes=[]
def spawn(cmd,log,cwd=None):
    proc=subprocess.Popen(cmd,cwd=cwd,stdout=open(O/log,"w"),stderr=subprocess.STDOUT,start_new_session=True)
    processes.append(dict(pid=proc.pid,argv=cmd,log=log)); return proc
spawn(["node",str(R/"Server/server.mjs")],"server.jsonl",R)
spawn(["node",str(B/"proxy.mjs"),str(R),str(O/"wire.jsonl")],"proxy.log")
for name,device in [("ARIA",a.aria),("NOVA",a.nova)]:
    spawn(["xcrun","simctl","launch","--console-pty","--terminate-running-process",device,
           "games.skylinepulse.arcade","--name",name,"--server","ws://127.0.0.1:8770"],name+"-app.log")
(O/"processes.json").write_text(json.dumps(processes,indent=2))
subprocess.run(["osascript","-e",'tell application "Simulator" to activate'],check=True)
time.sleep(6)
for window in cfg["windows"].values():
    x,y,w,h=window["bounds"]
    title=json.dumps(window["titleContains"])
    script=f'''tell application "System Events" to tell process "Simulator"
set position of (first window whose name contains {title}) to {{{x},{y}}}
set size of (first window whose name contains {title}) to {{{w},{h}}}
end tell'''
    subprocess.run(["osascript","-e",script],check=True)
(O/"geometry.json").write_text(json.dumps(cfg,indent=2))
print("Prepared manual native clients. Verify lobbies/geometry before run.py.",flush=True)
