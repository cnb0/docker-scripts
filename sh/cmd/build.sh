cmd_build_help() {
    cat <<_EOF
    build
        Build the docker image.

_EOF
}

cmd_build() {
    # copy docker files to a tmp dir
    # and preprocess Dockerfile
    local tmp=$(mktemp -u)
    cp -aT $APP_DIR $tmp
    m4 -I $APP_DIR -I "$LIBDIR/dockerfiles" \
       $APP_DIR/Dockerfile > $tmp/Dockerfile

    # build the image
    log docker build "$@" --tag=$IMAGE $tmp/

    # clean up
    rm -rf $tmp/
}
