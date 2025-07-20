#! /bin/bash

openvpn /etc/openvpn/server.conf &

service ssh start

/opt/websockify/run 5903 --cert=/self.pem --web=/opt/noVNC --wrap-mode=ignore -- vncserver :3 -securitytypes TLSVnc,VNC -localhost
