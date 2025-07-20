# Navy Autonomous Robot - Deployment Guide

## Purpose
This document provides step-by-step deployment instructions for the Navy Autonomous TurtleBot system across development, staging, and production environments.

## Overview
The Navy Autonomous robot system supports multiple deployment configurations:

1. **Development**: Local Docker environment for development and testing
2. **Staging**: Pre-production validation environment
3. **Production**: Full production deployment with monitoring and logging
4. **Raspberry Pi**: Edge deployment for physical robot hardware

## Quick Reference

### Available Operation Modes
1. **Basic**: Manual control and SLAM functionality
2. **Mapping**: Autonomous exploration and environment mapping
3. **Semi-autonomous**: Manual setup followed by autonomous trash collection
4. **Full-autonomous**: Complete autonomous operation
5. **Test YOLO**: Object detection testing only

### Key System Requirements
- **Environment**: Well-lit space with clear pathways
- **Physical Setup**: Open environment for navigation testing
- **Network**: Stable WiFi or ethernet connectivity
- **Hardware**: TurtleBot3 Waffle Pi with OpenManipulator

## Deployment Procedures

### Phase 1: Environment Preparation

1. **Clone and Setup Workspace**
```bash
# Run the automated setup script
./scripts/setup_robot_workspace.sh

# Or manual setup:
cd catkin_ws/src
wstool init . ../../navy-autonomous.rosinstall
wstool update
cd ..
catkin build
source devel/setup.bash
```

2. **Verify Installation**
```bash
# Test basic functionality
roslaunch turtlebot_complete.launch mode:=test_yolo

# Check YOLO detection
rostopic echo /darknet_ros/bounding_boxes
```

### Phase 2: Physical Setup

1. **Print and Attach AR Tag**
```bash
# Download and print the AR tag
wget https://github.com/Cornell-Tech-Turtlebot/object_tracking/raw/master/markers/MarkerData_0.png

# Print at actual size and attach to trash can
# Measure the black square size in centimeters
```

2. **Configure AR Tag Size**
```bash
# Edit the marker size in the launch file
nano catkin_ws/src/object_tracking/launch/ar_track_alvar.launch
# Change: <arg name="marker_size" default="20" /> (use your measurement)
```

3. **Camera Calibration**
```bash
# Calibrate the Raspberry Pi camera for accurate detection
rosrun camera_calibration cameracalibrator.py --size 8x6 --square 0.108 image:=/raspicam_node/image camera:=/raspicam_node
```

### Phase 3: Testing and Validation

1. **Test Basic Operations**
```bash
# Start basic mode
roslaunch turtlebot_complete.launch mode:=basic

# Test teleoperation
# Use keyboard controls to move robot
```

2. **Test Object Detection**
```bash
# Start YOLO testing mode
roslaunch turtlebot_complete.launch mode:=test_yolo

# Place bottle in camera view
# Verify detection in /darknet_ros/bounding_boxes topic
```

3. **Test Mapping**
```bash
# Start mapping mode
roslaunch turtlebot_complete.launch mode:=mapping

# Robot will explore and create map automatically
# Save map when complete:
rosrun map_server map_saver -f my_map
```

### Phase 4: Semi-Autonomous Operation

1. **Launch Semi-Autonomous Mode**
```bash
roslaunch turtlebot_complete.launch mode:=semi_autonomous
```

2. **Initialize Object Detection**
```bash
# Drive robot to see bottle and trash can
# Objects will be remembered even when out of view

# Command robot to approach bottle:
rostopic pub /state std_msgs/String "approach_trash"

# Command robot to pickup bottle:
rostopic pub /state std_msgs/String "pickup_trash"

# Command robot to approach trash can:
rostopic pub /state std_msgs/String "approach_trashcan"

# Command robot to drop bottle:
rostopic pub /state std_msgs/String "drop_trash"
```

### Phase 5: Full Autonomous Operation

1. **Launch Full Autonomous Mode**
```bash
roslaunch turtlebot_complete.launch mode:=full_autonomous
```

2. **Monitor Operation**
```bash
# Monitor state transitions
rostopic echo /state

# Monitor robot position
rostopic echo /tf

# Monitor object detections
rostopic echo /darknet_ros/bounding_boxes
```

## Raspberry Pi Deployment

### Option 1: Direct Installation on Pi
```bash
# Copy workspace to Raspberry Pi
scp -r catkin_ws pi@ROBOT_IP:~/

# SSH into Pi and build workspace
ssh pi@ROBOT_IP
cd ~/catkin_ws
catkin build
source devel/setup.bash
```

### Option 2: Docker Deployment on Pi
```bash
# Build Pi-specific Docker image
docker build -f deployment/raspberry_pi/Dockerfile -t navy-autonomous-pi:latest .

# Run container on Pi
docker run -d \
  --name navy-autonomous \
  --privileged \
  --network host \
  --device /dev/video0 \
  -v /dev:/dev \
  navy-autonomous-pi:latest
```

### Option 3: Remote Operation
```bash
# On Pi: Start robot nodes
roslaunch turtlebot3_bringup turtlebot3_robot.launch
roslaunch turtlebot3_bringup turtlebot3_rpicamera.launch

# On server/laptop: Start processing nodes
export ROS_MASTER_URI=http://PI_IP:11311
export ROS_IP=SERVER_IP
roslaunch turtlebot_complete.launch mode:=semi_autonomous
```

## Production Deployment

### Container Registry Setup
```bash
# Tag and push images
docker tag navy-autonomous-pi:latest ghcr.io/your-org/navy-autonomous-pi:v1.0.0
docker push ghcr.io/your-org/navy-autonomous-pi:v1.0.0
```

### Kubernetes Deployment (for multiple robots)
```bash
# Deploy to cluster
kubectl apply -f k8s/navy-autonomous-deployment.yaml

# Scale for multiple robots
kubectl scale deployment navy-autonomous --replicas=3
```

### CI/CD Pipeline
```bash
# Trigger automatic deployment
git tag v1.0.0
git push origin v1.0.0

# Monitor deployment
./scripts/deployment/deploy.sh production v1.0.0
```

## Monitoring and Troubleshooting

### Health Monitoring
```bash
# Check system health
./deployment/raspberry_pi/healthcheck_pi.sh

# Monitor performance
htop
rostopic hz /darknet_ros/bounding_boxes
```

### Common Issues and Solutions

1. **YOLO Detection Slow**
```bash
# Reduce image resolution
# Switch to yolov3-tiny.weights
# Increase detection threshold
```

2. **Robot Not Moving**
```bash
# Check motor connections
# Verify battery level
# Check ROS network connectivity
rostopic list
rosnode list
```

3. **AR Tag Not Detected**
```bash
# Verify tag size configuration
# Check lighting conditions
# Calibrate camera
# Try AprilTag alternative
```

4. **Arm Not Moving**
```bash
# Check arm power
# Verify joint controllers
rostopic echo /joint_states
rosservice call /controller_manager/list_controllers
```

## Performance Optimization

### For Raspberry Pi
```bash
# Enable performance mode
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Increase GPU memory
sudo raspi-config
# Advanced Options > Memory Split > 128
```

### For Object Detection
```bash
# Use optimized YOLO config
# Reduce image processing frequency
# Implement region of interest filtering
```

### For Navigation
```bash
# Tune move_base parameters
# Optimize map resolution
# Adjust planning algorithms
```

## Deployment Checklist

### Pre-Deployment
- [ ] Hardware assembled and tested
- [ ] Workspace built and verified
- [ ] Camera calibrated
- [ ] AR tag printed and attached
- [ ] Network connectivity confirmed
- [ ] Power supply adequate

### Testing Phase
- [ ] Basic mode functional
- [ ] Object detection working
- [ ] Mapping successful
- [ ] Semi-autonomous mode tested
- [ ] All commands respond correctly

### Production Deployment
- [ ] Docker images built and pushed
- [ ] Configuration files updated
- [ ] Monitoring systems active
- [ ] Backup procedures in place
- [ ] Documentation updated

### Post-Deployment
- [ ] System performance monitored
- [ ] Error logs reviewed
- [ ] User training completed
- [ ] Maintenance schedule established

## Maintenance and Updates

### Regular Tasks
- **Daily**: Check system health and battery levels
- **Weekly**: Review performance metrics and logs
- **Monthly**: Update software packages and security patches
- **Quarterly**: Full system calibration and testing

### Update Procedures
```bash
# Update workspace
cd catkin_ws/src
wstool update
cd ..
catkin build

# Update Docker images
docker pull ghcr.io/your-org/navy-autonomous-pi:latest
docker system prune -f

# Deploy updates
./scripts/deployment/deploy.sh production latest
```

## Support and Documentation

### Log Files
- **ROS logs**: `~/.ros/log/`
- **System logs**: `/var/log/syslog`
- **Application logs**: `/var/log/navy-autonomous/`

### Debugging Commands
```bash
# ROS debugging
roswtf
rostopic list
rosnode list
rqt_graph

# System debugging
dmesg
journalctl -u navy-autonomous
```

### Performance Monitoring
```bash
# Monitor topics
rostopic hz /darknet_ros/bounding_boxes
rostopic bw /camera/image_raw

# System resources
htop
iotop
vcgencmd measure_temp  # Pi temperature
```

The system is now ready for deployment. Follow this guide step-by-step to achieve full autonomous trash-picking functionality. 