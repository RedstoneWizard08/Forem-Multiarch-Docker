# ------------------------ ImageMagick ------------------------

# FROM ubuntu:21.10 as imagemagick_builder

# ENV DEBIAN_FRONTEND=noninteractive
# ENV TZ=America/Los_Angeles
# ENV LC_ALL=C

# ARG IMAGEMAGICK_SOURCE="ImageMagick/ImageMagick"
# ARG IMAGEMAGICK_BRANCH=main

# RUN apt-get update && \
#     apt-get -y upgrade && \
#     apt-get -y install build-essential \
#     checkinstall libx11-dev libxext-dev \
#     zlib1g-dev libpng-dev libjpeg-dev \
#     libfreetype6-dev libxml2-dev libltdl-dev \
#     pkg-config make cmake gcc g++ libjemalloc-dev \
#     libreadline6-dev tcl fondu ghostscript libfreetype-dev \
#     ghostscript-x bash sudo git && \
#     git clone https://github.com/${IMAGEMAGICK_SOURCE}.git -b ${IMAGEMAGICK_BRANCH} $HOME/ImageMagick && \
#     cd $HOME/ImageMagick && \
#     ./configure --with-modules && \
#     make && \
#     make check || true && \
#     make install && \
#     ldconfig /usr/local/lib && \
#     magick identify -version && \
#     cd $HOME && \
#     rm -r ImageMagick

# ------------------------ Redis ------------------------

FROM ubuntu:21.10 as redis_builder

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Los_Angeles
ENV LC_ALL=C

ARG REDIS_SOURCE="redis/redis"
ARG REDIS_BRANCH="6.2"

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install software-properties-common \
    apt-transport-https gnupg-agent apt git build-essential \
    libltdl-dev pkg-config make cmake gcc g++ libjemalloc-dev \
    libreadline6-dev tcl checkinstall libx11-dev libxext-dev \
    zlib1g-dev bash sudo && \
    apt-get -y install redis-server && \
    sed -i 's/protected-mode\ yes/protected-mode\ no/g' /etc/redis/redis.conf && \
    git clone https://github.com/${REDIS_SOURCE} -b ${REDIS_BRANCH} $HOME/redis && \
    cd $HOME/redis && \
    cd deps/lua && \
    make linux && \
    make test && \
    cd ../hiredis && \
    make && \
    service redis-server start && \
    make test && \
    service redis-server stop && \
    cd ../linenoise && \
    make && \
    cd ../hdr_histogram && \
    make && \
    cd ../jemalloc && \
    ./configure && \
    make && \
    cd ../.. && \
    make && \
    make test && \
    make install && \
    sed -i 's/ExecStart\=\/usr\/bin\/redis-server\ \/etc\/redis\/redis.conf\ \-\-supervised\ systemd\ \-\-daemonize\ no/ExecStart\=\/usr\/local\/bin\/redis-server\ \/etc\/redis\/redis.conf\ \-\-daemonize\ no/g' /lib/systemd/system/redis-server.service && \
    cd $HOME && \
    rm -r redis

# ------------------------ ImgProxy ------------------------

FROM ubuntu:21.10 as imgproxy_builder

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Los_Angeles
ENV LC_ALL=C

ARG IMGPROXY_SOURCE="imgproxy/imgproxy"
ARG IMGPROXY_BRANCH=master

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install software-properties-common \
    apt-transport-https gnupg-agent apt git bash sudo && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E2B7D64D93330B78 && \
    add-apt-repository -y "deb http://ppa.launchpad.net/dhor/myway/ubuntu focal main" && \
    add-apt-repository -y ppa:longsleep/golang-backports && \
    git clone https://github.com/${IMGPROXY_SOURCE} -b ${IMGPROXY_BRANCH} $HOME/imgproxy && \
    cd $HOME/imgproxy && \
    apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install libvips-dev golang-go && \
    CGO_LDFLAGS_ALLOW="-s|-w" go build -o /usr/local/bin/imgproxy && \
    cd $HOME && \
    rm -r imgproxy

# ------------------------ Base OS ------------------------

FROM ubuntu:21.10 as forem

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Los_Angeles
ENV LC_ALL=C

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install sudo bash \
    lsb-release wget curl gnupg-agent \
    ca-certificates software-properties-common \
    apt python3 kmod git apt-transport-https \
    autoconf bison build-essential libssl-dev \
    libyaml-dev libreadline6-dev zlib1g-dev \
    libncurses5-dev libffi-dev libgdbm-dev net-tools \
    iproute2 nano

SHELL [ "/bin/bash", "-c" ]

# ------------------------ Variables ------------------------

ARG POSTGRES_USER=root
ARG POSTGRES_PASSWORD=root

ARG NVM_VERSION=0.39.1
ARG NVM_DIR=/usr/lib/nvm

ARG ELASTICSEARCH_VERSION=7.8.0

ARG FOREM_SOURCE="RedstoneWizard08/forem"
ARG FOREM_BRANCH=main

# ------------------------ Copy files from ImageMagick builder ------------------------

#COPY --from=imagemagick_builder /usr/local/lib/* /usr/local/lib
#COPY --from=imagemagick_builder /usr/local/share/doc/ImageMagick-7 /usr/local/share/doc
#COPY --from=imagemagick_builder /usr/local/etc/ImageMagick-7 /usr/local/etc
#COPY --from=imagemagick_builder /usr/local/include/ImageMagick-7 /usr/local/include
#COPY --from=imagemagick_builder /usr/local/bin/* /usr/local/bin

RUN apt-get -y install imagemagick && \
#    rm /usr/local/lib/libMagick++-7.Q16HDRI.so \
#    /usr/local/lib/libMagick++-7.Q16HDRI.so.5 \
#    /usr/local/lib/libMagickCore-7.Q16HDRI.so \
#    /usr/local/lib/libMagickCore-7.Q16HDRI.so.10 \
#    /usr/local/lib/libMagickWand-7.Q16HDRI.so \
#    /usr/local/lib/libMagickWand-7.Q16HDRI.so.10 && \
#    ln -s /usr/local/lib/libMagick++-7.Q16HDRI.so.5.0.0 /usr/local/lib/libMagick++-7.Q16HDRI.so && \
#    ln -s /usr/local/lib/libMagick++-7.Q16HDRI.so.5.0.0 /usr/local/lib/libMagick++-7.Q16HDRI.so.5 && \
#    ln -s /usr/local/lib/libMagickCore-7.Q16HDRI.so.10.0.0 /usr/local/lib/libMagickCore-7.Q16HDRI.so && \
#    ln -s /usr/local/lib/libMagickCore-7.Q16HDRI.so.10.0.0 /usr/local/lib/libMagickCore-7.Q16HDRI.so.10 && \
#    ln -s /usr/local/lib/libMagickWand-7.Q16HDRI.so.10.0.0 /usr/local/lib/libMagickWand-7.Q16HDRI.so && \
#    ln -s /usr/local/lib/libMagickWand-7.Q16HDRI.so.10.0.0 /usr/local/lib/libMagickWand-7.Q16HDRI.so.10 && \
#    ldconfig /usr/local/lib && \
    magick identify -version

# ------------------------ Copy files from Redis builder ------------------------

COPY --from=redis_builder /usr/local/bin/redis-benchmark /usr/local/bin
COPY --from=redis_builder /usr/local/bin/redis-check-aof /usr/local/bin
COPY --from=redis_builder /usr/local/bin/redis-check-rdb /usr/local/bin
COPY --from=redis_builder /usr/local/bin/redis-cli /usr/local/bin
COPY --from=redis_builder /usr/local/bin/redis-sentinel /usr/local/bin
COPY --from=redis_builder /usr/local/bin/redis-server /usr/local/bin

COPY --from=redis_builder /etc/redis/redis.conf /etc/redis/redis.conf
COPY --from=redis_builder /lib/systemd/system/redis-server.service /lib/systemd/system/redis-server.service

RUN yes O | apt-get -y install redis-server
RUN rm /usr/bin/redis-server \
    /usr/bin/redis-benchmark \
    /usr/bin/redis-check-aof \
    /usr/bin/redis-check-rdb \
    /usr/bin/redis-cli && \
    redis-server --version && \
    redis-cli --version

# ------------------------ Copy files from ImgProxy builder ------------------------

COPY --from=imgproxy_builder /usr/local/bin/imgproxy /usr/local/bin

# ------------------------ Ruby & Rails ------------------------

RUN git clone https://github.com/rbenv/rbenv.git $HOME/.rbenv && \
    git clone https://github.com/rbenv/ruby-build.git $HOME/.rbenv/plugins/ruby-build && \
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> $HOME/.bashrc && \
    echo 'eval "$(rbenv init -)"' >> $HOME/.bashrc && \
    export RUBY_VERSION=$(curl -fsSL https://raw.githubusercontent.com/${FOREM_SOURCE}/${FOREM_BRANCH}/.ruby-version) && \
    export PATH="$HOME/.rbenv/bin:$PATH" && \
    eval "$(rbenv init -)" && \
    rbenv install ${RUBY_VERSION} && \
    rbenv global ${RUBY_VERSION} && \
    gem install bundler

# ------------------------ Node.js & Yarn ------------------------

RUN mkdir -p ${NVM_DIR} && \
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash && \
    export NODE_VERSION=$(curl -fsSL https://raw.githubusercontent.com/${FOREM_SOURCE}/${FOREM_BRANCH}/.nvmrc) && \
    . "${NVM_DIR}/nvm.sh" && \
    nvm install $NODE_VERSION && \
    nvm use $NODE_VERSION && \
    npm install --global yarn@latest npm@latest concurrently@latest && \
    corepack enable

# ------------------------ PostgreSQL ------------------------

RUN apt-get -y install postgresql \
    postgresql-contrib libpq-dev && \
    service postgresql start && \
    sudo -u postgres createuser -s ${POSTGRES_USER} && \
    sudo -u postgres psql -c "ALTER USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}';" && \
    sudo -u postgres psql -c "CREATE DATABASE ${POSTGRES_USER};"

# ------------------------ Elasticsearch ------------------------

RUN wget "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-oss-${ELASTICSEARCH_VERSION}-$(dpkg --print-architecture).deb" && \
    apt-get -y install "./elasticsearch-oss-${ELASTICSEARCH_VERSION}-$(dpkg --print-architecture).deb" && \
    rm "elasticsearch-oss-${ELASTICSEARCH_VERSION}-$(dpkg --print-architecture).deb"

# ------------------------ Volumes ------------------------

VOLUME [ "/var/lib/postgresql/13/main" ]
VOLUME [ "/var/lib/redis" ]
VOLUME [ "/var/lib/elasticsearch" ]

# ------------------------ Forem ------------------------

RUN apt-get -y install libcurl4 \
    libcurl4-openssl-dev libcairo2-dev \
    libpango1.0-dev libgif-dev librsvg2-dev && \
    git clone https://github.com/${FOREM_SOURCE}.git -b ${FOREM_BRANCH} /forem

WORKDIR /forem

# ------------------------ Install Forem dependencies ------------------------

RUN export PATH="$HOME/.rbenv/bin:$PATH" && \
    eval "$(rbenv init -)" && \
    . "${NVM_DIR}/nvm.sh" && \
    cp .env_sample .env && \
    sed -i "s/postgresql\:\/\/localhost\:5432/postgresql\:\/\/${POSTGRES_USER}\:${POSTGRES_PASSWORD}\@localhost\:5432/g" .env && \
    echo "" >> .env && \
    echo "# ImgProxy" >> .env && \
    echo "IMGPROXY_BIND='0.0.0.0:8083'" >> .env && \
    echo "IMGPROXY_ENDPOINT='http://localhost:8083'" >> .env && \
    echo "IMGPROXY_KEY='$(xxd -g 2 -l 64 -p /dev/random | tr -d '\n')'" >> .env && \
    echo "IMGPROXY_SALT='$(xxd -g 2 -l 64 -p /dev/random | tr -d '\n')'" >> .env && \
    bundle install && \ 
    yarn install

# ------------------------ Configure Forem ------------------------

RUN export PATH="$HOME/.rbenv/bin:$PATH" && \
    eval "$(rbenv init -)" && \
    . "${NVM_DIR}/nvm.sh" && \
    service redis-server start && \
    service postgresql start && \
    service elasticsearch start && \
    bin/webpack && \
    bin/setup

# ------------------------ Startup preparation ------------------------

ADD *.js /
ADD docker-entrypoint.sh /
RUN chmod a+rx /docker-entrypoint.sh

EXPOSE 3000

ENV S_NVM_DIR=${NVM_DIR}

# ------------------------ Clean up apt and temporary files ------------------------

RUN apt-get -y autoremove && \
    apt-get -y clean && \
    apt-get -y autoclean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ------------------------ Initialization ------------------------

FROM forem

CMD [ "/bin/bash", "/docker-entrypoint.sh" ]