# Prompt: a framed input line in the Obsidian colours (palette/README.md).
#
#   ╭─  c-practice/stage-1   main ●  ─────────────────── 3.2s · 23:46
#   ╰─› make clean
#
# After Enter the frame folds into one line (transient prompt):
#   ● make clean
# and a command that failed or ran long leaves a quiet note under its output:
#     ✗ exit 1 · 4.2s
#
# Replaces Tide's prompt (Tide stays installed). To go back to Tide: delete
# this file and open a new shell.

set -g fish_transient_prompt 1

function _prompt_git
    set -l branch (command git symbolic-ref --short HEAD 2>/dev/null)
    or set branch (command git rev-parse --short HEAD 2>/dev/null)
    or return
    set_color 134b40
    printf '   %s' $branch
    if not command git diff --quiet HEAD 2>/dev/null
        set_color b4541b
        printf ' ●'
    end
end

function fish_prompt
    set -l last $status
    set -l frame 7daea3

    # after Enter: one line, an ember dot in front of the command
    if contains -- --final-rendering $argv
        set_color b4541b
        printf '● '
        set_color normal
        return
    end

    # top line: folder (parent dim, current navy) · git · ──── · duration · time
    set -l dir (prompt_pwd --full-length-dirs 2)
    set -l parent (string replace -r '[^/]*$' '' -- $dir)
    set -l here (string match -r '[^/]*$' -- $dir)
    # "$(…)": an empty result (no git here) must not empty the whole string
    set -l left "$(set_color $frame)╭─ $(set_color 1f6b5c) $(set_color 8f8276)$parent$(set_color --bold 1e3a5f)$here$(set_color normal)$(_prompt_git) "
    set -l right ' '
    if test "$CMD_DURATION" -ge 1000 2>/dev/null
        set right "$right"(set_color 8f8276)(math -s1 $CMD_DURATION / 1000)'s'(set_color c9b99c)' · '
    end
    set right "$right"(set_color 8f8276)(date +%H:%M)(set_color normal)
    set -l fill (math $COLUMNS - (string length --visible -- $left) - (string length --visible -- $right))
    echo
    printf '%s%s%s%s\n' $left (set_color $frame) (string repeat -n (math max 1, $fill) ─) $right

    # input line: › in insert mode (rust after an error), ‹ in normal mode
    set_color $frame
    printf '╰─'
    switch "$fish_bind_mode"
        case default visual
            set_color --bold 1f6b5c
            printf '‹ '
        case '*'
            test $last -eq 0; and set_color --bold b4541b; or set_color --bold b0381a
            printf '› '
    end
    set_color normal
end

# the mode is shown by › / ‹ above; Tide's right prompt is not used
function fish_mode_prompt
end
function fish_right_prompt
end

# a failed or slow (≥ 3 s) command leaves one quiet line under its output
function _prompt_after --on-event fish_postexec
    set -l last $status
    set -l slow (test "$CMD_DURATION" -ge 3000 2>/dev/null; and echo 1)
    if test $last -ne 0
        set_color b0381a
        printf '  ✗ exit %s' $last
        test -n "$slow"; and printf (set_color 8f8276)' · %ss' (math -s1 $CMD_DURATION / 1000)
        set_color normal
        echo
    else if test -n "$slow"
        set_color 5d6a1c
        printf '  ✓ '
        set_color 8f8276
        printf '%ss\n' (math -s1 $CMD_DURATION / 1000)
        set_color normal
    end
end
