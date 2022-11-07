FROM pm-v4-base:latest AS app-env

#
# build args
#
ARG PM_BRANCH

#
# pull repo, unzip, copy to working dir
#
ENV PM_DIRECTORY "/home/pm-v4"
ENV PM_GIT_REPO_URI "https://github.com/ProcessMaker/processmaker.git"

#
# create the base directory to store our code
#
RUN if [ ! -d "$PM_DIRECTORY" ]; then \
      rm -rf "$PM_DIRECTORY" && mkdir -p "$PM_DIRECTORY"; \
    fi

#
# clone the ProcessMaker repo
#
WORKDIR $PM_DIRECTORY
RUN git clone "$PM_GIT_REPO_URI" . && \
    git checkout ${PM_BRANCH}

#
# bring over the .env.example file
#
COPY .env.example .

#
# composer install
#
RUN composer install --optimize-autoloader

#
# laravel echo server
#
COPY stubs/laravel-echo-server.json .

#
# npm install/build
#
RUN npm clean-install --no-audit
RUN npm run dev --no-progress
