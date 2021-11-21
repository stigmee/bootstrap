#!/bin/bash -e
###############################################################################
## Stigmee: A 3D browser and decentralized social network.
## Copyright 2021 Quentin Quadrat <lecrapouille@gmail.com>
##
## This file is part of Stigmee.
##
## Stigmee is free software: you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.
###############################################################################
###
### bash script allowing to download and compile Brave browser, FCE, Godot ...
### needed for https://github.com/stigmee
###
### Command line: $1 the (existing or not existing) Stigmee's workspace path
### in which all Stigmee and third parts will be stored.
###
###############################################################################

###############################################################################
### USER SETTINGS
###############################################################################

# Set here Stigmee's third-part desired versions. If you do not desire to
# install a third-part unset its version.
GODOT_VERSION=3.4-stable
BRAVE_VERSION= #v1.32.96
CHROMIUM_EMBEDDED_FRAMEWORK_VERSION=4664 # FIXME not used yet, track the HEAD

# Use Docker for building Stigmee ? If no unset the variable !
USING_DOCKER=1

###############################################################################
### Color messages
###############################################################################

# Green color message
function msg
{
    echo -e "\033[32m*** $*\033[00m"
}

# Orange color message
function info
{
    echo -e "\033[36m*** $*\033[00m"
}

# Red color message
function err
{
    echo -e "\033[31m*** $*\033[00m"
}

###############################################################################
### Check the command line.
### $1 is the path of the desired Stigmee root folder to be created. It will
### hold the whole code source of third-part projects.
###############################################################################
WORKSPACE_STIGMEE="$1"
if [ -z "$WORKSPACE_STIGMEE" ]; then
    err "Please define \$1 as the path for your workspace holding "
    err "Stigmee project (ie $0 ~/workspace_stigmee). Abort!"
    exit 1
fi

# Subfolders relative to $WORKSPACE_STIGMEE folder
STIGMEE_FOLDER=$WORKSPACE_STIGMEE/stigmee
GODOT_FOLDER=$WORKSPACE_STIGMEE/godot
CEF_FOLDER=$WORKSPACE_STIGMEE/CEF
BRAVE_FOLDER=$WORKSPACE_STIGMEE/brave-browser

# We are supposed to be inside the root folder cloned by https://github.com/stigmee/bootstrap
# This folder may not be inside $WORKSPACE_STIGMEE. We save this path.
BOOTSRAP_FOLDER=`pwd`

###############################################################################
### Get the operating system.
###############################################################################
OS=`uname -s`
if [ "$OS" != "Linux" ]; then
    err "Operating System $OS not yet managed"
    exit 1
fi

###############################################################################
### If docker is desired then check if docker is installed.
###############################################################################
if [ -z "$USING_DOCKER" ]; then
    info "You have not requested using docker"
else
    info "You have requested using docker"
    USING_DOCKER=`echo which docker`
    if [ -z "$USING_DOCKER" ]; then
        err "It seems that you have no docker installed. Abort!"
        exit 1
    fi
fi

###############################################################################
### Create the docker image for Stigmee if it does not exist. The docker image
### will offer all packages needed to compile Stigmee's third parts such as CEF,
### (Brave?), Godot and finally Stigmee.
###############################################################################
if [ ! -z "$USING_DOCKER" ]; then
    (cd $BOOTSRAP_FOLDER && \
         docker build \
                --build-arg USER=$USER --build-arg UID=$UID --build-arg GID=$GID \
                -t stigmee .
    )
fi

###############################################################################
### Helper function calling a command with or without docker
### $1: the folder name (not its full path). Shall exist!
### $*: the command to execute.
###############################################################################
function cmd()
{
    if [ -z "$USING_DOCKER" ]; then
        # Docker not desired: call the command directly
        FOLDER=$1
        shift
        msg "Command: cd $FOLDER && $*"
        (cd $FOLDER && $*)
    else
        # Call the command inside docker
        FOLDER=`basename $1`
        shift
        msg "Dockering command: cd $FOLDER && $*"
        (cd $WORKSPACE_STIGMEE && \
             docker run --rm -ti -v $(pwd):/workspace -w /workspace/$FOLDER \
                    stigmee:latest /bin/bash -c "$*"
        )
    fi
}

###############################################################################
### Create and jump to Stigmee root folder (or die if it does not exist).
###############################################################################
msg "Going to workspace $WORKSPACE_STIGMEE ..."
mkdir -p $WORKSPACE_STIGMEE
cd $WORKSPACE_STIGMEE || (err "Cannot go to Stigmee workspace"; exit 1)

###############################################################################
### Git clone or update Chromium Embedded Framework's bootstraper to the desired
### version.
###############################################################################
cd $WORKSPACE_STIGMEE
CEF_VERSION=$CHROMIUM_EMBEDDED_FRAMEWORK_VERSION
if [ ! -z "$CEF_VERSION" ]; then
    if [ -d $CEF_FOLDER -a -e $CEF_FOLDER/.done ]; then
        info "Nothing to do for CEF"
    else
        mkdir -p $CEF_FOLDER/automate $CEF_FOLDER/chromium_git
        cd $CEF_FOLDER || (err "Cannot go to CEF folder"; exit 1)

        # Install system packages
        if [ -z "$USING_DOCKER" ]; then
            SCRIPT=/tmp/cef-install-build-deps.sh
            curl 'https://chromium.googlesource.com/chromium/src/+/master/build/install-build-deps.sh?format=TEXT' | base64 -d > $SCRIPT
            chmod +x /tmp/cef-install-build-deps.sh
            ./tmp/cef-install-build-deps.sh --arm --no-chromeos-fonts --no-prompt
            if [ "`dpkg --print-architecture`" == "arm64" ]; then
                ./$SCRIPT --arm --no-chromeos-fonts --no-prompt
            else
                ./$SCRIPT --no-arm --no-chromeos-fonts --no-prompt --no-nacl
            fi
        fi

        # Configure CEF
        export PATH=$CEF_FOLDER/depot_tools:$PATH

        if [ "`dpkg --print-architecture`" == "arm64" ]; then
            export GYP_DEFINES="target_arch=arm64"
            export GN_DEFINES="is_official_build=true use_sysroot=true use_allocator=none symbol_level=1 enable_nacl=false use_cups=false"
            export CEF_INSTALL_SYSROOT="arm64"
            export EXTRA_AUTOMATE_ARGS="--arm64-build"
            export NINJA_DEBUG_ARGS="-C out/Debug_GN_arm64"
            export NINJA_RELEASE_ARGS="-C out/Release_GN_arm64"
        else
            export CEF_USE_GN=1
            export GYP_DEFINES="disable_nacl=1 use_sysroot=1 buildtype=Official use_allocator=none"
            export GN_DEFINES="is_official_build=true use_sysroot=true use_allocator=none symbol_level=1 enable_nacl=false use_cups=false"
            export NINJA_DEBUG_ARGS="-C out/Debug_GN_x64"
            export NINJA_RELEASE_ARGS="-C out/Release_GN_x64"
            export EXTRA_AUTOMATE_ARGS="--x64-build"
            export CHROME_DEVEL_SANDBOX=/usr/local/sbin/chrome-devel-sandbox
        fi

        # Install packages needed for compiling CEF
        msg "Installing packages for chromium embedded framework $CEF_VERSION ..."
        cd $CEF_FOLDER && git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
        cd $CEF_FOLDER/automate
        # This script works well but git clone with full history. For the moment use our hand-patched script
        # curl https://bitbucket.org/chromiumembedded/cef/raw/master/tools/automate/automate-git.py --output automate-git.py
        cp $BOOTSRAP_FOLDER/patches/CEF/bootstrap.py automate-git.py
        cd $CEF_FOLDER/chromium_git

        # Build CEF
        msg "Building chromium embedded framework $CEF_VERSION ..."
        python $CEF_FOLDER/automate/automate-git.py \
               --download-dir=$CEF_FOLDER/chromium_git \
               --depot-tools-dir=$CEF_FOLDER/depot_tools \
               --no-distrib --no-build $EXTRA_AUTOMATE_ARGS # \
               # --branch=$CHROMIUM_EMBEDDED_FRAMEWORK_VERSION
        $CEF_FOLDER/docker/install_sysroot_wrapper.sh
        cd $CEF_FOLDER/chromium_git/chromium/src/cef && ./cef_create_projects.sh
        cd $CEF_FOLDER/chromium_git/chromium/src
        ninja ${NINJA_DEBUG_ARGS} cefsimple chrome_sandbox
        ninja ${NINJA_RELEASE_ARGS} cefsimple chrome_sandbox

        # Add a summy file indicating the compilation has ended with success
        # FIXME: detect libcef instead
        touch $CEF_FOLDER/.done
    fi
else
    info "Ignoring CEF (explicitly set by the user)"
fi

###############################################################################
### Git clone or update brave-core's bootstraper to the desired version.
###############################################################################
cd $WORKSPACE_STIGMEE
if [ ! -z "$BRAVE_VERSION" ]; then
    if [ -d $BRAVE_FOLDER ]; then
        msg "Updating brave-browser $BRAVE_VERSION ..."
        (cd $BRAVE_FOLDER && git pull --depth=1)
        (cd $BRAVE_FOLDER/src && git pull --depth=1)
    else
        msg "Cloning brave-browser $BRAVE_VERSION ..."
        git clone https://github.com/brave/brave-browser.git --depth=1 -b $BRAVE_VERSION

        msg "Patching brave-browser $BRAVE_VERSION ..."
        cd $BRAVE_FOLDER
        cp $BOOTSRAP_FOLDER/patches/brave-browser/0001-Force-depth-1-to-reduce-size.patch .
        git am --signoff < 0001-Force-depth-1-to-reduce-size.patch
        cd src
        git clone https://github.com/brave/brave-core.git --depth=1 -b $BRAVE_VERSION brave
        cd brave
        cp $BOOTSRAP_FOLDER/patches/brave-core/0001-Force-git-cloning-brave-core-with-depth-1-to-save-di.patch .
        cp $BOOTSRAP_FOLDER/patches/brave-core/0002-Do-not-care-to-be-root-when-inside-docker.patch .
        git am --signoff < 0001-Force-git-cloning-brave-core-with-depth-1-to-save-di.patch
        git am --signoff < 0002-Do-not-care-to-be-root-when-inside-docker.patch
    fi

    # Call the docker against Stigmee workspace to compile Brave ...
    if [ -d $BRAVE_FOLDER/out/brave ]; then
        msg "Synchronizing brave-browser $BRAVE_VERSION ..."
        cmd "$BRAVE_FOLDER" "npm run sync"
    else
        msg "Compiling brave-browser $BRAVE_VERSION ..."
        cmd "$BRAVE_FOLDER" "npm install"
        cmd "$BRAVE_FOLDER" "npm run init"
    fi
    cmd "$BRAVE_FOLDER" "npm run build Component"
else
    info "Ignoring Brave (explicitly set by the user)"
fi

###############################################################################
### Git clone or update Godot to the desired version.
###############################################################################
cd $WORKSPACE_STIGMEE
if [ ! -z "$GODOT_VERSION" ]; then
    if [ -d $GODOT_FOLDER ]; then
        msg "Updating Godot $GODOT_VERSION ..."
        (cd $GODOT_FOLDER && git pull --depth=1)
    else
        msg "Cloning Godot $GODOT_VERSION ..."
        git clone https://github.com/godotengine/godot.git --depth=1 -b $GODOT_VERSION
    fi

    # Call the docker against Stigmee workspace to compile Godot ...
    msg "Compiling Godot $GODOT_VERSION ..."
    cmd "$GODOT_FOLDER" "scons -j$(nproc) platform=linuxbsd"
else
    info "Ignoring Godot (explicitly set by the user)"
fi

###############################################################################
### Git clone or update Stigmee.
###############################################################################
cd $WORKSPACE_STIGMEE
if [ -d $STIGMEE_FOLDER ]; then
    msg "Updating Stigmee ..."
else
    # Copy the Godot's CEF module
    msg "Cloning Stigmee ..."
    git clone https://github.com/Lecrapouille/bacasablemodulegodotcef.git --depth=1 $STIGMEE_FOLDER

    # Copy Stigmee's Godot modules into Godot's code source"
    msg "Copying Godot's modules ..."
    cp -TR $STIGMEE_FOLDER/godot_modules $GODOT_FOLDER/modules
fi

# Compile Stigmee modules for Godot
if [ -d $GODOT_FOLDER ]; then
    cd $GODOT_FOLDER && scons -j$(nproc) platform=linuxbsd
else
    err "Godot folder does not exist: CEF modules not compiled !"
fi

info "DONE"
