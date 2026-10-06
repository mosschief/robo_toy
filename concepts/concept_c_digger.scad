// Concept C: "Digger" - two big wheels taller than the body plus a rear skid,
// rotating turret with a single 3-servo claw arm, HC-SR04 "eyes" ringed by
// WS2812 LED rings (Otto style), 8x8 matrix mouth.
include <parts.scad>

module digger() {
    // big wheels
    for (s = [-1, 1]) translate([s * 66, -10, 52]) wheel(104, 30);
    // rear skid ball
    color(C_DARK) translate([0, 70, 10]) sphere(d = 22);
    // body pod (wheels are taller, so it rolls over instead of landing on its face)
    color(C_SHELL) translate([-48, -62, 18]) rbox([96, 140, 72], r = 20);
    // front rubber nose bumper
    color(C_DARK) translate([0, -62, 40]) scale([1, 0.5, 0.6]) rotate([0, 90, 0]) cylinder(d = 40, h = 90, center = true);
    // turret ring + turret
    color(C_GREY) translate([0, 5, 90]) cylinder(d = 80, h = 6);
    translate([0, 5, 96]) {
        color(C_SHELL2) cylinder(d = 76, h = 8);
        // head
        color(C_SHELL) translate([-42, -38, 8]) rbox([84, 62, 76], r = 14);
        // ultrasonic eyes with LED rings
        translate([0, -39, 62]) rotate([90, 0, 0]) {
            hcsr04();
            for (x = [-13, 13]) translate([x, 0, 1]) led_ring([0.2, 0.8, 1.0]);
        }
        translate([0, -39.5, 28]) rotate([90, 0, 0]) { matrix8x8(SMILE); window(); }
        // arm: shoulder servo tower on the right of the head
        translate([52, 0, 40]) {
            color(C_SHELL2) translate([-8, -16, -32]) rbox([18, 32, 48], r = 4);
            translate([10, 0, 0]) rotate([0, 90, 0]) mag_joint(28);
            translate([16, 0, 0]) rotate([-140, 0, 0]) {
                limb(70, 22, 16);
                translate([0, 0, -70]) rotate([0, 90, 0]) color(C_GREY) cylinder(d = 20, h = 26, center = true);
                translate([0, 0, -70]) rotate([90, 0, 0]) {
                    limb(60, 20, 14);
                    translate([0, 0, -62]) rotate([60, 0, 0]) claw(12);
                }
            }
        }
    }
}

digger();
