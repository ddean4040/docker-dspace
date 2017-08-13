#
# DSpace image
#

FROM tomcat:8.5
MAINTAINER Alan Orth <alan.orth@gmail.com>

# Environment variables
ENV DSPACE_VERSION=5.7 \
    DSPACE_GIT_URL=https://github.com/DSpace/DSpace.git \
    DSPACE_GIT_REVISION=dspace-5.7 \
    DSPACE_HOME=/dspace
ENV CATALINA_OPTS="-Xmx512M -Dfile.encoding=UTF-8" \
    MAVEN_OPTS="-XX:+TieredCompilation -XX:TieredStopAtLevel=1" \
    PATH=$CATALINA_HOME/bin:$DSPACE_HOME/bin:$PATH

WORKDIR /tmp

# Update the operating system userland, see notes on baseimage-docker
# See: https://github.com/phusion/baseimage-docker#upgrading_os
RUN apt update && apt upgrade -y -o Dpkg::Options::="--force-confold"

# Install runtime and dependencies
RUN apt install -y \
    ant \
    maven \
    postgresql-client \
    git \
    imagemagick \
    ghostscript \
    openjdk-8-jdk-headless \
    cron

# Add a non-root user to perform the Maven build. DSpace's Mirage 2 theme does
# quite a bit of bootstrapping with npm and bower, which fails as root. Also
# change ownership of DSpace and Tomcat install directories.
RUN useradd -r -s /bin/bash -m -d "$DSPACE_HOME" dspace \
    && chown -R dspace:dspace "$DSPACE_HOME" "$CATALINA_HOME"

# Change to dspace user for build and install
USER dspace

# Clone DSpace source to $WORKDIR/dspace
RUN git clone --depth=1 --branch "$DSPACE_GIT_REVISION" "$DSPACE_GIT_URL" dspace

# Enable the Mirage 2 XMLUI theme
RUN sed -i 's#path="Mirage/"#path="Mirage2/"#' dspace/dspace/config/xmlui.xconf

# Build DSpace with Mirage 2 enabled
RUN cd dspace && mvn -Dmirage2.on=true package

# Install compiled applications to $CATALINA_HOME
RUN cd dspace/dspace/target/dspace-installer \
    && ant init_installation init_configs install_code copy_webapps \
    && rm -fr "$CATALINA_HOME/webapps" && mv -f "$DSPACE_HOME/webapps" "$CATALINA_HOME" \
    && sed -i s/CONFIDENTIAL/NONE/ "$CATALINA_HOME"/webapps/rest/WEB-INF/web.xml

# Change back to root user for cleanup
USER root

# Tweak default Tomcat server configuration
COPY config/server.xml "$CATALINA_HOME"/conf/server.xml

# Install root filesystem
COPY rootfs /

# Docker's COPY instruction always sets ownership to the root user, so we need
# to explicitly change ownership of those files and directories that we copied
# from rootfs.
RUN chown dspace:dspace $DSPACE_HOME $DSPACE_HOME/bin/*

# Make sure the crontab uses the correct DSpace directory
RUN sed -i "s#DSPACE=/dspace#DSPACE=$DSPACE_HOME#" /etc/cron.d/dspace-maintenance-tasks

RUN rm -fr "$DSPACE_HOME/.m2" /tmp/* /var/lib/apt/lists/* \
    && apt remove -y ant maven git openjdk-8-jdk-headless && apt -y autoremove

WORKDIR $DSPACE_HOME

# Build info
RUN echo "Debian GNU/Linux `cat /etc/debian_version` image. (`uname -rsv`)" >> /root/.built && \
    echo "- with `java -version 2>&1 | awk 'NR == 2'`" >> /root/.built && \
    echo "- with DSpace $DSPACE_VERSION on Tomcat $TOMCAT_VERSION"  >> /root/.built && \
    echo "\nNote: if you need to run commands interacting with DSpace you should enter the" >> /root/.built && \
    echo "container as the dspace user, ie: docker exec -it -u dspace dspace /bin/bash" >> /root/.built

EXPOSE 8080
# will run `start-dspace` script as root, then drop to dspace user
CMD ["start-dspace"]
