# 휴대용 라이다 지도 생성기 — 아키텍처 문서

> 텀블러형 케이스에 RPLIDAR C1 + Orange Pi 4 Pro를 장착하고 들고 다니며
> 실내 2D 지도(로봇청소기 수준) + 실외 GPS 경로를 기록하는 개인용 프로젝트

이 문서는 지금까지 확정된 내용을 기반으로 **하드웨어 → 소프트웨어 → 데이터 → 개발 프로세스** 전체를 구조화한다.
장비(보드)가 아직 없는 상태이므로, PC Ubuntu에서 먼저 100% 동일한 구조로 개발하고
보드가 도착하면 코드 변경 없이 이식하는 것을 목표로 설계한다.

---

## 0. 확정 사항 요약

| 항목 | 내용 |
|---|---|
| 센서 | RPLIDAR C1 (구매 완료) |
| 보드 | **Orange Pi 4 Pro 4GB** (Allwinner A733, 2x A76+6x A55) — 2026-09-08 결정, 구매 전. Raspberry Pi 5에서 변경 (아래 사유 참고) |
| 폼팩터 | 텀블러형 케이스, 백팩 측면 포켓 휴대 |
| 목적 | 실내 2D SLAM 지도 + 실외 GPS 경로 기록 |
| SW 스택 | ROS2 Humble + slam_toolbox + rosbridge + Foxglove |
| 개발 순서 | PC Ubuntu 선개발 → 보드 도착 시 이식 |
| 개발 환경 | Docker (`docker/`) — PC 호스트 OS(20.04)와 무관하게 컨테이너 안에서 Ubuntu22.04+Humble로 통일. 상세: `docker/README.md` |

---

## 1. 레이어드 시스템 아키텍처

시스템은 5개 계층으로 나눈다. 각 계층은 독립적으로 테스트 가능해야 하며,
상위 계층은 하위 계층의 인터페이스(ROS2 토픽)에만 의존한다. 이렇게 하면
라이다가 없어도 3~5계층을 mock 데이터로 그대로 개발할 수 있다.

```
5. 시각화/앱     Foxglove(스마트폰) / RViz2(PC)
                        ▲  WebSocket
4. 저장/데이터    SQLite(방/가구) / 맵 파일(pgm,yaml) / devlog
                        ▲
3. ROS2 미들웨어  /scan → slam_toolbox → map_saver
                        ▲  LaserScan msg
2. 드라이버/통신  sllidar_ros2 (USB) / GPS 브릿지(MQTT)
                        ▲
1. 하드웨어       RPLIDAR C1 / Orange Pi 4 Pro / 전원부·GPS모듈
```

**핵심 설계 원칙**
- 계층 간 통신은 오직 **ROS2 토픽/메시지**로만 이루어진다 (직접 함수 호출 금지) → 나중에 라이다를 mock에서 실제 센서로 바꿔도 상위 계층 코드는 무수정.
- 3계층(SLAM)까지는 순수 소프트웨어이므로 **하드웨어 없이 100% 개발 가능**.
- 1~2계층만 하드웨어 의존적이며, 도착 즉시 교체(mock → real)한다.

---

## 2. 하드웨어 설계도

### 2.1 텀블러 마운트 단면 구조 (개념도)

```
        ┌────────────────┐  ← 상단 캡 (평탄화 디스크, 3D프린팅)
        │  ⊙ RPLIDAR C1   │     라이다 스캔 평면이 지면과 평행 유지
        │   (지름 ~75mm)  │     360도 스캔, 케이블 하단으로 관통
        ├────────────────┤
        │                │
        │   텀블러 몸체    │  ← 기존 텀블러/보온병 재활용 or 원통 케이스
        │  (단열재 제거)   │
        │                │
        ├────────────────┤
        │ Orange Pi 4 Pro │  ← 무게 중심을 낮추기 위해 하단 배치
        │  + 보조배터리    │
        └────────────────┘
              │
        백팩 측면 포켓에 수직으로 삽입
```

### 2.2 부품 리스트 & 배치 원칙

| 부품 | 배치 위치 | 이유 |
|---|---|---|
| RPLIDAR C1 | 최상단 | 360도 스캔 시야 확보, 몸/배낭에 가려지지 않게 |
| 평탄화 디스크 | 라이다 바로 아래 | 원통 뚜껑 곡면 위에서도 스캔 평면 수평 유지 |
| Orange Pi 4 Pro | 중~하단 | 발열 방출 공간 확보, 무게중심 하향 (발열이 큰 편이라 액티브 쿨링 필수 — `hardware/orange_pi_4_pro_bringup_risks.md` 참고) |
| 보조배터리 | 최하단 | 가장 무거운 부품 → 무게중심 안정화 |
| USB 케이블(라이다-보드) | 내부 관통홀 | 외부 노출 시 걸림/단선 위험 |
| GPS | 별도 (스마트폰 앱) | 자체 GPS 모듈 대신 스마트폰 GPS를 Wi-Fi/MQTT로 수신 (실내 GPS 무의미) |

### 2.3 검증해야 할 물리 제약
- **수평 유지가 핵심**: 라이다 스캔 평면이 기울면 SLAM 정확도 급락 → 텀블러가 기울어져도 라이다 마운트 자체는 수평 고정되는 짐벌/평탄화 구조 필요
- **진동은 허용, 기울기는 비허용**: 걷는 진동(좌우 흔들림)은 SLAM이 누적 보정 가능하지만 지속적 틸트는 누적 오차 유발
- **발열**: 보드(Orange Pi 4 Pro) + SLAM 연산 시 발열 있음(실제 리뷰로 확인된 리스크,
  `hardware/orange_pi_4_pro_bringup_risks.md` 참고) → 방열판/액티브 쿨러 필수, 밀폐 케이스 지양

> 상세 치수(C1 지름 75mm 기준 마운트 설계)는 실측 후 `hardware/tumbler_mount_design.md`에 업데이트 예정.

---

## 3. 소프트웨어 아키텍처 (ROS2 노드 그래프)

```
┌─────────────────┐    /scan (sensor_msgs/LaserScan)
│  sllidar_node    │ ────────────────────────────┐
│ (실제 C1 or Mock) │                              ▼
└─────────────────┘                    ┌────────────────────┐    /map (nav_msgs/OccupancyGrid)
                                        │  slam_toolbox        │ ──────────────┐
┌─────────────────┐   /gps/fix          │  (online_async)      │               ▼
│  gps_bridge_node │ ──────────────────▶│                       │    ┌─────────────────┐
│ (MQTT 구독)       │                    └────────────────────┘    │  map_saver_cli   │
└─────────────────┘                                                │  → .pgm / .yaml  │
                                                                    └─────────────────┘
                        rosbridge_server (WebSocket :9090)
                                        ▲
                                        │
                          Foxglove (스마트폰 브라우저 접속)
```

**패키지 분리 전략 (ROS2 워크스페이스)**
```
src/
├── lidar_mapper_bringup/   # launch 파일 모음 (실제 하드웨어 + SLAM + rosbridge 통합 실행)
├── lidar_mapper_mock/      # 하드웨어 없이 개발용 가짜 /scan 퍼블리셔
├── lidar_mapper_db/        # /session_event, /session_end 구독 → AI 요약 → SQLite 저장 (2026-09-01 구현)
├── (외부) sllidar_ros2      # RPLIDAR 공식 드라이버 (git clone)
└── (외부) slam_toolbox      # apt 설치
```

이렇게 나누는 이유: `bringup`은 "무엇을 실행할지"만 담당하고,
`mock`은 라이다 없이도 `/scan`을 흉내내는 **개발 전용 패키지**로 완전히 분리한다.
보드+실제 센서가 오면 launch 인자 하나(`use_mock:=false`)로 전환한다.

**저장소 최상위 구성 (2026-09-01 확정)**
```
app/    # Flutter 모바일 뷰어 앱 (app/lidar_mapper_app) — 언어: Dart
ai/     # AI 에이전트 provider 어댑터 자리. AIProvider 인터페이스 + NullProvider 기본값.
        # provider 이름만 바꾸면 Anthropic/OpenAI/중국계(Qwen 등) 어떤 모델로도 교체 가능.
docker/ # 개발 환경 (README_ARCHITECTURE 0번 항목 및 docker/README.md 참고)
```
언어 선택: 엣지·백엔드는 Python(ROS2 기존 스택과 통일), 모바일 앱은 Flutter(Dart, 크로스플랫폼).
마켓플레이스/랭킹/게임화(다중 사용자 데이터 공유)는 사용자가 여러 명이 되는 시점에나 의미가
생기는 확장 아이디어로, 지금 구조에는 반영하지 않고 기록만 해둔다.

---

## 4. 데이터 아키텍처

| 데이터 | 형식 | 용량(추정) | 저장 위치 |
|---|---|---|---|
| 최종 2D 지도 | .pgm + .yaml | ~100KB (30평 기준) | `maps/` |
| 원본 스캔 로그 | rosbag2 (.db3) | ~30~40MB | `bags/` (필요시만 기록) |
| 방/가구 메타데이터 | SQLite | 수십 KB | `data/rooms.db` |
| GPS 경로(실외) | GeoJSON or SQLite | 경로 길이 비례 | `data/routes.db` |
| 개발 로그 | Markdown | - | `devlog/` |

**저장 원칙**: SLAM 실시간 처리에는 rosbag이 필요 없음(메모리 상에서 map으로 수렴).
디버깅/재현이 필요할 때만 선택적으로 rosbag 기록 → 저장공간 절약.

---

## 5. 개발 프로세스 & 개발 로그 규칙

### 5.1 개발 로그 원칙
- 위치: `devlog/YYYY-MM-DD_주제.md`
- 매 개발 세션 시작 시 **직전 로그를 먼저 읽고** 시작 (컨텍스트 복원)
- 로그 템플릿은 `devlog/TEMPLATE.md` 참고 — 목표/진행/막힌점/다음단계 4블록 고정
- 막힌 문제와 해결 방법은 반드시 기록 (동일 삽질 반복 방지)

### 5.2 장비 도착 전 진행 가능한 개발 순서 (PC Ubuntu 기준)

1. **환경 세팅**: `docker/run_dev.sh --build` (Docker 컨테이너 안에 ROS2 Humble +
   slam_toolbox + rosbridge 설치됨. 호스트가 20.04라 Humble 네이티브 설치가
   불가능해서 컨테이너로 통일 — 2026-08-31 결정, `devlog/2026-08-31_docker_kickoff.md`
   참고. 호스트 직접 설치용 `scripts/setup_env.sh`는 참고/백업 용도로 유지.)
2. **Mock 노드로 파이프라인 검증**: `lidar_mapper_mock` → `/scan` 가짜 데이터 → slam_toolbox가 뭔가 그리는지 확인 (지도 품질은 무의미, **파이프라인 연결 자체**를 검증하는 목적)
3. **DB 스키마 설계 & 저장 로직 작성**: 방/가구 좌표 저장 (`lidar_mapper_db`, 아직 미착수)
4. **Foxglove 연동 검증**: mock 데이터로 스마트폰에서 실시간으로 보이는지 확인
5. (C1 USB 연결 시) **1~4를 실제 센서로 교체**하고 그대로 동작하는지만 확인
6. (보드 도착 시) 워크스페이스 통째로 이식, 보드 전용 설정 도구(Orange Pi는
   `orangepi-config`/Armbian 설정)와 GPIO 관련 항목만 추가 설정

### 5.3 개발 단계 (Phase) — 2026-09-08 정의
보드(Orange Pi 4 Pro)가 없는 지금과, 보드로 실제 휴대 이동하는 이후는 목적 자체가 달라서 단계를 나눈다.

| | **Phase 1 (현재)** | **Phase 2 (보드 도착 후)** |
|---|---|---|
| 장소 | PC + **고정된 한 공간** | 실내외 휴대 이동 |
| 목적 | SLAM/오도메트리 파라미터 품질 검증 | 실제 지도 생성 |
| 주 시각화 도구 | **RViz2** (정밀 디버깅, 색상 왜곡 없음) | **Foxglove** (폰 원격 접속) |
| Foxglove 역할 | 원격 접속 연습/유지만 (병행) | 메인 |
| Flutter 앱(`app/lidar_mapper_app`) | 우선순위 낮음 | 의미 생김 — 본격 개발 |

RViz2는 로컬 GUI라 폰 원격 접속이 안 되기 때문에 Phase 2에서 Foxglove를 대체하지
않는다 — 지금 단계의 디버깅 전용 도구. 사용법은 `docker/README.md` 참고.

### 5.4 다음 단계 로드맵
- [x] Docker 개발 환경 구축 (`docker/run_dev.sh`) → ROS2 Humble 컨테이너 빌드 완료 (2026-08-31)
- [x] RPLIDAR C1 USB 연결 확인 (프로토콜 GET_INFO 응답 확인, 컨테이너 패스스루도 확인) (2026-08-31)
- [x] `lidar_mapper_db` 패키지 구현 + 세션 이벤트→AI 요약→SQLite 저장 흐름 검증 (2026-09-01)
- [x] Flutter 앱(`app/lidar_mapper_app`) 스캐폴딩 (2026-09-01)
- [x] `lidar_mapper_mock` 노드 + slam_toolbox + Foxglove로 mock 지도 시각화 확인 (2026-09-01)
- [x] 실제 RPLIDAR C1로 sllidar_ros2 붙여서 `/scan`·`/map` 실데이터 확인 (2026-09-01)
- [x] 오도메트리 부재로 지도가 안 넓혀지던 문제 해결: rf2o_laser_odometry(스캔 기반
      2D 레이저 오도메트리) 도입, `map→odom`은 slam_toolbox가 발행하도록 정리 (2026-09-01)
- [x] RViz2 디버깅 환경 추가 (`config/rviz_default.rviz`, Phase 1 정밀 진단용,
      X11 필요 — `docker/run_dev.sh --rviz`) (2026-09-08)
- [ ] **Phase 1 진행 중**: 고정 공간에서 SLAM/오도메트리 파라미터 품질 검증 (RViz2로 판단)
- [ ] (Phase 2로 넘어간 뒤) 실제로 걸어다니며 지도가 안 깨지는지 현장 검증
- [ ] (Phase 2) Flutter 앱에서 rosbridge(9090) 연결 최소 화면
- [ ] (Phase 2, 설계 확정 2026-09-08) **앱 기능: 수동 지도 보정(터치 삭제)**.
      배경: slam_toolbox는 사람 몸이 라이다를 잠깐 가려도 그 지점을 "벽"으로 영구
      기록하는 경향이 있고(자기 그림자 문제), 재매핑으로 시간이 지나면 자동
      갱신되긴 하지만(로보락과 동일 원리) 즉시 고치고 싶을 때를 위한 수동 삭제
      기능이 필요. 설계: 스캔 진행 중 폰 앱에서 지도 확대 → 검은 점 터치 →
      이어진 영역 flood-fill로 자동 선택 → 팝업(삭제/취소) → 삭제 시 해당 좌표를
      "강제 빈 공간" 보정 레이어에 기록(SQLite, `lidar_mapper_db` 확장) → 최종
      지도 = slam_toolbox 원본 위에 보정 레이어를 항상 마지막에 덮어써서 생성.
      slam_toolbox가 지도를 매번 처음부터 재계산하기 때문에 원본을 직접 수정하는
      대신 이 보정 레이어 방식이 필요.
- [ ] 텀블러 실측 후 `hardware/tumbler_mount_design.md` 치수 확정 + 3D프린팅 도면
- [x] 보드 결정: Raspberry Pi 5 → **Orange Pi 4 Pro 4GB**로 변경 (2026-09-08,
      사유는 리스크 섹션 참고)
- [ ] Orange Pi 4 Pro 구매 + 도착 후 이식 (Phase 2 시작 조건)

---

## 6. 리스크 & 열린 질문
- **보드를 Raspberry Pi 5 → Orange Pi 4 Pro 4GB로 변경 (2026-09-08)**: Pi5가
  LPDDR4 메모리 품귀로 실구매가가 정가 대비 크게 뛴 상태라 대안을 비교함
  (Orange Pi Zero 3 - CPU 너무 약함, Orange Pi 5/5 Max(RK3588S/RK3588) - 정상
  스펙이지만 매물 가격이 애매하거나 상위 모델과 혼동됨). 최종적으로 Orange Pi 4 Pro
  (Allwinner A733, 2x Cortex-A76 + 6x Cortex-A55, 4GB LPDDR5, ₩74,800, 판매
  600+/평점 4.6 검증)로 결정. RK3588S(Orange Pi 5)보다 빅코어가 2개 적어 이론상
  약간 아래지만, Pi4B보다는 확실히 강하고 GPIO에 I2C/SPI가 있어 향후 IMU 확장에도
  유리. Docker 기반 아키텍처라 보드가 바뀌어도 이미지는 그대로 이식 가능(핵심 전제
  유지됨). 아직 실물 구매/테스트 전이라 실제 ROS2/Docker 구동 시 예상 못 한 이슈
  가능성은 남아있음. 스펙 비교표/가격 추이 기록은 `hardware/board_price_tracking.md` 참고.
- 텀블러 기울임 시 라이다 수평 유지 메커니즘은 아직 물리 설계 미검증 (프로토타입 필요)
- GPS-실내지도 좌표계 통합(실외↔실내 전환 시점 판단 로직)은 미설계 — 추후 별도 아키텍처 논의 필요
- **2D 라이다 단독으로는 빠른 손 회전/기울기에 근본적으로 취약** (2026-09-04 확인,
  방사형 노이즈 패턴). slam_toolbox 파라미터 튜닝으로 어느 정도 완화했지만, 완전히
  강건하게 하려면 IMU 추가 + `robot_localization`(EKF) 융합이 표준 해법 — 아직 미구매/미착수
- **테스트용 컨테이너를 장시간(며칠) 방치하면 안 됨**: 2026-09-04~07 세션에서
  실제로 컨테이너를 끄지 않고 3일 넘게 방치했다가, 그 사이 쌓인 오래된 로그/누적된
  지도를 "방금 튜닝한 결과"로 착각해서 엉뚱한 원인 분석을 한 적이 있음. 테스트
  시작 전엔 항상 `docker rm -f lidar_mapper_dev`로 재시작해서 깨끗한 상태로 시작할 것
