#
# DSpace image - multistage build
#

#
# First step - Build DSpace
#

FROM openjdk:8-jre AS builder
MAINTAINER Alan Orth <alan.orth@gmail.com>

# Set DSpace version
ARG DSPACE_VERSION=5.8

ARG DSPACE_HOME=/dspace

# Environment variables
ENV DSPACE_VERSION=$DSPACE_VERSION \
    DSPACE_GIT_URL=https://github.com/DSpace/DSpace.git \
    DSPACE_GIT_REVISION=dspace-$DSPACE_VERSION \
    DSPACE_HOME=/dspace
ENV CATALINA_OPTS="-Xmx512M -Dfile.encoding=UTF-8" \
    MAVEN_OPTS="-XX:+TieredCompilation -XX:TieredStopAtLevel=1" \
    PATH=$DSPACE_HOME/bin:$PATH

WORKDIR /tmp

# Install runtime and dependencies
RUN apt-get update \
    && apt-get install -y \
    ant \
    maven \
    postgresql-client \
    git \
    openjdk-8-jdk-headless \
    xmlstarlet \
    && rm -rf /var/lib/apt \
    && apt -y autoremove


# Add a non-root user to perform the Maven build. DSpace's Mirage 2 theme does
# quite a bit of bootstrapping with npm and bower, which fails as root. Also
# change ownership of DSpace and Tomcat install directories.
RUN useradd -r -s /bin/bash -m -d "$DSPACE_HOME" dspace \
    && chown -R dspace:dspace "$DSPACE_HOME"

# Change to dspace user for build and install
USER dspace

# Clone DSpace source to $WORKDIR/dspace
RUN git clone --depth=1 --branch "$DSPACE_GIT_REVISION" "$DSPACE_GIT_URL" dspace

# Inject a dependency into the pom.xml for Maven 2.7+
RUN xmlstarlet ed --inplace -N x="http://maven.apache.org/POM/4.0.0" \
        -s "/x:project/x:build/x:pluginManagement/x:plugins/x:plugin[starts-with(x:artifactId,'maven-resources-plugin') and x:version > 2.6]" \
        -t elem -n "dependencies" \
        -s "/x:project/x:build/x:pluginManagement/x:plugins/x:plugin[starts-with(x:artifactId,'maven-resources-plugin') and x:version > 2.6]/dependencies" \
        -t elem -n "dependency" \
        -s "/x:project/x:build/x:pluginManagement/x:plugins/x:plugin[starts-with(x:artifactId,'maven-resources-plugin') and x:version > 2.6]/dependencies/dependency" \
        -t elem -n "groupId" -v "org.apache.maven.shared" \
        -s "/x:project/x:build/x:pluginManagement/x:plugins/x:plugin[starts-with(x:artifactId,'maven-resources-plugin') and x:version > 2.6]/dependencies/dependency" \
        -t elem -n "artifactId" -v "maven-filtering" \
        -s "/x:project/x:build/x:pluginManagement/x:plugins/x:plugin[starts-with(x:artifactId,'maven-resources-plugin') and x:version > 2.6]/dependencies/dependency" \
        -t elem -n "version" -v "1.3" \
        dspace/pom.xml

# Change the rb-inotify version to work around https://jira.duraspace.org/browse/DS-4115
RUN xmlstarlet ed --inplace -N x="http://maven.apache.org/POM/4.0.0" \
       -s "/x:project/x:dependencies" \
       -t elem -n "dependencyADD" \
       -s "/x:project/x:dependencies/dependencyADD" \
       -t elem -n "groupId" -v "rubygems" \
       -s "/x:project/x:dependencies/dependencyADD" \
       -t elem -n "artifactId" -v "rb-inotify" \
       -s "/x:project/x:dependencies/dependencyADD" \
       -t elem -n "version" -v "0.9.10" \
       -s "/x:project/x:dependencies/dependencyADD" \
       -t elem -n "type" -v "gem" \
       -r "/x:project/x:dependencies/dependencyADD" -v dependency \
       dspace/dspace/modules/xmlui-mirage2/pom.xml


# Copy customized build.properties (taken straight from the DSpace source
# tree and modified only to add bits to make it easier to replace hostname
# and port below)
COPY config/build.properties dspace

# Install user-supplied themes
# XMLUI themes not based on Mirage2 can be added after DSpace is built
COPY mirage2-themes dspace/dspace/modules/xmlui-mirage2/src/main/webapp/themes
COPY xmlui-themes   dspace/dspace-xmlui/src/main/webapp/themes

# Send most logs to stdout with custom log4j files
COPY config/log4j.properties dspace/dspace/config/log4j.properties
COPY config/log4j-solr.properties dspace/dspace/config/log4j-solr.properties

# Build DSpace with Mirage 2 enabled
RUN cd dspace && mvn -Dmirage2.on=true package

# Install compiled applications to $CATALINA_HOME
RUN cd dspace/dspace/target/dspace-installer \
    && ant init_installation init_configs install_code copy_webapps

# Download the MaxMind GeoIP database
RUN wget -qO- http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz | gunzip -c > "$DSPACE_HOME"/config/GeoLiteCity.dat
RUN wget -qO- http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz | tar -zxf - --strip-components=1 && mv GeoLite2-City.mmdb "$DSPACE_HOME"/config/

# Clean up DSpace build files
RUN rm -rf "$DSPACE_HOME/.m2"

#
# Second step - create a runner image from the components we built in the first step
#

FROM tomcat:8.5 AS dspace

# Set DSpace version
ARG DSPACE_VERSION=5.8

# Set DSpace home directory
ARG DSPACE_HOME=/dspace

# Environment variables
ENV DSPACE_VERSION=$DSPACE_VERSION \
    DSPACE_HOME=/dspace
ENV CATALINA_OPTS="-Xmx512M -Dfile.encoding=UTF-8" \
    PATH=PATH=$CATALINA_HOME/bin:$DSPACE_HOME/bin:$PATH

WORKDIR /tmp

RUN useradd -r -s /bin/bash -m -d "$DSPACE_HOME" dspace

COPY --from=builder --chown=dspace:dspace $DSPACE_HOME $DSPACE_HOME

# Tweak default Tomcat server configuration
COPY config/server.xml "$CATALINA_HOME"/conf/server.xml

# Install root filesystem
COPY rootfs /

# Link the native APR library into java.library.path
RUN ln -s /usr/local/tomcat/native-jni-lib /usr/lib/jni

#RUN chown -R dspace:dspace "$DSPACE_HOME" "$CATALINA_HOME" \
RUN chown -R dspace:dspace "$CATALINA_HOME" \
    && rm -fr "$CATALINA_HOME/webapps" \
    && mv -f "$DSPACE_HOME/webapps" "$CATALINA_HOME" \
    && sed -i s/CONFIDENTIAL/NONE/ "$CATALINA_HOME"/webapps/rest/WEB-INF/web.xml

# Install runtime and dependencies
RUN apt-get update \
    && apt-get install -y \
    cron \
    postgresql-client \
    imagemagick \
    ghostscript \
    xmlstarlet \
    && apt -y autoremove \
    && rm -rf /var/lib/apt

