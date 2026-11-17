#!/usr/bin/env bash
#
# lock-demo.sh: show Terraform's state locking in action.
#
# Two `terraform apply` processes run at the same time against the same
# saved plan and the same state file. The first to start takes the lock
# (.terraform.tfstate.lock.info). The second should fail with
# "Error acquiring the state lock".
#
# Usage:
#   ./lock-demo.sh               # second apply fails immediately on the lock
#   LOCK_TIMEOUT=60s ./lock-demo.sh
#                                # second apply waits for the lock instead,
#                                # then fails because the saved plan is stale

set -uo pipefail

cd "$(dirname "$0")"

PLAN_FILE="tfplan-lock-demo"
LOCK_FILE=".terraform.tfstate.lock.info"
LOG_DIR="lock-demo-logs"
LOCK_TIMEOUT="${LOCK_TIMEOUT:-0s}"

mkdir -p "$LOG_DIR"
rm -f "$LOG_DIR"/*.log

log() { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*"; }

# ---------------------------------------------------------------------------
# 1. Make a plan that actually changes something.
#    A no-op apply finishes too fast for the two applies to overlap, so if
#    nothing has changed, force-replace the random_pet: its new name changes
#    the instance tags, which keeps the apply busy for a few seconds.
# ---------------------------------------------------------------------------
log "Creating plan -> $PLAN_FILE"
terraform plan -input=false -no-color -detailed-exitcode -out="$PLAN_FILE" \
  > "$LOG_DIR/plan.log" 2>&1
rc=$?

if [[ $rc -eq 1 ]]; then
  log "Plan failed, see $LOG_DIR/plan.log"
  tail -20 "$LOG_DIR/plan.log"
  exit 1
elif [[ $rc -eq 0 ]]; then
  log "No changes pending, forcing replace of random_pet.instance"
  terraform plan -input=false -no-color -out="$PLAN_FILE" \
    -replace=random_pet.instance > "$LOG_DIR/plan.log" 2>&1 || {
      log "Plan failed, see $LOG_DIR/plan.log"; exit 1; }
fi
grep -E '^Plan:' "$LOG_DIR/plan.log" | sed 's/^/          /'

# ---------------------------------------------------------------------------
# 2. Run two applies in parallel (background processes; bash has no threads).
# ---------------------------------------------------------------------------
run_apply() {
  local name=$1
  log "$name: starting apply"
  terraform apply -input=false -no-color -lock-timeout="$LOCK_TIMEOUT" \
    "$PLAN_FILE" > "$LOG_DIR/$name.log" 2>&1
  local code=$?
  log "$name: finished with exit code $code"
  return $code
}

log "Launching two applies in parallel (lock-timeout=$LOCK_TIMEOUT)"
run_apply worker-A & pid_a=$!
run_apply worker-B & pid_b=$!

# ---------------------------------------------------------------------------
# 3. While they run, watch for the lock file and show who holds it.
# ---------------------------------------------------------------------------
seen_lock=false
while kill -0 "$pid_a" 2>/dev/null || kill -0 "$pid_b" 2>/dev/null; do
  if [[ -f "$LOCK_FILE" && $seen_lock == false ]]; then
    seen_lock=true
    log "Lock file appeared: $LOCK_FILE"
    sed 's/^/          /' "$LOCK_FILE"
    echo
  fi
  sleep 0.2
done

wait "$pid_a"; code_a=$?
wait "$pid_b"; code_b=$?

# ---------------------------------------------------------------------------
# 4. Report.
# ---------------------------------------------------------------------------
echo
log "================ RESULTS ================"
for w in worker-A worker-B; do
  echo "--- $w ($LOG_DIR/$w.log) ---"
  grep -E 'Apply complete|Error|Lock Info|ID:|Path:|Operation:|Who:|stale' \
    "$LOG_DIR/$w.log" | sed 's/^/  /'
done
echo
log "worker-A exit=$code_a, worker-B exit=$code_b"
if [[ -f "$LOCK_FILE" ]]; then
  log "Lock file still exists (a crashed run?). Remove with: terraform force-unlock <ID>"
else
  log "Lock file is gone: the lock was released after the apply finished."
fi
