#!/bin/bash

set -euo pipefail

# If glob doesn't match anything, return empty string rather than literal pattern
shopt -s nullglob

# Print all commands executed if DEBUG mode enabled
[ -n "${DEBUG:-""}" ] && set -x

# We execute instead of sourcing the script so that we have the flexibility to
# use a different interpreter (e.g. Ruby, Python) rather than force the use of bash.
for script in /entrypoint.d/*; do
  if [ -x "$script" ]; then
    "$script" "$@"
  else [[ "$script" = *.bash ]]; then
    # Otherwise, attempt to source the script.
    # Sourcing scripts allows them to set environment variables and do other
    # dangerous things, so use them sparingly.
    source "$script"
  fi
done

# Always run command under dumb-init so signals are forwarded correctly
exec /usr/local/bin/dumb-init "$@"
