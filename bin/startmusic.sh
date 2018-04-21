# Play background music.

MP3DIR="/home/pi/RetroPie/roms/music"
NOMUSIC_FILE="/home/pi/.NoMusic"

mkdir -p "$MP3DIR"

if pgrep mpg123;
then
	pkill mpg123 2> /dev/null
fi

# Start music if it is not disabled, and there are mp3 files in the mp3 directory.
if [ ! -f "$NOMUSIC_FILE" ] && [ $(ls -1 $MP3DIR/*.mp3 2>/dev/null | wc -l) -gt 0 ];
then
	while pgrep omxplayer > /dev/null; do sleep 1; done
	mpg123 -Z $MP3DIR/*.mp3 >/dev/null 2>&1 &
fi
