#
# DSpace image
#

FROM openjdk:8-jdk
MAINTAINER Alan Orth <alan.orth@gmail.com>

# Environment variables
ENV DSPACE_VERSION=5.6 TOMCAT_MAJOR=7 TOMCAT_VERSION=7.0.78
ENV TOMCAT_TGZ_URL=https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz \
    MAVEN_TGZ_URL=http://apache.mirror.iweb.ca/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz \
    DSPACE_GIT_URL=https://github.com/DSpace/DSpace.git \
    DSPACE_GIT_REVISION=dspace-5.6
ENV CATALINA_HOME=/usr/local/tomcat DSPACE_HOME=/dspace
ENV PATH=$CATALINA_HOME/bin:$DSPACE_HOME/bin:$PATH

WORKDIR /tmp

# Install runtime and dependencies
RUN apt-get update && apt-get install -y \
    vim \
    ant \
    postgresql-client \
    git \
    && mkdir -p maven dspace "$CATALINA_HOME" \
    && curl -fSL "$TOMCAT_TGZ_URL" | tar -xz --strip-components=1 -C "$CATALINA_HOME" \
    && curl -fSL "$MAVEN_TGZ_URL" | tar -xz --strip-components=1 -C maven \
    && git clone --depth=1 --branch "$DSPACE_GIT_REVISION" "$DSPACE_GIT_URL" dspace \
    && cd dspace && ../maven/bin/mvn package \
    && cd dspace/target/dspace-installer \
    && ant init_installation init_configs install_code copy_webapps \
    && rm -fr "$CATALINA_HOME/webapps" && mv -f /dspace/webapps "$CATALINA_HOME" \
    && sed -i s/CONFIDENTIAL/NONE/ /usr/local/tomcat/webapps/rest/WEB-INF/web.xml \
    && rm -fr ~/.m2 /tmp/* /var/lib/apt/lists/* \
    && apt-get remove -y ant git && apt-get -y autoremove

# Install root filesystem
ADD ./rootfs /

WORKDIR /dspace

# Build info
RUN echo "Debian GNU/Linux 8 (jessie) image. (`uname -rsv`)" >> /root/.built && \
    echo "- with `java -version 2>&1 | awk 'NR == 2'`" >> /root/.built && \
    echo "- with DSpace $DSPACE_VERSION on Tomcat $TOMCAT_VERSION"  >> /root/.built

EXPOSE 8080
CMD ["start-dspace"]
