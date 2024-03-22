#!/bin/bash

if [[ $MODE == "nogui" ]]
then
	retroshare
elif [[ $MODE == "nogui-web" ]]
then
	retroshare-nogui --webinterface 9090 --docroot /usr/share/retroshare/webui/ --http-allow-all
elif [[ $MODE == "gui" ]]
then
	xpra start :100 --bind-tcp=0.0.0.0:14500 --no-mdns --no-notifications --no-pulseaudio
	sleep 2
        DISPLAY=:100 retroshare
else
	echo "Wrong mode selected"
fi
