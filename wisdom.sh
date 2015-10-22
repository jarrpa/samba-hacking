#!/bin/bash

bin/default/ctdb/ctdb catdb secrets.tdb | grep -v "dmaster\|rsn\|Dumped" | sed -e 's/key/{\nkey/' -e 's/^$/}/' >foodb
rm -f /etc/samba/secrets.*
tdbrestore /etc/samba/secrets.tdb <foodb
