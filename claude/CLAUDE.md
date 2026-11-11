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
- Wrap patent-sensitive or pre-disclosure content in `<private>...</private>`. This genuinely works: the
  tagged text is stripped before the memory layer stores it. Two blind spots, both tested: text inside a
  **tool call** (a shell command, a path, a grep pattern) is logged verbatim, and the editor's own session
  transcript keeps the full text on local disk regardless. So keep secrets out of commands and filenames,
  not just out of prose.
- When opening a PR from a session that used plan mode, include a `Plan: plans/inbox/<file>` line in the PR
  body so the plan and the PR stay linked.

@~/claude_stuff/index.md
