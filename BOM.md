# Bill of Materials

## Exact parts this build used

| Part | Product | Source |
| --- | --- | --- |
| **MCU** | ELEGOO ESP-32 Development Board, 3-pack | Micro Center [#704603](https://www.microcenter.com/product/704603/ESP-32_Development_Board_-_3_Pack), Mfr 50.303.0052 |
| **Sensor** | BME280 5V Sensor Module, 2-pack (GY-BME280) | Amazon [B0DHPCFXCK](https://www.amazon.com/dp/B0DHPCFXCK) |

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

## Enclosure implications

- **No mounting holes** on either sensor variant, so board retention is a slot
  or clip, not screw bosses.
- **The sensor cannot share a sealed volume with the ESP32.** A WROOM-32 with
  Wi-Fi active self-heats enough to bias the temperature reading by several
  degrees C, and it will skew relative humidity along with it. The enclosure
  needs the BME280 in a vented chamber thermally separated from the MCU, most
  practically on a short pigtail.
