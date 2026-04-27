#!/usr/bin/env bash
# One-time setup for workspace-standards.
# Run this once after cloning — configures Claude Code, syncs skills, and creates a starter CLAUDE.md.
#
#   bash workspace-standards/scripts/setup.sh
#
# Safe to re-run: existing settings and CLAUDE.md are never overwritten.

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
WS_STANDARDS="$(cd "$SCRIPTS_DIR/.." && pwd)"
WORKSPACE="$(cd "$SCRIPTS_DIR/../.." && pwd)"

echo ""
echo "workspace-standards setup"
echo "========================="
echo "Workspace root : $WORKSPACE"
echo "Standards dir  : $WS_STANDARDS"
echo ""

# ── 1. Sync skills ────────────────────────────────────────────────────────────
echo "── Step 1: Syncing skills"
bash "$SCRIPTS_DIR/sync-skills.sh"
echo ""

# ── 2. Claude Code SessionStart hook ─────────────────────────────────────────
echo "── Step 2: Configuring Claude Code SessionStart hook"

SETTINGS_DIR="$WORKSPACE/.claude"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"
CHECK_SCRIPT="$SCRIPTS_DIR/check-skills.sh"

mkdir -p "$SETTINGS_DIR"

python3 - "$SETTINGS_FILE" "$CHECK_SCRIPT" <<'PYEOF'
import json, os, sys

settings_file, check_script = sys.argv[1], sys.argv[2]

if os.path.exists(settings_file):
    try:
        with open(settings_file) as f:
            settings = json.load(f)
    except json.JSONDecodeError:
        print(f"  WARNING: {settings_file} contains invalid JSON — creating backup and starting fresh")
        os.rename(settings_file, settings_file + ".bak")
        settings = {}
else:
    settings = {}

hooks = settings.setdefault("hooks", {})
session_start = hooks.setdefault("SessionStart", [])

# Idempotent: don't add if already present
for group in session_start:
    for hook in group.get("hooks", []):
        if hook.get("command") == check_script:
            print(f"  already configured — skipping")
            sys.exit(0)

session_start.append({
    "hooks": [{
        "type": "command",
        "command": check_script,
        "statusMessage": "Checking for unlinked skills..."
    }]
})

with open(settings_file, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")

print(f"  hook written to {settings_file}")
PYEOF

echo ""

# ── 3. Starter CLAUDE.md ──────────────────────────────────────────────────────
echo "── Step 3: CLAUDE.md"

CLAUDE_MD="$WORKSPACE/CLAUDE.md"

if [ -f "$CLAUDE_MD" ]; then
    echo "  already exists — skipping (edit manually to add @imports)"
else
    cat > "$CLAUDE_MD" <<MDEOF
# Workspace

## Coding Standards

@workspace-standards/.cursor/rules/security-standards.md

# Uncomment the rules that apply to your stack:
# @workspace-standards/.cursor/rules/kotlin-standards.md
# @workspace-standards/.cursor/rules/groovy-standards.md
# @workspace-standards/.cursor/rules/vue-standards.md
# @workspace-standards/.cursor/rules/api-standards.md
# @workspace-standards/.cursor/rules/playwright-standards.md
# @workspace-standards/.cursor/rules/terraform-standards.md

## Engineering Codex — Always-On Gotchas

# Uncomment if engineering-codex is cloned alongside workspace-standards:
# @engineering-codex/.cursor/rules/security-gotchas.md

## Available Skills

Skills are in \`.claude/skills/\` — invoke with /skill-name.
Run workspace-standards/scripts/sync-skills.sh to update after adding repos.
MDEOF
    echo "  created $CLAUDE_MD"
    echo "  → Uncomment the rules that apply to your stack"
fi

echo ""
echo "══════════════════════════════════════════════"
echo "  Setup complete!"
echo ""
echo "  Next steps:"
if [ ! -f "$CLAUDE_MD.already_existed" ]; then
    echo "  1. Edit CLAUDE.md at $WORKSPACE"
    echo "     Uncomment the rules for your stack"
    echo "  2. Open a new Claude Code session in $WORKSPACE"
    echo "     The SessionStart hook will now warn about unlinked skills"
    echo "  3. In Cursor / Augment, add $WORKSPACE to your workspace"
else
    echo "  1. Open a new Claude Code session in $WORKSPACE"
    echo "  2. In Cursor / Augment, add $WORKSPACE to your workspace"
fi
echo ""
echo "  Re-run this script whenever you add a new repo with skills."
echo "══════════════════════════════════════════════"
echo ""
