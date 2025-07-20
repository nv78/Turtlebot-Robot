# Bottle Manipulator

## Overview
The bottle manipulator package provides control and coordination of the OpenManipulator robotic arm for automated bottle handling operations. The system enables precise grasping and placement of bottles in the autonomous waste collection system.

## Features
- Motion planning using MoveIt
- Grasp pose generation
- Trajectory execution
- State monitoring
- Error handling

## Dependencies
- ROS Noetic
- MoveIt
- OpenManipulator packages
- TurtleBot3 manipulation packages
- Custom messages

## Installation
1. Install system dependencies:
```bash
sudo apt install ros-noetic-moveit
sudo apt install ros-noetic-open-manipulator
```

2. Build the workspace:
```bash
catkin_make
source devel/setup.bash
```

## Usage
Launch the manipulation system:
```bash
roslaunch bottle_manipulator manipulation_bringup.launch
rosrun bottle_manipulator execute_trajectory.py
```

## System Architecture
The package implements:
- Motion planning interface
- Grasp pose calculation
- Trajectory execution
- State machine for manipulation sequences
- Error recovery

## Topics
### Subscribed
- `/joint_states`: Manipulator state
- `/object_pose`: Target object position
- `/state`: System state commands

### Published
- `/move_group/goal`: Motion planning goals
- `/gripper_command`: Gripper control
- `/manipulation_status`: Operation status

## Services
- `/plan_motion`: Generate motion plan
- `/execute_grasp`: Execute grasping sequence
- `/reset_arm`: Return to home position

## Parameters
- Joint limits
- Planning parameters
- Grasp configurations
- Safety thresholds

## Configuration
System behavior can be modified through:
- MoveIt configuration files
- Launch file parameters
- Planning scene configuration
- Controller settings
