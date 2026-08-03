# Bill of Materials

## Exact parts this build used

| Part | Product | Source |
| --- | --- | --- |
| **MCU** | ELEGOO ESP-32 Development Board, 3-pack | Micro Center [#704603](https://www.microcenter.com/product/704603/ESP-32_Development_Board_-_3_Pack), Mfr 50.303.0052 |
| **Sensor** | BME280 5V Sensor Module, 2-pack (GY-BME280) | Amazon [B0DHPCFXCK](https://www.amazon.com/dp/B0DHPCFXCK) |
| **Carrier** | 4 x 6 cm double-sided prototyping board | see below |
| **Interconnect** | 4-pin cable + connectors, MCU end to sensor end | see below |

## MCU - ELEGOO ESP-32 devkit

### It is a 30-pin DevKit V1, not a 38-pin board

This was the first thing the photos settled, and it matters: the two layouts are
different lengths and the 38-pin variants mostly lack mounting holes. Counted
from [images/ESP32_top.jpg](images/ESP32_top.jpg): **15 pins per row, 30 total**,
with the DOIT ESP32 DevKit V1 label sequence:

```
row A:  3V3 GND D15 D2  D4  RX2 TX2 D5  D18 D19 D21 RX0 TX0 D22 D23
row B:  VIN GND D13 D12 D14 D27 D26 D25 D33 D32 D35 D34 VN  VP  EN
```

**Confirmed** (Elegoo's own listing for the same board, [B0D8T53CQ5](https://www.amazon.com/ELEGOO-ESP-WROOM-32-Development-Bluetooth-Microcontroller/dp/B0D8T53CQ5), plus the photos):

- ESP-WROOM-32 module, dual-core 240 MHz, 4 MB flash, ~520 KB SRAM
- Wi-Fi 802.11 b/g/n + Bluetooth 4.2 LE
- **USB-C** connector, **CP2102** USB-UART, EN + BOOT tact switches
- Auto-reset programming circuit - no need to hold BOOT to flash
- **Four corner mounting holes**, ~3.1 mm
- ESPHome: `board: esp32dev`

### Dimensions

No vendor drawing exists - Elegoo publishes none, and Espressif's
[KiCad library](https://github.com/espressif/kicad-libraries) ships STEP for the
WROOM-32 *module* only, not for any devkit carrier board. So the numbers in
[params.scad](hardware/params.scad) come from two independent sources that were
cross-checked against each other:

1. **[reference/esp32_devkitv1.3mf](reference/esp32_devkitv1.3mf)** - a community
   DevKit V1 model. Validated, not trusted blindly: its pin geometry (15/row,
   2.55 pitch, two rows) and outline (51.50 x 28.50) both match the photos.
2. **The photos**, scaled against the 2.54 mm header pitch. Measured
   51.4 +/- 0.9 x 28.7 +/- 0.4 mm.

Where they conflict, see the tags in params.scad. The 3MF is **flattened in
height** and understates the USB-C overhang (0.70 vs a measured 1.75 mm), so
heights and the port cutout come from the photos and datasheets instead.

## Sensor - BME280 breakout

- BME280 (temperature + humidity + pressure), I2C and SPI capable
- I2C address **0x76** with SDO tied low (default), 0x77 with SDO high

### Identified from [images/sensor_bottom.jpg](images/sensor_bottom.jpg)

Purple board, silkscreened **GYBMEP**. It is **not** the 6-pin GY-BME280 this
document originally assumed:

- **4 pins** - VCC / GND / SCL / SDA, **I2C only**. This is why a 4-wire cable
  is sufficient, and it is a neat consistency check on the whole build.
- **Onboard 3.3V LDO** - the SOT-23 marked `662K` is an XC6206. So VCC tolerates
  roughly 3.3-5V, which matches the listing's "5V" claim.
- **One mounting hole.** An earlier note in this file said neither sensor
  variant had mounting holes. That was wrong for the board we actually have.
- **The connector is on the trace side, opposite the components.** Its pins pass
  up through the board and are soldered on the component face - the four dark
  blobs along the top edge of the photo are those solder joints, not the
  connector body. So the sensor end's envelope **straddles** the board rather
  than stacking on one side: ~11.6 mm of mated connector below, ~3.4 mm of
  components and pin ends above, **15 mm across**.
- **13 x 10 mm**, ~2.5 mm thick overall. A vendor reference gives 13 x 10, and
  measuring the photo independently gave 12.3 x 10.4 - two unrelated sources
  within 0.5 mm. (A different listing claimed 9 x 11 x 2; it disagrees with both
  and is disregarded.) Re-shoot flat before designing the sensor enclosure.

### Powering it

The build feeds VCC from the ESP32's **3V3**. That puts the onboard LDO near
dropout, but a BME280 draws microamps, so an XC6206 passes ~3.1-3.2V and the
part runs fine. **If readings ever go erratic, move VCC to VIN/5V first** - that
gives the regulator proper headroom and costs nothing to try.

SCL/SDA go to GPIO22 / GPIO21; see [docs/assembly.md](docs/assembly.md).

### Still worth confirming

**Is it actually a BME280?** These cheap multipacks are notorious for shipping
BMP280 instead - same footprint, no humidity. The `GYBMEP` silkscreen is used
for both. If ESPHome reports pressure and temperature but humidity reads `nan`,
that is what happened.

## Perfboard - 4 x 6 cm prototyping board

The ESP32 is soldered to this, so **the enclosure mounts to the perfboard's four
corner holes, not to the ESP32's**. That makes the perfboard the mechanical
interface, and its corner holes the most important dimensions in the project.

Measured from [images/perfboard_4x6_photo.jpg](images/perfboard_4x6_photo.jpg),
a photo of the actual board at 8.71 px/mm. It carries **silkscreen labels** -
columns A..N, rows 1..20, and "40*60MM" - which settle the grid outright.

- Outline **40 x 60 mm**, 1.6 mm FR-4 (silkscreen confirms)
- **14 x 20** grid of 1.0 mm thru-holes on a 2.54 mm pitch, centered
- Corner mounting holes, **unplated**, on a **36.02 x 56.34 mm** pattern
  (~1.99 and ~1.83 mm in from the respective edges)
- Each 40 mm edge carries **12 elongated SMD pads** - solid tinned copper with
  nothing drilled through - on their **own ~2.70 mm pitch**, not the 2.54 grid

Method check: measuring the round thru-holes the same way returns 1.04 mm
against a 1.0 mm nominal, so these are good to roughly +/-5%.

### The corner holes take M2

**Settled by screw test: M2 passes, M2.5 does not.** So the hole is in
[2.05, 2.50); `params.scad` carries 2.20 as the midpoint.

Worth recording *how* that went, because it is a lesson about the method: my
photo measurement said **1.85 mm**, which the screw test shows was low by at
least 0.2 mm. The radial half-max technique under-reads on an **unplated** hole,
because there is no bright annular ring to bound the edge against - it worked
fine on the plated thru-holes precisely because those have one. A go/no-go check
with a real screw beat careful image analysis here.

### Corrections the real photo forced

The listing image ([perfboard_4x6.png](images/perfboard_4x6.png)) is only
7.0 px/mm and got three things wrong, all now fixed:

| | listing image | actual board |
| --- | --- | --- |
| Grid rows | 21 (inferred) | **20** (silkscreen) |
| Edge features | oval *holes* | **SMD pads**, nothing drilled |
| Edge pad pitch | assumed 2.54 | **~2.70**, its own pitch |

On hole diameter the listing image was the one that got it right: it suggested
2.2-2.5 mm, the photo measurement said 1.85, and the screw test landed on
[2.05, 2.50). A low-resolution source is not wrong about everything, and a
higher-resolution one is not right about everything - which is the argument for
keeping the confidence tags in `params.scad` per-value rather than per-source.

## Connector - "JST-XH style" 2.54 mm, 4-pin

Carries power and I2C between the two enclosures.

**On the pitch:** genuine JST XH (`B4B-XH-A`) is **2.50 mm**, per
[JST's own datasheet](https://www.jst-mfg.com/product/pdf/eng/eXH.pdf). This
build uses a *"JST-XH **style**"* part sold as 2.54 mm, and clone makers do
build true 2.54 versions specifically to drop into 0.1 in perfboard. We model
2.54. Note the two are near-indistinguishable by fit at 4 pins - the pin spans
differ by 0.12 mm total (7.50 vs 7.62), which a 0.95 mm hole absorbs entirely -
so the listing settles this, not how it seats.

Body geometry is from the KiCad model of the genuine `B4B-XH-A`, which agrees
with JST's own footprint outline. Only the pin span is rescaled to 2.54; the
moulding around the pins is a fixed 4.90 mm of plastic either way.

| | |
| --- | --- |
| Body | **12.52 x 5.75 mm** (12.40 at genuine 2.50 pitch) |
| Height above board | **7.00 mm** |
| Pin tails below board | **3.40 mm** |
| Pin post | 0.64 mm square, 0.95 mm recommended drill |
| Shroud offset | 2.35 mm one side of the pin row, 3.40 mm on the latch side |

**Mated height: 11.6 mm** from the board surface to the plug's outer face,
measured off [images/sensor_profile.jpg](images/sensor_profile.jpg) with the
plug face lined up against the mat ruler's zero. This - not the bare 7.00 mm
header - is what sets lid clearance. It does **not** include wire bend radius
beyond the plug; budget that separately at the cable exit.

The connector on that board is soldered slightly askew, so this was measured on
a tilted assembly. A tilt projects *longer*, so 11.6 is more likely a small
over-read than an under-read - the safe direction. Do not shave it.

**Design for the tilt.** Hand-soldered connectors are not reliably square to
their board. Wherever the housing constrains the connector or its cable exit,
allow a few degrees of slop (`xh_solder_tilt`) rather than assuming a
perpendicular plug - otherwise a unit that works on the bench will not close.

## Enclosure implications

- **Two enclosures**, MCU end and sensor end, joined by a 4-pin cable. Both
  boards are already built and wired; the enclosures are the remaining work.
  The MCU module as built is documented in [docs/assembly.md](docs/assembly.md).
- **Mount through the perfboard's corner holes, with M2.** M2.5 does not pass.
  The ESP32's own mounting holes are unused - it is soldered to the perfboard -
  so the +/-0.6 mm disagreement in the ESP32 hole pattern no longer matters.
- **The mated connector is the tallest thing inside**, at 13.2 mm above the
  wiring face, against 8.84 mm for the ESP32 stack. The lid is set by the
  connector; `xh_mated_h` behind it is now measured at 11.6 mm.
- **USB-C stands 3.31 mm proud of the perfboard end**, and exits the opposite
  end from the 4-pin cable.
- **Allow 4.4 mm under the board** for untrimmed ESP32 header tails, plus the
  wiring itself.
- **The sensor board has a single mounting hole**, so the sensor end needs one
  boss plus something to stop rotation - a slot, a rib, or the connector itself.
- **The sensor cannot share a sealed volume with the ESP32.** A WROOM-32 with
  Wi-Fi active self-heats enough to bias the temperature reading by several
  degrees C, and it will skew relative humidity along with it. The enclosure
  needs the BME280 in a vented chamber thermally separated from the MCU, most
  practically on a short pigtail.
