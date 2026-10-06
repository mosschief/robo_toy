// Concept B: "Brick" - 4WD skid-steer with chunky TPU tyres tucked under
// fenders, wrap-around rubber bumper, one-piece head/torso "brick" body,
// two arms with grippers, three 8x8 matrices behind a window, HC-SR04 in the grille.
include <parts.scad>

module arm(s) {
    translate([s * 60, -5, 150]) {
        rotate([0, s * 90, 0]) mag_joint(30);
        translate([s * 14, 0, 0]) rotate([-70, 0, 0]) {
            limb(60, 24, 18);
            translate([0, 0, -64]) rotate([0, 0, 90]) claw(10);
        }
    }
}

module brick() {
    // wheels
    for (sx = [-1, 1], sy = [-1, 1]) translate([sx * 70, sy * 55, 36]) wheel(72, 32);
    // chassis tub
    color(C_SHELL2) translate([-52, -88, 16]) rbox([104, 176, 46], r = 8);
    // fenders covering the top half of each wheel
    for (sx = [-1, 1], sy = [-1, 1]) color(C_SHELL)
        translate([sx * 70, sy * 55, 36]) intersection() {
            rotate([90, 0, 90]) difference() {
                cylinder(r = 46, h = 40, center = true);
                cylinder(r = 40, h = 50, center = true);
            }
            translate([-30, -60, 4]) cube([60, 120, 60]);
        }
    // wrap-around bumper (TPU) at wheel-centre height
    color(C_DARK) translate([0, 0, 36]) difference() {
        hull() for (x = [-80, 80], y = [-110, 110]) translate([x, y, 0]) cylinder(r = 14, h = 14, center = true);
        hull() for (x = [-72, 72], y = [-102, 102]) translate([x, y, 0]) cylinder(r = 10, h = 20, center = true);
    }
    for (x = [-1, 1], y = [-1, 1]) color(C_DARK) translate([x * 30, y * 98, 36]) cube([10, 20, 12], center = true);
    // grille with ultrasonic
    translate([0, -89, 40]) rotate([90, 0, 0]) hcsr04();
    // body / head brick
    color(C_SHELL) translate([-58, -50, 62]) rbox([116, 100, 120], r = 16);
    // face window
    color(C_DARK) translate([-48, -52, 82]) rbox([96, 6, 88], r = 4);
    color([0.75, 0.9, 1.0, 0.15]) translate([-46, -54, 84]) cube([92, 2, 84]);
    for (x = [-22, 22]) translate([x, -53, 146]) rotate([90, 0, 0]) matrix8x8(EYE);
    translate([0, -53, 104]) rotate([90, 0, 0]) matrix8x8(SMILE);
    // carry handle on top (doubles as roll bar)
    color(C_DARK) translate([0, 10, 182]) rotate([0, 90, 0]) difference() {
        scale([1, 1.6, 1]) cylinder(r = 22, h = 70, center = true);
        scale([1, 1.6, 1]) cylinder(r = 15, h = 80, center = true);
        translate([22, 0, 0]) cube([44, 90, 90], center = true);
    }
    // big power button
    color([0.2, 0.85, 0.3]) translate([35, 30, 180]) cylinder(d = 16, h = 6);
    arm(-1); arm(1);
}

brick();
