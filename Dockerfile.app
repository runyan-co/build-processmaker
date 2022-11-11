FROM pm-v4-base AS app-env

#
# setup default shell as bash
#
SHELL ["/bin/bash", "-c"]

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
RUN rm -rf "$PM_DIRECTORY" && mkdir -p "$PM_DIRECTORY"

#
# Working dir
#
WORKDIR $PM_DIRECTORY

#
# clone the ProcessMaker repo
#
RUN git clone --filter=tree:0 --branch ${PM_BRANCH} "$PM_GIT_REPO_URI" .

#
# bring over the .env.example file
#
COPY .env.build .

#
# composer install
#
RUN composer install  \
    --no-progress  \
    --no-suggest  \
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
