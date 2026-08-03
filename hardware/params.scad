// ---------------------------------------------------------------------------
// params.scad - single source of truth for every dimension in this build.
//
// Nothing else in hardware/ hardcodes a number. Correct a value here and
// re-render; everything downstream follows.
//
// Confidence tags:
//   [EXACT]    fixed by a standard, or counted (pin counts).
//   [DERIVED]  computed from an [EXACT] value.
//   [MODEL]    from the DevKit V1 3MF, cross-checked against the photos.
//   [PHOTO]    measured from images/, scaled against the 2.54 mm pin pitch.
//   [DATASHEET] from the Espressif ESP32-WROOM-32 datasheet.
//   [EST]      placeholder, not yet verified.
//   [OPEN]     sources disagree; see the note. Not enclosure-critical yet.
//
// Coordinate convention for the ESP32 model:
//   origin at the center of the PCB footprint, Z = 0 at the PCB bottom face,
//   +X toward the WROOM/antenna end, -X toward the USB-C end, Z up.
// ---------------------------------------------------------------------------

// --- Universals -------------------------------------------------------------

pitch     = 2.54;   // [EXACT] 0.100" header pitch
pcb_thick = 1.60;   // [EXACT] standard FR-4. 3MF models it as 1.5; photo reads
                    //         ~1.8 edge-on (oblique view). 1.6 is the real part.

// ===========================================================================
// ESP32 - DOIT ESP32 DevKit V1 clone, 30-pin, USB-C
// Sold as ELEGOO ESP-32, Micro Center #704603.
//
// IDENTIFICATION: 30 pins (15 per row), NOT the 38-pin layout. Confirmed twice
// from images/ESP32_top.jpg - pin count and the full silkscreen label sequence
// both match DevKit V1 exactly:
//   row A: 3V3 GND D15 D2 D4 RX2 TX2 D5 D18 D19 D21 RX0 TX0 D22 D23
//   row B: VIN GND D13 D12 D14 D27 D26 D25 D33 D32 D35 D34 VN VP EN
// ===========================================================================

esp_pins_per_row = 15;                              // [EXACT] counted
esp_pin_span     = (esp_pins_per_row-1) * pitch;    // [DERIVED] 35.56 mm

esp_len   = 51.50;  // [MODEL] photo: 51.4 +/- 0.9 -> agrees
esp_width = 28.50;  // [MODEL] photo: 28.7 +/- 0.4 -> agrees
esp_corner_r = 1.5; // [EST]   visible radius, not critical

// Header rows, symmetric about the board centerline.
esp_row_spacing = 25.40;  // [OPEN] nominal 10 pitches = breadboard-compatible.
                          //   BUT: 3MF reads 25.74 and the photo reads 25.86,
                          //   and both put the rows 1.38-1.40 mm in from the
                          //   long edges. The photo's vertical axis is biased
                          //   ~1% high (board sits off-axis in frame), which
                          //   explains part but not all of the gap.
                          //   Unresolved. Does NOT affect the enclosure - the
                          //   pins sit inside the board footprint either way.
                          //   Resolve with a printed gauge before making any
                          //   part that engages the headers.

// Mounting holes - one near each corner. THIS BOARD HAS THEM; the 38-pin
// variants mostly do not, which is a real advantage for enclosure design.
esp_hole_dx  = 23.30;  // [MODEL] +/- from center, along length
esp_hole_dy  = 11.90;  // [MODEL] +/- from center, across width
esp_hole_dia = 3.10;   // [PHOTO] measured 2.89-3.03 across both axes. The 3MF
                       //   says 3.5 and DevKit V1 is usually quoted at 3.2.
                       //   Treat as "M3 clearance at best, likely tight".
                       //
                       // NOTE on the hole PATTERN: the photo puts the holes at
                       // dx ~23.8, dy ~11.4 against the 3MF's 23.30 / 11.90, so
                       // the two sources agree only to about +/-0.6 mm. Do not
                       // design screw bosses that need tighter alignment than
                       // that - oversize the boss clearance holes, or locate
                       // the board off its outline and treat screws as
                       // secondary retention.

// USB-C receptacle, at the -X end, centered across the width (3MF offset 0.00).
// Shell dims are the standard 16-pin SMD receptacle, NOT taken from the 3MF -
// that model is flattened in height (only 1.8 mm tall vs 3.26 real).
usb_width    = 8.94;   // [EXACT] standard shell; photo reads 8.66 -> agrees
usb_height   = 3.26;   // [EXACT] above PCB top face. The 3MF is flattened to
                       //   1.80 here and must not be used for this.
usb_body_len = 7.35;   // [EXACT] shell length along X; photo reads 7.72
usb_overhang = 1.75;   // [PHOTO] projection past the PCB edge, measured off
                       //   images/ESP32_top.jpg. The 3MF says 0.70 - it is
                       //   WRONG, or at least models a different connector.
                       //   The photo is direct evidence, so it wins. This is
                       //   the single highest-risk number for the port cutout.

// ESP32-WROOM-32 module, at the +X end.
wroom_len     = 25.50;  // [DATASHEET] 18.00 x 25.50 x 3.10
wroom_width   = 18.00;  // [DATASHEET]
wroom_height  = 3.10;   // [DATASHEET] total above the PCB top face
wroom_pcb_h   = 0.80;   // [DATASHEET] module PCB alone (the antenna tail)
wroom_can_len = 17.60;  // [MODEL] the shield can is smaller than the module
wroom_can_w   = 15.74;  // [MODEL]
wroom_x0      = 0.25;   // [MODEL] module starts here, runs to +esp_len/2
wroom_can_x   = 9.95;   // [MODEL] can center along X

// EN and BOOT tact switches, one near each long edge at the USB-C end.
// Positions read off images/ESP32_top.jpg - approximate, but they set the
// height budget at that end of the board so they are worth carrying.
esp_btn_x  = -22.70;  // [PHOTO]
esp_btn_dy =   7.70;  // [PHOTO] +/- from centerline
esp_btn    =   4.50;  // [PHOTO] small SMD tact, body ~4.1 x 3.1 plus solder
                      //   tabs. Not the 6x6 through-hole type.
esp_btn_h  =   2.50;  // [EST]  low-profile SMD tact

// Header assembly below the board.
hdr_plastic_h = 2.54;  // [PHOTO] measured 2.54 exactly - standard part
hdr_below     = 8.50;  // [MODEL] PCB bottom face to pin tips. Photo reads ~9.0
                       //   at an oblique angle; 8.5 is the standard header.
hdr_pin_sq    = 0.64;  // [EXACT] standard square pin
esp_hdr_x_off = 2.00;  // [MODEL] the header rows are NOT centered on the board -
                       //   they sit 2 mm toward the WROOM end, because the
                       //   buttons take the space at the USB-C end.

// Everything else on the top face (CP2102, regulator, EN/BOOT buttons, caps).
// Modeled as a single keep-out slab rather than individual parts - for
// enclosure clearance that is the number that matters.
esp_misc_height = 3.50;  // [EST] keep-out height over the non-WROOM half.
                         //   Driven by the USB-C shell at 3.26; 3.50 leaves a
                         //   little margin for parts not individually modeled.
                         //   Revisit if the lid ends up within ~1 mm of it.

// ===========================================================================
// PERFBOARD - 4 x 6 cm double-sided prototyping board
//
// This is what the enclosure actually mounts to. The ESP32 is soldered to this
// board, so the ESP32's own mounting holes are NOT used - the perfboard's four
// corner holes carry the assembly.
//
// Measured from images/perfboard_4x6_photo.jpg - a photo of the actual board,
// at 8.71 px/mm. It carries silkscreen row/column labels, which settle the grid
// counts outright, and "40*60MM" confirming the outline.
//
// The listing image (images/perfboard_4x6.png) was used first and got several
// things wrong; where they disagree, the photo wins. Method check: measuring
// the round thru-holes the same way returns 1.04 mm against a 1.0 mm nominal,
// so these numbers are good to roughly +/-5%.
// ===========================================================================

pb_len   = 60.00;  // [EXACT] stated on the listing image, confirmed by aspect
pb_width = 40.00;  // [EXACT]
pb_thick =  1.60;  // [EXACT] standard FR-4

pb_pitch = 2.54;   // [EXACT] silkscreen grid; measured 2.549
pb_cols  = 14;     // [EXACT] silkscreen labels A..N. Span 13*2.54 = 33.02 mm
pb_rows  = 20;     // [EXACT] silkscreen labels 1..20. Span 19*2.54 = 48.26 mm
                   //   Both grids are centered on the board (measured margins
                   //   3.70/3.12 and 5.80/5.17 vs 3.49 and 5.87 nominal).

// The two 40 mm edges carry a row of elongated SMD pads. They are PADS, not
// holes - solid tinned copper, nothing drilled through. They also sit on their
// OWN pitch, not the 2.54 grid, which is why they looked half a pitch off when
// measured against the columns in the lower-resolution listing image.
pb_edge_pads       = 12;    // [PHOTO] counted three ways, all agree
pb_edge_pad_pitch  = 2.70;  // [PHOTO] NOT 2.54; span 11*2.70 = 29.7 mm
pb_edge_pad_inset  = 1.78;  // [PHOTO] pad row center, from the board edge
pb_edge_pad_w      = 1.80;  // [PHOTO] short axis, across the row
pb_edge_pad_l      = 2.90;  // [PHOTO] long axis, pointing at the board edge
pb_edge_pad_h      = 0.10;  // copper + finish. Exaggerated slightly so the pads
                            //   are visible in renders; real HASL is ~0.07.
pb_edge_pad_x = pb_len/2 - pb_edge_pad_inset;   // [DERIVED] row center, +/- X

pb_hole_dia = 1.00;  // [PHOTO] measured 1.04 across three holes; 1.0 nominal
pb_pad_dia  = 1.80;  // [EST] annular ring around each thru-hole

// Corner mounting holes. THESE ARE THE ENCLOSURE INTERFACE - the most important
// numbers on this page. Unplated: bare drilled holes, no copper ring.
pb_mount_dx = 28.17;  // [PHOTO] +/- along the 60 mm axis (pattern 56.34 mm)
pb_mount_dy = 18.01;  // [PHOTO] +/- along the 40 mm axis (pattern 36.02 mm)
                      //   i.e. ~1.83 and ~1.99 mm in from the respective edges.
pb_mount_dia = 1.85;  // [PHOTO] four holes gave 1.56 / 1.79 / 1.93 / 1.93 by
                      //   radial half-max, a method that returned 1.04 on the
                      //   1.0 mm thru-holes. So ~2.0 mm nominal at most.
                      //
                      //   CONSEQUENCE: this is an M2 hole at best, and an M2
                      //   screw (2.0 mm major dia) will be interference or will
                      //   not pass at all. M3 is definitively out. Plan on M2
                      //   with the holes opened up, or M1.6, or do not screw
                      //   through them at all and capture the board edges
                      //   instead. Worth settling with an actual screw.


// --- Print and fit -----------------------------------------------------------

clearance = 0.20;  // [EST] per-side slip fit. Replace with the value the
                   //       printed fit gauge actually selects.
wall      = 2.00;
nozzle    = 0.40;
layer     = 0.20;

// --- Guards ------------------------------------------------------------------

assert(esp_pins_per_row == 15,
       "This build uses the 30-pin DevKit V1. 38-pin boards differ in length.");
assert(esp_len > esp_pin_span, "board shorter than its own pin span");
assert(esp_width > esp_row_spacing, "board narrower than its header rows");
assert(esp_hole_dx + esp_hole_dia/2 < esp_len/2,
       "mounting hole breaks the end edge");
assert(esp_hole_dy + esp_hole_dia/2 < esp_width/2,
       "mounting hole breaks the side edge");
assert(usb_width < esp_width, "USB-C wider than the board");
// Buttons sit alongside the corner holes; catch any overlap after an edit.
assert(esp_btn_dy + esp_btn/2 < esp_hole_dy - esp_hole_dia/2,
       "EN/BOOT buttons overlap the corner mounting holes");
