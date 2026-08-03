// ---------------------------------------------------------------------------
// connector.scad - "JST-XH style" 2.54 mm 4-pin board header.
//
// Rough model, same spirit as the others: the shroud outline, height and pin
// pattern are real; the latch ramp and internal detail are not modeled.
//
// Origin: center of the pin row, on the board surface.
//   Z = 0 is the PCB TOP face - the connector sits on it, pins run negative.
//   (Note this differs from esp32.scad / perfboard.scad, where Z = 0 is the
//   PCB bottom. Placing this on the perfboard means translating to Z = pb_thick.)
//   +X runs along the pin row, +Y toward the latch side.
//
// Render:  openscad -o build/connector.stl hardware/connector.scad
// ---------------------------------------------------------------------------

include <params.scad>

$fn = $preview ? 24 : 48;

// Pin 1 .. n centers along X, centered on the origin.
function xh_pin_x(i) = -xh_pin_span/2 + i*xh_pitch;

module xh_pins() {
    for (i = [0 : xh_pins-1])
        translate([xh_pin_x(i), 0, -xh_pin_below])
            cube([xh_pin_sq, xh_pin_sq, xh_pin_below + xh_body_h*0.6], center = false);
}

// Shroud: a box around the pin row, deeper on the latch side, hollowed from
// the top so the model reads as a socket rather than a solid block.
module xh_shroud() {
    wall = 0.9;
    difference() {
        translate([-xh_body_len/2, -xh_body_front, 0])
            cube([xh_body_len, xh_body_front + xh_body_back, xh_body_h]);
        translate([-xh_body_len/2 + wall, -xh_body_front + wall, wall])
            cube([xh_body_len - 2*wall,
                  xh_body_front + xh_body_back - 2*wall,
                  xh_body_h]);
    }
}

module xh_header() {
    color("#e8e8e8") xh_shroud();
    color("#c8a24a") translate([-xh_pin_sq/2, -xh_pin_sq/2, 0]) xh_pins();
}

// Drill pattern, for cutting into a carrier board.
module xh_drills(h = 10) {
    for (i = [0 : xh_pins-1])
        translate([xh_pin_x(i), 0, -h/2]) cylinder(h = h, d = xh_drill);
}

// Clearance solid including the MATED plug. Use this against a lid, not
// xh_header() - the plug is what actually collides.
//
// This used the HEADER's outline until the fit gauge showed the plug is about
// 1 mm per side bigger. It is centred on the header's body, not on the pin row,
// because the shroud is asymmetric about the pins.
function xh_body_cx() = (xh_body_back - xh_body_front)/2;

module xh_mated_keepout(gap = clearance) {
    translate([0, xh_body_cx(), xh_mated_h/2 - gap/2])
        cube([xh_plug_len + 2*gap,
              xh_plug_depth + 2*gap,
              xh_mated_h + gap], center = true);
}

// --- guards -----------------------------------------------------------------

assert(xh_pitch > 2.4 && xh_pitch < 2.6, "XH pitch should be 2.50 or 2.54");
assert(xh_drill > xh_pin_sq * 1.414,
       "drill smaller than the diagonal of the square post");
assert(xh_mated_h > xh_body_h,
       "mated height must exceed the bare header height");
assert(xh_plug_len >= xh_body_len && xh_plug_depth >= xh_body_front + xh_body_back,
       "the plug cannot be smaller than the header it pushes over");

xh_header();
