// ============================================================
// ⚠️ 이 파일은 폐기됨 (2026-09-15) — 가방을 감싸는 프레임 구조는
// 방향이 잘못됨(특정 가방 형태를 전제로 함). 대체 파일:
// mount_plate_and_case_v1.scad (상단 평판 + 별도 케이스 분리형)
// ============================================================
// Portable LiDAR Mapper — 프레임 하네스(스쿠버탱크형) v0.1 [DEPRECATED]
// 사용법: OpenSCAD(무료, openscad.org)에서 이 파일을 열고
//   F5 = 미리보기, F6 = 렌더링, File > Export > Export as STL
//   로 STL을 뽑아서 슬라이서(Bambu Studio 등)에 넣으면 됩니다.
// 아래 변수만 실측값으로 바꾸면 전체 형상이 자동으로 재계산됩니다.
// ============================================================

// ---------- 실측 확정값 ----------
lidar_diameter   = 75;   // RPLIDAR C1 지름 (hardware/tumbler_mount_design.md 실측값)
lidar_height     = 40;   // 추정치 — 실물 도착 후 캘리퍼스로 재측정 후 수정할 것

// ---------- 추정치 (반드시 실측 후 갱신) ----------
body_diameter    = 80;   // 본체(오렌지파이+배터리) 원통 지름
body_height      = 220;  // 본체 높이
rail_width       = 14;   // 프레임 레일 폭
rail_thickness   = 5;    // 프레임 레일 두께
rail_gap         = 5;    // 본체-레일 사이 간격(스트랩 통과 공간)
strap_width      = 12;   // 스트랩 루프 폭
strap_thickness  = 4;    // 스트랩 루프 두께
plate_size       = 90;   // 상단 마운트 플레이트 한 변
plate_thickness  = 4;    // 상단 마운트 플레이트 두께
mount_hole_dia   = 3.2;  // M3 나사용 구멍 지름
mount_hole_spacing = 40; // 마운트 나사 구멍 간격

// 레일이 본체를 감싸는 반경(간격 포함)
rail_radius = body_diameter/2 + rail_gap + rail_width/2;

$fn = 64; // 원형 부드럽게

// ---------- 본체(참고용, 실제 인쇄 대상 아님 — 피팅 확인용) ----------
module body_reference() {
    color("lightgray", 0.25)
    translate([0, 0, body_height/2])
        cylinder(h=body_height, d=body_diameter, center=true);
}

// ---------- 프레임 레일 (좌/우 세로 기둥, 곡선은 단순화된 초안) ----------
module frame_rail(x_offset) {
    color("dimgray")
    translate([x_offset, 0, 0])
    hull() {
        translate([0, 0, rail_width/2])
            rotate([90,0,0]) cylinder(h=1, d=rail_width, center=true);
        translate([0, 0, body_height - rail_width/2])
            rotate([90,0,0]) cylinder(h=1, d=rail_width, center=true);
    }
}

module frame_rails() {
    frame_rail(rail_radius);
    frame_rail(-rail_radius);
}

// ---------- 상단 육각 손잡이 루프 (경량화 + 손잡이 겸용) ----------
module top_handle_loop() {
    color("dimgray")
    translate([0, 0, body_height + 30])
    rotate([90, 0, 0])
    difference() {
        hull() {
            for (a = [0:60:300])
                rotate([0,0,a]) translate([body_diameter/2, 0, 0]) cylinder(h=rail_thickness, d=rail_width, center=true);
        }
        hull() {
            for (a = [0:60:300])
                rotate([0,0,a]) translate([body_diameter/2 - rail_width - 6, 0, 0]) cylinder(h=rail_thickness+2, d=rail_width, center=true);
        }
    }
}

// ---------- 스트랩 루프 (본체를 프레임에 고정) ----------
module strap_loop(z_pos) {
    color("black")
    translate([0, 0, z_pos])
    rotate_extrude(angle=200, $fn=64)
        translate([rail_radius - rail_width/2, 0, 0])
            square([strap_width, strap_thickness], center=true);
}

module strap_loops() {
    strap_loop(body_height * 0.25);
    strap_loop(body_height * 0.75);
}

// ---------- 상단 마운트 플레이트 (라이다 장착부) ----------
module mount_plate() {
    color("purple")
    translate([0, 0, body_height + 5])
    difference() {
        // 플레이트 본체
        translate([-plate_size/2, -plate_size/2, 0])
            cube([plate_size, plate_size, plate_thickness]);
        // 마운트 나사 구멍 4개
        for (x = [-1, 1], y = [-1, 1])
            translate([x*mount_hole_spacing/2, y*mount_hole_spacing/2, -1])
                cylinder(h=plate_thickness+2, d=mount_hole_dia);
    }
    // 라이다 풋프린트(참고용 반투명 실린더, 실제 인쇄 대상 아님)
    color("orange", 0.3)
    translate([0, 0, body_height + 5 + plate_thickness])
        cylinder(h=lidar_height, d=lidar_diameter);
}

// ---------- 조립 전체 ----------
module assembly() {
    body_reference();
    frame_rails();
    top_handle_loop();
    strap_loops();
    mount_plate();
}

assembly();

// ============================================================
// 인쇄용으로 개별 부품만 뽑고 싶으면 위 assembly() 호출을 주석 처리하고
// 아래 중 필요한 모듈만 개별 호출하세요. body_reference()는 실제 부품이
// 아니라 피팅 확인용 참고 형상이라 인쇄 대상에서 제외할 것.
//
// frame_rails();
// top_handle_loop();
// strap_loops();
// mount_plate();
// ============================================================
