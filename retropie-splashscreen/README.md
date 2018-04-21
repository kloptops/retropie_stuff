This is a modified version of the [builtin splashscreen script included with retropie](https://github.com/RetroPie/retropie-splashscreens).

It enables the usage of a pair of image/video files. A static image to show when the pi first boots, and a video that is loaded once video it is able to be.

A typical usage.

splashscreen.list:

    /home/pi/RetroPie/splashscreens/RPi0_

Contents of `/home/pi/RetroPie/splashscreens/`:

    /home/pi/RetroPie/splashscreens/RPi0_image.png
    /home/pi/RetroPie/splashscreens/RPi0_video.mp4

You need to set `RANDOMIZE` to either `"imgvideo"` or `"imgvideorand"` in `asplashscreen.sh`. Its possible to have multiple combinations of splash image/video in the splashscreens folder and have it randomly choose one of the pairs.

It is quite flexible, I unfortunately haven't modified the retropie configurator to allow you to configure it with that system yet.