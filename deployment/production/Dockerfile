# Multi-stage build for production deployment
FROM ros:noetic-ros-base AS base

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-catkin-tools \
    python3-rosdep \
    wget \
    curl \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install ROS packages
RUN apt-get update && apt-get install -y \
    ros-noetic-navigation \
    ros-noetic-image-transport \
    ros-noetic-cv-bridge \
    ros-noetic-vision-opencv \
    && rm -rf /var/lib/apt/lists/*

FROM base AS builder

# Copy source code
WORKDIR /catkin_ws
COPY catkin_ws/src ./src
COPY requirements.txt /tmp/

# Install Python dependencies
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt

# Initialize rosdep
RUN rosdep init || true && rosdep update

# Install package dependencies
RUN rosdep install --from-paths src --ignore-src -r -y

# Build the workspace
RUN /bin/bash -c "source /opt/ros/noetic/setup.bash && catkin build --cmake-args -DCMAKE_BUILD_TYPE=Release"

# Download YOLO weights
RUN cd src/darknet_ros/darknet_ros/yolo_network_config/weights && \
    wget -q http://pjreddie.com/media/files/yolov3-tiny.weights && \
    wget -q http://pjreddie.com/media/files/yolov2-tiny.weights

FROM base AS production

# Create non-root user for security
RUN groupadd -r navy && useradd -r -g navy navy

# Copy built workspace from builder stage
COPY --from=builder --chown=navy:navy /catkin_ws /catkin_ws

# Copy configuration files
COPY deployment/production/config/ /config/
COPY deployment/production/scripts/ /scripts/

# Install runtime Python dependencies only
COPY requirements.txt /tmp/
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt && rm /tmp/requirements.txt

# Set up environment
ENV ROS_PYTHON_VERSION=3
ENV ROS_DISTRO=noetic
ENV TURTLEBOT3_MODEL=waffle_pi
ENV PYTHONPATH=/opt/ros/noetic/lib/python3/dist-packages

# Health check
COPY deployment/production/healthcheck.sh /healthcheck.sh
RUN chmod +x /healthcheck.sh
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /healthcheck.sh

# Switch to non-root user
USER navy
WORKDIR /catkin_ws

# Set up ROS environment
RUN echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc && \
    echo "source /catkin_ws/devel/setup.bash" >> ~/.bashrc

EXPOSE 11311 11312

# Entry point
COPY deployment/production/entrypoint.sh /entrypoint.sh
USER root
RUN chmod +x /entrypoint.sh
USER navy

ENTRYPOINT ["/entrypoint.sh"]
CMD ["roslaunch", "turtlebot_complete.launch", "mode:=full_autonomous"] 