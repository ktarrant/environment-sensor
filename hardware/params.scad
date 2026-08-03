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
//   [GAUGE]    read off the printed fit gauge, on THIS printer in THIS
//              material. Reprint hardware/fitgauge.scad if either changes.
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
esp_row_spacing = 25.40;  // [PROVEN] exactly 10 pitches. The board is soldered
                          //   into the perfboard with its two header rows on
                          //   columns B and L, which are 10 * 2.54 apart. A
                          //   part physically seated in a 2.54 grid cannot be
                          //   at any other spacing, so this is now certain.
                          //   (Was [OPEN]: the 3MF read 25.74 and the photo
                          //   25.86. Both were high - the 3MF is loose here and
                          //   the photo's vertical axis carried a ~1% bias.)

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
pb_mount_dia = 2.20;  // [SCREW TEST] M2 passes, M2.5 does not -> the hole is
                      //   in [2.05, 2.50). 2.20 is the midpoint.
                      //   My photo measurement said 1.85, which the screw test
                      //   shows was low by at least 0.2 mm; the radial half-max
                      //   method under-reads on an unplated hole with no bright
                      //   annular ring to bound it. The screw wins.
                      //
                      //   CONSEQUENCE: fasten with M2. M2.5 and M3 are out.


// ===========================================================================
// CONNECTOR - "JST-XH style" 2.54 mm, 4-pin, board header
//
// Joins the MCU enclosure to the sensor enclosure. Both ends already built.
//
// ON THE PITCH: genuine JST XH (B4B-XH-A) is 2.50 mm, per JST's own datasheet.
// The part in this build is a "JST-XH *style*" clone sold as 2.54 mm, and clone
// makers do build true 2.54 versions so they drop into 0.1 in perfboard. We use
// 2.54. Note the two are nearly indistinguishable by fit at 4 pins - the spans
// differ by 0.12 mm total, which a 0.95 mm hole swallows - so if this ever
// needs settling, settle it on the listing, not on how it seats.
//
// Body dimensions are from the KiCad model of the genuine B4B-XH-A, which
// agrees with the JST footprint outline. Only the pin span is rescaled to 2.54;
// the moulding around it is a fixed 4.90 mm of plastic.
// ===========================================================================

xh_pitch = 2.54;   // [SPEC] per the listing for this part (JST proper is 2.50)
xh_pins  = 4;      // [EXACT]
xh_pin_span = (xh_pins - 1) * xh_pitch;          // [DERIVED] 7.62
xh_body_len = xh_pin_span + 4.90;                // [DERIVED] 12.52
xh_body_depth = 5.75;   // [MODEL] across the pin row
xh_body_h     = 7.00;   // [MODEL] shroud height above the PCB top face
xh_pin_below  = 3.40;   // [MODEL] pin tails below the PCB
xh_pin_sq     = 0.64;   // [EXACT] standard XH square post
xh_drill      = 0.95;   // [MODEL] recommended PCB hole

// The shroud is not centered on the pin row: the latch side is deeper.
xh_body_front = 2.35;   // [MODEL] pin row to the shallow side
xh_body_back  = 3.40;   // [MODEL] pin row to the latch side

// Mated envelope - header PLUS the plug housing pushed onto it. This is what
// actually sets the lid clearance, and it is the one number here that is NOT
// from a datasheet.
xh_mated_h = 11.60;     // [PHOTO] measured off images/sensor_profile.jpg, where
                        //   the plug's outer face was lined up with the mat
                        //   ruler's zero: board surface to plug face reads
                        //   11.6 mm. (The earlier 11.50 estimate was right.)
                        //   Does NOT include wire bend radius beyond the plug -
                        //   budget that separately at the cable exit.
                        //
                        //   CAVEAT: the connector on the photographed sensor
                        //   board is soldered slightly askew, so this was
                        //   measured on a tilted assembly. A tilt projects
                        //   LONGER, not shorter, so 11.6 is more likely a small
                        //   over-read than an under-read - the safe direction
                        //   for clearance. Do not shave it.

// Hand-soldered connectors are not reliably square to the board. Allow this
// much angular slop wherever a housing constrains the connector or its cable
// exit, rather than designing to a perfectly perpendicular plug.
xh_solder_tilt = 5;     // [EST] degrees, from the built units

// ===========================================================================
// SENSOR BOARD - purple "GYBMEP" BME280 breakout
//
// Identified from images/sensor_bottom.jpg. NOT the 6-pin GY-BME280 the BOM
// originally assumed - this one is 4-pin, I2C only, which is exactly why a
// 4-wire cable suffices. It carries an onboard 3.3 V LDO (SOT-23 marked 662K =
// XC6206), so VCC accepts anything from ~3.3 to 5 V.
//
// It also has ONE mounting hole, contradicting the earlier "no mounting holes
// on either sensor variant" note in BOM.md.
//
// Outline: a vendor reference says 13 x 10, and measuring the photo
// independently gave 12.3 x 10.4. Two unrelated sources within 0.5 mm, so 13x10
// is adopted. (A different listing claimed 9 x 11 x 2 - that is the outlier and
// is disregarded; it disagrees with both.)
//
// Everything else here is soft. The photo is hand-held and angled, the board
// occupies only ~137x162 px in it, and the pad-pitch trick that worked
// elsewhere could not resolve four pads at that scale. Re-shoot flat and
// straight down before designing the sensor enclosure.
// ===========================================================================

bme_len       = 13.00;  // [REF, photo agrees +/-0.5] long axis
bme_width     = 10.00;  // [REF, photo agrees +/-0.5] the connector is on this edge
bme_pins      = 4;      // [PHOTO] VCC / GND / SCL / SDA - I2C only
bme_has_ldo   = true;   // [PHOTO] 662K / XC6206 3.3 V regulator on board
bme_mount_dia = 3.00;   // [EST] the single hole; not yet measured

// Mounting hole center, from the PCB center. Estimated off the BOTTOM-side
// photo by proportion, so the magnitudes are soft and the SIGN OF Y IS NOT
// TRUSTWORTHY - a bottom view is mirrored, and this hole is off-center by
// ~2 mm, so getting the mirror wrong puts a boss ~4 mm out of place.
// Confirm against a TOP-side photo before committing to a screw boss.
bme_mount_x = -3.25;    // [EST] toward the end away from the connector
bme_mount_y = -2.10;    // [EST] MIRROR-AMBIGUOUS, see above

// Connector pin row, measured in from the edge it sits on.
bme_conn_inset = 1.50;  // [EST] the shroud slightly overhangs that edge, and
                        //   overhangs both long sides too: the 12.52 mm body on
                        //   a 10 mm wide board hangs over by ~1.3 mm a side.
                        //   That is visible in images/sensor_bottom.jpg.
bme_pcb_thick = 1.20;   // [EST] these breakouts run thinner than 1.6
bme_comp_h    = 1.30;   // [EST] tallest part above the PCB; ~2.5 overall, which
                        //   matches the "2-3 mm" a vendor reference quotes.
                        //   Irrelevant to lid height either way - the mated
                        //   connector at 11.6 mm dwarfs it.

// --- Print and fit -----------------------------------------------------------

clearance = 0.20;  // [EST] per-side slip fit. Replace with the value the
                   //       printed fit gauge actually selects.
wall      = 2.00;
nozzle    = 0.40;
layer     = 0.20;

// M2 is the only fastener in this build - the perfboard's corner holes settle
// that (M2.5 does not pass). One screw per corner does three jobs at once:
// it enters from OUTSIDE the tub floor, passes up the standoff, through the
// board, and taps into a post hanging from the lid. See enclosure_mcu.scad.
m2_free   = 2.40;  // [EST] clearance hole for an M2 shank
m2_pilot  = 1.70;  // [OPEN] UNRESOLVED - the fit gauge did not settle this, it
                   //   failed it. In a 4.20 mm free-standing post: 1.80 split
                   //   the post while driving, and 1.90 accepted the screw only
                   //   because it is very nearly a clearance hole - an M2's
                   //   major diameter is 2.00, so 1.90 leaves 0.05 mm of radial
                   //   thread. DO NOT ADOPT 1.90. It will strip on the first or
                   //   second assembly.
                   //
                   //   The gauge conflated two variables in one row - pilot
                   //   diameter AND the strength of a thin column - so it can
                   //   say "a 4.2 mm post will not take an M2 thread on this
                   //   printer" but it cannot say what pilot to use in solid
                   //   material. The pod's screws tap into 6 mm-thick SOLID
                   //   end walls, which is not the case that failed.
m2_head_d = 3.80;  // [EST] pan head
m2_engage = 6.00;  // thread engagement in the lid post
enc_fillet = 1.20; // [DESIGN] flare where a post or standoff meets the plate it
                   //   stands on. Added after the fit gauge's posts sheared off
                   //   at exactly that junction, hole intact - a root failure,
                   //   not a thread failure. Costs nothing to print.

// ===========================================================================
// ENCLOSURE - MCU box
//
// Everything here is a choice, not a measurement, so the tags are [DESIGN]
// unless noted. The dimensions these choices have to RESPECT all live above.
// ===========================================================================

enc_board_gap = 0.40;   // [DESIGN] per side, between a board and the cavity
                        //   around it. Deliberately looser than `clearance`:
                        //   in BOTH enclosures the board is located by its
                        //   fasteners or by the connector, never by the cavity
                        //   walls, so this gap does no work and a tight print
                        //   here is a board that will not drop in for nothing.
                        //   Use `clearance` for fits that actually locate.

enc_wall      = 2.00;   // [DESIGN] side walls
enc_floor     = 2.40;   // [DESIGN] thicker than the walls: the screw heads are
                        //   counterbored into it, so it loses 1.4 mm locally.
enc_lid_t     = 2.00;   // [DESIGN]
enc_r_out     = 3.00;   // [DESIGN] outer corner radius
enc_r_in      = 0.80;   // [DESIGN] inner corner fillet. MUST stay small: only
                        //   1.76 mm of slack exists at the board's corners, and
                        //   a radius over ~1.0 eats into them. Asserted below.

enc_standoff_h = 6.00;  // [DESIGN] wiring face to the tub's inner floor. Must
                        //   clear 4.36 mm of untrimmed ESP32 header tails PLUS
                        //   the hand-laid wiring on that face, which nobody has
                        //   measured. First thing to raise if the board will
                        //   not sit down flat.
enc_boss_od    = 5.00;  // [DESIGN] standoff tube under each corner hole
enc_post_od    = 4.20;  // [DERIVED] the lid post over each corner hole. NOT a
                        //   free choice: at the -X/+Y corner the ESP32's own
                        //   PCB edge is 2.49 mm away, so anything over ~4.6
                        //   collides with the board it is meant to hold down.
                        //   Asserted in enclosure_mcu.scad.

enc_cable_head = 4.00;  // [EST] room above the MATED plug face for the cable to
                        //   turn and leave through the wall. This is a guess
                        //   standing in for a bend radius nobody has measured -
                        //   the cable finishes its bend outside the box, which
                        //   is what keeps this number as small as 4.
cable_od       = 3.40;  // [GAUGE] the cable passes the 3.40 hole and not the
                        //   3.20, so 3.40 is the smallest bore it fits - which
                        //   is its diameter, read to the row's 0.20 step. Was
                        //   [EST] 3.00; the pigtail is fatter than assumed.
enc_exit_w     = 5.00;  // [DESIGN] cable notch width: cable_od plus room for
                        //   xh_solder_tilt to throw the plug sideways.

// Interference at a cable clamp. NOT 0.40: the gauge's one-sided pinch ribs at
// that value let the cable slide straight through, which is the whole reason
// the MCU box now closes on the cable with a clamp on the lid instead of
// relying on two bumps in a wall.
cable_grip     = 0.80;

usb_cut_margin = 0.50;  // [GAUGE] per side, around the USB-C shell. The gauge's
                        //   smallest window - this value - took the receptacle
                        //   AND the plug with margin to spare, so the 0.80 it
                        //   was drawn at is more than needed. Not tightened
                        //   further: nothing is gained past "it fits".
usb_plug_w     = 12.50; // [EST] the PLUG's overmold, not the receptacle. The
usb_plug_h     =  7.50; // [EST]   shell face lands 0.45 mm inside the outer
usb_relief_d   =  1.20; // [DESIGN] wall face, so without this relief pocket a
                        //   fat cable cannot seat. Both [EST] values are pure
                        //   guesses - put them on the fit gauge.

enc_vent_w     = 1.60;  // [DESIGN] 4 nozzle widths - bridges and prints clean
enc_vent_pitch = 4.40;  // [DESIGN]
enc_vents      = 9;     // [DESIGN] per long wall

// ===========================================================================
// ENCLOSURE - sensor pod
//
// A clamshell split down the plane of the cable, NOT a tub and lid. Two
// reasons, and the second one is the real one:
//   - the cable has a housing on BOTH ends, so it cannot be threaded through
//     a closed hole; the exit has to be split between the two halves.
//   - the board is held with no screw through it at all, so the pod does not
//     depend on bme_mount_x/y, which are [EST] and mirror-ambiguous. Nothing
//     here is blocked on that photo.
// ===========================================================================

pod_wall   = 2.00;   // [DESIGN]
pod_r      = 1.50;   // [DESIGN] outer edge radius. Small on purpose: printed on
                     //   the parting face, this radius is a roof.
pod_gap    = 0.50;   // [EST] around the connector and plug. Deliberately looser
                     //   than `clearance`: the PLUG's outline has never been
                     //   measured, and connector.scad just assumes it matches
                     //   the header's.
pod_ledge_t   = 2.00;  // [DESIGN] shelf the board's trace face rests on
pod_screw_wall = 3.00; // [DESIGN] material each side of the screw in the end
                       //   walls, so the wall comes out 6.0 thick. Sized by the
                       //   TAPERED plug pocket, which leans toward the +X screw
                       //   as it deepens - at 2.60 the wall between them came
                       //   out under 0.9 mm. Asserted in enclosure_sensor.scad.
pod_cable_room = 2.00; // [DESIGN] between the plug's face and the end wall
                       // The pod's gland uses `cable_grip` above. It is a full
                       // 360 degree clamp pulled up by two screws, so it starts
                       // from a much better place than the pinch that failed -
                       // but it is set to the same interference, because a
                       // clamp that does not grip is not strain relief.
pod_tap_depth  = 8.00; // [DESIGN] tapped depth in the far half

pod_vents      = 5;     // [DESIGN] slots in the grille over the sensor
pod_vent_w     = 1.60;  // [DESIGN]
pod_vent_pitch = 2.60;  // [DESIGN]

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

// --- enclosure guards --------------------------------------------------------

// The screw passes through the board's own corner hole on its way to the lid
// post. This is the screw test, encoded.
assert(pb_mount_dia > 2.05,
       "an M2 shank will not pass the perfboard corner hole");
assert(enc_standoff_h > hdr_below - hdr_plastic_h - pb_thick,
       "standoff shorter than the untrimmed ESP32 header tails");
assert(enc_post_od > m2_pilot + 4*nozzle,
       "lid post wall too thin to hold a tapped M2 thread");
assert(enc_boss_od > m2_free + 4*nozzle,
       "standoff tube wall too thin");
assert(enc_exit_w > cable_od,
       "cable exit narrower than the cable");
assert(enc_vent_w >= 3*nozzle, "vent slots too narrow to print open");
