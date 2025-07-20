# Raspberry Pi ARM64 optimized Dockerfile for Navy Autonomous TurtleBot
FROM ros:noetic-ros-base

# Install system dependencies for Raspberry Pi
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-catkin-tools \
    python3-rosdep \
    python3-rosinstall \
    python3-wstool \
    wget \
    curl \
    git \
    build-essential \
    cmake \
    pkg-config \
    libopencv-dev \
    python3-opencv \
    libeigen3-dev \
    libgtest-dev \
    libyaml-cpp-dev \
    && rm -rf /var/lib/apt/lists/*

# Install TurtleBot3 and manipulation packages
RUN apt-get update && apt-get install -y \
    ros-noetic-turtlebot3 \
    ros-noetic-turtlebot3-msgs \
    ros-noetic-turtlebot3-bringup \
    ros-noetic-turtlebot3-description \
    ros-noetic-turtlebot3-navigation \
    ros-noetic-turtlebot3-teleop \
    ros-noetic-open-manipulator-msgs \
    ros-noetic-open-manipulator-libs \
    ros-noetic-turtlebot3-manipulation \
    ros-noetic-turtlebot3-manipulation-bringup \
    ros-noetic-turtlebot3-manipulation-moveit-config \
    ros-noetic-multirobot-map-merge \
    ros-noetic-explore-lite \
    ros-noetic-image-transport \
    ros-noetic-cv-bridge \
    ros-noetic-vision-opencv \
    ros-noetic-camera-calibration \
    && rm -rf /var/lib/apt/lists/*

# Install Raspberry Pi camera support
RUN apt-get update && apt-get install -y \
    libraspberrypi-bin \
    libraspberrypi-dev \
    raspberrypi-kernel-headers \
    && rm -rf /var/lib/apt/lists/*

# Create catkin workspace
WORKDIR /catkin_ws
COPY catkin_ws/src ./src
COPY navy-autonomous.rosinstall ./
COPY requirements.txt /tmp/

# Install Python dependencies
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt

# Initialize rosdep and install package dependencies
RUN rosdep init || true && rosdep update
RUN rosdep install --from-paths src --ignore-src -r -y

# Build the workspace with ARM optimizations
RUN /bin/bash -c "source /opt/ros/noetic/setup.bash && \
    catkin config --init && \
    catkin config --extend /opt/ros/noetic && \
    catkin config --cmake-args -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS='-mcpu=cortex-a72' && \
    catkin build"

# Download YOLO weights (lightweight for Pi)
RUN cd src/darknet_ros/darknet_ros/yolo_network_config/weights && \
    wget -q http://pjreddie.com/media/files/yolov3-tiny.weights || true

# Set up environment variables for TurtleBot3
ENV TURTLEBOT3_MODEL=waffle_pi
ENV ROS_PYTHON_VERSION=3
ENV ROS_DISTRO=noetic
ENV C_INCLUDE_PATH=/usr/include/python3.8

# Create non-root user for security
RUN groupadd -r turtlebot && useradd -r -g turtlebot turtlebot
RUN chown -R turtlebot:turtlebot /catkin_ws

# Copy entry and health check scripts
COPY deployment/raspberry_pi/entrypoint_pi.sh /entrypoint.sh
COPY deployment/raspberry_pi/healthcheck_pi.sh /healthcheck.sh
RUN chmod +x /entrypoint.sh /healthcheck.sh

# Switch to non-root user
USER turtlebot
WORKDIR /catkin_ws

# Set up ROS environment
RUN echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc && \
    echo "source /catkin_ws/devel/setup.bash" >> ~/.bashrc

# Health check optimized for Pi
HEALTHCHECK --interval=60s --timeout=30s --start-period=120s --retries=3 \
    CMD /healthcheck.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["roslaunch", "turtlebot_complete.launch", "mode:=basic"] 