##################################################################################
# Dockerfile for compiling Brave browser (https://github.com/brave/brave-browser)
# Can be called by the bootstrap.sh script or manually:
#   docker build -t stigmee .
# If you want to push on https://hub.docker.com/ replace lecrapouille by your login
#   docker login
#   docker tag stigmee:latest lecrapouille/stigmee:latest
#   docker push lecrapouille/stigmee:latest
##################################################################################

# Debian 10 (do not use yet Debian 11)
FROM debian:buster-slim

# Install general system packages
RUN apt-get update
RUN apt-get install -y bash curl lsb-release flex git-core gperf pkg-config zip bzip2 p7zip patch xz-utils sudo

SHELL ["/bin/bash", "-c"]

# Install packages needed for compiling Godot
RUN apt-get install -y build-essential scons libx11-dev libxcursor-dev libxinerama-dev libgl1-mesa-dev libglu-dev libasound2-dev libpulse-dev libudev-dev libxi-dev libxrandr-dev

# Install packages needed for compiling Chromium Embedded Framework
RUN curl 'https://chromium.googlesource.com/chromium/src/+/master/build/install-build-deps.sh?format=TEXT' | base64 -d > /tmp/cef-install-build-deps.sh
RUN chmod +x /tmp/cef-install-build-deps.sh
RUN ./tmp/cef-install-build-deps.sh --arm --no-chromeos-fonts --no-prompt
RUN if [[ "`dpkg --print-architecture`" == "arm64" ]]; then ./tmp/cef-install-build-deps.sh --arm --no-chromeos-fonts --no-prompt; \
else ./tmp/cef-install-build-deps.sh --no-arm --no-chromeos-fonts --no-prompt --no-nacl; fi

# Install packages needed for compiling brave-core and listed by the script
# brave-browser/src/build/install-build-deps.sh Note: this is a modified list
# for Debian 11 since currently install-build-deps.sh returns libappindicator3
# which has been removed and replaced by libayatana-appindicator.
# RUN apt-get install -y apache2-bin binutils binutils-aarch64-linux-gnu binutils-arm-linux-gnueabihf binutils-mips64el-linux-gnuabi64 binutils-mipsel-linux-gnu bison cdbs dbus-x11 devscripts dpkg-dev elfutils fakeroot lib32gcc-s1 lib32stdc++6 libapache2-mod-php7.4 libayatana-appindicator3-1 libasound2 libasound2-dev libatk1.0-0 libatspi2.0-0 libatspi2.0-dev libbluetooth-dev libbrlapi0.8 libbrlapi-dev libbz2-1.0 libbz2-dev libc6 libc6-dev libc6-i386 libcairo2 libcairo2-dev libcap2 libcap-dev libcups2 libcups2-dev libcurl4-gnutls-dev libdrm2 libdrm-dev libelf-dev libevdev2 libevdev-dev libexpat1 libffi7 libffi-dev libfontconfig1 libfreetype6 libgbm1 libgbm-dev libglib2.0-0 libglib2.0-dev libglu1-mesa-dev libgtk-3-0 libgtk-3-dev libinput10 libinput-dev libjpeg-dev libkrb5-dev libnspr4 libnspr4-dev libnss3 libnss3-dev libpam0g libpam0g-dev libpango-1.0-0 libpci3 libpci-dev libpcre3 libpixman-1-0 libpng16-16 libpulse0 libpulse-dev libsctp-dev libspeechd2 libspeechd-dev libsqlite3-0 libsqlite3-dev libssl-dev libstdc++6 libudev1 libudev-dev libuuid1 libva-dev libvulkan1 libvulkan-dev libwayland-egl1-mesa libwww-perl libx11-6 libx11-xcb1 libxau6 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxdmcp6 libxext6 libxfixes3 libxi6 libxinerama1 libxkbcommon-dev libxrandr2 libxrender1 libxshmfence-dev libxslt1-dev libxss-dev libxt-dev libxtst6 libxtst-dev locales mesa-common-dev openbox perl php7.4-cgi python2-dev python-is-python2 python-setuptools rpm ruby subversion uuid-dev wdiff x11-utils xcompmgr zlib1g

# Install the good version of node.js not impacted by the following error
# message: "fatal: repository 'undefined' does not exist" (see
# https://github.com/brave/brave-browser/issues/13631) Beware not all node.js
# are good (v10.24.1:ok, v12.22.5: ko, v12.22.7: ok, v16.13.0: ko)
ENV NODE_VERSION=12.22.7
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.39.0/install.sh | bash
ENV NVM_DIR=/root/.nvm
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"
RUN node --version
RUN npm --version

# Clean and supress repo lists needed for apt-get install
# No more installation will be able after this command
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Stigmee workspace folder
ENV WORKSPACE=/workspace
WORKDIR $WORKSPACE
