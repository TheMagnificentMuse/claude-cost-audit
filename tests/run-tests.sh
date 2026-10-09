#!/bin/sh
# run-tests.sh — verification for claude-cost-audit (lite). Usage: ./tests/run-tests.sh (from repo root)
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
TDIR="$REPO/tests/fixtures/projects/demo"
PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "  PASS: $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  FAIL: $1"; }
echo "== audit.sh: synthetic transcript test =="
rm -rf "$REPO/tests/fixtures"; mkdir -p "$TDIR"
cat > "$TDIR/transcript-alpha.jsonl" <<'EOF'
{"type":"assistant","sessionId":"sess-alpha","message":{"model":"claude-sonnet-5.5","usage":{"input_tokens":1000,"output_tokens":200,"cache_read_input_tokens":5000,"cache_creation_input_tokens":300}}}
{"type":"user","sessionId":"sess-alpha","message":{"content":"here is my log"}}
{"type":"assistant","sessionId":"sess-alpha","message":{"model":"claude-sonnet-5.5","usage":{"input_tokens":2000,"output_tokens":400,"cache_read_input_tokens":10000,"cache_creation_input_tokens":600}}}
{"type":"assistant","sessionId":"sess-alpha","message":{"model":"claude-sonnet-5.5","usage":{"input_tokens":500,"output_tokens":100,"cache_read_input_tokens":2000,"cache_creation_input_tokens":100}}}
EOF
cat > "$TDIR/transcript-beta.jsonl" <<'EOF'
{"type":"assistant","message":{"model":"claude-sonnet-5.5","usage":{"input_tokens":3000,"output_tokens":600,"cache_read_input_tokens":20000,"cache_creation_input_tokens":1200}}}
{"type":"assistant","message":{"model":"claude-sonnet-5.5","usage":{"input_tokens":700,"output_tokens":140,"cache_read_input_tokens":3000,"cache_creation_input_tokens":180}}}
EOF
OUT=$("$REPO/audit.sh" "$REPO/tests/fixtures/projects")
echo "$OUT" | grep -q "Total tokens        : 51020" && ok "grand total" || bad "grand total"
echo "$OUT" | grep -q "Requests scanned: 5" && ok "5 requests" || bad "requests"
echo "$OUT" | grep -q 'Rough API-equivalent cost: \$0.04' && ok "cost" || bad "cost"
echo
echo "RESULT: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
