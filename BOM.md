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

**Two things to check the moment the board is in hand:**

1. **Which variant is it?** The listing title says *"BME280 **5V** Sensor
   Module"*. The 5V board and the common 3.3V GY-BME280 are physically different
   parts, and the 5V one usually carries an onboard LDO and/or level shifter.
   **Count the pins** - 6 (VCC/GND/SCL/SDA/CSB/SDO) or 4 (I2C only) - and look
   for a small regulator next to the VCC pin. For reference, the 3.3V variant is
   [verified at 15.5 x 11.5 mm, 6-pin, no regulator](https://protosupplies.com/product/gy-bme280-pressure-humidity-temperature-sensor-module/).

2. **Is it actually a BME280?** These cheap multipacks are notorious for
   shipping BMP280 instead - same footprint, no humidity. If ESPHome reports
   pressure and temperature but humidity reads `nan`, that is what happened.

### Wiring depends on the answer to (1)

| Variant | VCC connects to |
| --- | --- |
| Plain 3.3V GY-BME280 (no regulator) | ESP32 **3V3** |
| 5V variant **with** onboard LDO | ESP32 **VIN / 5V** - an LDO fed 3.3V will drop out and the sensor will read erratically or not enumerate |

Either way SCL/SDA go to the ESP32's I2C pins (GPIO22 / GPIO21 by default) and
GND to GND.

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

### The corner holes are smaller than they look

They measure **~1.85 mm** (four holes: 1.56 / 1.79 / 1.93 / 1.93). That makes
them **M2 at the absolute best** - an M2 screw is 2.0 mm across the threads and
will be interference or simply will not pass. **M3 is definitively out.**

Options, in rough order of preference: open the holes to 2.2 mm and use M2;
use M1.6; or skip screws entirely and capture the board by its edges in a slot,
which avoids the question and is easier to print. Worth settling with an actual
screw before any of this is committed to.

### Corrections the real photo forced

The listing image ([perfboard_4x6.png](images/perfboard_4x6.png)) is only
7.0 px/mm and got three things wrong, all now fixed:

| | listing image | actual board |
| --- | --- | --- |
| Grid rows | 21 (inferred) | **20** (silkscreen) |
| Corner hole dia | 2.2-2.5 mm | **~1.85 mm** |
| Edge features | oval *holes* | **SMD pads**, nothing drilled |
| Edge pad pitch | assumed 2.54 | **~2.70**, its own pitch |

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

**Unverified and it matters:** the **mated height** with the plug pushed on.
`xh_mated_h = 11.50` is an estimate, and it - not the bare header - is what sets
the lid clearance. Measure the plug on a cable you already have.

## Enclosure implications

- **Two enclosures**, MCU end and sensor end, joined by a 4-pin cable. Both
  boards are already built and wired; the enclosures are the remaining work.
  The MCU module as built is documented in [docs/assembly.md](docs/assembly.md).
- **Mount through the perfboard's corner holes, with M2.** M2.5 does not pass.
  The ESP32's own mounting holes are unused - it is soldered to the perfboard -
  so the +/-0.6 mm disagreement in the ESP32 hole pattern no longer matters.
- **The mated connector is the tallest thing inside**, at 13.1 mm above the
  wiring face, against 8.84 mm for the ESP32 stack. The lid is set by the
  connector, and `xh_mated_h` behind it is still an estimate.
- **USB-C stands 3.31 mm proud of the perfboard end**, and exits the opposite
  end from the 4-pin cable.
- **Allow 4.4 mm under the board** for untrimmed ESP32 header tails, plus the
  wiring itself.
- **No mounting holes** on either sensor variant, so retention at the sensor end
  is a slot or clip, not screw bosses.
- **The sensor cannot share a sealed volume with the ESP32.** A WROOM-32 with
  Wi-Fi active self-heats enough to bias the temperature reading by several
  degrees C, and it will skew relative humidity along with it. The enclosure
  needs the BME280 in a vented chamber thermally separated from the MCU, most
  practically on a short pigtail.
