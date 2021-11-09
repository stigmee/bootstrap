#!/bin/bash -e
### bash script allowing to download and compile Brave browser.

# We are supposed to be inside the folder cloned by
# https://github.com/chreage-rebirth/bootstrap
# Save this path.
HERE=`pwd`

# Create the docker image if it does not exist. The docker image will offer all
# packages needed to compile Chreage and its third parts such as Brave,
# Godot ...
docker build -t chreage .

# $1 is the path of the desired Chreage root folder to be created and holding
# the whole code source of the project.
WORKSPACE_CHREAGE="$1"
if [ -z $WORKSPACE_CHREAGE ]; then
   echo "Please define \$1 as the path for your workspace holding Chreage project (ie $0 ~/workspace_chreage)"
   exit 1
fi
mkdir -p $WORKSPACE_CHREAGE

# Jump to Chreage root folder (or die if cannot).
cd $WORKSPACE_CHREAGE || (echo "Cannot go to Chreage workspace"; exit 1)

### Remove godot folder if already existing to allow git cloning.
rm -fr godot
git clone https://github.com/godotengine/godot.git --depth=1

### Remove brave-browser folder if already existing to allow git cloning.
rm -fr brave-browser

# Download brave-browser (the bootstraper for compiling brave-core) and apply
# patches to it and to brave-core such as forcing git cloning third-parts
# without their whole history in the aim to save disk usage and save downloading
# time.
git clone https://github.com/brave/brave-browser.git --depth=1
(cd brave-browser
 cp $HERE/patches/brave-browser/0001-Force-depth-1-to-reduce-size.patch .
  git am --signoff < 0001-Force-depth-1-to-reduce-size.patch
  cd src
  git clone https://github.com/brave/brave-core.git --depth=1 brave
  cd brave
  cp $HERE/patches/brave-core/0001-Force-git-cloning-brave-core-with-depth-1-to-save-di.patch .
  cp $HERE/patches/brave-core/0002-Do-not-care-to-be-root-when-inside-docker.patch .
  git am --signoff < 0001-Force-git-cloning-brave-core-with-depth-1-to-save-di.patch
  git am --signoff < 0002-Do-not-care-to-be-root-when-inside-docker.patch
)

# Go inside your Chreage workspace and call the docker against your workspace to
# compile Brave, Godot ...
cd $WORKSPACE_CHREAGE
docker run --rm -ti -v $(pwd):/workspace -w /workspace/godot chreage:latest /bin/bash -c "scons -j$(nproc) platform=linuxbsd"
docker run --rm -ti -v $(pwd):/workspace -w /workspace/brave-browser chreage:latest /bin/bash -c "npm install; npm run init; npm run build"
