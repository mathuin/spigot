#!/bin/bash
set -e
usermod --uid $UID minecraft

if [ ! -e $SPIGOT_HOME/eula.txt ]; then
  if [ "$EULA" != "" ]; then
    echo "# Generated via Docker on $(date)" > $SPIGOT_HOME/eula.txt
    echo "eula=$EULA" >> $SPIGOT_HOME/eula.txt
  else
    echo "*****************************************************************"
    echo "*****************************************************************"
    echo "** To be able to run spigot you need to accept minecrafts EULA **"
    echo "** see https://account.mojang.com/documents/minecraft_eula     **"
    echo "** include -e EULA=true on the docker run command              **"
    echo "*****************************************************************"
    echo "*****************************************************************"
    exit
  fi
fi

# Some variables are mandatory.
if [ -z "$REV" ]; then
    REV="latest"
fi

# Some variables make good shorthand.
SPIGOT_JENKINS=https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild
ESSENTIALS_JENKINS=https://ci.drtshock.net/job/EssentialsX/lastSuccessfulBuild
DYNMAP_BUILDS=http://mikeprimm.com/dynmap/builds

# Some variables depend on other variables.

# Creeper block disable is a feature of the Essentials plugin.
if [ -n "$CREEPERBLOCKDISABLE" ]; then
    if [ "$CREEPERBLOCKDISABLE" = "true" ]; then
	ESSENTIALS=true
    fi
fi

# Force rebuild of spigot.jar if REV is latest.
rm -f $SPIGOT_HOME/spigot-latest.jar

# Only build a new spigot.jar if a jar for this REV does not already exist.
if [ ! -f $SPIGOT_HOME/spigot-$REV.jar ]; then
  echo "Building spigot jar file, be patient"
  mkdir -p $SPIGOT_HOME/build
  cd $SPIGOT_HOME/build
  wget -O $SPIGOT_HOME/build/BuildTools.jar $SPIGOT_JENKINS/artifact/target/BuildTools.jar
  HOME=$SPIGOT_HOME/build java -jar BuildTools.jar --rev $REV
  cp $SPIGOT_HOME/build/Spigot/Spigot-Server/target/spigot-*.jar $SPIGOT_HOME/spigot-$REV.jar
  mkdir -p $SPIGOT_HOME/plugins
fi

# Select the spigot.jar for this particular rev.
rm -f $SPIGOT_HOME/spigot.jar && ln -s $SPIGOT_HOME/spigot-$REV.jar $SPIGOT_HOME/spigot.jar

# Install Dynmap and associated tweaks.
if [ -n "$DYNMAP" ]; then
  if [ "$DYNMAP" = "true" ]; then
    echo "Downloading Dynmap..."
    wget -O $SPIGOT_HOME/plugins/dynmap-HEAD.jar $DYNMAP_BUILDS/dynmap/dynmap-HEAD.jar
    wget -O $SPIGOT_HOME/plugins/dynmap-mobs-HEAD.jar $DYNMAP_BUILDS/dynmap-mobs/dynmap-mobs-HEAD.jar
    if [ -n "$ESSENTIALS" ]; then
      if [ "$ESSENTIALS" = "true" ]; then
        echo "Downloading Dynmap Essentials..."
        wget -O $SPIGOT_HOME/plugins/Dynmap-Essentials-HEAD.jar $DYNMAP_BUILDS/Dynmap-Essentials/Dynmap-Essentials-HEAD.jar
      else
    echo "Removing Dynmap Essential..."
        rm -f $SPIGOT_HOME/plugins/Dynmap-Essentials-HEAD.jar
      fi
    fi
  else
    echo "Removing Dynmap..."
    rm -f $SPIGOT_HOME/plugins/dynmap-HEAD.jar
    rm -f $SPIGOT_HOME/plugins/dynmap-mobs-HEAD.jar
    rm -f $SPIGOT_HOME/plugins/Dynmap-Essentials-HEAD.jar
  fi
fi

# Install Essentials.
if [ -n "$ESSENTIALS" ]; then
  ESSENTIALS_JAR=EssentialsX-2.0.1.jar
  EPROTECT_JAR=EssentialsXProtect-2.0.1.jar
  if [ "$ESSENTIALS" = "true" ]; then
    echo "Downloading Essentials..."
    wget -O $SPIGOT_HOME/plugins/$ESSENTIALS_JAR $ESSENTIALS_JENKINS/artifact/Essentials/target/$ESSENTIALS_JAR
    wget -O $SPIGOT_HOME/plugins/$EPROTECT_JAR $ESSENTIALS_JENKINS/artifact/EssentialsProtect/target/$EPROTECT_JAR
    if [ -n "$CREEPERBLOCKDISABLE" ]; then
        if [ "$CREEPERBLOCKDISABLE" = "true" ]; then
            if [ -f $SPIGOT_HOME/plugins/Essentials/config.yml ]; then
                echo "Disabling creeper block damage..."
                sed -i "s/creeper-blockdamage: .*/creeper-blockdamage: $CREEPERBLOCKDISABLE/" $SPIGOT_HOME/plugins/Essentials/config.yml
            fi
        fi
    fi
  else
    echo "Removing Essentials..."
    rm -f $SPIGOT_HOME/plugins/$ESSENTIALS_JAR
    rm -f $SPIGOT_HOME/plugins/$EPROTECT_JAR
  fi
fi

# Install Clearlag. 
if [ -n "$CLEARLAG" ]; then
  if [ "$CLEARLAG" = "true" ]; then
    echo "Downloading ClearLag..."
    wget -O $SPIGOT_HOME/plugins/Clearlag.jar http://dev.bukkit.org/media/files/909/721/Clearlag.jar
  else
    echo "Removing Clearlag..."
    rm -f $SPIGOT_HOME/plugins/Clearlag.jar
  fi
fi

# Install PermissionsEx.
if [ -n "$PERMISSIONSEX" ]; then
  if [ "$PERMISSIONSEX" = "true" ]; then
    echo "Downloading PermissionsEx..."
    wget -O $SPIGOT_HOME/plugins/PermissionsEx-1.23.4.jar http://dev.bukkit.org/media/files/909/154/PermissionsEx-1.23.4.jar
  else
    echo "Removing PermissionsEx..."
    rm -f $SPIGOT_HOME/plugins/PermissionsEx-*.jar
  fi
fi

# Install configuration files.
if [ ! -f $SPIGOT_HOME/white-list.txt ]
then
    cp $STATIC_DIR/white-list.txt $SPIGOT_HOME/
fi

if [ ! -f $SPIGOT_HOME/server.properties ]
then
  cp $STATIC_DIR/server.properties $SPIGOT_HOME/
fi

# Update configuration file settings.
if [ -n "$MOTD" ]; then
  sed -i "/motd\s*=/ c motd=$MOTD" $SPIGOT_HOME/server.properties
fi

if [ -n "$LEVEL" ]; then
  sed -i "/level-name\s*=/ c level-name=$LEVEL" $SPIGOT_HOME/server.properties
fi

if [ -n "$SEED" ]; then
  sed -i "/level-seed\s*=/ c level-seed=$SEED" $SPIGOT_HOME/server.properties
fi

if [ -n "$PVP" ]; then
  sed -i "/pvp\s*=/ c pvp=$PVP" $SPIGOT_HOME/server.properties
fi

if [ -n "$VDIST" ]; then
  sed -i "/view-distance\s*=/ c view-distance=$VDIST" $SPIGOT_HOME/server.properties
fi

if [ -n "$OPPERM" ]; then
  sed -i "/op-permission-level\s*=/ c op-permission-level=$OPPERM" $SPIGOT_HOME/server.properties
fi

if [ -n "$NETHER" ]; then
  sed -i "/allow-nether\s*=/ c allow-nether=$NETHER" $SPIGOT_HOME/server.properties
fi

if [ -n "$FLY" ]; then
  sed -i "/allow-flight\s*=/ c allow-flight=$FLY" $SPIGOT_HOME/server.properties
fi

if [ -n "$MAXBHEIGHT" ]; then
  sed -i "/max-build-height\s*=/ c max-build-height=$MAXBHEIGHT" $SPIGOT_HOME/server.properties
fi

if [ -n "$NPCS" ]; then
  sed -i "/spawn-npcs\s*=/ c spawn-npcs=$NPCS" $SPIGOT_HOME/server.properties
fi

if [ -n "$WLIST" ]; then
  sed -i "/white-list\s*=/ c white-list=$WLIST" $SPIGOT_HOME/server.properties
fi

if [ -n "$ANIMALS" ]; then
  sed -i "/spawn-animals\s*=/ c spawn-animals=$ANIMALS" $SPIGOT_HOME/server.properties
fi

if [ -n "$HC" ]; then
  sed -i "/hardcore\s*=/ c hardcore=$HC" $SPIGOT_HOME/server.properties
fi

if [ -n "$ONLINE" ]; then
  sed -i "/online-mode\s*=/ c online-mode=$ONLINE" $SPIGOT_HOME/server.properties
fi

if [ -n "$RPACK" ]; then
  sed -i "/resource-pack\s*=/ c resource-pack=$RPACK" $SPIGOT_HOME/server.properties
fi

if [ -n "$DIFFICULTY" ]; then
  sed -i "/difficulty\s*=/ c difficulty=$DIFFICULTY" $SPIGOT_HOME/server.properties
fi

if [ -n "$CMDBLOCK" ]; then
  sed -i "/enable-command-block\s*=/ c enable-command-block=$CMDBLOCK" $SPIGOT_HOME/server.properties
fi

if [ -n "$MAXPLAYERS" ]; then
  sed -i "/max-players\s*=/ c max-players=$MAXPLAYERS" $SPIGOT_HOME/server.properties
fi

if [ -n "$MONSTERS" ]; then
  sed -i "/spawn-monsters\s*=/ c spawn-monsters=$MONSTERS" $SPIGOT_HOME/server.properties
fi

if [ -n "$STRUCTURES" ]; then
  sed -i "/generate-structures\s*=/ c generate-structures=$STRUCTURES" $SPIGOT_HOME/server.properties
fi

if [ -n "$SPAWNPROTECTION" ]; then
  sed -i "/spawn-protection\s*=/ c spawn-protection=$SPAWNPROTECTION" $SPIGOT_HOME/server.properties
fi

if [ -n "$MODE" ]; then
  case ${MODE,,?} in
    0|1|2|3)
      ;;
    s*)
      MODE=0
      ;;
    c*)
      MODE=1
      ;;
    *)
      echo "ERROR: Invalid game mode: $MODE"
      exit 1
      ;;
  esac

  sed -i "/gamemode\s*=/ c gamemode=$MODE" $SPIGOT_HOME/server.properties
fi

# Configure ops file.
if [ -n "$OPS" -a ! -e $SPIGOT_HOME/ops.txt.converted ]; then
  echo $OPS | awk -v RS=, '{print}' >> $SPIGOT_HOME/ops.txt
fi

# Server icon?
if [ -n "$ICON" -a ! -e $SPIGOT_HOME/server-icon.png ]; then
  echo "Using server icon from $ICON..."
  # Not sure what it is yet...call it "img"
  wget -q -O /tmp/icon.img $ICON
  specs=$(identify /tmp/icon.img | awk '{print $2,$3}')
  if [ "$specs" = "PNG 64x64" ]; then
    mv /tmp/icon.img $SPIGOT_HOME/server-icon.png
  else
    echo "Converting image to 64x64 PNG..."
    convert /tmp/icon.img -resize 64x64! $SPIGOT_HOME/server-icon.png
  fi
fi

# Change owner to minecraft.
chown -R minecraft.minecraft $SPIGOT_HOME/

cd $SPIGOT_HOME/

su - minecraft -c "exec java $JVM_OPTS -jar spigot.jar"

# Fallback to root and run shell if spigot don't start/forced exit.
bash
