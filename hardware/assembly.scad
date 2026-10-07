// Tank robot: full assembly with bought parts, for checking fit.
// openscad -o tank.png --imgsize=1200,1000 assembly.scad
include <robot.scad>
use <../concepts/parts.scad>

SHOW_TANK = true;
SH = 40;      // shoulder angle, degrees forward from straight down
EL = 50;      // elbow angle, degrees forward relative to the upper arm
NECK = 0;     // head turn, degrees
EXPLODE = 0;  // 0 = assembled, ~1 = exploded view

C_BODY = [1.00, 0.62, 0.10];
C_ACC  = [0.16, 0.45, 0.85];
C_TPU  = [0.18, 0.18, 0.20];
C_CLR  = [0.75, 0.90, 1.00, 0.35];
C_PCB  = [0.10, 0.35, 0.18];

E = EXPLODE;

FACE16 = [
    "................", "..####....####..", ".######..######.", ".##..##..##..##.",
    ".##..##..##..##.", ".######..######.", "..####....####..", "................",
    "................", "................", ".#............#.", ".##..........##.",
    "..###......###..", "...##########...", ".....######.....", "................"];

module chassis() {
    for (s = [-1, 1]) translate([s * (CH_W / 2 - TR_W / 2), 0, -24]) rotate([0, 0, 90]) track(CH_L, CH_H - 4, TR_W);
    color([0.8, 0.82, 0.85]) translate([-(CH_W / 2 - TR_W - 2), -CH_L / 2 + 18, -3]) cube([CH_W - 2 * TR_W - 4, CH_L - 36, 3]);
}

module electronics_lb() {
    color([0.2, 0.2, 0.22]) translate([-38.5, -76, WALL]) cube([77, 41, 20]);          // 2 x 18650 holder
    color(C_PCB) translate([-8, 26, 14]) cube([45, 57, 1.6]);                            // Otto Nano shield
    color([0.1, 0.3, 0.7]) translate([17, 40, 26]) cube([18, 43, 8]);                  // Nano, USB to the back
    color(C_PCB) translate([-34, -20, 14]) cube([20, 20, 1.6]);                          // TB6612
    color([0.15, 0.4, 0.75]) translate([-36, 20, 14]) cube([26, 52, 12]);                // 5 V buck
    color([0.1, 0.1, 0.1]) translate([0, -LB[1] / 2 + WALL + 1, 30]) rotate([-90, 0, 0]) cylinder(d = 12, h = 8);  // buzzer
}

module upper_arm_assy() {
    color(C_BODY) upper_arm_inner();
    color(C_BODY * 0.92) translate([E * 25, 0, 0]) upper_arm_outer();
    elbow_frame() servo_vitamin();
    color(C_ACC) translate([EL_TAB_X + HUB_FACE + E * 35, 0, -UA_LEN]) rotate([0, 90, 0]) clutch_hub();
    translate([UA_T + 1 + E * 60, 0, -UA_LEN]) rotate([-EL, 0, 0]) color(C_BODY) forearm();
}

module arm_assy() {
    color(C_ACC) translate([SH_TAB_X + HUB_FACE + E * 20, SHOULDER_Y, SHOULDER_Z]) rotate([0, 90, 0]) clutch_hub();
    translate([TO[0] / 2 + 1 + E * 50, SHOULDER_Y, SHOULDER_Z]) rotate([-SH, 0, 0]) upper_arm_assy();
}

module torso_assy() {
    color(C_BODY) torso();
    for (s = [-1, 1]) shoulder_frame(s) servo_vitamin();
    neck_frame() servo_vitamin();
    color(C_ACC) translate([0, 0, NK_TAB_Z + HUB_FACE + E * 20]) clutch_hub();
    color(C_ACC) translate([0, -TO[1] / 2 - E * 30, 0]) chest_guard();
    color(C_PCB) translate([CAM_X - CAM_PCB[0] / 2, -TO[1] / 2 + WALL + 5.5, CAM_Z + 12.5 - CAM_PCB[1]]) cube([CAM_PCB[0], 1.6, CAM_PCB[1]]);
    color([0.1, 0.1, 0.12]) translate([CAM_X, -TO[1] / 2 + WALL + 5.5, CAM_Z]) rotate([90, 0, 0]) cylinder(d = 8, h = 6);
    color([0.4, 0.2, 0.6]) translate([TOF_X - TOF_PCB[0] / 2, -TO[1] / 2 + WALL + 0.4, TOF_Z - TOF_PCB[1] / 2]) cube([TOF_PCB[0], 1.6, TOF_PCB[1]]);
    for (s = [-1, 1]) mirror([s < 0 ? 1 : 0, 0, 0]) arm_assy();
    color(C_CLR) translate([CAM_X - 12, -TO[1] / 2 - 2.2 - E * 20, CAM_Z - 12]) cube([24, 2, 24]);
}

module head_assy() {
    color(C_BODY) head_front();
    color(C_BODY * 0.9) translate([0, E * 40, 0]) head_back();
    translate([0, -HD[1] / 2 + WALL + WIN_SHEET[2] + E * 25, FACE_Z]) {
        color(C_ACC) face_carrier();
        translate([0, -0.01, 0]) rotate([90, 0, 0]) translate([0, 0, -1.2]) matrix16x16(FACE16);
    }
    color(C_TPU) translate([28, 8, HD[2] + E * 30]) antenna();
    // clear parts last so the preview draws what is behind them
    color(C_CLR) translate([-WIN_SHEET[0] / 2, -HD[1] / 2 + WALL - E * 10, FACE_Z - WIN_SHEET[1] / 2]) cube([WIN_SHEET[0], WIN_SHEET[2], WIN_SHEET[1]]);
}

module tank() {
    chassis();
    {
        color(C_BODY) lower_body();
        electronics_lb();
        color(C_ACC) translate([0, 0, 11]) tray();
        for (r = [0, 180]) rotate([0, 0, r]) color(C_TPU) translate([0, -LB[1] / 2 - E * 30, BUMPER_Z]) bumper();
        for (s = [-1, 1]) mirror([s < 0 ? 1 : 0, 0, 0]) color(C_ACC) translate([LB[0] / 2 + E * 30, 0, 0]) fender();
    }
    color(C_BODY * 0.95) translate([0, 0, LB[2] + E * 40]) lid();
    translate([0, 0, Z_TORSO + E * 90]) torso_assy();
    translate([0, 0, Z_HEAD + E * 170]) rotate([0, 0, NECK]) head_assy();
}

if (!is_undef(SHOW_TANK) ? SHOW_TANK : true) tank();
