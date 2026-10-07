// Printed tracked base, a scaled-up SMARS-style design.
// Replaces the bought TP101 chassis: the lower body bolts onto the deck.
// World frame: deck top at z = 0, front is -Y, right track on +X.
// The right track is driven at the front, the left at the rear, so the two
// motors sit side by side under the deck without touching.
include <lib.scad>

LB_FLOOR_SCREWS = [for (x = [-1, 1], y = [-28, 20, 80]) [x * 22, y]];   // match the lower body floor slots
ROAD_Y = [-22, 22];

function drive_y(s) = s > 0 ? -TK_S / 2 : TK_S / 2;
function idler_y(s) = -drive_y(s);
function mot_x(s) = s * (FR_X - FR_T);       // motor gearbox face (inner face of the side frame)
MOT_Z = Z_AXLE - MOT_OFF;                    // motor can centre (below the shaft)

// ---------- base frame: deck + both side frames, one print (deck on the bed) ----------
module side_frame_solid(s) {
    x0 = s > 0 ? FR_X - FR_T : -FR_X;
    hull() {
        for (y = [-TK_S / 2, TK_S / 2]) translate([x0, y, Z_AXLE]) rotate([0, 90, 0]) cylinder(r = 15, h = FR_T);
        translate([x0, -TK_S / 2 - 15, -DECK_T]) cube([FR_T, TK_S + 30, DECK_T]);
    }
    // axle bosses on the outside: spacers for the bearing inner races
    for (y = ROAD_Y) translate([s * FR_X, y, Z_RW]) rotate([0, s * 90, 0]) cylinder(d = 11, h = 2.5);
    hull() for (d = [-4, 4]) translate([s * FR_X, idler_y(s) + d, Z_AXLE]) rotate([0, s * 90, 0]) cylinder(d = 11, h = 2.5);
    // motor tail cradle hanging from the deck
    translate([mot_x(s) - s * 40 - 4, drive_y(s) - MOT_CAN_D / 2 - 4, MOT_Z]) cube([8, MOT_CAN_D + 8, -MOT_Z - DECK_T + 0.01]);
}

module side_frame_cuts(s) {
    // road wheel axles (M8) and the idler slot (slide to tension the track)
    for (y = ROAD_Y) translate([s * FR_X, y, Z_RW]) rotate([0, 90, 0]) cylinder(d = 8.4, h = 40, center = true);
    hull() for (d = [-4, 4]) translate([s * FR_X, idler_y(s) + d, Z_AXLE]) rotate([0, 90, 0]) cylinder(d = 8.4, h = 40, center = true);
    // motor: shaft + sprocket boss opening, two face screws (counterbored outside)
    translate([s * FR_X, drive_y(s), Z_AXLE]) rotate([0, 90, 0]) cylinder(d = 16, h = 40, center = true);
    for (d = [-1, 1]) translate([s * FR_X, drive_y(s) + d * MOT_HOLE_SP / 2, MOT_Z]) rotate([0, s * -90, 0]) {
        translate([0, 0, -1]) cylinder(d = M3, h = FR_T + 2);
        translate([0, 0, -1]) cylinder(d = M3_HEAD, h = 4);
    }
    // cradle saddle for the motor can, with a zip-tie hole through it
    translate([mot_x(s) - s * 26, drive_y(s), MOT_Z]) rotate([0, 90, 0]) cylinder(d = MOT_CAN_D + 0.6, h = 40, center = true);
    translate([mot_x(s) - s * 40 - 5, drive_y(s) - MOT_CAN_D / 2 - 1.5, MOT_Z + MOT_CAN_D / 2 + 1.5]) cube([10, MOT_CAN_D + 3, 2.5]);
}

module base_frame() {
    difference() {
        union() {
            translate([-FR_X, -LB[1] / 2, -DECK_T]) rslab([2 * FR_X, LB[1], DECK_T], 6);
            for (s = [-1, 1]) side_frame_solid(s);
            for (p = LB_FLOOR_SCREWS) translate([p[0], p[1], -DECK_T - 6]) cylinder(d = BOSS_D, h = 6.01);
        }
        for (s = [-1, 1]) side_frame_cuts(s);
        for (p = LB_FLOOR_SCREWS) translate([p[0], p[1], 0.01]) mirror([0, 0, 1]) insert_hole(INS_L + 1);
        // motor wires up into the lower body
        translate([-17, 33, -DECK_T - 1]) cube([34, 14, DECK_T + 2]);
    }
}

// ---------- drive sprocket: two identical halves + a hub on the motor shaft ----------
// Local frame: axle along X, x = 0 on the track centre line, side frame toward -X.
SPR_DISK_R = TK_R * cos(180 / SPR_T) - LINK_T / 2 - 0.3;   // the link plates rest on this
SPR_FRAME_X = FR_X - TK_X;                  // side frame outer face (local x, -15.5)
GROOVE_HW = 3.5;                            // half width of the guide-horn groove
SPR_SCREWS = [0, 120, 240];                 // 3 x M3 x 20 hold the halves to the hub

// Outer half (x >= 0); the inner half is the same part turned round.
module sprocket_half() {
    difference() {
        union() {
            translate([GROOVE_HW, 0, 0]) rotate([0, 90, 0]) cylinder(r = SPR_DISK_R, h = 10.5 - GROOVE_HW, $fn = 64);
            rotate([0, 90, 0]) cylinder(r = 14, h = GROOVE_HW + 0.01);
            for (i = [0 : SPR_T - 1]) rotate([i * 360 / SPR_T + 180 / SPR_T, 0, 0]) hull() {
                translate([5.5, -2.5, SPR_DISK_R - 1]) cube([5, 5, 1]);
                translate([5.5, -1.5, SPR_DISK_R + LINK_T + 1]) cube([5, 3, 0.5]);
            }
        }
        d_bore(12);
        for (a = SPR_SCREWS) rotate([a, 0, 0]) translate([-1, 0, 10]) rotate([0, 90, 0]) {
            cylinder(d = M3, h = 14);
            translate([0, 0, 11.5 - 4.5 + 1]) cylinder(d = M3_HEAD, h = 6);   // head recess in the outer face
        }
    }
}

module d_bore(len) {
    translate([-len / 2, 0, 0]) rotate([0, 90, 0]) intersection() {
        cylinder(d = MOT_SHAFT_D + 0.15, h = len);
        translate([-(MOT_SHAFT_D + 1) / 2, -(MOT_SHAFT_D + 1) / 2, 0])
            cube([(MOT_SHAFT_D + 1) / 2 + MOT_SHAFT_FLAT - MOT_SHAFT_D / 2 + 0.1, MOT_SHAFT_D + 1, len]);
    }
}

// Hub: flange against the inner sprocket half, boss through the side frame to the motor.
// Local frame as the sprocket.
module sprocket_hub() {
    difference() {
        union() {
            translate([-14.5, 0, 0]) rotate([0, 90, 0]) cylinder(d = 24, h = 4);
            translate([SPR_FRAME_X - FR_T + 0.5, 0, 0]) rotate([0, 90, 0]) cylinder(r = 7, h = -14.5 - (SPR_FRAME_X - FR_T + 0.5) + 0.01);
        }
        translate([-16, 0, 0]) d_bore(14);
        // M3 set screw onto the flat, through the flange rim
        translate([-12.5, 0, 0]) cylinder(d = 2.6, h = 13);
        for (a = SPR_SCREWS) rotate([a, 0, 0]) translate([-15, 0, 10]) rotate([0, 90, 0]) cylinder(d = 2.6, h = 6);
    }
}

module sprocket() {
    sprocket_half();
    mirror([1, 0, 0]) sprocket_half();
    sprocket_hub();
}

// ---------- idler and road wheels: two identical halves, one 608 bearing each ----------
// Local frame: axle along X, x = 0 on the track centre line. This is the +X half.
module wheel_half(r = WHEEL_R) {
    difference() {
        translate([GROOVE_HW, 0, 0]) rotate([0, 90, 0]) cylinder(r = r, h = TK_W / 2 - GROOVE_HW, $fn = 64);
        translate([TK_W / 2 - BRG608[2], 0, 0]) rotate([0, 90, 0]) cylinder(d = BRG608[1] + 0.1, h = BRG608[2] + 1);
        rotate([0, 90, 0]) cylinder(d = BRG608[0] + 2, h = 40, center = true);
    }
}
// Keeps the two inner races apart on the M8 axle.
module wheel_spacer() {
    difference() {
        cylinder(d = 11, h = TK_W - 2 * BRG608[2]);
        translate([0, 0, -1]) cylinder(d = 8.4, h = TK_W);
    }
}
module road_wheel_half() { wheel_half(RW_R); }
module wheel(r = WHEEL_R) {
    wheel_half(r);
    mirror([1, 0, 0]) wheel_half(r);
    color("silver") translate([-TK_W / 2 + BRG608[2], 0, 0]) rotate([0, 90, 0]) wheel_spacer();
}

// ---------- track link: PETG, joined with M3 x 25 screws + nyloc nuts ----------
// Local frame: x across the track, pins at y = +-TK_P/2, z = 0 on the pitch line, +Z = outside (ground).
module track_link() {
    W = TK_W / 2; P = TK_P;
    difference() {
        union() {
            translate([-W, -P / 2, -LINK_T / 2]) cube([2 * W, P, LINK_T]);
            for (sg = [[-W, -6.75], [6.75, W]]) translate([sg[0], -P / 2, 0]) rotate([0, 90, 0]) cylinder(d = KN_D, h = sg[1] - sg[0]);
            translate([-6.25, P / 2, 0]) rotate([0, 90, 0]) cylinder(d = KN_D, h = 12.5);
            // guide horn (runs in the wheel and sprocket grooves)
            hull() {
                translate([-2.5, -3, -LINK_T / 2 - 0.01]) cube([5, 6, 0.01]);
                translate([-1.5, -2, -LINK_T / 2 - HORN_H]) cube([3, 4, 0.01]);
            }
            // grip ribs, between the tooth windows
            for (sg = [[-W, -11.5], [-4.5, 4.5], [11.5, W]]) translate([sg[0], -2, LINK_T / 2 - 0.01]) cube([sg[1] - sg[0], 4, GROUSER]);
        }
        // room for the next link's knuckles
        translate([-6.75, -P / 2, 0]) rotate([0, 90, 0]) cylinder(d = KN_D + 1, h = 13.5);
        for (sg = [[-W - 1, -5.75], [5.75, W + 1]]) translate([sg[0], P / 2, 0]) rotate([0, 90, 0]) cylinder(d = KN_D + 1, h = sg[1] - sg[0]);
        // pin holes, screw head and nut recesses
        for (y = [-P / 2, P / 2]) translate([-W - 1, y, 0]) rotate([0, 90, 0]) cylinder(d = 3.3, h = 2 * W + 2);
        translate([W - 2.6, -P / 2, 0]) rotate([0, 90, 0]) cylinder(d = 6, h = 3);
        translate([-W - 0.01, -P / 2, 0]) rotate([0, 90, 0]) rotate(30) cylinder(d = NUT_AF / cos(30), h = 3.5, $fn = 6);
        // sprocket tooth windows
        for (sx = [-8, 8]) translate([sx - 3, -3, -LINK_T]) cube([6, 6, 2 * LINK_T]);
    }
}

// ---------- vitamins for the assembly view ----------
module gearmotor_vitamin() {
    // shaft on the origin pointing +X; can centre MOT_OFF below
    color([0.75, 0.75, 0.78]) translate([0, 0, -MOT_OFF]) rotate([0, -90, 0]) {
        cylinder(d = MOT_GB_D, h = 21);
        translate([0, 0, 21]) cylinder(d = MOT_CAN_D, h = MOT_LEN - 21);
    }
    color("silver") rotate([0, 90, 0]) cylinder(d = MOT_SHAFT_D, h = 12);
}

// pins of one track loop, for drawing it (arcs approximated by the sprocket wrap)
TK_RR = SPR_T / 2 * TK_P / PI;
TK_LOOP = 2 * TK_S + 2 * PI * TK_RR;
function tk_pin(u) = let(v = u - floor(u / TK_LOOP) * TK_LOOP)
    v < TK_S ? [-TK_S / 2 + v, -TK_RR] :
    v < TK_S + PI * TK_RR ? let(a = (v - TK_S) / TK_RR * 180 / PI) [TK_S / 2 + TK_RR * sin(a), -TK_RR * cos(a)] :
    v < 2 * TK_S + PI * TK_RR ? [TK_S / 2 - (v - TK_S - PI * TK_RR), TK_RR] :
    let(a = (v - 2 * TK_S - PI * TK_RR) / TK_RR * 180 / PI) [-TK_S / 2 - TK_RR * sin(a), TK_RR * cos(a)];

module track_loop() {
    for (i = [0 : TK_N - 1]) {
        p1 = tk_pin(i * TK_P + 3); p2 = tk_pin((i + 1) * TK_P + 3);
        m = (p1 + p2) / 2;
        translate([0, m[0], m[1]]) rotate([atan2(p2[1] - p1[1], p2[0] - p1[0]) + 180, 0, 0]) track_link();
    }
}

module base_assy() {
    color([0.2, 0.45, 0.85]) base_frame();
    for (s = [-1, 1]) {
        translate([mot_x(s), drive_y(s), Z_AXLE]) mirror([s < 0 ? 1 : 0, 0, 0]) gearmotor_vitamin();
        translate([s * TK_X, 0, Z_AXLE]) {
            color([0.95, 0.75, 0.2]) translate([0, drive_y(s), 0]) mirror([s < 0 ? 1 : 0, 0, 0]) sprocket();
            color([0.95, 0.75, 0.2]) translate([0, idler_y(s), 0]) wheel();
            color([0.95, 0.75, 0.2]) for (y = ROAD_Y) translate([0, y, Z_RW - Z_AXLE]) wheel(RW_R);
            color([0.16, 0.16, 0.18]) track_loop();
        }
    }
}
