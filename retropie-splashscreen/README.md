This is a modified version of the [builtin splashscreen script included with retropie](https://github.com/RetroPie/RetroPie-Setup/tree/master/scriptmodules/supplementary/splashscreen).

It enables the usage of a pair of image/video files. A static image to show when the pi first boots, and a video that is loaded once video it is able to be.

A typical usage.

Contents of `/etc/splashscreen.list`:

    /home/pi/RetroPie/splashscreens/RPi0_

Contents of `/home/pi/RetroPie/splashscreens/`:

    RPi0_image.png
    RPi0_video.mp4

You need to set `RANDOMIZE` to either `"imgvideo"` or `"imgvideorand"` in `asplashscreen.sh` (it defaults to `imgvideo`). With `imgvideorand` it's possible to have multiple combinations of splashscreen image/video in the splashscreens folder and have it randomly choose one of the pairs.

for example `/etc/splashscreen.list` could contain:

    /home/pi/RetroPie/splashscreens/AAA_
    /home/pi/RetroPie/splashscreens/BBB_
    /home/pi/RetroPie/splashscreens/CCC_

and `/home/pi/RetroPie/splashscreens/` could contain:

    AAA_image.png
    AAA_video_1.mp4
    AAA_video_2.mp4
    AAA_video_3.mp4
    
    BBB_image_1.png
    BBB_image_2.png
    BBB_image_3.png
    BBB_video.mp4
    
    CCC_image_1.png
    CCC_image_2.png
    CCC_image_3.png
    CCC_video_1.mp4
    CCC_video_2.mp4
    CCC_video_3.mp4

Meaning you could have multiple different splashscreen image/video sets, and each set could have different image/videos that could be randomly chosen from.
