// ---------------------------------------------------------------------------
// esp32.scad - rough model of the DOIT ESP32 DevKit V1 (30-pin, USB-C).
//
// Deliberately rough. This is a fit-and-clearance stand-in for enclosure work,
// not a replica. Everything an enclosure actually touches - outline, mounting
// holes, USB-C port, overall height - follows params.scad. Small top-face parts
// are represented only where they set the height budget.
//
// The detailed reference model is reference/esp32_devkitv1.3mf.
//
// Origin: center of the PCB footprint, Z = 0 at the PCB bottom face.
// +X is the WROOM/antenna end, -X is the USB-C end.
//
// Render:  openscad -o build/esp32.stl hardware/esp32.scad
// ---------------------------------------------------------------------------

include <params.scad>

$fn = $preview ? 24 : 64;

// --- helpers ----------------------------------------------------------------

module rounded_plate(len, wid, thk, r) {
    hull() for (sx = [-1,1], sy = [-1,1])
        translate([sx*(len/2 - r), sy*(wid/2 - r), 0])
            cylinder(h = thk, r = r);
}

module box(size, at) { translate(at) cube(size, center = true); }

// --- sub-assemblies ---------------------------------------------------------

module esp_pcb() {
    difference() {
        rounded_plate(esp_len, esp_width, pcb_thick, esp_corner_r);
        for (sx = [-1,1], sy = [-1,1])
            translate([sx*esp_hole_dx, sy*esp_hole_dy, -1])
                cylinder(h = pcb_thick + 2, d = esp_hole_dia);
    }
}

// ESP32-WROOM-32: module PCB across the full footprint, shield can on top.
// The exposed tail at the +X end is the PCB antenna - keep metal away from it.
module esp_wroom() {
    box([wroom_len, wroom_width, wroom_pcb_h],
        [wroom_x0 + wroom_len/2, 0, pcb_thick + wroom_pcb_h/2]);
    box([wroom_can_len, wroom_can_w, wroom_height - wroom_pcb_h],
        [wroom_can_x, 0, pcb_thick + wroom_pcb_h + (wroom_height - wroom_pcb_h)/2]);
}

module esp_usb() {
    box([usb_body_len, usb_width, usb_height],
        [-esp_len/2 - usb_overhang + usb_body_len/2, 0, pcb_thick + usb_height/2]);
}

module esp_buttons() {
    for (sy = [-1,1])
        box([esp_btn, esp_btn, esp_btn_h],
            [esp_btn_x, sy*esp_btn_dy, pcb_thick + esp_btn_h/2]);
}

module esp_headers() {
    for (sy = [-1,1]) {
        // plastic spacer, under the board
        box([esp_pin_span + pitch, pitch, hdr_plastic_h],
            [esp_hdr_x_off, sy*esp_row_spacing/2, -hdr_plastic_h/2]);
        // pins, through the board down to the tips
        for (i = [0 : esp_pins_per_row - 1])
            box([hdr_pin_sq, hdr_pin_sq, hdr_below + pcb_thick],
                [esp_hdr_x_off - esp_pin_span/2 + i*pitch,
                 sy*esp_row_spacing/2,
                 pcb_thick - (hdr_below + pcb_thick)/2]);
    }
}

// --- public modules ---------------------------------------------------------

module esp32_board() {
    color("#14532d") esp_pcb();
    color("#8a7f6a") esp_wroom();
    color("#c0c0c0") esp_usb();
    color("#3a3a3a") esp_buttons();
    color("#b8912f") esp_headers();
}

// Clearance solid for enclosure boolean ops: the board swept out by `gap` on
// every side. Subtract this from a housing to carve the cavity. Note the USB-C
// is included, so the port cutout appears automatically when the connector
// reaches the wall.
module esp32_keepout(gap = clearance) {
    minkowski() {
        union() {
            box([esp_len, esp_width, pcb_thick], [0, 0, pcb_thick/2]);
            box([esp_len - 2*wroom_x0, esp_width, esp_misc_height],
                [wroom_x0, 0, pcb_thick + esp_misc_height/2]);
            esp_wroom();
            esp_usb();
            box([esp_pin_span + pitch, esp_row_spacing + pitch, hdr_below],
                [esp_hdr_x_off, 0, -hdr_below/2]);
        }
        sphere(r = gap, $fn = 12);
    }
}

// Overall envelope, for sanity checks and for sizing the housing.
esp_total_h = hdr_below + pcb_thick + max(wroom_height, usb_height, esp_btn_h);

// --- default render ---------------------------------------------------------

esp32_board();
