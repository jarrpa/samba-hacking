#!/bin/bash

CMD="cd /shared/source; make install"
VDIR=~/projects/vagrant/vagrant-ansible-samba-cluster
VNODES=""

reading=false
while read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == "[samba_servers]" ]]; then
        reading=true
        continue
    fi
    if [ "$reading" = true ]; then
      if [ "x${line}" == "x"  ]; then
        break
      fi
      VNODES="${VNODES} ${line}"
    fi
done < ${VDIR}/.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory

case $1 in
  -f|--force)
  CMD="${CMD} || ./wafbuild-fed.sh"
  ;;
  *)
  CMD="$@"
  ;;
esac

cd ${VDIR}
vagrant rsync ${VNODES}
for NODE in ${VNODES}; do
  vagrant ssh ${NODE} -c "${CMD}"
done
