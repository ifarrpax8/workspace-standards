#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SOURCE="$(cd "$SCRIPT_DIR/../skills" && pwd)"
SKILLS_TARGET="$HOME/.cursor/skills"
RULES_SOURCE="$(cd "$SCRIPT_DIR/../rules/auto-apply" && pwd)"
RULES_TARGET="$HOME/.cursor/rules"

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
for rule in "$RULES_SOURCE"/jira-standards.md; do
  [ -f "$rule" ] || continue
  rule_name="$(basename "$rule")"
  cp "$rule" "$RULES_TARGET/$rule_name"
  echo "  Copied: $rule_name"
  ((copied++))
done

echo "  Rules copied: $copied"
echo ""

# --- Summary ---
total_skills=$(find "$SKILLS_TARGET" -maxdepth 1 -type l | wc -l | tr -d ' ')
echo "=== Done ==="
echo "Skills available in Cursor: $total_skills"
echo ""
echo "Restart Cursor (or reload window) for skills to appear."
echo "Verify in: Cursor Settings → Skills"
