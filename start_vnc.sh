#!/bin/bash

# Launch virtual X server
Xvfb :1 -screen 0 1024x768x16 &
export DISPLAY=:1
sleep 2

# Start window manager
xfce4-session &

# Start noVNC server (must be before x11vnc for WebSocket support)
websockify --web=/usr/share/novnc/ 6080 localhost:5900 &

# Start VNC server (in background)
x11vnc -display :1 -forever -nopw -shared &

# Optional: Start rviz
source /opt/ros/kinetic/setup.bash
source /catkin_ws/devel/setup.bash
rviz &

# Keep the container alive
wait
