#!/bin/bash

NAME="glusterfs"
CASE="-autocase"
declare -A CONF
CONF=( ["case sensitive"]="auto" ["preserve case"]="yes" ["short preserve case"]="yes" ) #["store dos attributes"]="no" ["map archive"]="no" )
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
    nomangle)
    CASE="-$1"
    CONF["case sensitive"]="no"
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

LOG_DIRS="/var/log/samba"
if [[ $NAME == glusterfs* ]]; then
  LOG_DIRS+=" /var/log/glusterfs"
  SHARE="share1"
else
  SHARE="share2"
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
echo "Connecting to ${SHARE}..."
smbclient -m ${PROT} -U vagrant%vagrant //ganesh/${SHARE} -c "put scripts/foo foo; q;" && SAVE=true || SAVE=false

kill -INT $PID

if [ $SAVE == true ]; then
  vagrant ssh ganesh -c "sudo tar -czvf ${RUN_NAME}_logs.tgz ${LOG_DIRS}"
  vagrant ssh-config >scripts/ssh_config
  scp -F scripts/ssh_config vagrant@ganesh:${RUN_NAME}_logs.tgz scripts/
  cd scripts
  tar -xzvf ${RUN_NAME}_logs.tgz -O var/log/samba/log.jarrpa >${RUN_NAME}.samba.log.jarrpa.csv
  sed -i "s/\"/'/g" ${RUN_NAME}.samba.log.jarrpa.csv
  sed -i "s/^\[/\"[/" ${RUN_NAME}.samba.log.jarrpa.csv
  sed -i "s/\] \.\./]\",\"../" ${RUN_NAME}.samba.log.jarrpa.csv
  sed -i 'N;s/)\n  /)","/;P;D' ${RUN_NAME}.samba.log.jarrpa.csv
  sed -i "s/^  /,,\"/" ${RUN_NAME}.samba.log.jarrpa.csv
  sed -i "s/$/\"/" ${RUN_NAME}.samba.log.jarrpa.csv
fi
