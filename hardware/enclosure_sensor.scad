// ---------------------------------------------------------------------------
// enclosure_sensor.scad - sensor pod: two clamshell halves.  FIRST DRAFT.
//
// Origin and axes are sensor.scad's:
//   center of the PCB footprint, Z = 0 at the TRACE face,
//   +X toward the connector edge, connector pins running along Y.
// The components are on +Z and the mated plug hangs off -Z, so the pod is
// deep on the -Z side. IN USE the pod hangs with -Z UP: the cable leaves the
// top, the sensor faces down out of the grille, and the pod sits level with or
// below the MCU box, never above it.
//
// WHY A CLAMSHELL, NOT A TUB AND LID
//
// The interconnect has a housing on BOTH ends - both boards carry male headers
// - so the cable cannot be threaded through a closed hole. The exit has to be
// split, which puts the parting plane through the cable axis (y = 0). Once it
// is there, the two halves close sideways onto the board and nothing needs to
// be inserted along Z.
//
// HOW THE BOARD IS HELD - no screw touches it
//
// The board's one mounting hole is [EST] and its Y sign is mirror-ambiguous,
// so a boss built on it could land 4 mm out on a 10 mm board. Nothing here
// uses it. Instead the connector does the work, because it is soldered to the
// board and its top face is flush with the board's underside at Z = 0:
//
//   above Z=0  the cavity is the BOARD's outline only, so shell material
//              stands over the connector's flange - it overhangs the board by
//              1.26 mm each side and 0.85 mm past the end - and stops the
//              assembly lifting.
//   below Z=0  the cavity is the CONNECTOR's outline only, so shell material
//              remains under the board out to x = 1.10 and holds it up.
//
// That locks X, Y, Z and rotation with two boxes and no fasteners through the
// board. It works only because the halves close laterally; a tub and lid would
// need clearance in Z for insertion and would lose the shoulder.
//
// The plug pocket TAPERS by xh_solder_tilt over the plug's depth. The built
// connectors are visibly askew and a pocket cut for a perpendicular plug is
// the classic way to end up with a pod that will not close.
//
// Print: each half on its parting face, open side up. In that orientation
// every internal feature is vertical - there is not one overhang in the part.
// The only sloped surface is the outer taper, at 25 degrees off vertical.
//
// Render:
//   openscad -o build/pod_a.stl -D 'part="a"' hardware/enclosure_sensor.scad
//   openscad -o build/pod_b.stl -D 'part="b"' hardware/enclosure_sensor.scad
//   part="check" must render EMPTY.
// ---------------------------------------------------------------------------

include <params.scad>
use <enclosure_common.scad>
use <connector.scad>
use <sensor.scad>

part = "a";     // "a" | "b" | "check" | "assembled" | "exploded"
$fn = $preview ? 24 : 48;

// --- the cavity, derived from the board -------------------------------------

in_x0     = -(bme_len/2 + clearance);        // board end
in_x1     = bme_conn_x1() + pod_gap;         // past the connector
pocket_x0 = bme_conn_x0() - pod_gap;

in_y_board = bme_width/2   + clearance;      // sensor chamber
in_y_conn  = xh_body_len/2 + pod_gap;        // connector, at the board
tilt       = xh_mated_h * tan(xh_solder_tilt);
in_y_max   = in_y_conn + tilt;               // ...and at the plug's face

in_z1  = bme_above() + clearance;            // top of the sensor chamber
z_plug = -xh_mated_h;                        // the mated plug's outer face
in_z0  = z_plug - pod_cable_room;

// End walls carry the two screws, which run along Y through the parting plane.
screw_x0 = in_x0 - pod_screw_wall;
screw_x1 = in_x1 + pod_screw_wall;
screw_z  = (in_z1 + in_z0)/2;

out_x0     = screw_x0 - pod_screw_wall;
out_x1     = screw_x1 + pod_screw_wall;
out_y      = in_y_max   + pod_wall;          // widest, at the plug
out_y_nose = in_y_board + pod_wall;          // narrowest, over the sensor
out_z1     = in_z1 + pod_wall;
out_z0     = in_z0 - pod_wall;

cable_x  = (bme_conn_x0() + bme_conn_x1())/2;
cable_d  = cable_od - pod_cable_grip;        // split gland: the halves clamp it
grille_l = 2*in_y_board - 2.0;
cross_z  = in_z1 - 1.4;                      // cross-flow slot, level with the
                                             // BME280's can and clear of both
                                             // the chamber ceiling and the board

// The pocket leans out as it deepens. Where it ends up matters twice: against
// the side wall, and against the +X screw.
function pocket_x1_at(z) = in_x1 + abs(min(z, 0)) * tan(xh_solder_tilt);

// --- helpers ----------------------------------------------------------------

module box3(x0, x1, yh, z0, z1) {
    translate([x0, -yh, z0]) cube([x1 - x0, 2*yh, z1 - z0]);
}

// Cylinder running along +Y from the origin.
module ycyl(h, d) { rotate([-90, 0, 0]) cylinder(h = h, d = d); }

// --- shell ------------------------------------------------------------------

// Tapered: full width where the plug is, narrow over the sensor. The taper is
// not styling - it is what gets the sensor chamber's side walls down to 2 mm
// so the cross-flow slot is a slot and not a tunnel.
module pod_shell() {
    cx = (out_x0 + out_x1)/2;
    lx = out_x1 - out_x0;
    hull() {
        translate([cx, 0, out_z0])
            rbox(lx, 2*out_y, (-pod_ledge_t) - out_z0, pod_r);
        translate([cx, 0, out_z1 - 0.01])
            rbox(lx, 2*out_y_nose, 0.01, pod_r);
    }
}

module pod_cavity() {
    // sensor chamber: the BOARD's outline, nothing wider
    box3(in_x0, -in_x0, in_y_board, 0, in_z1);
    // connector and plug: the CONNECTOR's outline, tapering out for solder tilt
    hull() {
        box3(pocket_x0, in_x1, in_y_conn, -0.01, 0);
        box3(pocket_x0 - tilt, in_x1 + tilt, in_y_max, z_plug, z_plug + 0.01);
    }
    // and below the ledge it is all one chamber, so the pod is not a solid
    // block of plastic with a hole in it
    box3(in_x0, in_x1, in_y_max, in_z0, -pod_ledge_t);
}

// Grille straight over the sensor, plus one cross-flow slot through both side
// walls. The grille is 2 mm from the BME280's can, which is the whole point of
// putting the sensor in its own shell.
module pod_vents_cut() {
    for (i = [0 : pod_vents-1])
        translate([-(pod_vents-1)*pod_vent_pitch/2 + i*pod_vent_pitch,
                   0, in_z1 - 0.1])
            rotate([0, 0, 90]) pill(grille_l, pod_vent_w,
                                    (out_z1 - in_z1) + 0.2);
    // through both faces in one cut, high in the chamber where the wall is
    // thinnest
    translate([0, -20, cross_z]) rotate([-90, 0, 0])
        pill(2*in_y_board, pod_vent_w, 40);
}

module pod_cable_cut() {
    translate([cable_x, 0, out_z0 - 0.1])
        cylinder(h = (in_z0 + 0.01) - (out_z0 - 0.1), d = cable_d);
}

module pod_body() {
    difference() {
        pod_shell();
        pod_cavity();
        pod_vents_cut();
        pod_cable_cut();
    }
}

// --- the two halves ---------------------------------------------------------

module half_space(s) {
    translate([-60, s > 0 ? 0 : -60, -60]) cube([120, 60, 120]);
}

// s = +1: the near half, clearance hole and counterbored head.
// s = -1: the far half, tapped.
module pod_half(s) {
    difference() {
        intersection() { pod_body(); half_space(s); }
        for (sx = [screw_x0, screw_x1])
            translate([sx, 0, screw_z])
                if (s > 0) {
                    translate([0, -0.1, 0]) ycyl(out_y + 0.2, m2_free);
                    translate([0, out_y - 1.40, 0])
                        ycyl(pod_wall + 1.5, m2_head_d + 0.40);
                } else {
                    rotate([180, 0, 0]) translate([0, -0.1, 0])
                        ycyl(pod_tap_depth + 0.1, m2_pilot);
                }
    }
}

// --- guards -----------------------------------------------------------------
//
// The first three are the retention scheme. If any of them fails the board is
// loose in the pod and the pod still looks perfectly fine on screen.

assert(in_y_board < xh_body_len/2,
       "no shoulder over the connector's flange - the board can lift out");
assert(bme_len/2 + clearance < bme_conn_x1(),
       "connector does not overhang the board's end - no shoulder there");
assert(pocket_x0 > in_x0 + 2,
       "no ledge left under the board - nothing holds it up");

assert(in_z1 >= bme_above() + clearance,
       "sensor chamber fouls the connector's pin tails");

// The pocket has to hold a plug that is leaning, not a plug that is square.
assert(in_y_max >= xh_body_len/2 + tilt,
       "plug pocket is too narrow for the plug at full solder tilt");
pod_screw_gap = screw_x1 - m2_free/2 - pocket_x1_at(screw_z - m2_free/2);
assert(pod_screw_gap > 1.0,
       "leaning plug pocket breaks into the +X screw - raise pod_screw_wall");
assert(cable_d < xh_body_len && cable_d < xh_body_front + xh_body_back,
       "cable exit is wide enough for the plug to pull through it");
assert(cable_d > 0, "cable grip exceeds the cable diameter");

// The screw must reach past the parting plane and stop inside the far half.
pod_screw_len = 16.00;                       // the same M2 x 16 as the MCU box
pod_screw_in  = pod_screw_len - (out_y - 1.40);
assert(pod_screw_in > 4, "M2 x 16 barely crosses the parting plane");
assert(pod_screw_in <= pod_tap_depth, "tapped hole is shallower than the screw");
assert(pod_screw_in < out_y - 1.5, "screw tip breaks out of the far face");

// Vents and screws share the end walls; keep them apart.
assert(abs(screw_z - cross_z) > pod_vent_w/2 + m2_free/2 + 1,
       "cross-flow slot runs into the screw");
assert(cross_z + pod_vent_w/2 < in_z1 - 0.4,
       "cross-flow slot breaks into the chamber ceiling");
assert(cross_z - pod_vent_w/2 > bme_pcb_thick,
       "cross-flow slot cuts below the board instead of past the sensor");

// --- output -----------------------------------------------------------------

if      (part == "a") pod_half( 1);
else if (part == "b") pod_half(-1);
else if (part == "check") {
    // Empty = no collision. As at the MCU end, the intended bearing surfaces
    // are exempt: here that is the Z = 0 plane itself, where the ledge holds
    // the board's trace face and the shoulder holds the connector's flange.
    //
    // The keepout is asked for a hair under `clearance` on purpose. This pod's
    // cavity IS the board plus exactly `clearance`, so at the full value every
    // cavity wall is coplanar with a keepout face and CGAL returns a zero-facet
    // artifact instead of an empty set - indistinguishable, at a glance, from a
    // real hit. Ten microns less asks the same question and answers it cleanly.
    check_gap = clearance - 0.01;
    intersection() {
        union() { pod_half(1); pod_half(-1); }
        difference() {
            sensor_keepout(check_gap);
            translate([in_x0, -in_y_max, -check_gap - 0.01])
                cube([in_x1 - in_x0, 2*in_y_max, 2*check_gap + 0.02]);
        }
    }
}
else if (part == "assembled") {
    color("#c8d2c0") pod_half(1);
    color("#b4c0aa") pod_half(-1);
    sensor_assembly();
}
else if (part == "exploded") {
    translate([0, 14, 0]) color("#c8d2c0") pod_half(1);
    sensor_assembly();
    translate([0, -14, 0]) color("#b4c0aa") pod_half(-1);
}
else assert(false, "part must be a | b | check | assembled | exploded");

echo(str("pod exterior ", out_x1 - out_x0, " x ", 2*out_y, " x ",
         out_z1 - out_z0, " mm"));
echo(str("  sensor chamber ", -2*in_x0, " x ", 2*in_y_board, " x ", in_z1,
         ", grille ", pod_vents, " slots ", pod_vent_w, " wide, ",
         100 * pod_vents * pod_vent_w * grille_l / (-2*in_x0 * 2*in_y_board),
         "% open over the sensor"));
echo(str("  plug pocket widens ", 2*tilt, " mm over its depth for ",
         xh_solder_tilt, " deg of solder tilt; ", pod_screw_gap,
         " mm left between it and the +X screw"));
echo(str("  fasteners 2x M2 x ", pod_screw_len, ", ", pod_screw_in,
         " mm into the far half"));
echo(str("  cable exit ", cable_d, " mm across a ", cable_od,
         " mm cable - the halves clamp it"));
