#!/usr/bin/env bash
# Syncs all .cursor/skills/* from repos into:
#   .claude/skills/  — Claude Code workspace-level skill index
#   .agents/skills/  — Augment workspace-level skill index
#
# Run from anywhere — the script self-locates:
#   bash ~/Development/workspace-standards/scripts/sync-skills.sh
#
# Re-run whenever you add a new repository with skills.

set -euo pipefail

# workspace-standards/scripts/ → workspace-standards/ → parent dev directory
SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$(cd "$SCRIPTS_DIR/../.." && pwd)"
CLAUDE_SKILLS_DIR="$WORKSPACE/.claude/skills"
AGENTS_SKILLS_DIR="$WORKSPACE/.agents/skills"

mkdir -p "$CLAUDE_SKILLS_DIR"
mkdir -p "$AGENTS_SKILLS_DIR"

claude_linked=0
claude_skipped=0
claude_warned=0
agents_linked=0
agents_skipped=0
agents_warned=0

for skill_dir in "$WORKSPACE"/*/.cursor/skills/*/; do
  [ -d "$skill_dir" ] || continue

  skill_name="$(basename "$skill_dir")"
  repo_name="$(basename "$(dirname "$(dirname "$(dirname "$skill_dir")")")")"
  rel_path="../../$repo_name/.cursor/skills/$skill_name"

  # Claude Code
  target="$CLAUDE_SKILLS_DIR/$skill_name"
  if [ -L "$target" ]; then
    claude_skipped=$((claude_skipped + 1))
  elif [ -e "$target" ]; then
    echo "  WARN (claude): $skill_name already exists and is not a symlink — skipping"
    claude_warned=$((claude_warned + 1))
  else
    ln -s "$rel_path" "$target"
    echo "  linked (claude): $skill_name  ($repo_name)"
    claude_linked=$((claude_linked + 1))
  fi

  # Augment
  target="$AGENTS_SKILLS_DIR/$skill_name"
  if [ -L "$target" ]; then
    agents_skipped=$((agents_skipped + 1))
  elif [ -e "$target" ]; then
    echo "  WARN (augment): $skill_name already exists and is not a symlink — skipping"
    agents_warned=$((agents_warned + 1))
  else
    ln -s "$rel_path" "$target"
    echo "  linked (augment): $skill_name  ($repo_name)"
    agents_linked=$((agents_linked + 1))
  fi
done

echo ""
echo "Claude Code (.claude/skills): $claude_linked linked, $claude_skipped already present, $claude_warned warnings"
echo "Augment (.agents/skills):     $agents_linked linked, $agents_skipped already present, $agents_warned warnings"
echo ""
echo "=== .claude/skills ==="
ls "$CLAUDE_SKILLS_DIR"
echo ""
echo "=== .agents/skills ==="
ls "$AGENTS_SKILLS_DIR"
