FROM ubuntu:xenial
MAINTAINER Jack Twilley <mathuin@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

COPY ./lib/apt/sources.list /etc/apt/
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  software-properties-common \
  && rm -rf /var/lib/apt/lists/*
RUN add-apt-repository ppa:webupd8team/java -y
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  curl \
  oracle-java8-installer \
  oracle-java8-set-default \
  supervisor \
  pwgen \
  wget \
  git \
  && rm -rf /var/lib/apt/lists/*

# Data volume for Minecraft
ENV SPIGOT_HOME /minecraft

# Location for static files
ENV STATIC_DIR /static

RUN useradd -s /bin/bash -d $SPIGOT_HOME -m minecraft

COPY ./lib/minecraft/* $STATIC_DIR/
COPY ./lib/scripts/spigot_init.sh /

RUN chmod +x /spigot_init.sh

EXPOSE 25565
EXPOSE 8123
VOLUME ["/minecraft"]

# Variables for overall setup
ENV UID 1000

# Variables for compilation
ENV REV latest

# Variables for plugins
ENV DYNMAP true
ENV ESSENTIALS false
ENV PERMISSIONSEX false
ENV CLEARLAG false

# Variables for config files
ENV MOTD A Minecraft Server Powered by Spigot & Docker

# Variables for execution
ENV JVM_OPTS -Xmx1024M -Xms1024M

CMD /spigot_init.sh
