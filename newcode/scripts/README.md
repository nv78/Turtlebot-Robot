# TurtleBot3 SLAM and Navigation Scripts

This collection of scripts provides comprehensive functionality for TurtleBot3 simulation, SLAM, navigation, and autonomous exploration through your VNC interface.

## Quick Start

### Method 1: Use the Menu System (Recommended)
```bash
cd /turtlebot_ws
./scripts/turtlebot_menu.sh
```

### Method 2: Run Individual Scripts
```bash
cd /turtlebot_ws/scripts
./01_launch_gazebo_world.sh  # Start simulation
./02_launch_slam_gmapping.sh # Start SLAM (in new terminal)
./04_teleop_control.sh       # Control robot (in new terminal)
./05_save_map.sh            # Save map when done
```

## Available Scripts

### 🌍 Simulation Environments
- **`01_launch_gazebo_world.sh`** - Basic Gazebo world with TurtleBot3
- **`07_launch_gazebo_house.sh`** - Complex house environment for advanced testing

### 🗺️ SLAM (Simultaneous Localization and Mapping)
- **`02_launch_slam_gmapping.sh`** - SLAM using gmapping algorithm
- **`03_launch_slam_cartographer.sh`** - SLAM using Google's Cartographer
- **`05_save_map.sh`** - Save the generated map to `/turtlebot_ws/maps/`

### 🧭 Navigation
- **`06_launch_navigation.sh`** - Navigate using pre-built maps
- **`04_teleop_control.sh`** - Manual keyboard control

### 🤖 Autonomous Behaviors
- **`08_autonomous_exploration.sh`** - Autonomous exploration for mapping

### 🎛️ Utilities
- **`turtlebot_menu.sh`** - Interactive menu system for all functionalities

## Typical Workflows

### 🗺️ Creating a Map with SLAM

1. **Start Simulation**
   ```bash
   ./01_launch_gazebo_world.sh
   ```

2. **Start SLAM** (in new terminal)
   ```bash
   ./02_launch_slam_gmapping.sh
   # OR
   ./03_launch_slam_cartographer.sh
   ```

3. **Control Robot** (in new terminal)
   ```bash
   ./04_teleop_control.sh
   ```
   - Use `w/x` for forward/backward
   - Use `a/d` for left/right rotation
   - Use `space/s` to stop

4. **Save Map** (when mapping is complete)
   ```bash
   ./05_save_map.sh
   ```

### 🧭 Navigation with Existing Map

1. **Start Simulation**
   ```bash
   ./01_launch_gazebo_world.sh
   ```

2. **Start Navigation** (in new terminal)
   ```bash
   ./06_launch_navigation.sh
   ```
   - Select a previously saved map
   - Use RViz's "2D Nav Goal" to set destinations

### 🤖 Autonomous Exploration

1. **Start Simulation**
   ```bash
   ./01_launch_gazebo_world.sh
   ```

2. **Start SLAM** (in new terminal)
   ```bash
   ./02_launch_slam_gmapping.sh
   ```

3. **Start Autonomous Exploration** (in new terminal)
   ```bash
   ./08_autonomous_exploration.sh
   ```

4. **Save Map** (when exploration is complete)
   ```bash
   ./05_save_map.sh
   ```

## Important Notes

### 🖥️ Display Configuration
- All scripts are configured for display `:3` (VNC display)
- TurtleBot3 model is set to `waffle_pi`

### 📁 File Locations
- **Maps**: Saved in `/turtlebot_ws/maps/`
- **Scripts**: Located in `/turtlebot_ws/scripts/`

### ⚡ Terminal Usage
- Run different components in separate terminal windows
- Use `Ctrl+C` to stop any running process
- Gazebo simulation must be running before starting SLAM or Navigation

### 🔧 Troubleshooting

**If RViz doesn't open:**
```bash
export DISPLAY=:3
```

**If scripts aren't executable:**
```bash
chmod +x scripts/*.sh
```

**To kill all ROS processes:**
```bash
pkill -f "roscore|gzserver|gzclient|rviz"
```

**Check ROS status:**
```bash
rosnode list
rostopic list
```

## Controls Reference

### Keyboard Teleop Controls
- **`w`** - Increase linear velocity (forward)
- **`x`** - Decrease linear velocity (backward)
- **`a`** - Increase angular velocity (turn left)
- **`d`** - Decrease angular velocity (turn right)
- **`space`** - Force stop
- **`s`** - Force stop
- **`Ctrl+C`** - Quit teleop

### RViz Navigation Tools
- **2D Pose Estimate** - Set robot's initial position
- **2D Nav Goal** - Set navigation target
- **Select** - Move around the view
- **Focus Camera** - Center view on robot

## Machine Learning Integration

Your Docker environment includes TensorFlow and PyTorch for ML experiments:
- **TensorFlow** - For deep learning applications
- **PyTorch** - Alternative deep learning framework
- **Jupyter** - For interactive development
- **OpenCV** - Computer vision processing

Access Jupyter notebooks:
```bash
jupyter notebook --ip=0.0.0.0 --port=8888 --allow-root
```

## Need Help?

Run the interactive menu system:
```bash
./scripts/turtlebot_menu.sh
```

Then press `h` for detailed help and workflow instructions. 