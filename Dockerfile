##################################################################################
# Dockerfile for compiling Brave browser (https://github.com/brave/brave-browser)
# Can be called by the bootstrap.sh script or manually:
#   docker build -t chreage .
# If you want to push on https://hub.docker.com/
#   docker login
#   docker tag chreage:latest lecrapouille/chreage:latest
#   docker push lecrapouille/chreage:latest
##################################################################################

# Debian 11
FROM debian:bullseye-slim

# Install packages needed for compiling brave-core and listed by the script
# brave-browser/src/build/install-build-deps.sh Note: this is a modified list
# for Debian 11 since currently install-build-deps.sh returns libappindicator3
# which has been removed and replaced by libayatana-appindicator.
RUN apt-get update
RUN apt-get install -y curl apache2-bin binutils binutils-aarch64-linux-gnu binutils-arm-linux-gnueabihf binutils-mips64el-linux-gnuabi64 binutils-mipsel-linux-gnu bison bzip2 cdbs curl dbus-x11 devscripts dpkg-dev elfutils fakeroot flex git-core gperf lib32gcc-s1 lib32stdc++6 libapache2-mod-php7.4 libayatana-appindicator3-1 libasound2 libasound2-dev libatk1.0-0 libatspi2.0-0 libatspi2.0-dev libbluetooth-dev libbrlapi0.8 libbrlapi-dev libbz2-1.0 libbz2-dev libc6 libc6-dev libc6-i386 libcairo2 libcairo2-dev libcap2 libcap-dev libcups2 libcups2-dev libcurl4-gnutls-dev libdrm2 libdrm-dev libelf-dev libevdev2 libevdev-dev libexpat1 libffi7 libffi-dev libfontconfig1 libfreetype6 libgbm1 libgbm-dev libglib2.0-0 libglib2.0-dev libglu1-mesa-dev libgtk-3-0 libgtk-3-dev libinput10 libinput-dev libjpeg-dev libkrb5-dev libnspr4 libnspr4-dev libnss3 libnss3-dev libpam0g libpam0g-dev libpango-1.0-0 libpci3 libpci-dev libpcre3 libpixman-1-0 libpng16-16 libpulse0 libpulse-dev libsctp-dev libspeechd2 libspeechd-dev libsqlite3-0 libsqlite3-dev libssl-dev libstdc++6 libudev1 libudev-dev libuuid1 libva-dev libvulkan1 libvulkan-dev libwayland-egl1-mesa libwww-perl libx11-6 libx11-xcb1 libxau6 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxdmcp6 libxext6 libxfixes3 libxi6 libxinerama1 libxkbcommon-dev libxrandr2 libxrender1 libxshmfence-dev libxslt1-dev libxss-dev libxt-dev libxtst6 libxtst-dev locales mesa-common-dev openbox p7zip patch perl php7.4-cgi pkg-config python2-dev python-is-python2 python-setuptools rpm ruby subversion uuid-dev wdiff x11-utils xcompmgr xz-utils zip zlib1g

# Clean apt-get install
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

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

# Chreage's project root folder
WORKDIR /workspace
