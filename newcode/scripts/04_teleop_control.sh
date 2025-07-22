#!/bin/bash
echo "========================================="
echo "TurtleBot3 Keyboard Teleop Control"
echo "========================================="
source /opt/ros/noetic/setup.bash
source /turtlebot_ws/devel/setup.bash
export TURTLEBOT3_MODEL=waffle_pi
echo "Keyboard Controls:"
echo "  w/x : increase/decrease linear velocity"
echo "  a/d : increase/decrease angular velocity"  
echo "  space/s : force stop"
echo "  CTRL-C to quit"
echo "Starting teleop control..."
roslaunch turtlebot3_teleop turtlebot3_teleop_key.launch
