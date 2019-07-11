#!/bin/bash

home="$(eval echo ~$user)"

#This Script is optimized for the following versions:
refDrivers="r18p0-01rel0 (UK version 10.6)"
refKernel="4.4.135-rockchip"
refOS="debian"
refDist="stretch"

# check, if sudo is used
check_sudo ()
{
    if [[ "$(id -u)" -eq 0 ]]; then
        echo "Script must NOT be run under sudo."
        exit 1
    fi
}

unknown_os ()
{
read -p "ATTENTION: this script is not optimized for your system (read the lines above for more information). Do you want to continue anyway? (!!RISKY!!) (Y/N)"
if ! [[ $REPLY =~ ^[Yy]$ ]]
then
echo "Exiting setup script..."
  exit 1
fi

}

detect_os ()
{
  if [[ ( -z "${os}" ) && ( -z "${dist}" ) ]]; then
    if [ `which lsb_release 2>/dev/null` ]; then
      dist=`lsb_release -c | cut -f2`
      os=`lsb_release -i | cut -f2 | awk '{ print tolower($1) }'`
    else
      unknown_os
    fi
  fi

  if [ -z "$dist" ]; then
    unknown_os
  fi

  # remove whitespace from OS and dist name
  os="${os// /}"
  dist="${dist// /}"
}

check_os () {
    detect_os
    
    if [[ "${os}" != "${refOS}" || "${dist}" != "${refDist}" ]]; then
	echo "Different OS/Distribution detected: $os/$dist"
	echo "This script is optimized for: $refOS/$refDist"
        unknown_os
    fi
	echo "OS/Distribution: $os/$dist"
}

check_kernel () {
    if [[ ( -z "${kernel}" ) ]]; then
        kernel=`uname -r`
        if [[ -z "$dist" ]]; then
            unknown_os
        fi
        
        if [[ "${kernel}" != "${refKernel}" ]]; then
            echo "Different kernel detected: $kernel"
			echo "This script is optimized for: $refKernel"
            unknown_os
        fi
        
        echo "Linux Kernel version: $kernel"
    fi
}

check_drivers () {
    if [[ ( -z "${drivers}" ) ]]; then
        drivers=`cat /sys/module/midgard_kbase/version`
        if [[ -z "$drivers" ]]; then
            unknown_os
        fi
        
        
        
        if [[ "${drivers}" != "${refDrivers}" ]]; then
            echo "Different drivers detected: $drivers"
			echo "This script is optimized for: $refDrivers"
            unknown_os
        fi
        
        echo "Mali Driver version: $drivers"
    fi
}

install_basis () {
    read -p "Do you want to continue? this will update your system and install the required packages and drivers. (Y/N)" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        echo "###############################"
        echo "## Add no password for user  ##"
        echo "###############################"
        echo ""
        sudo sed -i "/sudoers(5)/i\# User no password privilege" /etc/sudoers
        sudo echo "$USER" | sudo sed -i "/# User no password privilege/a\\$USER  ALL=(ALL) NOPASSWD: ALL\n" /etc/sudoers
        echo "User no password privilege added"
        echo ""
    
        echo ""
        echo "#######################"
        echo "##  Updating system  ##"
        echo "#######################"
        echo ""
        sudo apt update
        sudo apt upgrade -y
        
        echo ""
        echo "############################################"
        echo "##  Installing various required packaged  ##"
        echo "############################################"
        echo ""
        sudo apt install -y libtool cmake autoconf automake libxml2-dev libusb-1.0-0-dev libavcodec-dev \
                            libavformat-dev libavdevice-dev libdrm-dev pkg-config mpv
        
	    echo ""
        echo "#################################"
        echo "##  Installing specific Deps   ##"
        echo "#################################"
        echo ""
		sudo apt install -y libgl1-mesa-dev libxcursor-dev libxi-dev libxinerama-dev libxrandr-dev libxss-dev
		
        echo ""
        echo "#################################"
        echo "##  Installing kernel headers  ##"
        echo "#################################"
        echo ""
        wget https://github.com/RetroPie-Expanded/linux-headers/raw/master/armbian/linux-headers-rockchip_5.50.deb
        sudo dpkg -i linux-headers-rockchip_5.50.deb
        rm *.deb
        
        echo ""
        echo "##############################################"
        echo "##  Installing requirements for GPU driver  ##"
        echo "##############################################"
        echo ""
        sudo apt install -y libdrm2 libx11-6 libx11-data libx11-xcb1 libxau6 libxcb-dri2-0 libxcb1 \
                            libxdmcp6 libgles1-mesa-dev libgles2-mesa-dev libegl1-mesa-dev
        echo ""
        echo "#######################################"
        echo "##  Installing GPU userspace driver  ##"
        echo "#######################################"
        echo ""
        wget https://github.com/rockchip-linux/rk-rootfs-build/raw/master/packages/armhf/libmali/libmali-rk-midgard-t76x-r14p0-r0p0_1.6-1_armhf.deb
        sudo dpkg -i libmali-rk-midgard-t76x-r14p0-r0p0_1.6-1_armhf.deb
        wget https://github.com/rockchip-linux/rk-rootfs-build/raw/master/packages/armhf/libmali/libmali-rk-dev_1.6-1_armhf.deb
        sudo dpkg -i libmali-rk-dev_1.6-1_armhf.deb
        rm *.deb
        
        echo ""
        echo "################################################################"
        echo "##  Installing libDRM with experimental rockchip API support  ##"
        echo "################################################################"
        echo ""
        sudo apt install -y xutils-dev
        git clone --branch rockchip-2.4.74 https://github.com/rockchip-linux/libdrm-rockchip.git
        cd libdrm-rockchip
        ./autogen.sh --disable-intel --enable-rockchip-experimental-api --disable-freedreno --disable-tegra --disable-vmwgfx --disable-vc4 --disable-radeon --disable-amdgpu --disable-nouveau
        make -j4 && sudo make install
        cd ~
        rm -rf libdrm-rockchip
        
        echo ""
        echo "##########################"
        echo "##  Installing libmali  ##"
        echo "##########################"
        echo ""
        git clone --branch rockchip-header https://github.com/RetroPie-Expanded/libmali.git
        cd libmali
        cmake CMakeLists.txt
        make -j4 -C ~/libmali && sudo make install
        cd ~
        rm -rf libmali
        git clone --branch rockchip https://github.com/RetroPie-Expanded/libmali.git
        cd libmali
        cmake CMakeLists.txt
        make -j4 -C ~/libmali && sudo make install
        cd ~
        rm -rf libmali
        
        echo ""
        echo "######################"
        echo "##  Installing MPP  ##"
        echo "######################"
        echo ""
        git clone https://github.com/rockchip-linux/mpp.git
        cd mpp
        cmake -src-dir ~/mpp -DRKPLATFORM=ON -DHAVE_DRM=ON
        make -j4 && sudo make install
        cd ~
        rm -rf mpp
        
        echo ""
        echo "##########################"
        echo "##  Installing Wayland  ##"
        echo "##########################"
        echo ""
        sudo apt install -y libffi-dev libexpat1-dev
        git clone https://github.com/wayland-project/wayland.git
        cd wayland
        ./autogen.sh --disable-documentation
        make -j4 && sudo make install
        cd ~
        rm -rf wayland
        
        echo ""
        echo "########################"
        echo "##  Cloning RetroPie  ##"
        echo "########################"
        echo ""
        git clone --depth=1 https://github.com/RetroPie-Expanded/RetroPie-Setup.git

        echo ""
        echo "####################################"
        echo "##  Basic installation completed.  ##"
        echo "####################################"
        echo "" 
    fi
}

install_optional () {
    read -p "Do you want to install additional features such as bluetooth support, background music, audio source etc ...? (Y/N)" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        echo ""
        echo "##############################"
        echo "##  Optional installation  ##"
        echo "##############################"
        echo ""
        read -p "Do you want to install bluetooth? (Y/N)" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            echo ""
            echo "############################"
            echo "##  Installing bluetooth  ##"
            echo "############################"
            echo ""
            sudo apt install -y bluetooth
            sudo sed -i "/ExecStart=/i\ExecStartPre=/usr/sbin/rfkill unblock all" /lib/systemd/system/tinker-bluetooth.service
            sudo sed -i "/ExecStart=/a\Restart=on-failure" /lib/systemd/system/tinker-bluetooth.service

            echo ""
            echo "###############################"
            echo "##  Launch bluetooth service ##"
            echo "###############################"
            echo ""
            sudo systemctl stop tinker-bluetooth-restart
            sudo systemctl disable tinker-bluetooth-restart
            sudo rm /lib/systemd/system/tinker-bluetooth-restart.service
            sudo systemctl daemon-reload
            sudo systemctl stop tinker-bluetooth
            sudo systemctl start tinker-bluetooth
                
            echo ""
            echo "##  Bluetooth installed ##"
            echo ""
        fi        
            
        read -p "Do you want audio via HDMI? (Y/N)" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            echo ""
            echo "####################"
            echo "##  Audio source  ##"
            echo "####################"
            echo ""
            sudo sed -i "/defaults.pcm.card 0/c\defaults.pcm.card 1" /usr/share/alsa/alsa.conf
                    
            echo ""
            echo "##  Audio source on HDMI  ##"
        fi
                
        read -p "Do you want to install Xbox One S Wireless support? (Y/N)" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            echo ""
            echo "#####################################"
            echo "##  Installing Xbox One S support  ##"
            echo "#####################################"
            echo ""
            sudo sed -i "/nothing./a\echo 1 > /sys/module/bluetooth/parameters/disable_ertm &\n" /etc/rc.local
                   
            echo ""
            echo "##  Xbox One S Wireless Controller installed  ##"
            echo ""
        fi
		
		read -p "Do you want to install additional controller support? (Y/N)" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            echo ""
            echo "#####################################"
            echo "##  Installing controller support  ##"
            echo "#####################################"
            echo ""
            sudo apt install -y joystick joy2key jstest-gtk qjoypad xinput        
            echo ""
            echo "##  Additional controller support installed  ##"
            echo ""
        fi
                    
        read -p "Do you want to install Background Music? (Y/N)" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            echo ""
            echo "#####################################"
            echo "##  Installing Background Music  ##"
            echo "#####################################"
            echo ""
            mkdir -p $HOME/RetroPie/roms/music
            sudo mkdir -p /opt/retropie/configs/all
            sudo wget https://raw.githubusercontent.com/RetroPie-Expanded/Armbian-Setup-for-RetroPie/master/autostart.sh -O /opt/retropie/configs/all/autostart.sh
            sudo wget https://raw.githubusercontent.com/RetroPie-Expanded/Armbian-Setup-for-RetroPie/master/runcommand-onend.sh -O /opt/retropie/configs/all/runcommand-onend.sh
            sudo wget https://raw.githubusercontent.com/RetroPie-Expanded/Armbian-Setup-for-RetroPie/master/runcommand-onstart.sh -O /opt/retropie/configs/all/runcommand-onstart.sh
            sudo chmod +x "/opt/retropie/config/all/autostart.sh" "/opt/retropie/config/all/runcommand-onend.sh" "/opt/retropie/config/all/runcommand-onstart.sh"
            echo ""
            echo "##  Background Music ready  ##"
            echo "## You can drop your music files into ~/RetroPie/roms/music"
            echo ""
        fi
                    
        read -p "Do you want to install OMXPLAYER for splachscreen? (Y/N)" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            echo ""
            echo "#####################################"
            echo "##  Install OMXPLAYER  ##"
            echo "#####################################"
            echo ""
            wget http://ftp.de.debian.org/debian/pool/main/o/openssl/libssl1.0.0_1.0.2l-1~bpo8+1_armhf.deb
            sudo dpkg -i libssl1.0.0_1.0.2l-1~bpo8+1_armhf.deb
            sudo apt install -y libssh-4 fonts-freefont-ttf
            wget http://omxplayer.sconde.net/builds/omxplayer_0.3.7~git20170130~62fb580_armhf.deb
            sudo dpkg -i omxplayer_0.3.7~git20170130~62fb580_armhf.deb
            rm *.deb
                            
            echo ""
            echo "##  OMXPLAYER installed  ##"
            echo ""
        fi
	    read -p "Do you want to install TheBezelProject? (Y/N)" -n 1 -r
        echo	
		if [[ $REPLY =~ ^[Yy]$ ]]
        then
            echo ""
            echo "#####################################"
            echo "##  Install TheBezelProject  ##"
            echo "#####################################"
            echo ""
			mkdir -p $HOME/RetroPie/retropiemenu/
            sudo wget https://raw.githubusercontent.com/thebezelproject/BezelProject/master/bezelproject.sh -O /home/$USER/RetroPie/retropiemenu/bezelproject.sh
            sudo chmod +x "/home/$USER/RetroPie/retropiemenu/bezelproject.sh"       
            echo ""
            echo "##  TheBezelProject is ready  ##"
            echo ""
        fi
		read -p "Do you want to create a symlink from pi to this user? (Y/N)" -n 1 -r
        echo	
		if [[ $REPLY =~ ^[Yy]$ ]]
        then
            echo ""
            echo "#####################################"
            echo "##  Creating symlink  ##"
            echo "#####################################"
            echo ""
            sudo ln -s 	$HOME/ /home/pi
			sudo chown -h $USER:$USER /home/pi
            echo ""
            echo "##  Symlink created  ##"
            echo ""
        fi
                        
        echo ""
        echo "##############################"
        echo "##  Installation completed  ##"
        echo "##############################"
        echo ""
        echo "Run 'sudo ~/RetroPie-Setup/retropie_setup.sh' and then reboot your system. Then you can install the packages from RetroPie-Setup."
fi
}

main ()
{
    check_sudo
    check_os
    check_kernel
    check_drivers
    install_basis
    install_optional
}

main
