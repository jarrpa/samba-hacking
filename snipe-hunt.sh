#!/bin/bash

NAME="glusterfs"
CASE="-defaults"
declare -A CONF
CONF=( ["case sensitive"]="auto" ["preserve case"]="yes" ["short preserve case"]="yes" )
PROT="NT1"

if [[ $# > 0 ]]; then
  case $1 in
    yescase)
    CASE="-$1"
    CONF["case sensitive"]="yes"
    shift
    ;;
    nocase)
    CASE="-$1"
    CONF["case sensitive"]="no"
    shift
    ;;
    largedir)
    CASE="-$1"
    CONF["case sensitive"]="yes"
    CONF["preserve case"]="no"
    CONF["short preserve case"]="no"
    shift
    ;;
  esac
fi

if [[ $# > 0 ]]; then
  case $1 in
    SMB3)
    PROT="$1"
    shift
    ;;
    SMB2)
    PROT="$1"
    shift
    ;;
  esac
fi

if [[ $# > 0 ]]; then
  NAME="$1"
  shift
fi

for OPT in "${!CONF[@]}"; do
  sed -i "s/\\(:${OPT}: \\).*/\\1'${CONF[${OPT}]}'/" vagrant.yaml
done

RUN_NAME="${NAME}-${PROT}${CASE}"

vagrant provision || exit 1

rm -f scripts/${RUN_NAME}.pcap
rm -f scripts/${RUN_NAME}_logs.tgz

tcpdump -w scripts/${RUN_NAME}.pcap -i virbr0 -s 0 tcp &
PID=$!

smbclient -m ${PROT} -U vagrant%vagrant -L ganesh || true
smbclient -m ${PROT} -U vagrant%vagrant //ganesh/share1 -c "put scripts/foo foo; rm foo; q;" && SAVE=true || SAVE=false

kill -INT $PID

if [ $SAVE == true ]; then
  vagrant ssh ganesh -c "sudo tar -czvf ${RUN_NAME}_logs.tgz /var/log/samba /var/log/glusterfs"
  vagrant ssh-config >scripts/ssh_config
  scp -F scripts/ssh_config vagrant@ganesh:${RUN_NAME}_logs.tgz scripts/
fi
