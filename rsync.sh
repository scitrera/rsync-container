#!/bin/bash

# Allow multiple return codes for rsync if specified...
IFS=',' read -r -a allowed_codes <<< "$ALLOWED_RETURN_CODES"

run_rsync() {
  local args=()
  local paths=()

  for arg in "$@"; do
    if [[ "$arg" == -* ]]; then
      args+=("$arg")  # Add options like -avz, --delete, etc.
    else
      paths+=("$arg")  # Add paths where globbing is allowed
    fi
  done

  #  echo rsync "$@"
  set -x
  eval "rsync ${args[*]} ${paths[*]}"
  local rsync_return_code=$?
  set +x

  # Check if the exit code exists in the allowed list
  for code in "${allowed_codes[@]}"; do
      if [[ $rsync_return_code -eq $code ]]; then
          return 0
      fi
  done

  # If the exit code is not in the list, exit with the actual exit code
  return $rsync_return_code
}

# if there is no recurring watch set, then we just run normal rsync (with exit code manipulation)
if [ -z "$RECURRING_WATCH" ]; then
  run_rsync "$@"
  exit $?
fi

# support multiple files/paths for recurring watch
IFS=':' read -r -a recurring_watch_paths <<< "$RECURRING_WATCH"

# keep variable for whether termination was requested
TERM_CALL="0"

if [ -z "$INOTIFY_EVENTS" ]; then
  INOTIFY_EVENTS="modify,create,delete,move"
fi

handle_term_call() {
  echo "Received SIGINT/SIGTERM Signal"
  TERM_CALL="1"
}

reconf_traps() {
  # function to configure traps; probably doesn't need to be function but for historical reasons, it is...
  trap handle_term_call SIGINT
  trap handle_term_call SIGTERM
}

reconf_traps

# while we didn't receive a termination signal...
while [ "$TERM_CALL" != "1" ]; do
    if [ "$INOTIFY_EVENTS" != "-" ]; then
      # wait for change(s) in the files/directory (create, delete, modify, move)
      inotifywait -r -e "$INOTIFY_EVENTS" "${recurring_watch_paths[@]}"
    fi

    # run rsync on changes
    run_rsync "$@"

    ret_code=$?
    if [ "$TERM_CALL" == "1" ]; then
      exit $ret_code
    elif [ -n "$SLEEP_DELAY" ]; then
      sleep "$SLEEP_DELAY"
    fi
done
