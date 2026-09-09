# 2026-08-31 개발 로그 — 프로젝트 킥오프 & Docker 개발 환경 전환

## 오늘의 목표
- 프로젝트 전체 방향/문서 백브리핑
- 라이다 USB 연결 상태 실제 확인
- PC-Pi5 이식을 고려한 개발 환경(배포판) 방침 확정

## 진행 내용
- 문서(`README_ARCHITECTURE.md`, devlog, hardware, config) 검토 완료. 프로젝트 방향 재확인.
- **라이다 USB 감지 확인**: `/dev/ttyUSB1`에서 Silicon Labs CP2102N 칩 인식 확인.
  단순 lsusb 수준이 아니라 RPLIDAR 프로토콜(GET_INFO, 0xA5 0x50)로 직접 통신해서
  응답 확인 (`model=65, fw=1.2, hw=18`, 460800bps). 하드웨어 정상 동작 확인됨.
- **문제 발견**: `README_ARCHITECTURE.md`는 Ubuntu 22.04 + ROS2 Humble을 전제하지만
  실제 PC는 Ubuntu 20.04(focal)이고 ROS2 미설치 상태였음 (`scripts/setup_env.sh`가
  이 상태로는 Humble 설치에 실패할 상황).
- 사용자와 상의 후 **Docker 기반 개발 환경으로 전환 결정**:
  - `docker/Dockerfile`: `ros:humble-ros-base` + slam_toolbox + rosbridge_server +
    nav2-map-server + colcon + pyserial 설치.
  - `docker/run_dev.sh`: mock 전용 실행(`./run_dev.sh`) / 실제 라이다 패스스루
    (`./run_dev.sh --with-lidar`, `/dev/ttyUSB*` `/dev/ttyACM*` 자동 감지) 지원.
    빌드 산출물(`build`/`install`/`log`)은 named volume으로 유지해서 매번 재빌드
    안 되게 처리.
  - `docker/README.md`: PC/WSL2/Mac 환경별 사용법 정리.
    - PC(여기): 라이다 실기 테스트 가능한 유일한 환경.
    - WSL2: mock 위주, 실기 테스트하려면 `usbipd-win` 별도 설정 필요.
    - Mac: Docker Desktop이 USB 패스스루 미지원 → mock 개발 + PC 컨테이너의
      rosbridge(9090)에 원격 Foxglove 접속으로 시각화 확인하는 용도로 한정.
- **컨테이너 동작 검증 완료**:
  - `docker build` 성공.
  - 컨테이너 안에서 `--device /dev/ttyUSB1` 패스스루로 RPLIDAR GET_INFO 응답
    재확인 (호스트에서와 동일 결과) — USB 패스스루 정상 동작 확인.
  - `colcon build` 로 `lidar_mapper_mock`, `lidar_mapper_bringup` 두 패키지
    정상 빌드 확인.
- `README_ARCHITECTURE.md` 갱신: 개발 환경 항목에 Docker 명시, 로드맵 체크리스트
  갱신(Docker 환경 구축/라이다 확인 완료 표시).

## 막힌 문제 & 해결
| 증상 | 원인 | 해결 방법 |
|---|---|---|
| PC가 20.04라 ROS2 Humble 네이티브 설치 불가 | 아키텍처 문서가 22.04 전제로 작성됨, 실제 PC는 20.04 | Docker 컨테이너(`ros:humble-ros-base`, 내부는 22.04)로 통일. 호스트 OS 변경 없이 해결 |
| `docker compose` 명령 없음 | compose plugin 미설치, apt 저장소에도 없음(docker 설치 경로가 일반 apt repo 아님) | compose 없이 plain `docker run` 스크립트(`run_dev.sh`)로 대체 — 의존성 최소화 |
| scratchpad에 쓴 임시 진단 스크립트가 이후 permission denied로 안 써짐 | `docker run -v <미존재 host 경로>:...` 시 Docker가 root 권한으로 디렉터리를 자동 생성해서 소유권이 root로 바뀜 | 이후 호스트-컨테이너 파일 공유가 필요한 임시 테스트는 파일 마운트 대신 `python3 -c "..."` 인라인 스크립트로 우회 |

## 다음 단계
- `docker/run_dev.sh` 로 컨테이너 진입 → `lidar_mapper_mock` + slam_toolbox 로
  mock `/scan` → 지도 그려지는 흉내 확인 (Foxglove 또는 RViz2)
- 실제 C1로 `sllidar_ros2` 붙여서 `use_mock:=false` 실데이터 파이프라인 확인
- SQLite 스키마 설계 착수 (`lidar_mapper_db`, 아직 미착수)
- 텀블러 실측 → `hardware/tumbler_mount_design.md` 치수 확정
- Pi5 구매 시점은 여전히 미정 (가격 추이 관찰 중) — Pi5 도착 시 이 Docker 이미지를
  그대로 옮기는 것으로 이식 전략 확정

## 참고 (에러 로그/명령어 등)
```
# RPLIDAR GET_INFO 응답 (호스트/컨테이너 동일)
$ python3 -c "... GET_INFO 0xA5 0x50 ..."
bytes: 27 a55a140000000441020112857dfc8bc6e598d1b59598f906df5762
RPLIDAR DETECTED model=65 fw=1.2 hw=18

# Docker 빌드/실행
$ docker build -t lidar_mapper_dev:humble -f docker/Dockerfile docker
$ docker run --rm --device /dev/ttyUSB1 -v $PWD/src:/lidar_ws/src lidar_mapper_dev:humble \
    bash -c "source /opt/ros/humble/setup.bash && cd /lidar_ws && colcon build --symlink-install"
# Summary: 2 packages finished
```
