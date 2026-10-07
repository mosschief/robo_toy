// Shared geometry helpers for the Tank robot.
include <config.scad>

// Rounded box, corner at origin (or centred). Rounded on every edge.
module rbox(size, r = 6, center = false, fn = 20) {
    translate(center ? -size / 2 : [0, 0, 0])
    hull() for (x = [r, size[0] - r], y = [r, size[1] - r], z = [r, size[2] - r])
        translate([x, y, z]) sphere(r, $fn = fn);
}

// Box with rounded vertical edges and a flat top and bottom.
module rslab(size, r = 6, center = false) {
    translate(center ? -size / 2 : [0, 0, 0])
    hull() for (x = [r, size[0] - r], y = [r, size[1] - r])
        translate([x, y, 0]) cylinder(r = r, h = size[2]);
}

// Hollow rounded box (rounded everywhere), centred in X/Y, bottom at z = 0.
module rshell(size, r, wall = WALL) {
    difference() {
        translate([-size[0] / 2, -size[1] / 2, 0]) rbox(size, r);
        translate([-size[0] / 2 + wall, -size[1] / 2 + wall, wall])
            rbox([size[0] - 2 * wall, size[1] - 2 * wall, size[2] - 2 * wall], max(r - wall, 1));
    }
}

// Heat-set insert boss: solid post, insert hole opening at z = 0 facing -Z.
module insert_boss(h, d = BOSS_D) { cylinder(d = d, h = h); }
module insert_hole(depth = INS_L) { translate([0, 0, -0.01]) cylinder(d = INS_D, h = depth); }

// ---------- servo (vitamin, for the assembly view) ----------
// Origin: on the output shaft axis, in the plane of the TOP of the tabs.
// Shaft points +Z, body long axis along +X.
module servo_vitamin() {
    color([0.15, 0.35, 0.75]) {
        translate([SV_SHAFT - SV_L / 2, -SV_W / 2, -SV_TAB_T - SV_BELOW]) cube([SV_L, SV_W, SV_BELOW + SV_TAB_T + SV_ABOVE]);
        translate([SV_SHAFT - SV_TAB_L / 2, -SV_W / 2, -SV_TAB_T]) cube([SV_TAB_L, SV_W, SV_TAB_T]);
        cylinder(d = SV_DOME_D, h = SV_ABOVE + 2);
    }
    color("white") cylinder(d = 4.8, h = SV_SPLINE);
    color("white") translate([0, 0, HUB_FACE - HORN_T]) cylinder(d = HORN_D, h = HORN_T);
}

// Cut for a servo whose tabs press against the -Z face of a bulkhead.
// Bulkhead spans z = 0 .. bh. Screws go in from -Z through the tabs.
module servo_mount_cut(bh = 6) {
    // body above the tabs
    translate([SV_SHAFT - SV_L / 2 - CLR, -SV_W / 2 - CLR, -0.1]) cube([SV_L + 2 * CLR, SV_W + 2 * CLR, SV_ABOVE + 0.4]);
    // gear dome + horn boss pass straight through
    translate([0, 0, -0.1]) cylinder(d = SV_DOME_D + 1, h = bh + 0.2);
    // tab screw pilots
    for (s = [-1, 1]) translate([SV_SHAFT + s * SV_SCREW / 2, 0, -0.1]) cylinder(d = M2_PILOT, h = bh - 0.8);
    // body below the tabs (clearance)
    translate([SV_SHAFT - SV_TAB_L / 2 - 1, -SV_W / 2 - 1, -SV_TAB_T - SV_BELOW - 2]) cube([SV_TAB_L + 2, SV_W + 2, SV_BELOW + SV_TAB_T + 2]);
}

// ---------- clutch ----------
// One ridge/groove: triangular prism along +X from r0 to r1, base on z = 0, apex at +Z.
module ridge(h, w, r0 = 3.5, r1 = CL_D / 2) {
    translate([r0, 0, 0]) rotate([0, 90, 0])
        linear_extrude(r1 - r0) polygon([[0, -w / 2], [0, w / 2], [-h, 0]]);
}
module ridges(h = CL_RH, w = CL_RW, r1 = CL_D / 2) {
    for (i = [0 : CL_RIDGES - 1]) rotate(i * 360 / CL_RIDGES) ridge(h, w, 3.5, r1);
}

// Horn hub (printable part). Servo side at z = 0, ridges on top.
module clutch_hub() {
    difference() {
        union() {
            cylinder(d = CL_D, h = CL_T);
            translate([0, 0, CL_T]) ridges();
        }
        // disk horn recess
        translate([0, 0, -0.01]) cylinder(d = HORN_D + 0.6, h = HORN_T + 0.2);
        // M2 horn screw head + driver access
        translate([0, 0, -0.01]) cylinder(d = 5.2, h = 4.6);
        // horn fixing screws (self-tapping, from the horn side)
        for (a = [90, 270]) rotate(a) translate([HORN_HOLE_R, 0, -0.01]) cylinder(d = M2_PILOT, h = 6);
        // side-loading M3 nut slot
        translate([0, 0, 5]) {
            cylinder(d = NUT_AF / cos(30), h = NUT_T, $fn = 6);
            translate([0, -NUT_AF / 2, 0]) cube([CL_D, NUT_AF, NUT_T]);
        }
        // M3 clearance up through the ridges
        translate([0, 0, -1]) cylinder(d = M3, h = CL_T + CL_RH + 2);
    }
}

// Limb-side cut. Contact face at z = 0, limb material toward +Z.
// depth: how thick the limb is here; spring pocket opens on the far side.
module limb_socket_cut(depth, floor = 4) {
    translate([0, 0, -0.01]) ridges(CL_RH + 0.4, CL_RW * 1.25, CL_D / 2 + 1);
    translate([0, 0, -1]) cylinder(d = M3 + 0.4, h = depth + 2);
    translate([0, 0, floor]) cylinder(d = SPRING_D, h = depth);
}

// A boss ring around the limb socket so the grooves have material.
module limb_socket_boss(depth) { cylinder(d = CL_D + 4, h = depth); }
