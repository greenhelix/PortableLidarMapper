# 2026-09-07 개발 로그 — Phase 1(고정 공간 검증) 정의 & RViz2 도입

## 오늘의 목표
- Pi5 도착 전까지의 개발 단계를 명확히 정의하고 문서/도구에 반영
- 정지 테스트 중 발견된 방사형 노이즈 문제의 진짜 원인 파악

## 진행 내용
- **긴 진단 세션**: 화면 캡처로 방사형(별 모양) 노이즈 패턴을 여러 차례 재현/분석.
  - 원본 `/scan`은 실제로 깨끗함(720개 중 620개 유효, 큰 튐 거의 없음) → 문제는
    지도 합성(occupancy grid) 과정에 있다고 판단.
  - `correlation_search_space_dimension`을 0.5→1.0으로 넓혔더니 `Message Filter
    dropping message ... queue is full` 경고가 2.6초마다 반복 → 계산량 증가로
    처리가 밀려서 스캔이 버려지는 부작용으로 추정, 되돌림(0.5 유지) +
    `transform_timeout` 0.2→0.5로 여유 확보.
  - **결정적 함정 발견**: 컨테이너가 대화 세션 사이(2026-09-04~07, 실제 3일)
    계속 켜진 채 방치되어 있었음. 이후 관찰한 "점점 커지고 촘촘해지는 별 모양"은
    그 3일 동안 쌓인 로그/맵이었을 뿐, 방금 바꾼 설정을 반영한 결과가 아니었음.
    컨테이너를 완전히 새로 띄워서 재검증하니 rf2o yaw가 -0.007~-0.009 rad로
    안정적이고 `queue is full` 경고도 재발하지 않음 → 최소한 그 세션 시점 설정으로는
    정상 동작 확인. (진짜 "정지 상태 지도 품질"은 다음 세션에서 Phase 1 절차대로
    재검증 필요.)
- **RViz2 도입 결정**: Foxglove는 색상 모드를 임의로 커스텀할 수 있어(노랑/파랑 등)
  점유/빈공간 판단을 헷갈리게 만들 수 있음을 확인. RViz2는 기본 흑백이라 더
  정확한 디버깅 도구. 다만 로컬 GUI라 폰 원격 접속이 안 되므로, 휴대 단계(Phase 2)의
  Foxglove를 대체하지 않고 지금 단계 전용 도구로 도입.
  - Claude가 X11 화면을 직접 캡처할 수 있는지 확인(`gnome-screenshot`, DISPLAY=:0
    접근 가능) → 실제로 캡처 성공, 앞으로 RViz2 화면도 직접 보고 판단 가능.
- **개발 단계(Phase) 정의**: Phase 1(현재, PC+고정 공간, RViz2 위주) vs
  Phase 2(Pi5 도착 후, 휴대 이동, Foxglove 위주)로 명확히 구분해서
  `README_ARCHITECTURE.md` 5.3에 표로 정리.

## 변경한 파일
- `docker/Dockerfile`: `ros-humble-rviz2` 추가
- `docker/run_dev.sh`: `--rviz` 옵션 추가 (X11 전달), 컨테이너 방치 경고 주석 추가
- `docker/README.md`: RViz2 사용법 섹션 추가
- `config/rviz_default.rviz` 신규: Map/LaserScan/TF/Grid 기본 세팅
- `README_ARCHITECTURE.md`: 5.3 Phase 정의, 5.4 로드맵/리스크 갱신

## 막힌 문제 & 해결
| 증상 | 원인 | 해결 방법 |
|---|---|---|
| 튜닝해도 지도가 계속 지저분해 보임 | 컨테이너를 3일간 방치, 관찰 중인 화면이 최신 설정 반영이 아니라 3일치 누적 데이터였음 | 테스트 전 항상 컨테이너 재시작하는 규칙을 문서(`README_ARCHITECTURE.md` 6번, `docker/run_dev.sh` 주석)에 명시 |
| correlation_search_space 확대가 오히려 역효과 | 계산량 증가 → 처리 지연 → tf2 MessageFilter 큐 초과로 스캔 유실 | 0.5로 원복, `transform_timeout` 0.5로 확대해 여유 확보 |

## 다음 단계
- Phase 1 절차대로 **깨끗하게 재시작한 컨테이너**에서 RViz2로 정지 상태 지도 품질
  재검증 (지금까지의 진단은 방치된 컨테이너로 오염되어 있었으므로 원점에서 재확인 필요)
- `min_pass_through`/`occupancy_threshold` 튜닝(4, 0.35)이 실제로 효과 있는지도
  이번 재검증에서 같이 확인
- 이후 Phase 2(Pi5 도착) 전까지는 Flutter 앱, 텀블러 마운트 등은 우선순위 낮음
