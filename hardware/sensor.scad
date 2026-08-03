// ---------------------------------------------------------------------------
// sensor.scad - purple "GYBMEP" BME280 breakout, and the sensor-end assembly.
//
// Rough, and rougher than the other models: this part has only been photographed
// hand-held and at an angle, so the outline is corroborated (13 x 10, two
// sources within 0.5 mm) but the mounting hole and component heights are
// estimates. See the [EST] tags in params.scad before trusting anything here
// for a screw boss.
//
// Origin: center of the PCB footprint, Z = 0 at the PCB's trace-only face.
// +X toward the connector edge, connector pins running along Y.
//
// SIDEDNESS: the connector body is mounted on the TRACE side (-Z), and the
// components - BME280 can, XC6206 regulator, passives - are on the opposite
// face (+Z). The connector's pins therefore pass up through the board and are
// soldered on the component side, which is what the four dark blobs along the
// top edge of images/sensor_bottom.jpg actually are. The white housing is only
// visible around the board's edges in that photo because it is wider than the
// board it is mounted to.
//
// Render:
//   openscad -o build/sensor.stl          -D 'part="board"'    hardware/sensor.scad
//   openscad -o build/sensor_assembly.stl -D 'part="assembly"' hardware/sensor.scad
// ---------------------------------------------------------------------------

include <params.scad>
use <connector.scad>

part = "assembly";      // "board" | "assembly"
$fn = $preview ? 24 : 48;

// --- the breakout -----------------------------------------------------------

module bme_pcb() {
    difference() {
        translate([0, 0, bme_pcb_thick/2])
            cube([bme_len, bme_width, bme_pcb_thick], center = true);
        translate([bme_mount_x, bme_mount_y, -1])
            cylinder(h = bme_pcb_thick + 2, d = bme_mount_dia);
    }
}

// Everything on the top face as one keep-out slab: the BME280 can, the XC6206
// regulator and the passives. Individually modeling them would imply a
// precision the source photo does not support.
module bme_components() {
    inset = 0.6;
    keepout = 0.7;      // annular clearance kept free around the mounting hole
    difference() {
        translate([-bme_len/2 + inset, -bme_width/2 + inset, bme_pcb_thick])
            cube([bme_len - bme_conn_inset - 2*inset,
                  bme_width - 2*inset,
                  bme_comp_h]);
        // the real board keeps this area clear so a screw head can land
        translate([bme_mount_x, bme_mount_y, bme_pcb_thick - 1])
            cylinder(h = bme_comp_h + 2, d = bme_mount_dia + 2*keepout);
    }
}

module sensor_board() {
    color("#6b3fa0") bme_pcb();
    color("#3a3a3a") bme_components();
}

// --- sensor end, with the connector fitted ----------------------------------

// Connector hangs off the trace side (Z = 0), body pointing down, pins passing
// up through the board to be soldered on the component face.
module sensor_assembly() {
    sensor_board();
    translate([bme_len/2 - bme_conn_inset, 0, 0])
        rotate([180, 0, 0]) rotate([0, 0, 90]) xh_header();
}

// --- guards -----------------------------------------------------------------

assert(xh_pin_span < bme_width,
       "connector pin row is wider than the board edge it sits on");
assert(abs(bme_mount_x) + bme_mount_dia/2 < bme_len/2,
       "mounting hole breaks the board end");
assert(abs(bme_mount_y) + bme_mount_dia/2 < bme_width/2,
       "mounting hole breaks the board side");
assert(bme_mount_x + bme_mount_dia/2 < bme_len/2 - bme_conn_inset - xh_body_depth/2,
       "mounting hole collides with the connector footprint");

// --- output -----------------------------------------------------------------

if      (part == "board")    sensor_board();
else if (part == "assembly") sensor_assembly();
else assert(false, "part must be \"board\" or \"assembly\"");

// The connector and the components face opposite ways, so the sensor end's
// envelope straddles the board rather than stacking on one side of it.
echo(str("sensor board ", bme_len, " x ", bme_width, " mm"));
echo(str("  component side: +", bme_pcb_thick + bme_comp_h,
         " mm  (plus ", xh_pin_below - bme_pcb_thick,
         " mm of connector pin poking through)"));
echo(str("  trace side:     -", xh_mated_h, " mm to the mated plug face"));
echo(str("  total across the board = ",
         xh_mated_h + max(bme_pcb_thick + bme_comp_h, xh_pin_below), " mm"));
