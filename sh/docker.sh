#!/bin/bash

cmd_version() {
    echo "DockerScripts:$VERSION https://gitlab.com/docker-scripts/ds"
}

cmd_start() {
    docker start $CONTAINER
}

cmd_stop() {
    docker stop $CONTAINER 2>/dev/null
}

cmd_restart() {
    docker restart $CONTAINER
}

cmd_shell() {
    cmd_exec bash
}

cmd_exec() {
    is_up || (cmd_start && sleep 2)
    docker exec -u root -it $CONTAINER env TERM=xterm "$@"
}

cmd_remove() {
    is_up && cmd_stop && sleep 2
    [[ -n $NETWORK ]] && docker network disconnect $NETWORK $CONTAINER 2>/dev/null
    docker rm $CONTAINER 2>/dev/null
    docker rmi $IMAGE 2>/dev/null
}

cmd_make() {
    ds build
    ds create
    ds config
}

# When the command is 'cd', go to the directory of the given container.
# It must be called by sourcing, like this: `. ds cd @container`
cmd_cd() {
    DSDIR=${DSDIR:-$HOME/.ds}
    local config_file="$DSDIR/config.sh"
    local containers=$(cat $config_file | grep CONTAINERS= | sed -e "s/CONTAINERS=//" | tr -d "'"'"'' ')
    local arg1=$1
    cd $containers/${arg1:1}
}

call() {
    local cmd=$1; shift

    # load the installation command file
    [[ -f "$LIBDIR/${cmd//_//}.sh" ]] && source "$LIBDIR/${cmd//_//}.sh"

    # load the environment command file
    [[ -f "$DSDIR/${cmd//_//}.sh" ]] && source "$DSDIR/${cmd//_//}.sh"

    # load the application command file
    [[ -f "$APP_DIR/${cmd//_//}.sh" ]] && source "$APP_DIR/${cmd//_//}.sh"

    # load the container command file
    [[ -f "${cmd//_//}.sh" ]] && source "${cmd//_//}.sh"

    # run the command
    is_function $cmd || fail "Cannot find command '$cmd'"
    CMD=${cmd#*_}
    COMMAND="$PROGRAM ${CMD//_/ }"
    $cmd "$@"
}

load_ds_config() {
    # read the config file
    DSDIR=${DSDIR:-$HOME/.ds}
    local config_file="$DSDIR/config.sh"
    if [[ ! -f "$config_file" ]]; then
        mkdir -p "$(dirname "$config_file")"
        cat <<-_EOF > "$config_file"
REPO='https://gitlab.com/docker-scripts'
APPS='/opt/docker-scripts'
CONTAINERS='/var/ds'
NETWORK='dsnet'
#SUBNET='172.27.0.0/16'
_EOF
    fi
    unset REPO APPS CONTAINERS NETWORK
    source "$config_file"
    REPO=${REPO:-https://gitlab.com/docker-scripts}
    APPS=${APPS:-/opt/docker-scripts}
    CONTAINERS=${CONTAINERS:-/var/ds}
    NETWORK=${NETWORK:-dsnet}
    mkdir -p $APPS $CONTAINERS
}

ds_info() {
    cat <<-_EOF

$(cmd_version)

DSDIR='$DSDIR'

--> ls $DSDIR :
$(ls $DSDIR)

--> cat $DSDIR/config.sh :
$(cat $DSDIR/config.sh)

--> ls $APPS:
$(ls $APPS)

--> ls $CONTAINERS:
$(ls $CONTAINERS)

For help about commands try: ds -h

_EOF
}

cd_to_container_dir() {
    local arg1=$1
    local dir="${arg1:1}"
    [[ "${dir:0:2}" == './' || "${dir:0:1}" == '/' ]] || dir="$CONTAINERS/$dir"
    [[ -d "$dir" ]] || fail "Container directory '$arg1' does not exist."
    cd "$dir"
}

load_container_settings() {
    [[ -f settings.sh ]] \
        || fail "No file ./settings.sh found."

    # load the settings file
    source ./settings.sh

    [[ -n $APP ]] \
        || fail "No APP defined on ./settings.sh"

    APP_DIR="$APPS/$APP"
    [[ -d $APP_DIR ]] || APP_DIR="$APP"
    [[ -d $APP_DIR ]] \
        || fail "Cannot find the directory of '$APP'."

    [[ -n $CONTAINER ]] \
        || fail "No CONTAINER defined on ./settings.sh"
}

main() {
    set -o pipefail
    VERSION="1.0"
    LIBDIR="$(dirname "$0")"
    PROGRAM="${0##*/}"
    source "$LIBDIR/auxiliary.sh"

    # check the docker version
    if [[ "$1" != 'run' ]]; then
        local version=$(docker --version | cut -d, -f1 | cut -d' ' -f3 | cut -d. -f1)
        [[ "$version" -lt 17 ]] && fail "These scripts are supposed to work with docker 17+"
    fi

    # if the command is 'cd', go to the directory of the given container
    # it must be called by sourcing, like this: `. ds cd @container`
    if [[ "$1" == 'cd' ]]; then
        local container=$2
        cmd_cd $container
        return
    fi

    # load ~/.ds/config.sh
    load_ds_config

    # handle some basic options and commands
    local arg1=$1 ; shift
    case $arg1 in
        '')            ds_info ;              return ;;
        -v|--version)  cmd_version "$@" ;     return ;;
        -h|--help)     call cmd_help "$@" ;   return ;;
        pull|init|runtest|test)
            call cmd_$arg1 "$@"
            return
            ;;
        -x) exec bash -x ds "$@"
            ;;
        @*) cd_to_container_dir $arg1
            exec bash ds "$@"
            ;;
    esac

    # load container settings.sh
    load_container_settings

    # The file 'ds.sh' can be used to redefine
    # and customize some functions, without having to
    # touch the code of the main script.
    [[ -f "$DSDIR/ds.sh" ]] && source "$DSDIR/ds.sh"
    [[ -f "$APP_DIR/ds.sh" ]] && source "$APP_DIR/ds.sh"
    [[ -f ds.sh ]] && source ds.sh

    # run the given command
    local command=$arg1
    case $command in
        make|start|stop|restart|shell|exec|remove)
            cmd_$command "$@"
            ;;
        config)
            is_up || cmd_start && sleep 2
            log call cmd_$command "$@"
            cmd_restart && sleep 2
            ;;
        *)
            call cmd_$command "$@"
            ;;
    esac
}

main "$@"
