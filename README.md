# ProcessMaker v4 with Docker Compose
Build a docker image `processmaker:version` using a specific branch of [processmaker/processmaker](https://github.com/ProcessMaker/processmaker). 
### Getting started:
Copy the example `.env.build` to `.env` and fill out the variables:
```dotenv
# Absolute path to local docker socket
PM_DOCKER_SOCK=/var/run/docker.sock
# Domain name to be used for the containers
# (you shouldn't need to change this)
PM_DOMAIN=localhost
# Host port mapped to web container for port 80 traffic
PM_APP_PORT=8080
# Host port mapped to web container for port 6001 traffic
PM_BROADCASTER_PORT=6004
# Valid branch name to build and install the containers with.
# Note: version of the branch must be >= 4.3.*
PM_BRANCH=
# The tag to use for the built image
PM_IMAGE_NAME=
# Instructs the installer service whether or not to 
# install the enterprise packages
INSTALL_ENTERPRISE_PACKAGES=true
# Absolute path to the ProcessMaker directory in the 
# containers. You very likely will NOT need to change this
PM_DIR=/var/www/html
# The absolute path to directory containing all local
# versions of enterprise ProcessMaker composer 
# packages on the HOST machine
PM_COMPOSER_PACKAGES_SOURCE_PATH=
# The absolute path to the directory containing 
# the core ProcessMaker code on the HOST machine
PM_APP_SOURCE=
# Fill out the GitHib variables with a valid GitHub 
# personal OAuth token, your username, and email
GITHUB_OAUTH_TOKEN=
GITHUB_USERNAME=
GITHUB_EMAIL=
```
Then run `docker compose up -d --build`. When it's finished building, watch the output of the `processmaker-installer` service container.

Once complete, the app will be available at `http://localhost:8080`
