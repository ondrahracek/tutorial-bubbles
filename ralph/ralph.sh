#!/usr/bin/env bash
# Ralph Loop: Iterative AI agent execution until PRD completion
# Runs Cursor CLI repeatedly, stopping when the agent signals COMPLETE.
# See: https://ralph-cli.dev/ | https://cursor.com/docs/cli/using
#
# Environment: Flutter package or app (pubspec.yaml). Android build supported.
# Prerequisites: Cursor CLI (agent) and Flutter SDK in PATH. Run from project root or ralph/.

set -euo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly COMPLETE_MARKER="<promise>COMPLETE</promise>"
readonly PRD_FILE="ralph/prd.json"
readonly PROGRESS_FILE="ralph/progress.txt"

# Ensure we run from project root (parent of ralph/)
cd_to_project_root() {
  local root
  root="$(cd "$(dirname "$0")/.." && pwd)"
  [[ -f "$root/pubspec.yaml" ]] || {
    echo "Error: pubspec.yaml not found in $root - this must be a Flutter project root" >&2
    exit 1
  }
  cd "$root"
}
cd_to_project_root

usage() {
  echo "Usage: $SCRIPT_NAME [iterations]"
  echo ""
  echo "  iterations  Maximum number of agent iterations (default: prompts interactively)"
  echo ""
  echo "Ralph runs Cursor CLI in a loop. Each iteration implements the highest-priority"
  echo "PRD feature. The loop stops when the agent outputs $COMPLETE_MARKER"
  echo "or when the iteration limit is reached."
  exit 1
}

get_iterations() {
  local iterations
  if [[ -n "${1:-}" ]]; then
    if [[ "$1" =~ ^[0-9]+$ ]] && [[ "$1" -gt 0 ]]; then
      echo "$1"
      return
    fi
    echo "Error: iterations must be a positive integer" >&2
    exit 1
  fi
  while true; do
    read -rp "Enter number of iterations: " iterations
    if [[ "$iterations" =~ ^[0-9]+$ ]] && [[ "$iterations" -gt 0 ]]; then
      echo "$iterations"
      return
    fi
    echo "Please enter a positive integer." >&2
  done
}

run_agent_iteration() {
  local prompt
  prompt="@${PRD_FILE} @${PROGRESS_FILE}

This is a Flutter package or app. Work on one PRD feature per iteration.

1. Find the highest-priority PRD feature to work on and work ONLY on that feature.
   Choose the one YOU decide has the highest priority - not necessarily the first in the list.
2. Before committing, run the feedback loops:
   - flutter analyze (must pass with no errors; address any warnings)
   - flutter test (must pass)
   - If the package has an example/ app: run 'flutter pub get' and 'flutter analyze' in example/
3. Update the PRD: set passes to true for the item(s) you completed.
4. Append your progress to the ${PROGRESS_FILE} file. Keep it concise for the next iteration.
5. Make a git commit of that feature.
ONLY WORK ON A SINGLE FEATURE.

When the PRD is fully complete (all items have passes: true), output exactly this on its own line as the final signal:
${COMPLETE_MARKER}
Do NOT mention or reference this marker anywhere else in your response (e.g. do not write \"was not emitted\" or similar)."

  agent -p "$prompt" --force --trust --workspace "$(pwd)"
}

main() {
  [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && usage

  local iterations
  iterations=$(get_iterations "${1:-}")

  echo "Ralph Loop: up to $iterations iteration(s)"
  echo "Working directory: $(pwd)"
  echo "Stopping when agent outputs: $COMPLETE_MARKER"
  echo ""

  for ((i = 1; i <= iterations; i++)); do
    echo "========== Iteration $i / $iterations =========="
    echo ""

    local result
    local status
    result=$(run_agent_iteration 2>&1)
    status=$?
    echo "$result"
    if [[ $status -ne 0 ]]; then
      echo "Agent iteration failed with exit code $status. Not consuming iteration."
      continue
    fi

    local has_complete_marker=false
    while IFS= read -r line; do
      trimmed=$(echo "$line" | tr -d '[:space:]')
      if [[ "$trimmed" == "$COMPLETE_MARKER" ]]; then
        has_complete_marker=true
        break
      fi
    done <<< "$result"

    if [[ "$has_complete_marker" == true ]] && [[ "$result" != *"was not emitted"* ]] && [[ "$result" != *"did not emit"* ]]; then
      echo ""
      echo "PRD complete after $i iteration(s). Exiting."
      # Optional: tt notify "Ralph PRD complete after $i iterations" 2>/dev/null || true
      exit 0
    fi

    [[ $i -lt $iterations ]] && echo ""
  done

  echo ""
  echo "Reached iteration limit ($iterations). Run again to continue."
  exit 0
}

main "$@"
