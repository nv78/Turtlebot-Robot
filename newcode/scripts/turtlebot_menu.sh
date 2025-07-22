#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Ensure we're using VNC display
export DISPLAY=:3

show_menu() {
    clear
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${CYAN}    TurtleBot3 Control Center Menu${NC}"
    echo -e "${CYAN}    (VNC Display :3)${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo ""
    echo -e "${GREEN}Available Options:${NC}"
    echo -e "  ${YELLOW}1)${NC} Launch Gazebo World"
    echo -e "  ${YELLOW}2)${NC} Launch SLAM (gmapping)"
    echo -e "  ${YELLOW}3)${NC} Keyboard Teleop Control"
    echo -e "  ${YELLOW}4)${NC} Save Current Map"
    echo -e "  ${YELLOW}5)${NC} Test VNC Display"
    echo -e "  ${YELLOW}6)${NC} List Available Scripts"
    echo -e "  ${YELLOW}q)${NC} Quit"
    echo ""
    echo -e "${CYAN}Current Display: $DISPLAY${NC}"
    echo ""
}

while true; do
    show_menu
    echo -n "Enter your choice: "
    read choice
    case $choice in
        1) 
            echo "Launching Gazebo on VNC display :3..."
            DISPLAY=:3 xterm -title "Gazebo" -e "cd /turtlebot_ws/scripts && DISPLAY=:3 ./01_launch_gazebo_world.sh" &
            ;;
        2) 
            echo "Starting SLAM on VNC display :3..."
            DISPLAY=:3 xterm -title "SLAM" -e "cd /turtlebot_ws/scripts && DISPLAY=:3 ./02_launch_slam_gmapping.sh" &
            ;;
        3) 
            echo "Starting Teleop on VNC display :3..."
            DISPLAY=:3 xterm -title "Teleop" -e "cd /turtlebot_ws/scripts && DISPLAY=:3 ./04_teleop_control.sh" &
            ;;
        4) 
            echo "Saving Map..."
            ./scripts/05_save_map.sh
            echo "Press any key to continue..."
            read -n 1
            ;;
        5)
            echo "Testing VNC display with xclock..."
            DISPLAY=:3 xclock &
            echo "You should see a clock in your VNC window"
            echo "Press any key to continue..."
            read -n 1
            ;;
        6)
            echo "Available scripts:"
            ls -la scripts/
            echo "Press any key to continue..."
            read -n 1
            ;;
        q|Q) 
            echo "Goodbye!"
            exit 0
            ;;
        *) 
            echo "Invalid option"
            sleep 1
            ;;
    esac
done
