# Copyright 2017-2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License"). You may not use this file except in compliance with the License.
# A copy of the License is located at
#
#    http://aws.amazon.com/asl/
#
# or in the "license" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.
#

FROM ubuntu:14.04.5

ENV DOCKER_BUCKET="download.docker.com" \
    DOCKER_VERSION="18.09.0" \
    DOCKER_CHANNEL="stable" \
    DOCKER_SHA256="08795696e852328d66753963249f4396af2295a7fe2847b839f7102e25e47cb9" \
    DIND_COMMIT="3b5fac462d21ca164b3778647420016315289034" \
    DOCKER_COMPOSE_VERSION="1.23.2" \
    GITVERSION_VERSION="3.6.5"

# Install git, SSH, and other utilities
RUN set -ex \
    && echo 'Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/99use-gzip-compression \
    && apt-get update \
    && apt install -y apt-transport-https \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF \
    && echo "deb https://download.mono-project.com/repo/ubuntu stable-trusty main" | tee /etc/apt/sources.list.d/mono-official-stable.list \
    && apt-get update \
    && apt-get install software-properties-common -y --no-install-recommends \
    && apt-add-repository ppa:git-core/ppa \
    && apt-get update \
    && apt-get install git=1:2.* -y --no-install-recommends \
    && git version \
    && apt-get install -y --no-install-recommends openssh-client=1:6.6* \
    && mkdir ~/.ssh \
    && touch ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa,dsa -H github.com >> ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa,dsa -H bitbucket.org >> ~/.ssh/known_hosts \
    && chmod 600 ~/.ssh/known_hosts \
    && apt-get install -y --no-install-recommends \
       wget=1.15-* python3=3.4.* python3.4-dev=3.4.* fakeroot=1.20-* ca-certificates jq \
       tar=1.27.* gzip=1.6-* zip=3.0-* autoconf=2.69-* automake=1:1.14.* \
       bzip2=1.0.* file=1:5.14-* g++=4:4.8.* gcc=4:4.8.* imagemagick=8:6.7.* \
       libbz2-dev=1.0.* libc6-dev=2.19-* libcurl4-openssl-dev=7.35.* libdb-dev=1:5.3.* \
       libevent-dev=2.0.* libffi-dev=3.1~* libgeoip-dev=1.6.* libglib2.0-dev=2.40.* \
       libjpeg-dev=8c-* libkrb5-dev=1.12+* liblzma-dev=5.1.* \
       libmagickcore-dev=8:6.7.* libmagickwand-dev=8:6.7.* libmysqlclient-dev=5.5.* \
       libncurses5-dev=5.9+* libpng12-dev=1.2.* libpq-dev=9.3.* libreadline-dev=6.3-* \
       libsqlite3-dev=3.8.* libssl-dev=1.0.* libtool=2.4.* libwebp-dev=0.4.* \
       libxml2-dev=2.9.* libxslt1-dev=1.1.* libyaml-dev=0.1.* make=3.81-* \
       patch=2.7.* xz-utils=5.1.* zlib1g-dev=1:1.2.* unzip=6.0-* curl=7.35.* \
       e2fsprogs=1.42.* iptables=1.4.* xfsprogs=3.1.* xz-utils=5.1.* \
       mono-devel=5.* less=458-* groff=1.22.* liberror-perl=0.17-* \
       asciidoc=8.6.* build-essential=11.* bzr=2.6.* cvs=2:1.12.* cvsps=2.1-* docbook-xml=4.5-* docbook-xsl=1.78.* dpkg-dev=1.17.* \
       libdbd-sqlite3-perl=1.40-* libdbi-perl=1.630-* libdpkg-perl=1.17.* libhttp-date-perl=6.02-* \
       libio-pty-perl=1:1.08-* libserf-1-1=1.3.* libsvn-perl=1.8.* libsvn1=1.8.* libtcl8.6=8.6.* libtimedate-perl=2.3000-* \
       libunistring0=0.9.* libxml2-utils=2.9.* libyaml-perl=0.84-* python-bzrlib=2.6.* python-configobj=4.7.* \
       sgml-base=1.26+* sgml-data=2.0.* subversion=1.8.* tcl=8.6.* tcl8.6=8.6.* xml-core=0.13+* xmlto=0.0.* xsltproc=1.1.* python3-pip \
       tk=8.6.* gettext=0.18.* gettext-base=0.18.* libapr1=1.5.* libaprutil1=1.5.* libasprintf0c2=0.18.*  \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Download and set up GitVersion
RUN set -ex \
    && wget "https://github.com/GitTools/GitVersion/releases/download/v${GITVERSION_VERSION}/GitVersion_${GITVERSION_VERSION}.zip" -O /tmp/GitVersion_${GITVERSION_VERSION}.zip \
    && mkdir -p /usr/local/GitVersion_${GITVERSION_VERSION} \
    && unzip /tmp/GitVersion_${GITVERSION_VERSION}.zip -d /usr/local/GitVersion_${GITVERSION_VERSION} \
    && rm /tmp/GitVersion_${GITVERSION_VERSION}.zip \
    && echo "mono /usr/local/GitVersion_${GITVERSION_VERSION}/GitVersion.exe \$@" >> /usr/local/bin/gitversion \
    && chmod +x /usr/local/bin/gitversion

# Install Docker
RUN set -ex \
    && curl -fSL "https://${DOCKER_BUCKET}/linux/static/${DOCKER_CHANNEL}/x86_64/docker-${DOCKER_VERSION}.tgz" -o docker.tgz \
    && echo "${DOCKER_SHA256} *docker.tgz" | sha256sum -c - \
    && tar --extract --file docker.tgz --strip-components 1  --directory /usr/local/bin/ \
    && rm docker.tgz \
    && docker -v \
# set up subuid/subgid so that "--userns-remap=default" works out-of-the-box
    && addgroup dockremap \
    && useradd -g dockremap dockremap \
    && echo 'dockremap:165536:65536' >> /etc/subuid \
    && echo 'dockremap:165536:65536' >> /etc/subgid \
    && wget "https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind" -O /usr/local/bin/dind \
    && curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-Linux-x86_64 > /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/dind /usr/local/bin/docker-compose \
# Ensure docker-compose works
    && docker-compose version

# Install dependencies by all python images equivalent to buildpack-deps:jessie
# on the public repos.

RUN set -ex \
    && pip3 install awscli boto3

VOLUME /var/lib/docker

# Configure SSH
COPY ssh_config /root/.ssh/config

COPY dockerd-entrypoint.sh /usr/local/bin/

ENV JAVA_VERSION=11 \
    JAVA_HOME="/opt/jvm/openjdk-11" \
    JDK_HOME="/opt/jvm/openjdk-11" \
    JRE_HOME="/opt/jvm/openjdk-11" \
    ANT_VERSION=1.10.3 \
    MAVEN_HOME="/opt/maven" \
    MAVEN_VERSION=3.5.4 \
    MAVEN_CONFIG="/root/.m2" \
    GRADLE_VERSION=5.0 \
    SBT_VERSION=1.2.6 \
    PROPERTIES_COMMON_VERSION=0.92.37.8 \
    PYTHON_TOOL_VERSION="3.3-*" \
    JDK_VERSION=11.0.1 \
    JDK_VERSION_TAG=13 \
    JDK_DOWNLOAD_SHA256="7a6bb980b9c91c478421f865087ad2d69086a0583aeeb9e69204785e8e97dcfd" \
    ANT_DOWNLOAD_SHA512="73f2193700b1d1e32eedf25fab1009e2a98fb2f6425413f5c9fa1b0f2f9f49f59cb8ed3f04931c808ae022a64ecfa2619e5fb77643fea6dbc29721e489eb3a07" \
    MAVEN_DOWNLOAD_SHA1="22cac91b3557586bb1eba326f2f7727543ff15e3" \
    GRADLE_DOWNLOAD_SHA256="6157ac9f3410bc63644625b3b3e9e96c963afd7910ae0697792db57813ee79a6"

ENV JDK_DOWNLOAD_TAR="openjdk-${JDK_VERSION}_linux-x64_bin.tar.gz"

RUN set -ex \
    && apt-get update \
    && apt-get install -y software-properties-common=$PROPERTIES_COMMON_VERSION \
    && apt-get install -y python-setuptools=$PYTHON_TOOL_VERSION \

    # Install OpenJDK 11
    # Note: Installing ca-certificates-java installs JDK7 because it's a depedency.
    # We will use update-alternatives to make sure JDK11 has higher priority for all
    # the tools
    && apt-get install -y --no-install-recommends ca-certificates-java \

    && mkdir -p $JAVA_HOME \
    && curl -LSso /var/tmp/$JDK_DOWNLOAD_TAR https://download.java.net/java/GA/jdk11/$JDK_VERSION_TAG/GPL/$JDK_DOWNLOAD_TAR \
    && echo "$JDK_DOWNLOAD_SHA256 /var/tmp/$JDK_DOWNLOAD_TAR" | tee foo.txt | sha256sum -c - \
    && tar xzvf /var/tmp/$JDK_DOWNLOAD_TAR -C $JAVA_HOME --strip-components=1 \
    && for tool_path in $JAVA_HOME/bin/*; do \
          tool=`basename $tool_path`; \
          update-alternatives --install /usr/bin/$tool $tool $tool_path 10000; \
          update-alternatives --set $tool $tool_path; \
        done \
     && rm $JAVA_HOME/lib/security/cacerts && ln -s /etc/ssl/certs/java/cacerts $JAVA_HOME/lib/security/cacerts \

    # Install Ant
    && curl -LSso /var/tmp/apache-ant-$ANT_VERSION-bin.tar.gz https://archive.apache.org/dist/ant/binaries/apache-ant-$ANT_VERSION-bin.tar.gz  \
    && echo "$ANT_DOWNLOAD_SHA512 /var/tmp/apache-ant-$ANT_VERSION-bin.tar.gz" | sha512sum -c - \
    && tar -xzf /var/tmp/apache-ant-$ANT_VERSION-bin.tar.gz -C /opt \
    && update-alternatives --install /usr/bin/ant ant /opt/apache-ant-$ANT_VERSION/bin/ant 10000 \

    # Install Maven
    && mkdir -p $MAVEN_HOME \
    && curl -LSso /var/tmp/apache-maven-$MAVEN_VERSION-bin.tar.gz https://apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz \
    && echo "$MAVEN_DOWNLOAD_SHA1 /var/tmp/apache-maven-$MAVEN_VERSION-bin.tar.gz" | sha1sum -c - \
    && tar xzvf /var/tmp/apache-maven-$MAVEN_VERSION-bin.tar.gz -C $MAVEN_HOME --strip-components=1 \
    && update-alternatives --install /usr/bin/mvn mvn /opt/maven/bin/mvn 10000 \
    && mkdir -p $MAVEN_CONFIG \

    # Install Gradle
    && curl -LSso /var/tmp/gradle-$GRADLE_VERSION-bin.zip https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip \
    && echo "$GRADLE_DOWNLOAD_SHA256 /var/tmp/gradle-$GRADLE_VERSION-bin.zip" | sha256sum -c - \
    && unzip /var/tmp/gradle-$GRADLE_VERSION-bin.zip -d /opt \
    && update-alternatives --install /usr/local/bin/gradle gradle /opt/gradle-$GRADLE_VERSION/bin/gradle 10000 \

    # Install SBT
    && echo "deb https://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list \
    && apt-get install -y --no-install-recommends apt-transport-https \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823 \
    && apt-get update \
    && apt-get install -y --no-install-recommends sbt=$SBT_VERSION \


     && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
     && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
     && apt-get update -qqy \
     && apt-get -qqy install google-chrome-stable \
     && rm /etc/apt/sources.list.d/google-chrome.list \
     && rm -rf /var/lib/apt/lists/* /var/cache/apt/* \
     && sed -i 's/"$HERE\/chrome"/"$HERE\/chrome" --no-sandbox/g' /opt/google/chrome/google-chrome \
     && CHROME_DRIVER_VERSION=2.43 \
     && wget --no-verbose -O /tmp/chromedriver_linux64.zip https://chromedriver.storage.googleapis.com/$CHROME_DRIVER_VERSION/chromedriver_linux64.zip \
     && rm -rf /opt/chromedriver \
     && unzip /tmp/chromedriver_linux64.zip -d /opt \
     && rm /tmp/chromedriver_linux64.zip \
     && mv /opt/chromedriver /opt/chromedriver-$CHROME_DRIVER_VERSION \
     && chmod 755 /opt/chromedriver-$CHROME_DRIVER_VERSION \
     &&  ln -fs /opt/chromedriver-$CHROME_DRIVER_VERSION /usr/bin/chromedriver \

    # Cleanup
    && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && apt-get clean

COPY m2-settings.xml $MAVEN_CONFIG/settings.xml