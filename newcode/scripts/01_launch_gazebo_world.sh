#!/bin/bash
echo "========================================="
echo "Launching TurtleBot3 Gazebo Simulation"
echo "========================================="
source /opt/ros/noetic/setup.bash
source /turtlebot_ws/devel/setup.bash
export TURTLEBOT3_MODEL=waffle_pi
export DISPLAY=:3
echo "TurtleBot3 Model: $TURTLEBOT3_MODEL"
echo "Display: $DISPLAY"
echo "Starting Gazebo world..."
DISPLAY=:3 roslaunch turtlebot3_gazebo turtlebot3_world.launch
echo "Gazebo simulation ended."
