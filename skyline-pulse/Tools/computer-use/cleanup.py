#!/usr/bin/env python3
"""Stop matching processes recorded by prepare.py; dry-run by default."""
import argparse,json,pathlib,signal,subprocess,os
p=argparse.ArgumentParser()
p.add_argument("--out",type=pathlib.Path,required=True)
p.add_argument("--execute",action="store_true")
a=p.parse_args()
for item in reversed(json.loads((a.out/"processes.json").read_text())):
    pid=item["pid"]
    actual=subprocess.run(["ps","-p",str(pid),"-o","command="],
                          capture_output=True,text=True).stdout.strip()
    expected=" ".join(item["argv"][1:])
    if not actual:
        print("Already exited:",pid);continue
    if expected not in actual:
        print("REFUSING stale/reused PID:",pid,actual);continue
    print("Terminate" if a.execute else "Would terminate",pid,actual)
    if a.execute:os.kill(pid,signal.SIGTERM)
