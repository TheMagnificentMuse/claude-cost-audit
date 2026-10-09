# claude-cost-audit

**Audit your Claude Code token spend — and reduce your Claude API costs — from your session transcripts.**

If you run Claude Code daily, you're burning tokens you can't see. `claude-cost-audit` reads your session transcripts and shows where every token went: per-session totals, the top-10 burn sessions, how cache-heavy your usage is, and a rough API-equivalent dollar cost. Five minutes to install, one command to run.

This is the **free lite version** of the [Token Budget Kit](https://themusingsofmuse.gumroad.com/l/xpukki). It measures; the kit adds attribution, flags, and the fix-it playbook.

## What's here

| File | What it is |
|---|---|
| `audit.sh` | The audit script. POSIX `sh` + `awk`, no dependencies. |
| `budget-CLAUDE.md` | Cost-discipline rules to paste into your `CLAUDE.md`. |
| `tests/` | Test suite with synthetic transcripts (`tests/run-tests.sh`). |
| `TESTLOG.md` | What was verified and the results. |

## Install

```bash
git clone https://github.com/TheMagnificentMuse/claude-cost-audit.git
cd claude-cost-audit
chmod +x audit.sh
./audit.sh
```

`audit.sh` looks in `~/.claude/projects` by default. If your transcripts live elsewhere:

```bash
./audit.sh /path/to/your/claude/projects
```

macOS works too; on Windows use WSL or Git Bash.

### Cost-discipline rules (optional, 5 minutes)

Paste the sections from `budget-CLAUDE.md` into your project's `CLAUDE.md` (or `~/.claude/CLAUDE.md` for a global default): agent fan-out caps, batch-before-you-spawn, the 60%-context handoff rule, and the Sonnet-by-default model policy. Tune the `[BRACKETED]` values, then delete the brackets.

## Example output

Sample output from the bundled test fixtures (synthetic transcripts):

```
================ TOKEN BUDGET AUDIT (lite) ================
Transcripts dir : tests/fixtures/projects
Sessions found  : 2
Requests scanned: 5

--- OVERALL ---
Total tokens        : 51020
  fresh input       : 7200
  cache reads       : 40000
  cache writes      : 2380
  output            : 1440
Cache-read share    : 78.4% (healthy Claude Code usage is cache-read-heavy;
                      under ~50% usually means your context isn't caching)
Rough API-equivalent cost: $0.04
  (rates: in $2 / out $10 / cache-read $0.10 / cache-write $2.50 per 1M;
   defaults = Sonnet 5.5, 2026-10-09. Override with TOKEN_BUDGET_RATE_* env vars;
   re-check rates at anthropic.com/pricing.)
```

## License

MIT — fork it, PR it, vendor it. See `LICENSE`.
