#! /bin/bash

openvpn /etc/openvpn/server.conf &

service ssh start

# Clean up any existing display sessions
rm -f /tmp/.X3-lock /tmp/.X11-unix/X3 /root/.vnc/*.pid
rm -f /tmp/.X2-lock /tmp/.X11-unix/X2

# Start Xvfb on display :2 for VirtualGL/OpenGL support
Xvfb :2 -screen 0 1024x768x24 +extension GLX +render -noreset &

# Wait for Xvfb to be ready
sleep 2

# Use websockify with wrap mode to launch VNC server (this was working)
/opt/websockify/run 5903 --cert=/self.pem --web=/opt/noVNC --wrap-mode=ignore -- vncserver :3 -geometry 1024x768 -securitytypes TLSVnc,VNC -localhost
