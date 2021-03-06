ARG APACHE_VER

FROM wodby/httpd:${APACHE_VER}

ARG APACHE_VER

ENV APACHE_VER="${APACHE_VER}" \
    APP_ROOT="/var/www/html" \
    APACHE_DIR="/usr/local/apache2" \
    FILES_DIR="/mnt/files" \
    APACHE_VHOST_PRESET="html" \
    APACHE_MPM="event"

RUN set -ex; \
    \
    deluser www-data; \
    addgroup -S apache; \
    adduser -S -D -H -h /usr/local/apache2 -s sbin/nologin -G apache apache; \
    \
	addgroup -g 1000 -S wodby; \
	adduser -u 1000 -D -S -s /bin/bash -G wodby wodby; \
	sed -i '/^wodby/s/!/*/' /etc/shadow; \
	echo "PS1='\w\$ '" >> /home/wodby/.bashrc; \
    \
    apk --update --no-cache -t .apache-rundeps add \
        findutils \
        make \
        nghttp2 \
        sudo; \
    \
    mkdir -p \
        "${APP_ROOT}" \
        "${FILES_DIR}" \
        /usr/local/apache2/conf/conf.d; \
    \
    chown -R wodby:wodby \
        "${APP_ROOT}" \
        "${FILES_DIR}" \
        /usr/local/apache2; \
    \
    rm -f /usr/local/apache2/logs/httpd.pid; \
    \
    # Script to fix volumes permissions via sudo.
    echo "find ${APP_ROOT} ${FILES_DIR} -maxdepth 0 -uid 0 -type d -exec chown wodby:wodby {} +" > /usr/local/bin/init_volumes; \
    chmod +x /usr/local/bin/init_volumes; \
    \
    { \
        echo -n 'wodby ALL=(root) NOPASSWD:SETENV: ' ; \
        echo -n '/usr/local/bin/init_volumes, ' ; \
        echo '/usr/local/apache2/bin/httpd' ; \
    } | tee /etc/sudoers.d/wodby; \
    \
    # Cleanup
    rm -rf /var/cache/apk/*

USER wodby

WORKDIR $APP_ROOT

COPY bin /usr/local/bin
COPY templates /etc/gotpl/
COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["sudo", "httpd", "-DFOREGROUND"]
