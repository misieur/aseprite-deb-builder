#!/bin/bash

echo "Please select the package manager for installing dependencies:"
echo "1. apt (Debian/Ubuntu)"
echo "2. dnf (Fedora)             (not tested)"
echo "3. pacman (Arch Linux)      (not tested)"
echo "4. zypper (SUSE)            (not tested)"
read -p "Enter 1, 2, 3, or 4: " PM_CHOICE

if [ "$PM_CHOICE" -eq 1 ]; then
    sudo apt-get update
    sudo apt-get install -y g++ clang cmake ninja-build libx11-dev libxcursor-dev libxi-dev libxrandr-dev libgl1-mesa-dev libfontconfig1-dev git curl jq
elif [ "$PM_CHOICE" -eq 2 ]; then
    sudo dnf install -y gcc-c++ clang libcxx-devel cmake ninja-build libX11-devel libXcursor-devel libXi-devel libXrandr-devel mesa-libGL-devel fontconfig-devel git curl jq
elif [ "$PM_CHOICE" -eq 3 ]; then
    sudo pacman -S gcc clang cmake ninja libx11 libxcursor libxi libxrandr mesa-libgl fontconfig libwebp git curl jq --noconfirm
elif [ "$PM_CHOICE" -eq 4 ]; then
    sudo zypper install gcc-c++ clang cmake ninja libX11-devel libXcursor-devel libXi-devel libXrandr-devel Mesa-libGL-devel fontconfig-devel git curl jq
else
    echo "Invalid choice. Exiting."
    exit 1
fi

ASEPRITE_DIR="$HOME/aseprite-build"
REPO="aseprite/aseprite"
RELEASES=$(curl -s "https://api.github.com/repos/$REPO/releases")
LATEST_STABLE=$(echo "$RELEASES" | jq -r '.[] | select(.prerelease == false) | .tag_name' | head -n 1)
LATEST_PRERELEASE=$(echo "$RELEASES" | jq -r '.[] | select(.prerelease == true) | .tag_name' | head -n 1)

echo ""
echo "Please select the Aseprite version you want to build:"
echo "1. Latest stable ($LATEST_STABLE)"
echo "2. Latest pre-release ($LATEST_PRERELEASE)"
echo "3. Main branch (development version)"
read -p "Enter 1, 2, or 3: " VERSION_CHOICE

# Set the version based on user choice
if [ "$VERSION_CHOICE" -eq 1 ]; then
    VERSION="$LATEST_STABLE"
elif [ "$VERSION_CHOICE" -eq 2 ]; then
    VERSION="$LATEST_PRERELEASE"
elif [ "$VERSION_CHOICE" -eq 3 ]; then
    VERSION="main"
else
    echo "Invalid choice. Exiting."
    exit 1
fi

echo "Selected version: $VERSION"
echo ""

BUILDER_PWD="$(pwd)"
WORKING_DIR="$BUILDER_PWD/aseprite-temp"

sudo rm -rf "$WORKING_DIR"
mkdir -p "$WORKING_DIR"
cd "$WORKING_DIR" || exit 1

echo "Cloning Aseprite repository..."
echo ""

git clone --recursive https://github.com/aseprite/aseprite.git

cd aseprite || exit 1
if [ "$VERSION" != "main" ]; then
    echo "Checking out version $VERSION..."
    git checkout "tags/$VERSION"
    git submodule update --init --recursive
fi

echo ""
echo "Starting the build process..."
echo ""
./build.sh --auto --norun

echo "Build completed."
echo ""

if [ ! "$PM_CHOICE" -eq 1 ]; then
    echo "You need to have selected apt as package manager in order to create a debian package."
    exit 0
fi
echo "Creating the debian package..."
echo ""

sudo apt install dpkg-dev fakeroot

cd "$BUILDER_PWD" || exit 1

mkdir -p "$WORKING_DIR/package/DEBIAN"
mkdir -p "$WORKING_DIR/package/usr/local/bin"
mkdir -p "$WORKING_DIR/package/usr/share/applications"


# 'Version' field value 'v1.3.16': version number does not start with digit
if [ "$VERSION" = "main" ]; then
    DEB_VERSION="1.0-main"
else
    # Remove the 'v' or 'V' if present
    DEB_VERSION="${VERSION#v}"
    DEB_VERSION="${DEB_VERSION#V}"
fi

# Create necessary files to tell the system how to run it,
# install it, and give information about the package.
cat > "$WORKING_DIR/package/DEBIAN/control" <<EOF
Package: aseprite
Version: $DEB_VERSION
Architecture: amd64
Maintainer: Igara Studio (Script by Misieur)
Description: Aseprite compiled from source
Homepage: https://www.aseprite.org/
EOF

mkdir -p "$WORKING_DIR/package/usr/share/mime/packages"

cat > "$WORKING_DIR/package/usr/share/mime/packages/aseprite.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="image/x-aseprite">
    <comment>Aseprite Image File</comment>
    <glob pattern="*.ase"/>
    <glob pattern="*.aseprite"/>
  </mime-type>
</mime-info>
EOF

cat > "$WORKING_DIR/package/usr/share/applications/aseprite.desktop" <<EOF
[Desktop Entry]
Version=$DEB_VERSION
Name=Aseprite
Comment=Aseprite compiled from source
Exec=/usr/local/bin/aseprite %F
Icon=/usr/local/bin/data/icons/ase.ico
Terminal=false
Type=Application
MimeType=image/x-aseprite;image/bmp;video/x-flc;image/gif;image/x-tga;image/jpeg;image/vnd.zbrush.pcx;image/png;image/x-qoi;image/x-tga;image/webp;
EOF

# Copy built files to package directory (bin and data folders)
cp -r "$WORKING_DIR/aseprite/build/bin/" "$WORKING_DIR/package/usr/local"

dpkg-deb --build "$WORKING_DIR/package"

cp "$WORKING_DIR/package.deb" "$BUILDER_PWD/aseprite.deb"

echo "Cleaning up..."
sudo rm -rf "$WORKING_DIR"
echo ""

echo "Build finished!"
echo "The Aseprite debian package is located at: $BUILDER_PWD/aseprite.deb"