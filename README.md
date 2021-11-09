# Chreage setup and code source compilation

*note* these steps are not yet fully complete ie calling Godot from Docker is not working.

Chreage's development is depending on the following projects as third parts:
- Brave-core: https://github.com/brave/brave-browser
- Godot: https://github.com/godotengine/godot

This document will explain how to setup and compile Chreage project using
Docker. A docker can be useful, because, depending on the environment of your
operating system, you may have more or less difficulties to compile third parts
if you are trying to compile them
[directly](https://github.com/chreage-rebirth/doc)) that is why we are offering
a Dockerfile to allow you to have one correct compilation environment. You will
just need two install two packages (`apt-get install` for example):
- Docker (or podman which is a Docker without daemon and you can `alias
  docker=podman` for following this document).
- Git to download the code source and apply patches.

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

- After long hours of compilation, you can run Godot:
```bash
# $WORKSPACE_CHREAGE/godot/bin/godot.linuxbsd.tools.64
```

- you can run Brave:
```bash
TODO
```

- If you want to modify the Chreage's code source and recompile it:
```bash
cd $WORKSPACE_CHREAGE
docker run --rm -ti -v $(pwd):/workspace -w /workspace chreage:latest /bin/bash
```
