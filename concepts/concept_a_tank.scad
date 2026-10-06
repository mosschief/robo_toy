// Concept A: "Tank" - tracked chassis, two 2-DOF arms, head on a pan servo,
// face = two 8x8 matrix eyes + 8x8 matrix mouth, HC-SR04 in the chest.
include <parts.scad>

module arm(s) {
    translate([s * 52, 0, 112]) {
        rotate([0, s * 90, 0]) mag_joint();
        translate([s * 13, 0, 0]) rotate([-45, 0, 0]) {
            limb(55);
            translate([0, 0, -55]) rotate([0, 90, 0]) color(C_GREY) cylinder(d = 18, h = 24, center = true);
            translate([0, 0, -55]) rotate([-50, 0, 0]) {
                limb(42, 20, 14);
                translate([0, 0, -44]) claw(8);
            }
        }
    }
}

module tank() {
    // tracks (robot drives along Y, faces -Y)
    for (s = [-1, 1]) translate([s * 72, 0, 31]) rotate([0, 0, 90]) track(175, 58, 32);
    // lower hull
    color(C_SHELL) translate([-56, -78, 14]) rbox([112, 156, 50], r = 8);
    // rubber bumper bars front/back
    for (y = [-1, 1]) color(C_DARK) translate([0, y * 88, 34]) rotate([0, 90, 0]) cylinder(d = 18, h = 176, center = true);
    // track fenders
    for (s = [-1, 1]) color(C_SHELL2) translate([s * 72 - 19, -90, 60]) rbox([38, 180, 8], r = 3);
    // torso
    color(C_SHELL) translate([-48, -40, 62]) rbox([96, 80, 62], r = 10);
    // chest ultrasonic behind a guard
    translate([0, -40, 92]) rotate([90, 0, 0]) hcsr04();
    color(C_SHELL2) translate([0, -42, 92]) rotate([90, 0, 0]) difference() {
        rbox([56, 30, 6], r = 3, center = true);
        for (x = [-13, 13]) translate([x, 0, 0]) cylinder(d = 17, h = 10, center = true);
    }
    // neck (pan servo housing)
    color(C_GREY) translate([0, 0, 124]) cylinder(d = 40, h = 10);
    // head
    translate([0, 0, 134]) {
        color(C_SHELL) translate([-50, -36, 0]) rbox([100, 72, 104], r = 12);
        // face plate
        color(C_DARK) translate([-44, -38, 6]) rbox([88, 8, 92], r = 3);
        for (x = [-21, 21]) translate([x, -38.5, 70]) rotate([90, 0, 0]) { matrix8x8(EYE); window(); }
        translate([0, -38.5, 26]) rotate([90, 0, 0]) { matrix8x8(SMILE); window(); }
        // antenna (flexible TPU)
        color(C_DARK) translate([30, 10, 102]) cylinder(d = 5, h = 25);
        color(C_LED) translate([30, 10, 129]) sphere(d = 10);
    }
    arm(-1); arm(1);
}

tank();
