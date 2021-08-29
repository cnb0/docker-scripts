#!/bin/bash -i
#
# Usage: [DELAY=<secs>] play <bash-script> [<args>]
#
# Run the script and stop on comments that start with '##*' and on
# commands that start with ':*;*'. Highlight these commands and
# comments, as well as comments that start with '#*' or ':*'.
#
# The given <bash-script> has to set 'set -o verbose' on top of it.
#
# If it is called with a delay, like this:
#     DELAY=0.7 play bash-script.sh
# Then it will sleep that amount of time, instead of waiting for
# [Enter] to continue, and then continue automatically.

hl() {
    echo "$1" | highlight -S bash -O xterm256
}

hl_wait() {
    echo -n $(hl "$1")
    [[ -z $DELAY ]] && read </dev/tty || { sleep $DELAY; echo; }
}

#PS1='\033[01;34m\w\033[00m$ '

hl_cmd() {
    echo -n "${PS1@P}"
    local cmd=$(echo "$1" | cut -d';' -f3)
    echo $(hl "$(echo $cmd)")
}

hl_cmd_wait() {
    echo -n "${PS1@P}"
    local cmd=$(echo "$1" | cut -d';' -f2)
    hl_wait "$(echo $cmd)"
}

[[ -z $DELAY ]] && echo -e "\n========== Press [Enter] to continue ==========\n" | egrep --color '.*'

unbuffer bash -i "$@" 2>&1 |\
    while IFS='^$&' read line; do
        case $line in
            [#][#]*)      hl_wait "$line"     ;;
            [:]\;[:]\;*)  hl_cmd "$line"      ;;
            [:]*\;*)      hl_cmd_wait "$line" ;;
            [:]*|[#]*)    hl "$line"          ;;
            *)            echo "$line"        ;;
        esac
    done

[[ -z $DELAY ]] && echo -e "\n========== PLAY: $@ : DONE ==========\n" | egrep --color '.*'
