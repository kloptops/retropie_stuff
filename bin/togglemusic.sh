#!/bin/bash

NOMUSIC_FILE="/home/pi/.NoMusic"
STATUS="Disabled"

if [ -f "$NOMUSIC_FILE" ]
then
	rm -f "$NOMUSIC_FILE"
	STATUS="Enabled"
else
	touch "$NOMUSIC_FILE"
fi

/home/pi/bin/startmusic.sh

dialog --timeout 4 --backtitle "Background Music" --msgbox "Music $STATUS" 10 30
