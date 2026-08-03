// ---------------------------------------------------------------------------
// perfboard.scad - 4 x 6 cm prototyping board that carries the ESP32.
//
// The enclosure mounts to THIS board's four corner holes, not to the ESP32's.
// `pb_mount_positions()` is therefore the interface the housing is built
// around; the hole grid is cosmetic and can be switched off to render faster.
//
// Origin: center of the board, Z = 0 at the bottom face.
// +X is the long (60 mm) axis, matching the ESP32 model's convention, so the
// two boards' long axes line up when assembled.
//
// Render:  openscad -o build/perfboard.stl hardware/perfboard.scad
// ---------------------------------------------------------------------------

include <params.scad>

show_grid = true;   // false gives a fast preview - the grid is ~320 holes
$fn = $preview ? 16 : 32;

// Corner hole centers. Enclosure code should call this rather than re-deriving
// the pattern, so that a corrected inset propagates everywhere at once.
function pb_mount_positions() =
    [ for (sx = [-1,1], sy = [-1,1]) [sx*pb_mount_dx, sy*pb_mount_dy] ];

// Grid runs pb_rows along the 60 mm axis (X) and pb_cols along the 40 mm axis.
// $fn is pinned low here on purpose: this is ~320 holes of 1 mm, and at the
// default facet count CGAL takes over two minutes to difference them. At $fn=8
// it is a few seconds and looks identical at any sane render scale.
module pb_grid_holes() {
    for (r = [0 : pb_rows-1], c = [0 : pb_cols-1])
        translate([-(pb_rows-1)*pb_pitch/2 + r*pb_pitch,
                   -(pb_cols-1)*pb_pitch/2 + c*pb_pitch, -1])
            cylinder(h = pb_thick + 2, d = pb_hole_dia, $fn = 8);
}

module pb_mount_holes() {
    for (p = pb_mount_positions())
        translate([p[0], p[1], -1])
            cylinder(h = pb_thick + 2, d = pb_mount_dia);
}

// Oval edge pads. These are SURFACE PADS, not holes - solid tinned copper with
// nothing drilled through - so they are added on top of the board, never
// subtracted. They also run on their own pitch rather than the 2.54 grid.
module pb_edge_pads_solid() {
    for (sx = [-1,1], k = [0 : pb_edge_pads-1])
        translate([sx*pb_edge_pad_x,
                   -(pb_edge_pads-1)*pb_edge_pad_pitch/2 + k*pb_edge_pad_pitch,
                   pb_thick])
            hull() for (s = [-1,1])
                translate([s*(pb_edge_pad_l - pb_edge_pad_w)/2, 0, 0])
                    cylinder(h = pb_edge_pad_h, d = pb_edge_pad_w, $fn = 12);
}

module perfboard() {
    color("#1f7a5a")
        difference() {
            translate([0, 0, pb_thick/2])
                cube([pb_len, pb_width, pb_thick], center = true);
            pb_mount_holes();
            if (show_grid) pb_grid_holes();
        }
    if (show_grid) color("#d8d8d2") pb_edge_pads_solid();
}

// Clearance solid for enclosure boolean ops.
module perfboard_keepout(gap = clearance) {
    translate([0, 0, pb_thick/2])
        cube([pb_len + 2*gap, pb_width + 2*gap, pb_thick + 2*gap], center = true);
}

// --- guards -----------------------------------------------------------------

assert((pb_rows-1)*pb_pitch < pb_len,  "row grid does not fit the board length");
assert((pb_cols-1)*pb_pitch < pb_width,"column grid does not fit the board width");
assert(pb_mount_dx + pb_mount_dia/2 < pb_len/2,   "mount hole breaks the end edge");
assert(pb_mount_dy + pb_mount_dia/2 < pb_width/2, "mount hole breaks the side edge");

// The corner holes must clear the round grid. Getting this wrong merged them
// into keyholes, which is how the bad row count was caught in the first place.
assert(norm([pb_mount_dx - (pb_rows-1)*pb_pitch/2,
             pb_mount_dy - (pb_cols-1)*pb_pitch/2]) > (pb_mount_dia + pb_hole_dia)/2,
       "corner mounting hole collides with the round hole grid");
// ...and the SMD pad row must clear them too (pads run on their own pitch).
assert(pb_mount_dy - (pb_edge_pads-1)*pb_edge_pad_pitch/2
         > (pb_mount_dia + pb_edge_pad_w)/2,
       "corner mounting hole collides with the SMD edge pads");
assert(pb_edge_pad_x + pb_edge_pad_l/2 < pb_len/2,
       "SMD edge pads run off the end of the board");

perfboard();
