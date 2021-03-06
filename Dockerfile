####################
# BASE IMAGE
####################
FROM ubuntu:16.04

MAINTAINER madslundt@live.dk <madslundt@live.dk>


####################
# INSTALLATIONS
####################
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y \
        curl \
        fuse \
        unionfs-fuse \
        bc \
        unzip \
        wget \
        ca-certificates && \
    update-ca-certificates && \
    apt-get install -y openssl && \
    sed -i 's/#user_allow_other/user_allow_other/' /etc/fuse.conf

# S6 overlay
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
ENV S6_KEEP_ENV=1

RUN \
    OVERLAY_VERSION=$(curl -sX GET "https://api.github.com/repos/just-containers/s6-overlay/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]') && \
    curl -o /tmp/s6-overlay.tar.gz -L "https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-amd64.tar.gz" && \
    tar xfz  /tmp/s6-overlay.tar.gz -C /


####################
# ENVIRONMENT VARIABLES
####################
# Encryption
ENV ENCRYPT_MEDIA "1"
ENV READ_ONLY "1"

# Rclone
ENV BUFFER_SIZE "500M"
ENV MAX_READ_AHEAD "30G"
ENV CHECKERS "16"
ENV RCLONE_DISABLE_MEMORY_CACHE "1"
ENV RCLONE_CLOUD_ENDPOINT "gd-crypt:"
ENV RCLONE_LOCAL_ENDPOINT "local-crypt:"

# Plexdrive
# ENV PLEXDRIVE_CHECK_THREADS "2"
# ENV PLEXDRIVE_LOAD_AHEAD "3"
# ENV PLEXDRIVE_LOAD_THREADS "2"
# ENV PLEXDRIVE_CHUNK_SIZE "25M"
# ENV PLEXDRIVE_MAX_CHUNKS "50"
# ENV PLEXDRIVE_REFRESH_INTERVAL "1m0s"
# ENV PLEXDRIVE_VERBOSITY "1"

# Time format
ENV DATE_FORMAT "+%F@%T"

# Local files removal
ENV REMOVE_LOCAL_FILES_BASED_ON "space"
ENV REMOVE_LOCAL_FILES_WHEN_SPACE_EXCEEDS_GB "100"
ENV FREEUP_ATLEAST_GB "80"
ENV REMOVE_LOCAL_FILES_AFTER_DAYS "30"

# Plex
ENV PLEX_URL ""
ENV PLEX_TOKEN ""


####################
# SCRIPTS
####################
COPY setup/* /usr/bin/
COPY install.sh /
COPY scripts/* /usr/bin/
COPY root /

RUN chmod a+x /install.sh && \
    sh /install.sh && \
    chmod a+x /usr/bin/* && \
    groupmod -g 1000 users && \
    useradd -u 911 -U -d / -s /bin/false abc && \
    usermod -G users abc && \
    apt-get clean autoclean && \
    apt-get autoremove -y && \
    rm -rf /tmp/* /var/lib/{apt,dpkg,cache,log}/

####################
# VOLUMES
####################
# Define mountable directories.
VOLUME /data/db /cloud-encrypt /cloud-decrypt /local-decrypt /local-media /cache /log


RUN chmod -R 777 /data /log && \
    mkdir /config

####################
# WORKING DIRECTORY
####################
WORKDIR /data


####################
# ENTRYPOINT
####################
ENTRYPOINT ["/init"]
