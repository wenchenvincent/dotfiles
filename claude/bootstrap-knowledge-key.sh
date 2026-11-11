#!/usr/bin/env bash
# Per-machine deploy key for the private knowledge repo.
#
# Lives in this (public) repo rather than in the knowledge repo because it has to
# run BEFORE ~/claude_stuff can be cloned. It writes no secret here: the private
# key stays in ~/.ssh, and only the repo path below is public.
#
# Idempotent and safe to re-run: if SSH access already works it exits immediately.
# With gh authenticated the key self-registers; without gh it prints the public key
# and the next ./install completes the clone.

set -u
REPO=wenchenvincent/claude_stuff
KEY="$HOME/.ssh/knowledge_deploy"
SSH_OPTS="-o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -o BatchMode=yes"

[ -f /.dockerenv ] && exit 0            # containers use the host's key via the mount
command -v ssh-keygen >/dev/null 2>&1 || { echo "knowledge: ssh-keygen missing" >&2; exit 0; }

mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
if [ ! -f "$KEY" ]; then
  ssh-keygen -t ed25519 -N '' -C "claude-knowledge-sync@$(hostname -s)" -f "$KEY" -q || exit 0
  chmod 600 "$KEY"
fi

# Already working? Nothing to do — this also covers a key registered on an earlier run.
if GIT_SSH_COMMAND="ssh -i $KEY $SSH_OPTS" git ls-remote -q "git@github.com:$REPO.git" >/dev/null 2>&1; then
  exit 0
fi

if gh auth status >/dev/null 2>&1; then
  if gh repo deploy-key add "$KEY.pub" --repo "$REPO" --allow-write --title "$(hostname -s)" >/dev/null 2>&1; then
    echo "knowledge: deploy key registered for $(hostname -s)"
    exit 0
  fi
fi

echo "knowledge: add this key to $REPO as a deploy key WITH write access," >&2
echo "           then re-run ./install:" >&2
cat "$KEY.pub" >&2
exit 0
