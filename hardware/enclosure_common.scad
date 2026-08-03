// ---------------------------------------------------------------------------
// enclosure_common.scad - shell primitives shared by the two enclosures.
//
// This file deliberately holds NO dimensions. Every module takes what it needs
// as an argument, so params.scad stays the single source of truth and the
// sensor pod can reuse the same primitives at its own (much smaller) scale.
//
// Everything here is built for a tub printed open-side-up and a lid printed
// face-down: no module below produces an unsupported horizontal surface.
// ---------------------------------------------------------------------------

// Rounded-corner box, centered in X and Y, rising from z = 0.
// r = 0 gives a plain cube.
module rbox(len, wid, h, r) {
    if (r <= 0)
        translate([0, 0, h/2]) cube([len, wid, h], center = true);
    else
        hull() for (sx = [-1,1], sy = [-1,1])
            translate([sx*(len/2 - r), sy*(wid/2 - r), 0])
                cylinder(h = h, r = r);
}

// A rounded slot lying in the XY plane, running along X, extruded up Z.
// Used for vents and for anything that wants no sharp internal corners.
module pill(len, wid, h) {
    hull() for (s = [-1,1])
        translate([s*(len - wid)/2, 0, 0]) cylinder(h = h, d = wid);
}

// Vertical vent slots in a wall: n pills standing on end, centered on the
// origin, running along X. Cut through a wall of thickness `thk` (in Y).
module vent_slots(n, pitch, w, h, thk) {
    for (i = [0 : n-1])
        translate([-(n-1)*pitch/2 + i*pitch, 0, 0])
            rotate([-90, 0, 0]) rotate([0, 0, 90])
                translate([0, 0, -thk/2]) pill(h, w, thk);
}

// A screw column. `bore` runs the full height; `tap` narrows the far end so a
// self-tapping screw has something to bite. Printed standing up, the step from
// bore to tap is a shallow annular overhang, which prints fine.
//   tap_len = 0  ->  plain clearance tube
module screw_column(h, od, bore, tap = 0, tap_len = 0) {
    difference() {
        cylinder(h = h, d = od);
        translate([0, 0, -0.1]) cylinder(h = h - tap_len + 0.1, d = bore);
        if (tap_len > 0)
            translate([0, 0, h - tap_len]) cylinder(h = tap_len + 0.1, d = tap);
    }
}

// Conical flare at the root of a column, where it meets the plate it stands on.
// A 4.2 mm post joined to a flat face at a sharp 90 degrees is both a stress
// riser and, in FDM, a joint in the weakest direction - the fit gauge's posts
// sheared off there under nothing worse than a screwdriver. Free to print: the
// cone is wider at the bottom, so it never overhangs.
module root_fillet(d, r) {
    cylinder(h = r, d1 = d + 2*r, d2 = d);
}

// Through hole with a counterbore for the screw head, cut downward from z = 0.
module screw_bore(depth, bore, head_d, head_h) {
    translate([0, 0, -depth - 0.1]) cylinder(h = depth + 0.2, d = bore);
    translate([0, 0, -depth - 0.1]) cylinder(h = head_h + 0.1, d = head_d);
}
