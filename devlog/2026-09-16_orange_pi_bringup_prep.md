# 2026-09-16 개발 로그 — Orange Pi 4 Pro 브링업 준비 완료 (공식 매뉴얼 확인)

## 오늘의 목표
- 하드웨어 부속품 구매 확정 (IMU, microSD, PETG, 인두기 등)
- RPLIDAR C1 마운트 나사 규격 확인
- Orange Pi 4 Pro 공식 데이터시트/매뉴얼 확보 및 브링업 관련 미확인 사항 해소

## 진행 내용

### 부속품 구매 확정
`hardware/accessories_purchase_log.md`에 전체 기록. 총 지출 ₩255,380
(RPLIDAR C1 ₩100,800 + Orange Pi 4 Pro ₩74,800 + 케이스/공구/부속 ₩79,780).
IMU는 DFRobot 정품 대신 **CJMCU-055**(Bosch BNO055 칩, 저가 클론, ₩13,040)로
최종 결정 — 칩은 동일하고 문서화도 잘 되어있어 최소비용 원칙에 부합.

### RPLIDAR C1 마운트 규격 확인 (공식 datasheet)
바닥면 마운트 나사: **M2.5 × 4개, 43×43mm 정사각 배치**. ⚠️ 나사가 바닥으로
4mm 이상 들어가면 내부 파손(공식 경고). `hardware/cad/mount_plate_and_case_v1.scad`에
반영 완료(기존 추정치 40mm → 확정값 43mm로 수정, 나사구멍도 M3→M2.5 클리어런스로 수정).

### 데이터시트 3종 확보 (`hardware/datasheets/`)
- `rplidar_c1_datasheet.pdf` (SLAMTEC 공식)
- `bno055_datasheet.pdf` (Bosch Sensortec 공식)
- `orange_pi_4_pro_user_manual_v1.4.pdf` (Shenzhen Xunlong 공식) — **가장 큰 수확**

### Orange Pi 4 Pro 브링업 관련 미확인 사항 전부 해소
공식 User Manual v1.4를 읽고 그동안 `hardware/orange_pi_4_pro_bringup_risks.md`에
"미확인"으로 남아있던 항목들을 확정값으로 갱신:

| 항목 | 이전 상태 | 확정된 내용 |
|---|---|---|
| 40핀 GPIO 핀맵 | 미확인 | 28개 GPIO, 전부 **3.3V 로직**. I2C0(SDA=3번핀, SCL=5번핀) 확인 |
| IMU 연결 가능 여부 | - | I2C0 4선(3.3V/GND/SDA/SCL)으로 바로 연결 가능 확인 |
| 물리 버튼용 여유 GPIO | - | PD0(29)/PD1(31)/PD2(33)/PD3(35)/PD4(37) 등 다수 확보 |
| OS 이미지 | Armbian 커뮤니티 이미지에 의존할 것으로 예상 | **벤더 공식 Ubuntu/Debian/Android13 이미지 존재 확인**, ROS2 Humble용 Ubuntu 22.04(Jammy) 공식 지원 확인 |
| 부팅 매체 | 미확인 | **microSD/eMMC/NVMe SSD만 지원, USB 부팅 불가** — microSD 필수 |
| 발열 모니터링 명령 | Armbian 전용 명령 가정(`armbianmonitor`) | 공식 경로 확인: `/sys/class/thermal/thermal_zone{0,1,4,5,6}/temp` (각각 CPU리틀/빅/GPU/NPU/DDR) |
| wiringOP 설치 필요 여부 | - | **이미지에 사전 설치되어 있음**, 별도 컴파일 불필요 |
| 디버그 시리얼 포트 배선 | - | 전용 3핀(GND/TX/RX, TX·RX 교차 연결), 40핀 헤더의 UART7/8과는 별개 |
| 보드 상 eMMC/HDMI 등 위치 | - | Top/Bottom View 사진으로 전체 확인(위 해당 절 참고) |
| 네트워크 | - | 기가비트 이더넷(PoE 지원) + Wi-Fi6/BT5.4 둘 다 기본 내장 |

## 막힌 문제 & 해결
| 증상 | 원인 | 해결 방법 |
|---|---|---|
| 없음 | - | - |

## 다음 단계
- microSD 도착 → orangepi.net에서 **Ubuntu 22.04(Jammy)** 이미지 다운로드 → balenaEtcher로 굽기
- 첫 부팅 시 체크리스트(`hardware/orange_pi_4_pro_bringup_risks.md` 6번) 순서대로 진행:
  RPLIDAR C1 USB 연결 확인 → 이 프로젝트 Docker 이미지 arm64 빌드 확인 → Wi-Fi 테스트 →
  slam_toolbox 부하 중 발열 모니터링(`/sys/class/thermal/thermal_zone0,1/temp`)
- IMU(CJMCU-055) 도착 시 I2C0(3번/5번핀)로 브레드보드 배선 테스트
- `hardware/orange_pi_4_pro_bringup_risks.md`의 GPIO 배선 항목(0.7번 물리 버튼용
  핀 최종 선택)을 이번에 확인된 여유 GPIO 목록 기준으로 확정

## 참고 (에러 로그/명령어 등)
```
(없음)
```
