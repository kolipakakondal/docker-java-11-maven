# First stage: JDK 11 with modules required for Spring Boot
FROM debian:stretch-slim as packager

# source JDK distribution names
# update from https://jdk.java.net/java-se-ri/11
ENV JDK_VERSION="11.0.1"
ENV JDK_URL="https://download.java.net/java/GA/jdk11/13/GPL/openjdk-${JDK_VERSION}_linux-x64_bin.tar.gz"
ENV JDK_HASH="7a6bb980b9c91c478421f865087ad2d69086a0583aeeb9e69204785e8e97dcfd"
ENV JDK_HASH_FILE="${JDK_ARJ_FILE}.sha2"
ENV JDK_ARJ_FILE="openjdk-${JDK_VERSION}.tar.gz"
# target JDK installation names
ENV OPT="/opt"
ENV JKD_DIR_NAME="jdk-${JDK_VERSION}"
ENV JAVA_HOME="${OPT}/${JKD_DIR_NAME}"
ENV JAVA_MINIMAL="${OPT}/java-minimal"

# downlodad JDK to the local file
ADD "$JDK_URL" "$JDK_ARJ_FILE"

# verify downloaded file hashsum
RUN { \
        echo "Verify downloaded JDK file $JDK_ARJ_FILE:" && \
        echo "$JDK_HASH $JDK_ARJ_FILE" > "$JDK_HASH_FILE" && \
        sha256sum -c "$JDK_HASH_FILE" ; \
    }

# extract JDK and add to PATH
RUN { \
        echo "Unpack downloaded JDK to ${JAVA_HOME}/:" && \
        mkdir -p "$OPT" && \
        tar xf "$JDK_ARJ_FILE" -C "$OPT" ; \
    }
ENV PATH="$PATH:$JAVA_HOME/bin"

RUN { \
        java --version ; \
        echo "jlink version:" && \
        jlink --version ; \
    }

# build modules distribution
RUN jlink \
    --verbose \
    --add-modules \
        java.base,java.sql,java.naming,java.desktop,java.management,java.security.jgss,java.instrument \
        # java.naming - javax/naming/NamingException
        # java.desktop - java/beans/PropertyEditorSupport
        # java.management - javax/management/MBeanServer
        # java.security.jgss - org/ietf/jgss/GSSException
        # java.instrument - java/lang/instrument/IllegalClassFormatException
    --compress 2 \
    --strip-debug \
    --no-header-files \
    --no-man-pages \
    --output "$JAVA_MINIMAL"

# Second stage, add only our minimal "JRE" distr and our app
FROM debian:stretch-slim

ENV JAVA_HOME=/opt/java-minimal
ENV PATH="$PATH:$JAVA_HOME/bin"

# 
FROM ubuntu:18.04

ENV MAVEN_VERSION 3.5.0

RUN echo deb http://us.archive.ubuntu.com/ubuntu/ precise main restricted universe multiverse
RUN apt-get update && apt-get install -y wget git curl zip monit openssh-server git iptables ca-certificates daemon net-tools libfontconfig-dev

# Maven related
# -------------
ENV MAVEN_ROOT /var/lib/maven
ENV MAVEN_HOME $MAVEN_ROOT/apache-maven-$MAVEN_VERSION
ENV MAVEN_OPTS -Xms256m -Xmx512m

RUN echo "# Installing Maven " && echo ${MAVEN_VERSION} && \
    wget --no-verbose -O /tmp/apache-maven-$MAVEN_VERSION.tar.gz \
    http://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz && \
    mkdir -p $MAVEN_ROOT && \
    tar xzf /tmp/apache-maven-$MAVEN_VERSION.tar.gz -C $MAVEN_ROOT && \
    ln -s $MAVEN_HOME/bin/mvn /usr/local/bin && \
    rm -f /tmp/apache-maven-$MAVEN_VERSION.tar.gz

VOLUME /var/lib/maven

# Node related
# ------------

RUN echo "# Installing Nodejs" && \
    curl -sL https://deb.nodesource.com/setup_4.x | bash - && \
    apt-get install nodejs build-essential -y && \
    npm set strict-ssl false && \
    npm install -g npm@latest && \
    npm install -g bower grunt grunt-cli && \
    npm cache clear -f && \
    npm install -g n && \
    n stable
