#!/bin/bash

#!/bin/bash

BROADCAST=""
RESOURCE=""
STATE=""

while [[ $# > 0 ]]; do
  ARG="$1"

  case $ARG in
  -n|--nodes)
    BROADCAST="/root/samba/bin/default/ctdb/onnode -p $2 "
    shift
    ;;
  --)
    ;;
  *)
    RESOURCE=$1
    STATE=$2
    if [[ "x$RESOURCE" == "x" ]] || [[ "x$STATE" == "x" ]]; then
      echo "Invalid parameters: RESOURCE[$RESOURCE] STATE[$STATE]"
      exit 1
    fi
    shift
  esac
  shift
done

${BROADCAST}/root/samba/bin/smbcontrol witnessd witnessnotify change $RESOURCE $STATE
