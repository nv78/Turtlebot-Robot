#!/bin/bash
echo "========================================="
echo "Launching TurtleBot3 SLAM (gmapping)"
echo "========================================="
source /opt/ros/noetic/setup.bash
source /turtlebot_ws/devel/setup.bash
export TURTLEBOT3_MODEL=waffle_pi
export DISPLAY=:3
echo "TurtleBot3 Model: $TURTLEBOT3_MODEL"
echo "Display: $DISPLAY"
echo "IMPORTANT: Make sure Gazebo simulation is running first!"
echo "Starting SLAM with gmapping..."
echo "RViz will open in VNC display :3"
DISPLAY=:3 roslaunch turtlebot3_slam turtlebot3_slam.launch slam_methods:=gmapping
