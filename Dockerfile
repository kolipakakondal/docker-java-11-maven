FROM docker.io/clefos:latest

MAINTAINER James Dunnam "jamesd1184@gmail.com"

ENV MAVEN_VERSION 3.5.0

RUN yum update --setopt=tsflags=nodocs -y && \
    yum install --setopt=tsflags=nodocs -y tar

RUN echo deb http://us.archive.ubuntu.com/ubuntu/ precise main restricted universe multiverse
RUN apt-get update && apt-get install -y wget git curl zip monit openssh-server git iptables ca-certificates daemon net-tools libfontconfig-dev

#Install Oracle JDK 11
#--------------------
RUN 	curl -s -L 'https://api.adoptopenjdk.net/v2/binary/releases/openjdk11?openjdk_impl=openj9&os=linux&arch=s390x&release=latest&type=jdk' -o /tmp/openjdk.tar.gz && \
		mkdir -p /usr/lib/jvm/java-11-openjdk && \
		tar -C /usr/lib/jvm/java-11-openjdk -xzf /tmp/openjdk.tar.gz --strip-components=1 && \
		ln -sf /usr/lib/jvm/java-11-openjdk /usr/lib/jvm/java && \
		rm -f /tmp/openjdk.tar.gz && \
		yum clean all && \ 
		rm -rf /var/cache/yum/* /tmp/* /var/log/yum.log

ENV		JAVA_HOME=/usr/lib/jvm/java
ENV		PATH=$PATH:$JAVA_HOME/bin

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
