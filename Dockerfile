# This Dockerfile is a combination of:
# https://gitlab.com/nvidia/container-images/samples/-/blob/master/opengl/ubuntu16.04/turbovnc-virtualgl/Dockerfile
# https://github.com/lambdal/lambda-stack-dockerfiles/blob/master/Dockerfile.xenial
# and custom changes to install ROS, XFCE, Firefox
# and to pull an example ros workspace from our lab's rosinstall file hosted on github

# noVNC + TurboVNC + VirtualGL
# http://novnc.com
# https://turbovnc.org
# https://virtualgl.org

######
###### Directions for running this dockerfile:
######
# starx -- :2 (in a separate tmux window so it stays running forever)
# export DISPLAY=:2
# xhost +
# openssl req -new -x509 -days 365 -nodes -out self.pem -keyout self.pem
# vim vncpassword.txt (only uses first 8 characters!)
# docker build -t turtlebot_port5903 .
# docker run --init --gpus all --name=turtlebot_port5903 -i -v /tmp/.X11-unix/X2:/tmp/.X11-unix/X2 -p 5903:5903 turtlebot_port5903
# now, you can connect to this machine from a browser using https://localhost:5901
# and using the password you put in the vncpassword.txt
#####
#####
#####

FROM nvidia/opengl:1.0-glvnd-runtime

ARG TURBOVNC_VERSION=2.1.2
ARG VIRTUALGL_VERSION=2.5.2
ARG LIBJPEG_VERSION=1.5.2
ARG WEBSOCKIFY_VERSION=0.8.0
ARG NOVNC_VERSION=1.0.0-beta

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gcc \
        libc6-dev \
        libglu1 \
        libsm6 \
        libxv1 \
        make \
        python \
        python-numpy \
        x11-xkb-utils \
        xauth \
        xfonts-base \
        xkb-data && \
    rm -rf /var/lib/apt/lists/*

RUN cd /tmp && \
    curl -fsSL -O https://svwh.dl.sourceforge.net/project/turbovnc/${TURBOVNC_VERSION}/turbovnc_${TURBOVNC_VERSION}_amd64.deb \
        -O https://svwh.dl.sourceforge.net/project/libjpeg-turbo/${LIBJPEG_VERSION}/libjpeg-turbo-official_${LIBJPEG_VERSION}_amd64.deb \
        -O https://svwh.dl.sourceforge.net/project/virtualgl/${VIRTUALGL_VERSION}/virtualgl_${VIRTUALGL_VERSION}_amd64.deb \
        -O https://svwh.dl.sourceforge.net/project/virtualgl/${VIRTUALGL_VERSION}/virtualgl32_${VIRTUALGL_VERSION}_amd64.deb && \
    dpkg -i *.deb && \
    rm -f /tmp/*.deb && \
    sed -i 's/$host:/unix:/g' /opt/TurboVNC/bin/vncserver

ENV PATH ${PATH}:/opt/VirtualGL/bin:/opt/TurboVNC/bin

RUN curl -fsSL https://github.com/novnc/noVNC/archive/v${NOVNC_VERSION}.tar.gz | tar -xzf - -C /opt && \
    curl -fsSL https://github.com/novnc/websockify/archive/v${WEBSOCKIFY_VERSION}.tar.gz | tar -xzf - -C /opt && \
    mv /opt/noVNC-${NOVNC_VERSION} /opt/noVNC && \
    mv /opt/websockify-${WEBSOCKIFY_VERSION} /opt/websockify && \
    ln -s /opt/noVNC/vnc_lite.html /opt/noVNC/index.html && \
    cd /opt/websockify && make


RUN apt-get update && \
    env DEBIAN_FRONTEND=noninteractive apt-get install xfce4 xfce4-goodies -y

RUN apt-get update && \
    apt-get install lsb-release -y && \
    sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list' && \
    apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654 && \
    apt-get update && \
    apt-get install ros-kinetic-desktop-full -y

# https://github.com/lambdal/lambda-stack-dockerfiles/blob/master/Dockerfile.xenial
# Add libcuda dummy dependency
ADD control .
RUN apt-get update && \
	apt-get install --yes equivs && \
	equivs-build control && \
	dpkg -i libcuda1-dummy_10.2_all.deb && \
	rm control libcuda1-dummy_10.2_all.deb && \
	apt-get remove --yes --purge --autoremove equivs && \
	rm -rf /var/lib/apt/lists/*

ADD lambda.gpg .
RUN apt-key add lambda.gpg && \
	rm lambda.gpg && \
	echo "deb http://archive.lambdalabs.com/ubuntu xenial main" > /etc/apt/sources.list.d/lambda.list && \
	echo "cudnn cudnn/license_preseed select ACCEPT" | debconf-set-selections && \
	apt-get update && \
	DEBIAN_FRONTEND=noninteractive \
		apt-get install \
		--yes \
		--no-install-recommends \
		--option "Acquire:http::No-Cache=true" \
		--option "Acquire:http::Pipeline-Depth=0" \
		lambda-stack-cuda \
		lambda-server && \
	rm -rf /var/lib/apt/lists/*


ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_REQUIRE_CUDA "cuda>=10.0"
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility,display

RUN apt-get update && \
    apt-get install python-wstool python-catkin-tools -y && \
    mkdir /turtlebot_ws && \
    cd /turtlebot_ws && \
    wstool init src https://raw.githubusercontent.com/Cornell-Tech-Turtlebot/rosinstalls/master/vglrun_turtlebot_ml.rosinstall

RUN /bin/bash -c "source /opt/ros/kinetic/setup.bash && cd /turtlebot_ws && catkin build"

RUN chsh -s /bin/bash root

RUN echo "export TURTLEBOT3_MODEL=waffle_pi\n" \
         "source /turtlebot_ws/devel/setup.bash\n" \
         "cd /turtlebot_ws" \
         >> /root/.bashrc

RUN apt-get update && \
    apt-get install firefox -y

RUN echo 'no-remote-connections\n\
no-httpd\n\
no-x11-tcp-connections\n\
no-pam-sessions\n\
permitted-security-types = TLSVnc,VNC\n\
' > /etc/turbovncserver-security.conf

COPY self.pem /
EXPOSE 5902

COPY vncpassword.txt /
RUN mkdir /root/.vnc && \
    touch /root/.vnc/passwd && \
    cat /vncpassword.txt /vncpassword.txt | vncpasswd && \
    rm /vncpassword.txt

RUN apt-get update && \
    apt-get install openvpn -y

COPY ["openvpn-ca/keys/dh2048.pem","openvpn-ca/keys/server.key","openvpn-ca/keys/server.crt","openvpn-ca/keys/ca.crt","openvpn-ca/keys/ta.key","./"]

COPY root /
# the config file we just copied specifies that the openvpn server runs on the following port
EXPOSE 4194

RUN apt-get update && \
    apt-get install net-tools openssh-server telnet iputils-ping -y && \
    sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

ENV DISPLAY :3
ENV VGL_DISPLAY :2

COPY root_password.txt /

RUN cat /root_password.txt | chpasswd && \
    rm /root_password.txt

# set up ROS to use the VPN ip address.
RUN echo "export ROS_MASTER_URI=http://10.8.0.1:11311\n" \
         "export ROS_IP=10.8.0.1" \
         >> /root/.bashrc

COPY start_vpn_and_sshd_and_vnc.sh .
CMD ./start_vpn_and_sshd_and_vnc.sh