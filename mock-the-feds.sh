#!/bin/bash

SCM="~/projects/samba/samba-perf"
PKG="~/projects/fedora/samba"

MOCK_OPTS="--no-clean --without=configure --nocheck --no-cleanup-after"
if [ "x${1}" == "xclean" ]; then
  MOCK_OPTS="--no-cleanup-after"
  shift
elif [ "x${1}" == "xconfig" ]; then
  MOCK_OPTS="${MOCK_OPTS/without=configure/with=configure}"
  shift
fi

pushd $PKG

VERSION=$(grep "define samba_version" samba.spec | awk '{print $3}')
RELEASE=$(grep "define main_release" samba.spec | awk '{print $3}')
SRPM="samba-${VERSION}-${RELEASE}.fc23.src.rpm"

pushd $SCM
git archive --format=tar.gz --prefix=samba-${VERSION}/ HEAD -o $PKG/samba-${VERSION}.tar.gz
popd

fedpkg --dist f23 srpm

echo "sudo mock ${MOCK_OPTS} -r f23-x86_64 rebuild ${SRPM}"
sudo mock ${MOCK_OPTS} -r f23-x86_64 rebuild ${SRPM}
popd
vagrant rsync
