#!/usr/bin/env bash
# Ralph Once: Single iteration of the Ralph workflow
# Runs Cursor CLI once to implement one highest-priority PRD feature.
# Use ralph.sh for the full loop.
#
# Environment: Flutter package or app (pubspec.yaml). Android build supported.
# Prerequisites: Cursor CLI (agent) and Flutter SDK in PATH. Run from project root or ralph/.

set -euo pipefail

readonly PRD_FILE="ralph/prd.json"
readonly PROGRESS_FILE="ralph/progress.txt"

# Ensure we run from project root (parent of ralph/)
root="$(cd "$(dirname "$0")/.." && pwd)"
[[ -f "$root/pubspec.yaml" ]] || {
  echo "Error: pubspec.yaml not found in $root - this must be a Flutter project root" >&2
  exit 1
}
cd "$root"

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
<promise>COMPLETE</promise>
Do NOT mention or reference this marker anywhere else in your response (e.g. do not write \"was not emitted\" or similar)."

agent -p "$prompt" --force --trust --workspace "$(pwd)"
