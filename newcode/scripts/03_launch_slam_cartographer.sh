#!/bin/bash

# TurtleBot3 SLAM with Cartographer
# This script launches SLAM using Google's Cartographer algorithm
# Make sure to run the Gazebo simulation first!

echo "========================================="
echo "Launching TurtleBot3 SLAM (Cartographer)"
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
echo ""
echo "IMPORTANT: Make sure Gazebo simulation is running first!"
echo "If not, run ./01_launch_gazebo_world.sh in another terminal"
echo ""
echo "Starting SLAM with Cartographer..."
echo "RViz will open to visualize the mapping process"

# Launch SLAM with Cartographer
roslaunch turtlebot3_slam turtlebot3_slam.launch slam_methods:=cartographer

echo "SLAM ended." 