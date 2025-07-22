#!/bin/bash
echo "========================================="
echo "TurtleBot3 Map Saving"
echo "========================================="
source /opt/ros/noetic/setup.bash
source /turtlebot_ws/devel/setup.bash
mkdir -p /turtlebot_ws/maps
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
MAP_NAME="map_${TIMESTAMP}"
echo "Saving map as: ${MAP_NAME}"
cd /turtlebot_ws/maps
rosrun map_server map_saver -f ${MAP_NAME}
echo "Map saved successfully!"
ls -la /turtlebot_ws/maps/
