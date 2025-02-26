FROM cm2network/steamcmd:root
LABEL maintainer="studyfranco@hotmail.fr"

ARG PROTON_VERSION="GE-Proton9-25"

RUN set -x \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y gosu pigz curl python3 --no-install-recommends\
    && rm -rf /var/lib/apt/lists/*  \
    && rm -rf /var/log/* \
    && gosu nobody true

RUN mkdir -p /config \
 && chown steam:steam /config \
 && mkdir -p /home/steam/.steam/steam/compatibilitytools.d \
 && curl -L "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${PROTON_VERSION}/${PROTON_VERSION}.tar.gz" | tar xz -C /home/steam/.steam/steam/compatibilitytools.d

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
    WINEARCH=win64 \
    WINEPATH=/config/gamefiles \
    WINEPREFIX=/home/steam/icarus \
    GAMEBASECONFIGDIR="/home/steam/.steam/steam/compatibilitytools.d/${PROTON_VERSION}/dist/share/default_pfx/drive_c/icarus/Saved/Config" \
    GAMECONFIGDIR="/home/steam/.steam/steam/compatibilitytools.d/${PROTON_VERSION}/dist/share/default_pfx/drive_c/icarus/Saved/Config/WindowsServer" \
    GAMEBASESAVESDIR="/home/steam/.steam/steam/compatibilitytools.d/${PROTON_VERSION}/dist/share/default_pfx/drive_c/icarus/Saved/PlayerData/DedicatedServer" \
    GAMESAVESDIR="/home/steam/.steam/steam/compatibilitytools.d/${PROTON_VERSION}/dist/share/default_pfx/drive_c/icarus/Saved/PlayerData/DedicatedServer/Prospects" \
    PROTON_VERSION=${PROTON_VERSION} \
    STEAM_COMPAT_INSTALL_PATH="/home/steam/" \
    STEAM_COMPAT_DATA_PATH="/home/steam/.steam/steam/steamapps/compatdata" \
    STEAM_COMPAT_CLIENT_INSTALL_PATH="/home/steam/.steam" \
    SKIPUPDATE="false"

ENTRYPOINT [ "/init.sh" ]