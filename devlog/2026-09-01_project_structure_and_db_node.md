# 2026-09-01 개발 로그 — 프로젝트 구조 확정 & lidar_mapper_db 노드 버그 수정

## 오늘의 목표
- 사용 언어/플랫폼/프로그램 구성 확정
- `lidar_mapper_db`(SQLite 저장) 노드 구현 및 검증
- AI 에이전트 연동 "자리" 마련
- Flutter 앱 스캐폴딩

## 진행 내용
- **언어/플랫폼 결정**: 엣지·백엔드는 Python(ROS2 기존 스택 유지), 모바일 시각화 앱은
  Flutter(Dart)로 확정. 마켓플레이스/랭킹/게임화는 지금 범위에서 제외, 아이디어로만 기록.
- **AI 에이전트 자리 마련** (`ai/`): `AIProvider` 추상 인터페이스 + `NullProvider`
  기본 구현 + provider 레지스트리(`ai/providers/__init__.py`). config.yaml의 provider
  이름만 바꾸면 Anthropic/OpenAI/중국계(Qwen 등) 어떤 모델도 교체 가능하도록 설계.
  지금은 API 호출 없는 NullProvider만 존재.
- **`lidar_mapper_db` 패키지 신설**: `/session_event`, `/session_end` 토픽을 구독해서
  세션 이벤트를 모았다가 종료 시 AI provider로 요약 후 SQLite(`sessions` 테이블)에 저장.
  `rooms` 테이블 스키마도 함께 정의(방 이름/카테고리, 아직 채우는 로직은 없음 — 추후
  음성 태깅 등으로 채울 예정).
- **Flutter 앱 스캐폴딩**: `app/lidar_mapper_app` (Android 타겟) 생성, `flutter create`로
  기본 골격만 확보.
- **Docker 개발 환경 보완**: `ai/`, `data/` 디렉터리를 컨테이너에 마운트하도록
  `docker/run_dev.sh` 갱신.

## 막힌 문제 & 해결
| 증상 | 원인 | 해결 방법 |
|---|---|---|
| `ros2 run lidar_mapper_db session_logger_node` → "No executable found" (mock 패키지도 동일) | ROS2 ament_python 패키지에 **`setup.cfg`가 빠져 있어서** setuptools가 실행파일을 `install/<pkg>/lib/<pkg>/` 대신 `install/<pkg>/bin/`에 설치함. colcon(`colcon_core.task.python.build._get_install_scripts`)이 `setup.cfg`의 `[install] install-scripts` 값을 읽어서 `--install-scripts`를 setuptools에 넘기는 구조인데, 이 값이 없으면 기본 위치(`bin/`)로 감. Docker/setuptools 버전 문제로 오인해서 setuptools 58.2.0 다운그레이드도 시도했으나 무관했음(원인 아님, 되돌림) | `src/lidar_mapper_mock/setup.cfg`, `src/lidar_mapper_db/setup.cfg`에 `script_dir`/`install_scripts`를 `$base/lib/<pkg명>`으로 지정하는 표준 ROS2 ament_python 보일러플레이트 추가. 재빌드 후 `ros2 pkg executables`에 정상 노출 확인 |
| `docker/run_dev.sh`에 `--user "$(id -u):$(id -g)"` 추가 후 컨테이너에서 라이다 데이터 파일이 root 소유로 생성됨 → 이어서 `--user`로 고치자 이번엔 `rclpy_logging_configure: failed to initialize logging: Failed to create log directory: //.ros/log` 에러 발생 | 호스트 UID로 컨테이너를 실행하면 `/etc/passwd`에 해당 UID의 계정이 없어 `HOME`이 빈 문자열이 되고, ROS2가 `$HOME/.ros/log`를 만들려다 실패 | `docker run`에 `-e HOME=/lidar_ws` 명시. `Dockerfile`에도 `/lidar_ws`를 `chmod 777`로 미리 열어둬서 비루트 UID로도 build/install/log/data에 쓸 수 있게 함 |

## 추가 진행 (같은 날, mock 파이프라인 첫 실가동)
- `./docker/run_dev.sh` 방식으로 mock 파이프라인(`bringup.launch.py use_mock:=true`)을
  백그라운드 컨테이너로 실행해서 실제로 `/map`이 채워지는지 확인.
- **버그 1**: mock 데이터는 오도메트리가 없어서 slam_toolbox가 스캔을 map 좌표계로
  변환하지 못해 `/map`이 계속 빈 상태였음.
  → 원인: `laser` 프레임에서 `map`까지 이어지는 TF 체인이 아예 없었음.
  → 해결: `bringup.launch.py`에 mock 전용 고정(identity) TF 3개 추가
  (`map→odom→base_footprint→laser`, `use_mock` 조건에서만 켜짐). 이후 `/map`이
  122x122 격자(mock이 흉내내는 방 크기와 일치)로 정상 생성됨을 확인.
- **버그 2**: Foxglove로 `ws://localhost:9090` 접속은 성공했지만 rosbridge 로그에
  `call_service /rosapi/topics_and_raw_types` 가 계속 실패(`InvalidServiceException`).
  → 원인: `rosapi_node`를 launch에 포함하지 않아서, rosbridge 연결 자체는 되어도
  클라이언트가 토픽/타입 목록을 조회하는 서비스가 없었음.
  → 해결: 돌고 있던 컨테이너에는 `ros2 run rosapi rosapi_node`로 즉시 추가해서
  중단 없이 살리고, `bringup.launch.py`/`package.xml`에도 영구 반영(`use_rosbridge`
  조건에 같이 묶음).

## 추가 진행 (같은 날, 실제 RPLIDAR C1 첫 실가동)
- `docker/Dockerfile`에 `sllidar_ros2`(RPLIDAR 공식 드라이버)를 `/opt/sllidar_ws`
  오버레이로 빌드해 추가. 우리가 계속 수정하는 `src/`(볼륨 마운트)와 분리해서,
  외부 의존성은 이미지 안에 고정 빌드.
- `bringup.launch.py`에 `lidar_serial_port` 인자 추가, `use_mock:=false`일 때
  `sllidar_c1_launch.py`에 전달하도록 연결. 고정 TF 체인(map→odom→base_footprint→laser)은
  mock 전용이 아니라 실기에도 동일하게 필요해서 조건 없이 항상 켜지도록 변경
  (아직 오도메트리가 없어서 정지 가정은 mock/실기 공통 임시 방편).
- **버그**: `--user "$(id -u):$(id -g)"`로 컨테이너를 돌리면서 `/dev/ttyUSB1`
  접근이 `Error, unexpected error, code: 80008004`로 즉시 실패.
  → 원인: 호스트 UID만 넘기고 `dialout` 그룹(GID 20)을 안 넘겨서 문자 장치 권한 없음.
  → 해결: `docker run --group-add 20` 추가.
- **에피소드**: 권한 문제 해결 직후 `sllidar_node`가 `SL_RESULT_OPERATION_TIMEOUT`으로
  다시 죽었고, 이후 호스트에서 직접 pyserial로 찔러봐도 응답이 아예 없어짐(이전엔
  잘 응답했음). USB를 물리적으로 뽑았다 다시 꽂으니 재인식되고 정상 응답 복구됨.
  → 짐작되는 원인: 크래시 전에 모터/스캔이 시작된 상태로 프로세스가 죽으면서 장치가
  응답 불가 상태로 걸림. 소프트웨어 재시도로는 못 풀었고 물리적 재연결이 유일한 해결책이었음.
- **최종 확인**: `sllidar_node`가 실제 하드웨어 인식(S/N, 펌웨어 1.02, health OK,
  Standard 모드 5kHz/16m/10Hz) 하고, `/scan`(실측 각도 범위 ±π), `/map`(129x86,
  mock 때와 다른 비대칭 격자 — 실제 방 형태 반영)까지 정상 확인.

## 추가 진행 (같은 날, 오도메트리 부재로 인한 "지도 확장 안 됨" 버그 수정)
- **증상**: 라이다를 실제로 들고 새로운 공간 쪽으로 이동해도 `/map`이 넓어지지 않음.
- **원인**: 이전까지 쓰던 TF 체인이 `map→odom→base_footprint`를 전부 identity 고정값으로
  발행하고 있었음 — 즉 시스템 입장에서는 라이다가 "제자리에 정지"해 있다고 가정.
  slam_toolbox는 직전 위치 근처의 좁은 탐색 범위에서만 스캔 매칭을 시도하기 때문에,
  실제로 크게 이동하면 새 스캔을 기존 지도와 매칭 못 하고 무시함.
- **해결**: 바퀴 인코더가 없는 휴대용 기기 특성에 맞춰 **rf2o_laser_odometry**
  (연속된 라이다 스캔끼리 비교해서 이동을 추정하는 2D 레이저 오도메트리) 도입.
  - `docker/Dockerfile`에 `/opt/rf2o_ws` 오버레이로 빌드 추가 (GitHub `ros2` 브랜치,
    apt 패키지는 Humble용이 없어서 소스 빌드).
  - `bringup.launch.py` TF 구성 변경: `map→odom`은 slam_toolbox가 알아서 발행하도록
    맡기고(직접 발행 제거), `odom→base_footprint`는 rf2o가 스캔 기반으로 동적 발행,
    `base_footprint→laser`(센서 마운트 오프셋)만 계속 고정값 유지.
  - 실기로 재검증: rf2o 로그에 `Laser odom [x,y,yaw]=...` 값이 실시간으로 잡히고,
    `/map`도 정상 발행 계속됨 확인. (다만 실제로 걸어다니며 지도가 안 깨지는지는
    사용자가 직접 들고 이동해보며 추가 확인 필요 — 이 세션에서는 정적 검증까지만 완료)

## 추가 진행 (같은 날, 지도 갱신 속도 튜닝)
- **증상**: `/map`이 넓어지긴 하는데 체감상 너무 느리게 갱신됨.
- **원인**: slam_toolbox 기본 설정(`mapper_params_online_async.yaml`)의
  `map_update_interval: 5.0`(5초에 한 번만 지도 재계산/발행) — 로봇 기준 기본값이라
  사람이 걷는 속도엔 너무 느림. `config/slam_params_notes.md`에서 이미 예상했던
  `minimum_travel_distance`/`minimum_travel_heading` 튜닝 필요성과 같은 맥락.
- **해결**: `config/mapper_params_online_async.yaml` 신설 (기본값 복사 + 튜닝):
  `map_update_interval` 5.0→0.5, `minimum_travel_distance` 0.5→0.1,
  `minimum_travel_heading` 0.5→0.2. `bringup.launch.py`가 slam_toolbox의
  `online_async_launch.py`에 `slam_params_file:=/lidar_ws/config/mapper_params_online_async.yaml`
  로 전달하도록 연결(`docker/run_dev.sh`가 프로젝트 `config/`를 그 경로에 이미 마운트해둠).
  `ros2 topic hz /map`으로 실측: 0.5초 간격(초당 2회)으로 정상 갱신 확인.
- Foxglove의 점 크기는 SLAM/코드와 무관한 UI 설정(3D 패널 → `/scan` → Point size)이라
  코드 수정 없이 화면에서 바로 조절 가능하다고 안내.
- 휴대 불가 문제는 현재 설계상 당연한 상태(Pi5 미구매, PC에 라이다 USB 직결)임을 설명 —
  Pi5 구매 전까지는 파이프라인 검증 단계로 규정.

## 추가 진행 (같은 날, 로그 무한 적재 방지)
- 사용자 질문: "오래 돌리면 로그 너무 많이 쌓이는 거 아니냐" → 맞는 지적.
  ROS2 자체 로그(`.ros/log`)는 컨테이너 안에만 있다가 `--rm`으로 같이 삭제되지만,
  **Docker가 컨테이너 stdout을 호스트에 기록하는 기본 로그 드라이버는 크기 제한이
  없어서** slam_toolbox/rf2o처럼 초당 여러 줄 찍는 노드를 오래 돌리면 커질 수 있음.
- `docker/run_dev.sh`에 `--log-opt max-size=10m --log-opt max-file=3` 추가해서
  파일당 10MB, 최대 3개(총 30MB)로 자동 순환되게 함.

## 추가 진행 (2026-09-04, 손 흔들림으로 인한 지도 노이즈 진단)
- 사용자가 Foxglove 화면 캡처 공유: 방사형으로 뻗는 검은 줄무늬 패턴의 지저분한 점 구름.
  "AI/로직으로 아웃라인만 추출하는 알고리즘이 필요한 거 아니냐"는 질문.
- **진단**: 이 패턴은 원본 `/scan`을 여러 프레임 누적해서 볼 때 나오는 전형적인
  모양이라, `/map`(occupancy grid)과 별도로 봐야 정확한 판단이 됨. 또한 occupancy
  grid 자체가 이미 "광선이 처음 부딪힌 지점만 격자화"하는 방식이라 사용자가 원하는
  "아웃라인 추출"을 이미 하고 있음 — 부족한 건 알고리즘이 아니라 **입력 오도메트리의
  신뢰도**. 손으로 든 라이다는 바퀴 로봇보다 훨씬 빠르고 불규칙하게 방향이 바뀌어서
  rf2o 추정이 흔들리고, slam_toolbox의 스캔 매칭 탐색 범위(기본/기존 0.5m)를
  벗어나면 보정 실패한 나쁜 위치값을 그냥 받아들여 지도가 어긋남.
- **적용한 튜닝** (`config/mapper_params_online_async.yaml`):
  - `correlation_search_space_dimension` 0.5 → 1.0 (오도메트리 오차 허용 범위 확대)
  - `minimum_travel_heading` 0.2 → 0.35 (너무 낮춰서 손이 홱홱 돌아갈 때의 잡음까지
    다 스캔 처리 대상이 되던 부작용 완화, 응답성과 절충)
  - `bringup.launch.py`: rf2o `freq` 20.0 → 10.0 (실제 RPLIDAR C1 스캔 속도에 맞춤,
    불필요한 "Waiting for laser_scans" 루프 낭비 제거)
- **근본적 한계 재확인**: 2D 라이다 기반 스캔 매칭만으로는 빠른 회전/기울기에 완전히
  강건해지기 어려움. 진짜 robust하게 하려면 IMU를 붙여서 `robot_localization`(EKF)로
  rf2o 오도메트리와 융합하는 게 표준적인 해법이지만, 지금 하드웨어(IMU 없음)로는
  적용 불가 — 이전 질문(높낮이/기울기 커버 여부)에서 답변한 "짐벌/평탄화 마운트
  필요성"과 같은 근본 원인. IMU는 향후 하드웨어 확장 항목으로 별도 기록.
- **다음 검증 필요**: 튜닝 반영 후 실제로 걸어다니며 `/map`(scan 누적 아님)이
  이전보다 덜 어긋나는지 사용자가 직접 재검증 필요 (이 세션에서는 파라미터만 적용,
  라이다 재연결 실측 테스트는 아직 안 함).

## 추가 진행 (2026-09-04, "찌꺼기 데이터 필터링" 요청 → occupancy grid 확정 기준 튜닝)
- 사용자 질문: 정지 상태로 테스트해도 중복/찌꺼기 데이터를 걸러내는 기능이 없어
  보인다, 최종 목표가 "사용자가 깔끔하게 볼 지도 데이터"인데 그게 안 됨.
- **설명**: 이 "걸러내는 기능"은 이미 존재 — `/map`(occupancy grid)이 원본 점을
  그대로 쌓는 게 아니라 격자 칸마다 "몇 번 부딪혔는지"를 누적해서 일정 기준을
  넘어야 벽으로 확정하는 방식(`min_pass_through`, `occupancy_threshold`). 다만
  기본값(2번, 10%)이 너무 낮아서 튀는 반사 노이즈 한두 번도 벽으로 오인될 여지가 있었음.
- **적용한 튜닝**: `min_pass_through` 2→4, `occupancy_threshold` 0.1→0.35로 상향
  (확정 기준을 높여서 노이즈가 최종 지도에 덜 남게 함).
- **사용자에게 안내한 검증 방법**: `/scan`(원본, 항상 지저분함이 정상)과 `/map`
  (정제된 최종 결과)을 구분해서 봐야 한다 — Foxglove에서 `/scan`의 point
  decay/history를 줄이거나 레이어를 끄고 `/map`만 보고 판단할 것. 정지 테스트부터
  `/map` 기준으로 깔끔한지 재확인 필요.

## 다음 단계
- `./docker/run_dev.sh --with-lidar`로 실제 라이다 mock/실기 파이프라인(`bringup.launch.py`) 실행
- Foxglove(`studio.foxglove.dev` 또는 데스크톱 앱)로 `ws://localhost:9090` 접속해서
  `/scan` 시각화 확인 — 사용자가 요청했던 "라이다 작동 확인"의 마지막 단계
- Flutter 앱에서 rosbridge(9090) 붙는 최소 화면 (연결 상태 표시 정도부터)
- `lidar_mapper_bringup`에도 `lidar_mapper_db`의 `session_logger_node`를 launch에 포함

## 참고 (에러 로그/명령어 등)
```
# 실행파일 위치 문제 재현/확인
$ ros2 pkg executables lidar_mapper_db   # (수정 전) 빈 결과
$ find install/lidar_mapper_db -maxdepth 3   # bin/session_logger_node 로 잘못 설치됨

# setup.cfg 추가 후
$ ros2 pkg executables lidar_mapper_db
lidar_mapper_db session_logger_node

# 세션 저장 검증
$ ros2 topic pub --once /session_event std_msgs/String '{data: "거실 스캔 완료"}'
$ ros2 topic pub --once /session_end std_msgs/String '{data: "/lidar_ws/maps/test.pgm"}'
# sqlite: (1, '2026-09-01T03:52:23...', ..., '/lidar_ws/maps/test.pgm', '거실 스캔 완료 / 주방 스캔 완료')
```
