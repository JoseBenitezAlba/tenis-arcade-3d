#!/usr/bin/env bash
# Run from the Godot project directory after applying all three patches.
# Logs and artifacts are technical evidence, not a naturalness verdict.
set -eu
GODOT=${GODOT:-godot}
LOG_DIR=${LOG_DIR:-/tmp/tennis-v99-regressions}
mkdir -p "$LOG_DIR"
run() {
  test_name=$1
  shift
  log="$LOG_DIR/$test_name.log"
  echo "Running $test_name"
  if ! timeout 240 "$GODOT" --headless --path . --script "tests/$test_name.gd" "$@" > "$log" 2>&1; then
    cat "$log"
    exit 1
  fi
  if grep -E 'SCRIPT ERROR|Assertion failed|FAIL ' "$log"; then
    cat "$log"
    exit 1
  fi
  tail -n 8 "$log"
}
run point_release_regression
run gait_transition_regression
run arrival_turn_regression
run contact_arrival_body_regression
run contact_long_metrics -- seconds=240
run head_racket_clearance -- seconds=240
run twohand_recovery_metrics
run feet_planted_metrics
run contact_registered_chain_test
run serve_registered_metrics
run serve_rules_regression
run visual_replay_test
run overhead_readiness_regression
run preparation_side_regression
printf 'Finished. Read all logs, known preparation residual and exit-resource warnings in continuity note.\n'
