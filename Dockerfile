FROM openjdk:8

MAINTAINER Entria <developers@entria.com.br>

RUN mkdir -p /opt/app
WORKDIR /opt/app

ENV DEBIAN_FRONTEND noninteractive

# Install general dependencies
RUN dpkg --add-architecture i386 && apt-get update && apt-get install -yq \
    apt-transport-https \
    autoconf \
    automake \
    build-essential \
    libc6:i386 \
    libncurses5:i386 \
    libstdc++6:i386 \
    python \
    python-dev \
    python-pip \
    python-setuptools \
    software-properties-common \
    zlib1g:i386 \
    zlib1g-dev \
    --no-install-recommends

# Install AWS CLI
RUN pip install --upgrade awscli

ENV RUBY_VERSION="2.4.4"
ENV ANDROID_HOME="/opt/android-sdk-linux"
ENV ANDROID_SDK="${ANDROID_HOME}"
ENV PATH="${ANDROID_SDK}/tools:${ANDROID_SDK}/platform-tools:${ANDROID_SDK}/tools/bin:${PATH}"
RUN echo "export PATH=${PATH}" > /root/.profile

# Install Android SDK (based on: https://github.com/gfx/docker-android-project/blob/master/Dockerfile)
# See for CircleCI Issue:
#  https://discuss.circleci.com/t/failed-to-register-layer-error-processing-tar-file-exit-status-1-container-id-249512-cannot-be-mapped-to-a-host-id/13453/5
# Grab URL from footer of https://developer.android.com/studio/index.html
# Following URL is for 26.0.2
ENV ANDROID_SDK_URL https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip

#ENV ANDROID_BUILD_TOOLS_VERSION 26.0.2,25.0.3
#ENV ANDROID_API_LEVELS android-26,android-25
#ENV ANDROID_COMPONENTS platform-tools,build-tools-${ANDROID_BUILD_TOOLS_VERSION},${ANDROID_API_LEVELS}
#ENV GOOGLE_COMPONENTS extra-android-m2repository,extra-google-m2repository,extra-google-google_play_services,extra-google-gcm

RUN curl -L "${ANDROID_SDK_URL}" -o /tmp/android-sdk-linux.zip && \
    unzip /tmp/android-sdk-linux.zip -d /opt/ && \
    chown -R root:root /opt && \
    rm /tmp/android-sdk-linux.zip && \
    mkdir ${ANDROID_HOME} && \
    mv /opt/tools ${ANDROID_HOME}/ && \
    ls ${ANDROID_HOME} && \
    ls ${ANDROID_HOME}/tools && chown -R root:root ${ANDROID_HOME} 

# Install Android SDK components
RUN echo y | sdkmanager "platform-tools" "build-tools;26.0.2" "build-tools;25.0.3" "platforms;android-26" "platforms;android-25" \
                "extras;google;m2repository" "extras;android;m2repository" "extras;google;google_play_services"

# Install Watchman
RUN git clone https://github.com/facebook/watchman.git && \
    cd watchman && \
    git checkout v4.7.0 && \
    ./autogen.sh && ./configure && make && make install && cd .. && rm -rf watchman

# Install Ruby and RubyGems
RUN wget http://ftp.ruby-lang.org/pub/ruby/ruby-${RUBY_VERSION}.tar.gz && \
    tar -xzf ruby-${RUBY_VERSION}.tar.gz && \
    rm ruby-${RUBY_VERSION}.tar.gz && \
    cd ruby-${RUBY_VERSION}/ && \
    ./configure && make && make install

# Install bundler
RUN gem install bundler

# Install Node JS and Yarn
# https://github.com/nodejs/docker-node/blob/12ba2e5432cd50037b6c0cf53464b5063b028227/8.1/Dockerfile
ENV NPM_CONFIG_LOGLEVEL info
ENV NODE_VERSION 8.1.2
ENV YARN_VERSION 0.24.6

RUN groupadd --gid 1000 node && \
    useradd --uid 1000 --gid node --shell /bin/bash --create-home node

# gpg keys listed at https://github.com/nodejs/node#release-team
RUN set -ex \
    && for key in \
        9554F04D7259F04124DE6B476D5A82AC7E37093B \
        94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
        FD3A5288F042B6850C66B31F09FE44734EB7990E \
        71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
        DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
        B9AE9905FFD7803F25714661B63B535A4C206CA9 \
        C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
        56730D5401028683275BD23C23EFEFE93C4CFFFE \
    ; do \
        gpg --keyserver pgp.mit.edu --recv-keys "$key" || \
        gpg --keyserver keyserver.pgp.com --recv-keys "$key" || \
        gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" ; \
    done

RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" && \
    curl -SLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" && \
    gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc && \
    grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - && \
    tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 && \
    rm "node-v$NODE_VERSION-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt && \
    ln -s /usr/local/bin/node /usr/local/bin/nodejs

RUN set -ex && \
    for key in \
        6A010C5166006599AA17F08146C2130DFD2497F5 \
    ; do \
        gpg --keyserver pgp.mit.edu --recv-keys "$key" || \
        gpg --keyserver keyserver.pgp.com --recv-keys "$key" || \
        gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" ; \
    done && \
    curl -fSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" && \
    curl -fSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc" && \
    gpg --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz && \
    mkdir -p /opt/yarn && \
    tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/yarn --strip-components=1 && \
    ln -s /opt/yarn/bin/yarn /usr/local/bin/yarn && \
    ln -s /opt/yarn/bin/yarn /usr/local/bin/yarnpkg && \
    rm yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz

# Clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    apt-get autoremove -y && \
    apt-get clean

# Support Gradle
ENV TERM dumb

# Install code-push-cli
RUN npm install -g code-push-cli && chown -R root:root /usr/local/lib/node_modules/code-push-cli/node_modules

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
