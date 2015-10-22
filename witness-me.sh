#!/bin/bash

SHOW_LOG=""

while [[ $# > 0 ]]; do
  OPT="$1"

  case $OPT in
  -l|--log)
    SHOW_LOG="echo; echo '==== /var/log/samba/log.samba ====='; tail -25 /var/log/samba/log.samba"
    ;;
  *)
    echo "Unknown opt: " $OPT
    exit 1
  esac

  shift
done

function WPID() {
  if [ -e /var/run/witnessd.pid ]; then
    echo "Witness PID: $(cat /var/run/witnessd.pid)"
  else
    echo "Witness PID: NONE"
  fi
}

#watch -n 1 "bin/smbstatus -S; echo; netstat -4dnp | grep \":1024\" | grep samba | awk '{print \"PID: \" substr(\$7, 0, index(\$7, \"/\")-1) \" RPC (Witness) Conn: \" substr(\$4, 0, index(\$4,\":\")-1)}' | uniq; echo; bin/default/ctdb/ctdb status; bin/default/ctdb/ctdb ip; $SHOW_LOG"
watch -tn 1 "bin/smbstatus -p; echo `WPID`; echo; bin/default/ctdb/ctdb status; bin/default/ctdb/ctdb ip; $SHOW_LOG"
