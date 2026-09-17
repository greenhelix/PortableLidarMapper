// ============================================================
// Portable LiDAR Mapper — 상단 평판 + 오렌지파이/배터리 케이스 v1
// 가방을 뚫거나 개조하지 않음. 백팩 한정, 특정 가방 형태에 안 묶임.
//
// 구성:
//   1) mount_plate()  — 가방 상단 바깥면에 벨크로로 고정, 라이다+IMU 탑재
//   2) device_case()  — 오렌지파이+배터리, 가방 상단부 근처 주머니에 넣음
//      (별도 부품, 케이블로 mount_plate와 연결)
//
// 사용법: OpenSCAD(openscad.org)에서 열기 → F5 미리보기 → F6 렌더링 →
//   File > Export > Export as STL. 아래 변수만 실측값으로 바꾸면 됨.
//   두 부품은 따로 인쇄해야 하므로, 맨 아래 호출부에서 필요한 것만 주석 해제.
// ============================================================

$fn = 64;

// ================= 상단 평판 (mount_plate) =================

// ---------- 실측 확정값 (SLAMTEC 공식 datasheet, 2026-09-16 확인) ----------
lidar_diameter     = 75;   // RPLIDAR C1 지름
lidar_hole_spacing = 43;   // 라이다 마운트 나사 간격 43x43mm 정사각형 배치 (공식 datasheet)
lidar_screw_spec   = "M2.5"; // 나사 규격 — M3 아님, 주의
lidar_max_screw_depth = 4;   // ⚠️ 라이다 바닥으로 나사가 4mm 넘게 들어가면 내부 파손(공식 경고)
lidar_hole_dia     = 2.9;    // M2.5 나사용 여유구멍(클리어런스 홀)

// ---------- 추정치 (실측 필요) ----------
imu_length         = 25; // IMU 모듈 크기 — 아직 미구매, 임시값
imu_width          = 20;
imu_hole_spacing_x = 18;
imu_hole_spacing_y = 13;

mount_hole_dia    = lidar_hole_dia; // 하위 호환용 별칭 — 실제로는 M2.5 클리어런스
imu_hole_dia      = 2.2; // M2

// 2026-09-15 수정: IMU를 라이다와 나란히 두지 않고 라이다 풋프린트
// 중심(회전축) 바로 아래에 겹쳐서 배치 — EKF 센서퓨전 시 IMU-라이다 간
// 거리(모멘트암)가 짧을수록 오차가 줄어듦. 단, 라이다 실물 밑면에 이
// 크기의 IMU가 실제로 들어갈 공간이 있는지는 미확인 — 실물 도착 후
// 안 맞으면 imu_offset_x를 0이 아닌 값으로 바꿔서 옆으로 빼면 됨.
imu_offset_x      = 0;   // 0 = 라이다 중심과 동축, 안 맞으면 옆으로 이동

plate_length      = max(lidar_diameter, imu_length) + 40; // 평판 전체 길이
plate_width       = max(lidar_diameter, imu_width) + 30;  // 평판 전체 폭
plate_thickness   = 4;

velcro_strap_width = 20; // 사용할 벨크로 스트랩 폭 — 실측 필요
velcro_slot_w     = velcro_strap_width + 2;
velcro_slot_h     = 6;
velcro_slot_inset = 12;  // 평판 가장자리에서 슬롯까지 거리

module mount_plate() {
    color("purple")
    difference() {
        // 평판 본체 (모서리 둥글게)
        linear_extrude(height=plate_thickness)
            offset(r=6) offset(delta=-6)
                square([plate_length, plate_width], center=true);

        // 벨크로 스트랩 관통 슬롯 4개 (앞쪽 2개, 뒤쪽 2개 — 가방을 뚫지 않고
        // 스트랩을 평판 아래로 통과시켜 가방 상단을 감싸 고정하는 방식)
        for (x = [-1, 1])
            translate([x*(plate_length/2 - velcro_slot_inset), plate_width/2 - velcro_slot_h*1.5, -1])
                cube([velcro_slot_w, velcro_slot_h, plate_thickness+2], center=true);
        for (x = [-1, 1])
            translate([x*(plate_length/2 - velcro_slot_inset), -(plate_width/2 - velcro_slot_h*1.5), -1])
                cube([velcro_slot_w, velcro_slot_h, plate_thickness+2], center=true);

        // 라이다 마운트 나사구멍 4개 (평판 중심)
        for (x = [-1, 1], y = [-1, 1])
            translate([x*lidar_hole_spacing/2, y*lidar_hole_spacing/2, -1])
                cylinder(h=plate_thickness+2, d=mount_hole_dia);

        // IMU 마운트 나사구멍 4개 — 라이다와 동축(중심 겹침, imu_offset_x=0일 때)
        translate([imu_offset_x, 0, 0])
            for (x = [-1, 1], y = [-1, 1])
                translate([x*imu_hole_spacing_x/2, y*imu_hole_spacing_y/2, -1])
                    cylinder(h=plate_thickness+2, d=imu_hole_dia);

        // 케이블 인출 구멍 (평판 가장자리, 케이스로 내려가는 케이블용)
        translate([plate_length/2 - 8, 0, -1])
            cylinder(h=plate_thickness+2, d=8);
    }

    // 참고용 표시(인쇄 대상 아님): 라이다/IMU 풋프린트 — 겹쳐서 동축 배치 확인용
    color("orange", 0.25)
    translate([0, 0, plate_thickness])
        cylinder(h=1, d=lidar_diameter);
    color("cyan", 0.4)
    translate([imu_offset_x - imu_length/2, -imu_width/2, plate_thickness])
        cube([imu_length, imu_width, 1]);
}

// ================= 오렌지파이+배터리 케이스 (device_case) =================

// ---------- 실측 확정값 ----------
board_length = 89;  // Orange Pi 4 Pro (실측, hardware 문서 기준)
board_width  = 56;

// ---------- 추정치 (배터리 실물 치수 필요) ----------
board_thickness   = 20; // 보드+커넥터 돌출부 포함 추정
battery_length    = 95; // 보조배터리 추정치 — 반드시 실측 후 수정
battery_width     = 55;
battery_thickness = 25;

wall = 2.5;       // 케이스 벽 두께
clearance = 3;    // 부품-내벽 사이 여유 공간
lid_lip = 1.5;     // 뚜껑 결합부 높이

case_int_l = max(board_length, battery_length) + clearance*2;
case_int_w = max(board_width, battery_width) + clearance*2;
case_int_h = board_thickness + battery_thickness + clearance*3; // 보드 위에 배터리 스택

module device_case_body() {
    color("lightgray")
    difference() {
        // 외곽
        cube([case_int_l + wall*2, case_int_w + wall*2, case_int_h + wall], center=false);
        // 내부 공동
        translate([wall, wall, wall])
            cube([case_int_l, case_int_w, case_int_h + 1]);
        // 케이블 인출 구멍 (윗면, mount_plate로 올라가는 케이블용)
        translate([wall + case_int_l/2, wall + case_int_w/2, case_int_h + wall - 5])
            cylinder(h=10, d=8);
    }
}

module device_case_lid() {
    color("darkgray")
    translate([0, case_int_w + wall*2 + 10, 0])
    difference() {
        cube([case_int_l + wall*2, case_int_w + wall*2, wall*2], center=false);
        translate([wall + lid_lip, wall + lid_lip, -1])
            cube([case_int_l - lid_lip*2, case_int_w - lid_lip*2, wall+1]);
    }
}

// ================= 더미 가방 (참고용, 인쇄 대상 아님) =================
// 사용자 제공 사진(플랩탑 백팩, 상단 손잡이+양쪽 버클스트랩) 기준 대략적
// 형상. 실측 아님 — 사진 비례로 눈대중 추정. 실제 가방 스케치 받으면 갱신.

bag_width  = 300; // 가방 전체 폭
bag_depth  = 140; // 가방 두께
bag_height = 400; // 가방 높이(플랩 포함)
flap_height = 90; // 상단 플랩 높이
handle_gap = 30;  // 손잡이 폭

module dummy_backpack() {
    color("SaddleBrown", 0.35) {
        // 본체
        translate([-bag_width/2, -bag_depth/2, 0])
            cube([bag_width, bag_depth, bag_height - flap_height]);
        // 상단 플랩(앞쪽으로 살짝 기울어진 덮개)
        translate([-bag_width/2, -bag_depth/2, bag_height - flap_height])
            cube([bag_width, bag_depth, flap_height]);
        // 상단 손잡이(관통형 브라켓/벨크로가 걸리는 대상)
        translate([-handle_gap/2, 0, bag_height])
            rotate([90,0,0])
                cylinder(h=handle_gap, d=14);
    }
}

// ================= 집게형(스프링클립) 브라켓 =================
// 벨크로 대신/같이 쓸 수 있는 방식. 플랩 상단처럼 "판 모양 모서리"를
// 위아래로 물어서 고정 — PETG 자체 탄성으로 벌어졌다 오므라들어
// 별도 스프링 부품 없이 클립처럼 작동(3D 프린팅 스프링 클립의 표준 기법).

clamp_edge_thickness = 12; // 물릴 모서리(플랩 상단) 두께 — 실측 필요
clamp_jaw_depth      = 35; // 클립이 모서리를 물고 들어가는 깊이
clamp_width          = 60; // 클립 폭(평판 부착면 폭)
clamp_wall           = 3;  // 클립 벽 두께(탄성 확보 위해 얇게)
clamp_gap_margin     = -1.5; // 음수: 살짝 좁게 만들어서 끼울 때 압착되며 고정(억지끼움)

module flex_clamp_bracket() {
    color("purple")
    difference() {
        union() {
            // 위쪽 조(jaw)
            translate([-clamp_width/2, 0, clamp_edge_thickness + clamp_gap_margin])
                cube([clamp_width, clamp_jaw_depth, clamp_wall]);
            // 아래쪽 조(jaw)
            translate([-clamp_width/2, 0, -clamp_wall])
                cube([clamp_width, clamp_jaw_depth, clamp_wall]);
            // 안쪽(플랩 쪽) 연결부 — 여기 얇은 부분이 탄성 힌지 역할
            translate([-clamp_width/2, 0, -clamp_wall])
                cube([clamp_width, clamp_wall, clamp_edge_thickness + clamp_wall*2 + clamp_gap_margin]);
            // 바깥쪽 상단 마운트면(mount_plate를 이 위에 나사로 고정)
            translate([-clamp_width/2, clamp_jaw_depth - 4, clamp_edge_thickness + clamp_gap_margin])
                cube([clamp_width, 20, clamp_wall + 3]);
        }
        // 마운트 나사구멍 2개(위쪽 마운트면에)
        for (x = [-1, 1])
            translate([x*clamp_width/3, clamp_jaw_depth + 8, -1])
                cylinder(h=clamp_edge_thickness + 20, d=mount_hole_dia);
    }
}

// ================= 어깨끈형 브라켓 (GoPro 표준 마운트 규격 기반) =================
// 근거(웹 검색, 2026-09-15): GoPro 3프롱(남) 마운트 표준 —
//   탭 폭 ~25.4mm, 높이 ~18mm, 나사구멍 지름 ~5.5mm(GoPro 전용 썸스크류용),
//   양옆 프롱 두께 ~4.5mm, 가운데 슬롯(암 버클 삽입부) ~7mm.
// Sources: storytellertech.com/gopro-screw-size, printables.com GoPro mount 모델들
//
// ⚠️ 실전 팁: 이 프롱 형상은 정밀 끼워맞춤이 필요해서 직접 프린트하면
// 헐거움/뻑뻑함 조정에 시행착오가 필요합니다. **더 확실한 방법은 시중
// GoPro 호환 마운트 어댑터(개당 1천~2천원, 쿠팡/알리 등)를 사서 아래
// gopro_flat_boss() 평면에 나사/글루로 고정하는 것** — 그게 훨씬 안정적.
// 그래도 직접 프린트하고 싶으면 gopro_male_tab() 사용.

gopro_tab_width     = 25.4;
gopro_tab_height    = 18;
gopro_prong_thick   = 4.5;
gopro_slot_width    = 7;
gopro_hole_dia      = 5.5;

module gopro_male_tab() {
    color("purple")
    difference() {
        union() {
            // 좌우 프롱 2개
            translate([-gopro_tab_width/2, 0, 0])
                cube([gopro_prong_thick, 12, gopro_tab_height]);
            translate([gopro_tab_width/2 - gopro_prong_thick, 0, 0])
                cube([gopro_prong_thick, 12, gopro_tab_height]);
            // 베이스(끈 클램프에 붙는 바닥판)
            translate([-gopro_tab_width/2, 0, 0])
                cube([gopro_tab_width, 12, 3]);
        }
        // 썸스크류 관통구멍 (중앙, 높이 중간)
        translate([0, 6, gopro_tab_height/2])
            rotate([90,0,0])
                cylinder(h=14, d=gopro_hole_dia, center=true);
    }
}

// 대안: GoPro 어댑터를 사서 붙일 평평한 면 (프롱 프린트 리스크 회피용)
module gopro_flat_boss() {
    color("purple")
    difference() {
        cylinder(h=4, d=30);
        translate([0,0,-1]) cylinder(h=6, d=mount_hole_dia); // 어댑터 고정 나사구멍
    }
}

// ---------- 스트랩 클램프 본체 (양쪽 사진 참고 — 끈을 앞뒤 판으로 샌드위치) ----------
strap_width_est     = 45; // 배낭 어깨끈 폭 — 실측 필요(일반적으로 35~55mm 범위)
strap_thick_est     = 8;  // 어깨끈 두께(패딩 포함) — 실측 필요
clamp_plate_w       = strap_width_est + 20;
clamp_plate_l       = 70;
clamp_plate_t       = 4;
clamp_screw_inset   = 8;

module strap_clamp_front() {
    color("purple")
    difference() {
        union() {
            translate([-clamp_plate_w/2, -clamp_plate_l/2, 0])
                cube([clamp_plate_w, clamp_plate_l, clamp_plate_t]);
            // GoPro 마운트 탭을 전면 중앙에 부착
            translate([0, 0, clamp_plate_t])
                gopro_male_tab();
        }
        // 클램프 체결 나사구멍 4개(뒷판과 조여서 끈을 고정)
        for (x = [-1, 1], y = [-1, 1])
            translate([x*(clamp_plate_w/2 - clamp_screw_inset), y*(clamp_plate_l/2 - clamp_screw_inset), -1])
                cylinder(h=clamp_plate_t+2, d=mount_hole_dia);
    }
}

module strap_clamp_back() {
    color("plum")
    difference() {
        translate([-clamp_plate_w/2, -clamp_plate_l/2, 0])
            cube([clamp_plate_w, clamp_plate_l, clamp_plate_t]);
        for (x = [-1, 1], y = [-1, 1])
            translate([x*(clamp_plate_w/2 - clamp_screw_inset), y*(clamp_plate_l/2 - clamp_screw_inset), -1])
                cylinder(h=clamp_plate_t+2, d=mount_hole_dia + 0.5); // 너트 삽입용 살짝 여유
    }
}

// 미리보기용: 두 판 사이에 끈이 끼워진 모습 확인
module strap_clamp_preview() {
    strap_clamp_front();
    color("SaddleBrown", 0.4)
        translate([-strap_width_est/2, -clamp_plate_l/2 - 5, -strap_thick_est])
            cube([strap_width_est, clamp_plate_l + 10, strap_thick_est]);
    translate([0, 0, -strap_thick_est - clamp_plate_t])
        strap_clamp_back();
}

// ================= 조립/인쇄 대상 선택 =================
// 필요한 것만 주석 해제해서 개별 STL로 export

// dummy_backpack();
// translate([0, 0, bag_height]) mount_plate();

// translate([500, 0, 0]) device_case_body();
// translate([500, 0, 0]) device_case_lid();

strap_clamp_preview();
