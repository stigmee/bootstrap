# Chreage setup and code source compilation

Chreage's development will mainly depend on two major projects:
- Brave-core: https://github.com/brave/brave-browser
- Godot: https://github.com/godotengine/godot

This document will explain how to setup and compile the whole project.

## Compiling Brave's code source

Brave code source is made of two parts:
- https://github.com/brave/brave-core which contains the C++ code source.
- https://github.com/brave/brave-browser: the bootsraper for downloading
  third-parts and compiling brave-core.

The whole code source, git repos and compiled files of Brave will use more than
60 gigabytes on your hard disk (but this depends on your operating system) and
can hold several hours for compiling more than 50000 files. You have two choices
for compiling it:
- The straight method by following their documentation.
- Our suggested method: using Docker.

Depending on the environment of your operating system, you may have more or less
difficulties to compile Brave. Problems we had:
- All third part elements are git cloning with their whole git history which
  takes a lot of space.
- On Debian 11, libappindicator3 has been removed and replaced by
  libayatana-appindicator.
- You need the good version of node.js (v10.24.1: ok, v12.22.5: ko, v12.22.7:
  ok, v16.13.0: ko)

That is why we are offering a Dockerfile to allow you to have the correct
compilation environment. You will need two elements:
- Docker (or podman which is a Docker without daemon and you can `alias
  docker=podman` for following this document).
- Git to download the code source and apply patches.

### With Docker

This is the recommended way, since you will have all needed packages and their
good versions.

Steps:

- Export and ideally save this line inside your `~/.bashrc` file (or any equivalent file).
Do not forget to replace `path/for/chreage_workspace` by the desired folder:
```bash
export WORKSPACE_CHREAGE=path/for/chreage_workspace
```

- git clone this repo:
```bash
git clone https://github.com/chreage-rebirth/bootstrap.git --depth=1
cd bootstrap
```

- Execute the bash script:
```bash
./bootstrap.sh $WORKSPACE_CHREAGE
```

- After long hours of compilation, you can run Brave:
```bash
TODO
```

- If you want to modify the code source of Brave and recompile it:
```bash
cd $WORKSPACE_CHREAGE
docker run --rm -ti -v $(pwd):/workspace -w /workspace/brave-browser chreage:latest /bin/bash
```

### Without Docker

### Linux operating system

Follow steps described here:
https://github.com/brave/brave-browser#clone-and-initialize-the-repo

### Windows operating system:

https://chromium.googlesource.com/chromium/src/+/refs/heads/main/docs/windows_build_instructions.md#Visual-Studio

"Windows 10 SDK version 10.0.19041.0" is necessary for the compilation
https://developer.microsoft.com/en-us/windows/downloads/sdk-archive/

You will have to install the ATL library coming from with the compiler Visual Studio (for example the community version 2019).
Then you will have to copy the file `atls.lib` in the folder `lib` of the SDK:
```
C:\Program Files (x86)\Windows Kits\10\Lib\10.0.19041.0\um\x64
```

Finally, you will have to install Python 3.8 and Node v12.

## Godot's code source compilation

TODO

## Chreage's code source compilation

TODO
