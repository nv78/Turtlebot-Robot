# FROM ubuntu:16.04

# ENV DEBIAN_FRONTEND=noninteractive
# ENV ROS_DISTRO=kinetic

# # Add ROS repository and keys
# RUN apt-get update && apt-get install -y curl gnupg2 lsb-release && \
#     sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list' && \
#     apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key \
#     C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654

# # Install ROS and build tools
# RUN apt-get update && apt-get install -y \
#     ros-kinetic-desktop-full \
#     ros-kinetic-multirobot-map-merge \
#     ros-kinetic-explore-lite \
#     python-catkin-tools \
#     python-wstool \
#     python-pip \
#     git \
#     wget \
#     build-essential \
#     && rm -rf /var/lib/apt/lists/*

# # Setup ROS environment
# RUN echo "source /opt/ros/$ROS_DISTRO/setup.bash" >> ~/.bashrc

# # Create catkin workspace
# RUN mkdir -p /catkin_ws/src
# WORKDIR /catkin_ws/src

# # Clone all required repos
# RUN git clone https://github.com/Cornell-Tech-Turtlebot/object_tracking.git && \
#     git clone --recursive https://github.com/leggedrobotics/darknet_ros.git && \
#     git clone https://github.com/ros-perception/ar_track_alvar.git && \
#     git clone https://github.com/Cornell-Tech-Turtlebot/bottle_manipulator.git && \
#     git clone https://github.com/Cornell-Tech-Turtlebot/patrol.git && \
#     git clone https://github.com/Cornell-Tech-Turtlebot/orchestrator.git
#     # && \
#     # git clone https://github.com/ros-planning/moveit.git

# # Remove existing system moveit (conflicts with source build)
# # RUN rm -rf /opt/ros/$ROS_DISTRO/lib/python2.7/dist-packages/moveit_commander*

# # Modify move_group.py (wait_for_servers = 50.0)
# # RUN sed -i 's/self\.wait_for_servers =.*/self.wait_for_servers = 50.0/' \
# #     moveit/moveit_commander/src/moveit_commander/move_group.py

# # Build workspace
# WORKDIR /catkin_ws
# RUN /bin/bash -c "source /opt/ros/$ROS_DISTRO/setup.bash && catkin build"

# # Configure default environment
# RUN echo "export TURTLEBOT3_MODEL=waffle_pi" >> ~/.bashrc && \
#     echo "export ROS_MASTER_URI=http://10.8.0.1:11311" >> ~/.bashrc && \
#     echo "export ROS_IP=10.8.0.1" >> ~/.bashrc && \
#     echo "export C_INCLUDE_PATH=/usr/include/python2.7" >> ~/.bashrc && \
#     echo "source /catkin_ws/devel/setup.bash" >> ~/.bashrc

# # Default shell
# CMD ["bash"]

# Use ARM-compatible ROS Kinetic base
FROM ros:kinetic-ros-base

ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=kinetic

# Install GUI + ROS tools + noVNC stack
RUN apt-get update && apt-get install -y \
    python-catkin-tools python-wstool python-pip \
    ros-kinetic-desktop-full \
    ros-kinetic-rviz \
    ros-kinetic-explore-lite \
    ros-kinetic-multirobot-map-merge \
    git wget curl supervisor net-tools \
    xfce4 xfce4-goodies x11vnc xvfb \
    novnc websockify firefox \
    && rm -rf /var/lib/apt/lists/*

# Setup ROS environment
RUN echo "source /opt/ros/$ROS_DISTRO/setup.bash" >> ~/.bashrc

# Create catkin workspace
RUN mkdir -p /catkin_ws/src
WORKDIR /catkin_ws/src

# Clone repos (optional)
RUN git clone https://github.com/Cornell-Tech-Turtlebot/object_tracking.git

WORKDIR /catkin_ws

# Build workspace
RUN /bin/bash -c "source /opt/ros/$ROS_DISTRO/setup.bash && catkin build"

# Setup VNC password (blank)
RUN mkdir -p ~/.vnc && x11vnc -storepasswd "" ~/.vnc/passwd

# Copy noVNC launch script
COPY start_vnc.sh /start_vnc.sh
RUN chmod +x /start_vnc.sh

EXPOSE 6080

CMD ["/start_vnc.sh"]
