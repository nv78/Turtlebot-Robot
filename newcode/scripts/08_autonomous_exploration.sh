#!/bin/bash

# TurtleBot3 Autonomous Exploration Script
# This script launches autonomous exploration for mapping unknown environments
# Requires explore_lite package or similar exploration package

echo "========================================="
echo "TurtleBot3 Autonomous Exploration"
echo "========================================="

# Source ROS environment
source /opt/ros/noetic/setup.bash
source /turtlebot_ws/devel/setup.bash

# Set TurtleBot3 model
export TURTLEBOT3_MODEL=waffle_pi

# Set display for GUI
export DISPLAY=:3

echo "TurtleBot3 Model: $TURTLEBOT3_MODEL"
echo "Display: $DISPLAY"
echo ""
echo "IMPORTANT: Make sure the following are running first:"
echo "  1. Gazebo simulation (./01_launch_gazebo_world.sh)"
echo "  2. SLAM (./02_launch_slam_gmapping.sh or ./03_launch_slam_cartographer.sh)"
echo ""
echo "This script will make the robot explore autonomously to build a map"
echo "Press CTRL+C to stop exploration"
echo ""

# Check if required nodes are running
if ! rosnode list | grep -q "/slam_gmapping\|/cartographer"; then
    echo "ERROR: No SLAM node detected!"
    echo "Please run SLAM first using:"
    echo "  ./02_launch_slam_gmapping.sh  OR"
    echo "  ./03_launch_slam_cartographer.sh"
    exit 1
fi

echo "Starting autonomous exploration..."

# Create a simple exploration node using Python
cat > /tmp/simple_explorer.py << 'EOF'
#!/usr/bin/env python3

import rospy
import random
import math
from geometry_msgs.msg import Twist
from sensor_msgs.msg import LaserScan
from nav_msgs.msg import OccupancyGrid

class SimpleExplorer:
    def __init__(self):
        rospy.init_node('simple_explorer', anonymous=True)
        
        # Publishers and subscribers
        self.cmd_vel_pub = rospy.Publisher('/cmd_vel', Twist, queue_size=1)
        self.laser_sub = rospy.Subscriber('/scan', LaserScan, self.laser_callback)
        self.map_sub = rospy.Subscriber('/map', OccupancyGrid, self.map_callback)
        
        # Robot state
        self.laser_data = None
        self.current_map = None
        self.twist = Twist()
        
        # Control parameters
        self.safe_distance = 0.8  # meters
        self.max_linear_speed = 0.2
        self.max_angular_speed = 1.0
        
        rospy.loginfo("Simple Explorer initialized")
        
    def laser_callback(self, data):
        self.laser_data = data
        
    def map_callback(self, data):
        self.current_map = data
        
    def get_min_distance(self):
        if self.laser_data is None:
            return float('inf')
        
        # Find minimum distance in front 60-degree cone
        ranges = self.laser_data.ranges
        start_idx = int(len(ranges) * 0.4)  # -60 degrees
        end_idx = int(len(ranges) * 0.6)    # +60 degrees
        
        front_ranges = ranges[start_idx:end_idx]
        valid_ranges = [r for r in front_ranges if not math.isinf(r) and not math.isnan(r)]
        
        return min(valid_ranges) if valid_ranges else float('inf')
        
    def explore(self):
        rate = rospy.Rate(10)  # 10 Hz
        
        while not rospy.is_shutdown():
            if self.laser_data is None:
                continue
                
            min_dist = self.get_min_distance()
            
            # Simple exploration behavior
            if min_dist < self.safe_distance:
                # Too close to obstacle, turn
                self.twist.linear.x = 0.0
                self.twist.angular.z = self.max_angular_speed * (1 if random.random() > 0.5 else -1)
                rospy.loginfo(f"Obstacle detected at {min_dist:.2f}m, turning")
            else:
                # Clear path, move forward with some randomness
                self.twist.linear.x = self.max_linear_speed
                # Add some random turning to explore more area
                self.twist.angular.z = (random.random() - 0.5) * 0.5
                
            self.cmd_vel_pub.publish(self.twist)
            rate.sleep()

if __name__ == '__main__':
    try:
        explorer = SimpleExplorer()
        explorer.explore()
    except rospy.ROSInterruptException:
        pass
EOF

# Make the exploration script executable
chmod +x /tmp/simple_explorer.py

# Run the exploration
python3 /tmp/simple_explorer.py

echo "Autonomous exploration ended." 