#!/usr/bin/env bash
# Tests for probe-single command: single-agent probe for multi-agentic skill dispatch (v8.54.0)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ORCHESTRATE="$PROJECT_ROOT/scripts/orchestrate.sh"

TEST_COUNT=0; PASS_COUNT=0; FAIL_COUNT=0
pass() { TEST_COUNT=$((TEST_COUNT+1)); PASS_COUNT=$((PASS_COUNT+1)); echo "PASS: $1"; }
fail() { TEST_COUNT=$((TEST_COUNT+1)); FAIL_COUNT=$((FAIL_COUNT+1)); echo "FAIL: $1 — $2"; }
assert_contains() {
  local output="$1" pattern="$2" label="$3"
  echo "$output" | grep -qE "$pattern" && pass "$label" || fail "$label" "missing: $pattern"
}

# ── probe_single_agent function exists ────────────────────────────────────────

assert_contains "$(grep -c 'probe_single_agent()' "$ORCHESTRATE" 2>/dev/null || echo 0)" \
  "[1-9]" "probe_single_agent: function exists in orchestrate.sh"

# ── probe-single dispatch case exists ─────────────────────────────────────────

assert_contains "$(grep -c 'probe-single)' "$ORCHESTRATE" 2>/dev/null || echo 0)" \
  "[1-9]" "probe-single: dispatch case exists in orchestrate.sh"

# ── probe-single calls probe_single_agent ────────────────────────────────────

assert_contains "$(grep -A10 'probe-single)' "$ORCHESTRATE" | head -15)" \
  "probe_single_agent" "probe-single: dispatch calls probe_single_agent()"

# ── probe_single_agent writes result files ───────────────────────────────────

assert_contains "$(grep -A200 'probe_single_agent()' "$ORCHESTRATE" | head -220)" \
  'RESULTS_DIR.*agent_type.*task_id.*\.md' "probe_single_agent: writes result file to RESULTS_DIR"

# ── probe_single_agent calls apply_persona ───────────────────────────────────

assert_contains "$(grep -A100 'probe_single_agent()' "$ORCHESTRATE" | head -120)" \
  "apply_persona" "probe_single_agent: calls apply_persona()"

# ── probe_single_agent calls enforce_context_budget ──────────────────────────

assert_contains "$(grep -A100 'probe_single_agent()' "$ORCHESTRATE" | head -120)" \
  "enforce_context_budget" "probe_single_agent: calls enforce_context_budget()"

# ── probe_single_agent calls get_agent_command ───────────────────────────────

assert_contains "$(grep -A120 'probe_single_agent()' "$ORCHESTRATE" | head -140)" \
  "get_agent_command" "probe_single_agent: calls get_agent_command()"

# ── probe_single_agent has auth retry logic ──────────────────────────────────

assert_contains "$(grep -A200 'probe_single_agent()' "$ORCHESTRATE" | head -220)" \
  "auth_attempt|max_auth_retries" "probe_single_agent: has auth retry logic"

# ── probe_single_agent outputs result file path ──────────────────────────────

assert_contains "$(grep -A250 'probe_single_agent()' "$ORCHESTRATE" | head -270)" \
  'echo.*result_file' "probe_single_agent: outputs result file path on stdout"

# ── probe_single_agent handles timeout status ────────────────────────────────

assert_contains "$(grep -A250 'probe_single_agent()' "$ORCHESTRATE" | head -270)" \
  "Status: TIMEOUT" "probe_single_agent: handles TIMEOUT status"

# ── probe_single_agent handles failure status ────────────────────────────────

assert_contains "$(grep -A250 'probe_single_agent()' "$ORCHESTRATE" | head -270)" \
  "Status: FAILED" "probe_single_agent: handles FAILED status"

# ── flow-discover.md references probe-single ─────────────────────────────────

FLOW_DISCOVER="$PROJECT_ROOT/.claude/skills/flow-discover.md"
assert_contains "$(grep -c 'probe-single' "$FLOW_DISCOVER" 2>/dev/null || echo 0)" \
  "[1-9]" "flow-discover.md: references probe-single command"

# ── flow-discover.md has intensity parsing ───────────────────────────────────

assert_contains "$(grep -c 'intensity' "$FLOW_DISCOVER" 2>/dev/null || echo 0)" \
  "[1-9]" "flow-discover.md: has intensity parsing"

# ── flow-discover.md uses Agent tool (not single Bash probe) ─────────────────

assert_contains "$(grep -c 'run_in_background.*true' "$FLOW_DISCOVER" 2>/dev/null || echo 0)" \
  "[1-9]" "flow-discover.md: uses Agent(run_in_background=true)"

# ── flow-discover.md preserves test markers ──────────────────────────────────

assert_contains "$(cat "$FLOW_DISCOVER")" \
  "execution_mode: enforced" "flow-discover.md: preserves execution_mode: enforced"

assert_contains "$(cat "$FLOW_DISCOVER")" \
  "orchestrate_sh_executed" "flow-discover.md: preserves orchestrate_sh_executed validation gate"

assert_contains "$(cat "$FLOW_DISCOVER")" \
  "synthesis_file_exists" "flow-discover.md: preserves synthesis_file_exists validation gate"

assert_contains "$(cat "$FLOW_DISCOVER")" \
  "probe-synthesis" "flow-discover.md: preserves probe-synthesis reference"

assert_contains "$(cat "$FLOW_DISCOVER")" \
  "Perplexity" "flow-discover.md: preserves Perplexity indicator"

assert_contains "$(cat "$FLOW_DISCOVER")" \
  "EXECUTION CONTRACT" "flow-discover.md: preserves EXECUTION CONTRACT header"

# ── research.md has intensity AskUserQuestion ────────────────────────────────

RESEARCH_CMD="$PROJECT_ROOT/.claude/commands/research.md"
assert_contains "$(grep -c 'Research Intensity' "$RESEARCH_CMD" 2>/dev/null || echo 0)" \
  "[1-9]" "research.md: has Research Intensity AskUserQuestion"

assert_contains "$(grep -c 'intensity=' "$RESEARCH_CMD" 2>/dev/null || echo 0)" \
  "[1-9]" "research.md: passes intensity in Skill args"

# ── discover.md aligns intensity question ────────────────────────────────────

DISCOVER_CMD="$PROJECT_ROOT/.claude/commands/discover.md"
assert_contains "$(grep -c 'Research Intensity' "$DISCOVER_CMD" 2>/dev/null || echo 0)" \
  "[1-9]" "discover.md: has Research Intensity header"

assert_contains "$(grep -c 'intensity=' "$DISCOVER_CMD" 2>/dev/null || echo 0)" \
  "[1-9]" "discover.md: passes intensity in Skill args"

# ── backward compat: probe_discover still exists ─────────────────────────────

assert_contains "$(grep -c 'probe_discover()' "$ORCHESTRATE" 2>/dev/null || echo 0)" \
  "[1-9]" "probe_discover: original function still exists (backward compat)"

# ── backward compat: discover|research|probe dispatch still exists ───────────

assert_contains "$(grep -c 'discover|research|probe)' "$ORCHESTRATE" 2>/dev/null || echo 0)" \
  "[1-9]" "discover|research|probe: original dispatch still exists (backward compat)"

# ── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo "═══════════════════════════════════════════"
echo "probe-single tests: $PASS_COUNT/$TEST_COUNT passed"
if [[ $FAIL_COUNT -gt 0 ]]; then
  echo "$FAIL_COUNT FAILED"
  exit 1
fi
echo "All tests passed."
