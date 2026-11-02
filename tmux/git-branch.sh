#!/bin/bash
# Prints the git-branch pill of the tmux status bar for the folder in $1
# (nothing outside a repository). Called from theme.conf.
branch=$(git -C "$1" branch --show-current 2>/dev/null)
[ -n "$branch" ] || branch=$(git -C "$1" rev-parse --short HEAD 2>/dev/null)
[ -n "$branch" ] || exit 0
pill=${2:-#2a1f1b} text=${3:-#b5b07a}  # colours come from the tmux theme
printf ' #[fg=%s bg=default]#[fg=%s bg=%s] %s#[fg=%s bg=default]' "$pill" "$text" "$pill" "$branch" "$pill"
