// ============================================================
// Portable LiDAR Mapper — 텀블러형 쉘 v1 (사용자 스케치 #1~#4 기반)
// 구조(위→아래): 라이다(C1) 상단 마운트 → 바로 밑 IMU+미니브레드보드 →
//   본체 쉘 내부에 Orange Pi 4 Pro → 최하단 보조배터리
// 사용법: OpenSCAD(openscad.org) F5 미리보기 → F6 렌더링 → STL export
// ============================================================

$fn = 64;

// ---------- 실측 확정값 ----------
lidar_diameter     = 75;    // RPLIDAR C1 지름
lidar_hole_spacing = 43;    // M2.5 x 4, 43x43mm 정사각 배치 (공식 datasheet)
lidar_hole_dia     = 2.9;   // M2.5 클리어런스
lidar_max_screw_depth = 4;  // 나사 삽입 깊이 4mm 초과 금지(공식 경고)

board_length = 89;   // Orange Pi 4 Pro
board_width  = 56;

// ---------- 추정치 (실측 필요 — 스케치에 물음표로 표시된 항목 포함) ----------
imu_length         = 25;   // CJMCU-055 크기 추정
imu_width          = 20;
imu_hole_spacing_x = 18;
imu_hole_spacing_y = 13;
imu_hole_dia       = 2.2;  // M2

breadboard_length  = 47;   // SYB-170 미니 브레드보드 추정치(일반적 규격) — 실측 권장
breadboard_width   = 35;
breadboard_height  = 9;

board_thickness    = 20;   // Orange Pi 커넥터 돌출부 포함 추정
battery_capacity_note = "3000mAh? — 스케치에 물음표, 실물 확인 필요";
battery_length     = 70;   // 배터리 실물 미확정 — 추정치(스케치는 소형 배터리로 보임)
battery_width      = 50;
battery_thickness  = 20;

shell_diameter     = 80;   // 라이다(75) 기준 여유 5mm — 이전 텀블러 검토(⌀70~90mm)와 일치
wall               = 2.5;  // 쉘 벽 두께

// 내부 배치 높이 계산 (아래→위 순서로 스택)
battery_z   = wall + 5;
board_z     = battery_z + battery_thickness + 10;   // 배터리 위 10mm 간격
imu_z       = board_z + board_thickness + 10;       // 보드 위 10mm 간격 (IMU+브레드보드 구역)
cap_z       = imu_z + breadboard_height + 8;         // 그 위가 상단 캡(라이다 마운트)
shell_height = cap_z + 5;

// ================= 쉘 본체 (원통, 바닥 막힘 + 상단 개방) =================
module shell_body() {
    color("lightgray", 0.35)
    difference() {
        cylinder(h = shell_height, d = shell_diameter);
        translate([0, 0, wall])
            cylinder(h = shell_height, d = shell_diameter - wall*2);
    }
}

// ================= 배터리 베이 (최하단) =================
module battery_slot() {
    color("SaddleBrown", 0.5)
    translate([-battery_length/2, -battery_width/2, battery_z])
        cube([battery_length, battery_width, battery_thickness]);
}

// ================= Orange Pi 보드 슬롯 (중단, 세로로 세워 배치) =================
// 이전 검토(⌀70~90mm 텀블러에 89x56mm 보드 "세로로 세우면" 들어감)와 동일 원리 —
// 여기선 폭(56mm)이 쉘 지름 방향, 길이(89mm)가 세로(Z) 방향
module orange_pi_slot() {
    color("green", 0.4)
    translate([-board_width/2, -board_thickness/2, board_z])
        cube([board_width, board_thickness, board_length]);

    // 고정용 내부 레일 2개(양옆에서 보드를 슬라이드 삽입하는 가이드)
    color("gray")
    for (x = [-1, 1])
        translate([x*(board_width/2 + 1), -board_thickness/2 - 2, board_z])
            cube([3, board_thickness + 4, board_length]);
}

// ================= 상단 캡: 라이다 + IMU + 미니 브레드보드 =================
module top_cap() {
    // 캡 판
    color("purple")
    difference() {
        cylinder(h = wall, d = shell_diameter);
        // 라이다 마운트 나사구멍 4개
        for (x = [-1, 1], y = [-1, 1])
            translate([x*lidar_hole_spacing/2, y*lidar_hole_spacing/2, -1])
                cylinder(h = wall+2, d = lidar_hole_dia);
    }

    // 라이다 자리(참고용, 인쇄 대상 아님) — 캡 위에 얹힘
    color("orange", 0.25)
    translate([0, 0, wall])
        cylinder(h = 40, d = lidar_diameter); // 40mm는 C1 높이 추정, 실측 필요

    // IMU — 라이다 중심 바로 아래(캡 밑면)에 동축 배치 (2026-09-16 결정: EKF 오차 최소화)
    color("cyan", 0.4)
    translate([-imu_length/2, -imu_width/2, -8])
        cube([imu_length, imu_width, 8]);

    // 미니 브레드보드 — IMU 옆 공간에 배치 (쉘 내부 상단부)
    color("SkyBlue", 0.4)
    translate([imu_length/2 + 5, -breadboard_width/2, -breadboard_height - 2])
        cube([breadboard_length, breadboard_width, breadboard_height]);
}

// ================= 조립 미리보기 =================
shell_body();
battery_slot();
orange_pi_slot();
translate([0, 0, shell_height]) top_cap();

// ================= 참고: 케이블 경로 (스케치 #3,4의 USB/power 선) =================
// IMU → Orange Pi: 짧은 점퍼선 4가닥(3.3V/GND/SDA/SCL), 캡 밑면에서 보드까지
// Orange Pi → Battery: USB 케이블(전원), 보드 하단에서 배터리까지
// 실제 배선 경로는 쉘 내부 벽면을 따라 여유 공간에 자유 배치 — 별도 채널 불필요
// (내경이 board_width+battery_width보다 넉넉하면 배선 공간 충분)
