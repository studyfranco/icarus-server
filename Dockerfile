FROM cm2network/steamcmd:root
LABEL maintainer="studyfranco@hotmail.fr"

RUN set -x \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y gosu pigz winbind jq wine64 wine --no-install-recommends\
    && rm -rf /var/lib/apt/lists/*  \
    && rm -rf /var/log/* \
    && gosu nobody true

RUN mkdir -p /config \
 && chown steam:steam /config

COPY --chmod=700 init.sh /

COPY --chown=steam:steam --chmod=700 *.ini run.sh /home/steam/

WORKDIR /config

ENV SERVER_NAME="IcarusServerByMe" \
    SERVER_PORT=17777 \
    SERVER_QUERY_PORT=27015 \
    STEAMAPPID=2089300 \
    MAXPLAYERS=32 \
    SERVERPASSWORD="password" \
    SERVERADMINPASSWORD="password" \
    PUID=2198 \
    PGID=2198 \
    SHUTDOWN_NOT_JOINED_FOR=20 \
    SHUTDOWN_EMPTY_FOR=20 \
    ALLOW_NON_ADMINS_LAUNCH="True" \
    ALLOW_NON_ADMINS_DELETE="False" \
    LOAD_PROSPECT="" \
    CREATE_PROSPECT="" \
    RESUME_PROSPECT="True" \
    STEAM_ASYNC_TIMEOUT=60 \
    BRANCH="public" \
    WINEPREFIX=/home/steam/icarus \
    WINEARCH=win64 \
    WINEPATH=/config/gamefiles \
    GAMEBASECONFIGDIR="/home/steam/.wine/drive_c/icarus/Saved/Config" \
    GAMECONFIGDIR="/home/steam/.wine/drive_c/icarus/Saved/Config/WindowsServer" \
    GAMEBASESAVESDIR="/home/steam/.wine/drive_c/icarus/Saved/PlayerData/DedicatedServer" \
    GAMESAVESDIR="/home/steam/.wine/drive_c/icarus/Saved/PlayerData/DedicatedServer/Prospects" \
    SKIPUPDATE="false"

ENTRYPOINT [ "/init.sh" ]