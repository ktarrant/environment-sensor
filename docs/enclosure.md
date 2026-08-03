# Enclosure design plan

Three complete units, one per room. Each unit is **two printed enclosures on a
short pigtail**: an MCU box and a sensor pod. The boards are built and will not
be modified, so every dimension here is a consequence of
[`hardware/params.scad`](../hardware/params.scad), not a free choice.

| Unit | Location | MCU box | Sensor pod |
| --- | --- | --- | --- |
| A | Utility room | screwed to the side of a cabinet | hangs below the box on the pigtail |
| B | Sunroom | discreet, sits at the base of the LEGO orchid's pot | styled as a leaf / unbloomed bud |
| C | Living room | freestanding on a bookshelf | short stub arm off the box, front edge |

## The one constraint that drives everything

**The BME280 cannot share air with the WROOM.** A WROOM-32 with Wi-Fi up
self-heats enough to bias temperature by several degrees, and relative humidity
follows the temperature error. That is why there are two enclosures and not one
box with a divider - a divider still shares the wall, and 3D-printed plastic
conducts well enough to matter at these deltas.

Three rules follow, and they are non-negotiable in every variant:

1. **The pod is a separate volume on a pigtail**, 10-20 cm, per the decision
   made for this design.
2. **The pod is never directly above the MCU box.** Warm air off the box rises;
   put the pod level with it or below, and offset laterally. Unit A hangs the
   pod below the box for exactly this reason.
3. **The pod is vented top and bottom** so it convects, and the BME280 can
   itself sits in the airflow rather than behind a wall.

## Architecture: one family, swappable mounts

Do not design three enclosures. Design **one MCU box and one pod**, each with a
mount interface, and make the three locations three small adapter parts.

```
hardware/
  enclosure_common.scad     shell / lid / boss / vent-slot library, no dimensions of its own
  enclosure_mcu.scad        part = "base" | "lid" | "check"
  enclosure_sensor.scad     part = "base" | "lid" | "check";  style = "plain" | "bud"
  mounts.scad               part = "cabinet" | "shelf" | "orchid"
  fitgauge.scad             printed first, before any enclosure
```

The mount interface is a **dovetail or two-screw pad on the MCU box's back
face**, identical across all three, so a unit can be moved between rooms by
reprinting a 5 g adapter instead of the box. Adding this costs almost nothing
now and is very expensive to retrofit.

Every new dimension goes in `params.scad` with a confidence tag, same as
everything else. `enclosure_common.scad` should hardcode nothing.

## MCU box

### The envelope, from the model

`make assembly` echoes these; they are not estimates.

| | |
| --- | --- |
| Board | 60.00 x 40.00, mounted on its four corner holes, **M2 only** |
| Mount pattern | 56.34 x 36.02 |
| Above the wiring face | **13.20** - the mated connector, not the ESP32 |
| ESP32 stack top | 8.84 - 4.4 mm of headroom under the connector's number |
| Below the wiring face | **4.36** - untrimmed ESP32 header tails, plus the wiring itself |
| Total board-to-board | 17.56 |
| USB-C | -X end, stands **3.31 proud** of the board edge, window at Z = 5.74 to 9.00 above the wiring face |
| ESP32 PCB overhang | 1.56 past the -X board edge, under the USB port |

Interior floor-to-lid is therefore **~13.2 + standoff + margin**, and the
standoff must clear 4.36 of pin tails *plus* the wire runs on that face. Start
at **6.0 mm** standoffs and confirm on the real board - the wiring is hand-laid
and nobody has measured how proud it sits.

### The cable exit is the awkward part

The MCU connector is a **straight header on row 20** - the plug pulls
**straight up**, not sideways, and its face is 13.2 mm above the wiring face.
The cable then has to turn 90 degrees to leave the box. It also sits **7.62 mm
off the board centerline** toward column A (columns C..F), so the exit is *not*
on the box's midline. Two options:

- **Side exit at the +X wall** (recommended). Needs the interior to run to
  roughly 13.2 + one cable bend radius above the board, call it 22-24 mm, with
  a slot in the +X wall at the top. Only 5.87 mm separates the connector center
  from the board edge, so the bend is tight - measure the cable's real minimum
  radius before fixing this.
- **Top exit straight through the lid.** Shortest possible box, but the cable
  stands off the lid, which rules it out for the cabinet mount and looks wrong
  in the sunroom.

Whichever is chosen, **allow `xh_solder_tilt` (5 deg)** at the exit and around
the plug. The built connectors are visibly askew; a slot sized for a
perpendicular plug will bench-test fine and then refuse to close.

USB-C exits the **opposite** (-X) wall, so the two openings never interact.
Cut the USB window oversize - `usb_overhang` at 1.75 is flagged in `params.scad`
as the single highest-risk number in the project - and relieve the outside face
so a chunky USB-C overmold can seat.

### Construction

- Tub + lid. Print the tub open-side-up: no supports, and the board seat and
  bosses come out on the flat.
- Four bosses on the 56.34 x 36.02 pattern, M2 clearance through the perfboard
  into a pilot boss. Self-tapping M2 for v1; heat-set inserts are the upgrade
  if a unit is opened repeatedly.
- Lid on 4x M2 into corner posts. Do not design a snap-fit first - snap fits
  need a tuned clearance, and `clearance` is still `[EST]` at 0.20.
- Vent slots in the walls only, vertical, ~1.6 mm (4 nozzle widths) so they
  bridge cleanly. The MCU box vents to keep itself cool; it does **not** need
  to be sensor-grade.

## Sensor pod

Tiny: the board is 13 x 10 and ~2.5 thick. The **connector straddles the
board** - mated plug 11.6 mm off the trace side, components and pin tails ~3.4
on the other - so the envelope across the board is **15.0 mm**, and the pod's
internal cavity lands near 15 x 12 x 18 mm before venting.

Design notes:

- **One mounting hole**, so the pod needs a boss plus something to stop
  rotation: a rib along one long edge, or capture the connector shroud itself.
- **The mounting hole's position is `[EST]` and its Y sign is mirror-ambiguous**
  - it was read off a bottom-side photo. Getting the mirror wrong puts the boss
  ~4 mm out on a 10 mm-wide board. This must be resolved before any pod prints
  (see Measurements below).
- **Chimney venting**: inlet slots low, outlet slots high, on opposite faces,
  with the BME280 can in the path. Cross-drafts are better than a single
  screened window.
- **Sunroom means direct sun.** Sun on a dark pod reads as a temperature spike
  that has nothing to do with the room. Give unit B a double-wall shell - an
  outer decorative skin with an air gap to the inner cavity - which is a
  miniature Stevenson screen wearing a flower costume, and print it light.

## The three variants

### A - utility room, cabinet side

MCU box gets a **flanged back with two keyhole slots** so it drops onto two
pan-head screws already in the cabinet side, then a third screw locks it. Box
vertical, USB-C down so the power lead falls naturally and dust does not settle
in the port. Pod hangs **below** on the pigtail in a plain vented shell, either
free on the cable or clipped to a small bracket 10-15 cm down.

### B - sunroom, LEGO orchid

Two parts, deliberately different in character:

- **MCU box**: low and flat, sitting at the base of the pot, in a colour that
  disappears against it. No LEGO geometry - the orchid model does not offer a
  good attachment, so the box just sits. Cable exits toward the plant.
- **Sensor pod as a leaf or unbloomed bud**: an organic outer shell whose seams
  *are* the vents - louvres reading as leaf veins, or a bud whose petal gaps are
  the airflow path. It hangs or perches among the real LEGO leaves at pot
  height, which is also the height worth measuring in that room.

Print unit B in **PETG, not PLA**. A sunroom behind glass gets near PLA's glass
transition, and a drooping enclosure in a plant is a hard failure to diagnose.

This variant needs the orchid photographed with a scale reference before its
shell is drawn - see below.

### C - living room, bookshelf

Freestanding, so the box carries its own **foot**: stand it on a long edge with
a weighted or wide base so it reads as an object rather than a naked box.
Book-adjacent proportions hide it best. The pod goes on a **short stub arm** off
the front edge so it sits out past the shelf lip and out of the box's thermal
plume, rather than dangling.

## Verifying fit before printing

Two mechanisms, both cheap:

1. **`part = "check"`** in each enclosure file: `intersection()` of the shell
   with the assembly's keepout solids (`esp32_keepout()`,
   `perfboard_keepout()`, `xh_mated_keepout()`). A correct design renders
   **empty**. Anything visible is a collision, found in seconds instead of in
   PLA. This is the natural extension of the `assert()` discipline already in
   the models - asserts catch numbers, this catches geometry.
2. **The fit gauge, printed first**, per the last section of
   [measuring.md](measuring.md). Extend the existing idea to carry, at
   -0.30/-0.15/0/+0.15/+0.30: the USB-C window, an M2 boss, a perfboard corner
   seat, and the cable exit slot. Whatever offset actually fits becomes
   `clearance` in `params.scad`, and every later part inherits a measured
   number instead of a guessed one.

## Measurements still needed

In priority order. Items 1 and 2 block printing; 3 blocks unit B's shell only.

1. **Sensor board, flat and straight down, component side up**, with the header
   pins in frame for scale. Resolves the mounting hole position, the mirror
   ambiguity, and the PCB thickness - all `[EST]` today. The photo method gets
   ~0.1 mm from a flat shot and nothing useful from the hand-held ones we have.
2. **The mated plug and its cable**: plug body width and depth, cable outer
   diameter, and how tightly it will actually bend. This sets the cable exit
   slot and the MCU box's interior height, and there is currently no number for
   any of it.
3. **The LEGO orchid**, photographed with a 2x4 brick (31.8 mm) in frame:
   pot dimensions, leaf scale, and where a pod could plausibly perch.
4. **The cabinet side** - can it be drilled, or does unit A need adhesive
   mounting instead? Different back geometry either way.
5. **M2 hardware on hand**: available screw lengths, and whether heat-set
   inserts are worth buying.

## Order of work

| | |
| --- | --- |
| M0 | Take photos 1-3; add the enclosure block to `params.scad`, tagged |
| M1 | Print the fit gauge; replace `clearance = 0.20 [EST]` with a measured value |
| M2 | MCU box v1, plain, no mount. Fit the real board. Iterate the cable exit |
| M3 | Sensor pod, plain vented. Fit the real sensor board |
| M4 | Three mount adapters; print unit A and unit C |
| M5 | The bud/leaf shell for unit B, in PETG |
| M6 | ESPHome config, then check all three against one reference thermometer in one room before they are dispersed |

M6 is not optional. Three sensors that disagree by a degree are three sensors
you cannot trust; measure the offsets while they are still on the same table.

## Risks

- **`usb_overhang` (1.75, `[PHOTO]`)** - flagged in `params.scad` as the highest
  risk number in the project. The fit gauge retires it.
- **Cable bend radius is unmeasured** and sets the MCU box height. The side-exit
  design falls back to the top exit if the cable turns out to be stiff.
- **The sensor mount hole's mirror ambiguity** - do not print a pod boss until
  photo 1 exists.
- **Thermal validation is empirical.** The vent design is a reasoned guess. M6
  is what tells you whether the pod actually reads room air, and the fix if it
  does not is a longer pigtail, which is why the connector is there.
