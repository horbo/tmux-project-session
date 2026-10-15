# tmux-project-session

Fuzzy-pick a tmux session or a project directory from a popup. Picking a running
session switches to it; picking a project creates a session in that directory and
switches to it.

```
session>
  ● dotfiles  ~/dotfiles
  ● api  work/api
    work/web  ~/Projects
    tmux-project-session  ~/Code
```

## Features

- Running sessions and projects in one list, sessions first (marked with `●`).
- Projects are discovered under one or more root directories. A directory counts
  as a project when it contains `.git`, or when the search reaches the maximum depth.
- A project that already has a session pointing at it is hidden from the project
  list, so you switch instead of creating a duplicate.
- Preview pane with the current git branch and the top-level directory listing.
- Typing a name that matches nothing and pressing `enter` creates a new session in `$HOME`.

## Requirements

- tmux 3.2 or newer (for `display-popup`)
- [fzf](https://github.com/junegunn/fzf)
- bash
- optional: `tree` for the preview (falls back to `ls`)

## Installation

### With [TPM](https://github.com/tmux-plugins/tpm)

```tmux
set -g @plugin 'horbo/tmux-project-session'
```

Press `prefix` + `I` to install.

### Manually

```sh
git clone https://github.com/horbo/tmux-project-session ~/.config/tmux/plugins/tmux-project-session
```

```tmux
run-shell ~/.config/tmux/plugins/tmux-project-session/project-session.tmux
```

## Usage

`prefix` + `C-n` opens the popup.

| Key      | Action                                                         |
|----------|----------------------------------------------------------------|
| `enter`  | Switch to the session, or create a session for the project     |
| `ctrl-n` | Always create a new session, even when a session was selected   |
| `esc`    | Close                                                           |

Session names are taken from the project directory name. `.` and `:` are replaced
with `_`, and a `-2`, `-3`, … suffix is added when the name is taken.

## Configuration

```tmux
set -g @project-session-roots '~/Projects:~/IdeaProjects'
set -g @project-session-key 'C-n'
set -g @project-session-max-depth '3'
set -g @project-session-width '80%'
set -g @project-session-height '70%'
set -g @project-session-title 'Sessions'
```

| Option                       | Default      | Description                                                    |
|------------------------------|--------------|----------------------------------------------------------------|
| `@project-session-roots`     | `~/Projects` | Colon-separated list of directories to search for projects     |
| `@project-session-key`       | `C-n`        | Key bound under the prefix table                                |
| `@project-session-max-depth` | `3`          | How many levels below a root to descend when no `.git` is found |
| `@project-session-width`     | `80%`        | Popup width                                                     |
| `@project-session-height`    | `70%`        | Popup height                                                    |
| `@project-session-title`     | `Sessions`   | Popup title                                                     |

Set options before the TPM `run` line.

[tmux-sensible](https://github.com/tmux-plugins/tmux-sensible) binds `prefix` + `C-n`
to `next-window` when that key is free. List this plugin before tmux-sensible, or pick
a different `@project-session-key`.

## License

[MIT](LICENSE)
