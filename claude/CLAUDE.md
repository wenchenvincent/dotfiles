# User-level memory

Generic preferences. Anything naming internal projects, hostnames or work specifics belongs in the private
knowledge repo, not here — this repo is public.

## Working style

- Prefer the smallest change that actually works. Reuse what is already in the codebase before adding to it;
  reach for the standard library before a dependency.
- Read the whole flow a change touches before editing it. Fix root causes, not the symptom named in the report.
- Report outcomes honestly: if a check fails, say so with the output; if a step was skipped, say that.
- Verify version-dependent claims against what is installed rather than from memory, and say which you did.

## Knowledge repo

Persistent cross-project knowledge lives in `~/claude_stuff` (private). Conventions:

- File substantive analyses — comparisons, architecture deep dives, anything that took real work to derive —
  into `~/claude_stuff/analyses/` with an entry in that repo's `index.md`, before the session ends. Do not
  leave them only in chat history.
- Wrap patent-sensitive or pre-disclosure content in `<private>...</private>`. Treat this as a hint, not a
  guarantee: claude-mem 13.24.5 does not implement any stripping for it, so do not put anything in a session
  that would be harmful merely to have on local disk.
- When opening a PR from a session that used plan mode, include a `Plan: plans/inbox/<file>` line in the PR
  body so the plan and the PR stay linked.

@~/claude_stuff/index.md
