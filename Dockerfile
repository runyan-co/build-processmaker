# syntax=docker/dockerfile:1
FROM ubuntu:22.04
MAINTAINER "Alex Runyan <alex@runyan.co>"

#
# Set bash as the default shell
#
SHELL ["/bin/bash", "-c"]

#
# work in the temp dir to keep the image size low
#
WORKDIR /tmp

#
# Build arguments
#
ARG PM_BRANCH=develop
ARG PM_DOMAIN=localhost
ARG PM_DIR=/var/www/html
ARG PM_APP_PORT=8080
ARG PM_BROADCASTER_PORT=6004
ARG PM_DOCKER_SOCK=/var/run/docker.sock
ARG GITHUB_EMAIL
ARG GITHUB_USERNAME
ARG GITHUB_OAUTH_TOKEN
ARG DOCKERVERSION=20.10.5

#
# environment vars
#
ENV COMPOSER_ALLOW_SUPERUSER       1
ENV PHP_VERSION                    8.1
ENV NODE_VERSION                   16.18.1
ENV DEBIAN_FRONTEND                noninteractive
ENV PM_APP_PORT                    ${PM_APP_PORT}
ENV PM_BROADCASTER_PORT            ${PM_BROADCASTER_PORT}
ENV PM_DOMAIN                      ${PM_DOMAIN}
ENV PM_DOCKER_SOCK                 ${PM_DOCKER_SOCK}
ENV PM_BRANCH                      ${PM_BRANCH}
ENV PM_DIR                         ${PM_DIR}
ENV PM_COMPOSER_PACKAGES_PATH      /opt/packages
ENV PM_SETUP_DIR                   /opt/setup
ENV PM_CLI_DIR                     /opt/setup/cli
ENV NVM_DIR                        /root/.nvm
ENV PM_ENV                         .docker.env

#
# debian package updates and installs
#
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y --force-yes software-properties-common && \
    apt-get update -y && \
    apt-add-repository ppa:ondrej/php -y && \
    apt-add-repository ppa:ondrej/nginx -y && \
    apt-get update -y && \
    apt-get install -y --force-yes \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold" \
            time nginx cron supervisor vim htop curl git zip unzip wget mysql-client \
            pkg-config gcc g++ libmcrypt4 libpcre3-dev make python3 python3-pip whois acl \
            libpng-dev libmagickwand-dev libpcre2-dev jq net-tools build-essential \
            php8.1 php8.1-fpm php8.1-cli php8.1-common php8.1-mysql php8.1-zip php8.1-gd \
            php8.1-mbstring php8.1-curl php8.1-xml php8.1-bcmath php8.1-imagick php8.1-dom \
            php8.1-sqlite3 php8.1-imap php8.1-redis php8.1-dev php8.1-mysql php8.1-soap \
            php8.1-intl php8.1-readline php8.1-msgpack php8.1-igbinary php8.1-gmp && \
    git config --global user.name ${GITHUB_USERNAME} && \
    git config --global user.email ${GITHUB_EMAIL} && \
    setcap "cap_net_bind_service=+ep" /usr/bin/php8.1 && \
    sed -i 's/www-data/root/g' /etc/php/8.1/fpm/pool.d/www.conf && \
    mkdir -p /run/php && \
    update-alternatives --set php /usr/bin/php8.1 && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    composer config --global github-oauth.github.com ${GITHUB_OAUTH_TOKEN} && \
    curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKERVERSION}.tgz && \
    tar xzvf docker-${DOCKERVERSION}.tgz --strip 1 -C /usr/local/bin docker/docker && \
    rm -f docker-${DOCKERVERSION}.tgz && \
    ln -s /usr/local/bin/docker /usr/bin/docker && \
    rm -rf "$NVM_DIR" &&  \
    mkdir -p "$NVM_DIR" && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash && \
    chmod 0755 "$NVM_DIR/nvm.sh" && \
    ln -s "$NVM_DIR/nvm.sh" /usr/local/bin/nvm && \
    nvm install --default --no-progress "$NODE_VERSION" && \
    nvm alias default "$NODE_VERSION" && \
    nvm use default && \
    nvm cache clear && \
    nvm unload && \
    apt-get autoremove -y && \
    apt-get purge -y && \
    apt-get clean && \
    rm -rf /var/cache/* /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV PHP_BINARY /usr/bin/php8.1
ENV PATH "$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH"
ENV NODE_PATH "$NVM_DIR/versions/node/v$NODE_VERSION/lib/node_modules"
ENV NPX_PATH /usr/local/bin/npx

#
# update sysctl config for better performance with php
#
RUN echo "DefaultLimitNOFILE=65536" >>/etc/systemd/system.conf && \
    echo "session required pam_limits.so" >>/etc/pam.d/common-session && \
    echo "root soft nofile 65536" >>/etc/security/limits.conf && \
    echo "root hard nofile 65536" >>/etc/security/limits.conf && \
    { \
      echo net.ipv4.tcp_syncookies=1; \
      echo net.ipv4.conf.all.rp_filter=1; \
      echo net.ipv4.conf.all.secure_redirects=1; \
      echo net.ipv4.conf.all.send_redirects=0; \
      echo net.ipv4.conf.all.accept_source_route=0; \
      echo net.ipv6.conf.all.accept_source_route=0; \
      echo net.ipv4.icmp_echo_ignore_broadcasts=1; \
      echo net.ipv4.tcp_timestamps=0; \
      echo net.ipv4.tcp_mem=786432 1697152 1945728; \
      echo net.ipv4.tcp_rmem=4096 4096 16777216; \
      echo net.ipv4.tcp_wmem=4096 4096 16777216; \
      echo net.core.rmem_max=16777216; \
      echo net.core.wmem_max=16777216; \
      echo net.ipv4.netfilter.ip_conntrack_max=999999; \
      echo net.netfilter.nf_conntrack_max=999999; \
      echo net.ipv4.tcp_tw_reuse=1; \
      echo net.ipv4.tcp_max_orphans=262144; \
      echo net.ipv4.ip_local_port_range=1000 65535; \
      echo net.ipv4.tcp_fin_timeout=30; \
      echo net.core.netdev_max_backlog=10000; \
      echo net.core.somaxconn=60000; \
      echo net.ipv4.tcp_synack_retries=3; \
      echo fs.file-max=640000; \
    } >>/etc/sysctl.conf && sysctl --system

#
# cron and nginx config
#
COPY stubs/cron/laravel-cron /etc/cron.d/laravel-cron

#
# supervisord
#
COPY stubs/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

#
# copy php config files
#
COPY stubs/php/8.1/cli/conf.d /etc/php/8.1/cli/conf.d
COPY stubs/php/8.1/fpm/conf.d /etc/php/8.1/fpm/conf.d
COPY stubs/php/8.1/fpm/pool.d/processmaker.conf /etc/php/8.1/fpm/pool.d/processmaker.conf

#
# ensure config files are setup properly
#
RUN chmod 0644 /etc/cron.d/laravel-cron &&  \
    crontab /etc/cron.d/laravel-cron && \
    mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak && \
    mkdir -p /var/log/nginx && \
    touch /var/log/nginx/error.log && \
    mv /etc/php/8.1/fpm/pool.d/www.conf /etc/php/8.1/fpm/pool.d/www.conf.bak

#
# nginx config
#
COPY stubs/nginx/nginx.conf /etc/nginx/nginx.conf

#
# Global composer config
#
COPY stubs/composer/config.json .

#
# find the location for the global composer config and
# create the ProcessMaker setup directory, which
# we will use to store various build scripts,
# config files, and other usefil tools/files
#
RUN composer config --global --list | grep "\[home\]" | awk '{print $2}' > .composer && \
    mv config.json $(cat .composer) && \
    rm -rf "$PM_SETUP_DIR" && \
    mkdir -p "$PM_SETUP_DIR"

WORKDIR $PM_SETUP_DIR

#
# bring over needed config files
#
COPY stubs/.env.example .
COPY stubs/echo/laravel-echo-server.json .

#
# install the ProcessMaker-specific cli utility
#
COPY cli/ cli/

WORKDIR $PM_CLI_DIR

RUN composer install --optimize-autoloader --no-ansi --no-interaction && \
    composer clear-cache --no-ansi --no-interaction && \
    echo "PM_DIRECTORY=$PM_DIR" > .env && \
    ./pm-cli app:build pm-cli && \
    mv ./builds/pm-cli /usr/local/bin && \
    chmod +x /usr/local/bin/pm-cli && \
    cd .. && rm -rf cli

#
# add the .env variables into a .env file for use later
#
WORKDIR "/"

RUN rm -f "$PM_ENV" && \
    touch "$PM_ENV" && \
    chmod -x "$PM_ENV" && \
    { \
        echo PHP_BINARY=$PHP_BINARY; \
        echo PM_COMPOSER_PACKAGES_PATH=$PM_COMPOSER_PACKAGES_PATH; \
        echo PM_DIR=$PM_DIR; \
        echo PM_CLI_DIR=$PM_CLI_DIR; \
        echo PM_SETUP_DIR=$PM_SETUP_DIR; \
        echo PM_BRANCH=$PM_BRANCH; \
        echo PM_DOCKER_SOCK=$PM_DOCKER_SOCK; \
        echo COMPOSER_ALLOW_SUPERUSER=$COMPOSER_ALLOW_SUPERUSER; \
        echo NVM_DIR=$NVM_DIR; \
        echo NODE_PATH=$NODE_PATH; \
        echo NPX_PATH=$NPX_PATH; \
    } >"$PM_ENV"

#
# container entrypoints
#
COPY entrypoints/web.sh /usr/local/bin/web-entrypoint
COPY entrypoints/queue.sh /usr/local/bin/queue-entrypoint
COPY entrypoints/installer.sh /usr/local/bin/installer-entrypoint
COPY entrypoints/echo.sh /usr/local/bin/echo-entrypoint

RUN chmod +x /usr/local/bin/web-entrypoint && \
    chmod +x /usr/local/bin/queue-entrypoint && \
    chmod +x /usr/local/bin/installer-entrypoint && \
    chmod +x /usr/local/bin/echo-entrypoint

WORKDIR $PM_DIR

ENTRYPOINT ["/bin/bash"]
