# 1. Introduction

The Trash-picking Turtlebot system autonomously navigates around an unknown building, creates a map, detects and picks up water bottles, then deposits them into a trash can. System demonstration videos are available at:

https://youtu.be/wEwvhGS8GY8
https://drive.google.com/drive/folders/1VAmSW8Z5EUJZb4Y-RXb9zj3yCQSbMGp9

![Trash-picking Turltlebot](/images/trash-bot.png)

Required packages:
- Object tracking (https://github.com/Cornell-Tech-Turtlebot/object_tracking): Detects objects including water bottles and trash cans. Localizes object positions on the map. Navigates the robot toward detected objects.
- darknet_ros (https://github.com/leggedrobotics/darknet_ros): YOLO implementation for ROS. Detects various objects including water bottles.
- ar_track_alvar (http://wiki.ros.org/ar_track_alvar): Detects AR tags attached to trash cans.
- Bottle manipulator (https://github.com/Cornell-Tech-Turtlebot/bottle_manipulator): Controls the manipulator for bottle pickup and drop-off operations.
- explore_lite (http://wiki.ros.org/explore_lite): Provides autonomous exploration and mapping of unknown buildings.
- Patrol (https://github.com/Cornell-Tech-Turtlebot/patrol): Implements random patrolling of mapped buildings.
- Orchestrator (https://github.com/Cornell-Tech-Turtlebot/orchestrator): Coordinates package operations. Example: When object_tracking completes navigation to a bottle, orchestrator signals bottle_manipulator to initiate pickup.

Follow this guide to replicate the demonstrated functionality.

# 2. Setup

## 2.1 Laptop Configuration:
Configure ROS on the development laptop:
https://emanual.robotis.com/docs/en/platform/turtlebot3/setup/#setup
https://emanual.robotis.com/docs/en/platform/turtlebot3/manipulation/#manipulation

Configure VPN connectivity with robot and server: 
https://github.com/travers-rhodes/gazebo_tensorflow_turtlebot_docker#connection-instructions

## 2.2 Robot Configuration:
The robots have been pre-configured. SSH access credentials:

- Burger: `turtlebot`
- Waffle Pi: `admin`
- Waffle Pi with Open Manipulator: `turtlebot`

For new robot setup, follow these guides: 

- https://emanual.robotis.com/docs/en/platform/turtlebot3/setup/#setup
- https://emanual.robotis.com/docs/en/platform/turtlebot3/manipulation/#manipulation
- Camera calibration (required for tag detection): 
https://github.com/UbiquityRobotics/raspicam_node
http://wiki.ros.org/camera_calibration/Tutorials/MonocularCalibration

For new OpenManipulator servo configuration:
- https://github.com/Cornell-Tech-Turtlebot/DINAMIXEL_OPEN_MANIPULATOR_CONFIGURATION

## 2.3 Server Configuration:
The `/catkin_ws` workspace on the server is pre-configured. When creating new workspaces or virtual machines, backup the existing `/catkin_ws` folder to preserve critical configuration settings.

For new server setup:

- ROS server configuration:
        https://emanual.robotis.com/docs/en/platform/turtlebot3/setup/#setup
        https://emanual.robotis.com/docs/en/platform/turtlebot3/manipulation/#manipulation
        
- Package installation:

        cd /catkin_ws/src
        git clone https://github.com/Cornell-Tech-Turtlebot/object_tracking.git
        git clone --recursive https://github.com/leggedrobotics/darknet_ros.git
        git clone https://github.com/ros-perception/ar_track_alvar.git
        sudo apt install ros-${ROS_DISTRO}-multirobot-map-merge ros-${ROS_DISTRO}-explore-lite
        git clone https://github.com/Cornell-Tech-Turtlebot/bottle_manipulator.git
        git clone https://github.com/Cornell-Tech-Turtlebot/patrol.git
        git clone https://github.com/Cornell-Tech-Turtlebot/orchestrator

- MoveIt configuration:
               
        git clone https://github.com/ros-planning/moveit.git
                
  Modify the `wait_for_servers` parameter in move_group.py (catkin_ws/src/moveit/moveit_commander/src/moveit_commander) to `=50.0` or higher as needed.
        
  Remove the ROS Kinetic MoveIt package from `/opt/ros/kinetic/lib/python2.7/dist-packages/`

 - Workspace build:
 
        cd /catkin_ws
        catkin build
        source devel/setup.bash

   Alternative build command if catkin_build fails: `catkin_make_isolated` followed by `source devel_isolated/setup.bash`
   
 - Environment configuration (~/.bashrc):
 
        export TURTLEBOT3_MODEL=waffle_pi
        export ROS_MASTER_URI=http://10.8.0.1:11311
        export ROS_IP=10.8.0.1
        export C_INCLUDE_PATH=/usr/include/python2.7
        
   Execute: `source ~/.bashrc`
   
## 2.4 Physical Equipment:
Required: 1 water bottle and 1 trash can. Print and attach this AR tag to the trash can:
https://github.com/Cornell-Tech-Turtlebot/object_tracking/blob/master/markers/MarkerData_0.png

![Trashcan](/images/trash-can.png)
![Bottle](/images/bottle.png)

Measure the black square side length (cm) of the AR tag and update the configuration:

        cd /catkin_ws/src/object_tracking/launch/ar_track_alvar.launch
        
Modify the marker_size parameter:

        <arg name="marker_size" default="20" />

# 3. Basic Package Launch
## 3.1 Robot Initialization:
Execute in separate terminals:

        roslaunch turtlebot3_bringup turtlebot3_robot.launch
        roslaunch turtlebot3_bringup turtlebot3_rpicamera_2.launch    

## 3.2 Server Initialization:
Execute in separate terminals:
        
        rosrun image_transport republish compressed in:=/raspicam_node/image out:=/raspicam_node/image_raw
        rosrun tf static_transform_publisher 0 0 0 0 0 0 camera_rgb_optical_frame raspicam 100
        roslaunch object_tracking turtlebot3_slam.launch
        roslaunch turtlebot3_navigation move_base.launch
        roslaunch turtlebot3_teleop turtlebot3_teleop_key.launch 
        vglrun rviz

RViz Configuration:
1. Open RViz
2. Select File > Open Config
3. Navigate to `/catkin_ws/src/object_tracking/rviz/`
4. Load `object_tracking.rviz`

![Rviz](/images/rviz.png)

Robot Control Options:
1. Teleop control via the terminal running `turtlebot3_teleop_key.launch`
2. RViz navigation goals: http://wiki.ros.org/rviz/UserGuide#A2D_Nav_Goal_.28Keyboard_shortcut:_g.29

# 4. Autonomous Building Mapping
Server command:

        roslaunch explore_lite explore.launch

The system will autonomously explore and map unknown areas until complete coverage is achieved.

# 5. Semi-autonomous Operation
This mode requires initial teleoperation to locate the water bottle and trash can. Once detected, the system remembers object locations and can autonomously:
1. Navigate to the water bottle
2. Pick up the bottle
3. Navigate to the trash can
4. Deposit the bottle

## 5.1 Package Initialization:
Server commands (separate terminals):   

        roslaunch turtlebot3_manipulation_bringup turtlebot3_manipulation_bringup.launch
        roslaunch turtlebot3_manipulation_moveit_config move_group.launch
        rosrun bottle_manipulation execute_trajectory.py
        roslaunch object_tracking ar_track_alvar.launch
        roslaunch object_tracking darknet_ros.launch
        rosrun object_tracking detect_trashcan.py
        rosrun object_tracking find_trashcan.py
        rosrun object_tracking find_trash.py

## 5.2 Initial Navigation: 
Use teleoperation to position the robot for visual detection of the water bottle and trash can (with AR tag). The system will maintain object location memory.

## 5.3 Command Sequence: 
Publish commands to the `/state` topic:

Bottle approach:
        rostopic pub /state std_msgs/String approach_trash
        
Bottle pickup:
        rostopic pub /state std_msgs/String pickup_trash
        
Trash can approach:
        rostopic pub /state std_msgs/String approach_trashcan
        
Bottle deposit:
        rostopic pub /state std_msgs/String drop_trash

# 6. Fully Autonomous Operation
The orchestrator package coordinates all system operations through the `/state` topic. Communication flow:

1. explore_lite completion -> `explore_done` message
2. orchestrator initiates patrol -> `patrol` message
3. Detection system publishes `trashcan_detected` and `trash_detected`
4. Orchestrator sequences:
   - `approach_trash` -> `approach_trash_done`
   - `pickup_trash` -> `pickup_trash_done`
   - `approach_trashcan` -> `approach_trashcan_done`
   - `drop_trash`

Reference implementation: https://github.com/Cornell-Tech-Turtlebot/orchestrator/blob/master/src/orchestrator.py

Launch commands:
        roslaunch patrol random_nav.launch
        rosrun orchestrator orchestrator.py

# 7. System Improvements

## 7.1 Package Installation
Implement a comprehensive .rosinstall file for streamlined package installation.

## 7.2 Launch Configuration
Create a unified launch file to replace multiple terminal commands.

## 7.3 Orchestrator Enhancement
Complete testing and implementation of the orchestrator package.

## 7.4 Tag Detection Optimization
Current implementation uses ar_track_alvar with occasional position detection inaccuracies.

Alternative: AprilTag Detection
- Installation: https://github.com/AprilRobotics/apriltag_ros#quickstart
- Configuration:
  1. Modify detect_trashcan.py (line 24 comment, line 22 uncomment)
  2. Use tag #10 from apriltags1-20.pdf
  3. Update tags.yaml with measured tag dimensions
  4. Copy configuration files:
     - tags.yaml
     - settings.yaml
     to `/catkin_ws/src/apriltag_ros/config/`
  5. Replace ar_track_alvar.launch with apriltag_ros.launch
  6. Configure RViz for tag detection visualization








