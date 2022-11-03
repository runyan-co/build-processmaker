FROM pm-v4-base:latest AS app-env

#
# build args
#
ARG PM_VERSION

#
# pull repo, unzip, copy to working dir
#
RUN rm -rf /home/pm-v4
RUN git clone --single-branch https://github.com/ProcessMaker/processmaker.git /home/pm-v4
WORKDIR /home/pm-v4
RUN git checkout v${PM_VERSION}
COPY .env.example .

#
# composer install
#
RUN COMPOSER_ALLOW_SUPERUSER=1 composer install --optimize-autoloader

#
# laravel echo server
#
COPY stubs/laravel-echo-server.json .

#
# npm install/build
#
RUN npm clean-install --no-audit
RUN npm run dev --no-audit
