# MCU module - as built

The ESP32 and the 4-pin connector are soldered to a 4x6 cm perfboard. Both
units of this design are already built; what follows documents them.

## Which face is which

Components are on the face **opposite** the silkscreen. The wiring runs on the
silkscreen face, so the A..N / 1..20 grid labels stay readable while soldering.

In the model, the component face is +Z and the wiring face is Z = 0.

## Wiring

| # | Signal | Connector | ESP32 hole | ESP32 pin | Wire |
| --- | --- | --- | --- | --- | --- |
| 1 | Power  | C20 (pin 1) | L2  | `3V3`          | red |
| 2 | Ground | D20         | B3  | `GND`          | black |
| 3 | Clock  | E20         | L15 | `GPIO22 (SCL)` | orange |
| 4 | Data   | F20         | L12 | `GPIO21 (SDA)` | blue |

## The wiring is the placement

[assembly.scad](../hardware/assembly.scad) does not eyeball the layout from the
photos. It solves the ESP32's position from wire 1 alone, then **asserts** that
wires 2, 3 and 4 land on their own holes. Three independent checks on one
placement - if any dimension feeding into it were wrong, the render would fail
rather than quietly drift.

The photos are used only to confirm the result and to fix handedness (which
header row faces which way).

A useful by-product: the ESP32's two header rows land on columns **B and L**,
exactly **10 pitches = 25.40 mm** apart. A part physically seated in a 2.54 mm
grid cannot be at any other spacing, so this settles a row-spacing figure that
neither the 3MF (25.74) nor direct photo measurement (25.86) had pinned down.

## Resulting geometry

Origin at the perfboard center, Z = 0 at the wiring face, +X toward row 20
(the connector end), +Y toward column A.

| | |
| --- | --- |
| ESP32 offset from board center | (-5.81, +1.27) mm |
| ESP32 PCB bottom | 4.14 mm (1.6 board + 2.54 header plastic) |
| ESP32 stack top (WROOM) | 8.84 mm |
| **Connector, mated** | **13.20 mm - this sets the lid height** |
| Below the wiring face | 4.36 mm of untrimmed ESP32 header tail |
| Total envelope | 17.56 mm |

Two consequences worth carrying into the enclosure:

- **The USB-C port stands 3.31 mm proud of the perfboard's end.** The ESP32
  itself overhangs that end by 1.56 mm, and the connector shell adds another
  1.75 mm. The port cutout is positioned by the ESP32, not by the board edge.
- **USB-C and the 4-pin cable exit opposite ends** - USB at -X, the cable at
  +X. Convenient: the two openings never compete for the same wall.

The tallest item is the mated connector, not the ESP32. `xh_mated_h` is now
measured at **11.6 mm** from `images/sensor_profile.jpg`. It does not include
wire bend radius past the plug - budget that separately at the cable exit.

## Fasteners

M2 passes the perfboard's corner holes; M2.5 does not. Mount through the
perfboard's four corners - the ESP32's own mounting holes are unused, since it
is soldered to the perfboard.
