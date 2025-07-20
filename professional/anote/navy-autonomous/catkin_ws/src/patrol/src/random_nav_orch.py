#! /usr/bin/env python

"""
Random Navigation Node

Implements random patrol behavior by sending randomly sampled navigation goals to move_base.
This version integrates with the orchestrator package for state-based control of patrol behavior.

The node:
1. Subscribes to occupancy grid map
2. Samples safe navigation points from each quadrant
3. Sends goals sequentially to move_base
4. Monitors system state for patrol activation/deactivation
"""

import rospy
from nav_msgs.msg import OccupancyGrid
from geometry_msgs.msg import Twist
import actionlib
from move_base_msgs.msg import MoveBaseAction, MoveBaseGoal
import numpy as np
from std_msgs.msg import String

class Nav():
    """
    Navigation controller implementing random patrol behavior.
    Handles map processing, goal sampling, and move_base interaction.
    """

    def __init__(self):
        """Initialize node, subscribers, and navigation parameters."""
        self.is_current_state = True

        # Map parameters
        self.height = 0
        self.width = 0
        self.origin = (0,0)
        self.resolution = 0
        self.occ_grid = np.array([])

        # Navigation parameters
        self.buffer = 10
        self.goal_list = []
        
        rospy.init_node('random_nav', anonymous=True)
        rospy.loginfo("Initializing Random Navigation Node")

        # Subscribe to map and state topics
        rospy.Subscriber("/map", OccupancyGrid, self.get_map)
        rospy.Subscriber("/state", String, self.get_state)
        rospy.on_shutdown(self.stopOnShutdown)

    def get_state(self, msg):
        """Process state updates from orchestrator."""
        rospy.logdebug("State update received: %s", msg.data)
        self.is_current_state = (msg.data == 'patrolling')

    def check_goal(self, x_start, x_end, y_start, y_end, grid):
        """
        Generate and validate random navigation goals.
        
        Args:
            x_start, x_end: X coordinate bounds
            y_start, y_end: Y coordinate bounds
            grid: Occupancy grid for collision checking
            
        Returns:
            tuple: Safe goal coordinates (x, y)
        """
        while True:
            goal = (np.random.randint(x_start, x_end),
                   np.random.randint(y_start, y_end))
            
            # Check goal and surrounding area for safety
            safe = (grid[goal[0], goal[1]] == 0) and \
                  (grid[goal[0]+self.buffer, goal[1]] == 0) and \
                  (grid[goal[0], goal[1]+self.buffer] == 0) and \
                  (grid[goal[0]+self.buffer, goal[1]+self.buffer] == 0) and \
                  (grid[goal[0]-self.buffer, goal[1]] == 0) and \
                  (grid[goal[0], goal[1]-self.buffer] == 0) and \
                  (grid[goal[0]-self.buffer, goal[1]-self.buffer] == 0)
                  
            if safe:
                return goal

    def get_map(self, msg):
        """Process incoming occupancy grid map."""
        rospy.loginfo("Processing map data")
        self.height = msg.info.height
        self.width = msg.info.width
        self.origin = (msg.info.origin.position.x, msg.info.origin.position.y)
        self.resolution = msg.info.resolution
        self.occ_grid = np.array(msg.data).reshape(self.height, self.width).T
        rospy.loginfo("Map processing complete")

    def send_goals(self):
        """Main loop for goal generation and navigation."""
        while not rospy.is_shutdown():
            if not self.goal_list and (self.occ_grid.size > 0):
                rospy.loginfo("Generating new navigation goals")
                # Sample goals from each quadrant
                q1_goal = self.check_goal(0, self.width//2, 0, self.height//2, self.occ_grid)
                q2_goal = self.check_goal(self.width//2, self.width, 0, self.height//2, self.occ_grid)
                q3_goal = self.check_goal(0, self.width//2, self.height//2, self.height, self.occ_grid)
                q4_goal = self.check_goal(self.width//2, self.width, self.height//2, self.height, self.occ_grid)
                self.goal_list = [q1_goal, q2_goal, q3_goal, q4_goal]
            
            while self.goal_list:
                if self.is_current_state:
                    rospy.loginfo("Remaining goals: %d", len(self.goal_list))
                    goal = self.goal_list.pop()
                    rospy.loginfo("Sending navigation goal")
                    self.movebase_client(goal[0], goal[1], self.origin, self.resolution)

    def movebase_client(self, goal_x, goal_y, origin, resolution):
        """
        Send navigation goals to move_base action server.
        
        Args:
            goal_x, goal_y: Goal coordinates in grid cells
            origin: Map origin coordinates
            resolution: Map resolution (meters/cell)
        """
        client = actionlib.SimpleActionClient('move_base', MoveBaseAction)
        client.wait_for_server()

        goal = MoveBaseGoal()
        goal.target_pose.header.frame_id = "map"
        goal.target_pose.header.stamp = rospy.Time.now()
        goal.target_pose.pose.position.x = origin[0] + ((goal_x+0.5) * resolution)
        goal.target_pose.pose.position.y = origin[1] + ((goal_y+0.5) * resolution)
        goal.target_pose.pose.orientation.w = 1.0

        client.send_goal(goal)
        wait = client.wait_for_result()
        if not wait:
            rospy.logerr("Move base action server not available")
            rospy.signal_shutdown("Move base action server not available")
        else:
            rospy.loginfo("Navigation goal completed")
            return client.get_result()

    def stopOnShutdown(self):
        """Handle clean shutdown by stopping robot motion."""
        rospy.loginfo("Stopping navigation node")
        twist = Twist()
        pub = rospy.Publisher('/cmd_vel', Twist, queue_size=1)
        twist.linear.x = 0
        twist.angular.x = 0
        pub.publish(twist)

if __name__ == "__main__":
    patrol = Nav()
    patrol.send_goals()

