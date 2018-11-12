#!/bin/bash
echo "[-] Checking for a local PostgreSQL installation..."
CONF_FILE=$(/bin/ls /etc/postgresql/*/main/pg_hba.conf 2>/dev/null | head -1)
if [ -z "${CONF_FILE}" ] ; then
    echo '[x] No pg_hba.conf file under /etc/postgresql/*/main/ ... Aborting.'
    exit 1
else
    echo '[-]     Good, found config file under '"${CONF_FILE}"
fi
echo "[-] Checking whether local connections to PostgreSQL are trusted..."
if ! sudo grep '^local.*trust$' "${CONF_FILE}" >/dev/null 2>&1 ; then
    echo "[-] Setting local connections to PostgreSQL as trusted..."
    echo "local   all             all                                     trust" | \
       sudo tee -a "${CONF_FILE}"
else
    echo '[-]     All good, already set as such.'
fi
echo "[-] Checking whether a local postgres DB install has a 'taste' user..."
echo | psql -U taste postgres  2>/dev/null
if [ $? -ne 0 ] ; then
    echo "[-] Adding a 'taste' DB user..."
    sudo su - postgres -c psql -h 127.0.0.1 <<< \
        "create user taste with password 'tastedb'; alter user taste with superuser;" >/dev/null
    if [ $? -ne 0 ] ; then
        echo "[x] Failed to create DB user 'taste'... Aborting."
        exit 1
    fi
else
    echo '[-]     Already there.'
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
    echo '[-]     Already stored.'
fi
chmod 600 "${PGPASS}"
