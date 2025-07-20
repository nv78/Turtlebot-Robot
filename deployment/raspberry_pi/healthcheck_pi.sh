#!/bin/bash

# Navy Autonomous TurtleBot Raspberry Pi Health Check
# Returns 0 (healthy) or 1 (unhealthy)

set -e

# Configuration
MAX_RESPONSE_TIME=15
MAX_CPU_TEMP=75
MIN_FREE_MEM=200000  # 200MB in KB

log_check() {
    echo "[HEALTH-PI] $(date '+%Y-%m-%d %H:%M:%S') $1"
}

# Check if running on Raspberry Pi
check_is_pi() {
    if grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Check ROS master connectivity
check_ros_master() {
    log_check "Checking ROS master connectivity..."
    
    if timeout $MAX_RESPONSE_TIME rostopic list >/dev/null 2>&1; then
        log_check "ROS master is responding"
        return 0
    else
        log_check "ERROR: ROS master not responding"
        return 1
    fi
}

# Check critical ROS topics for TurtleBot
check_ros_topics() {
    log_check "Checking ROS topics..."
    
    local required_topics=()
    case "${NAVY_MODE:-basic}" in
        "full_autonomous"|"semi_autonomous")
            required_topics=(
                "/darknet_ros/bounding_boxes"
                "/move_base/goal"
                "/tf"
                "/joint_states"
            )
            ;;
        "test_yolo")
            required_topics=(
                "/darknet_ros/bounding_boxes"
                "/camera/image_raw"
            )
            ;;
        "basic")
            required_topics=(
                "/tf"
                "/scan"
            )
            ;;
    esac
    
    local failed_topics=()
    
    for topic in "${required_topics[@]}"; do
        if timeout 5 rostopic list | grep -q "^${topic}$" 2>/dev/null; then
            log_check "Topic $topic exists"
        else
            log_check "ERROR: Topic $topic not found"
            failed_topics+=("$topic")
        fi
    done
    
    if [ ${#failed_topics[@]} -eq 0 ]; then
        log_check "All required topics are available"
        return 0
    else
        log_check "ERROR: ${#failed_topics[@]} required topics missing"
        return 1
    fi
}

# Check TurtleBot3 specific nodes
check_turtlebot_nodes() {
    log_check "Checking TurtleBot3 nodes..."
    
    local required_nodes=()
    case "${NAVY_MODE:-basic}" in
        "full_autonomous")
            required_nodes=("/turtlebot3_core" "/darknet_ros" "/move_base" "/orchestrator")
            ;;
        "semi_autonomous")
            required_nodes=("/turtlebot3_core" "/darknet_ros" "/move_base")
            ;;
        "test_yolo")
            required_nodes=("/turtlebot3_core" "/darknet_ros")
            ;;
        "basic")
            required_nodes=("/turtlebot3_core")
            ;;
    esac
    
    local failed_nodes=()
    
    for node in "${required_nodes[@]}"; do
        if timeout 5 rosnode info "$node" >/dev/null 2>&1; then
            log_check "Node $node is running"
        else
            log_check "WARNING: Node $node not running"
            failed_nodes+=("$node")
        fi
    done
    
    # For nodes, we only warn but don't fail health check on Pi
    # as some nodes might restart during operation
    if [ ${#failed_nodes[@]} -gt 0 ]; then
        log_check "WARNING: ${#failed_nodes[@]} nodes not running"
    fi
    
    return 0
}

# Check Raspberry Pi specific hardware
check_pi_hardware() {
    if ! check_is_pi; then
        log_check "Not running on Pi, skipping hardware checks"
        return 0
    fi
    
    log_check "Checking Raspberry Pi hardware..."
    
    # Check CPU temperature
    if [ -f "/sys/class/thermal/thermal_zone0/temp" ]; then
        local temp=$(cat /sys/class/thermal/thermal_zone0/temp)
        local temp_c=$((temp / 1000))
        
        if [ "$temp_c" -gt "$MAX_CPU_TEMP" ]; then
            log_check "ERROR: CPU temperature too high: ${temp_c}°C (max: ${MAX_CPU_TEMP}°C)"
            return 1
        else
            log_check "CPU temperature OK: ${temp_c}°C"
        fi
    fi
    
    # Check camera
    if [ -e "/dev/video0" ]; then
        log_check "Camera device detected: /dev/video0"
    else
        log_check "WARNING: Camera device not found"
    fi
    
    # Check I2C devices (for sensors)
    if command -v i2cdetect >/dev/null 2>&1; then
        local i2c_devices=$(i2cdetect -y 1 2>/dev/null | grep -o '[0-9a-f][0-9a-f]' | wc -l)
        if [ "$i2c_devices" -gt 0 ]; then
            log_check "I2C devices detected: $i2c_devices"
        else
            log_check "WARNING: No I2C devices detected"
        fi
    fi
    
    return 0
}

# Check system resources (Pi-optimized)
check_system_resources() {
    log_check "Checking system resources..."
    
    # Check memory usage
    local mem_free=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    if [ "$mem_free" -lt "$MIN_FREE_MEM" ]; then
        log_check "ERROR: Low memory: ${mem_free}KB available (min: ${MIN_FREE_MEM}KB)"
        return 1
    else
        log_check "Memory OK: ${mem_free}KB available"
    fi
    
    # Check disk usage
    local disk_usage=$(df / | awk 'NR==2 {printf "%.0f", $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 90 ]; then
        log_check "ERROR: Disk usage critical: ${disk_usage}%"
        return 1
    elif [ "$disk_usage" -gt 80 ]; then
        log_check "WARNING: Disk usage high: ${disk_usage}%"
    else
        log_check "Disk usage OK: ${disk_usage}%"
    fi
    
    # Check CPU load
    local cpu_load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    local cpu_load_int=$(echo "$cpu_load * 100" | bc -l 2>/dev/null | cut -d. -f1)
    
    if [ -n "$cpu_load_int" ] && [ "$cpu_load_int" -gt 400 ]; then  # Load > 4.0 on Pi
        log_check "WARNING: High CPU load: $cpu_load"
    else
        log_check "CPU load OK: $cpu_load"
    fi
    
    return 0
}

# Check network connectivity
check_network() {
    log_check "Checking network connectivity..."
    
    # Check if we have an IP address
    local ip_addr=$(hostname -I | awk '{print $1}')
    if [ -n "$ip_addr" ]; then
        log_check "IP address: $ip_addr"
    else
        log_check "WARNING: No IP address assigned"
        return 1
    fi
    
    # Check if we can reach ROS master
    local ros_master_host=$(echo $ROS_MASTER_URI | cut -d: -f2 | sed 's|//||')
    if [ "$ros_master_host" != "localhost" ] && [ "$ros_master_host" != "127.0.0.1" ]; then
        if ping -c 1 -W 3 "$ros_master_host" >/dev/null 2>&1; then
            log_check "Can reach ROS master at $ros_master_host"
        else
            log_check "WARNING: Cannot reach ROS master at $ros_master_host"
        fi
    fi
    
    return 0
}

# Main health check
main() {
    log_check "Starting Raspberry Pi health check..."
    log_check "Mode: ${NAVY_MODE:-basic}"
    
    local checks_passed=0
    local total_checks=6
    
    # Run all health checks
    if check_ros_master; then
        ((checks_passed++))
    fi
    
    if check_ros_topics; then
        ((checks_passed++))
    fi
    
    if check_turtlebot_nodes; then
        ((checks_passed++))
    fi
    
    if check_pi_hardware; then
        ((checks_passed++))
    fi
    
    if check_system_resources; then
        ((checks_passed++))
    fi
    
    if check_network; then
        ((checks_passed++))
    fi
    
    # Determine overall health
    if [ $checks_passed -eq $total_checks ]; then
        log_check "Health check PASSED ($checks_passed/$total_checks)"
        exit 0
    elif [ $checks_passed -ge $((total_checks - 2)) ]; then
        log_check "Health check PASSED with warnings ($checks_passed/$total_checks)"
        exit 0
    else
        log_check "Health check FAILED ($checks_passed/$total_checks)"
        exit 1
    fi
}

# Set up ROS environment
if [ -f "/opt/ros/noetic/setup.bash" ]; then
    source /opt/ros/noetic/setup.bash
fi

if [ -f "/catkin_ws/devel/setup.bash" ]; then
    source /catkin_ws/devel/setup.bash
fi

# Run main health check
main "$@" 