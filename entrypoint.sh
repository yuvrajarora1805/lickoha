#!/bin/bash
set -e

INSTANCE="library"

# Start Memcached (Koha needs this)
service memcached start || true

# Wait for DB to be fully ready before proceeding
echo "Waiting for database port to open..."
while ! bash -c "</dev/tcp/${KOHA_DBHOST:-koha-db}/3306" 2>/dev/null; do
    sleep 2
done
# Wait an extra 10 seconds for MariaDB to finish initializing its internal tables
echo "Port open! Waiting 10s for MariaDB init..."
sleep 10
echo "Database is up!"

# Create Koha instance if it doesn't exist
if [ ! -f "/etc/koha/sites/${INSTANCE}/koha-conf.xml" ]; then
    echo "Creating Koha instance: ${INSTANCE}..."

    # Configure database connection
    cat > /etc/koha/koha-sites.conf <<EOF
DOMAIN=".local"
INTRAPORT="8080"
INTRAPREFIX=""
INTRASUFFIX="-intra"
DEFAULTSQL=""
OPACPORT="80"
OPACPREFIX=""
OPACSUFFIX=""
ZEBRA_MARC_FORMAT="marc21"
ZEBRA_LANGUAGE="en"
USE_ZEBRA_FACETS="yes"
KOHA_ZEBRA_PASSWORD="$(openssl rand -base64 12)"
EOF

    # Stop apache if running (koha-create tends to start it)
    service apache2 stop || true

    # Create instance using external DB
    koha-create --request-db ${INSTANCE}

    # Configure DB connection manually
    CONF="/etc/koha/sites/${INSTANCE}/koha-conf.xml"
    sed -i "s|<database>.*</database>|<database>${KOHA_DBNAME:-koha_library}</database>|g" $CONF
    sed -i "s|<hostname>.*</hostname>|<hostname>${KOHA_DBHOST:-koha-db}</hostname>|g" $CONF
    sed -i "s|<user>.*</user>|<user>${KOHA_DBUSER:-kohaadmin}</user>|g" $CONF
    sed -i "s|<pass>.*</pass>|<pass>${KOHA_DBPASS:-koha_db_password}</pass>|g" $CONF

    # Populate the DB schema manually since koha-create --populate-db fails on remote databases
    echo "Importing Koha database schema..."
    koha-mysql ${INSTANCE} < /usr/share/koha/intranet/cgi-bin/installer/data/mysql/kohastructure.sql || echo "Failed to import schema, might already exist."

    echo "Koha instance created."
fi

# Disable default Apache site
a2dissite 000-default || true

# Ensure Apache listens on 8080 for the Staff interface
if ! grep -q "Listen 8080" /etc/apache2/ports.conf; then
    echo "Listen 8080" >> /etc/apache2/ports.conf
fi

# Enable the site in Apache
a2ensite ${INSTANCE} || true

# Start Plack (The Koha application server backend)
echo "Starting Plack..."
koha-plack --start ${INSTANCE} || true

# Stop apache if started by background scripts and clean up pid
service apache2 stop || true
rm -f /var/run/apache2/apache2.pid

# Start Apache
echo "Starting Apache..."
exec apache2ctl -D FOREGROUND
