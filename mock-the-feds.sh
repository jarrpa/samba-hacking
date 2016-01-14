#!/bin/bash

SCM="~/projects/samba/samba-perf"
PKG="~/projects/fedora/samba"
REPO="~/repo/f23/x86_64"
REPO_NAME="jarrpa"
NODES="ganesh"

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

if [ -f "${REPO}/${SRPM}" ]; then
  OLD_MD5=`md5sum ${REPO}/${SRPM} | awk '{print $1}'`
else
  OLD_MD5=""
fi

pushd $SCM
git archive --format=tar.gz --prefix=samba-${VERSION}/ HEAD -o $PKG/samba-${VERSION}.tar.gz
popd

fedpkg --dist f23 srpm

NEW_MD5=`md5sum ${SRPM} | awk '{print $1}'`

if [ "${NEW_MD5}" != "${OLD_MD5}" ]; then
  echo "sudo mock ${MOCK_OPTS} -r f23-x86_64 rebuild ${SRPM}"
  sudo mock ${MOCK_OPTS} -r f23-x86_64 rebuild ${SRPM}
  popd
  vagrant rsync
  if [ "x${OLD_MD5}" != "x" ]; then
    CMD="SAMBA_PKGS=`dnf list installed | grep \"samba\\\|ctdb\\\|libwb\\\|libsmb\" | awk '{print $1}'`; sudo dnf reinstall ${SAMBA_PKGS}"
  else
    CMD="sudo dnf --disablerepo=* --enablerepo=${REPO_NAME} update"
  fi
  vagrant ssh ${NODES} -c "${CMD}"
fi
