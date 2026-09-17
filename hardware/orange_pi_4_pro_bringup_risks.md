# Orange Pi 4 Pro 이식 예상 리스크 (구매 전 사전 조사, 2026-09-08)

> 실제 보드가 아직 없는 상태에서 웹 검색으로 확인한 내용 기반 예측. 도착 후
> 실제로 겪는 문제와 다를 수 있음 — 도착하면 이 문서의 각 항목을 실측으로 검증할 것.

## 1. 확인된 진짜 리스크

### 🔴 발열 (가장 우려되는 항목)
실제 리뷰([boilingsteam.com](https://boilingsteam.com/orange-pi-4-pro-review/))에서
**"부하를 좀 걸면 온도가 금방 90°C까지 치솟아 스로틀링이 걸린다"**고 확인됨.
slam_toolbox의 Ceres 솔버 연산이 정확히 그런 지속적 CPU 부하다.

- **이 프로젝트에 미치는 영향**: 텀블러 케이스는 원래부터 "밀폐 지양, 방열판/액티브
  쿨러 필수"로 설계 문서(`README_ARCHITECTURE.md` 2.3)에 못 박아뒀는데, 이번 리뷰로
  그 필요성이 실측 근거로 확인된 셈. **패시브 방열판만으론 부족할 가능성이 높고,
  액티브 쿨링팬이 사실상 필수**로 봐야 함.
- **대응**: 구매 시 팬 포함 케이스/쿨러 키트를 같이 구매할 것. 텀블러 마운트
  설계(`hardware/tumbler_mount_design.md`)에 통풍/팬 공간을 반드시 반영.

### 🟡 OS/커뮤니티 지원이 아직 성숙하지 않음
- 공식 Armbian 프로젝트에 커뮤니티 지원이 **막 추가되는 단계**
  ([PR #9967](https://github.com/armbian/build/pull/9967), 2026년 기준 진행 중).
- 대신 서드파티 커뮤니티 이미지가 있음: [jonas5/orangepi-4pro-armbian](https://github.com/jonas5/orangepi-4pro-armbian)
  (Allwinner A733/sun60iw2용 Armbian 이미지, mainline 커널 기반).
- **✅ 확정 (2026-09-16, 공식 User Manual v1.4 확인)**: Orange Pi 벤더 자체 공식
  이미지가 실제로 존재하며 **Ubuntu, Debian, Android13을 공식 지원**한다
  (`hardware/datasheets/orange_pi_4_pro_user_manual_v1.4.pdf` 1.4절). ROS2
  Humble이 요구하는 **Ubuntu 22.04(Jammy)** 이미지도 공식 지원 목록에 있음
  (매뉴얼 3.30.2절 "Ubuntu Jammy system" 테스트 섹션 존재로 확인) — **라즈베리파이
  전용 OS 이미지는 이 보드에서 아예 부팅 안 됨(부트로더/커널 불일치), 반드시
  orangepi.net에서 이 보드 전용으로 빌드된 이미지를 받을 것.**
- **의미**: 라즈베리파이처럼 "공식 이미지 굽고 바로 씀" 수준의 매끄러움은 기대하기
  어려울 수 있으나, 벤더 공식 Ubuntu Jammy 이미지가 있다는 게 확인됐으니 커뮤니티
  Armbian 이미지에 의존할 필요는 없어짐(1순위: 벤더 공식, 2순위: Armbian).
- **다행인 점**: 우리 아키텍처는 애초에 Docker 기반이라, 호스트가 정확히 Ubuntu든
  Debian이든 상관없다 — **호스트 커널이 Docker/overlayfs/cgroup을
  지원하기만 하면 ROS2/slam_toolbox는 전부 컨테이너 안에서 그대로 동작**한다.
  이게 애초에 이 프로젝트를 Docker로 설계한 이유이고, 보드 교체 리스크를 크게 줄여준다.

### 🟢 부팅 매체 — microSD 필수 (USB 부팅 불가, 2026-09-16 확인)
공식 매뉴얼 기준 지원 부팅 매체는 **microSD / eMMC(별도 모듈) / M.2 NVMe SSD**
3가지뿐 — 일반 USB 부팅(라이브 스틱 등)은 지원 안 함. USB 포트는 OS 설치와
무관하고 PC↔보드 간 eMMC 굽기/adb 디버깅 용도로만 쓰인다. eMMC/NVMe 모듈을
따로 사지 않은 지금 상태에선 **microSD가 사실상 필수** — SanDisk 32GB 구매
완료(`hardware/accessories_purchase_log.md`).

## 1.5 전원 — 오히려 유리한 점 (2026-09-08 확인)
스펙상 **USB-C, 5V/3A(15W)** 입력. 사용자가 "보조배터리로 되냐"고 물어봐서 확인함:

- **일반 고속충전 보조배터리로 충분할 가능성이 높음** — 요즘 스마트폰 고속충전용
  보조배터리는 5V/2~3A 정도는 기본 지원하는 경우가 많음.
- **비교 참고**: Raspberry Pi 5는 공식적으로 **5V/5A(25W)**를 요구해서 전용 충전기가
  아니면 저전력 경고가 뜨거나 성능이 제한되는 걸로 유명함. Orange Pi 4 Pro는
  요구치가 더 낮아서(15W) **휴대용 보조배터리 호환성 면에서 오히려 유리**.
- **확인할 것**: 보조배터리 스펙에 "5V⎓3A" 또는 "15W" 이상 출력이 명시돼 있는지,
  케이블도 3A를 버티는지(저가 케이블은 못 버티는 경우 있음) — 구매 전 반드시 확인.
- 다만 이건 "오렌지파이라서 좋은 것"이 아니라 **이 특정 모델의 전력 요구치가
  낮은 것**뿐이다. USB-C 전원 방식 자체는 Pi5도 동일.

## 2. "통신 문제"(Wi-Fi) — 우려보다는 괜찮아 보임
보드의 Wi-Fi 6 + BT 5.4 모듈은 **AIC8800 칩셋**으로 확인되고, 커뮤니티 Armbian
이미지에 이 칩셋용 펌웨어 파일이 이미 포함되어 있는 것으로 확인됨. 즉 완전히
생소한 미지원 칩이 아니라, 이미 리눅스 드라이버/펌웨어 경로가 마련된 칩셋이다.

- **의미**: Wi-Fi 자체가 아예 안 잡히는 최악의 상황일 가능성은 낮아 보임.
- **단, 조건이 있음**: 반드시 이 보드 전용으로 빌드된 이미지(벤더 공식 또는
  jonas5의 Armbian)를 써야 한다 — 일반 범용 Ubuntu ARM 이미지를 그냥 구워서 쓰면
  Wi-Fi가 안 잡힐 가능성이 높다.
- 최악의 경우 대안: 보드에 **기가비트 이더넷**도 있으니, Wi-Fi가 문제되면 유선으로
  개발/디버깅하고 Wi-Fi 이슈는 나중에 별도로 해결하는 것도 가능.

## 3. USB(RPLIDAR 연결) 안정성 — 확인 안 됨, 도착 즉시 최우선 테스트
검색으로 이 보드 특유의 USB 전원/컨트롤러 문제 보고는 찾지 못했다. 즉 **알려진
문제가 없다는 것이지, 검증됐다는 뜻은 아니다.** 저가 SBC 일반적으로 USB 5V 레일
전류 공급이 빡빡한 경우가 종종 있어서, 실측 전까지는 미지수로 남겨둔다.

- **도착 즉시 첫 번째로 할 일**: PC에서 했던 것과 동일하게, RPLIDAR C1을 USB로
  연결하고 `rplidar_probe` 방식(GET_INFO 프로토콜 응답 확인)으로 정상 통신되는지
  가장 먼저 검증. 이 프로젝트 PC 개발 초기에 했던 것과 완전히 동일한 절차라
  재사용 가능.

## 4. Docker 구동 자체
벤더 BSP 커널이 6.6 기반으로 확인되어(비교적 최신), Docker/containerd 구동에
필요한 커널 기능(overlayfs, cgroups)은 문제없을 것으로 예상. 이 부분은 리스크가
낮다고 판단.

## 5. 상세 설정 절차 (예상 — 도착 후 실측 명령어로 갱신할 것)

아래는 Armbian/일반 SBC 관례 기준으로 미리 적어두는 예상 절차다. **정확한 명령은
실제 이미지를 받아봐야 확정되며, 도착 후 이 문서를 실측 내용으로 덮어쓸 것.**

### 5.1 OS 이미지 설치
1. 이미지 다운로드: 벤더 공식 이미지(구매 페이지/orangepi.org 다운로드 섹션) 또는
   커뮤니티 [jonas5/orangepi-4pro-armbian](https://github.com/jonas5/orangepi-4pro-armbian) 릴리즈 중 선택.
   - 헤드리스(디스플레이 없이 서버 용도)로만 쓸 거라 GUI 없는 "server/minimal" 이미지가 적합.
2. eMMC가 있으면 eMMC로 굽는 게 SD카드보다 안정적(전원 순간 끊김에 덜 취약).
   없으면 SD카드에 `balenaEtcher` 또는 `dd`로 굽기.
3. 최초 부팅 후 기본 계정/비밀번호 변경, `raspi-config` 격인 `armbian-config`
   (또는 벤더 자체 설정 툴)로 로케일/타임존 설정.

### 5.2 네트워크 & SSH
1. 유선(기가비트 이더넷)으로 먼저 붙여서 원격 SSH 접속 확보 — Wi-Fi가 바로 안
   잡힐 가능성(1.5번/2번 리스크)에 대비해 유선을 1순위로.
2. Wi-Fi는 `nmcli` 또는 `armbian-config` → Network 메뉴로 SSID/비번 등록.
3. `ssh-copy-id`로 이 PC(또는 노트북)에서 키 기반 접속 등록 — 매번 비번 입력 안 해도 되게.

### 5.3 Docker 설치
```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER   # dialout 그룹도 같이: sudo usermod -aG dialout $USER
# 재로그인 후 확인
docker run hello-world
```

### 5.4 프로젝트 이식
```bash
git clone git@github.com:greenhelix/PortableLidarMapper.git
cd PortableLidarMapper
./docker/run_dev.sh --build --with-lidar
```
`ros:humble-ros-base` 등 우리가 쓰는 베이스 이미지들은 공식적으로 arm64 빌드를
제공하므로, **`docker build` 명령 자체는 코드 수정 없이 그대로 실행되는 게
정상**이다. 여기서 에러가 나면 그게 이 이식 과정의 핵심 검증 실패 지점.

### 5.5 GPIO/I2C 핀맵 — 확정됨 (2026-09-16, 공식 User Manual v1.4 확인)
`hardware/datasheets/orange_pi_4_pro_user_manual_v1.4.pdf` 3.15절("40 Pin
Interface Pin Description")에서 확인:

- 40핀 중 **GPIO 28개 사용 가능, 전부 3.3V 로직**(5V 아님 — IMU/버튼 배선 시
  반드시 3.3V 핀에서 전원을 따야 함, 5V 핀에 물리면 레벨 미스매치 위험)
- **I2C0**: SDA = 물리핀 3번, SCL = 물리핀 5번 — IMU(BNO055/CJMCU-055) 연결에
  바로 사용
- **여유 GPIO(버튼용 후보)**: PD0(29번), PD1(31번), PD2(33번), PD3(35번),
  PD4(37번) 등 다수 — 0.7번(물리 시작/정지 버튼) 배선 시 이 중 하나 사용
- **wiringOP가 이미지에 사전 설치되어 있음** — 별도 컴파일 없이 `gpio readall`
  명령으로 바로 핀 상태 확인 가능
- I2C/SPI 커널 오버레이 활성화 여부는 `gpio readall` 결과로 판단(이미 활성화된
  상태로 보임, wiringOP 프리인스톨 자체가 그 근거) — 실기 도착 후 실제 명령
  실행으로 최종 확인

### 5.6 발열 모니터링 — 공식 명령 확인됨 (2026-09-16, User Manual 3.14절)
A733에 온도 센서 5개 내장, 공식 확인된 명령:
```bash
# CPU 리틀코어(A55)
cat /sys/class/thermal/thermal_zone0/temp   # cpul, 단위: milli-°C, 1000으로 나눠서 °C
# CPU 빅코어(A76)
cat /sys/class/thermal/thermal_zone1/temp   # cpub
# GPU
cat /sys/class/thermal/thermal_zone4/temp
# NPU
cat /sys/class/thermal/thermal_zone5/temp
# DDR(메모리)
cat /sys/class/thermal/thermal_zone6/temp
```
slam_toolbox 부하 테스트 중 이 값들(특히 cpul/cpub)을 `watch -n1`으로 계속
관찰해서 90°C 근처까지 가는지 확인. 쓰로틀링 여부는 `dmesg | grep -i throttl`로
확인(Armbian 전용 `armbianmonitor`는 벤더 공식 이미지에선 없을 수 있음 — 위
공식 경로가 더 확실함).

## 6. 요약 — 예상 체크리스트 (도착 후 순서대로 검증)

### 6.0 실행 순서 확정 (2026-09-17, microSD 도착 즉시 진행)
1. [ ] **microSD 도착 → Orange Pi 세팅 시작**: Ubuntu(Jammy 22.04, ROS2 Humble
   호환) 공식 이미지 설치, 기본 기능(부팅/SSH/네트워크) 파악, **전원 확인**
   (5V/3A 보조배터리 출력 확인 — 1.5번 참고)
2. [ ] **RPLIDAR C1을 Orange Pi에 연결 확인** (USB, PC 때와 동일 절차로 프로토콜
   응답 확인)
3. [ ] **IMU(CJMCU-055)를 Orange Pi에 연결 확인** (I2C, 물리핀 1/3/5/6 —
   `devlog`의 IMU 배선도 참고)
4. [ ] **보조배터리 전원으로 Orange Pi 정상 작동 확인** (벽전원 대신 배터리로
   구동했을 때 이상 없는지)

이후 아래 6.1번(상세 체크리스트)으로 진행.

### 6.1 상세 체크리스트
0. [ ] **(구매 전)** 보유 중이거나 살 보조배터리가 5V/3A(15W) 이상 출력, 케이블도
   3A 대응인지 확인 — 위 1.5번 참고
1. [ ] 벤더 공식 이미지 vs jonas5 커뮤니티 Armbian 이미지 중 선택, 설치
   (2026-09-16 확인: 벤더 공식 Ubuntu Jammy 이미지 존재 — 이걸 1순위로)
2. [ ] Docker 설치 및 `docker run hello-world` 확인
3. [ ] RPLIDAR C1 USB 연결 → 프로토콜 응답 확인 (PC 때와 동일 절차)
4. [ ] 이 프로젝트의 `docker/Dockerfile`을 arm64로 빌드 (별도 코드 수정 없이 되는지가 핵심 검증 포인트)
5. [ ] Wi-Fi 연결 테스트 (안 되면 이더넷으로 우회)
6. [ ] 부하 테스트(slam_toolbox 실행) 중 온도 모니터링 (`cat /sys/class/thermal/thermal_zone{0,1}/temp`) → 쓰로틀링 여부 확인, 필요시 쿨링 보강
