# syntax=docker/dockerfile:1
FROM ubuntu:22.04

#
# Set bash as the default shell
#
SHELL ["/bin/bash", "-oeux", "pipefail", "-c"]

#
# work in the temp dir to keep the image size low
#
WORKDIR /tmp

#
# Build arguments
#
ARG PM_BRANCH
ARG PM_DOMAIN=localhost
ARG PM_DIR=/var/www/html
ARG PM_SETUP_DIR=/opt/setup
ARG PM_CLI_DIR=/opt/setup/cli
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
ENV NODE_VERSION                   16
ENV DEBIAN_FRONTEND                noninteractive
ENV PM_APP_PORT                    ${PM_APP_PORT}
ENV PM_BROADCASTER_PORT            ${PM_BROADCASTER_PORT}
ENV PM_DOMAIN                      ${PM_DOMAIN}
ENV PM_DOCKER_SOCK                 ${PM_DOCKER_SOCK}
ENV PM_BRANCH                      ${PM_BRANCH}
ENV PM_DIR                         ${PM_DIR}
ENV PM_SETUP_DIR                   ${PM_SETUP_DIR}
ENV PM_CLI_DIR                     ${PM_CLI_DIR}
ENV PM_COMPOSER_PACKAGES_PATH      /opt/packages
ENV PM_ENV                         .docker.env
ENV PHP_BINARY                     "/usr/bin/php${PHP_VERSION}"
ENV PHP_FPM_BINARY                 "/usr/sbin/php-fpm${PHP_VERSION}"

COPY cli/ ${PM_CLI_DIR}
COPY stubs/.env.example ${PM_SETUP_DIR}
COPY stubs/composer/config.json ${PM_SETUP_DIR}/config.json
COPY --chmod=+x entrypoints/* /usr/bin

#
# debian package updates and installs
#
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y --force-yes software-properties-common curl && \
    curl -sL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash && \
    apt-get update -y && \
    apt-add-repository ppa:ondrej/php -y && \
    apt-get update -y && \
    apt-get install -y --force-yes \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold" \
            time vim htop git zip unzip wget mysql-client pkg-config \
            gcc g++ libmcrypt4 libpcre3-dev make python3 python3-pip \
            whois acl libpng-dev libmagickwand-dev librdkafka-dev libpcre2-dev \
            jq net-tools build-essential ca-certificates nodejs \
            php${PHP_VERSION} \
            php${PHP_VERSION}-fpm \
            php${PHP_VERSION}-cli \
            php${PHP_VERSION}-common \
            php${PHP_VERSION}-mysql \
            php${PHP_VERSION}-zip \
            php${PHP_VERSION}-gd \
            php${PHP_VERSION}-mbstring \
            php${PHP_VERSION}-curl \
            php${PHP_VERSION}-xml \
            php${PHP_VERSION}-bcmath \
            php${PHP_VERSION}-imagick \
            php${PHP_VERSION}-dom \
            php${PHP_VERSION}-sqlite3 \
            php${PHP_VERSION}-imap \
            php${PHP_VERSION}-redis \
            php${PHP_VERSION}-dev \
            php${PHP_VERSION}-mysql \
            php${PHP_VERSION}-soap \
            php${PHP_VERSION}-intl \
            php${PHP_VERSION}-readline \
            php${PHP_VERSION}-msgpack \
            php${PHP_VERSION}-igbinary \
            php${PHP_VERSION}-gmp && \
    pecl install rdkafka && \
    git config --global user.name ${GITHUB_USERNAME} && \
    git config --global user.email ${GITHUB_EMAIL} && \
    setcap "cap_net_bind_service=+ep" /usr/bin/php${PHP_VERSION} && \
    sed -i 's/www-data/root/g' /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
    mkdir -p /run/php && \
    update-alternatives --set php /usr/bin/php${PHP_VERSION} && \
    curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    composer config --global github-oauth.github.com ${GITHUB_OAUTH_TOKEN} && \
    curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKERVERSION}.tgz && \
    tar xzvf docker-${DOCKERVERSION}.tgz --strip 1 -C /usr/local/bin docker/docker && \
    rm -f docker-${DOCKERVERSION}.tgz && \
    ln -s /usr/local/bin/docker /usr/bin/docker && \
    composer config --global --list | grep "\[home\]" | awk '{print $2}' > .composer && \
    mv ${PM_SETUP_DIR}/config.json $(cat .composer) && \
    composer --working-dir=${PM_CLI_DIR} install --optimize-autoloader --no-ansi --no-interaction -v && \
    composer --working-dir=${PM_CLI_DIR} clear-cache --no-ansi --no-interaction -v && \
    echo "PM_DIRECTORY=${PM_DIR}" > ${PM_CLI_DIR}/.env && \
    ${PM_CLI_DIR}/pm-cli app:build pm-cli && \
    mv ${PM_CLI_DIR}/builds/pm-cli /usr/local/bin && \
    chmod +x /usr/local/bin/pm-cli && \
    rm -rf ${PM_SETUP_DIR}/cli && \
    rm -f "/${PM_ENV}" && \
    touch "/${PM_ENV}" && \
    chmod -x "/${PM_ENV}" && \
      { \
        echo PHP_BINARY=${PHP_BINARY}; \
        echo PM_COMPOSER_PACKAGES_PATH=${PM_COMPOSER_PACKAGES_PATH}; \
        echo PM_DIR=${PM_DIR}; \
        echo PM_CLI_DIR=${PM_CLI_DIR}; \
        echo PM_SETUP_DIR=${PM_SETUP_DIR}; \
        echo PM_BRANCH=${PM_BRANCH}; \
        echo PM_DOCKER_SOCK=${PM_DOCKER_SOCK}; \
        echo COMPOSER_ALLOW_SUPERUSER=${COMPOSER_ALLOW_SUPERUSER}; \
        echo NODE_PATH=$(which node); \
        echo NPX_PATH=$(which npx); \
        echo NPM_PATH=$(which npm); \
      } >"/${PM_ENV}" && \
    echo "session required pam_limits.so" >>/etc/pam.d/common-session && \
    sysctl --system && \
    apt-get autoremove -y && \
    apt-get purge -y && \
    apt-get clean && \
    rm -rf /var/cache/* /var/lib/apt/lists/* /tmp/* /var/tmp/*

#
# copy php config files
#
COPY stubs/php/${PHP_VERSION}/cli/conf.d /etc/php/${PHP_VERSION}/cli/conf.d
COPY stubs/php/${PHP_VERSION}/fpm/conf.d /etc/php/${PHP_VERSION}/fpm/conf.d
COPY stubs/php/${PHP_VERSION}/fpm/pool.d/processmaker.conf /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf

#
# copy a script which installs the datadog
# APM tracer/profiler for PHP and Node
#
COPY scripts/install-dd-tracer.sh .
#RUN bash install-dd-tracer.sh

WORKDIR ${PM_DIR}

ENTRYPOINT ["/bin/bash"]
