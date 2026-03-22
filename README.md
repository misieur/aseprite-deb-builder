# aseprite-deb-builder
A bash script to build a deb package file from aseprite's source

This script only work on Debian/Ubuntu, it may work on Fedora, Arch Linux or SUSE but isn't tested on those Linux distributions.
It lets you select if you want build to Aseprite from the latest stable release, latest pre-release or main branch.

Generating a `.deb` file only work on Debian/Ubuntu.

## How to use:
```bash
curl -sSLO https://raw.githubusercontent.com/misieur/aseprite-deb-builder/main/builder.sh && chmod +x builder.sh && sudo ./builder.sh
```
A `aseprite.deb` file will be created when the script finishes, you can install it using:
```bash
sudo apt install ./aseprite.deb
```
And delete the `builder.sh` file.
