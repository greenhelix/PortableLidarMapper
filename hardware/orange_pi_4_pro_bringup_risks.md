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
- Orange Pi 벤더 자체 공식 이미지도 별도로 존재할 것으로 예상(구매 페이지에서 확인 필요).
- **의미**: 라즈베리파이처럼 "공식 이미지 굽고 바로 씀" 수준의 매끄러움은 기대하기
  어려움. 이미지 선택(벤더 공식 vs 커뮤니티 Armbian)과 세팅에 추가 시간이 들 것으로 예상.
- **다행인 점**: 우리 아키텍처는 애초에 Docker 기반이라, 호스트가 정확히 Ubuntu든
  Debian(Armbian 기본은 Debian Trixie)이든 상관없다 — **호스트 커널이 Docker/overlayfs/cgroup을
  지원하기만 하면 ROS2/slam_toolbox는 전부 컨테이너 안에서 그대로 동작**한다.
  이게 애초에 이 프로젝트를 Docker로 설계한 이유이고, 보드 교체 리스크를 크게 줄여준다.

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

### 5.5 GPIO/I2C 활성화 (향후 IMU용, 지금 당장은 불필요)
Armbian 계열은 보통 `armbian-config` → System → Hardware 메뉴에서 I2C/SPI overlay를
켜거나, `/boot/orangepiEnv.txt`(또는 동급 설정 파일)에 `overlays=i2c0` 같은 줄을
추가하는 방식이다. **정확한 GPIO 핀 번호/오버레이 이름은 보드 실물의 핀아웃
문서를 봐야 확정** — 지금은 추측하지 않고, 도착 후 벤더 핀아웃 문서로 채울 것.

### 5.6 발열 모니터링
```bash
# Armbian
armbianmonitor -m
# 또는 범용
watch -n1 cat /sys/class/thermal/thermal_zone0/temp   # 단위: milli-°C
```
slam_toolbox 부하 테스트 중 이 값을 계속 관찰해서 90°C 근처까지 가는지, 쓰로틀링
표시(`vcgencmd get_throttled`는 라즈베리파이 전용이라 안 됨 — Armbian은
`armbianmonitor -m`의 throttling 표시나 `dmesg | grep -i throttl`로 확인)가
뜨는지 확인.

## 6. 요약 — 예상 체크리스트 (도착 후 순서대로 검증)
0. [ ] **(구매 전)** 보유 중이거나 살 보조배터리가 5V/3A(15W) 이상 출력, 케이블도
   3A 대응인지 확인 — 위 1.5번 참고
1. [ ] 벤더 공식 이미지 vs jonas5 커뮤니티 Armbian 이미지 중 선택, 설치
2. [ ] Docker 설치 및 `docker run hello-world` 확인
3. [ ] RPLIDAR C1 USB 연결 → 프로토콜 응답 확인 (PC 때와 동일 절차)
4. [ ] 이 프로젝트의 `docker/Dockerfile`을 arm64로 빌드 (별도 코드 수정 없이 되는지가 핵심 검증 포인트)
5. [ ] Wi-Fi 연결 테스트 (안 되면 이더넷으로 우회)
6. [ ] 부하 테스트(slam_toolbox 실행) 중 온도 모니터링 (`vcgencmd`/`cat /sys/class/thermal/...`) → 쓰로틀링 여부 확인, 필요시 쿨링 보강
