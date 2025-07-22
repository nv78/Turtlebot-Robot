#!/bin/bash

# TurtleBot3 Gazebo House World Launch Script
# This script launches Gazebo with TurtleBot3 in the house simulation environment

echo "========================================="
echo "Launching TurtleBot3 Gazebo House World"
echo "========================================="

# Source ROS environment
source /opt/ros/noetic/setup.bash
source /turtlebot_ws/devel/setup.bash

# Set TurtleBot3 model
export TURTLEBOT3_MODEL=waffle_pi

# Set display for GUI
export DISPLAY=:3

echo "TurtleBot3 Model: $TURTLEBOT3_MODEL"
echo "Display: $DISPLAY"
echo "Starting Gazebo house world..."
echo ""
echo "This world provides a more complex environment for SLAM and navigation testing"

# Launch TurtleBot3 in Gazebo house world
roslaunch turtlebot3_gazebo turtlebot3_house.launch

echo "Gazebo house simulation ended." 