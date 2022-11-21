# syntax=docker/dockerfile:1
FROM ubuntu:22.04 AS base

#
# Set bash as the default shell
#
SHELL ["/bin/bash", "-c"]

#
# Build arguments
#
ARG PM_DOCKER_SOCK
ARG GITHUB_EMAIL
ARG GITHUB_USERNAME
ARG GITHUB_OAUTH_TOKEN
ARG DOCKERVERSION=20.10.5

#
# environment vars
#
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV DEBIAN_FRONTEND          noninteractive
ENV PHP_VERSION              8.1
ENV NODE_VERSION             16.18.1
ENV PM_APP_PORT              8080
ENV PM_BROADCASTER_PORT      6004
ENV PM_DOMAIN                localhost
ENV PM_DOCKER_SOCK           ${PM_DOCKER_SOCK}

#
# debian package updates and installs
#
RUN apt-get update -y && \
    apt-get install -y --force-yes software-properties-common && \
    apt-get update -y && \
    apt-add-repository ppa:ondrej/php -y && \
    apt-get update -y && \
    apt-get install -y --force-yes \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold" \
            vim htop curl git zip unzip wget supervisor mysql-client build-essential \
            pkg-config gcc g++ libmcrypt4 libpcre3-dev make python3 python3-pip whois acl \
            libpng-dev libmagickwand-dev libpcre2-dev jq net-tools \
            php8.1 php8.1-cli php8.1-common php8.1-mysql php8.1-zip php8.1-gd \
            php8.1-mbstring php8.1-curl php8.1-xml php8.1-bcmath php8.1-imagick php8.1-dom \
            php8.1-sqlite3 php8.1-imap php8.1-redis php8.1-dev php8.1-mysql php8.1-soap \
            php8.1-intl php8.1-readline php8.1-msgpack php8.1-igbinary php8.1-gmp && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#
# Git
#
RUN git config --global user.name ${GITHUB_USERNAME} && \
    git config --global user.email ${GITHUB_EMAIL}

#
# copy php config files
#
COPY stubs/php/8.1/cli/conf.d /etc/php/8.1/cli/conf.d

#
# set the php binary env var
#
ENV PHP_BINARY=/usr/bin/php8.1

#
# misc. php config setup
#
RUN sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/8.1/cli/php.ini && \
    sed -i "s/display_errors = .*/display_errors = On/" /etc/php/8.1/cli/php.ini && \
    sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/8.1/cli/php.ini && \
    sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/8.1/cli/php.ini && \
    sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/8.1/cli/php.ini && \
    setcap "cap_net_bind_service=+ep" /usr/bin/php8.1 && \
    mkdir -p /run/php && \
    update-alternatives --set php "$PHP_BINARY"

#
# composer setup
#
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    composer config --global github-oauth.github.com ${GITHUB_OAUTH_TOKEN}

#
# node version manager setup
#
ENV NVM_DIR "/root/.nvm"

RUN rm -rf "$NVM_DIR" && mkdir -p "$NVM_DIR" && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | sh && \
    chmod 0755 "$NVM_DIR/nvm.sh" && \
    ln -s "$NVM_DIR/nvm.sh" /usr/local/bin/nvm && \
    nvm install "$NODE_VERSION" && \
    nvm alias default "$NODE_VERSION" && \
    nvm use default

ENV NODE_PATH "$NVM_DIR/versions/node/v$NODE_VERSION/lib/node_modules"
ENV PATH      "$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH"
ENV NPX_PATH  "$NVM_DIR/versions/node/v$NODE_VERSION/bin/npx"

#
# docker client
#
RUN curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKERVERSION}.tgz && \
    tar xzvf docker-${DOCKERVERSION}.tgz --strip 1 -C /usr/local/bin docker/docker && \
    rm -f docker-${DOCKERVERSION}.tgz && \
    ln -s /usr/local/bin/docker /usr/bin/docker

RUN sysctl --system

#
# App
#
FROM base AS app

#
# build args
#
ARG PM_BRANCH

#
# pull repo, unzip, copy to working dir
#
ENV PM_DIRECTORY "/home/pm-v4"
ENV PM_BRANCH ${PM_BRANCH}
ENV PM_GIT_REPO_URI "https://github.com/ProcessMaker/processmaker.git"

#
# create the base directory to store our code
#
RUN rm -rf "$PM_DIRECTORY" && \
    mkdir -p "$PM_DIRECTORY"

#
# Working dir
#
WORKDIR $PM_DIRECTORY

#
# clone the ProcessMaker repo
#
RUN git clone --filter=tree:0 --branch ${PM_BRANCH} "$PM_GIT_REPO_URI" . && \
    rm .env.example

#
# bring over the .env.example file
#
COPY ./stubs/.env.example .

#
# Move composer.json over to storage and then link it
#
RUN mv composer.json "$PM_DIRECTORY/storage" && \
    ln -s "$PM_DIRECTORY/storage/composer.json" . && \
    composer install  \
        --profile \
        --no-progress  \
        --optimize-autoloader  \
        --no-ansi  \
        --no-interaction && \
    composer clear-cache --no-ansi --no-interaction

#
# laravel echo server
#
COPY stubs/laravel-echo-server.json .

#
# npm install/build
#
RUN npm clean-install --no-audit && \
    npm run dev --no-progress && \
    npm cache clear --force

#
# App build stage
#
FROM app AS packages

#
# build args
#
ARG PM_BRANCH
ARG PM_INSTALL_ENTERPRISE_PACKAGES

#
# env variable setup
#
ENV PM_COMPOSER_PACKAGES_PATH "/opt/composer-packages"
ENV PM_SETUP_PATH "/opt/processmaker-setup"
ENV PM_INSTALL_ENTERPRISE_PACKAGES ${PM_INSTALL_ENTERPRISE_PACKAGES}

#
# copy ProcessMaker-authored composer packages over
#
RUN rm -rf "$PM_COMPOSER_PACKAGES_PATH"
COPY packages/ "$PM_COMPOSER_PACKAGES_PATH"

#
# find the location for the global composer config
#
WORKDIR /tmp
COPY stubs/composer/config.json .
RUN composer config --global --list | grep "\[home\]" | awk '{print $2}' > .composer && \
    mv config.json $(cat .composer)

#
# create the ProcessMaker setup directory, which
# we will use to store various build scripts,
# config files, and other usefil tools/files
#
RUN rm -rf "$PM_SETUP_PATH" && \
    mkdir -p "$PM_SETUP_PATH"

WORKDIR $PM_SETUP_PATH
COPY scripts/ scripts/

RUN chmod -x ./scripts/*.php &&\
    cd scripts/ &&  \
    composer install --optimize-autoloader --no-ansi --no-interaction && \
    composer clear-cache --no-ansi --no-interaction

#
# add the .env variables into a .env file for use later
#
WORKDIR "/"

ENV PM_ENV ".docker.env"

RUN rm -f "$PM_ENV" && \
    touch "$PM_ENV" && \
    chmod -x "$PM_ENV" && \
    { \
        echo PHP_BINARY=$PHP_BINARY; \
        echo PM_COMPOSER_PACKAGES_PATH=$PM_COMPOSER_PACKAGES_PATH; \
        echo PM_SETUP_PATH=$PM_SETUP_PATH; \
        echo PM_DIRECTORY=$PM_DIRECTORY; \
        echo PM_BRANCH=$PM_BRANCH; \
        echo PM_DOCKER_SOCK=$PM_DOCKER_SOCK; \
        echo COMPOSER_ALLOW_SUPERUSER=$COMPOSER_ALLOW_SUPERUSER; \
        echo NVM_DIR=$NVM_DIR; \
        echo NODE_PATH=$NODE_PATH; \
        echo NPX_PATH=$NPX_PATH; \
    } >"$PM_ENV"

WORKDIR $PM_DIRECTORY

#
# Installer-type build
#
FROM packages AS installer

#
# container entrypoint
#
COPY ./entrypoints/installer.sh /usr/local/bin/installer.sh
RUN chmod +x /usr/local/bin/installer.sh

#
# entrypoint
#
CMD ["/usr/local/bin/installer.sh"]

#
# Web-service Build
#
FROM packages AS web

#
# php-fpm limit defaults (these get written at entrypoint startup)
#
ENV FPM_PM_MAX_CHILDREN 20
ENV FPM_PM_START_SERVERS 2
ENV FPM_PM_MIN_SPARE_SERVERS 1
ENV FPM_PM_MAX_SPARE_SERVERS 3

#
# cleanup to save space
#
RUN rm -rf node_modules/ && \
    rm -rf /var/cache/*

#
# install nginx and cron
#
RUN apt-add-repository ppa:ondrej/nginx -y && \
    apt-get install -y --force-yes \
      -o Dpkg::Options::="--force-confdef" \
      -o Dpkg::Options::="--force-confold" \
        php8.1-fpm nginx cron && \
    apt-get autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#
# Setup php-fpm
#
RUN sed -i 's/www-data/root/g' /etc/php/8.1/fpm/pool.d/www.conf && \
    sed -i "s/display_errors = .*/display_errors = Off/" /etc/php/8.1/fpm/php.ini

#
# Write the php-fpm config
#
RUN { \
  echo pm.max_children = "$FPM_PM_MAX_CHILDREN"; \
  echo pm.start_servers = "$FPM_PM_START_SERVERS"; \
  echo pm.min_spare_servers = "$FPM_PM_MIN_SPARE_SERVERS"; \
  echo pm.max_spare_servers = "$FPM_PM_MAX_SPARE_SERVERS"; \
} >/etc/php/8.1/fpm/conf.d/100-processmaker.conf

#
# cron and nginx config
#
COPY stubs/laravel-cron /etc/cron.d/laravel-cron

RUN chmod 0644 /etc/cron.d/laravel-cron &&  \
    crontab /etc/cron.d/laravel-cron && \
    mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak && \
    mkdir -p /var/log/nginx && \
    touch /var/log/nginx/error.log

COPY stubs/nginx.conf /etc/nginx/nginx.conf


#
# supervisord
#
COPY stubs/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

#
# container entrypoint
#
COPY ./entrypoints/web.sh /usr/local/bin/web.sh
RUN chmod +x /usr/local/bin/web.sh

#
# Healthcheck setup
#
HEALTHCHECK --interval=5s --timeout=3s \
  CMD curl -f "http://$PM_DOMAIN/ping" || exit 1

#
# entrypoint
#
CMD ["/usr/local/bin/web.sh"]

#
# Queue-type build
#
FROM packages AS queue

#
# container entrypoint
#
COPY ./entrypoints/queue.sh /usr/local/bin/queue.sh
RUN chmod +x /usr/local/bin/queue.sh

#
# entrypoint
#
CMD ["/usr/local/bin/queue.sh"]
