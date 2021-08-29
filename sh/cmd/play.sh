cmd_play_help() {
    cat <<_EOF
    play [--delay <secs>] <script> [<args>]

        Run the script and stop on comments that start with '##*' and
        on commands that start with ':*;*'. Highlight these commands
        and comments, as well as comments that start with '#*' or ':*'

        The given <script> has to set 'set -o verbose' on top of it.

        If it is called with a delay, then it will sleep that amount
        of time, instead of waiting for [Enter] to continue, and then
        continue automatically.

_EOF
}

cmd_play() {
    if [[ $1 == '--delay' ]]; then
        local delay=$2
        local script=$3
        shift 3
        exec env DELAY=$delay playscript $APP_DIR/$script "$@"
    else
        local script=$1
        shift
        exec playscript $APP_DIR/$script "$@"
    fi
}
