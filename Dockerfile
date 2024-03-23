FROM debian:bookworm-slim

ENV MODE nogui-web
ENV DEBIAN_VERSION 12
ENV REPOFILE https://raw.githubusercontent.com/Xpra-org/xpra/master/packaging/repos/bookworm/xpra.sources
ENV QT_QPA_PLATFORM=xcb

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y wget gnupg screen && \
    wget -O "/usr/share/keyrings/xpra.asc" https://xpra.org/xpra.asc && \
    wget -qO - http://download.opensuse.org/repositories/network:retroshare/Debian_12/Release.key | gpg --dearmor > /etc/apt/trusted.gpg.d/retroshare.gpg && \
    /bin/bash -c "echo 'deb http://download.opensuse.org/repositories/network:/retroshare/Debian_${DEBIAN_VERSION}/ /' > /etc/apt/sources.list.d/retroshare.list" && \
    apt-get update && \
    apt-get install -y xpra retroshare-gui-unstable && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update -y
RUN apt-cache search python3-uinput
RUN apt-get install -y python3-uinput

RUN useradd -m -d /home/retrouser -s /bin/bash -p "tmp" retrouser

RUN PASSWD=$(gpg --gen-random --armor 0 8) && \
    echo "retrouser:$PASSWD" && \
    echo "retrouser:$PASSWD" | chpasswd && \
    echo "retrouser:$PASSWD" > /home/retrouser/inipass

RUN mkdir /run/user/1000 && \
    mkdir /run/user/1000/xpra && \
    chown -R retrouser:retrouser /run/user/1000

# Create the startup.sh script
RUN echo '#!/bin/bash' >> /home/retrouser/startup.sh
RUN echo 'if [[ $MODE == "nogui" ]]' >> /home/retrouser/startup.sh
RUN echo 'then' >> /home/retrouser/startup.sh
RUN echo '        retroshare' >> /home/retrouser/startup.sh
RUN echo 'elif [[ $MODE == "nogui-web" ]]' >> /home/retrouser/startup.sh
RUN echo 'then' >> /home/retrouser/startup.sh
RUN echo '        retroshare-nogui --webinterface 9090 --docroot /usr/share/retroshare/webui/ --http-allow-all' >> /home/retrouser/startup.sh
RUN echo 'elif [[ $MODE == "gui" ]]' >> /home/retrouser/startup.sh
RUN echo 'then' >> /home/retrouser/startup.sh
RUN echo '        su - retrouser -c "xpra start :100 --bind-tcp=0.0.0.0:14500 --no-mdns --no-notifications --no-pulseaudio"' >> /home/retrouser/startup.sh
RUN echo '        sleep 2' >> /home/retrouser/startup.sh
RUN echo '        su - retrouser -c "DISPLAY=:100 retroshare"' >> /home/retrouser/startup.sh
RUN echo 'else' >> /home/retrouser/startup.sh
RUN echo '        echo "Wrong mode selected"' >> /home/retrouser/startup.sh
RUN echo 'fi' >> /home/retrouser/startup.sh

RUN chown retrouser:retrouser /home/retrouser/startup.sh && \
    chmod +x /home/retrouser/startup.sh

# USER retrouser
WORKDIR /home/retrouser

ENTRYPOINT ["./startup.sh"]
