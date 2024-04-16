FROM debian:9 as base

RUN <<COMMAND
    sed -i 's/deb.debian.org/archive.debian.org/' /etc/apt/sources.list
    sed -i 's/security.debian.org/archive.debian.org/' /etc/apt/sources.list

    apt-get update
    apt-get install -y build-essential crossbuild-essential-mipsel flex bison wget
COMMAND

FROM base as ncurses
ARG NCURSES_VERSION=6.4

RUN <<COMMAND
    wget https://ftp.gnu.org/gnu/ncurses/ncurses-${NCURSES_VERSION}.tar.gz
    tar -xvf ncurses-${NCURSES_VERSION}.tar.gz
    mv ncurses-${NCURSES_VERSION} ncurses
    cd ncurses
    ./configure --host=mipsel-linux-gnu --prefix=/usr
    make
COMMAND

FROM base as readline
ARG READLINE_VERSION=7.0

RUN <<COMMAND
    wget https://ftp.gnu.org/gnu/readline/readline-${READLINE_VERSION}.tar.gz
    tar -xvf readline-${READLINE_VERSION}.tar.gz
    mv readline-${READLINE_VERSION} readline
    cd readline
    ./configure --host=mipsel-linux-gnu --prefix=/usr
    make
COMMAND

FROM base as bird
ARG BIRD_VERSION=2.15

COPY --from=ncurses /ncurses /ncurses
COPY --from=readline /readline /readline

RUN <<COMMAND
    ( cd /ncurses; make install; )
    ( cd /readline; make install; )
    wget https://bird.network.cz/download/bird-${BIRD_VERSION}.tar.gz
    tar -xvf bird-${BIRD_VERSION}.tar.gz
    mv bird-${BIRD_VERSION} bird
    cd bird
    ./configure --host=mipsel-linux-gnu --prefix=/usr --sysconfdir=/etc/bird
    make
COMMAND

WORKDIR /pkg
COPY --chown=root:root bird.service /pkg/etc/systemd/system/bird.service

RUN <<COMMAND
    mkdir -p usr/sbin etc/bird
    install -m 755 /bird/bird usr/sbin
    install -m 755 /bird/birdc usr/sbin
    install -m 755 /bird/birdcl usr/sbin
    install -m 644 /bird/doc/bird.conf.example etc/bird/bird.conf

    tar -zcvf /bird-${BIRD_VERSION}-mipsel.tar.gz .
COMMAND

WORKDIR /
