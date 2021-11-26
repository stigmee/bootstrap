# Stigmee setup and code source compilation

Stigmee's development is depending on the following projects as third parts:

- Godot: https://github.com/godotengine/godot for the 3d rendering
- Chromium Embedded Framework (CEF)
  https://bitbucket.org/chromiumembedded/cef/src/master/
- (Brave-core: https://github.com/brave/brave-browser replaced by CEF).

This document will explain how bootstraping Stigmee (meaning downloading
third-parts, doing the setup, compiling third-parts and Stigmee project) on
Linux (for the moment). Depending on the environment of your operating system,
you may have more or less difficulties to compile third parts if you are trying
to compile them [directly](https://github.com/stigmee/doc#installation)) that is
why we are also offering a [Dockerfile](Dockerfile) (optionaly called by
bootstrap.sh) to offer you a correct compilation environment (**Note:** the
usage of docker is still experimental since exporting the display an Vulkan for
Docker can be difficult. More information [here](https://github.com/stigmee/doc/blob/master/doc/tuto_docker_fr.md)).

For these reasons, you will just have to use the **entry-point** script
[bootstrap.sh](bootstrap.sh).

## Prerequisites

**Be sure you have around 60 gigabytes of free space on your hard disk.**

You will just need two install two packages (`apt-get install`
for example):
- Docker (or Podman which is a Docker without daemon and you can `alias
  docker=podman` for following this document).
- Git to download the code source and apply patches.

### Downloading stigmee docker image

- Create a docker Hub account and go to the following repository : https://hub.docker.com/r/lecrapouille/stigmee
- Copy the command line and paste it into a powershell terminal

```bash
PS D:\Docker> docker pull lecrapouille/stigmee
Using default tag: latest
latest: Pulling from lecrapouille/stigmee
Digest: sha256:580216370dc62ca1119e5ead8670ca8c1c9183561c38114254c5acc74945680c
Status: Image is up to date for lecrapouille/stigmee:latest
docker.io/lecrapouille/stigmee:latest
```

**Note:** in some case the remote image was modified and `docker pull` will synchronize your local image. The time for downloading the whole image will depend on your connection speed (around 1.5 Gb). You can then start the docker container from that image. For more information about Docker see [this document](https://github.com/stigmee/doc/blob/master/doc/tuto_docker_fr.md).

### Set you Bash/PowerShell environment for Stigmee

Save this in your `~/.bashrc` file (or any equivalent file):

- The environement variable `$WORKSPACE_STIGMEE` refering to the workspace folder for compiling Stigmee.
```bash
export WORKSPACE_STIGMEE=/your/desired/path/for/stigmee_workspace
```

- For developpers, save this command which will allow you to jump into your Stigmee workspace and call Docker against Stigmee's folder for compiling them.
```bash
function docker_stigmee()
{
    echo "Dockered Stigmee's workspace at $WORKSPACE_CHREAGE"
    (cd $WORKSPACE_CHREAGE || (echo "No Stigmee workspace found"; exit 1)
     docker run --rm -ti -v $(pwd):/workspace -w /workspace/$FOLDER \
         -u $(id -u ${USER}):$(id -g ${USER}) stigmee:latest /bin/bash
    )
}
```

## Bootstraping Stigmee Project

- Create the workspace folder:
```bash
mkdir -p $WORKSPACE_STIGMEE
cd $WORKSPACE_STIGMEE
```

- git clone the bootstraper git repo:
```bash
git clone https://github.com/stigmee-rebirth/bootstrap.git --depth=1
cd bootstrap
```

- Install the needed packages for your operating system. We are offering you a meta-package for this.
A meta package is package holding the list of packages to install. In this way, the package manager will
make the graph of dependencies which will automatically uninstall unused packages the day you desired to
uninstall Stigmee (See [meta/README.md](meta/README.md) for more informations).
**Note:** this is still experimental and only working for Debian 11 (work in progress).
```bash
apt-get install ./meta/stigmee-developpers_1.0_all.deb
# Alternative:
# sudo dpkg -i ./meta/stigmee-developpers_1.0_all.deb
```

- Optionally, you can edit some settings inside the script [bootstrap.sh](bootstrap.sh) :
  - The versions for Godot (currently `GODOT_VERSION=3.4-stable`), CEF (currently
    `CHROMIUM_EMBEDDED_FRAMEWORK_VERSION=4664`), Brave (is not currently compile but if
    needed, in the future, set `BRAVE_VERSION=v1.32.96`). **Note:** Unseting the version
    will make the force ignore the third-part to be installed (like currently for Brave).
  - If you want to compile Stigmee using Docker (`USING_DOCKER=1`) or not (`USING_DOCKER=`)
    **Note:** Docker is still experimental.

- Execute the bash script. It will git clone and start the compilation:
```bash
./bootstrap.sh $WORKSPACE_STIGMEE
```

- After long hours of compilation (if you see this king of message `[1:16:30] Still working on: src` during hours, this step is normal).
  - If Docker was not used:
    - you can run Godot: `$WORKSPACE_STIGMEE/godot/bin/godot.linuxbsd.tools.64`
    - you can run Brave (if installed): `cd $WORKSPACE_STIGMEE; npm start Component`
  - If Docker was used:
```bash
TODO
#Xephyr -resizeable :1 &
#
#docker run --rm -ti  --shm-size 1GB  -e DISPLAY=:1 -v /tmp/.X11-unix:/tmp/.X11-unix -v $(pwd):/workspace -w /#workspace/brave-browser stigmee:latest /bin/bash -c "/workspace/brave-browser/src/out/Component/brave --enable-#logging --v=0 --disable-brave-update --no-sandbox"
#
# $WORKSPACE_STIGMEE/godot/bin/godot.linuxbsd.tools.64
```

- With Docker, if you want to modify the Stigmee's code source and recompile it:
```bash
cd $WORKSPACE_STIGMEE
docker run --rm -ti -u $(id -u ${USER}):$(id -g ${USER}) -v $(pwd):/workspace -w /workspace stigmee:latest /bin/bash
```

For explanations of the command line: see [README](https://github.com/stigmee/doc/blob/master/doc/tuto_docker_fr.md) for more information.
