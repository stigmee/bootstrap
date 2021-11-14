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

source settings.sh

### If docker is desired then check if docker is installed
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

### Helper function calling a command with or without docker
# $1: the folder name (not its full path). Shall exist!
# $*: the command to execute
function docker_run()
{
    # Get the folder name (without the full path)
    FOLDER="$1"
    shift

    # Docker not desired: call the command directly
    if [ -z "$USING_DOCKER" ]; then
        (cd $FOLDER && $*)
    else
        # Call the command inside docker
        docker run --rm -ti -v $(pwd):/workspace -w /workspace/$WHERE \
               chreage:latest /bin/bash -c "$*"
    fi
}

### Create the docker image for Stigmee if it does not exist. The docker image will offer
### all packages needed to compile Stigmee's third parts such as Brave, CEF,
### Godot and finally Stigmee.
if [ ! -z "$USING_DOCKER" ]; then
    docker build \
           --build-arg USER=$USER --build-arg UID=$UID --build-arg GID=$GID \
           -t chreage .
fi

### $1 is the path of the desired Stigmee root folder to be created. It will
### hold the whole code source of third-part projects.
WORKSPACE_STIGMEE="$1"
if [ -z "$WORKSPACE_STIGMEE" ]; then
    err "Please define \$1 as the path for your workspace holding "
    err "Stigmee project (ie $0 ~/workspace_chreage). Abort!"
    exit 1
fi

### Create and jump to Stigmee root folder (or die if it does not exist).
msg "Going to workspace $WORKSPACE_STIGMEE ..."
mkdir -p $WORKSPACE_STIGMEE

###############################################################################
### Git clone or update Godot to the desired version.
###############################################################################
cd "$WORKSPACE_STIGMEE" || (err "Cannot go to Stigmee workspace"; exit 1)
if [ ! -z "$GODOT_VERSION" ]; then
    GODOT_FOLDER="godot"
    if [ -e $GODOT_FOLDER ]; then
        msg "Updating Godot $GODOT_VERSION ..."
        (cd $GODOT_FOLDER && git pull --depth=1)
    else
        msg "Cloning Godot $GODOT_VERSION ..."
        git clone https://github.com/godotengine/godot.git --depth=1 -b $GODOT_VERSION
    fi

    # Call the docker against Stigmee workspace to compile Godot ...
    msg "Compiling Godot $GODOT_VERSION ..."
    docker_run "$GODOT_FOLDER" "scons -j$(nproc) platform=linuxbsd"
else
    info "Ignoring Godot (explicitely set by the user)"
fi

###############################################################################
### Git clone or update Chromium Embedded Framework's bootstraper to the desired
### version.
###############################################################################
CEF_VERSION=$CHROMIUM_EMBEDDED_FRAMEWORK_VERSION
cd "$WORKSPACE_STIGMEE" || (err "Cannot go to Stigmee workspace"; exit 1)
if [ ! -z "$CEF_VERSION" ]; then
    CEF_FOLDER="CEF"
    mkdir -p $CEF_FOLDER
    (cd $CEF_FOLDER
     # This script works well but git clone with full history. For the moment use our hand-patched script
     # curl https://bitbucket.org/chromiumembedded/cef/raw/master/tools/automate/automate-git.py --output bootstrap.py
     cp $HERE/patches/CEF/bootstrap.py .

     msg "Cloning chromium embedded framework $CEF_VERSION ..."
     python bootstrap.py --download-dir="." --branch="$CEF_VERSION"
    )
else
    info "Ignoring CEF (explicitely set by the user)"
fi

###############################################################################
### Git clone or update brave-core's bootstraper to the desired version.
###############################################################################
cd "$WORKSPACE_STIGMEE" || (err "Cannot go to Stigmee workspace"; exit 1)
if [ ! -z "$BRAVE_VERSION" ]; then
    BRAVE_FOLDER="brave-browser"
    if [ -e $BRAVE_FOLDER ]; then
        msg "Updating brave-browser $BRAVE_VERSION ..."
        (cd $BRAVE_FOLDER &&  git pull --depth=1)
        (cd $BRAVE_FOLDER/src && git pull --depth=1)
    else
        msg "Cloning brave-browser $BRAVE_VERSION ..."
        git clone https://github.com/brave/brave-browser.git --depth=1 -b $BRAVE_VERSION

        msg "Patching brave-browser $BRAVE_VERSION ..."
        (cd $BRAVE_FOLDER
         cp $HERE/patches/brave-browser/0001-Force-depth-1-to-reduce-size.patch .
         git am --signoff < 0001-Force-depth-1-to-reduce-size.patch
         cd src
         git clone https://github.com/brave/brave-core.git --depth=1 -b $BRAVE_VERSION brave
         cd brave
         cp $HERE/patches/brave-core/0001-Force-git-cloning-brave-core-with-depth-1-to-save-di.patch .
         cp $HERE/patches/brave-core/0002-Do-not-care-to-be-root-when-inside-docker.patch .
         git am --signoff < 0001-Force-git-cloning-brave-core-with-depth-1-to-save-di.patch
         git am --signoff < 0002-Do-not-care-to-be-root-when-inside-docker.patch
        )
    fi

    # Call the docker against Stigmee workspace to compile Brave ...
    if [ -f $WORKSPACE_STIGMEE/$BRAVE_FOLDER/out/brave ]; then
        msg "Synchronizing brave-browser $BRAVE_VERSION ..."
        docker_run "$BRAVE_FOLDER" "npm run sync"
    else
        msg "Compiling brave-browser $BRAVE_VERSION ..."
        docker_run "$BRAVE_FOLDER" "npm install"
        docker_run "$BRAVE_FOLDER" "npm run init"
    fi
    docker_run "$BRAVE_FOLDER" "npm run build Component"
else
    info "Ignoring Brave (explicitely set by the user)"
fi

info "DONE"
