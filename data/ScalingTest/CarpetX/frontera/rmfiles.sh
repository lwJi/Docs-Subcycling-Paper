#!/bin/bash

# Execute and print the command
execute_command() {
    echo "\$ $@"
    "$@"
}
export -f execute_command

for dir in */ ; do
  echo "Processing directory: $dir"
  (cd $dir
    rm TimerReport*
    rm AllTimers*
    rm TwoPuncturesX.bbh
  )
done
