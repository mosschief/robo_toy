// Tank robot: printable parts.
// Render one part:  openscad -D 'part="torso"' -o torso.stl robot.scad
// Parts list: see PARTS below or hardware/export.sh.
include <base.scad>

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
TRAY_BOSS = [for (x = [-1, 1], y = [-22, 68]) [x * 33, y]];   // clear of the lid columns and rear bumper bosses

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
            // waist servo tower: the servo drops in from the top, tabs rest on the rim
            waist_frame() translate([-11.5, -8.9, -(WS_TAB_Z - WALL)]) cube([34.2, 17.8, WS_TAB_Z - WALL - SV_TAB_T]);
            }}
        }
        // chassis mounting slots + motor wire hole in the floor
        for (p = LB_FLOOR_SCREWS) translate([p[0], p[1], -1]) slot(10, M3, WALL + 2);
        translate([-17, 33, -1]) cube([34, 14, WALL + 2]);
        // waist servo pocket, tab screw pilots, cable slot
        waist_frame() {
            translate([SV_SHAFT - SV_L / 2 - 0.4, -SV_W / 2 - 0.4, -SV_TAB_T - SV_BELOW - 0.5]) cube([SV_L + 0.8, SV_W + 0.8, 40]);
            for (s = [-1, 1]) translate([SV_SHAFT + s * SV_SCREW / 2, 0, -SV_TAB_T - 8]) cylinder(d = M2_PILOT, h = 9);
            translate([SV_SHAFT + SV_L / 2 - 1, -3, -SV_TAB_T - 14]) cube([8, 6, 15]);
        }
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

// Lid with the waist bearing housing on top. The 6808 bearing presses into the
// housing from above and is held by the bearing cap.
CAP_LOBE_A = [0, 180, 270];
CAP_LOBE_R = BR_HOUSE_OD / 2 + 2.5;
CABLE_R = [BR_HOUSE_OD / 2 + 1, BR_HOUSE_OD / 2 + 15];   // cable arc: inner, outer radius

module lid() {
    W = LB[0]; L = LB[1];
    HH = LID_T + BR[2];
    difference() {
        union() {
            translate([-W / 2, -L / 2, 0]) rslab([W, L, LID_T], LB_R);
            cylinder(d = BR_HOUSE_OD, h = HH);
            for (a = CAP_LOBE_A) rotate(a) translate([CAP_LOBE_R, 0, 0]) cylinder(d = 9, h = HH);
        }
        for (p = LB_BOSS) translate([p[0], p[1], -1]) {
            cylinder(d = M3, h = LID_T + 2);
            translate([0, 0, LID_T - 1.6]) cylinder(d1 = M3, d2 = 6.4, h = 1.61);   // countersink
        }
        // bearing seat (outer race sits on the lid) and the opening under it
        translate([0, 0, LID_T]) cylinder(d = BR[1] + 0.15, h = BR[2] + 1, $fn = 96);
        translate([0, 0, -1]) cylinder(d = BR_OUT_ID, h = HH + 2);
        for (a = CAP_LOBE_A) rotate(a) translate([CAP_LOBE_R, 0, HH + 0.01]) mirror([0, 0, 1]) insert_hole();
        // the torso cables swing through this arc as the waist turns
        rotate(90 - WAIST_RANGE - 8) rotate_extrude(angle = 2 * WAIST_RANGE + 16)
            translate([CABLE_R[0], -1]) square([CABLE_R[1] - CABLE_R[0], LID_T + 2]);
        translate([0, 70, -1]) cylinder(d = 16.2, h = LID_T + 2);    // mode button (16 mm panel button)
    }
}

// Pegboard tray: boards mount with M3 nylon standoffs or zip ties.
module tray() {
    difference() {
        translate([-37, -28, 0]) rslab([74, 102, 3], 4);
        for (p = TRAY_BOSS) translate([p[0], p[1], -1]) cylinder(d = M3, h = 5);
        translate([-9.5, -12.5, -1]) rslab([19, 36, 5], 2);    // waist servo tower passes through
        for (x = [-32 : 8 : 32], y = [-20 : 8 : 68])
            if (min([for (p = TRAY_BOSS) norm([x - p[0], y - p[1]])]) > 7)
                translate([x, y, -1]) cylinder(d = 3.2, h = 5, $fn = 16);
    }
}

// ======================================================================
// WAIST: the torso turns on the bearing. Waist servo stands in the lower
// body, its clutch hub drives the waist plate tube from below.
// World frame (lower body frame).
// ======================================================================
WS_FACE_Z = LB[2];                         // clutch contact face = lid underside
WS_TAB_Z = WS_FACE_Z - LIMB_FACE;          // waist servo tab plane
module waist_frame() { translate([0, 0, WS_TAB_Z]) rotate([0, 0, 90]) children(); }

WP_DROP = CAP_T + WAIST_GAP;               // plate bottom -> inner race top
WP_FACE = -(WP_DROP + BR[2] + LID_T);      // contact face, plate frame
CLAMP_A = [90, 210, 330];
CLAMP_R = 17;

// Waist plate: torso bolts on top, tube goes down through the bearing.
// Local frame: plate bottom at z = 0, centred.
module waist() {
    difference() {
        union() {
            translate([-WP[0] / 2, -WP[1] / 2, 0]) rslab(WP, TO_R);
            translate([0, 0, -WP_DROP]) cylinder(d = BR_IN_OD - 0.5, h = WP_DROP + 0.01);       // rests on the inner race
            translate([0, 0, -WP_DROP - BR[2]]) cylinder(d = BR[0] - 0.1, h = BR[2] + 0.01, $fn = 96);
            translate([0, 0, WP_FACE]) cylinder(d = 30, h = LID_T + 0.01);
        }
        translate([0, 0, WP_FACE]) limb_socket_cut(WP[2] - WP_FACE, 4);
        for (a = CLAMP_A) rotate(a) translate([CLAMP_R, 0, -WP_DROP - BR[2]]) insert_hole(INS_L + 1);
        for (p = TORSO_BOSS) translate([p[0], p[1], -1]) cylinder(d = M3, h = WP[2] + 2);
        // cables down to the lower body
        hull() for (x = [-9, 9]) translate([x, 33.25, -1]) cylinder(d = 6.5, h = WP[2] + 2);
    }
}

// Holds the bearing's outer race down. Local frame: bottom on the housing top.
module bearing_cap() {
    difference() {
        union() {
            cylinder(d = BR_HOUSE_OD, h = CAP_T);
            for (a = CAP_LOBE_A) rotate(a) translate([CAP_LOBE_R, 0, 0]) cylinder(d = 9, h = CAP_T);
        }
        translate([0, 0, -1]) cylinder(d = BR_OUT_ID, h = CAP_T + 2);
        for (a = CAP_LOBE_A) rotate(a) translate([CAP_LOBE_R, 0, -1]) {
            cylinder(d = M3, h = CAP_T + 2);
            translate([0, 0, CAP_T + 1 - 1.6]) cylinder(d1 = M3, d2 = 6.4, h = 1.61);
        }
    }
}

// Clamps the plate tube under the inner race, so the robot can be lifted by its head.
// Local frame: bottom face at z = 0 (countersinks underneath).
module clamp_ring() {
    t = LID_T - 0.3;
    difference() {
        cylinder(d = BR_IN_OD - 0.5, h = t);
        translate([0, 0, -1]) cylinder(d = 30.6, h = t + 2);
        for (a = CLAMP_A) rotate(a) translate([CLAMP_R, 0, -0.01]) {
            cylinder(d = M3, h = t + 1);
            cylinder(d1 = 6.4, d2 = M3, h = 1.6);
        }
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
        // driver access to the waist clutch screw (the head covers it)
        translate([0, 0, H - WALL - 1]) cylinder(d = 8, h = WALL + 2);
        // face cable up into the head
        translate([HEAD_CABLE[0], HEAD_CABLE[1], H - WALL - 1]) cylinder(d = 12, h = WALL + 2);
        for (p = HEAD_BOLT) translate([p[0], p[1], H + 0.01]) mirror([0, 0, 1]) insert_hole(INS_L + 1);
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
// One-piece arm in the v4 style: slim upper arm, fixed elbow bend, claw.
// Only the shoulder moves (servo + clutch in the torso).

// Disc with rounded edges along +Z.
module rdisk(d, h, r = 3) {
    hull() for (z = [r, h - r]) translate([0, 0, z]) rotate_extrude($fn = 48) translate([d / 2 - r, 0]) circle(r, $fn = 16);
}

module claw() {
    translate([-14, -10, -6]) rbox([28, 20, 12], 3);
    for (s = [-1, 1]) translate([s * 8, 0, -6]) rotate([0, s * 8, 0]) translate([-3, -8, -28]) rbox([6, 16, 30], 2.5);
}

module arm() {
    c = ARM_T / 2;      // limb centre line (x)
    difference() {
        union() {
            rotate([0, 90, 0]) rdisk(CL_D + 6, ARM_T, 4);                                   // shoulder disc
            translate([c - ARM_T / 2, -ARM_W / 2, -ARM_UP]) rbox([ARM_T, ARM_W, ARM_UP + 8], 5);   // upper arm
            translate([0, 0, -ARM_UP]) {
                rotate([0, 90, 0]) rdisk(20, ARM_T, 4);                                       // elbow knuckle
                rotate([-ARM_BEND, 0, 0]) {
                    translate([c - 10, -7, -ARM_FORE]) rbox([20, 14, ARM_FORE + 6], 5);       // forearm
                    translate([c, 0, -ARM_FORE - 2]) claw();
                }
            }
        }
        rotate([0, 90, 0]) limb_socket_cut(ARM_T, 5);                                         // shoulder clutch
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
    top_z = 12;              // underside of the fender above the deck; check track clearance
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
PARTS = ["lower_body", "lid", "tray", "waist", "bearing_cap", "clamp_ring", "torso", "chest_guard",
         "head_front", "head_back", "face_carrier", "arm", "clutch_hub", "bumper", "fender", "antenna",
         "base_frame", "sprocket_half", "sprocket_hub", "wheel_half", "road_wheel_half", "wheel_spacer", "track_link"];

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
    if (p == "arm") rotate([0, -90, 0]) translate([-ARM_T, 0, 0]) arm();
    if (p == "waist") rotate([180, 0, 0]) translate([0, 0, -WP[2]]) waist();
    if (p == "bearing_cap") bearing_cap();
    if (p == "clamp_ring") clamp_ring();
    if (p == "clutch_hub") clutch_hub();
    if (p == "bumper") rotate([-90, 0, 0]) bumper();
    if (p == "fender") fender();
    if (p == "antenna") antenna();
    if (p == "base_frame") rotate([180, 0, 0]) base_frame();
    if (p == "sprocket_half") rotate([0, 90, 0]) translate([-10.5, 0, 0]) sprocket_half();
    if (p == "sprocket_hub") rotate([0, 90, 0]) translate([14.5, 0, 0]) sprocket_hub();
    if (p == "wheel_half") rotate([0, -90, 0]) translate([-GROOVE_HW, 0, 0]) wheel_half();
    if (p == "road_wheel_half") rotate([0, -90, 0]) translate([-GROOVE_HW, 0, 0]) road_wheel_half();
    if (p == "wheel_spacer") wheel_spacer();
    if (p == "track_link") rotate([180, 0, 0]) track_link();
}

if (part != "none") print_part(part);
