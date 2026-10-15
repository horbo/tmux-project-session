#!/usr/bin/env bash

MARKER="●"
TAB=$'\t'
DIM=$'\e[2m'
RESET=$'\e[0m'

export PATH="${PATH}:/opt/homebrew/bin:/usr/local/bin"

get_option() {
  local value
  value="$(tmux show-option -gqv "$1")"
  echo "${value:-$2}"
}

MAX_DEPTH="$(get_option "@project-session-max-depth" "3")"
case "$MAX_DEPTH" in
  '' | *[!0-9]*) MAX_DEPTH=3 ;;
esac

PROJECTS_ROOTS=()
IFS=':' read -ra raw_roots <<< "$(get_option "@project-session-roots" "$HOME/Projects")"
for root in "${raw_roots[@]}"; do
  [ -n "$root" ] || continue
  case "$root" in
    \~ | \~/*) root="$HOME${root#\~}" ;;
  esac
  PROJECTS_ROOTS+=("${root%/}")
done

list_projects() {
  local dir="$1" rel="$2" depth="$3" sub name subrel has_subdirs
  for sub in "$dir"/*/; do
    [ -d "$sub" ] || continue
    sub="${sub%/}"
    name="${sub##*/}"
    subrel="${rel:+$rel/}$name"
    if [ -e "$sub/.git" ] || [ "$depth" -ge "$MAX_DEPTH" ]; then
      echo "$subrel"
      continue
    fi
    has_subdirs=false
    for d in "$sub"/*/; do
      [ -d "$d" ] && has_subdirs=true && break
    done
    if $has_subdirs; then
      list_projects "$sub" "$subrel" $((depth + 1))
    elif [ "$depth" -gt 1 ]; then
      echo "$subrel"
    fi
  done
}

pretty_path() {
  local root
  for root in "${PROJECTS_ROOTS[@]}"; do
    case "$1" in
      "$root"/*) echo "${1#"$root"/}"; return ;;
    esac
  done
  case "$1" in
    "$HOME"*) echo "~${1#"$HOME"}" ;;
    *) echo "$1" ;;
  esac
}

build_entries() {
  local sessions name path rel root label
  sessions="$(tmux list-sessions -F "#{session_name}${TAB}#{session_path}")"
  while IFS="$TAB" read -r name path; do
    [ -n "$name" ] || continue
    echo "S${TAB}${name}${TAB}${path}${TAB}${MARKER} ${name}  $(pretty_path "$path")"
  done <<< "$sessions"
  for root in "${PROJECTS_ROOTS[@]}"; do
    [ -d "$root" ] || continue
    label="${DIM}$(pretty_path "$root")${RESET}"
    list_projects "$root" "" 1 | while read -r rel; do
      path="$root/$rel"
      printf '%s\n' "$sessions" | cut -f2 | grep -qxF "$path" && continue
      echo "P${TAB}${rel##*/}${TAB}${path}${TAB}  ${rel}  ${label}"
    done
  done
}

unique_name() {
  local base candidate i=2
  base="$(printf '%s' "$1" | tr '.:' '__')"
  candidate="$base"
  while tmux has-session -t "=$candidate" 2>/dev/null; do
    candidate="${base}-${i}"
    i=$((i + 1))
  done
  echo "$candidate"
}

create_and_switch() {
  local name
  name="$(unique_name "$1")"
  tmux new-session -d -s "$name" -c "$2" && tmux switch-client -t "=$name"
}

[ "${BASH_SOURCE[0]}" = "$0" ] || return 0

if ! command -v fzf >/dev/null 2>&1; then
  echo "tmux-project-session: fzf not found in PATH" >&2
  read -rsn1
  exit 1
fi

output="$(build_entries | fzf \
  --delimiter="$TAB" \
  --with-nth=4 \
  --ansi \
  --preview='branch="$(git -C {3} rev-parse --abbrev-ref HEAD 2>/dev/null)"; echo " ${branch:-(not a git repo)}"; echo; if command -v tree >/dev/null; then tree -C -L 1 --dirsfirst --noreport {3} | tail -n +2; else ls -A {3}; fi' \
  --preview-window=right:50% \
  --print-query \
  --expect=ctrl-n \
  --reverse \
  --header="enter: switch/create · ctrl-n: force new session · esc: cancel" \
  --prompt="session> ")"
[ $? -eq 130 ] && exit 0

query="$(sed -n 1p <<< "$output")"
key="$(sed -n 2p <<< "$output")"
selection="$(sed -n 3p <<< "$output")"

if [ -z "$selection" ]; then
  [ -n "$query" ] && create_and_switch "$query" "$HOME"
  exit 0
fi

IFS="$TAB" read -r kind name path _ <<< "$selection"

if [ "$kind" = "S" ] && [ "$key" != "ctrl-n" ]; then
  tmux switch-client -t "=$name"
else
  create_and_switch "$name" "$path"
fi
