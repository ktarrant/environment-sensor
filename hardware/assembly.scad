// ---------------------------------------------------------------------------
// assembly.scad - the MCU-end module as actually built.
//
// Placement is DERIVED FROM THE WIRING, not eyeballed from photos. The four
// wires over-determine the ESP32's position: one of them fixes it, and the
// other three then have to land on their own holes. Those are asserts below,
// so a wrong number cannot render silently.
//
//   # | signal | connector | ESP32 hole | ESP32 pin
//   1 | power  | C20       | L2         | 3V3
//   2 | ground | D20       | B3         | GND
//   3 | clock  | E20       | L15        | GPIO22 / SCL
//   4 | data   | F20       | L12        | GPIO21 / SDA
//
// Build note: components are on the face OPPOSITE the silkscreen. The wiring
// runs on the silkscreen face so the grid labels are readable while soldering.
// In this model the component face is +Z.
//
// Origin and axes are the perfboard's: center of the board, Z = 0 at the face
// the wiring is on, +X toward row 20 (the connector end), +Y toward column A.
//
// Render:  openscad -o build/assembly.stl hardware/assembly.scad
// ---------------------------------------------------------------------------

include <params.scad>
use <perfboard.scad>
use <esp32.scad>
use <connector.scad>

show_grid = true;
$fn = $preview ? 16 : 32;

// --- ESP32 pin numbering ----------------------------------------------------
// Row A carries 3V3 at the USB-C end; row B carries VIN at the same end.
// Position is 1-based from the USB-C end.

row_a = ["3V3","GND","D15","D2","D4","RX2","TX2","D5","D18","D19","D21","RX0","TX0","D22","D23"];
row_b = ["VIN","GND","D13","D12","D14","D27","D26","D25","D33","D32","D35","D34","VN","VP","EN"];

function esp_pos(name, row) = search([name], row)[0] + 1;   // 1-based

// ESP32-local coordinates of a header pin. Row A sits at -Y, row B at +Y,
// matching the real board's handedness (verified against ESP32_top.jpg).
function esp_pin_xy(name, is_row_a) =
    [ esp_hdr_x_off - esp_pin_span/2 + (esp_pos(name, is_row_a ? row_a : row_b) - 1)*pitch,
      (is_row_a ? -1 : 1) * esp_row_spacing/2 ];

// --- placement, solved from wire 1 (3V3 -> L2) ------------------------------
//
// Exposed as functions as well as variables: `use <assembly.scad>` imports
// functions and modules but not variables, and the enclosure needs these
// numbers without re-deriving them. The variables below are set FROM the
// functions so there is still exactly one definition of each.

function asm_esp_offset()  = pb_hole("L", 2) - esp_pin_xy("3V3", true);
function asm_esp_z()       = pb_thick + hdr_plastic_h;
function asm_conn_center() = [pb_row_x(20), (pb_col_y("C") + pb_col_y("F"))/2];

// How far the ESP32's PCB hangs past the perfboard's -X edge, and how far the
// USB-C shell then stands proud of that same edge.
function asm_end_overhang() = (abs(asm_esp_offset()[0]) + esp_len/2) - pb_len/2;
function asm_usb_proud()    = -pb_len/2
                              - (asm_esp_offset()[0] - esp_len/2 - usb_overhang);

// Height budget, measured from the wiring face (Z = 0).
function asm_top_f()   = asm_esp_z() + pcb_thick + wroom_height;   // ESP32 stack
function asm_conn_f()  = pb_thick + xh_mated_h;                    // mated plug
function asm_below_f() = max(hdr_below - hdr_plastic_h - pb_thick, // pin tails
                             xh_pin_below);

esp_offset = asm_esp_offset();
esp_z      = asm_esp_z();       // header plastic is the standoff

// Connector occupies row 20, columns C..F, pin 1 at C.
conn_center = asm_conn_center();
conn_rot    = -90;   // maps the connector's local +X pin axis onto -Y (C -> F)

// --- the remaining three wires must now land on their own holes -------------

assert(norm(esp_offset + esp_pin_xy("GND", false) - pb_hole("B", 3))  < 0.01,
       "wire 2: GND does not land on B3");
assert(norm(esp_offset + esp_pin_xy("D22", true) - pb_hole("L", 15)) < 0.01,
       "wire 3: GPIO22/SCL does not land on L15");
assert(norm(esp_offset + esp_pin_xy("D21", true) - pb_hole("L", 12)) < 0.01,
       "wire 4: GPIO21/SDA does not land on L12");
// Every ESP32 pin must land on a real hole in the 1..20 / A..N grid. This is
// the actual correctness condition - the PCB itself is allowed to hang over the
// edge, and does.
esp_first_row = 2;                                  // 3V3 -> L2
esp_last_row  = esp_first_row + esp_pins_per_row-1; // -> row 16
assert(esp_first_row >= 1 && esp_last_row <= pb_rows,
       "ESP32 header runs off the end of the perfboard grid");
assert(abs(esp_offset[1]) + esp_width/2 <= pb_width/2 + 0.01,
       "ESP32 overhangs the long sides");

// The ESP32 DOES hang over the USB-C end - by design, so the port clears the
// enclosure wall. Reported rather than asserted.
esp_end_overhang = (abs(esp_offset[0]) + esp_len/2) - pb_len/2;
usb_face_x       = esp_offset[0] - esp_len/2 - usb_overhang;

// --- assembly ---------------------------------------------------------------

module mcu_assembly() {
    perfboard();
    translate([esp_offset[0], esp_offset[1], esp_z]) esp32_board();
    translate([conn_center[0], conn_center[1], pb_thick])
        rotate([0, 0, conn_rot]) xh_header();
}

// Clearance solid for the whole module. An enclosure that intersects this
// collides with the hardware - see part = "check" in enclosure_mcu.scad.
module mcu_keepout(gap = clearance) {
    perfboard_keepout(gap);
    translate([esp_offset[0], esp_offset[1], esp_z]) esp32_keepout(gap);
    translate([conn_center[0], conn_center[1], pb_thick])
        rotate([0, 0, conn_rot]) xh_mated_keepout(gap);
}

// Overall envelope, for sizing the housing.
asm_top    = asm_top_f();                           // tallest of the ESP32 stack
asm_conn   = asm_conn_f();                          // connector, mated
asm_height = max(asm_top, asm_conn);

// How far things stick out the wiring side. The ESP32's header tails dominate
// and are untrimmed in this build (visible in esp32_assembled_profile.jpg), so
// the housing needs this much clearance under the board plus the wiring itself.
asm_below = asm_below_f();
echo(str("ESP32 offset      = ", esp_offset, " mm"));
echo(str("ESP32 stack top   = ", asm_top,  " mm above the wiring face"));
echo(str("connector, mated  = ", asm_conn, " mm  <- sets the lid height"));
echo(str("ESP32 overhangs the USB-C end of the perfboard by ",
         esp_end_overhang, " mm"));
echo(str("USB-C face at X = ", usb_face_x, " mm ; perfboard ends at X = ",
         -pb_len/2, " mm  -> port stands proud by ",
         -pb_len/2 - usb_face_x, " mm"));
echo(str("protrusion below the wiring face = ", asm_below,
         " mm (untrimmed ESP32 header tails), plus the wires themselves"));
echo(str("total board-to-board envelope = ", asm_height + asm_below, " mm"));

mcu_assembly();
