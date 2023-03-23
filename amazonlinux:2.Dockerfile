# syntax=docker/dockerfile:1
FROM amazonlinux:2

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
ENV NODE_VERSION                   16.18.1
ENV PM_APP_PORT                    ${PM_APP_PORT}
ENV PM_BROADCASTER_PORT            ${PM_BROADCASTER_PORT}
ENV PM_DOMAIN                      ${PM_DOMAIN}
ENV PM_DOCKER_SOCK                 ${PM_DOCKER_SOCK}
ENV PM_BRANCH                      ${PM_BRANCH}
ENV PM_DIR                         ${PM_DIR}
ENV PM_SETUP_DIR                   ${PM_SETUP_DIR}
ENV PM_CLI_DIR                     ${PM_CLI_DIR}
ENV PM_COMPOSER_PACKAGES_PATH      /opt/packages
ENV NVM_DIR                        /root/.nvm
ENV PM_ENV                         .docker.env
ENV PHP_BINARY                     "/usr/bin/php${PHP_VERSION}"
ENV PHP_FPM_BINARY                 "/usr/sbin/php-fpm${PHP_VERSION}"
ENV PATH                           "${NVM_DIR}/versions/node/v${NODE_VERSION}/bin:${PATH}"
ENV NODE_PATH                      "${NVM_DIR}/versions/node/v${NODE_VERSION}/lib/node_modules"
ENV NPX_PATH                       "/root/.nvm/versions/node/v${NODE_VERSION}/bin/npx"

RUN mkdir -p ${PM_CLI_DIR}

COPY cli/ ${PM_CLI_DIR}
COPY stubs/.env.example ${PM_SETUP_DIR}
COPY stubs/composer/config.json ${PM_SETUP_DIR}/global-composer-config.json
COPY stubs/php/${PHP_VERSION}/cli/conf.d /etc/php/${PHP_VERSION}/cli/conf.d
COPY stubs/php/${PHP_VERSION}/fpm/conf.d /etc/php/${PHP_VERSION}/fpm/conf.d
COPY stubs/php/${PHP_VERSION}/fpm/pool.d/processmaker.conf /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
COPY --chmod=+x entrypoints/entrypoint.sh /usr/local/bin/entrypoint

#
# Amazon Linux 2 package updates and installs
#
RUN amazon-linux-extras install epel -y && \
    yum update -y && \
    yum install -y https://rpms.remirepo.net/enterprise/remi-release-7.rpm && \
    yum install -y yum-config-manager && \
    yum-config-manager --enable remi-php81 && \
    yum install -y \
        time vim htop curl git zip unzip wget mysql gcc-c++ \
        pcre-devel make python3 python3-pip whois acl \
        libpng-devel ImageMagick-devel pcre2-devel jq \
        net-tools groupinstall "Development Tools" \
        ca-certificates nginx supervisor \
        php${PHP_VERSION} \
        php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-common \
        php${PHP_VERSION}-mysqlnd \
        php${PHP_VERSION}-zip \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-pecl-imagick \
        php${PHP_VERSION}-dom \
        php${PHP_VERSION}-sqlite3 \
        php${PHP_VERSION}-imap \
        php${PHP_VERSION}-redis \
        php${PHP_VERSION}-devel \
        php${PHP_VERSION}-mysqlnd \
        php${PHP_VERSION}-soap \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-readline \
        php${PHP_VERSION}-msgpack \
        php${PHP_VERSION}-igbinary \
        php${PHP_VERSION}-gmp && \
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
    rm -rf "${NVM_DIR}" &&  \
    mkdir -p "${NVM_DIR}" && \
    cp "${HOME}/.bashrc" "${HOME}/.bashrc.bak" && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash && \
    chmod 0755 "${NVM_DIR}/nvm.sh" && \
    ln -s "${NVM_DIR}/nvm.sh" /usr/bin/nvm && \
    nvm install --default --no-progress "${NODE_VERSION}" && \
    ln -s "${NVM_DIR}/versions/node/v${NODE_VERSION}/bin/node /usr/bin/node" && \
    ln -s "${NVM_DIR}/versions/node/v${NODE_VERSION}/bin/npm /usr/bin/npm" && \
    ln -s "${NVM_DIR}/versions/node/v${NODE_VERSION}/bin/npx /usr/bin/npx" && \
    ln -s "${NVM_DIR}/versions/node/v${NODE_VERSION}/bin/corepack /usr/bin/corepack" && \
    nvm alias default "${NODE_VERSION}" && \
    nvm use default && \
    nvm cache clear && \
    nvm unload && \
    cp "${HOME}/.bashrc.bak" "${HOME}/.bashrc" && \
    composer config --global --list | grep "\[home\]" | awk '{print $2}' > .composer && \
    mv ${PM_SETUP_DIR}/global-composer-config.json $(cat .composer) && \
    cd "${PM_CLI_DIR}" && composer install --optimize-autoloader --no-ansi --no-interaction && \
    cd "${PM_CLI_DIR}" && composer clear-cache --no-ansi --no-interaction && \
    cd "${PM_CLI_DIR}" && echo "PM_DIRECTORY=$PM_DIR" > .env && \
    cd "${PM_CLI_DIR}" && ./pm-cli app:build pm-cli && \
    cd "${PM_CLI_DIR}" && mv ./builds/pm-cli /usr/local/bin && \
    cd "${PM_CLI_DIR}" && chmod +x /usr/local/bin/pm-cli && \
    cd "${PM_SETUP_DIR}" && rm -rf cli && \
    rm -f "/${PM_ENV}" && \
    touch "/${PM_ENV}" && \
    chmod -x "/${PM_ENV}" && \
      { \
        echo PHP_BINARY=$PHP_BINARY; \
        echo PM_COMPOSER_PACKAGES_PATH=$PM_COMPOSER_PACKAGES_PATH; \
        echo PM_DIR=$PM_DIR; \
        echo PM_CLI_DIR=${PM_CLI_DIR}; \
        echo PM_SETUP_DIR=${PM_SETUP_DIR}; \
        echo PM_BRANCH=${PM_BRANCH}; \
        echo PM_DOCKER_SOCK=${PM_DOCKER_SOCK}; \
        echo COMPOSER_ALLOW_SUPERUSER=${COMPOSER_ALLOW_SUPERUSER}; \
        echo NVM_DIR=${NVM_DIR}; \
        echo NODE_PATH=${NODE_PATH}; \
        echo NPX_PATH=${NPX_PATH}; \
      } >"/${PM_ENV}" && \
    amazon-linux-extras install -y epel && \
    yum autoremove -y && \
    yum clean all && \
    rm -rf /var/cache/* /var/lib/yum/* /tmp/* /var/tmp/* && \
    echo "DefaultLimitNOFILE=65536" >>/etc/systemd/system.conf && \
    echo "session required pam_limits.so" >>/etc/pam.d/common-session && \
    echo "root soft nofile 65536" >>/etc/security/limits.conf && \
    echo "root hard nofile 65536" >>/etc/security/limits.conf && \
    sysctl --system

WORKDIR ${PM_DIR}

ENTRYPOINT ["/bin/bash"]
