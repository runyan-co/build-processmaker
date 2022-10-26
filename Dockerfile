FROM pm-v4-base:latest

#
# build args
#
ARG PM_VERSION

#
# pull repo, unzip, copy to working dir
#
WORKDIR /tmp
RUN wget https://github.com/ProcessMaker/processmaker/archive/refs/tags/v${PM_VERSION}.zip
RUN unzip v${PM_VERSION}.zip
RUN if [ -d /code ]; then rm -rf /code; fi
RUN mkdir -p /code
RUN mv processmaker-${PM_VERSION} pm-v4 && mv pm-v4 /code
WORKDIR /code/pm-v4

#
# composer install
#
RUN COMPOSER_ALLOW_SUPERUSER=1 composer install

#
# laravel echo server
#
COPY build-files/laravel-echo-server.json .

#
# npm install/build
#
RUN npm install --unsafe-perm=true && npm run dev

#
# container entrypoint
#
COPY build-files/init.sh .

#
# entrypoint
#
CMD /bin/bash init && supervisord --nodaemon --loglevel=debug
