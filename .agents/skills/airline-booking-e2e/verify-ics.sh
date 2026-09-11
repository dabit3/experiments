#!/usr/bin/env bash
# Verifies the calendar file downloaded at the end of the airline-booking E2E scenario.
#   verify-ics.sh <path/to/contrail-REF.ics> [REF]
# Prints the (unfolded) file, then one line per check. Exits 1 if any check fails.
set -u

file="${1:-}"
ref="${2:-}"
if [[ -z "$file" || ! -f "$file" ]]; then
  echo "usage: $0 <contrail-REF.ics> [REF]" >&2
  exit 2
fi
if [[ -z "$ref" ]]; then
  ref="$(basename "$file" .ics)"
  ref="${ref#contrail-}"
fi

# RFC 5545 folding: continuation lines start with a single space.
unfolded="$(tr -d '\r' <"$file" | awk '
  /^ / { buf = buf substr($0, 2); next }
  { if (NR > 1) print buf; buf = $0 }
  END { print buf }')"

echo "----- $file (unfolded) -----"
echo "$unfolded"
echo "----------------------------"

fail=0
check() { # check <ok:0|1> <label>
  if [[ "$1" -eq 0 ]]; then echo "ok    $2"; else echo "FAIL  $2"; fail=1; fi
}
count() { grep -c -- "$1" <<<"$unfolded"; }

check $([[ "$(count '^BEGIN:VEVENT$')" -eq 2 ]]; echo $?) "exactly two VEVENT blocks ($(count '^BEGIN:VEVENT$'))"
check $([[ "$(count '^TRIGGER:-PT3H$')" -eq 2 ]]; echo $?) "two 3-hour alarms (TRIGGER:-PT3H)"
check $([[ "$(count '^ACTION:DISPLAY$')" -eq 2 ]]; echo $?) "each alarm is a DISPLAY alarm"
check $([[ "$(count "^UID:${ref}-")" -eq 2 ]]; echo $?) "both UIDs carry booking reference ${ref}"
check $([[ "$(count "Booking reference ${ref}")" -eq 2 ]]; echo $?) "both descriptions mention booking reference ${ref}"
check $(grep -q '^SUMMARY:Flight [A-Z]\{2\}[0-9]\+ SFO → JFK$' <<<"$unfolded"; echo $?) "outbound summary is SFO → JFK"
check $(grep -q '^SUMMARY:Flight [A-Z]\{2\}[0-9]\+ JFK → SFO$' <<<"$unfolded"; echo $?) "return summary is JFK → SFO"
check $(grep -q '^LOCATION:San Francisco International (SFO)' <<<"$unfolded"; echo $?) "outbound location is SFO"
check $(grep -q '^LOCATION:John F. Kennedy International (JFK)' <<<"$unfolded"; echo $?) "return location is JFK"
check $([[ "$(count 'Nonstop')" -eq 2 ]]; echo $?) "both flights are nonstop"

# Every event must have DTSTART < DTEND (UTC stamps), events in chronological order, all in the future.
starts=($(grep '^DTSTART:' <<<"$unfolded" | cut -d: -f2))
ends=($(grep '^DTEND:' <<<"$unfolded" | cut -d: -f2))
now="$(date -u +%Y%m%dT%H%M%SZ)"
check $([[ ${#starts[@]} -eq 2 && ${#ends[@]} -eq 2 ]]; echo $?) "two DTSTART/DTEND pairs"
if [[ ${#starts[@]} -eq 2 && ${#ends[@]} -eq 2 ]]; then
  check $([[ "${starts[0]}" < "${ends[0]}" && "${starts[1]}" < "${ends[1]}" ]]; echo $?) "each event ends after it starts"
  check $([[ "${starts[0]}" < "${starts[1]}" ]]; echo $?) "return departs after outbound (${starts[0]} < ${starts[1]})"
  check $([[ "${starts[0]}" > "$now" ]]; echo $?) "flights are in the future"
fi

# Seats: "Seats — Name: 10A, Name: 10B" — both passengers on each leg must be adjacent
# window + middle (A+B or E+F in the same row).
leg=0
while IFS= read -r seatline; do
  leg=$((leg + 1))
  seats=($(grep -o '[0-9]\{1,2\}[A-F]' <<<"$seatline"))
  check $([[ ${#seats[@]} -eq 2 ]]; echo $?) "leg $leg lists two seats (${seats[*]:-none})"
  if [[ ${#seats[@]} -eq 2 ]]; then
    r1="${seats[0]%[A-F]}"; l1="${seats[0]#"$r1"}"
    r2="${seats[1]%[A-F]}"; l2="${seats[1]#"$r2"}"
    pair="$(printf '%s%s' "$l1" "$l2" | fold -w1 | sort | tr -d '\n')"
    check $([[ "$r1" == "$r2" && ( "$pair" == "AB" || "$pair" == "EF" ) ]]; echo $?) \
      "leg $leg seats ${seats[0]}+${seats[1]} are adjacent window + middle"
  fi
done < <(sed 's/\\,/,/g' <<<"$unfolded" | grep -o 'Seats — [^\\]*')
check $([[ $leg -eq 2 ]]; echo $?) "seat assignments present for both legs"

if [[ $fail -eq 0 ]]; then echo "PASS  $file"; else echo "FAIL  $file"; exit 1; fi
