#!/bin/bash
set -Eeuo pipefail

DIR_MODS_SYS="/opt/dst_server/mods"
DIR_MODS_USER="${DST_USER_DATA_PATH}/DoNotStarveTogether/Cluster_1/mods"
FILE_CLUSTER_TOKEN="${DST_USER_DATA_PATH}/DoNotStarveTogether/Cluster_1/cluster_token.txt"

on_error() {
    echo >&2 "Error on line ${1}${3+: ${3}}; RET ${2}."
    exit "$2"
}
trap 'on_error ${LINENO} $?' ERR 2>/dev/null || true

if [ "$#" -eq 0 ]; then
    set -- supervisord -c /etc/supervisor/supervisor.conf -n
fi

if [ "$1" = "dontstarve_dedicated_server_nullrenderer" ] || [ "$1" = "supervisord" ]; then
    if [ ! -d "${DST_USER_DATA_PATH}/DoNotStarveTogether" ]; then
        echo "Creating default server config..."
        mkdir -p "${DST_USER_DATA_PATH}"
        cp -r /opt/dst_default_config/* "${DST_USER_DATA_PATH}"
        touch "${FILE_CLUSTER_TOKEN}"
    fi

    if [ -n "${DST_CLUSTER_TOKEN:-}" ]; then
        echo "Filling cluster token from environment variable"
        printf "%s" "${DST_CLUSTER_TOKEN}" > "${FILE_CLUSTER_TOKEN}"
    fi

    if [ ! -f "${FILE_CLUSTER_TOKEN}" ]; then
        echo >&2 "Please fill in \`DoNotStarveTogether/Cluster_1/cluster_token.txt\` with your cluster token and restart server!"
        exit 1
    fi

    if [ -z "$(tail -c 1 "${FILE_CLUSTER_TOKEN}")" ]; then
        mv "${FILE_CLUSTER_TOKEN}" /tmp/cluster_token.txt
        tr -d '\n' < /tmp/cluster_token.txt > "${FILE_CLUSTER_TOKEN}"
        rm -f /tmp/cluster_token.txt
    fi

    chown -R "${DST_USER}:${DST_GROUP}" "${DST_USER_DATA_PATH}"

    if [[ -L "${DIR_MODS_SYS}" ]]; then
        rm -f "${DIR_MODS_SYS}"
        cp -r /opt/dst_default_config/DoNotStarveTogether/Cluster_1/mods "${DIR_MODS_SYS}"
    fi

    if [ ! -d "${DIR_MODS_USER}" ]; then
        echo "Creating default mod config..."
        mkdir -p "${DST_USER_DATA_PATH}/DoNotStarveTogether/Cluster_1"
        cp -r "${DIR_MODS_SYS}" "${DIR_MODS_USER}"
    fi

    rm -rf "${DIR_MODS_SYS}"
    ln -s "${DIR_MODS_USER}" "${DIR_MODS_SYS}"

    echo "Updating mods..."
    su --preserve-environment --group "${DST_GROUP}" -c "dontstarve_dedicated_server_nullrenderer -persistent_storage_root \"${DST_USER_DATA_PATH}\" -ugc_directory \"${DST_USER_DATA_PATH}\"/ugc -cluster Cluster_1 -only_update_server_mods" "${DST_USER}"

    rm -f /var/run/supervisor.sock
    touch /var/run/supervisor.sock
fi

exec "$@"
