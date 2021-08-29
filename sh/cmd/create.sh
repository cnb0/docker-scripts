cmd_create_help() {
    cat <<_EOF
    create
        Create the docker container.

_EOF
}

cmd_create() {
    local nosystemd='false'
    if [[ $1 == 'nosystemd' ]]; then
        nosystemd='true'
        shift
    fi

    # create a ds network if it does not yet exist
    local subnet=''
    [[ -n $SUBNET ]] && subnet="--subnet $SUBNET"
    docker network create $subnet $NETWORK 2>/dev/null

    # remove the container if it exists
    cmd_stop
    docker network disconnect $NETWORK $CONTAINER 2>/dev/null
    docker rm $CONTAINER 2>/dev/null

    # create a new container
    docker create --name=$CONTAINER --hostname=$CONTAINER \
        --restart=unless-stopped \
        --mount type=bind,source=$(pwd),destination=/host \
        $(_systemd_config $nosystemd) \
        $(_published_ports) \
        $(_network_and_aliases) \
        "$@" $IMAGE

    # add DOMAIN to wsproxy
    if [[ -n $DOMAIN ]]; then
        ds wsproxy add
        ds wsproxy ssl-cert
    fi
}

### Configure the host for running systemd containers.
### See: https://github.com/solita/docker-systemd/blob/master/setup
_systemd_config() {
    local nosystemd=$1
    [[ $nosystemd == 'true' ]] && echo '' && return

    # configure the host for running systemd containers
    if nsenter --mount=/proc/1/ns/mnt -- mount | grep /sys/fs/cgroup/systemd >/dev/null 2>&1; then
        : # do nothing
    else
        [[ ! -d /sys/fs/cgroup/systemd ]] && mkdir -p /sys/fs/cgroup/systemd
        nsenter --mount=/proc/1/ns/mnt -- mount -t cgroup cgroup -o none,name=systemd /sys/fs/cgroup/systemd
    fi

    local systemd_options=''
    systemd_options+=' --mount type=tmpfs,destination=/run'
    systemd_options+=' --mount type=tmpfs,destination=/run/lock'
    systemd_options+=' --mount type=bind,src=/sys/fs/cgroup,dst=/sys/fs/cgroup,readonly'
    echo "$systemd_options"
}

### published ports
_published_ports() {
    [[ -n $PORTS ]] || return

    local ports=''
    for port in $PORTS; do
        ports+=" --publish $port"
    done

    echo "$ports"
}

### network and aliases
_network_and_aliases() {
    [[ -n $NETWORK ]] || return

    local network=" --network $NETWORK"
    network+=" --network-alias $CONTAINER"
    if [[ -n $DOMAIN ]]; then
        for domain in $DOMAIN $DOMAINS; do
            network+=" --network-alias $domain"
        done
    fi

    echo "$network"
}
