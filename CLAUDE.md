# environment-sensor

ESPHome environmental sensor for Home Assistant: an ESP32 reading a BME280 over
I2C. Physically it is **two enclosures joined by a 4-pin cable** - an MCU end and
a sensor end. Both circuit boards are **already built and wired**; this repo
documents them and designs the enclosures. The enclosures do not exist yet.

## Build

OpenSCAD 2021.01, CLI at `/Applications/OpenSCAD-2021.01.app/Contents/MacOS/OpenSCAD`
(overridable via `OPENSCAD=`). There is no OpenSCAD on `$PATH`.

```
make            # 4 STLs into build/, 5 renders into images/renders/
make assembly   # just the MCU module
```

`build/perfboard.stl` takes ~30 s - CGAL differencing ~300 holes. Set
`show_grid = false` for fast iteration. Do not raise `$fn` on the grid holes;
at the default facet count that target took 2m14s for no visible gain.

## How the models are organised

- **`hardware/params.scad` is the single source of truth.** Nothing else
  hardcodes a dimension. Correct a value there and everything follows.
- Every value carries a confidence tag: `[EXACT]` `[DERIVED]` `[MODEL]`
  `[PHOTO]` `[DATASHEET]` `[PROVEN]` `[SCREW TEST]` `[EST]` `[OPEN]`.
  **Preserve these when editing** - they are how we know what is trustworthy.
  `[EST]` and `[OPEN]` mark things that are still guesses.
- Models are deliberately **rough**: outline, mounting features, ports and
  heights are real; cosmetic detail is not. They exist for fit and clearance.
- `assert()` guards encode the constraints. They have caught real errors twice.
  Add one whenever you encode a relationship.
- Each model also exposes a `*_keepout()` solid for enclosure boolean ops.

Coordinate conventions (stated in each file's header, they differ):

| file | origin | Z = 0 |
| --- | --- | --- |
| `esp32.scad` | PCB center, +X = WROOM end, -X = USB-C | PCB bottom |
| `perfboard.scad` | board center, +X = row 20, +Y = column A | wiring face |
| `connector.scad` | pin row center | the surface it mounts on |
| `assembly.scad` | perfboard's frame | perfboard wiring face |

`perfboard.scad` exposes `pb_hole("L", 2)` for silkscreen grid addressing - use
it instead of raw coordinates so wiring notes transcribe directly into geometry.

## The hardware, settled

| Part | What it actually is |
| --- | --- |
| MCU | **DOIT ESP32 DevKit V1 clone, 30-pin** (15/row), USB-C, CP2102. Sold as ELEGOO, Micro Center #704603. **Not** the 38-pin board. |
| Carrier | 4x6 cm perfboard, **14 x 20** grid at 2.54, silkscreen A..N / 1..20, corner holes take **M2 only** |
| Connector | "JST-XH style" 4-pin. **2.54 pitch per the listing** (genuine JST XH is 2.50 - do not "correct" this). Mated height **11.6 mm** |
| Sensor | Purple **GYBMEP** BME280 breakout. **4-pin, I2C only**, onboard 3.3V LDO (`662K`), **one** mounting hole, **13 x 10 mm**, ~2.5 thick |

## Wiring (MCU end)

Components are on the face **opposite** the silkscreen; wiring runs on the
silkscreen face so the grid labels stay readable while soldering.

| # | Signal | Connector | ESP32 hole | ESP32 pin | Wire |
| --- | --- | --- | --- | --- | --- |
| 1 | Power  | C20 (pin 1) | L2  | `3V3`          | red |
| 2 | Ground | D20         | B3  | `GND`          | black |
| 3 | Clock  | E20         | L15 | `GPIO22 (SCL)` | orange |
| 4 | Data   | F20         | L12 | `GPIO21 (SDA)` | blue |

`assembly.scad` solves the ESP32's position from wire 1 and **asserts** the
other three land on their own holes. Full detail in `docs/assembly.md`.

## Measuring parts without a caliper

The user has no caliper - only a tape measure. The method that works, and that
produced nearly every number here, is in `docs/measuring.md`:

**Scale photographs against the 2.54 mm header pitch.** It is held to well under
0.1 mm and sits in the same image as the subject, so camera distance and lens
error cancel. Fit a periodic model to the pin row for the scale, then measure
everything else against it. Calibrate the method by re-measuring a feature of
known size (the perfboard's 1.0 mm thru-holes returned 1.04).

Hard-won cautions:

- **Constrain the pitch search.** An unconstrained fit finds degenerate
  solutions - it will cram all N points into one dark blob.
- **Verify fits by overlaying them on the image** before trusting the numbers.
- **The vertical axis reads ~1% high** when the part sits off-center in frame.
- **Parallax inflates elevated parts near the frame edge** - the ESP32, 4 mm up
  on its headers, read ~1 mm wide at the board edge.
- **Radial half-max under-reads unplated holes** (no bright annular ring to
  bound the edge). It was 0.2+ mm low on the perfboard's corner holes; the
  screw test corrected it.
- **Listing images are not photos of your part.** The perfboard listing image
  got the row count, hole diameter, and the nature of the edge features all
  wrong. Ask for a photo of the real thing.

## Things that were wrong and got fixed

Do not re-derive these; they cost real effort.

- The BOM originally said **38-pin** ESP32. It is 30-pin. Pin count and the
  silkscreen label sequence both confirm DevKit V1.
- `reference/esp32_devkitv1.3mf` (community model) is **accurate in plan but
  flattened in height**, and its USB-C overhang (0.70) is wrong - the photo
  says 1.75. Validated it against photos before trusting it; do the same for
  anything else downloaded.
- ESP32 header row spacing is **exactly 25.40** (10 pitches). Proven by the
  board being soldered across perfboard columns B..L. The 3MF said 25.74 and
  photo measurement said 25.86; both were wrong.
- Perfboard edge features are **SMD pads, not holes**, on their **own ~2.70 mm
  pitch**, not the 2.54 grid.
- On the **sensor** board the connector body is on the **trace side, opposite
  the components** - its pins pass up through the board. So that end's envelope
  straddles the PCB (11.6 mm below, 3.4 mm above, 15 mm across) rather than
  stacking on one face like the MCU end does.
- OpenSCAD: an outer `color()` overrides children's colors in these renders.
  Color the parts individually, do not wrap the assembly.

## Status and what is next

**Done:** ESP32, perfboard, connector and MCU assembly models, all building and
manifold; BOM and measurement/assembly docs; photos in `images/`. Enclosure plan
in `docs/enclosure.md` - **three complete units**, one per room, each two shells
on a 10-20 cm pigtail. **Both enclosures drafted**, building manifold with an
empty `make check`, neither printed:

- `enclosure_mcu.scad` - tub + lid, 67.5 x 44.4 x 27.6, 4x M2x16 **from below**;
  one screw per corner holds the lid, the board, and locates the board.
- `enclosure_sensor.scad` - two clamshell halves, 27.8 x 21.6 x 23.4, 2x M2x16.
  **Printed and fits** (third attempt) - closed by hand on the real board and
  cable; screws still on order, so the tapped joint is unconfirmed.
  **Print each half OUTER FACE DOWN, opening up** - rim-down puts the half's own
  outer wall over its cavity as an unsupported ceiling, and that constraint is
  why the pod is a straight box rather than the tapered one it started as.
  Split on the cable axis because the pigtail has a housing on **both** ends and
  cannot be threaded. The board is held by shoulders on the connector's flange,
  not by a screw - so the pod does **not** depend on `bme_mount_x/y`.

Every fastener in the project is an M2 x 16.

**`hardware/fitgauge.scad` has been printed twice and both enclosures are built
on what it returned.** `cable_od` 3.40, `usb_cut_margin` 0.50. It killed the MCU
box's pinch-rib strain relief (now a screw-pulled clamp on the lid) and it
caught two things that would each have wasted a print:

- **This printer takes ~0.2 mm off a small hole.** Both gauges chose a 1.90
  pilot for M2, which is only sane if the hole comes out near 1.70. `m2_pilot`
  is a *modelled* value carrying that compensation - the only printer-specific
  number in `params.scad`. `cable_od` is NOT corrected the same way: a printed
  feature measured against another printed feature cancels the offset, one
  measured against a real object (the screw) does not.
- **The mated plug is ~1 mm per side bigger than the header** it pushes onto,
  which `connector.scad` had assumed they matched. `xh_plug_len/depth` are real
  parameters now and the pod's pocket derives from them. Also: the fit gauge
  posts sheared at their root, so every post and standoff carries `enc_fillet`.

Detail in `docs/enclosure.md`.

After that: the three mount adapters (M4), then unit B's skin.

Starting facts:

- MCU envelope: **17.56 mm** total (13.20 above the wiring face, 4.36 below).
  The **mated connector**, not the ESP32, sets the lid height.
- USB-C stands **3.31 mm proud** of the perfboard end, and exits the **opposite
  end** from the 4-pin cable, so the two openings never share a wall.
- Mount through the perfboard's four corner holes with **M2**. The ESP32's own
  mounting holes are unused.
- Print a **fit gauge** before printing an enclosure - see the last section of
  `docs/measuring.md`. It converts a wrong number into a measured one.

**Open, in priority order:**

1. **The BME280 must not share a sealed volume with the ESP32.** WROOM
   self-heating biases temperature by several degrees and drags RH with it.
   Plan a vented, thermally separated sensor chamber. This is the main reason
   the design is two enclosures, and it is the main design constraint left.
2. The **sensor end is unmodeled**. The part is identified and its outline is
   agreed by two sources (13 x 10), but the mounting hole, its position, and the
   thicknesses are all `[EST]`. **Ask for a flat, straight-down photo** before
   designing that enclosure - the method in `docs/measuring.md` will then give
   ~0.1 mm, which the hand-held shots we have cannot.
3. **Connectors are hand-soldered and sit slightly askew** - the built sensor
   board is visibly tilted. Allow `xh_solder_tilt` (~5 deg) wherever a housing
   constrains the connector or the cable exit. A design assuming a perpendicular
   plug will bench-test fine and then refuse to close.
4. `pb_edge_pad_*` dimensions are `[EST]`. Cosmetic only.

**Recently closed** (do not redo): `xh_mated_h` is now measured at 11.60 from
`images/sensor_profile.jpg`, where the plug face was aligned to the ruler zero -
the 11.50 estimate was very nearly right. Sensor variant is resolved: 4-pin,
I2C-only, with an onboard LDO, which is why 4 wires suffice.

One live caution: VCC is fed from **3V3**, which sits the sensor's LDO near
dropout. It works at the BME280's microamp draw, but if readings ever go
erratic, moving VCC to VIN/5V is the first thing to try.
