#!/bin/bash

# enlighten.sh
#
# A clustered Samba hacking script to synchronize the code repositories on the
# cluster nodes.

DEFAULT_NODES="ganesh buddhi riddhi siddhi"

get_help() {
echo "USAGE: enlighten.sh [-bcf] [<node> ...]

A clustered Samba hacking script to synchronize the code repositories on the
cluster nodes. By default, this script only tries to update the code on remote
nodes via rsync. Nodes are specified as a space-separated list of names or IP
address. If no nodes are specified, the following list is used:

$DEFAULT_NODES

Options:
 -b, --build
	Run a Samba build on the first node before distributing the repo to the
	other nodes.

 -c, --configure
	Clean the repo, run configure, and do a Samba build. Implies --build.

 -f, --force
	Normally, this script attempts to synchronize the repositories using an
	rsync batched write. This can be really finnicky if you change anything
	on the remote repositories. Use --force to perform a full, non-batched
	rsync on every node. This is much slower but will usually succeed.
"
}

BUILD=false
FORCE=false
CMD="make -j4"


while [[ $# > 0 ]]; do
  ARG="$1"

  if [[ ${ARG:0:1} != "-" ]]; then
    break
  fi

  OPTS=()

  if [[ ${#ARG} -gt 2 && ${ARG:0:2} != "--" && ${ARG:0:1} == "-" ]]; then
    for (( i=1; i<${#ARG}; i++ )); do
      OPTS+=("-${ARG:$i:1}")
    done
  else
    OPTS+=($ARG)
  fi

  for OPT in "${OPTS[@]}"; do
    case $OPT in
      -b|--build)
      BUILD=true
      shift
      ;;
      -f|--force)
      FORCE=true
      shift
      ;;
      -c|--configure)
      BUILD=true
      CMD="./wafbuild.sh"
      shift
      ;;
      *)
      echo "Unknown option: $OPT"
      get_help
      exit
      ;;
    esac
  done
done

nodes=${@:-"$DEFAULT_NODES"}

echo "BUILD: $BUILD"
echo "FORCE: $FORCE"
echo "CMD..: $CMD"
echo "NODES: $nodes"

exit

rm -rf rsync-batch*; rm -rf ../samba-rsync/rsync-batch*
if $FORCE; then
  rsync -rltvD . ../samba-rsync >/dev/null
else
  rsync --write-batch=rsync-batch -rltvD . ../samba-rsync >/dev/null
fi

sync_repo() {
    echo "Syncing $1..."
    ssh $1 "rm -rf rsync_batch*; rm -rf samba/rsync-batch* >/dev/null"

    if $FORCE; then
      rsync -rltvD . $1:samba >/dev/null
    else
      scp -q rsync-batch* $1:
      ssh $1 "./rsync-batch.sh samba >/dev/null"
    fi
}

if $BUILD; then
  head=$(echo "$nodes" | awk '{ print $1 }')
  others=${nodes#$head }

  echo "Syncing $head..."
  sync_repo $head

  echo "Running command [$CMD] on $head..."
  ssh $head "cd samba; $CMD"
  ret=$?

  if [ $ret == 0 ]; then
    if $FORCE; then
      FFLAG="f"
    else
      FFLAG=""
    fi
    ssh $head "cd samba; ./enlighten.sh -${FFLAG} ${others}"
  fi
else
  for n in $nodes; do
    sync_repo $n
  done
fi
