#!/bin/bash

#
#  Docker Entrypoint for Forem
#

set -e

# Initialize nvm and rbenv

export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"
. "$S_NVM_DIR/nvm.sh"

# Set variables

# > process.env.COMMUNITY || DEV(local)
FOREM_COMMUNITY=$(node /get-community.js)
# > process.env.EMAIL || webmaster@localhost
FOREM_EMAIL=$(node /get-email.js)
# > process.env.ENVIRONMENT || development
FOREM_ENV=$(node /get-env.js)
# > process.env.URL.split("://")[0] + "://" || http://
FOREM_PROTOCOL=$(node /get-proto.js)
# > process.env.SECRET || secret
FOREM_OWNER_SECRET=$(node /get-secret.js)
# > process.env.URL.split("://")[1] || localhost:3000
FOREM_URL=$(node /get-url.js)

# Set secret key

FOREM_SECRET_BASE=$(openssl rand -hex 50)

# Set in /forem/.env

sed -i "s/APP_DOMAIN=\"localhost:3000\"/APP_DOMAIN=\"$FOREM_URL\"/g" /forem/.env || true
sed -i "s/APP_PROTOCOL=\"http:\/\/\"/APP_PROTOCOL=\"$FOREM_PROTOCOL\"/g" /forem/.env || true
sed -i "s/COMMUNITY_NAME=\"DEV(local)\"/COMMUNITY_NAME=\"$FOREM_COMMUNITY\"/g" /forem/.env || true
sed -i "s/DEFAULT_EMAIL=\"yo@dev.to\"/DEFAULT_EMAIL=\"$FOREM_EMAIL\"/g" /forem/.env || true
sed -i "s/FOREM_OWNER_SECRET=\"secret\"/FOREM_OWNER_SECRET=\"$FOREM_OWNER_SECRET\"/g" /forem/.env || true
sed -i "s/RAILS_ENV=\"development\"/RAILS_ENV=\"$FOREM_ENV\"/g" /forem/.env || true
sed -i "s/NODE_ENV=\"development\"/NODE_ENV=\"$FOREM_ENV\"/g" /forem/.env || true
sed -i "s/SESSION_KEY=\"_Dev_Community_Session\"/SESSION_KEY=\"_Forem_Session\"/g" /forem/.env || true
echo "SECRET_KEY_BASE=${FOREM_SECRET_BASE}" >> /forem/.env
sed -i "s/secret_key_base: <%= ENV\[\"SECRET_KEY_BASE\"\] %>/secret_key_base: ${FOREM_SECRET_BASE}/g" /forem/config/secrets.yml

# Start services

service redis-server start
service postgresql start
service elasticsearch start

# Get more environment variables

source /forem/.env

# Configure forem

FOREM_LOWERCASE_ENV=$(echo $FOREM_ENV | tr '[:upper:]' '[:lower:]')
if [[ "$FOREM_LOWERCASE_ENV" == "production" ]]; then
    bin/setup
    node /webpack-config.js
fi

# Start Forem

#bin/startup
concurrently "imgproxy" "bundle exec sidekiq -t 25" "bin/rails s -p 3000 -b 0.0.0.0"