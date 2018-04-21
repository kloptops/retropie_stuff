#!/bin/sh

### BEGIN INIT INFO
# Provides:          asplashscreen
# Required-Start:    mountdevsubfs
# Required-Stop:
# Default-Start:     S
# X-Start-Before:    checkroot
# Default-Stop:
# Short-Description: Show custom splashscreen
# Description:       Show custom splashscreen
### END INIT INFO

ROOTDIR="/opt/retropie"
DATADIR="/home/pi/RetroPie"
RANDOMIZE="imgvideo"
REGEX_VIDEO="\.avi\|\.mov\|\.mp4\|\.mkv\|\.3gp\|\.mpg\|\.mp3\|\.wav\|\.m4a\|\.aac\|\.ogg\|\.flac"
REGEX_IMAGE="\.bmp\|\.jpg\|\.jpeg\|\.gif\|\.png\|\.ppm\|\.tiff\|\.webp"

do_start () {
    local config="/etc/splashscreen.list"
    local line
    local vidline
    local re="$REGEX_VIDEO\|$REGEX_IMAGE"
    case "$RANDOMIZE" in
        disabled)
            line="$(head -1 "$config")"
            ;;
        imgvideo)
            prefix=$(cat "$config" | head -1)
            imgline="$(find "$(dirname $prefix)" -iname "$(basename $prefix)*" -type 'f' | grep "$REGEX_IMAGE" | head -1)"
            vidline="$(find "$(dirname $prefix)" -iname "$(basename $prefix)*" -type 'f' | grep "$REGEX_VIDEO" | head -1)"
            ;;
        imgvideorand)
            prefix=$(cat "$config" | shuf -n1)
            imgline="$(find "$(dirname $prefix)" -iname "$(basename $prefix)*" -type 'f' | grep "$REGEX_IMAGE" | shuf -n1)"
            vidline="$(find "$(dirname $prefix)" -iname "$(basename $prefix)*" -type 'f' | grep "$REGEX_VIDEO" | shuf -n1)"
            ;;
        retropie)
            line="$(find "$ROOTDIR/supplementary/splashscreen" -type f | grep "$re" | shuf -n1)"
            ;;
        custom)
            line="$(find "$DATADIR/splashscreens" -type f | grep "$re" | shuf -n1)"
            ;;
        all)
            line="$(find "$ROOTDIR/supplementary/splashscreen" "$DATADIR/splashscreens" -type f | grep "$re" | shuf -n1)"
            ;;
        list)
            line="$(cat "$config" | shuf -n1)"
            ;;
    esac
    if [ "$RANDOMIZE" = "imgvideo" ] || [ "$RANDOMIZE" = "imgvideorand" ]; then
        # Display an image while we wait for dbus
        fbi -T 2 -once -t 30 -noverbose -a "$imgline" >/dev/null 2>&1 &
        # Wait for dbus
        while ! pgrep "dbus" >/dev/null; do
            sleep 1
        done
        # Play the video
        omxplayer -o both --layer 10000 "$vidline"
        pkill fbi
    elif $(echo "$line" | grep -q "$REGEX_VIDEO"); then
        # wait for dbus
        while ! pgrep "dbus" >/dev/null; do
            sleep 1
        done
        omxplayer -o both --layer 10000 "$line"
    elif $(echo "$line" | grep -q "$REGEX_IMAGE"); then
        if [ "$RANDOMIZE" = "disabled" ]; then
            local count=$(wc -l <"$config")
        else
            local count=1
        fi
        [ $count -eq 0 ] && count=1
        [ $count -gt 20 ] && count=20
        local delay=$((20/count))
        if [ "$RANDOMIZE" = "disabled" ]; then
            fbi -T 2 -once -t $delay -noverbose -a -l "$config" >/dev/null 2>&1
        else
            fbi -T 2 -once -t $delay -noverbose -a "$line" >/dev/null 2>&1
        fi
    fi
    exit 0
}

case "$1" in
    start|"")
        do_start &
        ;;
    restart|reload|force-reload)
        echo "Error: argument '$1' not supported" >&2
        exit 3
       ;;
    stop)
        # No-op
        ;;
    status)
        exit 0
        ;;
    *)
        echo "Usage: asplashscreen [start|stop]" >&2
        exit 3
        ;;
esac
