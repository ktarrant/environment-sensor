// ---------------------------------------------------------------------------
// fitgauge.scad - print THIS before either enclosure.
//
// The argument for it is in the last section of docs/measuring.md: it converts
// a wrong number into a measured one. Four of this project's numbers are still
// guesses, all four are cheap to test on a flat plate, and all four are
// expensive to get wrong on a part that takes an hour to print:
//
//   1. M2 pilot diameter. EVERY fastener in the build - four in the MCU box,
//      two in the pod - taps into printed plastic. Too tight splits a 4.2 mm
//      post, too loose strips it. This varies by printer and material more than
//      anything else here, so it is tested at the real post diameter, not in
//      a slab where the plastic cannot split.
//   2. cable_od [EST 3.00]. The pod's gland clamps the cable directly at
//      cable_od - 0.4. The hole row measures the real cable: the smallest one
//      it passes through IS its diameter, no caliper needed.
//   3. The USB-C window and its overmold relief. usb_overhang is flagged in
//      params.scad as the highest-risk number in the project, and usb_plug_w/h
//      are outright guesses. Five windows, at -0.30 to +0.30 on the opening.
//   4. The MCU box's cable exit and its pinch ribs - does the cable actually
//      snap in and stay?
//
// Each window/hole/post is labelled in HUNDREDTHS of a millimetre, so "170" is
// a 1.70 mm pilot and "-15" is a window 0.15 mm under nominal.
//
// HOW TO USE IT
//   posts   drive an M2 x 16 into each. Keep the smallest that goes in without
//           splitting the post and holds when backed out and redriven once.
//           That value replaces m2_pilot.
//   holes   push the interconnect cable through. The smallest it passes is
//           cable_od. Set that in params.scad; the gland follows from it.
//   windows hold the plate's UNDERSIDE against the ESP32's USB-C port so the
//           shell enters from below, then plug a cable in from above. The
//           smallest window that takes both is the one to use: feed the
//           difference back into usb_cut_margin.
//   slot    press the cable into the notch from the open edge. It should need
//           a push and then stay put.
//
// Print flat, no supports, same material and nozzle as the enclosures - the
// numbers it produces are only valid for the machine that made it.
//
// Render:  openscad -o build/fitgauge.stl hardware/fitgauge.scad
// ---------------------------------------------------------------------------

include <params.scad>
use <enclosure_common.scad>

$fn = $preview ? 16 : 32;   // these are 2-4 mm holes; 32 is already past the
                            // point where the facets matter, and the label text
                            // below drops far lower still - at 48 this file
                            // took two and a half minutes to render.

g_l = 86; g_w = 46; g_t = 3.00; g_r = 3;

usb_offsets = [-0.30, -0.15, 0, 0.15, 0.30];
pilots      = [ 1.50,  1.60, 1.70, 1.80, 1.90];
cable_ds    = [for (i = [0:8]) 2.0 + i*0.2];

usb_y   = 14;   usb_pitch  = 16;
usb_band = 9;   usb_band_top = 19;   // milled down to enc_wall between these
hole_y  =  0;   hole_pitch =  5;
post_y  = -13;  post_pitch = 10;  post_h   = 10;

// Sunk 0.1 into the plate on purpose: text that merely sits ON the top face
// touches it at a plane, which leaves each glyph a separate solid in the STL
// and coincident faces for the slicer to argue with.
module label(txt, x, y, sz = 3) {
    translate([x, y, g_t - 0.1]) linear_extrude(0.7)
        text(txt, size = sz, halign = "center", valign = "center", $fn = 8);
}

// The MCU box's cable notch, laid flat: a slot in from the plate's edge with
// the same pinch ribs. Ribs are added after the cut, for the same reason they
// are in enclosure_mcu.scad - inside the difference the slot erases them.
slot_x = g_l/2 - 12;

module exit_slot_cut() {
    hull() {
        translate([slot_x, hole_y, -1]) cylinder(h = g_t + 2, d = enc_exit_w);
        translate([g_l/2 + 1, hole_y - enc_exit_w/2, -1])
            cube([0.01, enc_exit_w, g_t + 2]);
    }
}

module exit_slot_ribs() {
    for (s = [-1, 1])
        translate([slot_x + 5, hole_y + s*enc_exit_w/2, 0])
            cylinder(h = g_t, d = enc_exit_w - cable_od + 0.4);
}

module fitgauge() {
    union() {
        difference() {
            union() {
                rbox(g_l, g_w, g_t, g_r);
                for (i = [0 : len(pilots)-1])
                    translate([-(len(pilots)-1)*post_pitch/2 + i*post_pitch,
                               post_y, g_t])
                        cylinder(h = post_h, d = enc_post_od);
                // labels
                for (i = [0 : len(usb_offsets)-1])
                    label(str(usb_offsets[i]*100),
                          -(len(usb_offsets)-1)*usb_pitch/2 + i*usb_pitch,
                          usb_band - 2.5);
                for (i = [0 : len(pilots)-1])
                    label(str(pilots[i]*100),
                          -(len(pilots)-1)*post_pitch/2 + i*post_pitch,
                          post_y - 6);
                for (i = [0 : len(cable_ds)-1])
                    if (i % 2 == 0)
                        label(str(cable_ds[i]*100),
                              -(len(cable_ds)-1)*hole_pitch/2 + i*hole_pitch,
                              hole_y - 5, 2.4);
            }

            // --- USB row: a band milled down to the real wall thickness -----
            // Bounded top and bottom. Running it off the edge would leave any
            // label above it floating 1 mm over thin air.
            translate([-g_l/2 - 1, usb_band, enc_wall])
                cube([g_l + 2, usb_band_top - usb_band, g_t]);
            for (i = [0 : len(usb_offsets)-1]) {
                x = -(len(usb_offsets)-1)*usb_pitch/2 + i*usb_pitch;
                o = usb_offsets[i];
                // overmold relief, from the outer (top) face
                translate([x, usb_y, enc_wall - usb_relief_d])
                    linear_extrude(usb_relief_d + 1)
                        square([usb_plug_w, usb_plug_h], center = true);
                // the window itself, at nominal + offset on each side
                translate([x, usb_y, -1])
                    linear_extrude(enc_wall + 2)
                        square([usb_width  + 2*usb_cut_margin + 2*o,
                                usb_height + 2*usb_cut_margin + 2*o],
                               center = true);
            }

            // --- cable diameter row -----------------------------------------
            for (i = [0 : len(cable_ds)-1])
                translate([-(len(cable_ds)-1)*hole_pitch/2 + i*hole_pitch,
                           hole_y, -1])
                    cylinder(h = g_t + 2, d = cable_ds[i]);

            exit_slot_cut();

            // --- a screw head in a counterbored floor ------------------------
            translate([-g_l/2 + 8, hole_y, -1]) {
                cylinder(h = g_t + 2, d = m2_free);
                translate([0, 0, 1 + g_t - 1.40])
                    cylinder(h = 1.5, d = m2_head_d + 0.40);
            }

            // --- tapped posts -----------------------------------------------
            for (i = [0 : len(pilots)-1])
                translate([-(len(pilots)-1)*post_pitch/2 + i*post_pitch,
                           post_y, g_t + post_h - m2_engage])
                    cylinder(h = m2_engage + 0.1, d = pilots[i]);
        }
        exit_slot_ribs();
    }
}

// --- guards -----------------------------------------------------------------

assert(usb_band < usb_y - usb_plug_h/2 &&
       usb_band_top > usb_y + usb_plug_h/2,
       "USB relief pocket runs off the milled band");
assert(post_y - 6 - 1.5 > -g_w/2,
       "pilot labels fall off the plate");
assert(cable_ds[0] < cable_od && cable_ds[len(cable_ds)-1] > cable_od,
       "the hole row does not bracket the estimated cable diameter");
assert(pilots[0] < m2_pilot && pilots[len(pilots)-1] > m2_pilot,
       "the pilot row does not bracket the value params.scad currently uses");
assert(post_h > m2_engage, "post shorter than the thread engagement it tests");

fitgauge();

echo(str("fit gauge ", g_l, " x ", g_w, " x ", g_t,
         " mm plate, posts stand ", post_h, " proud"));
echo(str("brackets: pilot ", pilots[0], "-", pilots[len(pilots)-1],
         " around m2_pilot = ", m2_pilot,
         " ; cable ", cable_ds[0], "-", cable_ds[len(cable_ds)-1],
         " around cable_od = ", cable_od));
