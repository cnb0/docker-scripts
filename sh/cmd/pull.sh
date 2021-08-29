cmd_pull_help() {
    cat <<_EOF
    pull <app> [<branch>]
        Clone or pull '$REPO/<app>'
        to '$APPS/<app>'. A certain branch can be specified
        as well. When a branch is given, then it is saved to
        '$APPS/<app>-<branch>'

_EOF
}

cmd_pull() {
    # get the name of the app and the branch
    local app=$1
    [[ -n $app ]] || fail "Usage:\n$(cmd_pull_help)"
    local branch=$2

    local app_dir="$APPS/$app"
    [[ -n $branch ]] && app_dir+="-$branch"
    if [[ -d $app_dir ]]; then
        cd $app_dir
        git pull
    else
        local repo_url="$REPO/$app"
        local branch_option=''
        [[ -n $branch ]] && branch_option="-b $branch"
        git clone $branch_option $repo_url $app_dir
    fi
}
