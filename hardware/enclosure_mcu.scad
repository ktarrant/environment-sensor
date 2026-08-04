// ---------------------------------------------------------------------------
// enclosure_mcu.scad - MCU-end box: tub + lid.  FIRST DRAFT, not yet printed.
//
// Origin and axes are the ASSEMBLY's, so this file and assembly.scad can be
// rendered into the same scene and checked against each other:
//   center of the perfboard, Z = 0 at its wiring face,
//   +X toward row 20 (the cable end), +Y toward column A.
// The board's component side is +Z, so the box is deep above Z = 0 and shallow
// below it - the shallow part is only there to clear untrimmed header tails.
//
// HOW IT FASTENS - one screw per corner, and it does three jobs:
//
//        M2 x 16, head counterbored into the OUTSIDE of the floor
//          |  up through the standoff tube  (clearance)
//          |  through the perfboard's own corner hole  (2.2 mm, clearance)
//          +->into a post hanging off the lid  (tapped, 6 mm engagement)
//
// So the same four screws clamp the lid down and trap the board between the
// standoff below and the lid post above. The heads end up on the outside of the
// floor, which is also where a mount adapter will later be captured, without
// adding fasteners.
//
// The board is located by the SCREW SHANKS through its 2.2 mm corner holes, not
// by the posts: a post carrying a 2.4 mm clearance bore cannot also spigot into
// a 2.2 mm hole. So until the screws go in the board can shift by the hole
// clearance, and the cavity walls are deliberately loose around it
// (`enc_board_gap`) because they are not locating anything either.
//
// Consequences worth knowing before editing:
//   - The lid post diameter is NOT free. At the -X/+Y corner the ESP32's own
//     PCB edge is 2.49 mm from the screw axis. See the assert below.
//   - The mated PLUG, not the ESP32, sets the height, and it pulls STRAIGHT UP
//     off row 20: the cable has to turn a right angle inside the box before it
//     leaves through the +X wall. It finishes that turn outside the wall, which
//     is the only reason enc_cable_head can be as small as 4 mm.
//   - The connector sits 7.62 mm off the board centerline (columns C..F), so
//     the cable exit is NOT on the box's midline. It looks like a mistake in
//     the render. It is not.
//
// Print: tub open-side-up, lid face-down. Nothing here needs support. The one
// bridge is the top edge of the USB-C window.
//
// Render:
//   openscad -o build/enclosure_mcu_base.stl -D 'part="base"' enclosure_mcu.scad
//   openscad -o build/enclosure_mcu_lid.stl  -D 'part="lid"'  enclosure_mcu.scad
//   part="check" renders the intersection with the hardware keepout. A correct
//   design renders EMPTY - anything visible is a collision.
// ---------------------------------------------------------------------------

include <params.scad>
use <enclosure_common.scad>
use <perfboard.scad>
use <assembly.scad>

part = "base";      // "base" | "lid" | "check" | "assembled"
$fn = $preview ? 24 : 48;

// --- the cavity, derived from the hardware ----------------------------------

// The ESP32 hangs past the perfboard's -X edge, so the interior is longer than
// the board. Kept symmetric: the same slack at the +X end is useful cable room.
in_half_x = pb_len/2 + asm_end_overhang() + enc_board_gap;
in_half_y = pb_width/2 + enc_board_gap;

in_z0 = -enc_standoff_h;                    // inner floor
in_z1 = asm_conn_f() + enc_cable_head;      // rim = mated plug + cable turn

out_half_x = in_half_x + enc_wall;
out_half_y = in_half_y + enc_wall;
floor_z    = in_z0 - enc_floor;

lip_h = 1.50;   // lid spigot into the tub - locates the lid, hides the seam
lip_t = 1.20;

// --- features ---------------------------------------------------------------

// USB-C, in the -X wall. The receptacle is centered on the ESP32's width, and
// the ESP32 is 1.27 mm off the perfboard's centerline, so this is off-center
// too. Outer pocket is for the PLUG's overmold: the shell face stops just
// short of the outer wall face, so without it a fat cable cannot seat.
module usb_cut() {
    yc = asm_esp_offset()[1];
    zc = asm_esp_z() + pcb_thick + usb_height/2;
    // Extruded along -X and rotated into place, so the square's local X is the
    // window's height and its local Y the width.
    translate([-out_half_x - 1, yc, zc]) rotate([0, 90, 0]) {
        // through the wall
        linear_extrude(enc_wall + 2.2)
            square([usb_height + 2*usb_cut_margin,
                    usb_width  + 2*usb_cut_margin], center = true);
        // overmold relief, outer face only
        linear_extrude(usb_relief_d + 1)
            square([usb_plug_h, usb_plug_w], center = true);
    }
}

// Cable exit: a notch open to the rim rather than a hole, so the board can be
// dropped in with the plug already mated and the lid then closes over the
// cable. Rounded at the bottom; cut from the lid's lip as well.
exit_z0 = asm_conn_f() - 0.60;      // just below the mated plug face

// z_top matters, and it differs between the two parts. In the TUB the notch is
// open all the way to the rim, so the cable can be laid in with the plug
// already mated. In the LID it stops at the plate's underside: the cut clears
// the locating lip and nothing more, so the plate itself roofs the notch and
// closes it into a hole. Cutting the lid to the same height as the tub leaves
// the channel open at the top and the cable simply lifts out.
// The floor is FLAT with radiused corners, not a half-round. At 8 mm wide a
// half-round floor curves up steeply at the edges, and since the wires arrive
// spread across the pin row it is the outermost two that would be crushed
// between that curve and the tongue. A flat floor and a flat tongue clamp a row
// of wires evenly, which is what actually arrives here.
module cable_exit_cut(z_top) {
    r   = 1.0;
    yc  = asm_conn_center()[1];
    x0  = in_half_x - 4;
    len = (out_half_x + 1) - x0;
    hull() {
        for (s = [-1, 1])
            translate([x0, yc + s*(enc_exit_w/2 - r), exit_z0 + r])
                rotate([0, 90, 0]) cylinder(h = len, r = r);
        translate([x0, yc - enc_exit_w/2, z_top - 0.01])
            cube([len, enc_exit_w, 0.01]);
    }
}

// Strain relief. The first version was two bumps in the notch walls that the
// cable was meant to snap past; the printed fit gauge showed the cable slides
// through them without being held at all, which is worse than useless - it
// looks like strain relief and leaves the plug taking the load.
//
// This is the pod's gland instead: a tongue on the LID that descends into the
// notch and squeezes the cable against the notch's floor as the four lid screws
// come up. Steel pulling plastic onto the cable, not a press fit.
clamp_z = exit_z0 + cable_od - cable_grip;   // underside of the tongue

module cable_clamp_tongue() {
    yc = asm_conn_center()[1];
    x0 = in_half_x - 2.8;                    // clear of the mated plug
    // Runs half a lid-thickness INTO the plate rather than stopping flush
    // against it: a part that meets another only on a plane stays a separate
    // solid in the STL.
    translate([x0, yc - (enc_exit_w - 2*clearance)/2, clamp_z])
        cube([out_half_x - x0,
              enc_exit_w - 2*clearance,
              in_z1 + enc_lid_t/2 - clamp_z]);
}

// The only places the box is ALLOWED to touch the board: a bearing ring at
// each corner hole, standoff below and lid post above. Used to exempt those
// four columns from the collision check.
module mount_contact(gap = clearance) {
    for (p = pb_mount_positions())
        translate([p[0], p[1], -gap - 0.5])
            cylinder(h = pb_thick + 2*gap + 1, d = enc_boss_od + 2*gap);
}

module vents() {
    zc = (in_z0 + 2 + pb_thick + 8) / 2;
    h  = (pb_thick + 8) - (in_z0 + 2);
    for (s = [-1, 1])
        translate([0, s*(in_half_y + enc_wall/2), zc])
            vent_slots(enc_vents, enc_vent_pitch, enc_vent_w, h, enc_wall + 2);
}

// --- the two parts ----------------------------------------------------------

module mcu_tub() {
    difference() {
        union() {
            difference() {
                translate([0, 0, floor_z])
                    rbox(2*out_half_x, 2*out_half_y,
                         in_z1 - floor_z, enc_r_out);
                translate([0, 0, in_z0])
                    rbox(2*in_half_x, 2*in_half_y,
                         in_z1 - in_z0 + 1, enc_r_in);
            }
            for (p = pb_mount_positions())
                translate([p[0], p[1], in_z0]) {
                    screw_column(enc_standoff_h, enc_boss_od, m2_free);
                    root_fillet(enc_boss_od, enc_fillet);
                }
        }
        usb_cut();
        cable_exit_cut(in_z1 + enc_lid_t + 1);   // open to the rim
        vents();
        for (p = pb_mount_positions())
            translate([p[0], p[1], in_z0])
                screw_bore(enc_floor, m2_free, m2_head_d + 0.40, m2_head_h);
    }
}

module mcu_lid() {
    union() {
    difference() {
        union() {
            translate([0, 0, in_z1])
                rbox(2*out_half_x, 2*out_half_y, enc_lid_t, enc_r_out);
            // locating lip, a ring standing down into the tub
            translate([0, 0, in_z1 - lip_h])
                difference() {
                    rbox(2*(in_half_x - clearance), 2*(in_half_y - clearance),
                         lip_h, enc_r_in);
                    translate([0, 0, -0.5])
                        rbox(2*(in_half_x - clearance - lip_t),
                             2*(in_half_y - clearance - lip_t),
                             lip_h + 1, max(enc_r_in - lip_t, 0.1));
                }
            // Posts: lid underside down to the board's top face, flared where
            // they meet the plate. That root is where the gauge's posts sheared,
            // and these are 15.6 mm long against the gauge's 10.
            for (p = pb_mount_positions())
                translate([p[0], p[1], pb_thick]) {
                    cylinder(h = in_z1 - pb_thick, d = enc_post_od);
                    translate([0, 0, in_z1 - pb_thick])
                        mirror([0, 0, 1]) root_fillet(enc_post_od, enc_fillet);
                }
        }
        for (p = pb_mount_positions())
            translate([p[0], p[1], pb_thick - 0.1]) {
                cylinder(h = m2_engage + 0.1, d = m2_pilot);
                translate([0, 0, m2_engage])
                    cylinder(h = in_z1 - pb_thick - m2_engage,
                             d = m2_free + 0.20);
            }
        cable_exit_cut(in_z1);                   // through the lip only
    }
    // After the cut: the tongue lives inside the notch the cut just made.
    cable_clamp_tongue();
    }
}

// --- guards -----------------------------------------------------------------
//
// These are the constraints that make the design a consequence of the hardware
// rather than a guess. Each one has already been within a fraction of a mm of
// failing at some point in the layout.

// The inner fillet must not reach the board's corners: there is 0.20 mm of
// slack across the width, and only the extra length at the ends saves it.
assert(enc_r_in <= in_half_x - pb_len/2,
       "inner corner fillet eats into the perfboard's corners");

// The tight one. The ESP32 sits 1.27 mm toward +Y, so its PCB edge runs within
// 2.49 mm of the +Y screw axes, and the lid post is concentric with those.
assert(pb_mount_dy - enc_post_od/2
         >= abs(asm_esp_offset()[1]) + esp_width/2 + clearance,
       "lid post collides with the ESP32's PCB edge - reduce enc_post_od");
assert(pb_mount_dy - enc_post_od/2
         >= asm_conn_center()[1] + xh_body_len/2 + clearance,
       "lid post collides with the connector body");

assert(in_z1 >= asm_top_f() + clearance,   "lid fouls the ESP32/WROOM stack");
// The posts flare where they meet the lid. That flare is 6.6 across, well over
// the 4.58 the tight corner allows, so it may only exist high above the board.
assert(in_z1 - enc_fillet > asm_top_f() + clearance,
       "post root fillet reaches down into the ESP32");
assert(in_z1 >= asm_conn_f(),              "lid fouls the mated plug");
assert(exit_z0 <= asm_conn_f(),
       "cable exit starts above the plug face - the cable cannot leave");
assert(clamp_z < in_z1 - 0.8,
       "no room left for the clamp tongue under the lid");
assert(clamp_z > exit_z0,
       "clamp tongue closes below the notch floor - it would pinch shut");
// The wires arrive spread across the pin row; the notch has to take them that
// way rather than asking them to gather in the 6 mm between plug and wall.
assert(enc_exit_w >= xh_pin_span,
       "cable notch narrower than the pin row the wires fan out from");
// The tongue must not reach back over the mated plug, or the lid will not seat.
assert(in_half_x - 2.8 > asm_conn_center()[0] + xh_body_back + clearance,
       "clamp tongue overhangs the mated plug");
assert(in_half_x >= pb_len/2 + asm_end_overhang(),
       "the ESP32's overhanging end does not fit inside the box");

// USB window must live entirely in the wall, not run into the floor or the rim.
usb_z0 = asm_esp_z() + pcb_thick - usb_cut_margin;
usb_z1 = usb_z0 + usb_height + 2*usb_cut_margin;
assert(usb_z0 > in_z0 + 1, "USB window breaks into the floor");
assert(usb_z1 < in_z1 - 1, "USB window breaks through the rim");

// --- output -----------------------------------------------------------------

if (part == "base")      mcu_tub();
else if (part == "lid")  mcu_lid();
else if (part == "check") {
    // Empty render = no collision. Anything visible is where the box hits the
    // hardware. This is the geometric counterpart of the asserts above.
    //
    // The four corners are exempt: the standoff bears on the board's underside
    // and the lid post on its top face, which is the whole clamping scheme, and
    // a keepout that forbade it would report the design as broken by design.
    // Nothing else in the box is allowed to touch the hardware.
    intersection() {
        union() { mcu_tub(); mcu_lid(); }
        difference() { mcu_keepout(); mount_contact(); }
    }
}
else if (part == "assembled") {
    // Color the parts individually - an outer color() would override the
    // board colors inside mcu_assembly().
    color("#b9c6d2") mcu_tub();
    color("#8fa3b5") mcu_lid();
    mcu_assembly();
}
else if (part == "exploded") {
    color("#b9c6d2") mcu_tub();
    mcu_assembly();
    translate([0, 0, 22]) color("#8fa3b5") mcu_lid();
}
else assert(false, "part must be base | lid | check | assembled | exploded");

echo(str("interior  ", 2*in_half_x, " x ", 2*in_half_y,
         " x ", in_z1 - in_z0, " mm"));
echo(str("exterior  ", 2*out_half_x, " x ", 2*out_half_y,
         " x ", in_z1 + enc_lid_t - floor_z, " mm"));
// Under-head length, so the counterbore counts as depth the screw does not have
// to span. Quoting the full floor thickness here over-stated it by 2.2 mm.
mcu_screw_need = (enc_floor - m2_head_h) + enc_standoff_h + pb_thick + m2_engage;
assert(mcu_screw_need <= 16, "an M2 x 16 no longer reaches the lid post");
assert(16 - ((enc_floor - m2_head_h) + enc_standoff_h + pb_thick)
         <= m2_engage + (in_z1 - pb_thick - m2_engage),
       "an M2 x 16 bottoms out in the lid post");
echo(str("screw     M2 x 16 - needs ", mcu_screw_need,
         " under the head (floor beneath the counterbore + standoff + board",
         " + engagement); add the mount adapter's thickness later"));
echo(str("lid post  ", enc_post_od, " dia, clearing the ESP32 edge by ",
         pb_mount_dy - enc_post_od/2
           - (abs(asm_esp_offset()[1]) + esp_width/2), " mm"));
echo(str("USB-C shell face sits ",
         out_half_x - (pb_len/2 + asm_usb_proud()),
         " mm inside the outer wall face - the relief pocket covers this"));
