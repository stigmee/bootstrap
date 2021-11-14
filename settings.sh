###############################################################################
### Project settings
### This file is included (do not run it directly)
###############################################################################

### User settings. Stigmee's third-part desired versions. If you do not desire
### to install a third-part unset its version.
GODOT_VERSION=3.4-stable
BRAVE_VERSION= #v1.32.96
CHROMIUM_EMBEDDED_FRAMEWORK_VERSION=4664

### User settings. Using Docker ? If yes set it with any value (WARNING:
### CURRENTLY EXPERIMENTAL !!)
USING_DOCKER=

### We are supposed to be inside the root folder cloned by
### https://github.com/stigmee/bootstrap We save this path.
HERE=`pwd`

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
