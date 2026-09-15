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
| 보드 | **Orange Pi 4 Pro 4GB** (Allwinner A733, 2x A76+6x A55) — 2026-09-08 결정, **2026-09-11 구매 완료(배송 중)**. Raspberry Pi 5에서 변경 (아래 사유 참고) |
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

## 3.5 확장 아키텍처: 온디맨드 연결 · Store-and-Forward · 라이다 한계 극복 · 진화형 지도 (2026-09-15 설계 확정)

Phase 2(보드 도착 후 실사용)를 대비해 Flutter 앱 + 백엔드 확장 구조를 설계했다.
**이 절은 전부 설계만 확정된 상태이고 아직 코드 구현 전**이다 — 5.4번 로드맵에서
진행 상황을 추적한다.

### 3.5.1 용어 정리
- **ROS2 노드**: 독립적으로 실행되는 하나의 프로세스(예: 라이다 드라이버, SLAM).
  노드끼리는 직접 호출하지 않고 **토픽(주제)** 을 통해 메시지를 주고받는다.
- **rosbridge**: ROS2 토픽/서비스를 WebSocket + JSON으로 바꿔서 브라우저/폰
  앱처럼 ROS2를 모르는 외부 클라이언트도 통신할 수 있게 해주는 게이트웨이
  (`:9090` 포트, 로컬망에서만 동작, 인터넷 불필요).
- **SLAM(동시적 위치추정 및 지도작성)**: "내가 어디 있는지"와 "주변 지도가
  어떻게 생겼는지"를 동시에 풀어내는 문제. 이 프로젝트에선 `slam_toolbox`가 담당.
- **오도메트리**: 절대 위치가 아니라 "직전 대비 얼마나 움직였는지"를 추정하는
  것. 바퀴 인코더가 없는 휴대 기기라 `rf2o_laser_odometry`(연속된 라이다 스캔
  비교)로 추정한다.

### 3.5.2 온디맨드 연결 모델 (배터리 절약)
- **Orange Pi = 자율 데이터 수집 엔진**. 폰(또는 물리 버튼)이 명시적으로 "수집
  시작"을 눌러야만 시작하고(부팅만으로 자동 시작 안 함 — 수평/장착 확인 전
  쓰레기 데이터 방지), 시작된 뒤로는 폰 연결 여부와 무관하게 계속 수집한다.
- **폰 = 온디맨드 모니터 + 중개자**. 평소엔 연결을 끊어(핫스팟 OFF) 배터리를
  아끼고, 확인하고 싶을 때만 핫스팟을 켜서 **mDNS(Avahi)** 로 `lidarmapper.local`
  같은 호스트이름을 찾아 접속한다(IP가 매번 바뀌어도 문제없음). 이미 아는
  SSID는 리눅스 NetworkManager가 알아서 재접속하므로 커스텀 코드가 필요 없다.

### 3.5.3 Store-and-Forward (저장 후 전송)
Orange Pi는 네트워크 유무와 무관하게 항상 로컬 SQLite에 먼저 저장(**STORE**)하고,
연결이 생기면 PC의 DB로 미전송분만 밀어올린다(**FORWARD**). 오프라인(산속/지하
등)에서도 100% 수집되고, 연결되면 자동으로 밀린 데이터가 업로드된다.

[다이어그램: data_sync_diagram](https://claude.ai/code/artifact/0686cb80-b7e4-421b-a3e3-a1d0db071f2b)

| 경로 | 용도 | 프로토콜 |
|---|---|---|
| 폰 ↔ Orange Pi | 실시간 확인/제어 | 기존 rosbridge WebSocket(:9090) 재사용 |
| Orange Pi → PC | 세션 종료 후 배치 전송(백업) | HTTP REST(POST), PC에 작은 FastAPI 엔드포인트 1개 |

MQTT 브로커/실시간 스트리밍 전용/클라우드 우선 업로드도 검토했으나, 오프라인
내구성이나 "최소구조" 원칙과 안 맞아 기각했다(대안 비교는 실제 구현 계획서 참고).

### 3.5.4 자동 데이터 최적화 (저장공간 관리)
지도(.pgm/.yaml)와 DB 메타데이터만 저장하는 지금 설계는 세션 1,000회 누적해도
~100MB 수준으로 사실상 안전하다. 위험한 건 원본 스캔 로그(rosbag, 세션당
~30~40MB)인데 **기본으로 꺼져 있음**. PC로 동기화 완료(`synced_at` 채워짐)된
세션은 일정 기간(예: 7일) 뒤 로컬 원본을 자동 삭제하는 정책을 예정하며,
동기화 안 된 데이터는 절대 자동 삭제하지 않는다.

### 3.5.5 관계형 DB 스키마 (실내/실외/산길 공통)
장소(`locations`)를 독립 개체로 두고, 장소 종류별 세부정보를 1:1 확장
테이블(`building_details`, `mountain_details`)로, 방문 기록을 `sessions`로
분리한 관계형 구조. 같은 장소를 여러 번 방문해도 장소는 한 번만 등록되고
세션만 늘어난다.

```sql
CREATE TABLE locations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    location_type TEXT NOT NULL,          -- 'building' | 'mountain' | ...
    name TEXT NOT NULL,
    gps_lat REAL,
    gps_lon REAL,
    current_map_serialized_path TEXT,     -- 진화형 지도용, 3.5.6 참고
    map_version INTEGER DEFAULT 0
);

CREATE TABLE building_details (
    location_id INTEGER PRIMARY KEY REFERENCES locations(id),
    floor INTEGER, building_type TEXT
);

CREATE TABLE mountain_details (
    location_id INTEGER PRIMARY KEY REFERENCES locations(id),
    trail_name TEXT, trail_difficulty TEXT
);

CREATE TABLE sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    location_id INTEGER REFERENCES locations(id),
    started_at TEXT NOT NULL, ended_at TEXT NOT NULL,
    map_pgm_path TEXT, map_yaml_path TEXT,
    summary TEXT, metadata_json TEXT,     -- 전용 테이블 없는 새 장소 종류용 escape hatch
    synced_at TEXT                        -- NULL = 미동기화
);
```

[다이어그램: db_schema_diagram](https://claude.ai/code/artifact/187c3b2d-13b7-421d-bd72-93b475922707)

### 3.5.6 진화형 지도 축적 (같은 장소 반복 방문 시 히스토리로 보완)
처음 방문에서 만드는 지도는 완성도가 낮을 수밖에 없다(30~50% 예상). slam_toolbox의
`serialize_map`/`deserialize_map` 서비스를 이용해 재방문 시 이전 지도를 불러와
**이어서** 매핑하면, 겹치는 구간은 스캔 매칭(loop closure)이 자동으로 정렬하고
빈 구석만 새로 채워진다 — 재방문 데이터가 중복이 아니라 보완으로 흡수된다.
`map_versions` 테이블(location_id, session_id, version, serialized_path 등)로
버전 히스토리를 덮어쓰지 않고 계속 쌓는다.

### 3.5.7 라이다 한계 극복 전략
텀블러+가방 옆주머니 장착 특성상 ①몸/가방에 시야 일부가 항상 가려짐,
②방향 전환/회전이 잦음, ③도보 속도로 스캔 간 겹침 부족, ④사람 등 동적
장애물, ⑤나무 많은 숲길처럼 2D 라이다가 놓치기 쉬운 환경 — 이 5가지를 새
알고리즘 없이 ROS2 표준 패키지로 대응한다.

- **가림각 대응**: `laser_filters` 패키지(ROS2 표준) — `LaserScanAngularBoundsFilter`
  (고정 각도 구간 무시), `LaserScanFootprintFilter`(자기 몸체 반사 제거),
  `LaserScanRangeFilter`/`LaserScanIntensityFilter`(근접/약한 반사 제거),
  `LaserScanSpeckleFilter`(고립 노이즈 제거), `ScanShadowsFilter`(물체 가장자리
  유령점 제거 — 나뭇가지 많은 환경에 유용).
- **회전 오차 보정**: `robot_localization`(EKF, 확장 칼만 필터)로 IMU와 rf2o
  라이다 오도메트리를 융합 — 회전 중엔 IMU를, 직선 이동 중엔 라이다를 더
  신뢰하도록 자동 가중. slam_toolbox에는 이 융합된 오도메트리를 입력한다.
  [다이어그램: ekf_diagram](https://claude.ai/code/artifact/56d51d00-6c3a-4580-b798-53d9f7a12807)
- **환경 프리셋**: SLAM 파라미터 + 라이다 필터 체인을 "실내"/"산길" 프리셋으로
  묶어서 세션 시작 전 선택 — Flutter 앱에서 프리셋 선택, 수동 파라미터 조절,
  필터 전/후 실시간 미리보기(테스트 모드)를 제공할 예정(Tier1-7).
- **3D 라이다는 채택 안 함**: 스피닝형(Livox Mid-360 ~$734, Unitree L1 단종)과
  solid-state ToF형(CygLiDAR D2, $181.95이나 시야각 120°/65°로 360° 회전
  스캔 전제와 안 맞음, 3D 사거리 2m로 짧음) 모두 검토했으나 비용 또는 구조
  전제 문제로 기각 — 알려진 한계로 문서화하고 위 대응으로 최대한 보완한다.

### 3.5.8 Flutter 앱 기능 확장 (Tier 1~3)
`app/lidar_mapper_app`에 MVVM(View→ViewModel(Riverpod)→Repository→
`ros_bridge_client`) 구조로 다음을 순차 구현 예정:

- **Tier 1(지금)**: DB 통신(get_sessions/log_event), 연결 설정, 수집 시작/정지
  버튼, 기기 점검(라이다/IMU/Orange Pi 상태/배터리 추정/네트워크), 기기 제어
  명령(리셋/DB 즉시전송), 실시간 지도/스캔 뷰어, 환경 프리셋+필터 조절 패널.
- **Tier 2(보드 도착 후)**: 세션 관리, 세션 상태/리셋 패널, 지도 히스토리 뷰
  (`flutter_map`/OpenStreetMap 기반, 실외 세션 GPS 핀 표시).
- **Tier 3(나중)**: 수동 지도 보정(터치 삭제), AI 기반 자동 하드웨어 제어,
  카메라/사물 인식 연동.

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
- [ ] (Phase 2, 2026-09-10 기록) **앱 기능: 세션 상태 확인/리셋 패널**. 지도는
      디스크가 아니라 RAM에만 있어서 저장공간 문제는 없지만, 현재 지도 크기
      (`/map_metadata`의 width/height)와 리셋 버튼(내부적으로 파이프라인 재시작
      트리거)을 보여주면 사용자가 안심하고 확인/정리할 수 있음.
      `/slam_toolbox/clear_changes` 서비스 존재는 확인했으나 정확한 동작(전체
      초기화 vs 수동 보정 취소만)은 미검증 — 도착 후 실측 필요.
- [ ] 텀블러 실측 후 `hardware/tumbler_mount_design.md` 치수 확정 + 3D프린팅 도면
- [x] 보드 결정: Raspberry Pi 5 → **Orange Pi 4 Pro 4GB**로 변경 (2026-09-08,
      사유는 리스크 섹션 참고)
- [x] Orange Pi 4 Pro 구매 (2026-09-11, 배송 중)
- [ ] 도착 후 `hardware/orange_pi_4_pro_bringup_risks.md` 절차대로 이식 (Phase 2 시작 조건)

### 5.5 Phase 2 세부 페이지 (2026-09-15 확정)
Orange Pi/IMU 도착 시점이 서로 달라서, Phase 2를 하드웨어 도착 순서에 맞춰
3단계로 더 쪼갠다. **앱 개발은 rosbridge 프로토콜이 PC/보드 동일하다는 환경
독립성 원칙(1번) 덕분에, 오렌지파이 도착을 기다리지 않고 지금 PC 컨테이너
기준으로 먼저 시작한다** (Tier1 대부분이 하드웨어 무관 — 3.5.8번 참고).

| 페이지 | 트리거 | 하드웨어 작업 | 앱/백엔드 작업 |
|---|---|---|---|
| **0 (지금, 대기 중 병행)** | 없음 | 액티브 쿨링/microSD 등 부품 준비 (아래 체크리스트) | Tier1 대부분을 PC rosbridge로 개발/검증 (연결화면, 수집 시작/정지, 지도뷰어, 필터 프리셋 등) |
| **1. Orange Pi 도착** | 보드 수령 | 라이다 재부착 + `orange_pi_4_pro_bringup_risks.md` 절차대로 실기 기능 테스트 | 페이지0 앱 기능을 오렌지파이 주소로 재검증 |
| **2. IMU 도착** (미구매) | IMU 모듈 수령 | IMU 부착 + 기능 테스트 + `robot_localization`(EKF) 연동 + 휴대성(장착) 테스트 | 앱 개발 계속 — 기기 점검 화면에 IMU 상태 반영 |
| **3. 실사용 필드 테스트 단계** | 위 2단계 완료 후 | GPIO 물리 버튼 부착(0.7번) + 실내/산길 실제 도보 테스트로 라이다 필터·EKF 튜닝값 확정(0.8번) + 진화형 지도 재방문 실측(2.6번) | 백엔드 구현(DB 스키마 확장, `sync_node`) → Tier1 나머지(기기제어) + Tier2(세션관리, 지도 히스토리) 착수 |

**오렌지파이 도착 전 부품 체크리스트** (`orange_pi_4_pro_bringup_risks.md` 0번에 이미
있는 보조배터리 항목 외 추가):
- [ ] **액티브 쿨링(팬+방열판)** — 90°C 스로틀링이 실측 확인된 리스크라 가장
      급함, 보드 도착 직후 부하 테스트(체크리스트 6번)에 바로 필요
- [ ] microSD 카드(32GB+, 또는 eMMC) + 카드 리더기 — OS 이미지 굽는 용도
- [ ] (선택) 랜선 — Wi-Fi 미검증 리스크(2번)의 1순위 폴백
- [ ] (선택) HDMI 케이블+모니터 — 헤드리스(SSH) 설정 실패 시 폴백
- [ ] IMU 모듈(DFRobot SEN0374 추천, 페이지2용) — 아직 미구매
- [ ] GPIO 물리 버튼 + 점퍼케이블(페이지3용) — 수천원대, 저렴

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
