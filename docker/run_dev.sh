#!/usr/bin/env bash
# 휴대용 라이다 지도 생성기 - 개발 컨테이너 실행 스크립트
#
# 사용 예:
#   ./run_dev.sh                # mock 전용 (WSL/Mac 등 라이다 없는 환경)
#   ./run_dev.sh --with-lidar   # 실제 라이다 USB 패스스루 (라이다가 물리 연결된 PC 전용)
#   ./run_dev.sh --with-lidar --rviz  # + RViz2 GUI (고정 공간 정밀 디버깅용, PC 전용)
#   ./run_dev.sh --build        # 이미지 새로 빌드 후 실행
#
# 주의: 컨테이너를 오래 켜둔 채로 방치하지 말 것. 며칠씩 방치하면 그 사이 쌓인
# 오래된 로그/누적 맵을 "방금 테스트한 결과"로 착각해서 잘못된 진단을 하게 됨
# (2026-09-04~07 세션에서 실제로 겪은 문제). 테스트 전엔 항상 재시작해서 새로 시작할 것.
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE_NAME="lidar_mapper_dev:humble"

WITH_LIDAR=false
DO_BUILD=false
WITH_RVIZ=false
for arg in "$@"; do
  case "$arg" in
    --with-lidar) WITH_LIDAR=true ;;
    --build) DO_BUILD=true ;;
    --rviz) WITH_RVIZ=true ;;
    *) echo "알 수 없는 옵션: $arg" && exit 1 ;;
  esac
done

if [ "$DO_BUILD" = true ] || ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
  echo "=== 이미지 빌드: $IMAGE_NAME ==="
  docker build -t "$IMAGE_NAME" -f "$PROJECT_ROOT/docker/Dockerfile" "$PROJECT_ROOT/docker"
fi

DOCKER_ARGS=(
  --rm -it
  --name lidar_mapper_dev
  --user "$(id -u):$(id -g)"
  -e "HOME=/lidar_ws"
  # slam_toolbox/rf2o가 초당 여러 줄씩 로그를 찍어서, Docker의 기본(무제한)
  # 로그 저장 방식대로 두면 오래 켜둘 때 호스트 디스크에 계속 쌓임.
  # 파일 하나당 10MB, 최대 3개까지만 남기고 자동으로 순환(오래된 것부터 삭제).
  --log-opt max-size=10m
  --log-opt max-file=3
  -p 9090:9090
  -v "$PROJECT_ROOT/src:/lidar_ws/src"
  -v "$PROJECT_ROOT/config:/lidar_ws/config"
  -v "$PROJECT_ROOT/ai:/lidar_ws/ai"
  -v "$PROJECT_ROOT/data:/lidar_ws/data"
  -v lidar_mapper_build:/lidar_ws/build
  -v lidar_mapper_install:/lidar_ws/install
  -v lidar_mapper_log:/lidar_ws/log
)

if [ "$WITH_LIDAR" = true ]; then
  FOUND_DEVICE=""
  for dev in /dev/ttyUSB0 /dev/ttyUSB1 /dev/ttyACM0; do
    if [ -e "$dev" ]; then
      echo "=== 라이다 USB 장치 패스스루: $dev ==="
      DOCKER_ARGS+=(--device "$dev")
      FOUND_DEVICE="$dev"
    fi
  done
  if [ -z "$FOUND_DEVICE" ]; then
    echo "경고: --with-lidar 옵션을 줬지만 /dev/ttyUSB*, /dev/ttyACM* 장치를 찾지 못했습니다."
    echo "라이다가 USB에 연결되어 있는지 lsusb로 확인하세요."
  fi
  # --user로 호스트 UID를 쓰면 dialout 그룹 권한이 자동으로 안 넘어와서
  # 시리얼 장치를 열 때 권한 오류가 남 (컨테이너에 dialout GID를 명시적으로 추가).
  DIALOUT_GID="$(getent group dialout | cut -d: -f3)"
  if [ -n "$DIALOUT_GID" ]; then
    DOCKER_ARGS+=(--group-add "$DIALOUT_GID")
  fi
fi

if [ "$WITH_RVIZ" = true ]; then
  echo "=== RViz2 GUI 모드: X11 화면 전달 설정 ==="
  echo "호스트에서 먼저 다음을 실행해야 컨테이너가 화면에 그릴 수 있습니다:"
  echo "  xhost +local:docker"
  DOCKER_ARGS+=(
    -e "DISPLAY=$DISPLAY"
    -v /tmp/.X11-unix:/tmp/.X11-unix:ro
  )
fi

echo "=== 컨테이너 실행 (컨테이너 안에서: cd /lidar_ws && colcon build --symlink-install) ==="
echo "RViz2 실행 예: rviz2 -d /lidar_ws/config/rviz_default.rviz"
docker run "${DOCKER_ARGS[@]}" "$IMAGE_NAME"
