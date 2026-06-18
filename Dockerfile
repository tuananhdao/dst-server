FROM jamesits/dst-server:nightly

RUN rm -rf /opt/dst_server \
    && mkdir -p /opt/dst_server \
    && steamcmd +force_install_dir /opt/dst_server +login anonymous +app_update 343050 validate +quit \
    && chown -R "${DST_USER}:${DST_GROUP}" /opt/dst_server

