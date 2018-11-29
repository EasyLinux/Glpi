FROM alpine:3.7
LABEL author="Serge NOEL <serge.noel@easylinux.fr>"

#ENV   GLPI_PLUGINS="fusioninventory|https://github.com/fusioninventory/fusioninventory-for-glpi/releases/download/glpi9.1%2B1.1/fusioninventory-for-glpi_9.1.1.1.tar.gz" 

# Install webserver & Php
RUN apk update\
    && apk add curl nginx php7 php7-curl php7-ctype php7-dom php7-fpm php7-gd php7-imap php7-json php7-zlib \
    supervisor php7-ldap php7-pdo_mysql php7-mysqli php7-openssl php7-opcache php7-xml php7-xmlrpc php7-apcu \
    && mkdir -p /run/nginx


# Install GLPI sources

WORKDIR /tmp
RUN curl -O -L "https://github.com/glpi-project/glpi/releases/download/9.3.3/glpi-9.3.3.tgz"

RUN mkdir -p /var/www \
    && cd /var/www \
    && tar -zxf /tmp/glpi-9.3.3.tgz --strip 1 \
    && rm /tmp/glpi-9.3.3.tgz \
    && rm -rf AUTHORS.txt CHANGELOG.txt LISEZMOI.txt README.md

# Install plugins
WORKDIR /var/www/plugins
RUN rm -f * \
    && curl -O -L https://github.com/fusioninventory/fusioninventory-for-glpi/releases/download/glpi9.3%2B1.3/fusioninventory-9.3+1.3.tar.bz2 \
    && curl -O -L https://github.com/pluginsGLPI/datainjection/releases/download/2.6.4/glpi-datainjection-2.6.4.tar.bz2 \
    && curl -O -L https://forge.glpi-project.org/attachments/download/2262/GLPI-dashboard_plugin-0.9.5.zip \
    && curl -O -L https://github.com/pluginsGLPI/formcreator/releases/download/v2.6.5/glpi-formcreator-2.6.5.tar.bz2 \
    && curl -O -L https://forge.glpi-project.org/attachments/download/2253/glpi-reports-1.12.0.tar.gz \
    && curl -O -L https://forge.glpi-project.org/attachments/download/2252/glpi-pdf-1.4.0.tar.gz \
    && curl -O -L https://github.com/pluginsGLPI/mreporting/releases/download/1.5.3/glpi-mreporting-1.5.3.tar.bz2 \
    && curl -O -L https://forge.glpi-project.org/attachments/download/2251/glpi-behaviors-2.1.1.tar.gz \
    && curl -O -L https://github.com/pluginsGLPI/fields/releases/download/1.8.2/glpi-fields-1.8.2.tar.bz2

RUN for i in *.bz2; do   extraction de $i; tar jxf $i; rm $i; done \
    && for i in *.gz; do   extraction de $i; tar zxf $i; rm $i; done \
    && for i in *.zip; do   extraction de $i; unzip $i; rm $i; done


# Apply PHP FPM configuration
RUN sed -i -e "s|;daemonize\s*=\s*yes|daemonize = no|g" /etc/php7/php-fpm.conf && \
    sed -i -e "s|display_errors = Off|display_errors = stderr|" /etc/php7/php.ini && \
    sed -i -e "s|display_startup_errors = Off|display_startup_errors = On|" /etc/php7/php.ini && \
    sed -i -e "s|user\s*=\s*nobody|user = nginx|g" /etc/php7/php-fpm.conf && \
    sed -i -e "s|group\s*=\s*nobody|group = nginx|g" /etc/php7/php-fpm.conf && \
    sed -i -e "s|listen\s*=\s*127\.0\.0\.1:9000|listen = /var/run/php-fpm.sock|g" /etc/php7/php-fpm.conf && \
    sed -i -e "s|;listen\.owner\s*=\s*.*$|listen.owner = nginx|g" /etc/php7/php-fpm.conf && \
    sed -i -e "s|;listen\.group\s*=.*$|listen.group = nginx|g" /etc/php7/php-fpm.conf && \
    sed -i -e "s|;listen\.mode\s*=\s*|listen.mode = |g" /etc/php7/php-fpm.conf && \
    sed -i -e "s|max_execution_time\s*=.*$|max_execution_time = 600|" /etc/php7/php.ini && \
    sed -i -e "s|upload_max_filesize\s*=.*$|upload_max_filesize = 30M|" /etc/php7/php.ini && \
    chown -R nginx.nginx /var/www && \
    chmod -R g=rX,o=--- /var/www

# Add some configurations files
COPY Files/ /

EXPOSE 80/tcp
VOLUME ["/var/www/files", "/var/www/config"]
WORKDIR "/var/www"

HEALTHCHECK --interval=5s --timeout=3s --retries=3 \
    CMD curl --silent --fail http://localhost:80 || exit 1

COPY launch-glpi /usr/local/bin/launch-glpi
CMD ["/usr/local/bin/launch-glpi"]
