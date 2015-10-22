#!/bin/bash

# rebirth.sh
#
# A clustered Samba hacking script to kill and restart Samba processes on the
# cluster nodes. This script should be run locally on the individual nodes.

TIMEOUT_SECS=0
DEFAULT_PROCS="ctdbd samba smbd nmbd winbindd"

get_help() {
echo "USAGE: rebirth.sh [<process> ...]

A clustered Samba hacking script to kill and restart Samba processes on the
cluster nodes. This script should be run locally on the individual nodes.
Processes to be killed and restarted can be specified by name as parameters on
the command line. By default, the following list of processes is defined:

$DEFAULT_PROCS
"
}

PROCS=""
RESTART_SAMBA=false
RESTART_CTDB=false
RESTART_WB=false

while [[ $# > 0 ]]; do
  PROG="$1"

  case $PROG in
  ctdb|ctdbd)
    PROCS="$PROCS ctdbd"
    ;;
  samba|smb|smbd)
    PROCS="$PROCS samba smbd nmbd"
    ;;
  winbind|winbindd|wb)
    PROCS="$PROCS winbindd"
    ;;
  all)
    PROCS=""
    ;;
  *)
    echo "Unknown process: " $PROC
    get_help
    exit 1
  esac

  shift
done

PROCS=${PROCS:-"$DEFAULT_PROCS"}

if [[ $PROCS == *"samba"* ]] || [[ $PROCS == *"smbd"* ]] || [[ $PROCS == *"nmbd"* ]]; then
  RESTART_SAMBA=true
fi
if [[ $PROCS == *"ctdbd"* ]]; then
  RESTART_CTDB=true
fi
if [[ $PROCS == *"winbindd"* ]]; then
  RESTART_WB=true
fi

echo "Killing processes [$PROCS]"
killall -9 $PROCS >/dev/null 2>&1
killall -9 $PROCS >/dev/null 2>&1

if $RESTART_SAMBA; then
  rm -rf /var/run/witnessd.pid
fi

mkdir -p /var/run/samba
mkdir -p /var/run/ctdb

if $RESTART_CTDB; then
  echo -n "Starting CTDB"
  bin/default/ctdb/ctdbd --reclock /data/lock-mnt/reclock --pidfile /var/run/ctdb/ctdbd.pid --event-script-dir ctdb/config/events.d/ --public-addresses=/etc/ctdb/public_addresses
  N=0
  STATUS=$(bin/default/ctdb/ctdb status 2>&1)
  NSTATUS=$(echo "$STATUS" | grep "THIS NODE" | awk '{ print $3 }')
  until [ "$NSTATUS" == "OK" ] || [ "$NSTATUS" == *"BANNED"* ] || [ "$STATUS" == *"Errno"* ] || [ $N -ge $TIMEOUT_SECS ]; do
    echo -n "."
    (( N++ ))
    sleep 1
    STATUS=$(bin/default/ctdb/ctdb status 2>&1)
    NSTATUS=$(echo "$STATUS" | grep "THIS NODE" | awk '{ print $3 }')
    #echo -n "$NSTATUS"
  done
  if [ "$NSTATUS" == *"BANNED"* ]; then 
    echo -e "BANNED?!\nCTDB failed to start, check logs."
    exit 1
  fi
  if [ $N -ge $TIMEOUT_SECS ]; then 
    echo -e "TIMEOUT!\nCTDB failed to start, check logs."
    exit 1
  fi
  if [ "$STATUS" == *"Errno"* ]; then 
    echo -e "ERROR!!\nCTDB failed to start, check logs."
    echo "$STATUS"
    exit 1
  fi
  echo "OK!"
fi

if $RESTART_SAMBA || $RESTART_WB; then
  echo "Starting Samba daemons"
  bin/samba >/dev/null 2>&1
fi

echo "Done."

