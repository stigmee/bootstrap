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
### bash script allowing to download and compile Brave browser and Godot.
###

### User settings. Desired versions. If you do not desire to install a
### package unset the value
GODOT_VERSION=3.4-stable
BRAVE_VERSION=v1.32.96

### User settings. Using Docker ? If yes set it with any value (WARNING:
### CURRENTLY EXPERIMENTAL !!)
USING_DOCKER=

### We are supposed to be inside the root folder cloned by
### https://github.com/chreage-rebirth/bootstrap. We save this path.
HERE=`pwd`

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

### Check if docker is installed
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

### Helper function calling docker with good params
function docker_run()
{
    # Get the folder name (without the full path)
    FOLDER="$1"
    shift

    if [ -z "$USING_DOCKER" ]; then
        (cd $FOLDER && $*)
    else
        docker run --rm -ti -v $(pwd):/workspace -w /workspace/$WHERE \
               chreage:latest /bin/bash -c "$*"
    fi
}

### Create the docker image if it does not exist. The docker image will offer
### all packages needed to compile Chreage and its third parts such as Brave,
### Godot ...
if [ ! -z "$USING_DOCKER" ]; then
    docker build \
           --build-arg USER=$USER --build-arg UID=$UID --build-arg GID=$GID \
           -t chreage .
fi

### $1 is the path of the desired Chreage root folder to be created. It will
### hold the whole code source of third-part projects.
WORKSPACE_CHREAGE="$1"
if [ -z "$WORKSPACE_CHREAGE" ]; then
    err "Please define \$1 as the path for your workspace holding "
    err "Chreage project (ie $0 ~/workspace_chreage). Abort!"
    exit 1
fi

### Create and jump to Chreage root folder (or die if it does not exist).
msg "Going to workspace $WORKSPACE_CHREAGE ..."
mkdir -p $WORKSPACE_CHREAGE

### Git clone or update Godot to the desired version.
cd "$WORKSPACE_CHREAGE" || (err "Cannot go to Chreage workspace"; exit 1)
if [ ! -z "$GODOT_VERSION" ]; then
    GODOT_FOLDER="godot"
    if [ -e $GODOT_FOLDER ]; then
        msg "Updating Godot $GODOT_VERSION ..."
        (cd $GODOT_FOLDER && git pull --depth=1)
    else
        msg "Cloning Godot $GODOT_VERSION ..."
        git clone https://github.com/godotengine/godot.git --depth=1 -b $GODOT_VERSION
    fi

    # Call the docker against Chreage workspace to compile Godot ...
    msg "Compiling Godot $GODOT_VERSION ..."
    docker_run "$GODOT_FOLDER" "scons -j$(nproc) platform=linuxbsd"
else
    info "Ignoring Godot (explicitely set by the user)"
fi

### Git clone or update brave-core's bootstraper to the desired version.
cd "$WORKSPACE_CHREAGE" || (err "Cannot go to Chreage workspace"; exit 1)
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

    # Call the docker against Chreage workspace to compile Brave ...
    if [ -f $WORKSPACE_CHREAGE/$BRAVE_FOLDER/out/brave ]; then
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
