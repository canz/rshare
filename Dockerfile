FROM debian:bookworm-slim

# Set environment variables
ENV MODE nogui-web
ENV DEBIAN_VERSION 12
ENV QT_QPA_PLATFORM=xcb

# Install required packages
RUN apt-get update && \
    apt-get install -y wget gnupg

# Add Retroshare repository and GPG key
RUN wget -O "/usr/share/keyrings/xpra.asc" https://xpra.org/xpra.asc && \
    wget -qO - http://download.opensuse.org/repositories/network:retroshare/Debian_${DEBIAN_VERSION}/Release.key | gpg --dearmor > /etc/apt/trusted.gpg.d/retroshare.gpg && \
    echo "deb http://download.opensuse.org/repositories/network:/retroshare/Debian_${DEBIAN_VERSION}/ /" > /etc/apt/sources.list.d/retroshare.list

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y xpra retroshare-gui && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a user with home directory and set password
RUN useradd -m -d /home/retrouser -s /bin/bash -p $(openssl passwd -1 -salt $(openssl rand -hex 16) "tmp") retrouser && \
    mkdir -p /run/user/1000/xpra && \
    chown -R retrouser:retrouser /run/user/1000

# Create the startup.sh script
RUN echo '#!/bin/bash' >> /home/retrouser/startup.sh && \
    echo 'if [[ $MODE == "nogui" ]]' >> /home/retrouser/startup.sh && \
    echo 'then' >> /home/retrouser/startup.sh && \
    echo '        su - retrouser -c "retroshare"' >> /home/retrouser/startup.sh && \
    echo 'elif [[ $MODE == "nogui-web" ]]' >> /home/retrouser/startup.sh && \
    echo 'then' >> /home/retrouser/startup.sh && \
    echo '        su - retrouser -c "retroshare-nogui --webinterface 9090 --docroot /usr/share/retroshare/webui/ --http-allow-all"' >> /home/retrouser/startup.sh && \
    echo 'elif [[ $MODE == "gui" ]]' >> /home/retrouser/startup.sh && \
    echo 'then' >> /home/retrouser/startup.sh && \
    echo '        su - retrouser -c "xpra start :100 --bind-tcp=0.0.0.0:14500 --no-mdns --no-notifications --no-pulseaudio && sleep 2 && DISPLAY=:100 retroshare"' >> /home/retrouser/startup.sh && \
    echo 'else' >> /home/retrouser/startup.sh && \
    echo '        echo "Wrong mode selected"' >> /home/retrouser/startup.sh && \
    echo 'fi' >> /home/retrouser/startup.sh && \
    chmod +x /home/retrouser/startup.sh && \
    chown retrouser:retrouser /home/retrouser/startup.sh

# USER retrouser
WORKDIR /home/retrouser

ENTRYPOINT ["./startup.sh"]
