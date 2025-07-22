#!/bin/bash

# TurtleBot3 Scripts Setup
# This script sets up the TurtleBot3 scripts environment

echo "========================================="
echo "TurtleBot3 Scripts Setup"
echo "========================================="

# Make all scripts executable
echo "Making scripts executable..."
find scripts -name "*.sh" -exec chmod +x {} \; 2>/dev/null

# Create maps directory
echo "Creating maps directory..."
mkdir -p /turtlebot_ws/maps

# Source ROS environment
echo "Sourcing ROS environment..."
source /opt/ros/noetic/setup.bash
source /turtlebot_ws/devel/setup.bash

# Set environment variables
export TURTLEBOT3_MODEL=waffle_pi
export DISPLAY=:3

echo ""
echo "Setup complete! You can now:"
echo ""
echo "1. Run the interactive menu:"
echo "   ./scripts/turtlebot_menu.sh"
echo ""
echo "2. Or run individual scripts from the scripts/ directory"
echo ""
echo "Available scripts:"
echo "  - 01_launch_gazebo_world.sh     (Basic Gazebo world)"
echo "  - 02_launch_slam_gmapping.sh    (SLAM with gmapping)"
echo "  - 03_launch_slam_cartographer.sh (SLAM with Cartographer)"
echo "  - 04_teleop_control.sh          (Keyboard control)"
echo "  - 05_save_map.sh               (Save current map)"
echo "  - 06_launch_navigation.sh       (Navigate with saved map)"
echo "  - 07_launch_gazebo_house.sh     (Complex house world)"
echo "  - 08_autonomous_exploration.sh  (Autonomous exploration)"
echo "  - turtlebot_menu.sh             (Interactive menu)"
echo ""
echo "See scripts/README.md for detailed usage instructions."
echo ""
echo "Environment configured:"
echo "  TURTLEBOT3_MODEL: $TURTLEBOT3_MODEL"
echo "  DISPLAY: $DISPLAY"
echo "  Maps directory: /turtlebot_ws/maps"
echo ""
echo "Ready to start TurtleBot3 operations!" 