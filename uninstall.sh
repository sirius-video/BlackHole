#!/bin/bash

sudo rm -rf /Library/Audio/Plug-Ins/HAL/BlackHole.SiriusA.driver/
sudo rm -rf /Library/Audio/Plug-Ins/HAL/BlackHole.SiriusB.driver/

if [[ $(sw_vers -productVersion) == "10.9" ]] 
	then
		sudo sudo killall coreaudiod
	else 
		sudo launchctl kickstart -k system/com.apple.audio.coreaudiod
fi

echo "Successfully uninstalled Sirius A and B audio drivers!"
