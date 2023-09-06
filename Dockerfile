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
ARG PM_DOMAIN=processmaker.test
ARG PM_DIR=/var/www/html
ARG PM_SETUP_DIR=/opt/setup
ARG PM_CLI_DIR=/opt/setup/cli
ARG PM_APP_PORT=80
ARG PM_BROADCASTER_PORT=6009
ARG PM_DOCKER_SOCK=/var/run/docker.sock
ARG GITHUB_EMAIL
ARG GITHUB_USERNAME
ARG GITHUB_OAUTH_TOKEN
ARG DOCKERVERSION=20.10.5
ARG INSTALL_DD_TRACER=0
ARG INSTALL_NODE=1

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
ENV PM_COMPOSER_PACKAGES_PATH      "/opt/packages"
ENV PM_ENV                         ".docker.env"
ENV ENV_REALPATH                   "${PM_DIR}/storage/build/.env"
ENV PHP_BINARY                     "/usr/bin/php${PHP_VERSION}"
ENV PHP_FPM_BINARY                 "/usr/sbin/php-fpm${PHP_VERSION}"

COPY cli/ ${PM_CLI_DIR}
COPY stubs/.env.example ${PM_SETUP_DIR}
COPY stubs/composer/config.json ${PM_SETUP_DIR}/config.json
COPY --chmod=+x entrypoints/* /usr/bin
COPY --chmod=+x stubs/helpers/* /usr/bin

RUN apt-get update -y && \
    apt-get install -y --force-yes \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold" \
            software-properties-common curl ca-certificates && \
    apt-add-repository ppa:ondrej/php -y && \
    cleanup_apt

RUN if [ "$INSTALL_NODE" = 1 ]; then install_node && cleanup_apt; fi

RUN apt-get update -y && \
    apt-get install -y --force-yes \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold" \
            wget time vim htop zip unzip mysql-client \
            git pkg-config gcc g++ make python3 python3-pip \
            whois acl jq net-tools build-essential \
            libmcrypt4 libpcre3-dev \
            libpng-dev libmagickwand-dev \
            librdkafka-dev libpcre2-dev && \
    cleanup_apt

RUN apt-get update -y && \
    apt-get install -y --force-yes \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold" \
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
    apt-get upgrade -y && \
    cleanup_apt

RUN git config --global user.name ${GITHUB_USERNAME} && \
    git config --global user.email ${GITHUB_EMAIL}

RUN pecl install rdkafka && \
    setcap "cap_net_bind_service=+ep" /usr/bin/php${PHP_VERSION} && \
    sed -i 's/www-data/root/g' /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
    mkdir -p /run/php && \
    update-alternatives --set php /usr/bin/php${PHP_VERSION}

RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    composer config --global github-oauth.github.com ${GITHUB_OAUTH_TOKEN} && \
    composer config --global --list | grep "\[home\]" | awk '{print $2}' > .composer && \
    mv ${PM_SETUP_DIR}/config.json $(cat .composer)

RUN curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKERVERSION}.tgz && \
    tar xzvf docker-${DOCKERVERSION}.tgz --strip 1 -C /usr/local/bin docker/docker && \
    rm -f docker-${DOCKERVERSION}.tgz && \
    ln -s /usr/local/bin/docker /usr/bin/docker

RUN composer --working-dir=${PM_CLI_DIR} install --optimize-autoloader --no-ansi --no-interaction -v && \
    composer --working-dir=${PM_CLI_DIR} clear-cache --no-ansi --no-interaction -v && \
    echo "PM_DIRECTORY=${PM_DIR}" > ${PM_CLI_DIR}/.env && \
    ${PM_CLI_DIR}/pm-cli app:build pm-cli && \
    mv ${PM_CLI_DIR}/builds/pm-cli /usr/local/bin && \
    chmod +x /usr/local/bin/pm-cli && \
    rm -rf ${PM_SETUP_DIR}/cli

RUN echo "session required pam_limits.so" >>/etc/pam.d/common-session && \
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
      } >"/${PM_ENV}"

#
# copy php config files
#
COPY stubs/php/${PHP_VERSION}/cli/conf.d /etc/php/${PHP_VERSION}/cli/conf.d
COPY stubs/php/${PHP_VERSION}/fpm/conf.d /etc/php/${PHP_VERSION}/fpm/conf.d
COPY stubs/php/${PHP_VERSION}/fpm/pool.d/processmaker.conf /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf

#
# Install the DataDog PHP tracing extension if indicated
# https://docs.datadoghq.com/tracing/trace_collection/dd_libraries/php/?tab=containers#install-the-extension
#
RUN if [ "$INSTALL_DD_TRACER" = 1 ] || [ "$INSTALL_DD_TRACER" = true ]; then install_dd_tracer; fi

WORKDIR ${PM_DIR}

ENTRYPOINT ["/bin/bash"]
