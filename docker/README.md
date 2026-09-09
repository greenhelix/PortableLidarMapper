# 개발 환경 (Docker) 사용 가이드

PC(Ubuntu 20.04)와 Pi5(예정: Ubuntu 22.04 계열)의 배포판이 달라서,
호스트 OS에 ROS2를 직접 설치하지 않고 **Docker 컨테이너 안에서 ROS2 Humble
(Ubuntu 22.04 기반)로 통일**해서 개발한다. 이렇게 하면:

- 호스트 OS(20.04)를 건드리지 않는다.
- Pi5가 22.04 계열을 쓴다면 이 이미지를 그대로 옮겨서 이식 가능.
- WSL/Mac에서도 같은 이미지로 동일한 개발 경험을 유지할 수 있다.

## 공통 사용법

```bash
# 최초 1회 (또는 Dockerfile 수정 후) 이미지 빌드
./docker/run_dev.sh --build

# 이후에는 mock 전용 실행
./docker/run_dev.sh

# 컨테이너 진입 후 (최초 1회)
cd /lidar_ws
colcon build --symlink-install
source install/setup.bash

# mock 파이프라인 실행 예시
ros2 launch lidar_mapper_bringup bringup.launch.py use_mock:=true
```

Foxglove는 컨테이너의 `9090` 포트(rosbridge websocket)를 호스트에 그대로
publish 하므로, 호스트 브라우저/앱에서 `ws://localhost:9090`으로 접속하면 된다.

## 환경별 차이

### PC (Ubuntu 20.04, 라이다 물리 연결) — 메인 개발 환경
```bash
./docker/run_dev.sh --with-lidar
# 컨테이너 안에서:
ros2 launch lidar_mapper_bringup bringup.launch.py use_mock:=false lidar_serial_port:=/dev/ttyUSB1
```
`/dev/ttyUSB0`, `/dev/ttyUSB1`, `/dev/ttyACM0` 중 존재하는 장치를 자동으로
컨테이너에 패스스루하고, `dialout` 그룹 권한도 같이 넘겨서(`--group-add`) 실제
시리얼 포트를 열 수 있게 한다. 실제 RPLIDAR C1 테스트는 여기서만 진행한다.

**라이다가 응답 없어지면**: `sllidar_node`가 비정상 종료된 직후 장치가 응답
불가 상태로 걸릴 수 있다(실제로 한 번 겪음). 이럴 땐 소프트웨어로 재시도해도
안 풀리고, **USB 케이블을 뽑았다 다시 꽂으면** 정상 복구된다.

### RViz2 — 고정 공간 정밀 디버깅 전용 (Pi5 도착 전 Phase 1)
Pi5가 없어서 지금은 라이다를 한 자리에 고정해두고 SLAM/오도메트리 파라미터
품질을 다듬는 단계다. 이 단계에선 Foxglove보다 **RViz2가 더 정확하다** — 색상이
임의로 커스텀되지 않고 기본이 흑백(점유=검정/빈공간=흰색/미지=회색)이라
"이게 벽인지 빈 공간인지" 헷갈릴 일이 없다. 다만 RViz2는 웹앱이 아니라 로컬 GUI라
휴대 단계(Phase 2)에서 폰으로 보는 용도로는 못 쓴다 — 그건 계속 Foxglove가 담당.

```bash
xhost +local:docker   # 호스트에서 최초 1회 (컨테이너가 화면에 그릴 수 있게 허용)
./docker/run_dev.sh --with-lidar --rviz
# 컨테이너 안에서 (별도 터미널로 docker exec 하거나 & 로 백그라운드 실행):
rviz2 -d /lidar_ws/config/rviz_default.rviz
```
`config/rviz_default.rviz`에 Map/LaserScan/TF/Grid 디스플레이가 미리 설정되어
있어서 매번 수동으로 추가할 필요 없다.

**컨테이너를 오래 켜둔 채로 방치하지 말 것.** 며칠씩 방치하면 그 사이 쌓인
오래된 로그/누적 맵을 "방금 테스트한 결과"로 착각해서 잘못된 진단을 하게 된다
(2026-09-04~07 세션에서 실제로 겪음). 테스트 전엔 항상 컨테이너를 재시작해서
깨끗한 상태로 시작할 것.

### WSL2 — 코드 검증용, 실기 테스트는 선택사항
Docker 자체는 WSL2에서도 동일하게 동작하지만, USB 장치는 기본적으로
Windows가 점유하고 있어서 WSL 컨테이너에 바로 안 보인다.

- **mock 전용으로만 쓸 경우**: 추가 설정 없이 `./docker/run_dev.sh` 그대로 사용.
- **실제 라이다까지 WSL에서 테스트하고 싶을 경우**: Windows에
  [`usbipd-win`](https://github.com/dorssel/usbipd-win)을 설치하고,
  ```powershell
  usbipd list
  usbipd bind --busid <라이다 버스ID>
  usbipd attach --wsl --busid <라이다 버스ID>
  ```
  로 WSL에 장치를 붙인 다음 `./docker/run_dev.sh --with-lidar`를 실행한다.
  다만 안정성이 PC 네이티브보다 떨어지므로 필수 워크플로는 아니다.

### Mac (Apple Silicon/Intel) — mock 개발 + Foxglove 원격 시각화 전용
Docker Desktop for Mac은 컨테이너가 Linux VM 안에서 돌기 때문에 **물리 USB
패스스루를 지원하지 않는다.** 따라서 Mac에서는:

1. `./docker/run_dev.sh` (옵션 없이, mock만)로 파이프라인 로직/코드 작업.
2. 실기 검증은 PC에서 진행 중인 컨테이너에 원격으로 붙어서 확인:
   - PC의 rosbridge(9090)에 같은 네트워크에서 `ws://<PC IP>:9090`으로
     Foxglove 접속 → 실시간 지도 확인.
   - 코드 자체는 Claude Code 원격 세션/SSH로 PC에 붙어서 편집·실행.

## 참고
- `scripts/setup_env.sh`는 호스트에 직접 ROS2를 설치하는 옛 방식(참고/백업용)이며,
  현재 권장 경로는 이 Docker 방식이다.
- 이미지 안 배포판은 `ros:humble-ros-base` (Ubuntu 22.04) 기준.
