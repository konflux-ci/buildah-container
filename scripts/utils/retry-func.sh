#!/bin/bash
# Retry a command accessing registry a few times if it fails

retry() {
  local status
  local interval=1
  local retry=0
  local -r factor=2
  local -r max_retries=10
  while true; do
    echo "Executing:" "${@}" >&2
    "$@" 2> /tmp/errors.txt && break
    status=$?
    cat /tmp/errors.txt
    ((retry += 1))
    if [ $retry -gt $max_retries ]; then
      echo "error: Command failed after ${max_retries} tries with status ${status}" >&2
      return $status
    fi
    echo "warning: Command failed and will retry, ${retry} try" >&2

    unauthorized_error=$(grep -ci "unauthorized" /tmp/errors.txt)
    if [ "$unauthorized_error" -ne 0 ]; then
      echo "error: Unauthorized error, wrong registry credentials provided, won't retry" >&2
      return 1
    fi

    ((interval = interval * factor))
    sleep "$interval"
  done
}

retry "$@"
