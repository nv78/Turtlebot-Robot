#!/bin/bash

echo "========================================="
echo "Creating TurtleBot3 Scripts in Container"
echo "========================================="

# Create scripts directory
mkdir -p /turtlebot_ws/scripts
cd /turtlebot_ws

# Create all the scripts with here documents
cat > scripts/01_launch_gazebo_world.sh << 'EOF'
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
roslaunch turtlebot3_gazebo turtlebot3_world.launch
echo "Gazebo simulation ended."
EOF

cat > scripts/02_launch_slam_gmapping.sh << 'EOF'
#!/bin/bash
echo "========================================="
echo "Launching TurtleBot3 SLAM (gmapping)"
echo "========================================="
source /opt/ros/noetic/setup.bash
source /turtlebot_ws/devel/setup.bash
export TURTLEBOT3_MODEL=waffle_pi
export DISPLAY=:3
echo "TurtleBot3 Model: $TURTLEBOT3_MODEL"
echo "IMPORTANT: Make sure Gazebo simulation is running first!"
echo "Starting SLAM with gmapping..."
roslaunch turtlebot3_slam turtlebot3_slam.launch slam_methods:=gmapping
EOF

cat > scripts/04_teleop_control.sh << 'EOF'
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
EOF

cat > scripts/05_save_map.sh << 'EOF'
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
EOF

cat > scripts/turtlebot_menu.sh << 'EOF'
#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

show_menu() {
    clear
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${CYAN}    TurtleBot3 Control Center Menu${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo ""
    echo -e "${GREEN}SIMULATION WORLDS:${NC}"
    echo -e "  ${YELLOW}1)${NC} Launch Gazebo World"
    echo -e "  ${YELLOW}2)${NC} Launch SLAM (gmapping)"
    echo -e "  ${YELLOW}3)${NC} Keyboard Teleop Control"
    echo -e "  ${YELLOW}4)${NC} Save Current Map"
    echo -e "  ${YELLOW}q)${NC} Quit"
    echo ""
}

while true; do
    show_menu
    echo -n "Enter your choice: "
    read choice
    case $choice in
        1) echo "Launching Gazebo..."; xterm -title "Gazebo" -e "cd /turtlebot_ws/scripts && ./01_launch_gazebo_world.sh" & ;;
        2) echo "Starting SLAM..."; xterm -title "SLAM" -e "cd /turtlebot_ws/scripts && ./02_launch_slam_gmapping.sh" & ;;
        3) echo "Starting Teleop..."; xterm -title "Teleop" -e "cd /turtlebot_ws/scripts && ./04_teleop_control.sh" & ;;
        4) echo "Saving Map..."; ./scripts/05_save_map.sh ;;
        q|Q) echo "Goodbye!"; exit 0 ;;
        *) echo "Invalid option" ;;
    esac
done
EOF

# Make all scripts executable
chmod +x scripts/*.sh

# Create maps directory
mkdir -p /turtlebot_ws/maps

echo ""
echo "✅ All TurtleBot3 scripts created!"
echo ""
echo "🎯 QUICK START:"
echo "   ./scripts/turtlebot_menu.sh"
echo ""
echo "Available scripts:"
echo "  - 01_launch_gazebo_world.sh  (Gazebo simulation)"
echo "  - 02_launch_slam_gmapping.sh (SLAM mapping)"  
echo "  - 04_teleop_control.sh       (Keyboard control)"
echo "  - 05_save_map.sh            (Save maps)"
echo "  - turtlebot_menu.sh          (Interactive menu)"
echo ""
echo "✅ Ready for TurtleBot3 operations!"
