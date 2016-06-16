FROM ubuntu:14.04
MAINTAINER AshDev <ashdevfr@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

COPY ./lib/apt/sources.list /etc/apt/
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  software-properties-common \
  && rm -rf /var/lib/apt/lists/*
RUN add-apt-repository ppa:webupd8team/java -y
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
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

ENV UID=1000

ENV MOTD A Minecraft Server Powered by Spigot & Docker
ENV REV latest
ENV JVM_OPTS -Xmx1024M -Xms1024M
# replace these with defaults in spigot_init.sh
ENV LEVEL=world PVP=true VDIST=10 OPPERM=4 NETHER=true FLY=false MAXBHEIGHT=256 NPCS=true WLIST=false ANIMALS=true HC=false ONLINE=true RPACK='' DIFFICULTY=3 CMDBLOCK=false MAXPLAYERS=20 MONSTERS=true STRUCTURES=true SPAWNPROTECTION=16

#ENV DYNMAP=true ESSENTIALS=false PERMISSIONSEX=false CLEARLAG=false

#set default command
CMD /spigot_init.sh
