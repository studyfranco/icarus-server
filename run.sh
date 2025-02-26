#!/bin/bash

set -e

set_ini_prop() {
    sed "/\[$2\]/,/^\[/ s/$3\=.*/$3=$4/" -i "${GAMECONFIGDIR}/$1"
}

set_ini_val() {
    sed "/\[$2\]/,/^\[/ s/((\"$3\",.*))/((\"$3\", $4))/" -i "/home/steam/$1"
}

NUMCHECK='^[0-9]+$'
launchDate=`date +"%Y_%m_%d_%H_%M_%s"`

if [ -f "${GAMECONFIGDIR}/PalWorldSettings.ini" ]; then
    tar cf - "/config/saves" "/config/gameconfigs" | pigz -9 -p 12 - > "/config/backups/${launchDate}.tar.gz"
fi

mkdir -p "${GAMEBASECONFIGDIR}"

if [ -d "${GAMECONFIGDIR}" ]; then
    if [ ! -L "${GAMECONFIGDIR}" ]; then
        rm -r "${GAMECONFIGDIR}"
    fi
fi

if [ ! -L "${GAMECONFIGDIR}" ]; then
    ln -sf "/config/gameconfigs" "${GAMECONFIGDIR}"
fi

mkdir -p "${GAMEBASESAVESDIR}"
if [ ! -L "${GAMESAVESDIR}" ]; then
    ln -sf "/config/saves" "${GAMESAVESDIR}"
fi

echo Initializing Wine...
wineboot --init > /dev/null 2>&1

## Initialise and update files
if ! [[ "${SKIPUPDATE,,}" == "true" ]]; then

    space=$(stat -f --format="%a*%S" .)
    space=$((space/1024/1024/1024))
    printf "Checking available space...%sGB detected\\n" "${space}"

    if [[ "$space" -lt 8 ]]; then
        printf "You have less than 8GB (%sGB detected) of available space to download the game.\\nIf this is a fresh install, it will probably fail.\\n" "${space}"
    fi

    printf "Downloading the latest version of the game...\\n"

    /home/steam/steamcmd/steamcmd.sh +@sSteamCmdForcePlatformType windows +force_install_dir /config/gamefiles +login anonymous +app_update "$STEAMAPPID" -beta "${BRANCH}" validate +quit
else
    printf "Skipping update as flag is set\\n"
fi

engineIni="${GAMECONFIGDIR}/Engine.ini"
if [[ ! -e ${engineIni} ]]; then
  mkdir -p ${GAMECONFIGDIR}
  touch ${engineIni}
fi

if ! grep -Fq "[OnlineSubsystemSteam]" ${engineIni}
then
    echo '[OnlineSubsystemSteam]' >> ${engineIni}
    echo 'AsyncTaskTimeout=' >> ${engineIni}
fi

if ! [[ "$STEAM_ASYNC_TIMEOUT" =~ $NUMCHECK ]] ; then
    printf "Invalid STEAM_ASYNC_TIMEOUT number given: %s\\n" "${STEAM_ASYNC_TIMEOUT}"
    STEAM_ASYNC_TIMEOUT=60
fi

sedCommand="/AsyncTaskTimeout=/c\AsyncTaskTimeout=${STEAM_ASYNC_TIMEOUT}"
sed -i ${sedCommand} ${engineIni}


serverSettingsIni="${GAMECONFIGDIR}/ServerSettings.ini"
if [[ ! -e ${serverSettingsIni} ]]; then
  touch ${serverSettingsIni}
fi

if ! [[ "$MAXPLAYERS" =~ $NUMCHECK ]] ; then
    printf "Invalid max players number given: %s\\n" "${MAXPLAYERS}"
    MAXPLAYERS=32
fi

if ! grep -Fq "[/Script/Icarus.DedicatedServerSettings]" ${serverSettingsIni}
then
    echo '[/Script/Icarus.DedicatedServerSettings]' >> ${serverSettingsIni}
    echo "SessionName=${SERVER_NAME}" >> ${serverSettingsIni}
    echo "JoinPassword=${SERVERPASSWORD}" >> ${serverSettingsIni}
    echo "MaxPlayers=${MAXPLAYERS}" >> ${serverSettingsIni}
    echo "AdminPassword=${SERVERADMINPASSWORD}" >> ${serverSettingsIni}
    echo "ShutdownIfNotJoinedFor=${SHUTDOWN_NOT_JOINED_FOR}" >> ${serverSettingsIni}
    echo "ShutdownIfEmptyFor=${SHUTDOWN_EMPTY_FOR}" >> ${serverSettingsIni}
    echo "AllowNonAdminsToLaunchProspects=${ALLOW_NON_ADMINS_LAUNCH}" >> ${serverSettingsIni}
    echo "AllowNonAdminsToDeleteProspects=${ALLOW_NON_ADMINS_DELETE}" >> ${serverSettingsIni}
    echo "LoadProspect=${LOAD_PROSPECT}" >> ${serverSettingsIni}
    echo "CreateProspect=${CREATE_PROSPECT}" >> ${serverSettingsIni}
    echo "ResumeProspect=${RESUME_PROSPECT}" >> ${serverSettingsIni}
fi

sed -i "/SessionName=/c\SessionName=${SERVER_NAME}" ${serverSettingsIni}
sed -i "/JoinPassword=/c\JoinPassword=${SERVERPASSWORD}" ${serverSettingsIni}
sed -i "/MaxPlayers=/c\MaxPlayers=${MAXPLAYERS}" ${serverSettingsIni}
sed -i "/AdminPassword=/c\AdminPassword=${SERVERADMINPASSWORD}" ${serverSettingsIni}
sed -i "/ShutdownIfNotJoinedFor=/c\ShutdownIfNotJoinedFor=${SHUTDOWN_NOT_JOINED_FOR}" ${serverSettingsIni}
sed -i "/ShutdownIfEmptyFor=/c\ShutdownIfEmptyFor=${SHUTDOWN_EMPTY_FOR}" ${serverSettingsIni}
sed -i "/AllowNonAdminsToLaunchProspects=/c\AllowNonAdminsToLaunchProspects=${ALLOW_NON_ADMINS_LAUNCH}" ${serverSettingsIni}
sed -i "/AllowNonAdminsToDeleteProspects=/c\AllowNonAdminsToDeleteProspects=${ALLOW_NON_ADMINS_DELETE}" ${serverSettingsIni}
sed -i "/LoadProspect=/c\LoadProspect=${LOAD_PROSPECT}" ${serverSettingsIni}
sed -i "/CreateProspect=/c\CreateProspect=${CREATE_PROSPECT}" ${serverSettingsIni}
sed -i "/ResumeProspect=/c\ResumeProspect=${RESUME_PROSPECT}" ${serverSettingsIni}

if ! [[ "$SERVER_PORT" =~ $NUMCHECK ]] ; then
    printf "Invalid server port given: %s\\n" "${SERVER_PORT}"
    SERVER_PORT=17777
fi

if ! [[ "$SERVER_QUERY_PORT" =~ $NUMCHECK ]] ; then
    printf "Invalid server query port given: %s\\n" "${SERVER_QUERY_PORT}"
    SERVER_QUERY_PORT=27015
fi

cd /config/gamefiles || exit 1

exec wine /config/gamefiles/Icarus/Binaries/Win64/IcarusServer-Win64-Shipping.exe \
  -Log \
  -UserDir='C:\icarus' \
  -SteamServerName="${SERVER_NAME}" \
  -PORT="${SERVER_PORT}" \
  -QueryPort="${SERVER_QUERY_PORT}"