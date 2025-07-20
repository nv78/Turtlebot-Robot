# Orchestrator

## Overview
The orchestrator package coordinates the execution and state management of the autonomous system's components:
- Exploration and mapping
- Patrol navigation
- Object detection
- Manipulation control

## System Architecture
The orchestrator implements a state machine that:
1. Monitors system state via ROS topics
2. Coordinates component activation/deactivation
3. Manages transitions between operational modes
4. Ensures proper sequencing of actions

## State Management
The system uses the `/state` topic for coordination:
- `explore_done`: Mapping completion
- `patrol`: Random navigation active
- `object_detected`: Target object found
- `approach_complete`: Navigation to target complete
- `manipulation_complete`: Object handling complete

## Usage
Launch the orchestrator node:
```bash
roslaunch orchestrator orch_sim.launch
```

## Dependencies
- ROS message generation
- Standard ROS messages
- Custom component messages

## Integration
The orchestrator interfaces with:
- Exploration system
- Navigation stack
- Object detection
- Manipulation control
- State monitoring

## Configuration
System behavior can be modified through:
- Launch file parameters
- State transition rules
- Component coordination settings
