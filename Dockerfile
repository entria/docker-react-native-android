FROM openjdk:8

MAINTAINER Entria <developers@entria.com.br>

ENV DEBIAN_FRONTEND noninteractive

# Install general dependencies
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -yq python python-dev python-pip python-virtualenv autoconf automake apt-transport-https git build-essential \
     libc6:i386 libstdc++6:i386 zlib1g:i386 libncurses5:i386 --no-install-recommends && \
    apt-get clean

ENV ANDROID_HOME="/opt/android-sdk-linux"
ENV ANDROID_SDK="${ANDROID_HOME}"
ENV PATH="${ANDROID_SDK}/tools:${ANDROID_SDK}/platform-tools:${PATH}"
RUN echo "export PATH=${PATH}" > /root/.profile

ENV ANDROID_BUILD_TOOLS_VERSION 25.0.3
ENV ANDROID_API_LEVELS android-25
ENV ANDROID_COMPONENTS platform-tools,build-tools-${ANDROID_BUILD_TOOLS_VERSION},${ANDROID_API_LEVELS}
ENV GOOGLE_COMPONENTS extra-android-m2repository,extra-google-m2repository,extra-google-google_play_services,extra-google-gcm

# Install Android SDK (based on: https://github.com/gfx/docker-android-project/blob/master/Dockerfile)
ENV ANDROID_SDK_URL https://dl.google.com/android/repository/tools_r${ANDROID_BUILD_TOOLS_VERSION}-linux.zip
RUN curl -L "${ANDROID_SDK_URL}" -o /tmp/android-sdk-linux.zip
RUN unzip /tmp/android-sdk-linux.zip -d /opt/
RUN rm /tmp/android-sdk-linux.zip
RUN mkdir ${ANDROID_HOME}
RUN mv /opt/tools ${ANDROID_HOME}/
RUN ls ${ANDROID_HOME}
RUN ls ${ANDROID_HOME}/tools

# Install Android SDK components
RUN echo y | android update sdk --no-ui --all --filter "${ANDROID_COMPONENTS}" ; \
    echo y | android update sdk --no-ui --all --filter "${GOOGLE_COMPONENTS}"

# Install Watchman
RUN git clone https://github.com/facebook/watchman.git && \
    cd watchman && \
    git checkout v4.7.0 && \
    ./autogen.sh && ./configure && make && make install

# install Node JS and Yarn
ENV NPM_CONFIG_LOGLEVEL info

# https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions
# https://yarnpkg.com/pt-BR/docs/install#linux-tab
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash
RUN apt-get install -y nodejs yarn

# Add React Native CLI
RUN npm install -g react-native-cli

# Support Gradle
ENV TERM dumb

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
