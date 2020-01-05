# TinkerRetroPie

TinkerRetroPie is an Armbian OS build wrapper and RetroPie install script generator for ASUS Tinker Boards.

The TinkerRetroPie install builder is currently tested and developed on Armbian Debian Stretch.

The provided images are tested on a Tinker Board S.

You need the ROTT/RetroPie-Armbian-Setup/setup1.sh file to install additional drivers and packages such as libmali.
then go into installer_src and use install.sh
once both steps are completed you will be greeted by the retropie screen where you can build the core files and emulators. 

## Release Images

See www.techtoytinker.com for the current release images.

A bare image, an image with RetroPie preinstalled.

**Note:** Make sure to unzip the provided image files before flashing them.

** Thank you to EriHoss for all his tinkerboard contributions, some of which have been used here, also a thank you to the former member Crash Cortez.

Release images with RetroPie installed will have the following credentials:

```bash
# tinker is the user RetroPie is installed under.

User: tinker
Password: tinkerboard

User: root
Password: tinkerboard

```

Release images **without** RetroPie installed can be logged into with:

```bash
# you will be asked to setup your own user when you boot one of the bare images.

User: root
Password: 1234


# The install script is mostly automated..


```

For starting emulationstation, see section: [Starting emulationstation](#starting-emulationstation)

## TOC

  * [Features](#features)
  * [Performance](#performance)
    * [Tested games](#tested-games)
  * [Starting emulationstation](#starting-emulationstation)
  * [Update RetroPie / Install more software](#update-retropie--install-more-software)
  * [Troubleshooting](#troubleshooting)
    * [Adjusting display resolution (Fix invalid signal problems)](#adjusting-display-resolution)
  * [Build from source / Install yourself](#build-from-source--install-yourself)
    * [Build the latest everything](#build-the-latest-everything)
    * [Install xpad / xboxdrv](#install-xpad--xboxdrv)
    * [Automate basic install + extra modules](#automate-tinkerretropie-basic-install--extra-modules)
    * [Forcing Armbian source update + rebuild](#forcing-armbian-source-update--rebuild)
    * [Build Armbian without prompts](#build-armbian-without-prompts)
      * [Override U-Boot version](#override-u-boot-version)
      * [Build container selection](#build-container-selection)
      * [Build clean level](#build-clean-level)
    * [Build the current release](#build-the-current-release)
  * [Create your own distributable image](#create-your-own-distributable-image)

# Features

TinkerRetroPie takes advantage of the Mali Midgard (GPU) devfreq support in newer linux kernels
to set the GPU to its max clock (600 MHz) on system boot. (Normally left at 100 MHz)

The `build_installer.sh` script can configure and build Armbian from source for you with 
Mali Midgard (GPU) devfreq support (Userland device frequency manipulation). This kernel option
is not enabled by default.

It will also automatically modularize the 'joypad' and 'evdev' module (mostly for debugging reasons), and remove
'xpad' all together so you may install RetroPie's or another version without issues.

It will produce a tarball containing an installer script and its supporting files that you can
run on your newly built image to install RetroPie.

You can also use an Armbian build that you have previously built by specifying its location when prompted.
But the build must have had Mali Midgard devfreq support enabled from kernel config menu.  It is recommended
to also manually modularize 'joypad' and 'evdev' from the kernel config menu, and remove 'xpad' completely.

TinkerRetroPie requires the "next" branch of the kernel (4.14.*), and is only tested on images based on Debian Stretch.

Install is only supported on the minimal server distribution. 
Adding a desktop environment is untested/unsupported due to the finickiness of the userland Mali GPU drivers and X11.

I have tested these emulators so far with good success:

 * reicast-latest-tinker (TinkerRetroPie patch, builds an up-to-date version)
 * lr-pcsx-rearmed
 * lr-mupen64plus
 * mupen64plus (TinkerRetroPie patch, builds a full up-to-date version)

A patch is applied to reicast which fixes major gamepad input bugs on this platform.

Working but moderately tested:

 * ppsspp-tinker (Sony PSP Emu) (Contributed TinkerRetroPie patch, builds a full up-to-date version)
 

# Performance

The `install.sh` script from the generated installer tarball will install an init.d
script that sets the GPU clock to its max frequency (600 MHz) and the GPU governor to "userspace".

The script that does this is `etc/init.d/gpu-freqboost-tinker`, which is installed to `/etc/init.d/gpu-freqboost-tinker`
and enabled by the install script.

Make sure you have heaksinks installed and are using some kind of fan to keep the device cool.

In the case that you do not have adequate cooling, you can disable the frequency boost with: 
`sudo systemctl disable gpu-freqboost-tinker` (performance will suffer a lot)

Make sure to restart after running the above command.


## Tested games

With this boot configuration, reicast (dreamcast emulator) and mupen64plus run surprisingly well.

Note: lr-mupen64plus runs a little bit faster at the moment than the full version of Mupen built for tinker.

Games I have tested on reicast running pretty much full or playable speed: 

 * Re-Volt
 * Prince Of Persia - Arabian Nights
 * Test Drive 6 (Kinda slow)
 * Test Drive - V Rally (A few graphical glitches, kinda slow)
 * Dead Or Alive 2
 * Soul Calibur (A few graphical glitches, kinda slow)
 * Shenmue (A few graphical glitches, kinda slow, some audio skip)
 * Crazy Taxi (Audio skips)
 * Crazy Taxi 2 (Audio skips)
 * Sonic Adventures 2
 * Rayman 2: The Great Escape
 * Star Wars - Episode I - Racer
 * GTA 2
 * Gauntlet Legends

Games I have tested on N64 with similar result:

 * Star Fox 64
 * Mario 64
 * Hydro Thunder
 * Wave Race 64
 * Perfect Dark
 * Golden Eye

PS1 games I have tested: 

 * Gran Turismo 2
 * Twisted Metal 4
 * Spyro The Dragon 1
 * Spyro The Dragon 2
 * Spyro The Dragon 3 (Slightly glitchy intro / cutscenes)
 * Tony Hawks Pro Skater 1 
 * Tony Hawks Pro Skater 2
 * Tony Hawks Pro Skater 3 (Little slow)
 * Tony Hawks Pro Skater 4
 * Tom Clancy's Rainbow Six
 * Medal Of Honor
 * Crash Bandicoot 1
 * Crash Bandicoot 2
 * Crash Bandicoot 3
 * Crash Team Racing
 * Crash Bash
 * Tomb Raider 1
 * Tomb Raider 2
 * Tomb Raider 3 (Little slow)
 * Tomb Raider 4
 * Tomb Raider 5

PSP games (Mostly bootup tested, maybe slow but playable):

 * Burnout Legends (Pretty good, minor audio skipping)
 * Mega Man - Powered Up (Pretty good, minor audio skipping)
 * Grand Theft Auto - Vice City Stories (Good, very minor audio skip)
 * Final Fantasy III (Good, occasional audio crackle)


# Starting emulationstation

To start emulation station, just call the **emulationstation** command.
It is on your path after installing RetroPie. It will not be configured to start on boot automatically.

```bash

emulationstation

```

If you want to have **emulationstation** start on boot, refer to: [RetroPie-Setup Wiki](https://github.com/RetroPie/RetroPie-Setup/wiki/FAQ#how-do-i-boot-to-the-desktop-or-kodi)

# Update RetroPie / Install more software


You can CD into `~/RetroPie-Setup` and run: `git pull origin master` to fetch the latest setup script changes.

Then run: `sudo ./retropie_setup.sh` to start the setup script, which will allow you to update
or install additional RetroPie packages by building them from source.

# Troubleshooting

## Adjusting display resolution

The default output resolution used by Armbian with kernel modesetting enabled is 1080p (1920x1080)

Some older TV's and possibly old monitors may not be happy with this when starting up an emulator, and they might
lose signal or display something along the lines of "invalid signal" because they cannot handle the requested 
resolution.

You can force Armbian to boot to a specific resolution by editing `/boot/armbianEnv.txt`

In order to force a 720-24p resolution that might work better on older TV's for example, you can add this line
to the end of your `/boot/armbianEnv.txt` file.

( *Edit with nano: `sudo nano /boot/armbianEnv.txt` password: 1234* )

```
extraargs=video=drm_kms_helper.edid_firmware=HDMI-A-1:edid/1280x720.bin video=HDMI-A-1:1280x720-24@60
```

After you have added this, reboot your board.  

```
sudo shutdown -r now
```

You should boot into a noticably lower resolution console if you have edited the file correctly. If you fail to get any video output once you have changed this, you can edit the file directly on the SDCard using an SDCard reader or over SSH to fix any mistakes / revert the file.

You can try various resolutions to get a better picture, for example:

```
extraargs=video=drm_kms_helper.edid_firmware=HDMI-A-1:edid/1280x1024.bin video=HDMI-A-1:1280x1024@60
```

The above will probably work as well if 1280x720 works on your TV, but the picture may be slightly skewed horizontally.

To return to using the default resolution just remove the line you added and reboot your board, or set it explicitly like this:

```
extraargs=video=drm_kms_helper.edid_firmware=HDMI-A-1:edid/1920x1080.bin video=HDMI-A-1:1920x1080@60
```


# Build from source / Install yourself

See the: [Reproduce Release Section](#reproduce-the-current-release) if you want to reproduce the current
release image and installer tarball.  The following steps will create an installer using the latest software versions, which
may or may not be tested.

The instructions on flashing the image and running the TinkerRetroPie installer script below
are still relevant for installing the resulting artifacts.

When you use the installer tarball from the reproduced release however, the entire install will be automated 
with no dialogs.

The Armbian OS Build will also be entirely automated with no prompts.

## Build the latest everything

Run `build_installer.sh` on your build machine.

On the first run you will be prompted if you want to build Armbian from source, if you say "no" you will
be asked for a path to an existing source tree where a build has been previously completed.

You will also be asked if you want access to the linux kernel configuration menu, for the kernel branch (linux kernel version), 
and for the Armbian OS LIB_TAG (this is a tag/branch/commit-hash from the Armbian/build repository).

If you are not sure about the prompts mentioned above, just hit enter to accept the default values.

Building Armbian from source with `build_installer.sh` will **require that you have docker installed** for simplicity.

When the script finishes running, **TinkerRetroPieInstaller.tar.gz** and the OS image will be left in the `output` directory, which
by default is in the same directory that `build_installer.sh` resides in.

After you have run `build_installer.sh` successfully, Flash the Armbian OS image and setup a non root user named to your liking.

Log into that user and transfer **TinkerRetroPieInstaller.tar.gz** to their home directory.

If your not sure how to do that with `rsync` you can just power down your device, put the 
SDCard back in your computer and place it there manually.

Untar: `tar -xvf TinkerRetroPieInstaller.tar.gz`

Run: `sudo ./TinkerRetroPieInstaller/install.sh`

The script will install/build a bunch of requirements for RetroPie, including userland GPU drivers and boot config.

Once the script is done installing RetroPie requirements it will clone and launch the RetroPie setup script.

This will bring up a blue menu where you can select "Basic Install".

"Basic Install" will build and install all the core packages of RetroPie onto your system.

You can restart the RetroPie config script to install additional packages later or update software by running `sudo ~/RetroPie-Setup/retropie_setup.sh`

Once installed you can launch emulationstation. see the [Starting emulationstation](#starting-emulationstation) section.

## Install xpad / xboxdrv

I recommend using xpad for Xbox / XInput controllers, install it from the `~/RetroPie-Setup/retropie_setup.sh` script.

It is under the Drivers section.

Once you have installed it do:

```bash

sudo modprobe xpad

```

To load the newly installed kernel module.

You will need to do some research on configuring controllers with RetroPie, it is generally a pain.

## Automate basic install + extra modules

See `TinkerRetroPieInstaller/install.sh --help` for installer parameters.


When [installer.cfg](https://github.com/EriHoss/TinkerRetroPie/blob/master/tools/installer.cfg) is present in the installer
directory, it will be used to define all install options. This will be the case when you use the [build_release.sh](https://github.com/EriHoss/TinkerRetroPie/blob/master/tools/build_release.sh) or [build_dev_release.sh](https://github.com/EriHoss/TinkerRetroPie/blob/master/tools/build_dev_release.sh) scripts to build the Armbian image / RetroPie installer combo.


```bash

# Automatically do a RetroPie basic install with some extra modules
# without ever opening a GUI or asking for input


./TinkerRetroPieInstaller/install.sh RETROPIE_BASIC_INSTALL=1 \
                                     RETROPIE_INSTALL_MODULES="xpad reicast-latest-tinker ppsspp-tinker"

# You can also select a branch + commit

./TinkerRetroPieInstaller/install.sh RETROPIE_BRANCH=master \
                                     RETROPIE_COMMIT=e719833 \
                                     RETROPIE_BASIC_INSTALL=1 \
                                     RETROPIE_INSTALL_MODULES="xpad reicast-latest-tinker ppsspp-tinker"

# Or a tag (via git --branch)

./TinkerRetroPieInstaller/install.sh RETROPIE_BRANCH=4.4 \
                                     RETROPIE_BASIC_INSTALL=1 \
                                     RETROPIE_INSTALL_MODULES="xpad reicast-latest-tinker ppsspp-tinker"

```

## Forcing Armbian source update + rebuild

Running `build_installer.sh --force-armbian-rebuild` will prompt you if you want to clone/update Armbian sources
again even they are already present in the build tree.

Saying 'yes' will cause the script to update the Armbian build script sources to their lastest version, and then
run the build over again.

An installer package will be generated overwriting the old one, and the most recently produced 
Armbian image will be put into the output folder of the **TinkerRetroPie** build tree possibly 
overwriting the last one that was produced.


## Build Armbian without prompts

Using `--force-armbian-rebuild` with any of the following command examples will force a complete
rebuild of Armbian OS, which would normally not happen unless no images are found in the builds
`output/images` directory.

```bash

# Example 1, This will:

# 1) Clone/update the Armbian/build repo at (scriptpath)/armbian_build
# 2) Skip the kernel configuration menu
# 3) Build with linux kernel at tag v4.14.81
# 4) Checkout Armbian/build repo at commit c1530db (Armbian 5.67)

./build_installer.sh BUILD_ARMBIAN=yes KERNEL_CONFIGURE=no KERNELBRANCH=tag:v4.14.81 LIB_TAG=a37a9cf

# Example 2, This Will:

# 1) Clone/update the Armbian/build repo to/at ARMBIAN_BUILD_PATH (./my_custom_build)
# 2) Give access to the kernel configuration menu
# 3) Build the kernel from the latest tag in the linux-4.14.y branch
# 4) Checkout Armbian/build repo at the latest commit (master)

./build_installer.sh ARMBIAN_BUILD_PATH=./my_custom_build \
                     BUILD_ARMBIAN=yes \
                     KERNEL_CONFIGURE=yes \
                     KERNELBRANCH=branch:linux-4.14.y \
                     LIB_TAG=master


# Example 3, This Will:

# 1.) Clone/update the Armbian/build repo at (scriptpath)/armbian_build
# 2.) Skip the kernel configuration menu
# 3.) Build the kernel from the latest tag in the linux-4.14.y branch
# 4.) Checkout Armbian/build repo at the latest commit (master)
#
# 5.) Place the output image and installer tarball in ./my_custom_output_dir
#     Creating the directory if it does not exist

./build_installer.sh BUILD_ARMBIAN=yes \
                     KERNEL_CONFIGURE=yes \
                     KERNELBRANCH=branch:linux-4.14.y \
                     LIB_TAG=master \
                     OUTPUT_DIR=./my_custom_output_dir


# Example 4, This Will:

# 1.) Clone/update the Armbian/build repo at (scriptpath)/armbian_build
# 2.) Skip the kernel configuration menu
# 3.) Build the kernel from the latest tag in the linux-4.14.y branch
# 4.) Checkout Armbian/build repo at commit: a37a9cf (5.67)
# 5.) Use the TinkerRetroPie installer config file at 'tools/cur_installer.cfg'
#
# 6.) Place the output image and installer tarball in ./my_custom_output_dir
#     Creating the directory if it does not exist

./build_installer.sh BUILD_ARMBIAN=yes \
                     KERNEL_CONFIGURE=yes \
                     KERNELBRANCH=branch:linux-4.14.y \
                     LIB_TAG=a37a9cf \
                     TINKER_RETROPIE_CONFIG="tools/cur_installer.cfg" \
                     OUTPUT_DIR=./my_custom_output_dir

```

### Override U-Boot version

You can override the version of U-Boot to compile with `BOOTBRANCH`.

e.g:

```bash

# Build from a tag

./build_installer.sh BOOTBRANCH="tag:v2019.01-rc2"

# Use latest

./build_installer.sh BOOTBRANCH="branch:master"

```

This is normally selected automatically by the underlying Armbian build system.

### Build container selection

You can force the build to occur on your actual machine by setting `BUILD_CONTAINER=""`.

The above is not recommended and is for making debugging build issues easier, you can also
just start up a VM running Ubuntu 18.04 LTS and do the build in there with this option set 
to null.

The default value is `BUILD_CONTAINER="docker"`.

You can also use vagrant instead by setting `BUILD_CONTAINER="vagrant"` (Not Tested)


### Build clean level

Build clean level can be adjusted using `CLEAN_LEVEL="..."`

See `CLEAN_LEVEL`: https://docs.armbian.com/Developer-Guide_Build-Options/


## Build the current release

`tools/build_release.sh` can be used to build an identical Armbian image and installer tarball as used
in the current release/state of this repository.

The Armbian OS installer tag is pinned to the last tested version, as well as the kernel tag.

An **installer.cfg** file is written into the packaged installer tarball that will cause
the installer to clone a specific version of RetroPie-Setup.

**installer.cfg** will tell the installer to build RetroPie's "basic install", "xpad", and "reicast-latest-tinker"
by default without prompting you for input.

It will also configure the TinkerRetroPie patch modules to build their emulators at tested commits.

The entire install will be automated after you kick off the install script.

You should first checkout a release before running:

```bash

# Checkout version vX.Y.Z ...

git checkout vX.Y.Z

# Build this version

./tools/build_release.sh


```

# Create your own distributable image

The `tools/squash_sd_img.sh` script can be used to shrink the filesystem on you SDCard to its minimal size,
clone it to an image and then return the filesystem on your device back to normal.

Note that this is probably not a great thing to do repeatedly to your SDCard, but it works.

If you are doing this for the Armbian image you just built and logged into, you should run
this command first and then shutdown (dont restart before making an image):

`sudo systemctl enable armbian-resize-filesystem`

This command will enable Armbian's onshot systemd service that expands the filesystem back
to its maximum size upon boot.  After the filesystem is expanded again the service disables itself.


```bash

# Shrink /dev/mmcblk0p1
# mmcblk0 is typicaly the name of your built in SDCard reader
# but you really should verify its the correct device first...

# Note that the partition is specified not the root device itself (p1)

# Generally Armbian OS images will have one primary partition, as with most SBC
# images.  You want to pick the primary partition, and it must be the last
# partition on the device.

./squash_sd_img.sh /dev/mmcblk0p1 my_customized_image.img

# Your bootable minified image will be written to my_customized_image.img

```













