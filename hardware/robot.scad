// Tank robot: printable parts.
// Render one part:  openscad -D 'part="torso"' -o torso.stl robot.scad
// Parts list: see PARTS below or hardware/export.sh.
include <lib.scad>

part = "none";

// ======================================================================
// LOWER BODY: tub that bolts to the chassis deck. Holds battery,
// Nano + shield, motor driver, buck converter, charger, buzzer, switches.
// Local frame: centred in X/Y, bottom at z = 0, front faces -Y.
// ======================================================================
LB_BOSS = [for (x = [-1, 1], y = [-80, 0, 80]) [x * (LB[0] / 2 - 6), y]];
TORSO_BOSS = [for (x = [-1, 1], y = [-1, 1]) [x * 38, y * 31]];
BUMPER_X = 36; BUMPER_Z = 14;
FENDER_Y = [-60, 0, 60]; FENDER_Z = 22;
TRAY_BOSS = [for (x = [-1, 1], y = [-22, 76]) [x * 34, y]];

module tub(size, r, wall) {
    intersection() {
        difference() {
            translate([-size[0] / 2, -size[1] / 2, 0]) rbox([size[0], size[1], size[2] + r], r);
            translate([-size[0] / 2 + wall, -size[1] / 2 + wall, wall])
                rbox([size[0] - 2 * wall, size[1] - 2 * wall, size[2] + r], max(r - wall, 1));
        }
        translate([-size[0], -size[1], 0]) cube([2 * size[0], 2 * size[1], size[2]]);
    }
}

module slot(len, w, h) { hull() for (x = [-len / 2, len / 2]) translate([x, 0, 0]) cylinder(d = w, h = h); }

module lower_body() {
    L = LB[1]; W = LB[0]; H = LB[2];
    difference() {
        union() {
            tub(LB, LB_R, WALL);
            intersection() {
            translate([-W / 2, -L / 2, 0]) rbox([W, L, H + LB_R], LB_R);
            union() {
            // lid screw columns
            for (p = LB_BOSS) translate([p[0], p[1], 0]) insert_boss(H);
            // bumper bosses, front and back
            for (y = [-1, 1], x = [-1, 1]) translate([x * BUMPER_X, y * (L / 2 - WALL), BUMPER_Z])
                rotate([y * 90, 0, 0]) insert_boss(10);
            // fender bosses on both sides
            for (s = [-1, 1], y = FENDER_Y) translate([s * (W / 2 - WALL), y, FENDER_Z])
                rotate([0, s * -90, 0]) insert_boss(9);
            // electronics tray standoffs
            for (p = TRAY_BOSS) translate([p[0], p[1], 0]) insert_boss(11, 8);
            // battery cradle (2 x 18650 holder, ~77 x 41 mm) with strap slots
            for (y = [-77.5, -33.5]) translate([-40, y - 1.5, 0]) cube([80, 3, 18]);
            for (x = [-1, 1]) translate([x * 41.5 - 1.5, -77.5, 0]) cube([3, 44, 10]);
            // buzzer holder behind the grille (12 mm passive buzzer)
            translate([0, -L / 2 + WALL, 30]) rotate([-90, 0, 0]) cylinder(d = 16, h = 9);
            }}
        }
        // chassis mounting slots + motor wire hole in the floor
        for (y = [-66, 0, 66], x = [-1, 1]) translate([x * 26, y, -1]) slot(18, M3, WALL + 2);
        translate([-17, 33, -1]) cube([34, 14, WALL + 2]);
        // insert holes: lid columns (from the top), bumpers, fenders, tray
        for (p = LB_BOSS) translate([p[0], p[1], H]) mirror([0, 0, 1]) insert_hole();
        for (y = [-1, 1], x = [-1, 1]) translate([x * BUMPER_X, y * (L / 2 + 1), BUMPER_Z])
            rotate([y * 90, 0, 0]) insert_hole(INS_L + 1);
        for (s = [-1, 1], y = FENDER_Y) translate([s * (W / 2 + 1), y, FENDER_Z])
            rotate([0, s * 90, 0]) mirror([0, 0, 1]) insert_hole(INS_L + 1);
        for (p = TRAY_BOSS) translate([p[0], p[1], 11]) mirror([0, 0, 1]) insert_hole();
        // battery strap slots
        for (y = [-77.5, -33.5]) translate([-11, y - 3, 12]) cube([22, 6, 3.5]);
        // front: speaker grille + buzzer bore
        for (x = [-16 : 8 : 16]) translate([x - 1.7, -L / 2 - 1, 22]) cube([3.4, WALL + 2, 16]);
        translate([0, -L / 2 + WALL - 0.1, 30]) rotate([-90, 0, 0]) cylinder(d = 12.6, h = 10);
        // back, all above the bumper: power rocker (KCD1, 19 x 13), USB-C charge port,
        // PROG/RUN slide switch, Nano USB
        translate([-26 - 9.7, L / 2 - WALL - 1, 28 - 6.6]) cube([19.4, WALL + 2, 13.2]);
        translate([0, L / 2 + 1, 35]) rotate([90, 0, 0]) hull() for (x = [-3, 3]) translate([x, 0, 0]) cylinder(d = 4.6, h = WALL + 2);
        translate([26 - 7, L / 2 - WALL - 1, 25]) cube([14, WALL + 2, 12]);
        translate([-4.6, L / 2 - WALL - 1, 24]) cube([9.2, WALL + 2, 4.6]);
    }
}

module lid() {
    W = LB[0]; L = LB[1];
    difference() {
        translate([-W / 2, -L / 2, 0]) rslab([W, L, LID_T], LB_R);
        for (p = LB_BOSS) translate([p[0], p[1], -1]) {
            cylinder(d = M3, h = LID_T + 2);
            translate([0, 0, LID_T - 1.6]) cylinder(d1 = M3, d2 = 6.4, h = 1.61);   // countersink
        }
        for (p = TORSO_BOSS) translate([p[0], p[1], -1]) cylinder(d = M3, h = LID_T + 2);
        translate([-25, -16, -1]) rslab([50, 32, LID_T + 2], 4);    // cable pass under the torso
        translate([0, 70, -1]) cylinder(d = 16.2, h = LID_T + 2);    // mode button (16 mm panel button)
    }
}

// Pegboard tray: boards mount with M3 nylon standoffs or zip ties.
module tray() {
    difference() {
        translate([-38, -28, 0]) rslab([76, 110, 3], 4);
        for (p = TRAY_BOSS) translate([p[0], p[1], -1]) cylinder(d = M3, h = 5);
        for (x = [-32 : 8 : 32], y = [-20 : 8 : 76])
            if (min([for (p = TRAY_BOSS) norm([x - p[0], y - p[1]])]) > 7)
                translate([x, y, -1]) cylinder(d = 3.2, h = 5, $fn = 16);
    }
}

// ======================================================================
// TORSO: shoulder servos, ESP32-CAM + VL53L0X in the chest. The head bolts on top.
// Local frame: centred in X/Y, bottom (on the lid) at z = 0.
// ======================================================================
SH_TAB_X = TO[0] / 2 + 1 - LIMB_FACE;            // shoulder servo tab plane
HEAD_BOLT = [for (x = [-1, 1], y = [-1, 1]) [x * 22, y * 22]];   // head-to-torso screws
HEAD_CABLE = [0, -17];                           // face cable hole, torso top + head floor
GUARD_BOSS = [for (x = [-1, 1], z = [14, 46]) [x * 30, z]];

module shoulder_frame(s) {
    translate([s * SH_TAB_X, SHOULDER_Y, SHOULDER_Z]) rotate([0, s * 90, 0]) rotate([0, 0, 90]) children();
}

module torso() {
    W = TO[0]; D = TO[1]; H = TO[2];
    difference() {
        union() {
            // shell, open at the bottom
            intersection() {
                difference() {
                    translate([-W / 2, -D / 2, -TO_R]) rbox([W, D, H + TO_R], TO_R);
                    translate([-W / 2 + WALL, -D / 2 + WALL, -TO_R]) rbox([W - 2 * WALL, D - 2 * WALL, H + TO_R - WALL], TO_R - WALL);
                }
                translate([-W, -D, 0]) cube([2 * W, 2 * D, H]);
            }
            intersection() {
            translate([-W / 2, -D / 2, -TO_R]) rbox([W, D, H + TO_R], TO_R);
            union() {
            // mounting bosses (screws come up through the lid)
            for (p = TORSO_BOSS) translate([p[0], p[1], 0]) insert_boss(10);
            // shoulder bulkheads
            for (s = [-1, 1]) translate([s > 0 ? SH_TAB_X : -SH_TAB_X - 6, -18, 22]) cube([6, 18 + D / 2 - 1, H - 22 - 1]);
            // head bolt bosses hanging from the top wall (inserts open upward)
            for (p = HEAD_BOLT) translate([p[0], p[1], H - WALL - 7]) insert_boss(7 + WALL - 0.5);
            // chest guard bosses
            for (p = GUARD_BOSS) translate([p[0], -D / 2 + WALL - 0.5, p[1]]) rotate([-90, 0, 0]) insert_boss(8);
            // ESP32-CAM rails (PCB vertical, lens forward)
            for (x = [CAM_X - CAM_PCB[0] / 2, CAM_X + CAM_PCB[0] / 2]) translate([x - 3, -D / 2 + WALL - 0.5, 0.5]) cube([6, 10, 44]);
            // VL53L0X rails
            for (x = [TOF_X - TOF_PCB[0] / 2, TOF_X + TOF_PCB[0] / 2]) translate([x - 2.5, -D / 2 + WALL - 0.5, TOF_Z - 14]) cube([5, 5, 28]);
            }}
        }
        // servo pockets
        for (s = [-1, 1]) shoulder_frame(s) servo_mount_cut(6);
        // clutch wells
        for (s = [-1, 1]) translate([s * (SH_TAB_X + 6 - 0.01), SHOULDER_Y, SHOULDER_Z]) rotate([0, s * 90, 0]) cylinder(d = WELL_D, h = W);
        // face cable up into the head
        translate([HEAD_CABLE[0], HEAD_CABLE[1], H - WALL - 1]) cylinder(d = 12, h = WALL + 2);
        for (p = HEAD_BOLT) translate([p[0], p[1], H + 0.01]) mirror([0, 0, 1]) insert_hole(INS_L + 1);
        // elbow cable slots behind each shoulder
        for (s = [-1, 1]) translate([s * W / 2 - 5, 24, 44]) cube([10, 10, 6]);
        // insert holes
        for (p = TORSO_BOSS) translate([p[0], p[1], 0]) insert_hole();
        for (p = GUARD_BOSS) translate([p[0], -D / 2 - 1, p[1]]) rotate([-90, 0, 0]) insert_hole(INS_L + 1);
        // chest openings: lens and distance sensor
        translate([CAM_X, -D / 2 - 1, CAM_Z]) rotate([-90, 0, 0]) cylinder(d = 13, h = WALL + 2);
        translate([TOF_X - 5.5, -D / 2 - 1, TOF_Z - 4.5]) cube([11, WALL + 2, 9]);
        // PCB slots in the rails
        translate([CAM_X - CAM_PCB[0] / 2 - 0.3, -D / 2 + WALL + 5.5, 1]) cube([CAM_PCB[0] + 0.6, 2, CAM_Z + 12.6 + 1]);
        translate([TOF_X - TOF_PCB[0] / 2 - 0.3, -D / 2 + WALL + 0.4, TOF_Z - 15]) cube([TOF_PCB[0] + 0.6, 2, 31]);
        // keep the shoulder servo bodies clear of the rails and webs
        for (s = [-1, 1]) shoulder_frame(s) translate([SV_SHAFT - SV_TAB_L / 2 - 1, -SV_W / 2 - 1, -40]) cube([SV_TAB_L + 2, SV_W + 2, 40]);
    }
}

// Raised guard over the lens and the distance sensor. Clear sheet goes behind the lens window.
module chest_guard() {
    difference() {
        translate([-35, -6, 10]) rbox([70, 6, 40], 3);
        // lens window (clear 24 x 24 x 2 sheet sits in the recess at the back)
        translate([CAM_X - 9, -7, CAM_Z - 9]) cube([18, 8, 18]);
        translate([CAM_X - 12.2, -2.2, CAM_Z - 12.2]) cube([24.4, 2.3, 24.4]);
        // distance sensor stays uncovered (a cover sheet would blind it)
        translate([TOF_X - 6, -7, TOF_Z - 5]) cube([12, 8, 10]);
        for (p = GUARD_BOSS) translate([p[0], -7, p[1]]) rotate([-90, 0, 0]) {
            cylinder(d = M3, h = 8);
            cylinder(d = M3_HEAD, h = 3.5);
        }
    }
}

// ======================================================================
// HEAD: 16x16 face behind a clear window, bolted to the top of the torso
// (4 x M3 x 12 down through the head floor; reach them with the back cap off).
// Local frame: centred in X/Y, bottom at z = 0, front faces -Y.
// Printed in two pieces: front shell and back cap (split at y = HEAD_SPLIT).
// ======================================================================
HEAD_SPLIT = HD[1] / 2 - 10;
HEAD_CAP_BOSS = [for (x = [-1, 1], z = [14, 86]) [x * 38, z]];
FACE_BOSS = [for (x = [-1, 1], z = [-1, 1]) [x * 40, FACE_Z + z * 40]];
FACE_BOSS_LEN = WIN_SHEET[2] + MX_DEPTH;

module head_solid() { translate([-HD[0] / 2, -HD[1] / 2, 0]) rbox(HD, HD_R); }
module head_void() {
    translate([-HD[0] / 2 + WALL, -HD[1] / 2 + WALL, WALL]) rbox([HD[0] - 2 * WALL, HD[1] - 2 * WALL, HD[2] - 2 * WALL], HD_R - WALL);
}

module head_front() {
    difference() {
        union() {
            difference() { head_solid(); head_void(); }
            // floor bosses for the head bolts
            for (p = HEAD_BOLT) translate([p[0], p[1], 0]) cylinder(d = BOSS_D + 1, h = 6);
            // back-cap screw bosses
            for (p = HEAD_CAP_BOSS) translate([p[0], HEAD_SPLIT - 14, p[1]]) rotate([-90, 0, 0]) insert_boss(14);
            // face carrier bosses
            for (p = FACE_BOSS) translate([p[0], -HD[1] / 2 + WALL - 0.5, p[1]]) rotate([-90, 0, 0]) insert_boss(FACE_BOSS_LEN + 0.5);
            // antenna socket
            translate([28, 8, HD[2] - WALL - 6]) cylinder(d = 14, h = 6.5);
        }
        translate([-HD[0], HEAD_SPLIT, -1]) cube([2 * HD[0], HD[1], HD[2] + 2]);
        // head bolts
        for (p = HEAD_BOLT) translate([p[0], p[1], -1]) cylinder(d = M3, h = 10);
        // face cable down into the torso
        translate([HEAD_CABLE[0], HEAD_CABLE[1], -1]) cylinder(d = 9, h = WALL + 2);
        // face opening
        translate([-FACE_WIN / 2, -HD[1] / 2 - 1, FACE_Z - FACE_WIN / 2]) cube([FACE_WIN, WALL + 2, FACE_WIN]);
        // insert holes
        for (p = HEAD_CAP_BOSS) translate([p[0], HEAD_SPLIT + 0.01, p[1]]) rotate([90, 0, 0]) insert_hole();
        for (p = FACE_BOSS) translate([p[0], -HD[1] / 2 + WALL + FACE_BOSS_LEN + 0.01, p[1]]) rotate([90, 0, 0]) insert_hole();
        // antenna hole
        translate([28, 8, HD[2] - 20]) cylinder(d = 8.3, h = 30);
    }
}

module head_back() {
    difference() {
        intersection() {
            difference() { head_solid(); head_void(); }
            translate([-HD[0], HEAD_SPLIT, -1]) cube([2 * HD[0], HD[1], HD[2] + 2]);
        }
        for (p = HEAD_CAP_BOSS) translate([p[0], HEAD_SPLIT - 1, p[1]]) rotate([-90, 0, 0]) {
            cylinder(d = M3, h = 20);
            translate([0, 0, 4]) cylinder(d = M3_HEAD, h = 20);
        }
    }
    // screw towers in the cap
    difference() {
        for (p = HEAD_CAP_BOSS) translate([p[0], HEAD_SPLIT, p[1]]) rotate([-90, 0, 0]) cylinder(d = BOSS_D, h = HD[1] / 2 - HEAD_SPLIT - 1);
        for (p = HEAD_CAP_BOSS) translate([p[0], HEAD_SPLIT - 1, p[1]]) rotate([-90, 0, 0]) {
            cylinder(d = M3, h = 20);
            translate([0, 0, 4]) cylinder(d = M3_HEAD, h = 20);
        }
    }
}

// Holds the four 8x8 modules face-first against the window sheet.
// Local frame: front face (against the sheet) at y = 0, display centre at x = z = 0.
module face_carrier() {
    pocket = MX + 0.2;
    grid = 2 * pocket + MX_GAP;
    frame = grid + 4;
    difference() {
        union() {
            translate([-frame / 2, 0, -frame / 2]) cube([frame, MX_DEPTH, frame]);
            translate([-44, MX_DEPTH - 0.5, -44]) rbox([88, 3.5, 88], 1.5);
        }
        for (cx = [0, 1], cz = [0, 1])
            translate([-grid / 2 + cx * (pocket + MX_GAP), -0.01, -grid / 2 + cz * (pocket + MX_GAP)]) cube([pocket, MX_DEPTH + 0.02, pocket]);
        // wire / header opening at the back, leaving a rim that holds the modules
        translate([-grid / 2 + 5, MX_DEPTH - 1, -grid / 2 + 5]) cube([grid - 10, 6, grid - 10]);
        for (p = FACE_BOSS) translate([p[0], -1, p[1] - FACE_Z]) rotate([-90, 0, 0]) cylinder(d = M3, h = 20);
    }
}

// ======================================================================
// ARMS. Right arm shown; the left is a mirror image.
// Local frame: shoulder axis is the X axis, inner face at x = 0,
// arm hangs down -Z, front is -Y.
// ======================================================================
EL_TAB_X = UA_T + 1 - LIMB_FACE;          // elbow servo tab plane inside the upper arm
UA_BOT = -UA_LEN - 22;
UA_SCREWS = [[-9, -26], [-10, -78], [10, -78]];   // [y, z] of the half-joining screws

module elbow_frame() { translate([EL_TAB_X, 0, -UA_LEN]) rotate([0, 90, 0]) rotate([0, 0, 180]) children(); }

module upper_arm_solid() {
    hull() {
        translate([0, -UA_W / 2, -20]) rbox([UA_T, UA_W, 36], 7);
        translate([0, -UA_W / 2, UA_BOT]) rbox([UA_T, UA_W, 36], 7);
    }
}

module upper_arm_cuts() {
    rotate([0, 90, 0]) limb_socket_cut(UA_T, 5);                          // shoulder clutch
    elbow_frame() servo_mount_cut(6);                                      // elbow servo
    translate([EL_TAB_X + 6 - 0.01, 0, -UA_LEN]) rotate([0, 90, 0]) cylinder(d = WELL_D, h = UA_T);   // elbow well
    // cable channel from the servo bay to the back of the arm
    translate([6, -4, -46]) cube([EL_TAB_X - 6 + 0.1, 8, 30]);
    translate([6, 0, -22]) cube([10, UA_W, 7]);
    // half-joining screws: counterbored from the outside, inserts in the inner half
    for (p = UA_SCREWS) translate([UA_T + 1, p[0], p[1]]) rotate([0, -90, 0]) {
        cylinder(d = M3, h = UA_T - EL_TAB_X + 1.1);
        cylinder(d = M3_HEAD, h = 5);
    }
    for (p = UA_SCREWS) translate([EL_TAB_X + 0.01, p[0], p[1]]) rotate([0, -90, 0]) insert_hole();
}

module upper_arm_inner() {
    difference() {
        intersection() { upper_arm_solid(); translate([-1, -50, -150]) cube([EL_TAB_X + 1, 100, 300]); }
        upper_arm_cuts();
    }
}
module upper_arm_outer() {
    difference() {
        intersection() { upper_arm_solid(); translate([EL_TAB_X, -50, -150]) cube([UA_T, 100, 300]); }
        upper_arm_cuts();
    }
}

// Forearm with a fixed two-finger claw. Elbow axis = X axis, inner face at x = 0.
module forearm() {
    difference() {
        union() {
            hull() {
                translate([0, -FA_W / 2, -14]) rbox([FA_T, FA_W, 28], 6);
                translate([0, -FA_W / 2 - 2, -FA_LEN - 6]) rbox([FA_T, FA_W + 4, 14], 6);
            }
            // fingers
            for (s = [-1, 1]) hull() {
                translate([0, s * 11 - 4, -FA_LEN - 4]) rbox([FA_T, 8, 8], 3.5);
                translate([2, s * 9 - 3.5, -FA_LEN - 30]) rbox([FA_T - 4, 7, 7], 3.2);
            }
        }
        rotate([0, 90, 0]) limb_socket_cut(FA_T, 5);
    }
}

// ======================================================================
// TPU parts
// ======================================================================
// Bumper bar, local frame: mounting face (against the lower body) at y = 0, bar toward -Y.
module bumper() {
    bar_y = -13;
    difference() {
        union() {
            hull() for (x = [-86, 86]) translate([x, bar_y, 0]) sphere(d = 20, $fn = 32);
            for (x = [-1, 1]) translate([x * BUMPER_X - 8, bar_y, -8]) cube([16, -bar_y, 16]);
        }
        for (x = [-1, 1]) translate([x * BUMPER_X, 1, 0]) rotate([90, 0, 0]) {
            cylinder(d = M3, h = 30);
            translate([0, 0, 9]) cylinder(d = 7.5, h = 30);
        }
    }
}

// Track fender, right side. Local frame: lower-body side face at x = 0, deck top at z = 0.
FENDER_LEN = CH_L + 10;
module fender() {
    top_z = 10;              // underside of the fender above the deck; check track clearance
    difference() {
        union() {
            translate([0, -FENDER_LEN / 2, top_z]) rslab([TR_W + 10, FENDER_LEN, 4], 4);
            translate([TR_W + 6, -FENDER_LEN / 2, top_z]) rslab([4, FENDER_LEN, 10], 2);        // outer rim
            translate([0, -FENDER_LEN / 2 + 20, top_z]) cube([4, FENDER_LEN - 40, 20]);        // mounting flange
        }
        for (y = FENDER_Y) translate([-1, y, FENDER_Z]) rotate([0, 90, 0]) {
            cylinder(d = M3, h = 10);
        }
    }
}

module antenna() {
    cylinder(d = 16, h = 3);
    translate([0, 0, -7]) difference() {
        union() { cylinder(d = 8, h = 7.01); translate([0, 0, 1.5]) cylinder(d1 = 8, d2 = 9, h = 2); }
        translate([-0.75, -5, -1]) cube([1.5, 10, 6]);
    }
    cylinder(d = 6, h = 30);
    translate([0, 0, 33]) sphere(d = 12);
}

// ======================================================================
PARTS = ["lower_body", "lid", "tray", "torso", "chest_guard", "head_front", "head_back",
         "face_carrier", "upper_arm_inner", "upper_arm_outer", "forearm", "clutch_hub",
         "bumper", "fender", "antenna"];

module print_part(p) {
    // each part laid out in a good print orientation
    if (p == "lower_body") lower_body();
    if (p == "lid") lid();
    if (p == "tray") tray();
    if (p == "torso") rotate([180, 0, 0]) translate([0, 0, -TO[2]]) torso();
    if (p == "chest_guard") rotate([-90, 0, 0]) chest_guard();
    if (p == "head_front") rotate([90, 0, 0]) head_front();
    if (p == "head_back") rotate([-90, 0, 0]) translate([0, -HD[1] / 2, 0]) head_back();
    if (p == "face_carrier") rotate([-90, 0, 0]) face_carrier();
    if (p == "upper_arm_inner") rotate([0, 90, 0]) upper_arm_inner();
    if (p == "upper_arm_outer") rotate([0, -90, 0]) translate([-UA_T, 0, 0]) upper_arm_outer();
    if (p == "forearm") rotate([0, -90, 0]) translate([-FA_T, 0, 0]) forearm();
    if (p == "clutch_hub") clutch_hub();
    if (p == "bumper") rotate([-90, 0, 0]) bumper();
    if (p == "fender") fender();
    if (p == "antenna") antenna();
}

if (part != "none") print_part(part);
