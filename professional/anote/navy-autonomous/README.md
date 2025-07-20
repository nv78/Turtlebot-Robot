# Navy Autonomous TurtleBot Workspace

This repository contains a complete autonomous TurtleBot system that can navigate, map buildings, detect objects using YOLO, and manipulate items autonomously.

## Features

- **Autonomous Mapping**: Explore and map unknown buildings
- **YOLO Object Detection**: Detect water bottles and trash cans using YOLO v3/v4
- **AR/April Tag Detection**: Dual tag detection system for precise localization
- **Autonomous Navigation**: Navigate to detected objects
- **Manipulation**: Pick up bottles and drop them in trash cans
- **Full Autonomy**: Complete orchestrated workflow from exploration to cleanup

## Video Demonstration

See the system in action:
- [YouTube Demo](https://youtu.be/wEwvhGS8GY8)
- [Additional Videos](https://drive.google.com/drive/folders/1VAmSW8Z5EUJZb4Y-RXb9zj3yCQSbMGp9)

## macOS Installation Guide

### Option 1: Native macOS Installation (Recommended)

#### Prerequisites
1. **macOS 10.15+** (Catalina or later)
2. **Homebrew** installed: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
3. **Xcode Command Line Tools**: `xcode-select --install`

#### Quick Start Installation
```bash
# Clone and setup
git clone <this-repo-url> navy-autonomous
cd navy-autonomous
./setup_macos.sh
```

#### Manual Installation Steps

1. **Install ROS Noetic via Homebrew**:
   ```bash
   # Add ROS tap
   brew tap ros/melodic
   brew tap osrf/simulation
   
   # Install ROS Noetic
   brew install ros-noetic-desktop-full
   
   # Install additional ROS packages
   brew install ros-noetic-turtlebot3-msgs
   brew install ros-noetic-navigation
   brew install ros-noetic-image-transport
   ```

2. **Install OpenCV and Dependencies**:
   ```bash
   # Core dependencies
   brew install opencv
   brew install boost
   brew install eigen
   brew install cmake
   brew install pkg-config
   
   # Python dependencies
   pip3 install opencv-python numpy scipy matplotlib
   ```

3. **Setup Catkin Workspace**:
   ```bash
   cd catkin_ws
   catkin_make -DCMAKE_BUILD_TYPE=Release
   source devel/setup.bash
   ```

### Option 2: Docker Installation (Alternative)

If you encounter issues with native installation, use Docker:

```bash
# Build and run the Docker container
./docker_setup.sh
```

### Option 3: UTM/Parallels Ubuntu VM

For complete compatibility, run Ubuntu in a VM:
1. Install UTM (Apple Silicon) or Parallels (Intel)
2. Install Ubuntu 20.04 LTS
3. Follow standard Ubuntu ROS installation

## YOLO Configuration for macOS

### CPU-Only YOLO (Default on macOS)
Since macOS doesn't support CUDA (Apple deprecated it), YOLO will run on CPU:

```bash
# The system automatically detects no CUDA and builds for CPU
# Performance: ~1.5 seconds per frame on modern Intel/M1 Macs
```

### Metal Performance Shaders (M1/M2 Macs)
For Apple Silicon Macs, we can leverage Metal:

```bash
# Install PyTorch with Metal support
pip3 install torch torchvision --index-url https://download.pytorch.org/whl/cpu
```

### Download YOLO Weights
```bash
cd catkin_ws/src/darknet_ros/darknet_ros/yolo_network_config/weights/

# Download pre-trained weights
wget http://pjreddie.com/media/files/yolov3.weights
wget http://pjreddie.com/media/files/yolov3-tiny.weights
wget http://pjreddie.com/media/files/yolov2.weights
wget http://pjreddie.com/media/files/yolov2-tiny.weights
```

## Quick Launch Options

### Basic Operation (Robot Control + Visualization)
```bash
source catkin_ws/devel/setup.bash
roslaunch turtlebot_complete.launch mode:=basic
```

### Autonomous Mapping
```bash
roslaunch turtlebot_complete.launch mode:=mapping
```

### Semi-Autonomous Trash Picking
```bash
roslaunch turtlebot_complete.launch mode:=semi_autonomous
```

### Fully Autonomous Operation
```bash
roslaunch turtlebot_complete.launch mode:=full_autonomous
```

### Test YOLO Detection
```bash
# Test YOLO with webcam
roslaunch darknet_ros darknet_ros.launch
```

## Repository Structure

```
navy-autonomous/
├── catkin_ws/                     # ROS catkin workspace
│   └── src/
│       ├── object_tracking/       # Object detection and tracking
│       ├── darknet_ros/          # YOLO object detection
│       ├── ar_track_alvar/       # AR tag detection
│       ├── apriltag_ros/         # April tag detection (alternative)
│       ├── bottle_manipulator/   # Manipulator control
│       ├── patrol/               # Random navigation
│       ├── orchestrator/         # System orchestration
│       ├── moveit/               # Motion planning
│       └── turtlebot-documentation/ # Original documentation
├── docker/                       # Docker configuration files
├── scripts/                      # Setup and utility scripts
├── navy-autonomous.rosinstall    # ROS package dependencies
├── setup_macos.sh               # macOS automated setup
├── docker_setup.sh              # Docker setup script
└── README.md                    # This file
```

## Included Packages

| Package | Description | Repository |
|---------|-------------|------------|
| **object_tracking** | Object detection and robot navigation | [Cornell-Tech-Turtlebot/object_tracking](https://github.com/Cornell-Tech-Turtlebot/object_tracking) |
| **darknet_ros** | YOLO object detection on ROS | [leggedrobotics/darknet_ros](https://github.com/leggedrobotics/darknet_ros) |
| **ar_track_alvar** | AR tag detection | [ros-perception/ar_track_alvar](https://github.com/ros-perception/ar_track_alvar) |
| **bottle_manipulator** | OpenManipulator control for bottle handling | [Cornell-Tech-Turtlebot/bottle_manipulator](https://github.com/Cornell-Tech-Turtlebot/bottle_manipulator) |
| **patrol** | Random navigation and patrolling | [Cornell-Tech-Turtlebot/patrol](https://github.com/Cornell-Tech-Turtlebot/patrol) |
| **orchestrator** | System state orchestration | [Cornell-Tech-Turtlebot/orchestrator](https://github.com/Cornell-Tech-Turtlebot/orchestrator) |
| **moveit** | Motion planning framework | [ros-planning/moveit](https://github.com/ros-planning/moveit) |
| **apriltag_ros** | April tag detection (alternative) | [AprilRobotics/apriltag_ros](https://github.com/AprilRobotics/apriltag_ros) |

## macOS-Specific Considerations

### Performance Optimization
- **M1/M2 Macs**: Leverage ARM64 optimization and Metal Performance Shaders
- **Intel Macs**: Use AVX2 optimizations in OpenCV and YOLO
- **CPU-only YOLO**: Expect 1-3 seconds per frame (vs. 0.02s on GPU)

### Common macOS Issues & Solutions

1. **Homebrew Permission Issues**:
   ```bash
   sudo chown -R $(whoami) /opt/homebrew
   ```

2. **ROS Master Connection**:
   ```bash
   export ROS_MASTER_URI=http://localhost:11311
   export ROS_IP=127.0.0.1
   ```

3. **OpenCV Version Conflicts**:
   ```bash
   pip3 uninstall opencv-python opencv-contrib-python
   pip3 install opencv-python==4.5.5.64
   ```

4. **Python Path Issues**:
   ```bash
   export PYTHONPATH="/opt/homebrew/lib/python3.9/site-packages:$PYTHONPATH"
   ```

### System Requirements

- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 10GB for full installation
- **CPU**: Intel i5 or Apple M1/M2 for decent YOLO performance
- **Network**: For robot communication and weight downloads

## YOLO Detection Classes

Based on COCO dataset, the system can detect:
- **person**, **bottle** (primary targets)
- **bicycle, car, motorbike, bus, truck**
- **chair, sofa, dining table, tv monitor**
- **cat, dog, bird, horse, sheep, cow**
- And 60+ additional object classes

## Physical Setup

### Required Equipment
- 1 water bottle
- 1 trash can with AR tag attached
- Printed AR tag: [MarkerData_0.png](https://github.com/Cornell-Tech-Turtlebot/object_tracking/blob/master/markers/MarkerData_0.png)

### AR Tag Configuration
1. Print the AR tag and attach to trash can
2. Measure the black square side length in centimeters
3. Update the marker size in: `catkin_ws/src/object_tracking/launch/ar_track_alvar.launch`

## Alternative Tag Detection

Switch to April tags for improved accuracy:
```bash
roslaunch turtlebot_complete.launch mode:=semi_autonomous use_apriltag:=true
```

## Development

### Building for Release (Performance)
```bash
cd catkin_ws
catkin_make -DCMAKE_BUILD_TYPE=Release -j$(sysctl -n hw.ncpu)
```

### Custom YOLO Models
1. Place weights in: `catkin_ws/src/darknet_ros/darknet_ros/yolo_network_config/weights/`
2. Place config in: `catkin_ws/src/darknet_ros/darknet_ros/yolo_network_config/cfg/`
3. Update ROS config in: `catkin_ws/src/darknet_ros/config/`

### Testing
```bash
# Test individual components
roslaunch darknet_ros darknet_ros.launch
rostopic echo /darknet_ros/bounding_boxes
```

## Troubleshooting

### Build Issues
```bash
# Clean and rebuild
cd catkin_ws
catkin_make clean
catkin_make -DCMAKE_BUILD_TYPE=Release
```

### Runtime Issues
```bash
# Check ROS environment
env | grep ROS

# Test basic ROS functionality
roscore &
rostopic list
```

## Contributing

This project was developed by the Cornell Tech TurtleBot team. macOS compatibility added for broader accessibility.

## License

See individual package repositories for licensing information.

## Original Documentation

For detailed setup instructions and technical details, see the original documentation in `catkin_ws/src/turtlebot-documentation/README.md`. 