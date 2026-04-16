#!/bin/bash
set -eu
# This does not work with a symlink to this script
# SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# See https://stackoverflow.com/a/246128/24637657
SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  SCRIPT_DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "$SOURCE")
  # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  [[ $SOURCE != /* ]] && SOURCE=$SCRIPT_DIR/$SOURCE
done
SCRIPT_DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )

export CONTAINER_RUNTIME=${CONTAINER_RUNTIME:-podman}

if [[ $# -gt 0 ]]; then
  if [[ "$1" == "podman" || "$1" == "docker" ]]; then
    export CONTAINER_RUNTIME=$1
  else
    echo "$(warn) Container runtime passed in as an argument is not valid, defaulting to podman..."
    export CONTAINER_RUNTIME=podman
  fi
fi


"$CONTAINER_RUNTIME" run --rm -it --network "${NET_NAME:-os-net}" \
    -v "$SCRIPT_DIR/support/fluent-bit.yaml":/fluent-bit/etc/fluent-bit.yaml \
    ghcr.io/fluent/fluent-bit:4.2.3 -c /fluent-bit/etc/fluent-bit.yaml
