#!/bin/bash

#
#  Docker Entrypoint for Forem
#

if [[ "$1" == "bash" ]]; then
    bash
    exit 0
fi

set -e

# Exit

function cleanup {
    printf "${BLACK}${BG_RED} ERROR ${RESET} ${RED}Forem exited! Quitting...${RESET}\n"
}

trap cleanup EXIT

# Colors

RESET="\033[0m"
BLACK="\033[0;30m"
BLUE="\033[1;34m"
RED="\033[1;31m"
YELLOW="\033[1;33m"

BG_CYAN="\033[46m"
BG_RED="\033[41m"
BG_YELLOW="\033[43m"

# Initialize forem

[[ ! -f "/forem/.copied" ]] && rm -rf /forem/*
[[ ! -f "/forem/.copied" ]] && rm -rf /forem/.* || true
if [[ ! -f "/forem/.copied" ]]; then
    for f in $(ls -A /forem-tmp); do
        cp -r "/forem-tmp/${f}" /forem
    done
fi
[[ ! -f "/forem/.copied" ]] && rm -rf /forem-tmp
[[ ! -f "/forem/.copied" ]] && touch /forem/.copied

# Initialize nvm and rbenv

printf "${BLACK}${BG_CYAN} INFO ${RESET} ${BLUE}Initializing programs...${RESET}\n"

source "${HOME}/.bashrc"
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"
. "${S_NVM_DIR}/nvm.sh"

# Set variables

printf "${BLACK}${BG_CYAN} INFO ${RESET} ${BLUE}Checking environment variables...${RESET}\n"

# > process.env.COMMUNITY || DEV(local)
FOREM_COMMUNITY=$(node /get-community.js)
[[ "$FOREM_COMMUNITY" == "DEV(local)" ]] && printf "${BLACK}${BG_CYAN} INFO ${RESET} ${BLUE}Community not specified, setting to default...${RESET}\n"
# > process.env.EMAIL || webmaster@localhost
FOREM_EMAIL=$(node /get-email.js)
[[ "$FOREM_EMAIL" == "webmaster@localhost" ]] && printf "${BLACK}${BG_CYAN} INFO ${RESET} ${BLUE}Email not specified, setting to default...${RESET}\n"
# > process.env.ENVIRONMENT || development
FOREM_ENV=$(node /get-env.js)
[[ "$FOREM_ENV" == "development" ]] && printf "${BLACK}${BG_CYAN} INFO ${RESET} ${BLUE}Environment not specified, setting to development...${RESET}\n"
# > process.env.URL.split("://")[0] + "://" || http://
FOREM_PROTOCOL=$(node /get-proto.js)
[[ "$FOREM_PROTOCOL" == "http://" ]] && printf "${BLACK}${BG_CYAN} INFO ${RESET} ${BLUE}Protocol not specified, setting to default...${RESET}\n"
# > process.env.SECRET || secret
FOREM_OWNER_SECRET=$(node /get-secret.js)
[[ "$FOREM_OWNER_SECRET" == "secret" ]] && printf "${BLACK}${BG_YELLOW} WARN ${RESET} ${YELLOW}Secret not specified! This is insecure! Setting to default and proceeding...${RESET}\n"
# > process.env.URL.split("://")[1] || localhost:3000
FOREM_URL=$(node /get-url.js)
[[ "$FOREM_URL" == "localhost:3000" ]] && printf "${BLACK}${BG_CYAN} INFO ${RESET} ${BLUE}External URL not specified, setting to development...${RESET}\n"

# Set secret key

printf "${BLACK}${BG_CYAN} INFO ${RESET} ${BLUE}Setting default encryption key...${RESET}\n"

FOREM_SECRET_BASE=$(openssl rand -hex 50)

# Set in /forem/.env

printf "${BLACK}${BG_CYAN} INFO ${RESET} ${BLUE}Setting variables in .env (ignore these errors, it's fine)...${RESET}\n"

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

# Prepare services

[[ ! -f "/var/lib/postgresql/13/main/.configured" ]] && printf "${BLACK}${BG_CYAN} INFO ${RESET} ${BLUE}Initializing PostgreSQL...${RESET}\n"

[[ ! -f "/var/lib/postgresql/13/main/.configured" ]] && sudo -u postgres sudo rm -rf /var/lib/postgresql/13/main/*
[[ ! -f "/var/lib/postgresql/13/main/.configured" ]] && sudo -u postgres sudo rm -rf /var/lib/postgresql/13/main/.* || true
[[ ! -f "/var/lib/postgresql/13/main/.configured" ]] && sudo -u postgres /usr/lib/postgresql/13/bin/initdb --encoding=UTF8 -D /var/lib/postgresql/13/main
[[ ! -f "/var/lib/postgresql/13/main/.configured" ]] && touch "/var/lib/postgresql/13/main/.configured"

[[ -d "/elastic-temp" ]] && printf "${BLACK}${BG_CYAN} INFO ${RESET} ${BLUE}Initializing ElasticSearch...${RESET}\n"

[[ -d "/elastic-temp" ]] && cp -r /elastic-temp/* /var/lib/elasticsearch
[[ -d "/elastic-temp" ]] && chmod -R a+rwx /var/lib/elasticsearch
[[ -d "/elastic-temp" ]] && rm -r /elastic-temp

# Start services

printf "${BLACK}${BG_CYAN} INFO ${RESET} ${BLUE}Starting services...${RESET}\n"

service redis-server start
service postgresql start
service elasticsearch start

# Create postgres user

printf "${BLACK}${BG_CYAN} INFO ${RESET} ${BLUE}Creating PostgreSQL user...${RESET}\n"

[[ ! -f "/var/lib/postgresql/13/main/.configured" ]] && sudo -u postgres createuser -s "${S_POSTGRES_USER}"
[[ ! -f "/var/lib/postgresql/13/main/.configured" ]] && sudo -u postgres psql -c "ALTER USER ${S_POSTGRES_USER} WITH PASSWORD '${S_POSTGRES_PASSWORD}';"
[[ ! -f "/var/lib/postgresql/13/main/.configured" ]] && sudo -u postgres psql -c "CREATE DATABASE ${S_POSTGRES_USER};"

# Get more environment variables

printf "${BLACK}${BG_CYAN} INFO ${RESET} ${BLUE}Checking other environment variables...${RESET}\n"

source "/forem/.env"

# Configure forem

printf "${BLACK}${BG_CYAN} INFO ${RESET} ${BLUE}Checking for development environment...${RESET}\n"

FOREM_LOWERCASE_ENV="$(echo "${FOREM_ENV}" | tr '[:upper:]' '[:lower:]')"

if [[ "$FOREM_LOWERCASE_ENV" == "production" ]] && [[ ! -f "/forem/.ready" ]]; then
    printf "${BLACK}${BG_CYAN} INFO ${RESET} ${BLUE}Environment is production.${RESET}\n"

    # Configure Forem

    printf "${BLACK}${BG_CYAN} INFO ${RESET} ${BLUE}Configuring forem...${RESET}\n"

    bin/rails db:create
    bin/setup

    printf "${BLACK}${BG_CYAN} INFO ${RESET} ${BLUE}Compiling webpack assets...${RESET}\n"

    node /webpack-config.js
    bin/webpack

    # Clear database

    printf "${BLACK}${BG_CYAN} INFO ${RESET} ${BLUE}Clearing database...${RESET}\n"

    psql -to truncate.sql -c "SELECT 'TRUNCATE ' || table_name || ';' FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE';"
    psql -f truncate.sql
    pg_dump -v -Fc -s -f forem.dump Forem_development
    dropdb Forem_development
    createdb Forem_development
    pg_restore -v -d Forem_development forem.dump
    dropdb Forem_development
    createdb Forem_development

    printf "${BLACK}${BG_CYAN} INFO ${RESET} ${BLUE}Migrating database...${RESET}\n"

    bin/rails db:migrate

    printf "${BLACK}${BG_CYAN} INFO ${RESET} ${BLUE}Reconfiguring forem...${RESET}\n"

    bin/setup

    [[ ! -f "/forem/.ready" ]] && touch "/forem/.ready"
else
    printf "${BLACK}${BG_YELLOW} WARN ${RESET} ${YELLOW}Environment is development.${RESET}\n"
fi

# Start Forem

printf "${BLACK}${BG_CYAN} INFO ${RESET} ${BLUE}Starting forem...${RESET}\n"

bin/startup
