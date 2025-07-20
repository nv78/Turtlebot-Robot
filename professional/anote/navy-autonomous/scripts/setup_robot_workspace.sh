#!/bin/bash

# Navy Autonomous Robot Workspace Setup Script
# Sets up complete workspace for trash-picking TurtleBot

set -e

# Color codes for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

# Configuration
WORKSPACE_DIR="$(pwd)/catkin_ws"
SRC_DIR="$WORKSPACE_DIR/src"

# Check if running on Raspberry Pi
check_platform() {
    log_info "Checking platform..."
    
    if grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
        export PLATFORM="raspberry_pi"
        log_info "Running on Raspberry Pi"
    else
        export PLATFORM="desktop"
        log_info "Running on desktop/server"
    fi
}

# Install ROS dependencies
install_ros_dependencies() {
    log_info "Installing ROS dependencies..."
    
    # Update package lists
    sudo apt update
    
    # Install base ROS packages
    sudo apt install -y \
        ros-${ROS_DISTRO}-turtlebot3 \
        ros-${ROS_DISTRO}-turtlebot3-msgs \
        ros-${ROS_DISTRO}-turtlebot3-navigation \
        ros-${ROS_DISTRO}-turtlebot3-teleop \
        ros-${ROS_DISTRO}-turtlebot3-bringup \
        ros-${ROS_DISTRO}-turtlebot3-description
    
    # Install manipulation packages
    sudo apt install -y \
        ros-${ROS_DISTRO}-open-manipulator-msgs \
        ros-${ROS_DISTRO}-open-manipulator-libs \
        ros-${ROS_DISTRO}-turtlebot3-manipulation \
        ros-${ROS_DISTRO}-turtlebot3-manipulation-bringup \
        ros-${ROS_DISTRO}-turtlebot3-manipulation-moveit-config
    
    # Install other required packages
    sudo apt install -y \
        ros-${ROS_DISTRO}-multirobot-map-merge \
        ros-${ROS_DISTRO}-explore-lite \
        ros-${ROS_DISTRO}-image-transport \
        ros-${ROS_DISTRO}-cv-bridge \
        ros-${ROS_DISTRO}-vision-opencv \
        ros-${ROS_DISTRO}-image-geometry \
        ros-${ROS_DISTRO}-camera-calibration \
        ros-${ROS_DISTRO}-camera-info-manager \
        ros-${ROS_DISTRO}-image-proc \
        ros-${ROS_DISTRO}-usb-cam
    
    # Install build tools
    sudo apt install -y \
        python3-catkin-tools \
        python3-rosdep \
        python3-rosinstall \
        python3-rosinstall-generator \
        python3-wstool
    
    log_success "ROS dependencies installed"
}

# Set up catkin workspace
setup_workspace() {
    log_info "Setting up catkin workspace..."
    
    # Create workspace directories
    mkdir -p "$SRC_DIR"
    cd "$WORKSPACE_DIR"
    
    # Initialize workspace if not already done
    if [ ! -f "$WORKSPACE_DIR/devel/setup.bash" ]; then
        log_info "Initializing catkin workspace..."
        catkin config --init
        catkin config --extend /opt/ros/${ROS_DISTRO}
        catkin config --cmake-args -DCMAKE_BUILD_TYPE=Release
    fi
    
    log_success "Workspace setup complete"
}

# Clone all required repositories
clone_repositories() {
    log_info "Cloning required repositories..."
    
    cd "$SRC_DIR"
    
    # Use rosinstall to install packages
    if [ -f "../../navy-autonomous.rosinstall" ]; then
        log_info "Using rosinstall file to clone repositories..."
        wstool init . ../../navy-autonomous.rosinstall
        wstool update
    else
        log_warning "rosinstall file not found, cloning manually..."
        
        # Clone Cornell-Tech-Turtlebot packages
        git clone https://github.com/Cornell-Tech-Turtlebot/object_tracking.git || log_warning "object_tracking already exists"
        git clone --recursive https://github.com/leggedrobotics/darknet_ros.git || log_warning "darknet_ros already exists"
        git clone https://github.com/ros-perception/ar_track_alvar.git || log_warning "ar_track_alvar already exists"
        git clone https://github.com/Cornell-Tech-Turtlebot/bottle_manipulator.git || log_warning "bottle_manipulator already exists"
        git clone https://github.com/Cornell-Tech-Turtlebot/patrol.git || log_warning "patrol already exists"
        git clone https://github.com/Cornell-Tech-Turtlebot/orchestrator.git || log_warning "orchestrator already exists"
        
        # Clone additional packages
        git clone https://github.com/AprilRobotics/apriltag_ros.git || log_warning "apriltag_ros already exists"
    fi
    
    log_success "Repositories cloned"
}

# Configure MoveIt
configure_moveit() {
    log_info "Configuring MoveIt..."
    
    cd "$SRC_DIR"
    
    # Clone MoveIt if not present
    if [ ! -d "moveit" ]; then
        git clone https://github.com/ros-planning/moveit.git -b ${ROS_DISTRO}-devel
    fi
    
    # Configure wait_for_servers parameter
    MOVE_GROUP_FILE="$SRC_DIR/moveit/moveit_commander/src/moveit_commander/move_group.py"
    if [ -f "$MOVE_GROUP_FILE" ]; then
        log_info "Updating MoveIt wait_for_servers parameter..."
        sed -i 's/wait_for_servers([^)]*)/wait_for_servers(50.0)/g' "$MOVE_GROUP_FILE"
    fi
    
    log_success "MoveIt configured"
}

# Install and configure YOLO weights
setup_yolo_weights() {
    log_info "Setting up YOLO weights..."
    
    YOLO_WEIGHTS_DIR="$SRC_DIR/darknet_ros/darknet_ros/yolo_network_config/weights"
    
    if [ -d "$YOLO_WEIGHTS_DIR" ]; then
        cd "$YOLO_WEIGHTS_DIR"
        
        # Download YOLO weights if not present
        if [ ! -f "yolov3-tiny.weights" ]; then
            log_info "Downloading YOLOv3-tiny weights..."
            wget -q http://pjreddie.com/media/files/yolov3-tiny.weights
        fi
        
        if [ ! -f "yolov2-tiny.weights" ]; then
            log_info "Downloading YOLOv2-tiny weights..."
            wget -q http://pjreddie.com/media/files/yolov2-tiny.weights
        fi
        
        log_success "YOLO weights configured"
    else
        log_warning "darknet_ros weights directory not found"
    fi
}

# Install Python dependencies
install_python_dependencies() {
    log_info "Installing Python dependencies..."
    
    if [ -f "requirements.txt" ]; then
        pip3 install -r requirements.txt
    fi
    
    log_success "Python dependencies installed"
}

# Configure environment variables
configure_environment() {
    log_info "Configuring environment variables..."
    
    # Set up environment variables
    cat >> ~/.bashrc << 'EOF'

# Navy Autonomous TurtleBot Environment
export TURTLEBOT3_MODEL=waffle_pi
export C_INCLUDE_PATH=/usr/include/python3.8

# ROS Network Configuration (update as needed)
export ROS_MASTER_URI=http://localhost:11311
export ROS_IP=$(hostname -I | awk '{print $1}')

# Source workspace
if [ -f ~/catkin_ws/devel/setup.bash ]; then
    source ~/catkin_ws/devel/setup.bash
fi
EOF

    log_success "Environment variables configured"
}

# Build the workspace
build_workspace() {
    log_info "Building catkin workspace..."
    
    cd "$WORKSPACE_DIR"
    
    # Initialize rosdep if needed
    if [ ! -f "/etc/ros/rosdep/sources.list.d/20-default.list" ]; then
        sudo rosdep init
    fi
    rosdep update
    
    # Install dependencies
    rosdep install --from-paths src --ignore-src -r -y
    
    # Build workspace
    catkin build
    
    if [ $? -eq 0 ]; then
        log_success "Workspace built successfully"
    else
        log_error "Workspace build failed"
        exit 1
    fi
}

# Main execution
main() {
    log_info "Starting Navy Autonomous Robot workspace setup..."
    
    check_platform
    install_ros_dependencies
    install_python_dependencies
    setup_workspace
    clone_repositories
    configure_moveit
    setup_yolo_weights
    configure_environment
    build_workspace
    
    log_success "Workspace setup complete!"
    log_info "Please run 'source ~/.bashrc' or start a new terminal session"
    log_info "Test the setup with: roslaunch turtlebot_complete.launch mode:=test_yolo"
}

# Run main function
main "$@" 