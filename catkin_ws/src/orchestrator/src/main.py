#!/usr/bin/env python
"""
Navy Autonomous Robot - Main Orchestrator
Finite State Machine for coordinating autonomous trash collection operations

This module manages the high-level state transitions for the robot's autonomous
behavior, including exploration, trash detection, and collection phases.
"""

import rospy
import roslaunch
import os
from std_msgs.msg import String 

# Configuration constants
DEFAULT_WORKSPACE_PATH = '/catkin_ws'
WORKSPACE_PATH = os.environ.get('CATKIN_WS', DEFAULT_WORKSPACE_PATH)

# Global state variables for inter-callback communication
EXPLORING_COMPLETED = False
TRASHCAN_DETECTED = False


def exploring_callback(data):
    """
    Callback function for exploration completion status
    
    Args:
        data (String): Status message from exploration node
    """
    rospy.loginfo('Exploration callback received: %s', data.data)
    if data.data == 'completed':
        rospy.loginfo('Exploration phase completed')
        global EXPLORING_COMPLETED
        EXPLORING_COMPLETED = True


def trashcan_callback(data):
    """
    Callback function for trash can detection
    
    Args:
        data (std_msgs/Int32 or String): Detection status from vision system
    """
    # Handle both integer and boolean detection signals
    detection_value = data.data
    if isinstance(detection_value, str):
        detection_value = detection_value.lower() in ['true', '1', 'detected']
    elif isinstance(detection_value, int):
        detection_value = bool(detection_value)
    
    if detection_value:
        rospy.loginfo('Trash can detected')
        global TRASHCAN_DETECTED
        TRASHCAN_DETECTED = True


class FiniteStateMachine:
    """
    Finite State Machine for autonomous robot operation
    
    States:
    0 - Initialization
    1 - Exploration/Mapping
    2 - Trash Detection
    3 - Navigation to Trash
    4 - Manipulation/Collection
    5 - Return to Base
    """

    def __init__(self):
        """Initialize the state machine with default state"""
        self.state = 0
        self.num_states = 6
        self.switcher = {
            0: 'exploring',
            1: 'patrolling',
            2: 'approach_trash',
            3: 'pickup_trash',
            4: 'approach_trashcan',
            5: 'dumping_trash'
        }
        
    def get_state(self):
        s = self.switcher.get(self.state, 'Invalid State')
        return String(s)

    def next(self):

        # Explore only once, then go to patrolling
        if self.state == 0:
            
            print('STATE0 ------------------------------------------------')

            # Move to Patrolling 
            if EXPLORING_COMPLETED:

                print('DONE EXPLORING--------- ------------------------------------------------')

                # Launch navigation
                path = WORKSPACE_PATH + '/src/turtlebot3_navigation/launch/turtlebot3_navigation_orch.launch'
                uuid = roslaunch.rlutil.get_or_generate_uuid(None, False)
                roslaunch.configure_logging(uuid)
                launch = roslaunch.parent.ROSLaunchParent(uuid, [path]) 
                launch.start()
                rospy.loginfo('navigation launched')

                # Launch patrol navigation
                package = 'patrol'
                 executable = 'random_nav_orch.py'
                 node = roslaunch.core.Node(package, executable)
                 launch = roslaunch.scriptapi.ROSLaunch()
                 launch.start()
                 process = launch.launch(node)
                 # Note: Process lifecycle managed by ROS launch system

                # Increment state
                self.state += 1

        # Patrolling
        elif self.state == 1:

            # THIS IS ALL DONE IN orch LAUNCH FILE	
            # Launch apriltag
            # roslaunch apriltag_ros continuous_detection.launch
            # Run trashcan tracking
            # rosrun object_tracking detect_trashcan.py
            # rosrun object_tracking find_trashcan.py

                         # Start looking for water bottle
             if TRASHCAN_DETECTED:	
                 rospy.loginfo('Trash can detected, initiating trash detection phase')
                 # Launch trash detection system
                 # Future implementation: Launch find_trash.py and darknet_ros
                 # roslaunch darknet_ros darknet_ros.launch
                 # rosrun object_tracking find_trash.py

            # Switch to approaching trash
            # if trashcan_detected and /trash_detected: True:
                # switch to state2=approaching_trash

        # Approach trash
        elif self.state == 2:
            pass			
            # subscribe /trash_approached: True
                # switch to state3=pickup_trash

        # Pickup trash
        elif self.state == 3:
            pass			
            # subscribe /trash_picked_up: True 
                # switch to state4=approaching_trashcan

        # Approaching trashcan
        elif self.state == 4:
            pass			
            # subscribe /trashcan_approached: True
                # switch to state5=dumping_trash

        # Dumping trash
        else:
            pass			
            # subscribe /trash_dumped: True
                # switch to state1=patrolling	
        

        ## Go to next state 
        #elif self.state + 1 < self.num_states:
        #	self.state += 1 

        ## Restart the cycle excluding exploring, go from dumping to patrolling
        #else:
        #	self.state = 1



def orchestrator():

    # Initialize subscribers
    rospy.Subscriber('exploring_completed', String, exploring_callback)

    # Initialize publisher
    rospy.init_node('orch_node')
    pub = rospy.Publisher('state', String, queue_size=10)
    r = rospy.Rate(0.2) # 5hz
    

    # Initialize finite state machine
    fsm = FiniteStateMachine()

    # Loop infinitely
    while not rospy.is_shutdown():

        # Publish state
        pub.publish(fsm.get_state())

        # Update state
        fsm.next()

        # Publish at specified rate
        r.sleep()


if __name__ == '__main__':
    orchestrator()
