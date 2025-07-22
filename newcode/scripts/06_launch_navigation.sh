#!/bin/bash

# TurtleBot3 Navigation Script
# This script launches navigation with a pre-built map
# Make sure to have a saved map first!

echo "========================================="
echo "TurtleBot3 Navigation with Pre-built Map"
echo "========================================="

# Source ROS environment
source /opt/ros/noetic/setup.bash
source /turtlebot_ws/devel/setup.bash

# Set TurtleBot3 model
export TURTLEBOT3_MODEL=waffle_pi

# Set display for GUI
export DISPLAY=:3

# Create maps directory if it doesn't exist
mkdir -p /turtlebot_ws/maps

# Check if maps exist
if [ ! -d "/turtlebot_ws/maps" ] || [ -z "$(ls -A /turtlebot_ws/maps/*.yaml 2>/dev/null)" ]; then
    echo "ERROR: No maps found!"
    echo "Please create a map first using SLAM:"
    echo "  1. Run ./01_launch_gazebo_world.sh"
    echo "  2. Run ./02_launch_slam_gmapping.sh or ./03_launch_slam_cartographer.sh"
    echo "  3. Run ./04_teleop_control.sh to move robot and create map"
    echo "  4. Run ./05_save_map.sh to save the map"
    exit 1
fi

# List available maps
echo "Available maps:"
cd /turtlebot_ws/maps
for map_file in *.yaml; do
    if [ -f "$map_file" ]; then
        map_name=$(basename "$map_file" .yaml)
        echo "  $map_name"
    fi
done

echo ""
echo -n "Enter map name (without .yaml extension): "
read MAP_NAME

# Check if selected map exists
if [ ! -f "/turtlebot_ws/maps/${MAP_NAME}.yaml" ]; then
    echo "ERROR: Map '${MAP_NAME}' not found!"
    exit 1
fi

echo ""
echo "TurtleBot3 Model: $TURTLEBOT3_MODEL"
echo "Display: $DISPLAY"
echo "Using map: ${MAP_NAME}"
echo ""
echo "IMPORTANT: Make sure Gazebo simulation is running first!"
echo "If not, run ./01_launch_gazebo_world.sh in another terminal"
echo ""
echo "Starting navigation..."
echo "RViz will open. Use '2D Nav Goal' to set navigation targets"

# Launch navigation with the selected map
roslaunch turtlebot3_navigation turtlebot3_navigation.launch map_file:=/turtlebot_ws/maps/${MAP_NAME}.yaml

echo "Navigation ended." 