# keyCD

keyCD lets you jump to a directory in Bash without typing its full path. Run keyCD by typing `c` followed by a shortcut name, such as `c docs`. You can also use `c` like `cd` with an ordinary directory path.

```text
$ cd ~/Documents
$ c -a docs # Add the docs shortcut
$ cd ~
$ c docs
$ pwd
/home/alex/Documents
```

## Table of contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [File locations](#file-locations)
- [Updating](#updating)
- [Uninstallation](#uninstallation)

## Features

- Add, remove and list named directory shortcuts.
- Complete shortcut names, options and directory paths with Tab.
- Highlight missing directories when listing shortcuts.
- Shortcuts are stored in a plain-text database.
- Keep your existing database when reinstalling or updating.

## Requirements

- Bash 4 or newer.
- Standard Linux utilities from GNU Coreutils, plus `grep`. These are normally already installed.
- Git, if you choose to clone and update the repository with Git.

The current version of keyCD only supports the Bash shell.

## Installation

### 1. Download and install keyCD

Open a terminal and run these commands, one line at a time:

```bash
git clone https://github.com/terminallyblunt/keycd.git
cd keycd
bash install.sh
```

These commands download keyCD into a new `keycd` folder inside your current directory, enter that folder, and run the installer.

Run them as your normal user, without `sudo`.

The installer copies the main script and Bash completion file into `~/.local/share/keycd/`.

The installer does not modify `~/.bashrc`.

### 2. Configure Bash

Open `~/.bashrc` in your preferred text editor. This is a hidden file in your home folder; most graphical file managers let you show hidden files with Ctrl+H.

Add the following lines to the end of your `~/.bashrc` file, then save it. You only need to add them once:

```bash
# keyCD: directory shortcuts with cd-style path fallback
c() { source "$HOME/.local/share/keycd/keycd.sh" "$@"; }

# keyCD Bash completion
source "$HOME/.local/share/keycd/_keycd_completion.bash"
```

If you already use an alias or function named `c`, remove or rename that existing definition before adding these lines.

The `c` function sources keyCD into your current shell so it can change that shell's directory. Running `bash keycd.sh` will not change your terminal's working directory.

### 3. Open a new terminal

Check that keyCD is available:

```bash
c --help
c -l
```

The first time you run `c`, keyCD creates an empty database for your shortcuts if one doesn’t already exist. If you already have saved shortcuts, keyCD keeps them.

On a new installation, `c -l` displays only the column headings until you add your own shortcuts.

Once you’ve confirmed keyCD is working, you can delete the `keycd` folder that `git clone` created. The installer has already copied the files keyCD needs into `~/.local/share/keycd/`.

## Usage

| Command | Action |
| --- | --- |
| `c <shortcut-name>` | Jump to a saved directory |
| `c <path>` | Change to an ordinary directory path |
| `c` | Return to your home directory |
| `c -a <shortcut-name>` | Save the current directory under a shortcut name |
| `c -a` | Prompt for a shortcut name and save the current directory |
| `c -r <shortcut-name>` | Remove the shortcut with that name |
| `c -r` | Remove the shortcut for the current directory |
| `c -l` | List shortcuts and flag missing directories |
| `c -h` | Show help |

Long options are also available: `--add`, `--remove`, `--list` and `--help`.

### Add and use a shortcut

```bash
cd ~/Documents
c -a docs

cd /tmp
c docs
```

In keyCD, a **key** is the name you give a shortcut, such as `docs` in `c docs`.

Shortcut names may contain letters, numbers, underscores and hyphens. Shortcut names are case-sensitive. Each shortcut name and each directory path must be unique.

For ordinary directory paths, you can use `c /etc` or `c ../`.

Shortcut names take priority over ordinary paths. To explicitly select a relative directory whose name matches a shortcut name, use `c ./directory-name`.

### Tab completion

**You don't need to type the full shortcut name.** Tab completion makes jumping to saved directories even quicker and soon becomes part of your everyday workflow.

For example, if you saved a directory as `mango`:

1. Type `c man` without pressing Enter.
2. Press **Tab** to complete it to `c mango`, provided it is the only matching suggestion.
3. Press **Enter** to jump to the saved directory.

Once you get used to it, navigating becomes a quick routine: **`c`, a few letters, Tab, Enter.** You can give shortcuts meaningful, descriptive names without having to type them in full every time.

If several shortcut names or directories match, type a few more letters to narrow the suggestions, or press **Tab twice** to see the available matches with the usual Bash settings.

Tab completion also works with command options and ordinary directory paths, including names containing spaces. You can complete a directory, type the first few letters of a directory inside it, and press **Tab** again to continue navigating through the path.

### Remove a shortcut

```bash
c -r docs
```

This removes the database entry only. It does not delete the directory or its contents. Removal does not ask for confirmation.

## File locations

| Location | Purpose |
| --- | --- |
| `~/.local/share/keycd/keycd.sh` | Installed main script |
| `~/.local/share/keycd/_keycd_completion.bash` | Installed Bash completion |
| `~/.config/keycd/keycd_db.txt` | Your personal shortcuts |

These paths are currently fixed under your home directory.

Your personal database is created automatically on first use. No default database is included in the repository.

### Database format

Each entry contains a shortcut name and an absolute directory path separated by `|`:

```text
docs|/home/alex/Documents
projects|/home/alex/src
```

Blank lines and lines beginning with `#` are ignored when loading the database. Paths containing `|` or newline characters are not supported.

When you add or remove a shortcut, keyCD sorts the entries by shortcut name and rewrites the database. Comments and blank lines are not retained during that rewrite.

Back up your personal database if you want to preserve or transfer your shortcuts.

## Updating

Update the repository files, then rerun:

```bash
bash install.sh
```

If you installed from a Git clone, pull the changes before running the installer.

The installer replaces the installed main script and completion file while preserving your database. You do not need to add the lines in `.bashrc` again.

Open a new terminal after updating so the latest completion code is loaded.

## Uninstallation

1. Remove the keyCD lines you added to `~/.bashrc`.
2. Remove the installed shell files:

```bash
rm -r -- "$HOME/.local/share/keycd"
```

3. Open a new terminal.

Your personal database remains in `~/.config/keycd/`. Keep it as a backup, or delete it separately if you no longer want your saved shortcuts:

```bash
rm -r -- "$HOME/.config/keycd"
```

Removing the source repository is optional and separate from uninstalling the working files.

