# Patrol

A package that contains nodes for various automated patrol algorithms on a robot running ROS. The implementation is designed for the Turtlebot3 and can be adapted to other robots with LIDAR scanning capabilities running ROS.

[Autonomous Patrol Video](http://img.youtube.com/vi/lCQRPiYSwbE/0.jpg)](https://www.youtube.com/watch?v=lCQRPiYSwbE)

## Nodes

### FixedTurn

![FixedTurn Patrol](https://github.com/Cornell-Tech-Turtlebot/patrol/blob/master/images/fixedturn.gif)

*(20x Speed)*

```fixed_turn``` is a rospy node that implements a deterministic patrol algorithm. The robot moves in a straight line until the LIDAR detects an obstacle within a specified threshold. The robot then stops and turns clockwise until the forward path is clear, then continues moving in a straight line.

### Bounce

![Bounce Patrol](https://github.com/Cornell-Tech-Turtlebot/patrol/blob/master/images/bounce.gif)

*(20x Speed)*

```bounce``` is a rospy node that implements a random sampling patrol algorithm. The robot moves in a straight line until the LIDAR detects an obstacle within a specified threshold. The robot then stops, samples a new random angle, rotates to that angle, and continues moving in a straight line.

### RandomNav

![RandomNav Patrol](https://github.com/Cornell-Tech-Turtlebot/patrol/blob/master/images/randomnav.gif)

*(20x Speed)*

```random_nav``` is a rospy node that implements a stratified rejection sampling patrol algorithm using the move_base and actionlib packages. Given an occupancy grid map of the environment, the algorithm:
1. Divides the map into 4 quadrants
2. Randomly samples a cell from each quadrant
3. Rejects occupied cells and samples new points until free cells are found
4. Transforms free cell coordinates to the world coordinate frame
5. Sends coordinates as navigation goals to move_base
6. Repeats the process after all 4 goals are visited

## Implementation

Clone this repository to the ```src``` directory in the workspace and build.

### Requirements

```fixed_turn```:
- LaserScan message on topic ```/scan```
- Twist message support on topic ```/cmd_vel```

```bounce```:
- LaserScan message on topic ```/scan```
- Odometry message on topic ```/odom```
- Twist message support on topic ```/cmd_vel```

```random_nav```:
- OccupancyGrid message on topic ```/map```
- ```move_base``` for navigation goals
- ```turtlebot3_navigation``` package for map publishing and move_base initialization
- Pre-generated SLAM map (dynamic maps not currently supported)

### Usage

Launch turtlebot3_navigation with a map file:
```bash
roslaunch turtlebot3_navigation turtlebot3_navigation.launch map_file:=$MAP
```
where ```$MAP``` specifies the environment map file.
