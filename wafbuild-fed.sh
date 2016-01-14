IDMAP_SHARED_MODULES="idmap_ad,idmap_rid,idmap_adex,idmap_hash,idmap_tdb2"
PDB_SHARED_MODULES="pdb_tdbsam,pdb_ldap,pdb_ads,pdb_smbpasswd,pdb_wbc_sam,pdb_samba4"
AUTH_SHARED_MODULES="auth_unix,auth_wbc,auth_server,auth_netlogond,auth_script,auth_samba4"

BUNDLES_LIBS="heimdal,!zlib,!popt,\
talloc,pytalloc,pytalloc-util,\
tevent,pytevent,\
tdb,pytdb,\
ldb,pyldb,pyldb-util"

LDFLAGS="-Wl,-z,relro -specs=/usr/lib/rpm/redhat/redhat-hardened-ld"

CONFIGURE_OPTS=" \
                \
                --build=x86_64-redhat-linux-gnu \
                --host=x86_64-redhat-linux-gnu \
                --program-prefix= \
                --disable-dependency-tracking \
                --prefix=/usr \
                --exec-prefix=/usr \
                --bindir=/usr/bin \
                --sbindir=/usr/sbin \
                --sysconfdir=/etc \
                --datadir=/usr/share \
                --includedir=/usr/include \
                --libdir=/usr/lib64 \
                --libexecdir=/usr/libexec \
                --localstatedir=/var \
                --sharedstatedir=/var/lib \
                --mandir=/usr/share/man \
                --infodir=/usr/share/info \
                --enable-fhs \
                --with-piddir=/run \
                --with-sockets-dir=/run/samba \
                --with-modulesdir=/usr/lib64/samba \
                --with-pammodulesdir=/usr/lib64/security \
                --with-lockdir=/var/lib/samba/lock \
                --with-statedir=/var/lib/samba \
                --with-cachedir=/var/lib/samba \
                --disable-rpath-install \
                --with-shared-modules=${IDMAP_SHARED_MODULES},\
                                      ${PDB_SHARED_MODULES},\
                                      ${AUTH_SHARED_MODULES} \
                --bundled-libraries=${BUNDLED_LIBS} \
                --with-pam \
                --with-pie \
                --with-relro \
                --without-fam \
                --with-system-mitkrb5 \
                --without-ad-dc \
                --with-cluster-support \
                --with-profiling-data \
                --with-systemd \
               $@"

make distclean && ( export ${LDFLAGS}; ./buildtools/bin/waf configure ${CONFIGURE_OPTS} ) && make -j8
