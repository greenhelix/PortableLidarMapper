# Portable LiDAR Mapper

> 텀블러형 케이스에 RPLIDAR C1 + Orange Pi 4 Pro를 넣고 들고 다니며 실내 2D 지도(로봇청소기 수준)와 실외 GPS 경로를 기록하는 개인용 프로젝트.

**현재 단계: Phase 1 — PC + 고정 공간에서 SLAM 파라미터 품질 검증 중** (보드 미도착, `docker/` 환경으로 PC에서 선개발).
상세 아키텍처/로드맵은 [`README_ARCHITECTURE.md`](./README_ARCHITECTURE.md), 세션별 작업 기록은 [`devlog/`](./devlog)를 참고.

---

## 개발 단계 (Phase)

| | **Phase 1 (현재)** | **Phase 2 (보드 도착 후)** |
|---|---|---|
| 장소 | PC + **고정된 한 공간** | 실내외 휴대 이동 |
| 목적 | SLAM/오도메트리 파라미터 품질 검증 | 실제 지도 생성 |
| 주 시각화 도구 | RViz2 (정밀 디버깅, `docker/run_dev.sh --rviz`) | Foxglove (폰 원격 접속) |
| 보드 | 없음 (PC로 대체) | Orange Pi 4 Pro 4GB |
| 다음 하드웨어 할 일 | — | 구매 → `hardware/orange_pi_4_pro_bringup_risks.md` 절차대로 이식 |
| Flutter 앱 | 우선순위 낮음 (스캐폴딩만) | 본격 개발 시작 |
| IMU(관성 측정 장치) 추가 | 안 함 | 몸통 가림 등 물리적 문제 먼저 해결 후 검토 (`hardware/tumbler_mount_design.md` 1.5번) |

전환 조건: Orange Pi 4 Pro 구매 + 도착. 상세 이식 절차는 [`hardware/orange_pi_4_pro_bringup_risks.md`](./hardware/orange_pi_4_pro_bringup_risks.md).

## 소프트웨어 아키텍처

이 프로젝트는 4가지 설계 원칙 위에 서 있습니다.

1. **레이어드 구조** — 하드웨어 → 드라이버 → ROS2 미들웨어(오도메트리/SLAM) → 데이터
   저장 → 시각화, 5개 계층으로 나뉘고 **계층 간 통신은 오직 ROS2 토픽/메시지로만**
   이루어집니다. 직접 함수를 호출하는 계층 간 결합이 없습니다.
2. **노드 단위 분리(교체 가능성)** — 라이다 드라이버, 오도메트리, SLAM, DB 로깅,
   AI 요약이 각각 독립된 ROS2 노드(프로세스)입니다. 그래서 라이다를
   mock ↔ 실기로, AI 모델을 provider 하나만 바꿔서 교체해도 **다른 코드는 무수정**입니다.
3. **환경 독립성(Docker)** — ROS2/SLAM 전부 Docker 컨테이너 안에서 돌기 때문에,
   호스트가 PC(Ubuntu 20.04)든 나중에 Orange Pi 4 Pro든 **같은 이미지가 그대로
   이식**됩니다. 이게 보드를 라즈베리파이→오렌지파이로 바꿔도 코드 리스크가 적었던
   핵심 이유입니다.
4. **어댑터 패턴** — `ai/`의 `AIProvider` 인터페이스처럼, 하드웨어·모델 종류를
   구체 구현이 아니라 인터페이스로 감싸서 나중에 무엇으로 바뀌어도 갈아끼우기만
   하면 되게 설계합니다.

전체 계층 구조, 각 계층의 책임, ROS2 노드 그래프, 데이터 저장 형식까지의 상세
내용은 [`README_ARCHITECTURE.md`](./README_ARCHITECTURE.md)에 있습니다 — 이 README는
요약이고, 그 문서가 정본입니다.

## 데이터 흐름

```mermaid
flowchart TD
    LIDAR["📡 RPLIDAR C1<br/>USB · 460800bps"] --> SLLIDAR["sllidar_node<br/>(실기 드라이버)"]
    MOCK["mock_scan_publisher<br/>(개발용 가짜 데이터)"] -.-> SCAN
    SLLIDAR --> SCAN(("/scan"))

    SCAN --> RF2O["rf2o_laser_odometry<br/>(스캔 기반 오도메트리)"]
    RF2O -- "odom→base_footprint (동적)" --> SLAM["slam_toolbox<br/>(SLAM)"]
    SLAM -- "map→odom" --> SLAM
    SLAM --> MAP(("/map"))

    MAP --> BRIDGE["rosbridge + rosapi<br/>:9090"]
    BRIDGE --> FOX["📱 Foxglove<br/>(브라우저/앱)"]
    BRIDGE -.-> APP["lidar_mapper_app<br/>(Flutter, 미연결)"]

    CLI["ros2 topic pub<br/>(수동 트리거)"] -.-> LOGGER["session_logger_node"]
    LOGGER --> AI["ai/ provider<br/>(NullProvider, 교체 가능)"]
    AI --> DB[("🗄️ SQLite<br/>data/rooms.db")]
```

실선 = 지금 자동으로 동작 확인된 경로. 점선 = 코드는 있지만 수동 트리거이거나(우측 DB 경로) 아직 연결 전(Flutter 앱).

## 빠른 시작 (Docker)

```bash
# 최초 1회: 이미지 빌드
./docker/run_dev.sh --build

# mock 데이터로 파이프라인만 검증 (라이다 없이도 가능)
./docker/run_dev.sh
ros2 launch lidar_mapper_bringup bringup.launch.py use_mock:=true

# 실제 RPLIDAR C1 연결 시
./docker/run_dev.sh --with-lidar
ros2 launch lidar_mapper_bringup bringup.launch.py use_mock:=false lidar_serial_port:=/dev/ttyUSB1

# 고정 공간 정밀 디버깅용 RViz2 (PC 전용, X11 필요)
./docker/run_dev.sh --with-lidar --rviz
```

시각화는 `ws://localhost:9090`으로 [Foxglove](https://studio.foxglove.dev)에 접속하거나, 위 `--rviz` 옵션으로 RViz2를 띄우면 됩니다. 자세한 사용법은 [`docker/README.md`](./docker/README.md).

## 하드웨어

| 부품 | 내용 |
|---|---|
| 센서 | RPLIDAR C1 |
| 보드 | Orange Pi 4 Pro 4GB (Allwinner A733) — **구매 완료(배송 중, 2026-09-11)**, 상세는 [`hardware/board_price_tracking.md`](./hardware/board_price_tracking.md) |
| 폼팩터 | 텀블러형 케이스, 백팩 측면 휴대 |

## 저장소 구조

| 경로 | 내용 |
|---|---|
| `src/` | ROS2 워크스페이스 — `lidar_mapper_bringup`(launch 통합), `lidar_mapper_mock`(가짜 /scan), `lidar_mapper_db`(세션 로깅) |
| `ai/` | AI provider 어댑터 (`AIProvider` 인터페이스 + `NullProvider`, provider 이름만 바꾸면 모델 교체) |
| `app/lidar_mapper_app/` | Flutter 모바일 뷰어 (스캐폴딩, 아직 rosbridge 미연결) |
| `docker/` | 개발 환경 (Dockerfile, `run_dev.sh`, RViz2/Foxglove 가이드) |
| `config/` | slam_toolbox 파라미터, RViz2 기본 레이아웃 |
| `hardware/` | 텀블러 마운트 설계, 보드 가격/스펙 비교·리스크 조사 |
| `devlog/` | 세션별 개발 로그 (매 세션 시작 시 최신 로그부터 읽을 것) |
| `data/` `maps/` `bags/` | 런타임 산출물 (SQLite, 지도 파일, rosbag) |

## 문서 갱신 원칙

이 README와 `README_ARCHITECTURE.md`는 프로젝트의 첫 화면이자 최신 상태를 보여주는 문서입니다.
**구조가 바뀌거나(새 패키지/폴더), 하드웨어 결정이 바뀌거나, 개발 단계(Phase)가 넘어갈 때마다 반드시 갱신**합니다.
다이어그램은 Mermaid로 관리해서(이미지 파일 대신) 코드처럼 diff로 리뷰하고 계속 최신 상태를 유지합니다.
