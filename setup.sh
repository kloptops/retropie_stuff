#!/bin/bash

#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/kloptops/retropie_stuff/master/LICENSE.md
#

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

########################################################################################
### Shutdown button.
do_shutdown_button_install() {
	echo "Installing shutdown button script"
	if [ -f $HOME/bin/shutdown.py ];
	then
		echo "Shutdown button already installed!"
		return
	fi

	echo " * Moving files"
	mkdir -vp $HOME/bin
	cp -v bin/shutdown.py $HOME/bin/
	chmod -v +x $HOME/bin/shutdown.py

	echo " * Creating service"
	cat <<EOF | sudo tee /etc/systemd/system/shutdownpy.service
[Service]
ExecStart=/usr/bin/python /home/pi/bin/shutdown.py
WorkingDirectory=/home/pi
Restart=always
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=shutdownpy
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

	echo " * Starting service"
	sudo systemctl enable shutdownpy.service
	sudo systemctl start shutdownpy.service
	echo "Finished installing shutdown button script"
}

do_shutdown_button_uninstall() {
	echo "Uninstalling shutdown button script"
	if [ ! -f $HOME/bin/shutdown.py ];
	then
		echo "Shutdown button not installed!"
		return
	fi

	echo " * Stopping service"
	sudo systemctl stop shutdownpy.service
	sudo systemctl disable shutdownpy.service

	echo " * Removing files"
	sudo rm -v /etc/systemd/system/shutdownpy.service
	
	rm -v $HOME/bin/shutdown.py
	do_remove_home_bin
	echo "Finished uninstalling shutdown button script"
}

########################################################################################
## Quiet boot
do_quiet_boot_install() {
	WANT_BERRIES=0
	if [ x"$1" != "" ];
	then
		WANT_BERRIES=$1
	fi

	echo "Installing quiet boot"
	if [ $(grep -c 'quiet' /boot/cmdline.txt) -gt 0 ];
	then
		echo "Quiet boot already installed!"
		return
	fi

	echo " * Backing up files"
	cp -v /etc/motd backup/motd

	echo " * Making things a little more quiet"
	touch ~/.hushlogin
	echo "" | sudo tee /etc/motd

	echo " * Making things a quite a bit more quiet"
	sudo sed -i 's#^ExecStart.*#ExecStart=-/sbin/agetty --skip-login --noclear --noissue --login-options "-f pi" \%I \$TERM#' /etc/systemd/system/autologin@.service
	sudo sed -i 's/console=tty[0-9]/console=tty3/; s/loglevel=[0-9]/loglevel=3/; s/$/ vt.global_cursor_default=0 quiet/' /boot/cmdline.txt

	if [ $WANT_BERRIES -eq 1 ];
	then
		sudo sed -i 's/$/ logo.nologo/' /boot/cmdline.txt
	fi

	echo "Done installing quiet boot"
}

do_quiet_boot_uninstall() {
	echo "Installing quiet boot"
	if [ $(grep -c 'quiet' /boot/cmdline.txt) -eq 0 ];
	then
		echo "Quiet boot hasn't been installed!"
		return
	fi

	echo " * Restoring files back to their former glory"

	if [ -f backup/motd ];
	then
		sudo cp -v backup/motd /etc/motd
		rm -v backup/motd
	fi

	rm -v ~/.hushlogin

	sudo sed -i 's#^ExecStart.*#ExecStart=-/sbin/agetty --autologin pi --noclear %I $TERM#' /etc/systemd/system/autologin@.service
	sudo sed -i 's/console=tty[0-9]/console=tty1/; s/ vt.global_cursor_default=0//; s/ quiet//; s/ logo.nologo//' /boot/cmdline.txt
	echo "Done uninstalling quiet boot"
}


########################################################################################
## Helper functions
do_remove_home_bin() {
	if [ $(ls -1 $HOME/bin | wc -l) -eq 0 ];
	then
		rm -vr $HOME/bin
	fi
}

do_help() {
	cat <<EOF
Usage: setup.sh <command>

Commands:
    --network-[no]wait                    wait for network connection at startup

    --[un]install-music                   installs background music player for
                                          emulationstation
    --[un]install-splashscreen            installs a better splashscreen for booting
    --[un]install-shutdown-button         installs a service to handle a shutdown button
    --[un]install-quiet-boot[-no-berries] makes boot text a lot quieter, the -no-berries
                                          version removes the raspberries also

    --full-boyle[-no-berries]             installs everything
EOF
}


########################################################################################
## main code

if [ ! -d backup/ ];
then
	mkdir -vp backup/
fi

# No arguments? Then show help!
if [ $# -eq 0 ];
then
	do_help
fi

for i in $*
do
	case $i in
	--network-nowait)
		do_network_nowait
		;;
	--network-wait)
		do_network_wait
		;;

	--install-music)
		do_music_install
		;;
	--uninstall-music)
		do_music_uninstall
		;;

	--install-splashscreen)
		do_splashscreen_install
		;;
	--uninstall-splashscreen)
		do_splashscreen_uninstall
		;;

	--install-shutdown-button)
		do_shutdown_button_install
		;;
	--uninstall-shutdown-button)
		do_shutdown_button_uninstall
		;;

	--install-quiet-boot-no-berries)
		do_quiet_boot_install 1
		;;

	--install-quiet-boot)
		do_quiet_boot_install 0
		;;

	--uninstall-quiet-boot*)
		do_quiet_boot_uninstall
		;;

	--help)
		do_help
		exit 0
		;;

	--full-boyle-no-berries)
		## NINE-NINE!
		do_network_nowait
		do_music_install
		do_splashscreen_install
		do_shutdown_button_install
		do_quiet_boot_install 1
		exit 0
		;;

	--full-boyle)
		## NINE-NINE!
		do_network_nowait
		do_music_install
		do_splashscreen_install
		do_shutdown_button_install
		do_quiet_boot_install 0
		exit 0
		;;
	*)
		# Unknown option
		echo "Unknown option: $i"
		exit 1
		;;
	esac
done
