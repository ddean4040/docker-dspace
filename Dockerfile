#
# DSpace image
#

FROM phusion/baseimage:0.9.22
MAINTAINER Alan Orth <alan.orth@gmail.com>

# Environment variables
ENV DSPACE_VERSION=5.7 TOMCAT_MAJOR=7 TOMCAT_VERSION=7.0.79
ENV TOMCAT_TGZ_URL=https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz \
    DSPACE_GIT_URL=https://github.com/CodeObia/DSpace.git \
    DSPACE_GIT_REVISION=5.7-production
ENV CATALINA_HOME=/usr/local/tomcat DSPACE_HOME=/dspace
ENV CATALINA_OPTS="-Xmx512M -Dfile.encoding=UTF-8"
ENV PATH=$CATALINA_HOME/bin:$DSPACE_HOME/bin:$PATH

WORKDIR /tmp

# Update the operating system userland, see notes on baseimage-docker
# See: https://github.com/phusion/baseimage-docker#upgrading_os
RUN apt update && apt upgrade -y -o Dpkg::Options::="--force-confold"

# Install runtime and dependencies
RUN apt install -y \
    vim \
    ant \
    maven \
    postgresql-client \
    git \
    imagemagick \
    ghostscript \
    openjdk-8-jdk-headless

# Add a non-root user to perform the Maven build. DSpace's Mirage 2 theme does
# quite a bit of bootstrapping with npm and bower, which fails as root.
RUN useradd -m dspace

RUN mkdir -p dspace "$CATALINA_HOME" \
    && curl -fSL "$TOMCAT_TGZ_URL" | tar -xz --strip-components=1 -C "$CATALINA_HOME" \
    && git clone --depth=1 --branch "$DSPACE_GIT_REVISION" "$DSPACE_GIT_URL" dspace \
    && chown -R dspace:dspace dspace

COPY config/build.properties dspace

# Switch to dspace user for build
USER dspace

RUN cd dspace && mvn -Dmirage2.on=true -P \!dspace-lni,\!dspace-rdf,\!dspace-sword,\!dspace-swordv2,\!dspace-jspui package

# Switch back to root for install
USER root

RUN cd dspace/dspace/target/dspace-installer \
    && ant init_installation init_configs install_code copy_webapps \
    && rm -fr "$CATALINA_HOME/webapps" && mv -f "$DSPACE_HOME/webapps" "$CATALINA_HOME" \
    && sed -i s/CONFIDENTIAL/NONE/ "$CATALINA_HOME"/webapps/rest/WEB-INF/web.xml

RUN rm -fr ~/.m2 /tmp/* /var/lib/apt/lists/* \
    && apt remove -y ant maven git && apt -y autoremove

# rename xmlui app to ROOT so it is available on /
RUN mv $CATALINA_HOME/webapps/xmlui $CATALINA_HOME/webapps/ROOT

COPY config/server.xml /usr/local/tomcat/conf/server.xml

# Install root filesystem
COPY ./rootfs /

WORKDIR $DSPACE_HOME

# Build info
RUN echo "Ubuntu GNU/Linux 16.04 (xenial) image. (`uname -rsv`)" >> /root/.built && \
    echo "- with `java -version 2>&1 | awk 'NR == 2'`" >> /root/.built && \
    echo "- with DSpace $DSPACE_VERSION on Tomcat $TOMCAT_VERSION"  >> /root/.built

EXPOSE 8080
CMD ["start-dspace"]
