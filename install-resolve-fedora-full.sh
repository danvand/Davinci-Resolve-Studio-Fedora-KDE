#!/bin/bash

# Script to Install DaVinci Resolve on Fedora with Desktop Launcher and GPU Support

set -e

# Variables
ACTIVE_USER=$(logname)
HOME_DIR=$(eval echo "~$ACTIVE_USER")
DOWNLOADS_DIR="$HOME_DIR/Downloads"
EXTRACTION_DIR="/opt/resolve"
DESKTOP_FILE="/usr/share/applications/davinci-resolve.desktop"
PROFILE_ENV_SCRIPT="/etc/profile.d/resolve.sh"
ZIP_FILE_PATTERN="DaVinci_Resolve_*.zip"

# Step 1: Ensure FUSE is Installed
echo "Checking for FUSE..."
if ! rpm -q fuse &>/dev/null; then
    echo "Installing FUSE..."
    sudo dnf install -y fuse fuse-libs fuse-devel
fi

# Step 2: Install Required Qt5 and X11 Libraries
echo "Installing required Qt and X11 libraries..."
sudo dnf install -y \
    qt5-qtbase-devel qt5-qttools qt5-qtx11extras \
    libXrender libXrandr libXi libxkbcommon libxkbcommon-x11 \
    xcb-util xcb-util-image xcb-util-keysyms xcb-util-renderutil xcb-util-wm \
    mesa-libGLU mesa-libGL \
    qt5-qtwayland qt5-qtbase-gui qt5-qtbase-common \
    unzip

# Optional: Install GPU dependencies (NVIDIA/CUDA or AMD/OpenCL)
#echo "Installing optional GPU support libraries (CUDA/OpenCL)..."
#sudo dnf install -y ocl-icd opencl-headers mesa-libOpenCL --allowerasing

# Optional for NVIDIA users:
# sudo dnf install -y xorg-x11-drv-nvidia-cuda

# Step 3: Navigate to Downloads Directory
echo "Navigating to Downloads directory..."
if [ ! -d "$DOWNLOADS_DIR" ]; then
    echo "Error: Downloads directory not found at $DOWNLOADS_DIR."
    exit 1
fi
cd "$DOWNLOADS_DIR"

# Step 4: Extract DaVinci Resolve ZIP File
echo "Extracting DaVinci Resolve installer..."
ZIP_FILE=$(find . -maxdepth 1 -type f -name "$ZIP_FILE_PATTERN" | head -n 1)
if [ -z "$ZIP_FILE" ]; then
    echo "Error: DaVinci Resolve ZIP file not found in $DOWNLOADS_DIR."
    exit 1
fi

unzip -o "$ZIP_FILE" -d DaVinci_Resolve/
chown -R "$ACTIVE_USER:$ACTIVE_USER" DaVinci_Resolve
chmod -R 774 DaVinci_Resolve

# Step 5: Run the Installer or Extract AppImage
echo "Running the DaVinci Resolve installer..."
cd DaVinci_Resolve
INSTALLER_FILE=$(find . -type f -name "DaVinci_Resolve_*.run" | head -n 1)
if [ -z "$INSTALLER_FILE" ]; then
    echo "Error: DaVinci Resolve installer (.run) file not found in extracted directory."
    exit 1
fi

chmod +x "$INSTALLER_FILE"

# Set Qt platform plugin path
export QT_DEBUG_PLUGINS=1
export QT_QPA_PLATFORM_PLUGIN_PATH=/usr/lib64/qt5/plugins/platforms
export QT_PLUGIN_PATH=/usr/lib64/qt5/plugins
export LD_LIBRARY_PATH=/usr/lib64:$LD_LIBRARY_PATH

if ! SKIP_PACKAGE_CHECK=1 ./"$INSTALLER_FILE" -a; then
    echo "FUSE may not be functional. Extracting AppImage contents..."
    sudo mkdir -p "$EXTRACTION_DIR"
    ./"$INSTALLER_FILE" --appimage-extract
    sudo mv squashfs-root/* "$EXTRACTION_DIR/"
    sudo chown -R root:root "$EXTRACTION_DIR"
fi

# Step 6: Resolve Library Conflicts
echo "Resolving library conflicts..."
if [ -d "$EXTRACTION_DIR/libs" ]; then
    cd "$EXTRACTION_DIR/libs"
    sudo mkdir -p not_used
    sudo mv libgio* not_used || true
    sudo mv libgmodule* not_used || true

    if [ -f /usr/lib64/libglib-2.0.so.0 ]; then
        sudo cp /usr/lib64/libglib-2.0.so.0 "$EXTRACTION_DIR/libs/"
    else
        echo "Warning: libglib-2.0.so.0 not found. Please check for compatibility."
    fi
fi

# Step 7: Create Environment Variable Script
echo "Creating environment variable loader..."
sudo tee "$PROFILE_ENV_SCRIPT" > /dev/null <<EOF
# DaVinci Resolve Environment Settings
export QT_QPA_PLATFORM_PLUGIN_PATH=/usr/lib64/qt5/plugins/platforms
export QT_PLUGIN_PATH=/usr/lib64/qt5/plugins
export LD_LIBRARY_PATH=/usr/lib64:\$LD_LIBRARY_PATH
EOF
sudo chmod +x "$PROFILE_ENV_SCRIPT"

# Step 8: Create Desktop Launcher
echo "Creating desktop launcher..."
sudo tee "$DESKTOP_FILE" > /dev/null <<EOF
[Desktop Entry]
Name=DaVinci Resolve
Exec=$EXTRACTION_DIR/bin/resolve
Icon=$EXTRACTION_DIR/resolve.png
Type=Application
Categories=AudioVideo;Video;Graphics;
StartupNotify=true
Terminal=false
EOF

sudo chmod +x "$DESKTOP_FILE"
sudo update-desktop-database /usr/share/applications/

# Step 9: Cleanup
echo "Cleaning up installation files..."
cd "$DOWNLOADS_DIR"
rm -rf DaVinci_Resolve

echo "DaVinci Resolve installation completed successfully!"
echo "You may need to log out and back in for environment variables to take effect."
