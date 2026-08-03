# environment-sensor
ESPHome device with ESP32 and BME280 to report Temp/Humidity to Home Assistant

Physically it is two enclosures joined by a 4-pin cable: an MCU end and a sensor
end. The circuit boards are built; the enclosures are in design.

## Layout

| | |
| --- | --- |
| [BOM.md](BOM.md) | The exact parts, with what is verified and what is not |
| [docs/assembly.md](docs/assembly.md) | **The wiring**, and the MCU module as built |
| [docs/measuring.md](docs/measuring.md) | How parts were dimensioned without a caliper |
| [hardware/](hardware/) | OpenSCAD models. `params.scad` holds every dimension |
| [reference/](reference/) | Third-party models kept for cross-checking |
| [images/](images/) | Photos the dimensions were measured from, and renders |

## Build

Needs OpenSCAD (2021.01 tested). `make` writes STLs to `build/` and renders to
`images/renders/`.

```
make                    # everything
make assembly           # just the MCU module
OPENSCAD=/path/to/openscad make
```

## Wiring

Components sit on the face opposite the perfboard silkscreen; the wiring runs on
the silkscreen face so the A..N / 1..20 grid stays readable while soldering.

| # | Signal | Connector | ESP32 hole | ESP32 pin | Wire |
| --- | --- | --- | --- | --- | --- |
| 1 | Power  | C20 (pin 1) | L2  | `3V3`          | red |
| 2 | Ground | D20         | B3  | `GND`          | black |
| 3 | Clock  | E20         | L15 | `GPIO22 (SCL)` | orange |
| 4 | Data   | F20         | L12 | `GPIO21 (SDA)` | blue |
