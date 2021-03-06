## Intro

So this is my little guide to setting up a RetroPie on a Raspberry Pi Zero (W or not). These are my personal tweaks to make RetroPie on a RPi0 better.

This isn't a complete newbies guide to ssh/terminal or the linux operating system but I will try to make it as easy to understand as possible.

I have built a few of these now, to be given as presents, and I quite often see people ask how the performance on the Pi0 is... well its okay, not spectacular, but its good enough for quite a few emulators.

Usable Emulators:
* Atari 2600
* Atari 7600
* GameGear
* GameBoy
* GameBoy Colour
* GameBoy Advanced
* SEGA MasterSystem
* SEGA Megadrive (Genesis)
* NES
* SNES (Some things don't work so great but most games are playable, SFX games are however not playable)

I have found a few PSX games that work, but really are not that playable. Don't even bother with the N64.

## Setup

First off make sure you have a USB keyboard plugged in so we can dop into a terminal. Some of the changes we are going to make require that emulationstation is not running.

To do this press `F4` on the keyboard to quit emulationstation and drop you into a terminal.

Next we need to download my resource files from github, its as simple as

    git clone https://github.com/kloptops/retropie_stuff.git

then:

    cd retropie_stuff

## Step 1

The first real change I do to improve the experience for the Pi0 is to make the boot process a little faster, and to provide a more visually pleasing splashscreen experience.


### No wait for network connection

This first change is to make it so the operating system doesn't wait for a network connection to continue booting. To do this type:

    ./setup.sh --network-nowait

This can save 5-10 seconds... my wifi sucks sometimes.

### Better splashscreen

The next thing we do is install a better splashscreen system. Typically you can either have an image (or an assortment of images) that show during boot. Or you can have a video play. Unfortunately if you have a video, it can take upwards of 10 seconds before the video starts playing, however if you have just an image it is 1-2 seconds. During this 10 seconds it either displays a whole list of stuff that the average person doesnt understand, or a blank screen if you turn off showing boot information.

Therefore I decided why not have the best of both worlds? I have altered the splashscreen script to show an image immediately, and then swap to the splashscreen video once it able to. I have made a custom splashscreen video/image combination to make it so it works.

To install better splashscreen do:

    ./setup.sh --install-splashscreen

To understand the better splashscreens more, [see here](retropie-splashscreen/README.md).

## Step 2

So from my experience emulationstation is better with background music whilst choosing a game to play. I have a playlist of about 20 different songs from different video games over the years. I can't share it because of copyright reasons but I recommend finding music from games you love.

Unfortunately the RPi0 is quite weak and a few of the ways to add music makes emulator performance almost unsuable. However the user [MapleStory on the RetroPie forums has a good solution](https://retropie.org.uk/forum/topic/9133/quick-and-easy-guide-for-adding-music-to-emulatonstation-on-retropie-noob-friendly). I have tweaked it to make it more user friendly. It is possible to toggle the music playback from within emulationstation, it also waits for any splashscreen videos to finish before playing.

    ./setup.sh --install-music

To get music to play in emulationstation, just place mp3's into the `/home/pi/RetroPie/roms/music` folder.

## Step 3

So let's clean up the boot text so that all we see are the raspberries until the splash screen appears

To do this type:

    ./setup.sh --install-quiet-boot

If you'd like to remove the raspberries from boot, you can do the following instead.

    ./setup.sh --install-quiet-boot-no-berries

## Step 4

This is my personal preference, but I like to have a button to shutdown/reset the system. I've found that of the few systems I've given out, the ones with a shutdown button are the ones that the owners actually shut it down properly. I have followed [this tutorial to add a button between the ground pin and pin 5](https://gilyes.com/pi-shutdown-button/). I have included basically their script.

To install it type:

    ./setup.sh --install-shutdown-button

## Step 5

Since a shutdown button is a great, but can sometimes mean that emulationstation is not shutdown properly, I like to install a script that waits for a system shutdown to happen, and to cleanly exit whatever emulator is running and emulationstation. [This was taken from the retropie forums, and is made by the user meleu.](https://retropie.org.uk/forum/topic/12895/ensuring-es-gracefully-finish-and-save-metadata-in-every-system-shutdown/2)

To install it type:

    ./setup.sh --install-safer-shutdown

## Finally

If there is anything you don't quite like about any of the things you've installed with this script, there is a companion --uninstall version of it. Which does it's best to undo the work the install script has done.

## Done

For now this is all it does...
