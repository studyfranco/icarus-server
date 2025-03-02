#!/bin/bash
 
set -e

if [[ "$DEBUG" == "true" ]]; then
    printf "Debugging enabled (the container will exit after printing the debug info)\\n\\nPrinting environment variables:\\n"
    export

    echo "
System info:
OS:  $(uname -a)
CPU: $(lscpu | grep 'Model name:' | sed 's/Model name:[[:space:]]*//g')
RAM: $(awk '/MemAvailable/ {printf( "%d\n", $2 / 1024000 )}' /proc/meminfo)GB/$(awk '/MemTotal/ {printf( "%d\n", $2 / 1024000 )}' /proc/meminfo)GB
HDD: $(df -h | awk '$NF=="/"{printf "%dGB/%dGB (%s used)\n", $3,$2,$5}')"

    printf "\\nCurrent user:\\n"
    id

    printf "\\nProposed user:\\n"
    printf "uid=${PUID}(?) gid=${PGID}(?) groups=${PGID}(?)\\n"

    printf "\\nExiting...\\n"
    exit 1
fi

CURRENTUID=$(id -u)

if [[ "${CURRENTUID}" -ne "0" ]]; then
    printf "Current user is not root (${CURRENTUID})\\nPass your user and group to the container using the PGID and PUID environment variables\\nDo not use the --user flag (or user: field in Docker Compose)\\n"
    exit 1
fi

ramAvailable=$(awk '/MemAvailable/ {printf( "%d\n", $2 / 1024000 )}' /proc/meminfo)
printf "Checking available memory...%sGB detected\\n" "${ramAvailable}"

if [[ "$ramAvailable" -lt 2 ]]; then
    printf "You have less than the required 2GB minmum (%sGB detected) of available RAM to run the game server.\\nIt is likely that the server will fail to load properly.\\n" "${ramAvailable}"
fi

mkdir -p /config/backups /config/gamefiles /config/saves /config/gameconfigs || exit 1

NUMCHECK='^[0-9]+$'

if ! [[ "$PGID" =~ $NUMCHECK ]] ; then
    printf "Invalid group id given: ${PGID}\\n"
    PGID="2198"
fi

if ! [[ "$PUID" =~ $NUMCHECK ]] ; then
    printf "Invalid user id given: ${PUID}\\n"
    PUID="2198"
fi

if [[ $(getent group ${PGID} | cut -d: -f1) ]]; then
    usermod -a -G "${PGID}" steam
else
    groupmod -g "${PGID}" steam
fi

if [[ $(getent passwd ${PUID} | cut -d: -f1) ]]; then
    USER=$(getent passwd ${PUID} | cut -d: -f1)
else
    usermod -u "${PUID}" steam
fi

chown -R "${PUID}":"${PGID}" /config /home/steam

exec gosu "${USER}" "/home/steam/run.sh" "$@"