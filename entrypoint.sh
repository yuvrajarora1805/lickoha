#!/bin/bash
set -e

INSTANCE="library"

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

    # Create instance using external DB
    koha-create --request-db ${INSTANCE}

    # Configure DB connection manually
    CONF="/etc/koha/sites/${INSTANCE}/koha-conf.xml"
    sed -i "s|<database>.*</database>|<database>${KOHA_DBNAME:-koha_library}</database>|g" $CONF
    sed -i "s|<hostname>.*</hostname>|<hostname>${KOHA_DBHOST:-koha-db}</hostname>|g" $CONF
    sed -i "s|<user>.*</user>|<user>${KOHA_DBUSER:-kohaadmin}</user>|g" $CONF
    sed -i "s|<pass>.*</pass>|<pass>${KOHA_DBPASS:-koha_db_password}</pass>|g" $CONF

    echo "Koha instance created."
fi

# Enable the site in Apache
a2ensite ${INSTANCE}
a2ensite ${INSTANCE}-intranet || true

# Start Apache
echo "Starting Apache..."
exec apache2ctl -D FOREGROUND
