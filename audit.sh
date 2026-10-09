#!/bin/sh
# audit.sh — claude-cost-audit (lite)
# Scans Claude Code JSONL session transcripts and reports where your tokens went.
# Usage: ./audit.sh [transcript-dir]  (defaults to ~/.claude/projects)
# POSIX sh + awk. No jq, no python required.
set -u
DIR="${1:-$HOME/.claude/projects}"
RATE_IN="${TOKEN_BUDGET_RATE_IN:-2}"
RATE_OUT="${TOKEN_BUDGET_RATE_OUT:-10}"
RATE_CREAD="${TOKEN_BUDGET_RATE_CACHE_READ:-0.10}"
RATE_CWRITE="${TOKEN_BUDGET_RATE_CACHE_WRITE:-2.50}"
if ! command -v awk >/dev/null 2>&1; then
    echo "audit.sh: awk is required but not installed." >&2
    exit 1
fi
FILES=""
if command -v find >/dev/null 2>&1; then
    FILES=$(find "$DIR" -name 'transcript-*.jsonl' -type f 2>/dev/null)
fi
if [ -z "$FILES" ]; then
    echo "No Claude Code transcripts found. Looked in: $DIR"
    echo "Usage: ./audit.sh /path/to/your/claude/projects"
    exit 0
fi
TMPD=$(mktemp -d 2>/dev/null) || TMPD="/tmp/audit-$$"
mkdir -p "$TMPD" 2>/dev/null
trap 'rm -rf "$TMPD"' EXIT INT TERM
echo "$FILES" | awk '
function qkey(line, key,   re, pos, s, t, val) {
    re = "\"" key "\""
    s = line; t = ""
    while ((pos = index(s, re)) > 0) {
        t = substr(s, pos + length(re))
        s = substr(s, pos + length(re))
        sub(/^[ \t]*:[ \t]*/, "", t)
        if (t ~ /^[0-9]+/) { match(t, /[0-9]+/); t = substr(t, RSTART, RLENGTH); val = t + 0 } else { val = 0 }
    }
    return val
}
function qstr(line, key,   re, pos, s, t) {
    re = "\"" key "\""
    s = line; t = ""
    while ((pos = index(s, re)) > 0) {
        s = substr(s, pos + length(re))
        sub(/^[ \t]*:[ \t]*"/, "", s)
        if (match(s, /^[^"*/)) { t = substr(s, RSTART, RLENGTH) } else { t = "" }
    }
    return t
}
function stem(path,   n, parts, s) {
    n = split(path, parts, "/"); s = parts[n]
    sub(/\.jsonl$/, "", s); sub(/^transcript-/, "", s)
    return s
}
{
    line = $0
    if (line !~ /"type"[ \t]*:[ \t]*"assistant"/) next
    tin  = qkey(line, "input_tokens")
    tout = qkey(line, "output_tokens")
    tcr  = qkey(line, "cache_read_input_tokens")
    tcw  = qkey(line, "cache_creation_input_tokens")
    tot = tin + tout + tcr + tcw
    if (tot == 0) next
    sess = qstr(line, "sessionId")
    if (sess == "") sess = stem(FILENAME)
    reqs[sess]++; tok[sess] += tot
    iin[sess]  += tin; oout[sess] += tout
    cread[sess]+= tcr; cwrite[sess]+= tcw
    tot_all += tot; req_all++
    iin_all += tin; oout_all += tout; cread_all += tcr; cwrite_all += tcw
}
END {
    for (s in tok) {
        printf "S\t%s\t%d\t%d\t%d\t%d\t%d\t%d\n", s, tok[s]+0, reqs[s]+0, iin[s]+0, oout[s]+0, cread[s]+0, cwrite[s]+0
    }
    printf "G\t%d\t%d\t%d\t%d\t%d\t%d\n", tot_all+0, req_all+0, iin_all+0, oout_all+0, cread_all+0, cwrite_all+0
}
' $FILES > "$TMPD/raw"
if ! grep -q '^S' "$TMPD/raw"; then
    echo "Found transcripts, but no assistant messages with usage data. Nothing to report."
    exit 0
fi
grand=$(grep '^G' "$TMPD/raw")
set -- $grand
GTOT=$2; GREQ=$3; GIN=$4; GOUT=$5; GCREAD=$6; GCWRITE=$7
echo "================ TOKEN BUDGET AUDIT (lite) ================"
echo "Transcripts dir : $DIR"
echo "Sessions found  : $(grep -c '^S' "$TMPD/raw")"
echo "Requests scanned: $GREQ"
echo
echo "--- OVERALL ---"
echo "Total tokens        : $GTOT"
echo "  fresh input       : $GIN"
echo "  cache reads       : $GCREAD"
echo "  cache writes      : $GCWRITE"
echo "  output            : $GOUT"
if [ "$GTOT" -gt 0 ]; then
    CREPCT=$(awk -v s="$GCREAD" -v t="$GTOT" 'BEGIN{printf "%.1f", 100*s/t}')
else
    CREPCT="0.0"
fi
echo "Cache-read share    : ${CREPCT}%"
COST=$(awk -v i="$GIN" -v o="$GOUT" -v cr="$GCREAD" -v cw="$GCWRITE" -v ri="$RATE_IN" -v ro="$RATE_OUT" -v rc="$RATE_CREAD" -v rw="$RATE_CWRITE" 'BEGIN{printf "%.2f", (i*ri + o*ro + cr*rc + cw*rw)/1000000}')
echo "Rough API-equivalent cost: \$$COST"
echo
echo "--- PER-SESSION ---"
printf "%-36s %12s %8s\n" "session" "tokens" "requests"
grep '^S' "$TMPD/raw" | while IFS='\t' read -r _ sess tok reqs in out cread cwrite; do
    printf "%-36s %12d %8d\n" "$sess" "$tok" "$reqs"
done
echo
echo "--- TOP-10 BURN SESSIONS ---"
grep '^S' "$TMPD/raw" | awk -F'\t' '{print $3"\t"$2}' | sort -rn | head -10 | awk -F'\t' '{printf "%12d  %s\n", $1, $2}'
