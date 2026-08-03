# Measuring the boards without calipers

We have no caliper, and a tape measure is worth about ±1 mm — not enough for an
enclosure with a USB-C cutout. Fortunately we don't need one.

## The trick: the header pitch is the ruler

Both boards use **2.54 mm (0.100") header pitch**. That tolerance is held by the
connector manufacturer to well under 0.1 mm, and there are 18 gaps of it across
the ESP32. So instead of measuring the board, we *count pins* and multiply, then
use the same pitch as the scale reference for everything else.

This makes the measurement self-calibrating: any error in camera distance, lens
distortion, or scanner DPI cancels out, because the reference and the subject are
in the same image at the same scale.

## Procedure

1. Lay the board **flat, component side up**, on a plain sheet of white paper.
   Graph paper is a nice sanity check but is not the reference — the pins are.
2. Shoot **straight down**, phone as far back as focus allows, then crop in.
   Distance reduces perspective error; a close-up wide-angle shot will bow the
   edges outward and inflate every dimension.
3. Diffuse light, no flash. A hard shadow along one edge reads as extra board.
4. Take a second shot of the board **on its side**, so the USB-C connector's
   height and how far it overhangs the PCB edge are both visible in profile.
   This is the shot that determines whether the port cutout works.

Four images total: ESP32 top, ESP32 profile, BME280 top, BME280 profile.

A flatbed scanner at 600 dpi beats all of this if one is available — put the board
face down on the glass, leave the lid open, and scan. That is caliper-grade.

## What comes out of it

Derived from pin count alone, no measurement needed:

| Quantity | Derivation | Value |
| --- | --- | --- |
| ESP32 outer pin centers, along length | 14 gaps x 2.54 | **35.56 mm** |
| BME280 header span | depends on pin count, see BOM.md | 5 gaps x 2.54 = 12.7 mm |

This is also how the ESP32 was *identified*: counting 15 pins per row, not 19,
established that it is a 30-pin DevKit V1 rather than the 38-pin board the BOM
originally assumed. The silkscreen label sequence confirmed it independently.

Read off the images, scaled against the pitch:

- PCB length and width, and the pin inset from each edge
- PCB thickness (profile shot; expect ~1.6 mm, the near-universal standard)
- USB-C shell width, height, overhang past the PCB edge, and its offset from the
  board centerline
- Tallest component and its clearance above the PCB (the WROOM-32 can, and the
  electrolytic cap if present)
- BME280: **pin count** — 4 vs 6 tells us which variant shipped, which we still
  need to confirm. See BOM.md.

## What this produced for the ESP32

Worked end to end on images/ESP32_top.jpg. The pitch fit landed on all 30 pins,
giving a scale of **8.66 px/mm** and a board rotation of only 0.17 deg. Measured
outline: 51.4 +/- 0.9 x 28.7 +/- 0.4 mm, which agreed with the DevKit V1 3MF's
51.50 x 28.50 and so validated that model for the rest of the geometry.

Two cautions learned in the process:

- **The vertical axis reads ~1% high.** The board sat left of and below the
  frame center, so it is viewed slightly obliquely and the horizontal pitch
  reference does not transfer cleanly to the vertical. Board width and header
  row spacing both came out high by about that much. Center the part in frame
  next time, or scan it.
- **A downloaded model is not evidence.** The 3MF is excellent in plan but
  flattened in height, and its USB-C overhang (0.70 mm) disagrees with the photo
  (1.75 mm). Where the two conflict on something the enclosure touches, the
  photo of the actual part wins.

## Closing the loop on the first print

Even with good numbers, print a **fit gauge** before printing the enclosure: a
thin plate carrying the USB-C cutout and the board-seat pocket at several
tolerance offsets (-0.3, -0.15, 0, +0.15, +0.3 mm). It takes a few minutes to
print, and it converts a wrong number into a known number by finding which slot
actually fits. That measured offset then feeds back into `params.scad` as the
printer's real-world clearance, and every later part inherits it.
