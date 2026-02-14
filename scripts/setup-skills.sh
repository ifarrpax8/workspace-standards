#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_SOURCE="$REPO_ROOT/skills"
SKILLS_TARGET="$HOME/.cursor/skills"
RULES_SOURCE="$REPO_ROOT/rules/auto-apply"
RULES_TARGET="$HOME/.cursor/rules"
AGENTS_TARGET="$HOME/.cursor/agents"

CODEX_ROOT=""
CODEX_CANDIDATES=(
  "$REPO_ROOT/../engineering-codex"
  "$HOME/Development/engineering-codex"
)
for candidate in "${CODEX_CANDIDATES[@]}"; do
  if [ -d "$candidate" ]; then
    CODEX_ROOT="$(cd "$candidate" && pwd)"
    break
  fi
done

echo "=== Pax8 Workspace Standards Setup ==="
echo ""

# --- Skills ---
echo "Linking skills from $SKILLS_SOURCE → $SKILLS_TARGET"
mkdir -p "$SKILLS_TARGET"

linked=0
skipped=0
for skill in "$SKILLS_SOURCE"/*/; do
  skill_name="$(basename "$skill")"
  target="$SKILLS_TARGET/$skill_name"

  existing="$(readlink "$target" 2>/dev/null || true)"
  if [ -L "$target" ] && [ "${existing%/}" = "${skill%/}" ]; then
    ((skipped++))
    continue
  fi

  ln -sfn "${skill%/}" "$target"
  echo "  Linked: $skill_name"
  ((linked++))
done

echo "  Skills linked: $linked, already up-to-date: $skipped"
echo ""

# --- User-level rules ---
echo "Copying Pax8-wide rules to $RULES_TARGET"
mkdir -p "$RULES_TARGET"

copied=0
for rule in "$RULES_SOURCE"/jira-standards.md "$RULES_SOURCE"/security-standards.md; do
  [ -f "$rule" ] || continue
  rule_name="$(basename "$rule")"
  cp "$rule" "$RULES_TARGET/$rule_name"
  echo "  Copied: $rule_name"
  ((copied++))
done

echo "  Rules copied: $copied"
echo ""

# --- Subagents ---
echo "Linking subagents to $AGENTS_TARGET"
mkdir -p "$AGENTS_TARGET"

agents_linked=0
agents_skipped=0

link_agents_from() {
  local source_dir="$1"
  [ -d "$source_dir" ] || return 0

  for agent in "$source_dir"/*.md; do
    [ -f "$agent" ] || continue
    agent_name="$(basename "$agent")"
    target="$AGENTS_TARGET/$agent_name"

    existing="$(readlink "$target" 2>/dev/null || true)"
    if [ -L "$target" ] && [ "$existing" = "$agent" ]; then
      ((agents_skipped++))
      continue
    fi

    ln -sfn "$agent" "$target"
    echo "  Linked: $agent_name"
    ((agents_linked++))
  done
}

link_agents_from "$REPO_ROOT/.cursor/agents"

if [ -n "$CODEX_ROOT" ]; then
  echo "  Found engineering-codex at $CODEX_ROOT"
  link_agents_from "$CODEX_ROOT/.cursor/agents"
else
  echo "  engineering-codex not found — skipping codex agents"
  echo "  (Expected at ../engineering-codex or ~/Development/engineering-codex)"
fi

echo "  Agents linked: $agents_linked, already up-to-date: $agents_skipped"
echo ""

# --- Summary ---
total_skills=$(find "$SKILLS_TARGET" -maxdepth 1 -type l | wc -l | tr -d ' ')
total_agents=$(find "$AGENTS_TARGET" -maxdepth 1 \( -type l -o -type f \) -name "*.md" | wc -l | tr -d ' ')
echo "=== Done ==="
echo "Skills available:    $total_skills"
echo "Subagents available: $total_agents"
echo ""
echo "Restart Cursor (or reload window) for changes to take effect."
echo "Verify skills in:    Cursor Settings → Skills"
echo "Invoke agents with:  /codex-navigator, /standards-auditor, /ticket-refiner"
