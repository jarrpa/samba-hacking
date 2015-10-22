PDB_SHARED_MODULES="pdb_ads,pdb_tdbsam,pdb_smbpasswd,pdb_wbc_sam"
IDMAP_SHARED_MODULES="idmap_ipa,idmap_rid,idmap_ad,idmap_adex,idmap_hash,idmap_tdb2,idmap_ldap"
GPEXT_SHARED_MODULES="gpext_security,gpext_registry,gpext_scripts"
VFS_SHARED_MODULES="vfs_glusterfs"

CONFIGURE_OPTS=" \
                --prefix=/root/samba/ \
                --localstatedir=/var \
                --sysconfdir=/etc \
                --with-lockdir=/var/lib/samba \
                --with-piddir=/var/run \
                --with-privatedir=/etc/samba \
                --with-statedir=/var/lib/samba \
                --with-cachedir=/var/lib/samba \
                --with-quotas \
                --with-pam \
                --with-shared-modules=$IDMAP_SHARED_MODULES,$PDB_SHARED_MODULES,$GPEXT_SHARED_MODULES,$VFS_SHARED_MODULES \
                --with-ads \
                --with-dnsupdate \
                --enable-developer \
                --with-aio-support \
                --with-logfilebase=/var/log/samba \
                --enable-selftest \
                --with-selftest-prefix=./st \
                --enable-fhs \
                --with-cluster-support \
                $@"
#                --libdir=/usr/lib64 \
#                --mandir=/usr/share/man \
#                --with-modulesdir=/usr/lib64/samba \

make distclean && ./buildtools/bin/waf configure $CONFIGURE_OPTS && make -j4
