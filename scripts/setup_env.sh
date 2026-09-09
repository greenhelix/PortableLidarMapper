#!/usr/bin/env bash
# 휴대용 라이다 지도 생성기 - 개발 환경 세팅 스크립트
# 대상: Ubuntu 22.04 (PC 선개발 & Raspberry Pi 5 공용)
set -e

echo "=== 1. ROS2 Humble 설치 ==="
sudo apt update && sudo apt install -y curl gnupg lsb-release
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
  -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
sudo apt update
sudo apt install -y ros-humble-desktop   # Pi5 headless라면 ros-humble-ros-base 로 교체

echo "=== 2. SLAM / 시각화 패키지 설치 ==="
sudo apt install -y \
  ros-humble-slam-toolbox \
  ros-humble-rosbridge-server \
  ros-humble-nav2-map-server

echo "=== 3. 워크스페이스 빌드 도구 ==="
sudo apt install -y python3-colcon-common-extensions python3-rosdep
sudo rosdep init || true
rosdep update

echo "=== 4. RPLIDAR 공식 드라이버 clone (실제 하드웨어 도착 후 사용) ==="
mkdir -p ~/lidar_ws/src
cd ~/lidar_ws/src
if [ ! -d "sllidar_ros2" ]; then
  git clone https://github.com/Slamtec/sllidar_ros2.git
fi

echo "=== 5. 이 프로젝트 워크스페이스 심볼릭 연결 안내 ==="
echo "portable_lidar_mapper/src 의 lidar_mapper_bringup, lidar_mapper_mock 를"
echo "~/lidar_ws/src 아래로 복사하거나 심볼릭 링크 하세요:"
echo "  ln -s /path/to/portable_lidar_mapper/src/lidar_mapper_bringup ~/lidar_ws/src/"
echo "  ln -s /path/to/portable_lidar_mapper/src/lidar_mapper_mock ~/lidar_ws/src/"

echo "=== 6. 빌드 ==="
cd ~/lidar_ws
source /opt/ros/humble/setup.bash
colcon build --symlink-install

echo "=== 완료 ==="
echo "매 터미널마다 아래 실행 필요:"
echo "  source /opt/ros/humble/setup.bash"
echo "  source ~/lidar_ws/install/setup.bash"
