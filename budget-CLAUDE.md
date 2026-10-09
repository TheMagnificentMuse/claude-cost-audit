# budget-CLAUDE.md — cost-discipline rules for Claude Code (lite)

Paste the sections below into your `CLAUDE.md` (project root or `~/.claude/CLAUDE.md` for a global default). Tune the `[BRACKETED]` values to your workload, then delete the brackets.

## 1. Agent fan-out caps

- **Never run more than [3] subagents concurrently in one session.**
- If a task "needs" more than [3] parallel agents, split the work into sequential phases instead.
- **One agent, one job.** Every spawn must have a written deliverable: a file, a diff, a decision, a summary.
- **No nested fan-out.** Subagents must not spawn their own subagents.

## 2. Batch before you spawn

- **Never spawn an agent for a unit of work smaller than ~[15] minutes of equivalent effort.**
- **Batch small units.** Hand ONE agent a checklist, not five agents one task each.
- Before spawning, ask: "could I do this with one Grep and one Read instead?"

## 3. Hand off before bloat (the 60% rule)

- **At ~[60]% context usage, stop and compress.** Write state to a scratch file; hand ONE fresh agent the state file.
- **Never paste the full old transcript into the new session.**

## 4. Model policy: Sonnet by default

- **Default to Sonnet for everything.** **Opus only for:** architecture decisions, debugging that defeated [2] Sonnet attempts, security-sensitive review, novel ambiguous problems. **Haiku for:** bulk mechanical transforms and triage.
- **Never "upgrade to Opus to be safe."**

---

*These rules are the policy layer. audit.sh is the measurement layer — run it weekly. (The paid Token Budget Kit adds a pre-burn hook as the enforcement layer.)*
