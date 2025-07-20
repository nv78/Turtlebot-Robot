#!/bin/bash
set -e

# Navy Autonomous Production Entrypoint
# Handles initialization, health checks, and graceful shutdown

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

# Graceful shutdown handler
shutdown_handler() {
    log_info "Received shutdown signal, cleaning up..."
    
    # Kill all ROS processes
    pkill -f ros || true
    
    # Wait for processes to clean up
    sleep 2
    
    log_success "Shutdown complete"
    exit 0
}

# Set up signal handlers
trap shutdown_handler SIGTERM SIGINT

# Environment validation
validate_environment() {
    log_info "Validating environment..."
    
    # Check ROS environment
    if [ -z "$ROS_DISTRO" ]; then
        log_error "ROS_DISTRO not set"
        exit 1
    fi
    
    # Check workspace
    if [ ! -f "/catkin_ws/devel/setup.bash" ]; then
        log_error "Catkin workspace not built"
        exit 1
    fi
    
    # Check YOLO weights
    WEIGHTS_DIR="/catkin_ws/src/darknet_ros/darknet_ros/yolo_network_config/weights"
    if [ ! -f "$WEIGHTS_DIR/yolov3-tiny.weights" ]; then
        log_warning "YOLO weights not found, downloading..."
        cd "$WEIGHTS_DIR"
        wget -q http://pjreddie.com/media/files/yolov3-tiny.weights || {
            log_error "Failed to download YOLO weights"
            exit 1
        }
    fi
    
    log_success "Environment validation complete"
}

# Initialize ROS environment
initialize_ros() {
    log_info "Initializing ROS environment..."
    
    # Source ROS setup
    source /opt/ros/noetic/setup.bash
    source /catkin_ws/devel/setup.bash
    
    # Set ROS network configuration
    export ROS_MASTER_URI=${ROS_MASTER_URI:-http://localhost:11311}
    export ROS_IP=${ROS_IP:-$(hostname -I | awk '{print $1}')}
    
    log_info "ROS_MASTER_URI: $ROS_MASTER_URI"
    log_info "ROS_IP: $ROS_IP"
    
    # Start roscore if not running and we're the main process
    if [ "$1" != "roslaunch" ] && ! pgrep -x "roscore" > /dev/null; then
        log_info "Starting roscore..."
        roscore &
        sleep 3
    fi
    
    log_success "ROS environment initialized"
}

# Health check function
health_check() {
    # Check if ROS master is running
    if ! rostopic list > /dev/null 2>&1; then
        log_error "ROS master not responding"
        return 1
    fi
    
    # Check if critical nodes are running
    if [ "$NAVY_MODE" = "full_autonomous" ]; then
        REQUIRED_NODES=("/darknet_ros" "/move_base" "/orchestrator")
        for node in "${REQUIRED_NODES[@]}"; do
            if ! rosnode info "$node" > /dev/null 2>&1; then
                log_warning "Required node $node not running"
            fi
        done
    fi
    
    return 0
}

# Main execution
main() {
    log_info "Starting Navy Autonomous TurtleBot (Production)"
    log_info "Mode: ${NAVY_MODE:-default}"
    log_info "Arguments: $*"
    
    # Validate environment
    validate_environment
    
    # Initialize ROS
    initialize_ros
    
    # Wait for system to be ready
    log_info "Waiting for system initialization..."
    sleep 5
    
    # Start health monitoring in background
    if [ "${ENABLE_HEALTH_MONITORING:-true}" = "true" ]; then
        {
            while true; do
                sleep 30
                if ! health_check; then
                    log_warning "Health check failed"
                fi
            done
        } &
    fi
    
    # Execute the main command
    log_info "Starting main application: $*"
    
    if [ $# -eq 0 ]; then
        # Default behavior
        exec roslaunch turtlebot_complete.launch mode:=semi_autonomous
    else
        # Execute provided command
        exec "$@"
    fi
}

# Run main function with all arguments
main "$@" 