---
description: File the current implementation plan into the knowledge archive
allowed-tools: Bash, Read, Write, Glob, Grep
---
Plans are filed into `~/claude_stuff/plans/inbox/` automatically and archived by the
weekly distill once their PR merges. Run this only to archive one now, or to write a
custom outcome note.

1. Identify this session's plan: the stamped file in `~/claude_stuff/plans/inbox/`
   whose `repo:` frontmatter matches this repository's `git remote get-url origin`
   (newest if several; fall back to matching the plan's content against this
   session). If it is still ambiguous, list the candidates and ask me — do not guess.
2. Move it to `~/claude_stuff/plans/archive/<project>/YYYY-MM-<slug>.md`, where
   `<project>` is the repo name. Keep the existing frontmatter and add: `pr` (ask me
   for the URL if you cannot determine it) and `status: implemented|partial|abandoned`.
   Set `status:` from what actually happened, not from what the plan intended.
3. Append an `## Outcome` section: what diverged from the plan and why. Infer it from
   this session and confirm with me in one question. The plan-vs-outcome delta is the
   part the weekly distill mines for lessons, so be specific about *why* something
   diverged, not just that it did.
4. Print a one-line `Plan: <github link into the knowledge repo>` for me to paste into
   the PR description. Build the link from the knowledge repo's origin and the new path.
5. Commit in `~/claude_stuff` on the current branch. Do not push — the sync cron does
   that within 30 minutes.
