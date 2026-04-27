#!/usr/bin/env bash
# Checks for repos with .cursor/skills/ that aren't linked in .claude/skills/ or .agents/skills/.
# Called by the Claude Code SessionStart hook — outputs a systemMessage if any are missing.
#
# Run from anywhere — the script self-locates.

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$(cd "$SCRIPTS_DIR/../.." && pwd)"
CLAUDE_SKILLS_DIR="$WORKSPACE/.claude/skills"
AGENTS_SKILLS_DIR="$WORKSPACE/.agents/skills"
missing=()

for skill_dir in "$WORKSPACE"/*/.cursor/skills/*/; do
  [ -d "$skill_dir" ] || continue
  skill_name="$(basename "$skill_dir")"
  repo_name="$(basename "$(dirname "$(dirname "$(dirname "$skill_dir")")")")"
  label="$skill_name ($repo_name)"

  if [ ! -L "$CLAUDE_SKILLS_DIR/$skill_name" ]; then
    missing+=("claude:$label")
  fi
  if [ ! -L "$AGENTS_SKILLS_DIR/$skill_name" ]; then
    missing+=("augment:$label")
  fi
done

if [ "${#missing[@]}" -gt 0 ]; then
  list="${missing[*]}"
  printf '{"systemMessage": "Unlinked skills detected — run workspace-standards/scripts/sync-skills.sh to add them: %s"}\n' "$list"
else
  printf '{}\n'
fi
