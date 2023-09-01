# ProcessMaker v4 with Docker Compose

## Requirements
- macOS >= 12.0.*
- Node 16.18.1
- npm 8.19.2
- Docker Desktop

#### 1. Install basic dependencies and node/npm
Run the following in your console if you don't have the necessary dependencies:
```shell
# make sure xcode is installed
xcode-select --install

# create the default zsh profile dotfile if it doesn't exist
[ ! -f ~/.zshrc ] && touch ~/.zshrc

# install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install --formula jq

# install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash

# install the needed version of node
source ~/.zshrc
nvm install 16.18.1
nvm alias default 16.18.1

# smoke test to make sure we have the right versions installed
node -v
npm -v
```

#### 2. Create a local directory processmaker/processmaker
```shell
mkdir -p ~/repositories
cd ~/repositories
git clone https://github.com/ProcessMaker/processmaker
cd processmaker
# running this will give you the value to set 
# as "PM_APP_SOURCE" in the .env file:
pwd
```

#### 3. Create a local directory for the enterprise composer packages
```shell
mkdir -p ~/packages/composer/processmaker
cd ~/packages/composer/processmaker
# running this will give you the value to set as 
# "PM_COMPOSER_PACKAGES_SOURCE_PATH" in the .env file:
pwd
```

#### 4. Install Docker Desktop
- Download [Docker Desktop](https://www.docker.com/products/docker-desktop/) from their website and follow the installation instructions.
- Under `Settings > Resources > File Sharing` make sure your user directory is shared (it should look like /Users/{YOUR_USERNAME_HERE})

#### 5. Copy the sample build env file to use locally
```shell
cp .env.build .env
```
##### After running this, go through each variable in the `.env` file and set them appropriately.

#### 6. Helper scripts
[ TO DO ]
