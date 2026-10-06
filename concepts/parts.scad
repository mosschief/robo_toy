// Shared placeholder parts for the robot toy concepts.
// Dimensions are nominal (mm) so the concepts are drawn to real scale.

$fn = 48;

C_SHELL  = [1.00, 0.62, 0.10];   // bright orange printed shell
C_SHELL2 = [0.16, 0.45, 0.85];   // blue accent
C_DARK   = [0.18, 0.18, 0.20];   // TPU / rubber
C_GREY   = [0.55, 0.57, 0.60];
C_PCB    = [0.10, 0.35, 0.18];
C_LED    = [1.00, 0.15, 0.10];
C_LEDOFF = [0.28, 0.26, 0.26];
C_SILVER = [0.80, 0.82, 0.85];

module rbox(size, r = 6, center = false) {
    // rounded box (rounded vertical edges + top/bottom), friendly for kids
    translate(center ? -size / 2 : [0, 0, 0])
    hull() for (x = [r, size[0] - r], y = [r, size[1] - r], z = [r, size[2] - r])
        translate([x, y, z]) sphere(r, $fn = 20);
}

// MAX7219 8x8 module face (32 x 32 mm), shown with a pattern lit.
// pattern: 8 strings of 8 chars, "#" = lit.
module matrix8x8(pattern) {
    color(C_PCB) translate([-16, -16, -2]) cube([32, 32, 2]);
    color(C_DARK) translate([-16, -16, 0]) cube([32, 32, 1.2]);
    for (r = [0:7], c = [0:7]) {
        lit = pattern[r][c] == "#";
        color(lit ? C_LED : C_LEDOFF)
            translate([-14 + c * 4, 14 - r * 4, 1.2]) cylinder(d = 2.8, h = lit ? 1.0 : 0.4, $fn = 12);
    }
}

SMILE = [
    "........",
    "........",
    "#......#",
    "#......#",
    ".#....#.",
    "..####..",
    "........",
    "........"];

EYE = [
    "..####..",
    ".######.",
    "########",
    "###..###",
    "###..###",
    "########",
    ".######.",
    "..####.."];

// Clear-ish window bezel that protects a matrix (polycarbonate / PETG window)
module window(w = 36, h = 36, t = 2) {
    color([0.75, 0.9, 1.0, 0.12]) translate([-w / 2, -h / 2, 1.6]) cube([w, h, t]);
}

// HC-SR04 ultrasonic: 45 x 20 PCB, two 16 mm transducers
module hcsr04() {
    color(C_PCB) translate([-22.5, -10, -1.6]) cube([45, 20, 1.6]);
    for (x = [-13, 13]) translate([x, 0, 0]) {
        color(C_SILVER) cylinder(d = 16, h = 12);
        color([0.25, 0.25, 0.25]) translate([0, 0, 11.6]) cylinder(d = 12, h = 0.6);
    }
}

// WS2812 12-LED ring (37 mm OD)
module led_ring(col = [0.2, 0.8, 1.0]) {
    color(C_DARK) difference() { cylinder(d = 37, h = 1.6); translate([0, 0, -1]) cylinder(d = 23, h = 4); }
    for (i = [0:11]) rotate(i * 30) translate([15, 0, 1.6]) color(col) cube([4, 4, 1.4], center = true);
}

// SG90 / MG90S body (23 x 12.5 x 22.5 + tabs), output shaft at origin pointing +Z
module sg90() {
    color(C_SHELL2 * 0.6) translate([-6, -6.25, -22.5]) cube([23, 12.5, 22.5]);
    color(C_SHELL2 * 0.6) translate([-10.5, -6.25, -6]) cube([32, 12.5, 2.5]);
    color("white") cylinder(d = 5, h = 4);
}

// TT gear motor placeholder (body runs along +X from origin, shaft along Y)
module tt_motor() {
    color([1, 0.85, 0.1]) translate([0, -11, -9]) cube([37, 22, 18]);
    color(C_SILVER) translate([37, 0, 0]) rotate([0, 90, 0]) cylinder(d = 20, h = 25);
}

// Chunky wheel: printed hub + TPU tyre with tread blocks
module wheel(d = 70, w = 30) {
    rotate([90, 0, 0]) {
        color(C_DARK) difference() {
            cylinder(d = d, h = w, center = true);
            cylinder(d = d - 14, h = w + 2, center = true);
        }
        for (i = [0:17]) rotate(i * 20) translate([d / 2, 0, 0])
            color(C_DARK) cube([4, 6, w], center = true);
        color(C_SHELL2) cylinder(d = d - 13, h = w - 4, center = true);
        color(C_GREY) for (i = [0:4]) rotate(i * 72) translate([12, 0, 0]) cylinder(d = 7, h = w, center = true);
        color(C_SILVER) cylinder(d = 10, h = w + 1, center = true);
    }
}

// Tank track module: stadium loop along X, centred at origin, width w along Y
module track(len = 170, h = 60, w = 32) {
    r = h / 2;
    // rubber band
    color(C_DARK) rotate([90, 0, 0]) difference() {
        hull() for (x = [-len / 2 + r, len / 2 - r]) translate([x, 0, 0]) cylinder(r = r, h = w, center = true);
        hull() for (x = [-len / 2 + r, len / 2 - r]) translate([x, 0, 0]) cylinder(r = r - 5, h = w + 2, center = true);
    }
    // grousers on top and bottom
    for (x = [-len / 2 + r : 12 : len / 2 - r], z = [-r - 1.5, r + 1.5])
        color(C_DARK) translate([x, 0, z]) cube([5, w, 3], center = true);
    // sprockets / road wheels
    for (x = [-len / 2 + r, len / 2 - r]) translate([x, 0, 0]) rotate([90, 0, 0]) {
        color(C_SHELL2) cylinder(r = r - 6, h = w - 6, center = true);
        color(C_SILVER) cylinder(d = 10, h = w, center = true);
    }
    for (x = [-len / 2 + r + 30 : 25 : len / 2 - r - 20]) translate([x, 0, -r + 15]) rotate([90, 0, 0])
        color(C_GREY) cylinder(r = 10, h = w - 8, center = true);
}

// Simple claw/gripper at origin, opening along X, pointing -Z
module claw(open = 10) {
    color(C_SHELL) translate([-14, -10, -6]) rbox([28, 20, 12], r = 3);
    for (s = [-1, 1]) color(C_SHELL2)
        translate([s * open, 0, -6]) rotate([0, s * 8, 0]) translate([-3, -8, -28]) rbox([6, 16, 30], r = 2.5);
}

// Rounded arm segment from origin along -Z
module limb(len = 50, w = 22, t = 16) {
    color(C_SHELL) translate([-w / 2, -t / 2, -len]) rbox([w, t, len], r = 5);
}

// Magnetic breakaway joint disc (indicates arm pops off instead of stripping gears)
module mag_joint(d = 26) {
    color(C_GREY) cylinder(d = d, h = 4, center = true);
    for (i = [0:3]) rotate(i * 90 + 45) translate([d / 2 - 5, 0, 2]) color(C_SILVER) cylinder(d = 6, h = 1);
}

// 2 x 2 MAX7219 8x8 modules = one 16 x 16 display (64 x 64 mm).
// pattern: 16 strings of 16 chars, "#" = lit.
module matrix16x16(pattern) {
    for (tr = [0, 1], tc = [0, 1]) {
        color(C_PCB) translate([-32 + tc * 32, 32 - (tr + 1) * 32, -2]) cube([31.6, 31.6, 2]);
        color(C_DARK) translate([-32 + tc * 32, 32 - (tr + 1) * 32, 0]) cube([31.6, 31.6, 1.2]);
    }
    for (r = [0:15], c = [0:15]) {
        lit = pattern[r][c] == "#";
        color(lit ? C_LED : C_LEDOFF)
            translate([-30 + c * 4, 30 - r * 4, 1.2]) cylinder(d = 2.8, h = lit ? 1.0 : 0.4, $fn = 12);
    }
}

FACE16 = [
    "................",
    "..####....####..",
    ".######..######.",
    ".##..##..##..##.",
    ".##..##..##..##.",
    ".######..######.",
    "..####....####..",
    "................",
    "................",
    "................",
    ".#............#.",
    ".##..........##.",
    "..###......###..",
    "...##########...",
    ".....######.....",
    "................"];
