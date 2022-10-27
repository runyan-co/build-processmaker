FROM pm-v4-base:latest AS app-env

#
# build args
#
ARG PM_VERSION

#
# pull repo, unzip, copy to working dir
#
RUN rm -rf /home/pm-v4 && mkdir -p /home/pm-v4
WORKDIR /home
RUN git clone https://github.com/ProcessMaker/processmaker.git pm-v4
WORKDIR /home/pm-v4
RUN git checkout v${PM_VERSION}
COPY .env .env.example

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
RUN npm clean-install --no-audit --unsafe-perm=true && \
    npm run dev

#
# container entrypoint
#
RUN mkdir -p /home/pm-v4-docker
WORKDIR /home/pm-v4-docker
COPY ./init.sh entrypoint
RUN chmod 0755 entrypoint && ln -s /home/pm-v4-docker/entrypoint /usr/local/bin/entrypoint

#
# entrypoint
#
WORKDIR /home/pm-v4
CMD ["/usr/local/bin/entrypoint"]
