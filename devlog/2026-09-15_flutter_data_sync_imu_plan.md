# 2026-09-15 개발 로그 — Flutter 앱 + 데이터 동기화 + IMU + 라이다 한계 극복 설계 확정

## 오늘의 목표
- Flutter 앱/데이터 동기화/IMU 선정 등 8가지 요구사항을 종합 설계로 정리하고 승인받기
- 문서(README/README_ARCHITECTURE) 반영 + devlog 기록 + git 커밋

## 진행 내용
- **설계 계획 승인 완료** (`/home/kani/.claude/plans/purring-honking-twilight.md`, 코드
  구현은 아직 없음, 설계 문서만 확정):
  - IMU 9축(나침반 포함)으로 추천 방향 수정 — 산길(실외) 사용 확정에 따라
    지자기 나침반 신뢰도 재평가
  - 온디맨드 연결 모델(0.5) + 명시적 시작/정지 트리거(0.7, 부팅 자동시작 금지)
  - **라이다 한계 극복 전략(0.8, 신규)**: 텀블러+가방 옆주머니 장착 특성상
    가림각/회전오차/도보속도/동적장애물/숲길 5가지 문제를 `laser_filters`
    (ROS2 표준 필터체인) + `robot_localization`(EKF 센서퓨전)으로 대응.
    새 알고리즘 개발 없이 표준 패키지 조합+설정 튜닝으로 해결
  - Store-and-Forward 데이터 동기화(1) + 자동 데이터 최적화(2)
  - 관계형 DB 스키마(2.5): `locations`+`building_details`/`mountain_details`+`sessions`
  - **진화형 지도 축적(2.6, 신규)**: slam_toolbox의 `serialize_map`/`deserialize_map`
    으로 재방문 시 이전 지도에 이어서 매핑 — 재방문 데이터를 중복이 아니라
    완성도를 높이는 히스토리로 누적(`map_versions` 테이블)
  - Flutter 앱 Tier1(7개)/Tier2(3개)/Tier3(3개) 기능 목록, MVVM+Riverpod 구조
  - AI 연동 2단계 분리(4.5): 1단계 규칙 기반 환경 프리셋(SLAM+필터 체인 묶음),
    2단계 진짜 AI 자동 조정(나중)
- **3D 라이다/카메라 대안 검토** (전부 웹 검색으로 실가격 확인):
  - Livox Mid-360($734), Unitree L1(€220~275, 단종) — 스피닝형, 비용상 배제
  - 국내 슬램텍 A2M12/YDLIDAR G6·G4 — 확인해보니 전부 **2D**였음(3D 아님)
  - CygLiDAR D2($181.95, solid-state ToF) — 사용자가 발견, 저렴한 진짜 3D지만
    FOV가 120°/65°로 360° 회전 스캔 전제와 안 맞아 채택 안 함
  - 카메라(RGB)로 3D를 흉내내는 건 불가능(카메라 자체는 깊이 정보가 없음) —
    사물인식(Tier3) 목적이라면 저가 웹캠+AI가 깊이센서보다 목적에 맞음
- **Phase 2를 하드웨어 도착 순서 기준 페이지 0~3으로 세분화** (README_ARCHITECTURE
  5.5 신규): 페이지0(지금, PC로 앱 선개발) → 1(오렌지파이 도착) → 2(IMU 도착) →
  3(물리버튼+실사용 필드 테스트+백엔드 구현). Tier1 앱 기능 대부분은 rosbridge
  프로토콜이 PC/보드 동일해서 오렌지파이 도착 전인 지금부터 개발 가능함을 확인
- EKF(확장 칼만 필터) 작동 원리, LaserScan 메시지 구조, RPLIDAR C1 스캔 주파수
  조절 가능 범위(10~20Hz) 등 사용자 질문에 답변, 관련 아티팩트 3개 발행
  (data_sync_diagram, db_schema_diagram, ekf_diagram)
- README.md/README_ARCHITECTURE.md에 위 내용 전체 반영 (3.5번 신규 섹션 등)

## 막힌 문제 & 해결
| 증상 | 원인 | 해결 방법 |
|---|---|---|
| 없음 (설계 단계, 코드 실행 이슈 없었음) | - | - |

## 다음 단계
- 페이지0: PC rosbridge 기준으로 Flutter Tier1 앱 개발 착수 (연결화면, 수집
  시작/정지, 지도뷰어, 필터 프리셋 패널 등 — 하드웨어 무관 항목부터)
- 오렌지파이 도착 전 부품 준비: 액티브 쿨링(가장 급함), microSD+리더기,
  IMU 모듈(DFRobot SEN0374), GPIO 버튼
- `laser_filters`/`robot_localization` 패키지를 PC Docker 이미지에 추가해서
  필터/센서퓨전 기능부터 선검증
- `lidar_mapper_db`에 `get_sessions`/`log_event` 등 ROS2 서비스 추가 (백엔드
  선행 작업, Tier1-1/4/5 앱 기능이 여기 의존)

## 참고 (에러 로그/명령어 등)
```
(없음)
```
