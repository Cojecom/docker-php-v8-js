FROM phusion/baseimage:latest
MAINTAINER Guillaume WELLS <contact.at.wellsguillaume.fr>

# Locale configuration for ppa:ondrej/php repositiory who use special char

RUN     apt-get update && apt-get install -y locales && locale-gen fr_FR && \
        locale-gen fr_FR.UTF-8 && update-locale

ENV     DEBIAN_FRONTEND=noninteractive \
        LANG=fr_FR.UTF-8 \
        LC_ALL=fr_FR.UTF-8


# Apache2 php7.1 install

RUN     apt-get -y install software-properties-common &&  \
        add-apt-repository -y ppa:ondrej/php && apt-get update && \
        apt-get -y install apache2 php7.1 libapache2-mod-php7.1 && \
        apt-get -y install curl mcrypt php7.1-mysql php7.1-mcrypt php7.1-curl \
        php7.1-json php7.1-mbstring php7.1-gd php7.1-intl php7.1-xml php7.1-zip\
        php-gettext &&\
        phpenmod mcrypt && phpenmod curl && \
        a2enmod rewrite && service apache2 restart && \
        php -v && apachectl -v && apt-get clean

#Node.js env

RUN     curl -sL https://deb.nodesource.com/setup_8.x -o nodesource_setup.sh
RUN     bash nodesource_setup.sh
RUN     apt-get install -y nodejs && nodejs -v && npm -v
RUN     apt-get install -y build-essential

#Workdir where voulume need to be mounted

WORKDIR /var/www

RUN     apt-get install -y git libv8-3.14-dev

RUN     DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        git subversion make g++ python2.7 curl php7.1-cli php7.1-dev wget bzip2 xz-utils pkg-config

RUN     git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git /tmp/depot_tools

ENV     PATH="$PATH:/tmp/depot_tools"

# Compilation of v8 engine. An evironement variable need to be set.
# export VERSION="6.9.207"
# List of available version: https://chromium.googlesource.com/v8/v8.git

RUN     cd /usr/local/src && fetch v8 && cd v8 && \
        git checkout $VERSION && gclient sync && \
        tools/dev/v8gen.py -vv x64.release -- is_component_build=true && \
        ninja -C out.gn/x64.release/ &&\
            \
        mkdir -p /usr/local/lib && \
        cp out.gn/x64.release/lib*.so out.gn/x64.release/*_blob.bin out.gn/x64.release/icudtl.dat /usr/local/lib && \
        cp -R include/* /usr/local/include/ && \ 
            \ 
        git clone https://github.com/phpv8/v8js.git /usr/local/src/v8js && \
        cd /usr/local/src/v8js && phpize

RUN     cd /usr/local/src/v8js && ./configure LDFLAGS="-lstdc++" --with-v8js=/usr/local && \
        export NO_INTERACTION=1 

RUN     cd /usr/local/src/v8js && make all -j8
RUN     cd /usr/local/src/v8js && make install #TODO: put again make test install

RUN     echo extension=v8js.so > /etc/php/7.1/cli/conf.d/99-v8js.ini && \
            \
        cd /tmp && \
        rm -rf /tmp/depot_tools /usr/local/src/v8 /usr/local/src/v8js && \
        apt-get remove -y subversion make g++ python2.7 curl php7.1-dev wget bzip2 xz-utils pkg-config && \
        apt-get autoremove -y && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/* &&\
        echo "extension=v8js.so" > /etc/php/7.1/mods-available/v8js.ini &&\
        phpenmod -v 7.1 -s ALL v8js

# Vhost conf where the volume is mounted
ADD     conf/vhost.conf /etc/apache2/sites-enabled/000-default.conf

# Internal exposed port of container
expose  80 

CMD /usr/sbin/apache2ctl -D FOREGROUND
