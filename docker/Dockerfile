# 휴대용 라이다 지도 생성기 - 개발용 컨테이너
# 목적: PC(Ubuntu 20.04)/WSL2/Mac 등 호스트 OS가 달라도 동일한 ROS2 Humble
#       환경에서 개발하기 위함. 이 이미지 안의 배포판(Ubuntu 22.04 + Humble)이
#       Raspberry Pi 5에서 쓸 배포판과 일치하므로, 컨테이너만 그대로 Pi5로
#       옮기면 이식이 끝난다는 것이 핵심 목표.
FROM ros:humble-ros-base

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-humble-slam-toolbox \
    ros-humble-rosbridge-server \
    ros-humble-nav2-map-server \
    ros-humble-rviz2 \
    ros-humble-tf2-geometry-msgs \
    ros-humble-eigen3-cmake-module \
    libeigen3-dev \
    python3-colcon-common-extensions \
    python3-rosdep \
    python3-pip \
    git \
    && rosdep init || true \
    && rosdep update \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir pyserial numpy

# sllidar_ros2: RPLIDAR 공식 드라이버. 우리가 수정하는 워크스페이스(src/, 볼륨 마운트)와
# 분리해서 이미지 안에 고정 오버레이로 미리 빌드해둔다 (외부 의존성이라 매번 빌드할 필요 없음).
RUN mkdir -p /opt/sllidar_ws/src && \
    git clone --depth 1 https://github.com/Slamtec/sllidar_ros2.git /opt/sllidar_ws/src/sllidar_ros2 && \
    /bin/bash -c "source /opt/ros/humble/setup.bash && cd /opt/sllidar_ws && colcon build --symlink-install" && \
    chmod -R a+rX /opt/sllidar_ws

# rf2o_laser_odometry: 바퀴 인코더가 없는 휴대용 기기라서, 연속된 라이다 스캔끼리
# 비교해서 이동(오도메트리)을 추정하는 방식으로 대체. odom->base_footprint TF를
# 이 노드가 동적으로 발행한다 (기존 정지 가정 고정 TF를 대체).
RUN mkdir -p /opt/rf2o_ws/src && \
    git clone --depth 1 -b ros2 https://github.com/MAPIRlab/rf2o_laser_odometry.git \
        /opt/rf2o_ws/src/rf2o_laser_odometry && \
    /bin/bash -c "source /opt/ros/humble/setup.bash && cd /opt/rf2o_ws && colcon build --symlink-install" && \
    chmod -R a+rX /opt/rf2o_ws

WORKDIR /lidar_ws

# 빌드 산출물(build/install/log)과 data 디렉터리는 named volume으로 마운트되는데,
# 컨테이너를 호스트 UID로 실행(run_dev.sh --user)해도 쓸 수 있도록 미리 열어둔다.
RUN mkdir -p /lidar_ws/build /lidar_ws/install /lidar_ws/log /lidar_ws/data && \
    chmod -R 777 /lidar_ws

RUN echo "source /opt/ros/humble/setup.bash" >> /etc/bash.bashrc && \
    echo "source /opt/sllidar_ws/install/setup.bash" >> /etc/bash.bashrc && \
    echo "source /opt/rf2o_ws/install/setup.bash" >> /etc/bash.bashrc && \
    echo "[ -f /lidar_ws/install/setup.bash ] && source /lidar_ws/install/setup.bash" >> /etc/bash.bashrc

CMD ["bash"]
