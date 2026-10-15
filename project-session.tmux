#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

get_option() {
  local value
  value="$(tmux show-option -gqv "$1")"
  echo "${value:-$2}"
}

key="$(get_option "@project-session-key" "C-n")"
width="$(get_option "@project-session-width" "80%")"
height="$(get_option "@project-session-height" "70%")"
title="$(get_option "@project-session-title" "Sessions")"

tmux bind-key "$key" display-popup -T "$title" -w "$width" -h "$height" -E "'$CURRENT_DIR/scripts/project-session.sh'"
