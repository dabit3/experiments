"""Festival Don driver for Devin's injected scripted_tools runtime.

All inputs use tools.computer against two visible native Simulator windows.
Read the external computer-use section in README.md before invoking this file.
"""

import asyncio
import json
import statistics
import time
from pathlib import Path

from devin_tools import tools

ROOT = Path("/Users/devin/repos/experiments/festival-don")
OUT = ROOT / "build/computer-use-fb15df3"
SERVER_LOG = OUT / "server.log"
CHART = ROOT / "Resources/lantern-easy.json"
ACTIONS = OUT / "sdk-actions.jsonl"
SUMMARY = OUT / "sdk-summary.json"

COORDS = {
    "hana_create": [425, 240],
    "hana_easy": [108, 280],
    "hana_ready": [439, 278],
    "hana_rematch": [289, 312],
    "sora_code": [389, 633],
    "sora_join": [490, 633],
    "sora_ready": [439, 641],
    "sora_rematch": [289, 675],
    "hana_don": [240, 280],
    "hana_ka": [240, 244],
    "sora_don": [240, 642],
    "sora_ka": [240, 606],
}

run_id = f"sdk-{int(time.time() * 1000)}"
server_start_bytes = SERVER_LOG.stat().st_size
records = []


def emit(value):
    value = {"runId": run_id, **value}
    records.append(value)
    with ACTIONS.open("a") as f:
        f.write(json.dumps(value, sort_keys=True) + "\n")


def server_events():
    lines = SERVER_LOG.read_text(errors="replace").splitlines()
    return [json.loads(s) for s in lines if s.startswith("{")]


def new_server_events():
    text = SERVER_LOG.read_bytes()[server_start_bytes:].decode(errors="replace")
    return [json.loads(s) for s in text.splitlines() if s.startswith("{")]


async def computer(label, actions, intent=None):
    start = time.time()
    result = await tools.computer(actions=actions)
    end = time.time()
    emit({
        "event": "computerCall",
        "label": label,
        "intent": intent,
        "actions": actions,
        "callStartEpoch": start,
        "callEndEpoch": end,
        "callDurationMs": (end - start) * 1000,
        "toolResultPreview": str(result)[:500],
    })
    return result


async def click(label, coordinate, intent=None):
    return await computer(
        label,
        [{"action": "left_click", "coordinate": coordinate}],
        intent,
    )


async def wait_for_event(event, *, round_number=None, count=1, timeout=8):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        rows = [
            x for x in new_server_events()
            if x.get("event") == event
            and (round_number is None or x.get("round") == round_number)
        ]
        if len(rows) >= count:
            return rows
        await asyncio.sleep(0.05)
    raise RuntimeError(
        f"Timed out waiting for event={event} round={round_number} count={count}"
    )


async def wait_until(epoch):
    delay = epoch - time.time()
    if delay > 0:
        await asyncio.sleep(delay)


async def play_sparse_round(round_number, start_at_ms, chart, players):
    """Attempt spaced notes on alternating peers; log late targets as skipped."""
    selected = [
        note for i, note in enumerate(chart["notes"])
        if i >= 2 and i % 3 == 2
        and note["kind"] in ("don", "ka") and not note["big"]
    ]
    delay_samples = []
    attempted = []
    skipped = []
    for ordinal, note in enumerate(selected):
        player = players[ordinal % 2]
        target_epoch = start_at_ms / 1000 + note["at"] / 1000
        lead = statistics.median(delay_samples[-5:]) if delay_samples else 0.120
        call_epoch = target_epoch - lead
        if time.time() > target_epoch - 0.030:
            skipped.append({
                "noteId": note["id"],
                "player": player,
                "reason": "previous computer call returned too late",
                "targetEpoch": target_epoch,
                "observedEpoch": time.time(),
            })
            emit({"event": "skippedNote", "round": round_number, **skipped[-1]})
            continue
        await wait_until(call_epoch)
        before = len([x for x in new_server_events() if x.get("event") == "hit"])
        coord = COORDS[f"{player}_{note['kind']}"]
        call_start = time.time()
        await click(
            f"round{round_number}-{player}-note{note['id']}-{note['kind']}",
            coord,
            intent={
                "round": round_number,
                "player": player,
                "chartNoteId": note["id"],
                "kind": note["kind"],
                "chartAtMs": note["at"],
                "targetEpoch": target_epoch,
            },
        )
        hits = [x for x in new_server_events() if x.get("event") == "hit"]
        delivered = hits[before] if len(hits) > before else None
        if delivered:
            delivery_delay = delivered["at"] / 1000 - call_start
            lateness_ms = delivered["at"] - target_epoch * 1000
            delay_samples.append(delivery_delay)
        else:
            delivery_delay = None
            lateness_ms = None
        row = {
            "round": round_number,
            "player": player,
            "noteId": note["id"],
            "kind": note["kind"],
            "chartAtMs": note["at"],
            "targetEpoch": target_epoch,
            "callStartEpoch": call_start,
            "serverHit": delivered,
            "deliveryDelayMs": (
                delivery_delay * 1000 if delivery_delay is not None else None
            ),
            "latenessMs": lateness_ms,
        }
        attempted.append(row)
        emit({"event": "scheduledHitResult", **row})
    return {"attempted": attempted, "skipped": skipped}


async def main():
    preflight = await tools.exec(
        command="echo 'DEVIN_EVENT:{\"preflight\":\"sdk exec reached native host\"}'",
        workdir=str(ROOT),
        timeout=1000,
    )
    preflight_line = next(
        (s for s in str(preflight).splitlines() if s.startswith("DEVIN_EVENT:")),
        None,
    )
    emit({
        "event": "preflight",
        "revision": "fb15df3db27974e490d9040e615dc06d40d4335d",
        "autoplay": False,
        "preflight": (
            json.loads(preflight_line.split(":", 1)[1])
            if preflight_line else {"unparsed": str(preflight)[:500]}
        ),
        "coordinates": COORDS,
    })

    await click("create-room", COORDS["hana_create"], "Hana Create room button")
    joins = await wait_for_event("join", count=1)
    room = joins[-1]["room"]
    emit({"event": "roomObserved", "room": room, "source": "server join log"})

    await click("focus-room-code", COORDS["sora_code"], "Sora room-code field")
    await computer(
        "type-room-code",
        [{"action": "key", "text": "super+a"},
         {"action": "type", "text": room}],
        "Type observed room code into visible native field",
    )
    await click("join-room", COORDS["sora_join"], "Sora Join button")
    await wait_for_event("join", count=2)
    await click("choose-easy", COORDS["hana_easy"], "Hana selects Easy chart")

    chart = json.loads(CHART.read_text())
    round_summaries = []
    for round_number in (1, 2):
        if round_number == 1:
            await click("hana-ready", COORDS["hana_ready"], "Hana Ready")
            await click("sora-ready", COORDS["sora_ready"], "Sora Ready")
        else:
            before_ready = len([
                x for x in new_server_events() if x.get("event") == "ready"
            ])
            await click(
                "hana-rematch-vote",
                COORDS["hana_rematch"],
                "First rematch vote; other client should remain on results",
            )
            await asyncio.sleep(1.0)
            after_first_ready = [
                x for x in new_server_events() if x.get("event") == "ready"
            ]
            emit({
                "event": "singleRematchVoteCheck",
                "before": before_ready,
                "after": len(after_first_ready),
                "round2Started": any(
                    x.get("event") == "start" and x.get("round") == 2
                    for x in new_server_events()
                ),
                "passed": (
                    len(after_first_ready) == before_ready + 1
                    and not any(
                        x.get("event") == "start" and x.get("round") == 2
                        for x in new_server_events()
                    )
                ),
            })
            await click(
                "sora-rematch-vote",
                COORDS["sora_rematch"],
                "Second rematch vote starts fresh round",
            )

        starts = await wait_for_event("start", round_number=round_number)
        start = starts[-1]
        emit({"event": "roundStartObserved", "serverEvent": start})
        await wait_until(start["startAt"] / 1000 + 0.6)
        await computer(
            f"round{round_number}-gameplay-screenshot",
            [{"action": "screenshot"}],
            "Both playing screens; automation banners must be absent",
        )
        played = await play_sparse_round(
            round_number, start["startAt"], chart, ["hana", "sora"]
        )
        await wait_for_event("result", round_number=round_number, timeout=50)
        result = [
            x for x in new_server_events()
            if x.get("event") == "result" and x.get("round") == round_number
        ][-1]
        await computer(
            f"round{round_number}-results-screenshot",
            [{"action": "screenshot"}],
            "Capture both visible shared-results screens",
        )
        hits = [
            x for x in new_server_events()
            if x.get("event") == "hit" and x.get("round") == round_number
        ]
        round_summaries.append({
            "round": round_number,
            "start": start,
            "result": result,
            "hits": hits,
            "schedule": played,
        })

    joins = [x for x in new_server_events() if x.get("event") == "join"]
    player_ids = {
        "hana": next(x["player"] for x in joins if x["name"] == "Hana"),
        "sora": next(x["player"] for x in joins if x["name"] == "Sora"),
    }
    checks = []
    for round_row in round_summaries:
        result_by_id = {
            x["id"]: x for x in round_row["result"]["players"]
        }
        for peer, player_id in player_ids.items():
            hits = [x for x in round_row["hits"] if x["player"] == player_id]
            positive = [
                x for x in hits
                if x.get("judgment") not in ("", "BAD", None)
            ]
            result = result_by_id[player_id]
            required = round_row["round"] == 1
            passed = (
                len(positive) >= 5 and result["score"] >= 2500
                if required else result["score"] > 0
            )
            checks.append({
                "test": f"round {round_row['round']} {peer} UI scoring",
                "requiredThreshold": (
                    ">=5 positive judgments and >=2500 points"
                    if required else ">0 points in completed rematch"
                ),
                "positiveJudgments": len(positive),
                "score": result["score"],
                "serverHits": len(hits),
                "passed": passed,
            })
    checks.append({
        "test": "single rematch vote waits",
        "passed": any(
            x.get("event") == "singleRematchVoteCheck" and x.get("passed")
            for x in records
        ),
    })
    summary = {
        "runId": run_id,
        "room": room,
        "autoplay": False,
        "players": joins,
        "rounds": round_summaries,
        "computerCalls": len([
            x for x in records if x["event"] == "computerCall"
        ]),
        "coordinateMap": COORDS,
        "checks": checks,
        "allRequiredChecksPassed": all(x["passed"] for x in checks),
        "limitations": [
            "Sparse chart-aware hits; intentionally unplayed notes are misses",
            "Full-chart/all-perfect play is not claimed",
            "75ms BIG paired-hit behavior is not established by this driver",
        ],
    }
    SUMMARY.write_text(json.dumps(summary, indent=2))
    emit({"event": "driverComplete", "summaryPath": str(SUMMARY)})
    print("DEVIN_EVENT:" + json.dumps({
        "complete": True,
        "room": room,
        "rounds": [
            {
                "round": r["round"],
                "players": r["result"].get("players"),
                "hits": len(r["hits"]),
                "attempted": len(r["schedule"]["attempted"]),
                "skipped": len(r["schedule"]["skipped"]),
            } for r in round_summaries
        ],
        "summary": str(SUMMARY),
    }))


asyncio.run(main())
