# Davinci-Resolve-Studio-Fedora-KDE
A script to install Davinci Resolve Studio version on Fedora KDE linux. The script has two versions, one basic and one full. The difference is that the full version adds a desktop launcher icon, creates persistent environment variables, and adds some GPU support for OpenCL/CUDA. The script builds upon an excellet article from Annie Taylor Chen (https://dev.to/annietaylorchen/how-to-install-davinci-resolve-19-studio-on-linux-mint-22-with-amd-radeon-graphics-card-with-a-kd6) that details how to install Resolve Studio on Linux Mint 22 with AMD Radeon card. Since I use Fedora KDE and Nvidia, I have modified the original script to suit that environment. 
Disclaimer! The script can successfully install Resolve, but I have not yet managed to launch the application. A work in progress! 

The launcher will show up as “DaVinci Resolve” in your app menu.
The app installes in /opt/resolve, and launched via /opt/resolve/bin/resolve.
Additional steps to install Nvidia drivers might be neccessary, see https://www.youtube.com/watch?v=2YeebhfRSx4 for more details.

How to run:

1. Download Davinci Resolve Studio zip file into Downloads folder (don't unzip).
2. Place script in Downloads folder
3. make it executable. Example: chmod +x install-resolve-fedora.sh
4. run script: ./install-resolve-fedora.sh


