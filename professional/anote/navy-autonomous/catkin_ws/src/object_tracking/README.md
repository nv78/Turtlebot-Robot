# Object Tracking

## Overview
The object tracking package provides object detection, localization, and robot navigation capabilities. The system:
- Detects objects using computer vision
- Localizes detected objects in the map
- Navigates the robot to target objects

## Features
- YOLO-based object detection
- AR tag recognition
- Position estimation
- Navigation planning
- Robot control

## Dependencies
- ROS Noetic
- OpenCV
- YOLO darknet_ros
- AR tag detection
- Navigation stack

## Installation
1. Clone the repository to the catkin workspace
2. Make scripts executable:
```bash
chmod -R a+x scripts/
```
3. Build the workspace:
```bash
catkin_make
```

## Usage
Launch the object tracking system:
```bash
roslaunch object_tracking darknet_ros.launch
roslaunch object_tracking ar_track_alvar.launch
```

## Configuration
- YOLO configuration: `config/yolo.yaml`
- AR tag parameters: `config/ar_track_alvar.launch`
- Navigation settings: `config/move_base.yaml`

## Topics
### Subscribed
- `/camera/image_raw`: Camera input
- `/scan`: LIDAR data
- `/odom`: Robot odometry

### Published
- `/detected_objects`: Object detections
- `/object_positions`: Map positions
- `/cmd_vel`: Robot commands

## Parameters
- Detection thresholds
- Navigation parameters
- Camera calibration
- Tag configurations

    
