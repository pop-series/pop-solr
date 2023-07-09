#!/bin/bash

log() {
  MSG=$1
  echo "["$(date)"]" "$MSG"
}
export -f log

set_env_var_if_missing() {
  KEY=$1
  VALUE=$2

  if [[ -z "${!KEY}" ]]; then
    export "$KEY"="$VALUE"
  fi
  log "using $KEY: ${!KEY}"
}
export -f set_env_var_if_missing
