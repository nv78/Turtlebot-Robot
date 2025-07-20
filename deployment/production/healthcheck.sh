#!/bin/bash

# Navy Autonomous Health Check Script
# Returns 0 (healthy) or 1 (unhealthy)

set -e

# Configuration
MAX_RESPONSE_TIME=10
REQUIRED_TOPICS=(
    "/camera/image_raw"
    "/darknet_ros/bounding_boxes"
    "/move_base/goal"
    "/tf"
)

OPTIONAL_TOPICS=(
    "/darknet_ros/detection_image"
    "/move_base/result"
    "/state"
)

log_check() {
    echo "[HEALTH] $(date '+%Y-%m-%d %H:%M:%S') $1"
}

# Check if ROS master is responding
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

# Check critical ROS topics
check_ros_topics() {
    log_check "Checking required ROS topics..."
    
    local failed_topics=()
    
    for topic in "${REQUIRED_TOPICS[@]}"; do
        if timeout 5 rostopic echo "$topic" -n 1 >/dev/null 2>&1; then
            log_check "Topic $topic is publishing"
        else
            log_check "ERROR: Topic $topic not publishing"
            failed_topics+=("$topic")
        fi
    done
    
    if [ ${#failed_topics[@]} -eq 0 ]; then
        log_check "All required topics are healthy"
        return 0
    else
        log_check "ERROR: ${#failed_topics[@]} required topics failed"
        return 1
    fi
}

# Check critical ROS nodes
check_ros_nodes() {
    log_check "Checking critical ROS nodes..."
    
    local required_nodes=()
    case "${NAVY_MODE:-semi_autonomous}" in
        "full_autonomous")
            required_nodes=("/darknet_ros" "/move_base" "/orchestrator" "/rosout")
            ;;
        "semi_autonomous")
            required_nodes=("/darknet_ros" "/move_base" "/rosout")
            ;;
        "test_yolo")
            required_nodes=("/darknet_ros" "/rosout")
            ;;
        *)
            required_nodes=("/rosout")
            ;;
    esac
    
    local failed_nodes=()
    
    for node in "${required_nodes[@]}"; do
        if rosnode info "$node" >/dev/null 2>&1; then
            log_check "Node $node is running"
        else
            log_check "WARNING: Node $node not running"
            failed_nodes+=("$node")
        fi
    done
    
    # For nodes, we only warn but don't fail health check
    # as some nodes might restart during operation
    if [ ${#failed_nodes[@]} -gt 0 ]; then
        log_check "WARNING: ${#failed_nodes[@]} nodes not running"
    fi
    
    return 0
}

# Check system resources
check_system_resources() {
    log_check "Checking system resources..."
    
    # Check memory usage (fail if >90%)
    local mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    if [ "$mem_usage" -gt 90 ]; then
        log_check "ERROR: Memory usage too high: ${mem_usage}%"
        return 1
    else
        log_check "Memory usage OK: ${mem_usage}%"
    fi
    
    # Check disk usage (warn if >80%)
    local disk_usage=$(df / | awk 'NR==2 {printf "%.0f", $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 80 ]; then
        log_check "WARNING: Disk usage high: ${disk_usage}%"
    else
        log_check "Disk usage OK: ${disk_usage}%"
    fi
    
    return 0
}

# Check YOLO model availability
check_yolo_weights() {
    log_check "Checking YOLO weights..."
    
    local weights_dir="/catkin_ws/src/darknet_ros/darknet_ros/yolo_network_config/weights"
    local required_weights=("yolov3-tiny.weights")
    
    for weight in "${required_weights[@]}"; do
        if [ -f "$weights_dir/$weight" ]; then
            local size=$(stat -c%s "$weights_dir/$weight" 2>/dev/null || echo "0")
            if [ "$size" -gt 1000000 ]; then  # > 1MB
                log_check "YOLO weight $weight available (${size} bytes)"
            else
                log_check "ERROR: YOLO weight $weight too small or corrupted"
                return 1
            fi
        else
            log_check "ERROR: YOLO weight $weight not found"
            return 1
        fi
    done
    
    return 0
}

# Main health check
main() {
    log_check "Starting health check..."
    log_check "Mode: ${NAVY_MODE:-semi_autonomous}"
    
    local checks_passed=0
    local total_checks=5
    
    # Run all health checks
    if check_ros_master; then
        ((checks_passed++))
    fi
    
    if check_ros_topics; then
        ((checks_passed++))
    fi
    
    if check_ros_nodes; then
        ((checks_passed++))
    fi
    
    if check_system_resources; then
        ((checks_passed++))
    fi
    
    if check_yolo_weights; then
        ((checks_passed++))
    fi
    
    # Determine overall health
    if [ $checks_passed -eq $total_checks ]; then
        log_check "Health check PASSED ($checks_passed/$total_checks)"
        exit 0
    elif [ $checks_passed -ge $((total_checks - 1)) ]; then
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