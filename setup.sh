#!/bin/bash

if [ $(basename $PWD) != "retropie_stuff" ];
then
	echo "Please run this in the retropie_stuff root directory."
	exit 1
fi

########################################################################################
## Network no wait
do_network_nowait() {
	echo "Raspberry Pi will continue booting without a network connection"
	sudo raspi-config nonint do_boot_wait 1
}

do_network_wait() {
	echo "Raspberry Pi will wait for a network connection before statup"
	sudo raspi-config nonint do_boot_wait 0
}

########################################################################################
## Background music stuff
do_music_install() {
	echo "Installing emulationstation background music"
	if [ -f $HOME/bin/startmusic.sh ];
	then
		echo "Emulationstation background music already installed"
		return
	fi

	if pgrep emulationstation;
	then
		echo "Emulationstation must not be running."
		return
	fi

	echo "* Installing mpg123"
	# sudo apt-get update
	sudo apt-get -y install mpg123

	echo " * Moving music player scripts into place"
	mkdir -p $HOME/bin
	cp -v bin/startmusic.sh bin/togglemusic.sh $HOME/bin
	chmod -v +x $HOME/bin/startmusic.sh $HOME/bin/togglemusic.sh

	echo " * Patching player scripts into emulationstation configs"
	CONFIGDIR=/opt/retropie/configs/all/

	TEMPFILE=$(tempfile)
	cat - $CONFIGDIR/autostart.sh <<EOF > $TEMPFILE
# Plays music
/home/pi/bin/startmusic.sh & # music

EOF
	cat $TEMPFILE > $CONFIGDIR/autostart.sh
	rm -f $TEMPFILE

	cat - <<EOF > /opt/retropie/configs/all/runcommand-onstart.sh
# "STOP" the music
if pgrep mpg123; then pkill -STOP mpg123; fi
EOF

	cat - <<EOF > /opt/retropie/configs/all/runcommand-onend.sh
# Continue the music
if pgrep mpg123; then pkill -CONT mpg123; fi
EOF

	GAMELIST=$HOME/.emulationstation/gamelists/retropie/gamelist.xml

	echo " * Install emulationstation music toggle menu item"
	ln -vs $HOME/bin/togglemusic.sh $HOME/RetroPie/retropiemenu/togglemusic.sh
	ln -vs $HOME/RetroPie/retropiemenu/icons/{audiosettings,togglemusic}.png

	if [ $(grep -c 'togglemusic.sh' $GAMELIST) -eq 0 ];
	then
		TEMPFILE=$(tempfile)

		OFFSET=$(grep -n -m 1 '</gameList>' $GAMELIST | cut -d ':' -f 1)
		let OFFSET--
		head -n $OFFSET $GAMELIST > $TEMPFILE
		cat - <<EOF >> $TEMPFILE
	<game>
		<path>./togglemusic.sh</path>
		<name>Toggle Menu Music</name>
		<desc>Toggles the game selection menu music.</desc>
		<image>./icons/togglemusic.png</image>
    </game>
EOF
		let OFFSET++
		tail -n +$OFFSET $GAMELIST >> $TEMPFILE

		# Patch it in.
		cat $TEMPFILE > $GAMELIST
		rm -f $TEMPFILE
	fi

	echo "Done installing emulationstation background music"
}

do_music_uninstall() {
	if [ ! -f $HOME/bin/startmusic.sh ];
	then
		echo "Emulationstation background music not installed"
		return
	fi

	if pgrep mpg123;
	then
		echo "Stopping mpg123"
		pkill mpg123
	fi

	echo "Uninstalling mpg123"
	sudo apt-get -y remove mpg123

	echo " * Removing scripts"
	rm -vf $HOME/bin/startmusic.sh $HOME/bin/togglemusic.sh

	echo " * Unpatch emulationstation configs"
	CONFIGDIR=/opt/retropie/configs/all/
	TEMPFILE=$(tempfile)
	grep -vP '#.*music' $CONFIGDIR/autostart.sh > $TEMPFILE
	cat $TEMPFILE > $CONFIGDIR/autostart.sh
	rm -f $TEMPFILE 
	rm -v $CONFIGDIR/runcommand-on{end,start}.sh

	echo " * Removing auxillary files"
	rm -vf $HOME/.NoMusic

	GAMELIST=$HOME/.emulationstation/gamelists/retropie/gamelist.xml

	rm -vf $HOME/RetroPie/retropiemenu/togglemusic.sh
	rm -v $HOME/RetroPie/retropiemenu/icons/togglemusic.png
	if [ $(grep -c 'togglemusic.sh' $GAMELIST) -ne 0 ];
	then
		## Okay so I'm sure there is a better way to do this... but... it works?
		SIZE=$(wc -l < $GAMELIST)
		OFFSET=$(grep -n -m 1 '<path>./togglemusic.sh</path>' $GAMELIST | cut -d ':' -f 1)
		## Find the start of the gamelist entry.
		START=$OFFSET
		while [ $(head -n $START $GAMELIST | tail -n 1 | grep -c '<game>') -ne 1 ];
		do
			let START--
		done
		let START--

		## Find the end of the gamelist entry.
		END=$OFFSET
		while [ $(head -n $END $GAMELIST | tail -n 1 | grep -c '</game>') -ne 1 ] && [ $END -le $SIZE ];
		do
			let END++
		done
		let END++

		# Patch it out.
		TEMPFILE=$(tempfile)
		head -n $START $GAMELIST > $TEMPFILE
		tail -n +$END $GAMELIST >> $TEMPFILE
		cat $TEMPFILE > $GAMELIST
		rm -f $TEMPFILE
	fi

	do_remove_home_bin

	echo "Done installing emulationstation background music"
}

########################################################################################
## Better splashscrren stuff
do_splashscreen_install() {
	echo "Installing a better splashscreen"
	if [ $(grep -c 'imgvideo' /opt/retropie/supplementary/splashscreen/asplashscreen.sh) -gt 0 ];
	then
		echo "Better splashscreen already installed"
		return
	fi

	echo " * Backing up files"
	cp -v /opt/retropie/supplementary/splashscreen/asplashscreen.sh backup/
	cp -v /etc/splashscreen.list backup/

	echo " * Copying new splashscreen files"
	cp -v splashscreens/RPi0_* $HOME/RetroPie/splashscreens/
	sudo cp -v retropie-splashscreen/asplashscreen.sh /opt/retropie/supplementary/splashscreen/
	sudo cp -v splashscreens/splashscreen.list /etc/splashscreen.list

	echo "Finished installing a better splashscreen"
}

do_splashscreen_uninstall() {
	echo "Uninstalling a better splashscreen"
	if [ $(grep -c 'imgvideo' /opt/retropie/supplementary/splashscreen/asplashscreen.sh) -eq 0 ];
	then
		echo "Better splashscreen not installed"
		return
	fi

	echo " * Restoring old files"
	sudo cp -v backup/asplashscreen.sh /opt/retropie/supplementary/splashscreen/
	sudo cp -v backup/splashscreen.list /etc/splashscreen.list

	echo "Finished uninstalling a better splashscreen"
}


### Shutdown button.
do_shutdown_button_install() {
	echo "Installing shutdown button script"
	if [ -f $HOME/bin/pishutdown.py ];
	then
		echo "Shutdown script already installed"
		return
	fi

	echo " * Moving files"
	mkdir -vp $HOME/bin
	cp -v bin/shutdown.py $HOME/bin/
	chmod -v +x $HOME/bin/shutdown.py

	echo " * Creating service"
	cat << EOF > /etc/systemd/system/pishutdown.service
[Service]
ExecStart=/usr/bin/python /home/pi/bin/shutdown.py
WorkingDirectory=/home/pi
Restart=always
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=pishutdown
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

	echo " * Starting service"
	sudo systemctl enable pishutdown.service
	sudo systemctl start pishutdown.service
	echo "Finished installing shutdown button script"
}

do_shutdown_button_uninstall() {
	echo "Uninstalling shutdown button script"
	if [ !-f $HOME/bin/pishutdown.py ];
	then
		echo "Shutdown button not installed!"
		return
	fi

	echo " * Stopping service"
	sudo systemctl stop pishutdown.service
	sudo systemctl disable pishutdown.service

	echo " * Removing files"
	sudo rm -v /etc/systemd/system/pishutdown.service
	
	rm -v $HOME/bin/shutdown.py
	do_remove_home_bin
	echo "Finished uninstalling shutdown button script"
}

do_remove_home_bin() {
	if [ $(ls -1 $HOME/bin | wc -l) -eq 0 ];
	then
		rm -vr $HOME/bin
	fi
}

do_help() {
	cat << EOF
Usage: setup.sh <command>

Commands:
    --network-[no]wait          wait for network connection at startup

    --[un]install-music         installs background music player for emulationstation
    --[un]install-splashscreen  installs a better splashscreen for booting

    --full-boyle                installs everything
EOF
}

if [ ! -d backup/ ];
then
	mkdir -vp backup/
fi

for i in $*
do
	case $i in
	--network-nowait)
		do_network_nowait
		exit 0
		;;
	--network-wait)
		do_network_wait
		exit 0
		;;

	--install-music)
		do_music_install
		exit 0
		;;
	--uninstall-music)
		do_music_uninstall
		exit 0
		;;

	--install-splashscreen)
		do_splashscreen_install
		exit 0
		;;
	--uninstall-splashscreen)
		do_splashscreen_uninstall
		exit 0
		;;

	--install-shutdown-button)
		do_shutdown_button_install
		exit 0
		;;
	--uninstall-shutdown-button)
		do_shutdown_button_uninstall
		exit 0
		;;

	--help)
		do_help
		exit 0
		;;

	--full-boyle)
		do_network_nowait
		do_music_install
		do_splashscreen_install
		do_shutdown_button_install
		exit 0
		;;
	*)
		# Unknown option
		echo "Unknown option: $i"
		exit 1
		;;
	esac
done
