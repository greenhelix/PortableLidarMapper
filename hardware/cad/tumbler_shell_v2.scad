// ============================================================
// Portable LiDAR Mapper — 텀블러형 쉘 v2 + 어깨끈 마운트 비교 (2026-09-16)
// 색상 규칙: 검정 = 실제 기기(라이다/IMU/브레드보드), 보라 = 3D프린팅부(PETG),
//           초록 = Orange Pi/배터리
// 변경점(v1 대비):
//   - 라이다 마운트 구멍을 카운터싱크(접시머리 나사 대응)로 변경
//   - RPLIDAR C1 실측 형상(사각 베이스+원형 상부) 추가, 검정
//   - 미니브레드보드(45x35x9, SYB-170 실측)+IMU(20x20, CJMCU-055 실측) 스택 추가
//   - 상단을 "평탄화 판 2장 사이에 기기 샌드위치" 구조로 변경
//   - 배터리를 표준 파워뱅크(3000~10000mAh) 크기로 파라미터화, 초록색
//   - 어깨끈형(GoPro 스트랩 마운트) 버전을 옆에 나란히 배치
// ============================================================

$fn = 64;

// ================= 치수 라벨 헬퍼 (설계도처럼 표시용, 인쇄 대상 아님) =================
module dim_label(txt, size=4) {
    color("red")
    linear_extrude(height = 0.5)
        text(txt, size = size, halign = "center", valign = "center", font = "Liberation Sans:style=Bold");
}

// ---------- 실측 확정값 / 정정 (2026-09-16) ----------
// ⚠️ 기존 75mm는 공식 datasheet 근거가 아니었음(도면엔 사각 베이스+높이만
// 명시, 원형부 지름은 숫자로 없음) — 사각 베이스(55.6mm)와 비례가 맞는
// 58mm로 임시 수정. 실물 도착 후 캘리퍼스로 재측정 필수.
lidar_diameter     = 58;
lidar_base_square  = 55.6;   // RPLIDAR C1 사각 베이스 한 변 (공식 datasheet)
lidar_total_height = 41.3;   // 공식 datasheet 총 높이
lidar_base_height  = 15;     // 사각 베이스부 높이(도면 비례 추정, 실측 재확인 권장)
lidar_hole_spacing = 43;
lidar_hole_dia     = 2.9;    // M2.5 클리어런스
lidar_countersink_dia = 5.5; // 접시머리 나사 헤드 지름(M2.5 플랫헤드 일반 규격 추정)
lidar_max_screw_depth = 4;

imu_size           = 20;     // CJMCU-055 실측 20x20mm
imu_pcb_thickness  = 1.6;
imu_component_h    = 3;      // 칩/부품 높이 여유

breadboard_length  = 45;     // SYB-170 실측
breadboard_width   = 35;
breadboard_height  = 9;

pin_header_gap     = 8;      // IMU가 브레드보드에 핀헤더로 꽂힐 때 뜨는 높이

board_length = 89;   // Orange Pi 4 Pro
board_width  = 56;
board_thickness = 20;

// ---------- 배터리: 표준 파워뱅크 범위(3000~10000mAh) 대표값 ----------
// 3000mAh 슬림형 ~ 10000mAh 일반형까지 폭이 넓어, 중간~10000mAh 기준 실사용
// 제품에 흔한 크기로 대표값 설정(추정 — 실물 구매 후 갱신)
battery_length     = 100;
battery_width      = 65;
battery_thickness  = 18;

wall = 2.5;

// ================= 카운터싱크 나사구멍 모듈 (재사용) =================
module countersunk_hole(depth) {
    cylinder(h = depth+2, d = lidar_hole_dia);
    translate([0, 0, depth - 1.5])
        cylinder(h = 2, d1 = lidar_hole_dia, d2 = lidar_countersink_dia);
}

// ================= RPLIDAR C1 실제 형상 (검정, 참고용 — 인쇄 대상 아님) =================
module rplidar_c1() {
    color("black") {
        // 사각 베이스
        translate([-lidar_base_square/2, -lidar_base_square/2, 0])
            cube([lidar_base_square, lidar_base_square, lidar_base_height]);
        // 원형 상부(광학부)
        translate([0, 0, lidar_base_height])
            cylinder(h = lidar_total_height - lidar_base_height, d = lidar_diameter);
    }
}

// ================= 브레드보드 + IMU 스택 (검정) =================
module breadboard_imu_stack() {
    color("black") {
        // 미니 브레드보드
        translate([-breadboard_length/2, -breadboard_width/2, 0])
            cube([breadboard_length, breadboard_width, breadboard_height]);
        // IMU — 브레드보드 위에 바로 밀착(2026-09-16: 붙어있게 수정, 핀헤더 뜬 간격 제거)
        translate([-imu_size/2, -breadboard_width/2 + 3, breadboard_height])
            cube([imu_size, imu_size, imu_pcb_thickness + imu_component_h]);
    }
}

// ================= 평탄화 판 2장 (보라, PETG) — 기기를 사이에 샌드위치 =================
plate_gap = lidar_base_height + 4; // 두 판 사이 간격(라이다 베이스+여유)

module flatten_plate(d) {
    color("purple")
    difference() {
        cylinder(h = wall, d = d);
        for (x = [-1, 1], y = [-1, 1])
            translate([x*lidar_hole_spacing/2, y*lidar_hole_spacing/2, -1])
                countersunk_hole(wall);
    }
    // 치수 라벨: 판 두께, 나사구멍 간격
    translate([0, d/2 - 8, wall + 0.5]) dim_label(str("t=", wall, "mm"), 3.5);
    translate([lidar_hole_spacing/2, 0, wall + 0.5]) dim_label(str(lidar_hole_spacing, "x", lidar_hole_spacing), 3);
}

module top_assembly(shell_d) {
    // 하단 평탄화 판(브레드보드+IMU가 이 위에 얹힘)
    flatten_plate(shell_d);
    translate([0, 0, wall]) breadboard_imu_stack();

    // 스탠드오프 4개 (보라)
    color("purple")
    for (x = [-1, 1], y = [-1, 1])
        translate([x*lidar_hole_spacing/2, y*lidar_hole_spacing/2, wall])
            cylinder(h = plate_gap, d = lidar_hole_dia + 4);

    // 상단 평탄화 판(라이다가 이 위에 얹힘)
    translate([0, 0, wall + plate_gap]) {
        flatten_plate(shell_d);
        translate([0, 0, wall]) rplidar_c1();
    }
}

// ================= 옵션 1: 텀블러 쉘 =================
shell_diameter = 80;
// 배터리(100)+간격(10)+Orange Pi(89)+여유(15) 세로 스택 기준 재계산
shell_body_height = battery_length + 10 + board_length + 15;

module tumbler_variant() {
    // 쉘 본체 — 2026-09-16 재수정: color() 알파값이 뷰어에 따라 무시되는
    // 문제가 있어, OpenSCAD 표준 "배경(참고용) 투명" 표기인 % modifier로 변경.
    // 이러면 뷰어/렌더 방식과 무관하게 항상 회색 반투명으로 표시됨.
    %difference() {
        cylinder(h = shell_body_height, d = shell_diameter);
        translate([0, 0, wall])
            cylinder(h = shell_body_height, d = shell_diameter - wall*2);
    }
    // 치수 라벨: 쉘 지름/높이/벽두께
    translate([shell_diameter/2 + 12, 0, shell_body_height/2])
        rotate([90,0,90]) dim_label(str("H", shell_body_height, "mm"), 6);
    translate([0, shell_diameter/2 + 12, 10])
        dim_label(str("t", wall, "mm (벽두께)"), 4);
    translate([0, -(shell_diameter/2 + 12), 10])
        dim_label(str("⌀", shell_diameter, "mm"), 5);

    // 배터리 (초록, 최하단, 완전 불투명 — 쉘 투명화로 내부 부품이 잘 보이게)
    // 2026-09-16 버그 수정: 눕혀서 배치하면 대각선 116mm로 쉘 내경(~75mm)을
    // 뚫고 나옴 → Orange Pi처럼 세로로 세워서 배치(65x18 대각선 ~67mm로 내경
    // 안에 들어감). 단, 세로로 세우면 배터리 길이(100mm)만큼 전체 높이가
    // 늘어남 — 큰 배터리(10000mAh)를 쓰려면 쉘 지름을 키워야 함.
    color("green", 0.6)
    translate([-battery_width/2, -battery_thickness/2, wall + 5])
        cube([battery_width, battery_thickness, battery_length]);
    translate([shell_diameter/2 - 5, 0, wall + 5 + battery_length/2])
        rotate([90,0,90]) dim_label(str(battery_width,"x",battery_thickness,"x",battery_length), 4);

    // Orange Pi (초록, 배터리 위 세로 배치 — 색상/투명도 원복, 쉘만 투명화)
    color("green", 0.6)
    translate([-board_width/2, -board_thickness/2, wall + 5 + battery_length + 10])
        cube([board_width, board_thickness, board_length]);
    translate([shell_diameter/2 - 5, 0, wall + 5 + battery_length + 10 + board_length/2])
        rotate([90,0,90]) dim_label(str(board_width,"x",board_thickness,"x",board_length), 4);

    // 상단 평탄화 판 2장 + 라이다/IMU/브레드보드
    translate([0, 0, shell_body_height]) top_assembly(shell_diameter);
}

// ================= 옵션 2: 어깨끈형(GoPro 스트랩 마운트) =================
gopro_tab_width   = 25.4;
gopro_tab_height  = 18;
gopro_prong_thick = 4.5;
gopro_hole_dia    = 5.5;

// 2026-09-16 재수정: (1) 구멍이 프롱 사이 빈 공간을 뚫던 버그 → 두 프롱을
// 실제로 가로지르는 X방향으로 수정. (2) 프롱 위쪽에 사진처럼 둥근 돔 형태
// 추가. (3) female(암컷) 쪽도 "홈 2곳"으로 다시 모델링 — 이전에 넣었던
// 볼조인트/엉뚱한 위치의 나사는 전부 제거하고, 우리 프롱이 정확히 끼워지는
// 슬롯 2개 + 그 자리를 그대로 관통하는 나사 1개로 재구성.
module gopro_prong_rounded(w, d, h) {
    // 몸통(각기둥) + 위쪽 돔(구형 캡)을 hull로 이어붙여 둥근 형태로
    hull() {
        linear_extrude(height = h - w/2)
            translate([0, d/2])
                offset(r = w/3) offset(delta = -w/3)
                    square([w, d], center = true);
        translate([0, d/2, h - w/2])
            sphere(d = w, $fn = 24);
    }
}

module gopro_male_tab() {
    color("purple")
    difference() {
        union() {
            translate([-gopro_tab_width/2 + gopro_prong_thick/2, 0, 0])
                gopro_prong_rounded(gopro_prong_thick, 12, gopro_tab_height);
            translate([gopro_tab_width/2 - gopro_prong_thick/2, 0, 0])
                gopro_prong_rounded(gopro_prong_thick, 12, gopro_tab_height);
            // 베이스(발판) — 둥근 모서리
            translate([0, 6, 1.5])
                linear_extrude(height = 3, center = true)
                    offset(r=3) offset(delta=-3)
                        square([gopro_tab_width, 12], center = true);
        }
        // 관통 구멍 — 양쪽 프롱을 실제로 가로지름 (X축 방향), 나사 위치는
        // 여기 한 곳뿐 — female 슬롯에 끼운 뒤 이 구멍을 그대로 관통시킴
        translate([0, 6, gopro_tab_height/2])
            rotate([0, 90, 0])
                cylinder(h = gopro_tab_width + 4, d = gopro_hole_dia, center = true);
    }
}

// female(암컷) 리시버 — 우리 프롱 2개가 정확히 들어갈 홈 2곳을 판 것.
// 프롱과 같은 로컬 좌표계(y:0~12, z:0~tab_height)에 그대로 겹쳐서
// "완전히 끼워진 상태"를 표현 — 상용 구매품이라 인쇄 대상 아님, 참고용.
module female_receiver() {
    color("gray", 0.55)
    difference() {
        translate([-(gopro_tab_width/2 + 4), 0, -2])
            cube([gopro_tab_width + 8, 12, gopro_tab_height]);
        // 홈(슬롯) 2곳 — 우리 프롱이 끼워지는 자리, 여유 0.4mm
        translate([-gopro_tab_width/2 + gopro_prong_thick/2, 0, -3])
            gopro_prong_rounded(gopro_prong_thick + 0.4, 13, gopro_tab_height + 4);
        translate([gopro_tab_width/2 - gopro_prong_thick/2, 0, -3])
            gopro_prong_rounded(gopro_prong_thick + 0.4, 13, gopro_tab_height + 4);
        // 관통 구멍 — 남자 탭 구멍과 정확히 같은 축(x방향, y=6, z=tab_height/2)
        translate([0, 6, gopro_tab_height/2])
            rotate([0, 90, 0])
                cylinder(h = gopro_tab_width + 20, d = gopro_hole_dia + 0.3, center = true);
    }
}

// 커넥터 전체(수컷 탭 + female 홈 + 관통 나사) — 전부 같은 로컬 좌표계라
// 나사가 항상 프롱을 정확히 관통한 위치에 오도록 보장됨
module connector_assembly() {
    gopro_male_tab();
    female_receiver();
    // 고정 나사(볼트) — 프롱+female을 실제로 관통하는 유일한 축
    color("silver")
    translate([0, 6, gopro_tab_height/2])
        rotate([0, 90, 0])
            cylinder(h = gopro_tab_width + 18, d = gopro_hole_dia - 0.3, center = true);
    // 너트(육각, 반대쪽 끝)
    color("silver")
    translate([gopro_tab_width/2 + 9, 6, gopro_tab_height/2])
        rotate([0, 90, 0])
            cylinder(h = 3, d = 9, $fn = 6);
    translate([gopro_tab_width/2 + 24, 6, gopro_tab_height/2])
        dim_label(str("나사(볼트+너트)\n프롱+female 관통\n⌀", gopro_hole_dia, "mm, 나사산X"), 2.2);
}

// 2026-09-16 재설계: 라이다+IMU/브레드보드를 나란히 놓도록 판을 넓히고,
// GoPro 탭은 판 "중앙" 바로 밑(마운트에 실제로 물리는 지점)에 위치시킴 —
// 지난번엔 탭이 한쪽으로 치우쳐서 중심이 안 맞았음.
module strap_mount_variant() {
    lidar_cx = -(breadboard_length/2 + 15);
    bb_cx    = (lidar_diameter/2 + 15);

    plate_length = (lidar_cx - lidar_diameter/2 - 10) * -2; // 좌우 대칭 여유 포함
    plate_width  = max(lidar_diameter, breadboard_width) + 20;

    // 평탄화 판 1장 (직사각형 — 라이다+IMU/브레드보드 나란히 배치)
    color("purple")
    difference() {
        translate([-plate_length/2, -plate_width/2, 0])
            linear_extrude(height = wall)
                offset(r=6) offset(delta=-6)
                    square([plate_length, plate_width]);
        for (x = [-1, 1], y = [-1, 1])
            translate([lidar_cx + x*lidar_hole_spacing/2, y*lidar_hole_spacing/2, -1])
                countersunk_hole(wall);
    }
    // 치수 라벨: 판 길이/폭/두께
    translate([0, plate_width/2 + 8, wall + 0.5])
        dim_label(str("판: ", round(plate_length), "x", round(plate_width), "x", wall, "mm"), 4);

    // 라이다 (검정, 판 위 왼쪽)
    translate([lidar_cx, 0, wall]) rplidar_c1();

    // 브레드보드+IMU (검정, 판 위 오른쪽 — 라이다 옆에 나란히, 스택 아님)
    translate([bb_cx, 0, wall]) breadboard_imu_stack();

    // 커넥터(수컷 탭+female 홈+관통나사, connector_assembly 안에서 서로
    // 정확히 정렬됨) — 판 "중앙" 밑면에 완전히 밀착 (2026-09-16 전면 재구성:
    // 볼조인트 제거, 나사가 허공이 아니라 실제 프롱을 관통하도록 수정)
    translate([0, -6, 0])
        rotate([180,0,0])
            connector_assembly();

    // 벨크로 패널(참고용, 인쇄 대상 아님 — 실제 구매품, female 버클이 이 위에 있음)
    color("dimgray", 0.5)
    translate([-45, -35, -gopro_tab_height - 15])
        cube([90, 60, 12]);
}

// ================= 배치: 텀블러(왼쪽) vs 어깨끈형(오른쪽) =================
tumbler_variant();
translate([250, 0, 0]) strap_mount_variant();
