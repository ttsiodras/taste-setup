#!/bin/bash
echo "[-] Checking whether a local postgres DB install has a 'taste' user..."
echo | psql -U taste postgres  2>/dev/null
if [ $? -ne 0 ] ; then
    echo "[-] Adding a 'taste' DB user..."
    sudo su - postgres -c psql <<< \
        "create user taste with password 'tastedb'; alter user taste with superuser;" >/dev/null
    if [ $? -ne 0 ] ; then
        echo "[x] Failed to create DB user 'taste'... Aborting."
        exit 1
    fi
else
    echo '[-] Already there.'
fi
PGPASS="$HOME/.pgpass"
LINE='127.0.0.1:5432:*:postgres:tastevm'
echo "[-] Checking if 'taste' DB user credentials are stored in \$HOME/.pgpass..."
if ! grep "${LINE/*/\\*}" "$PGPASS" >/dev/null 2>&1 ; then
    echo "[-] Adding the 'taste' DB user credentials to \$HOME/.pgpass ..."
    echo "$LINE" >> "$PGPASS"
    LINE='localhost:5432:*:postgres:tastevm'
    echo "$LINE" >> "$PGPASS"
else
    echo '[-] Already there.'
fi
