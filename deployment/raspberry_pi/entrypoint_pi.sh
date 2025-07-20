#!/bin/bash
set -e

# Navy Autonomous TurtleBot Raspberry Pi Entrypoint
# Handles Pi-specific initialization, GPIO setup, and camera configuration

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
    
    # Stop all ROS processes
    pkill -f ros || true
    
    # Clean up GPIO if needed
    if command -v gpio >/dev/null 2>&1; then
        gpio reset || true
    fi
    
    # Wait for processes to clean up
    sleep 3
    
    log_success "Shutdown complete"
    exit 0
}

# Set up signal handlers
trap shutdown_handler SIGTERM SIGINT

# Check if running on Raspberry Pi
check_raspberry_pi() {
    log_info "Checking if running on Raspberry Pi..."
    
    if grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
        export IS_RASPBERRY_PI=true
        PI_MODEL=$(grep "Model" /proc/cpuinfo | cut -d: -f2 | xargs)
        log_info "Running on: $PI_MODEL"
    else
        export IS_RASPBERRY_PI=false
        log_warning "Not running on Raspberry Pi - some features may not work"
    fi
}

# Initialize GPIO and hardware
initialize_hardware() {
    if [ "$IS_RASPBERRY_PI" = "true" ]; then
        log_info "Initializing Raspberry Pi hardware..."
        
        # Enable camera if available
        if [ -e "/dev/video0" ]; then
            log_info "Camera detected at /dev/video0"
        else
            log_warning "No camera detected - check camera connection"
        fi
        
        # Check for I2C devices (for sensors)
        if command -v i2cdetect >/dev/null 2>&1; then
            log_info "Scanning I2C devices..."
            i2cdetect -y 1 || log_warning "I2C scan failed"
        fi
        
        # Initialize GPIO if tools available
        if command -v gpio >/dev/null 2>&1; then
            log_info "GPIO tools available"
        fi
        
        log_success "Hardware initialization complete"
    else
        log_info "Skipping hardware initialization (not on Pi)"
    fi
}

# Environment validation specific to Pi
validate_pi_environment() {
    log_info "Validating Raspberry Pi environment..."
    
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
    
    # Check for adequate memory
    TOTAL_MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    MIN_MEM=1000000  # 1GB in KB
    
    if [ "$TOTAL_MEM" -lt "$MIN_MEM" ]; then
        log_warning "Low memory detected: ${TOTAL_MEM}KB (recommended: >1GB)"
    else
        log_info "Memory check passed: ${TOTAL_MEM}KB available"
    fi
    
    # Check CPU temperature (Pi-specific)
    if [ "$IS_RASPBERRY_PI" = "true" ] && [ -f "/sys/class/thermal/thermal_zone0/temp" ]; then
        TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
        TEMP_C=$((TEMP / 1000))
        
        if [ "$TEMP_C" -gt 70 ]; then
            log_warning "High CPU temperature: ${TEMP_C}°C"
        else
            log_info "CPU temperature: ${TEMP_C}°C"
        fi
    fi
    
    log_success "Environment validation complete"
}

# Initialize ROS environment for Pi
initialize_ros_pi() {
    log_info "Initializing ROS environment for Raspberry Pi..."
    
    # Source ROS setup
    source /opt/ros/noetic/setup.bash
    source /catkin_ws/devel/setup.bash
    
    # Set ROS network configuration for Pi
    export ROS_MASTER_URI=${ROS_MASTER_URI:-http://localhost:11311}
    
    # Get Pi's IP address
    if [ "$IS_RASPBERRY_PI" = "true" ]; then
        # Try to get WiFi IP first, then Ethernet
        ROS_IP=$(ip addr show wlan0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)
        if [ -z "$ROS_IP" ]; then
            ROS_IP=$(ip addr show eth0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)
        fi
        if [ -z "$ROS_IP" ]; then
            ROS_IP=$(hostname -I | awk '{print $1}')
        fi
    else
        ROS_IP=${ROS_IP:-$(hostname -I | awk '{print $1}')}
    fi
    
    export ROS_IP
    
    log_info "ROS_MASTER_URI: $ROS_MASTER_URI"
    log_info "ROS_IP: $ROS_IP"
    
    # Start roscore if not running and we're the main process
    if [ "$1" != "roslaunch" ] && ! pgrep -x "roscore" > /dev/null; then
        log_info "Starting roscore..."
        roscore &
        sleep 5
    fi
    
    log_success "ROS environment initialized"
}

# Optimize system for robotics operations
optimize_pi_performance() {
    if [ "$IS_RASPBERRY_PI" = "true" ]; then
        log_info "Optimizing Raspberry Pi performance..."
        
        # Set CPU governor to performance if available
        if [ -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor" ]; then
            echo "performance" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || true
            log_info "CPU governor set to performance mode"
        fi
        
        # Increase GPU memory split for camera operations
        if command -v vcgencmd >/dev/null 2>&1; then
            GPU_MEM=$(vcgencmd get_mem gpu | cut -d= -f2 | cut -dM -f1)
            log_info "GPU memory: ${GPU_MEM}MB"
            
            if [ "$GPU_MEM" -lt 128 ]; then
                log_warning "GPU memory is low (${GPU_MEM}MB) - camera performance may be affected"
            fi
        fi
        
        log_success "Performance optimization complete"
    fi
}

# Health check function for Pi
health_check_pi() {
    # Check if ROS master is running
    if ! rostopic list > /dev/null 2>&1; then
        log_error "ROS master not responding"
        return 1
    fi
    
    # Check camera availability
    if [ "$IS_RASPBERRY_PI" = "true" ] && [ ! -e "/dev/video0" ]; then
        log_warning "Camera not detected"
    fi
    
    # Check CPU temperature
    if [ "$IS_RASPBERRY_PI" = "true" ] && [ -f "/sys/class/thermal/thermal_zone0/temp" ]; then
        TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
        TEMP_C=$((TEMP / 1000))
        
        if [ "$TEMP_C" -gt 80 ]; then
            log_error "CPU temperature critical: ${TEMP_C}°C"
            return 1
        fi
    fi
    
    return 0
}

# Main execution
main() {
    log_info "Starting Navy Autonomous TurtleBot (Raspberry Pi)"
    log_info "Mode: ${NAVY_MODE:-basic}"
    log_info "Arguments: $*"
    
    # Initialize Pi-specific components
    check_raspberry_pi
    initialize_hardware
    validate_pi_environment
    initialize_ros_pi
    optimize_pi_performance
    
    # Wait for system to be ready
    log_info "Waiting for system initialization..."
    sleep 10
    
    # Start health monitoring in background
    if [ "${ENABLE_HEALTH_MONITORING:-true}" = "true" ]; then
        {
            while true; do
                sleep 60
                if ! health_check_pi; then
                    log_warning "Health check failed"
                fi
            done
        } &
    fi
    
    # Execute the main command
    log_info "Starting main application: $*"
    
    if [ $# -eq 0 ]; then
        # Default behavior for Pi
        exec roslaunch turtlebot_complete.launch mode:=basic
    else
        # Execute provided command
        exec "$@"
    fi
}

# Run main function with all arguments
main "$@" 