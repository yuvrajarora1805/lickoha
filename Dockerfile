FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies and Koha from official apt repo
RUN apt-get update && apt-get install -y \
    wget gnupg2 curl apt-transport-https \
    && echo "deb [signed-by=/usr/share/keyrings/koha-keyring.gpg] https://debian.koha-community.org/koha 24.11 main" \
       > /etc/apt/sources.list.d/koha.list \
    && wget -qO- https://debian.koha-community.org/koha/gpg.asc \
       | gpg --dearmor > /usr/share/keyrings/koha-keyring.gpg \
    && apt-get update \
    && apt-get install -y koha-common \
    && apt-get clean

# Inject our custom files
COPY C4/Auth.pm /usr/share/koha/lib/C4/Auth.pm
COPY admin/license.pl /usr/share/koha/intranet/cgi-bin/admin/license.pl
COPY admin/license_expired.pl /usr/share/koha/intranet/cgi-bin/admin/license_expired.pl
COPY koha-tmpl/intranet-tmpl/prog/en/modules/admin/license.tt \
     /usr/share/koha/intranet/htdocs/intranet-tmpl/prog/en/modules/admin/license.tt
COPY koha-tmpl/intranet-tmpl/prog/en/modules/admin/license_expired.tt \
     /usr/share/koha/intranet/htdocs/intranet-tmpl/prog/en/modules/admin/license_expired.tt
COPY koha-tmpl/intranet-tmpl/prog/js/vue/components/Islands/AdminMenu.vue \
     /usr/share/koha/intranet/htdocs/intranet-tmpl/prog/js/vue/components/Islands/AdminMenu.vue

EXPOSE 80 8080

CMD ["apache2ctl", "-D", "FOREGROUND"]
