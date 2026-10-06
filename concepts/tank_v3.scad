// Tank, revision 3: camera moved to the chest, VL53L0X distance sensor added.
// - Drive: off-the-shelf "mini TP101"-style aluminium tank chassis
//   (about 193 L x 163 W x 60 H mm, plastic link tracks, metal-gear motors).
//   The printed robot bolts onto its top deck.
// - Vision: ESP32-CAM (OV2640) lens in the chest, next to a VL53L0X
//   time-of-flight distance sensor, both behind one guarded panel.
// - Face: two 8x8 MAX7219 eyes + 8x8 mouth on one chain.
include <parts.scad>

CH_L = 193; CH_W = 163; CH_H = 60; TR_W = 30;

// Bought chassis (drawn approximately, for fit only)
module bought_chassis() {
    for (s = [-1, 1]) {
        translate([s * (CH_W / 2 - TR_W / 2), 0, CH_H / 2]) rotate([0, 0, 90]) track(CH_L, CH_H - 4, TR_W);
        // aluminium side plates inside the tracks
        color(C_SILVER) translate([s * (CH_W / 2 - TR_W - 2) - 1.5, -CH_L / 2 + 20, 10]) cube([3, CH_L - 40, 44]);
    }
    // aluminium deck
    color(C_SILVER) translate([-(CH_W / 2 - TR_W - 2), -CH_L / 2 + 18, 52]) cube([CH_W - 2 * TR_W - 4, CH_L - 36, 3]);
    // motors (rear, driving the rear sprockets)
    for (s = [-1, 1]) color([0.35, 0.35, 0.38]) translate([s * 22, CH_L / 2 - 40, 30]) rotate([0, s * 90, 0]) cylinder(d = 33, h = 40);
}

module arm(s) {
    translate([s * 52, 0, 150]) {
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

// ESP32-CAM lens module in a protective bezel, facing -Y
module camera() {
    color(C_DARK) rotate([90, 0, 0]) cylinder(d = 22, h = 4);              // rubber bezel
    color([0.1, 0.1, 0.12]) translate([0, -4, 0]) rotate([90, 0, 0]) cylinder(d = 12, h = 3);
    color([0.25, 0.35, 0.6]) translate([0, -7, 0]) rotate([90, 0, 0]) cylinder(d = 7, h = 0.6);
    color([0.75, 0.9, 1.0, 0.3]) translate([0, -4.5, 0]) rotate([90, 0, 0]) cylinder(d = 18, h = 1.5); // clear cover
}

// VL53L0X breakout behind a small window, facing -Y
module tof() {
    color(C_PCB) translate([-6.5, 0, -6.5]) cube([13, 1.6, 13]);
    color(C_DARK) translate([-4, -2, -2.5]) cube([8, 2, 5]);
    color([0.75, 0.9, 1.0, 0.3]) translate([-7, -3.5, -7]) cube([14, 1.2, 14]);
}

module tank_v3() {
    bought_chassis();
    // printed body shell bolted to the deck, overhangs the deck but stays inside the tracks
    color(C_SHELL) translate([-48, -88, 55]) rbox([96, 176, 50], r = 8);
    // TPU bumpers front and back, mounted to the shell, reaching past the tracks
    for (y = [-1, 1]) color(C_DARK) translate([0, y * 101, 72]) rotate([0, 90, 0]) cylinder(d = 20, h = 172, center = true);
    for (y = [-1, 1], x = [-30, 30]) color(C_DARK) translate([x, y * 92, 72]) cube([12, 16, 14], center = true);
    // printed track fenders (protect fingers from the track)
    for (s = [-1, 1]) color(C_SHELL2) translate([s * (CH_W / 2 - TR_W / 2) - 18, -CH_L / 2 - 4, 64]) rbox([36, CH_L + 8, 7], r = 3);
    // torso
    color(C_SHELL) translate([-48, -40, 105]) rbox([96, 80, 56], r = 10);
    // chest: camera + distance sensor behind a raised guard
    color(C_SHELL2) translate([0, -41, 134]) rotate([90, 0, 0]) rbox([64, 38, 6], r = 5, center = true);
    translate([-10, -44, 134]) camera();
    translate([17, -46, 134]) tof();
    // speaker grille for the buzzer on the lower body front
    for (x = [-20 : 8 : 20]) color(C_DARK) translate([x, -88.5, 80]) cube([4, 1.5, 22], center = true);
    // power button
    color([0.2, 0.85, 0.3]) translate([30, 10, 161]) cylinder(d = 14, h = 5);
    // neck (pan servo housing)
    color(C_GREY) translate([0, 0, 161]) cylinder(d = 40, h = 10);
    // head
    translate([0, 0, 171]) {
        color(C_SHELL) translate([-50, -36, 0]) rbox([100, 72, 100], r = 12);
        color(C_DARK) translate([-44, -38, 6]) rbox([88, 8, 88], r = 3);
        for (x = [-21, 21]) translate([x, -38.5, 64]) rotate([90, 0, 0]) { matrix8x8(EYE); window(); }
        translate([0, -38.5, 26]) rotate([90, 0, 0]) { matrix8x8(SMILE); window(); }
        // antenna (flexible TPU) doubles as the Wi-Fi status light
        color(C_DARK) translate([30, 10, 98]) cylinder(d = 5, h = 25);
        color([0.2, 0.6, 1.0]) translate([30, 10, 125]) sphere(d = 10);
    }
    arm(-1); arm(1);
}

tank_v3();
