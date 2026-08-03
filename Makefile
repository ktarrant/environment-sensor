OPENSCAD ?= /Applications/OpenSCAD-2021.01.app/Contents/MacOS/OpenSCAD

CAM_ISO := --camera=0,0,0,62,0,205,150 --imgsize=1400,1000
CAM_TOP := --camera=0,0,0,0,0,0,105 --projection=o --imgsize=1400,900
SCHEME  := --colorscheme=Tomorrow

.PHONY: all esp32 perfboard connector sensor assembly enclosure fitgauge check renders clean
all: esp32 perfboard connector sensor assembly enclosure fitgauge renders

connector: build/connector.stl
build/connector.stl: hardware/connector.scad hardware/params.scad
	@mkdir -p build
	$(OPENSCAD) -o $@ $<

SENSOR_DEPS := hardware/params.scad hardware/connector.scad
sensor: build/sensor.stl build/sensor_assembly.stl
build/sensor.stl: hardware/sensor.scad $(SENSOR_DEPS)
	@mkdir -p build
	$(OPENSCAD) -o $@ -D 'part="board"' $<
build/sensor_assembly.stl: hardware/sensor.scad $(SENSOR_DEPS)
	@mkdir -p build
	$(OPENSCAD) -o $@ -D 'part="assembly"' $<
images/renders/sensor_assembly_iso.png: hardware/sensor.scad $(SENSOR_DEPS)
	@mkdir -p images/renders
	$(OPENSCAD) -o $@ -D 'part="assembly"' --camera=0,0,0,60,0,200,60 --imgsize=1200,900 $(SCHEME) $<
images/renders/sensor_assembly_top.png: hardware/sensor.scad $(SENSOR_DEPS)
	@mkdir -p images/renders
	$(OPENSCAD) -o $@ -D 'part="assembly"' --camera=0,0,0,0,0,0,48 --projection=o --imgsize=1100,900 $(SCHEME) $<

DEPS := hardware/params.scad hardware/perfboard.scad hardware/esp32.scad \
        hardware/connector.scad
assembly: build/assembly.stl
build/assembly.stl: hardware/assembly.scad $(DEPS)
	@mkdir -p build
	$(OPENSCAD) -o $@ $<
images/renders/assembly_top.png: hardware/assembly.scad $(DEPS)
	@mkdir -p images/renders
	$(OPENSCAD) -o $@ --camera=0,0,0,0,0,-90,150 --projection=o --imgsize=1000,1350 $(SCHEME) $<
images/renders/assembly_iso.png: hardware/assembly.scad $(DEPS)
	@mkdir -p images/renders
	$(OPENSCAD) -o $@ --camera=0,0,0,62,0,200,170 --imgsize=1400,1000 $(SCHEME) $<

# --- enclosures --------------------------------------------------------------
# `make check` renders the box intersected with the hardware keepout. It must
# print "Current top level object is empty" - anything else is a collision.
ENC_DEPS := hardware/params.scad hardware/enclosure_common.scad \
            hardware/assembly.scad hardware/perfboard.scad hardware/esp32.scad \
            hardware/connector.scad
POD_DEPS := hardware/params.scad hardware/enclosure_common.scad \
            hardware/sensor.scad hardware/connector.scad

# Print this BEFORE either enclosure - see the header of fitgauge.scad.
fitgauge: build/fitgauge.stl build/fitgauge_screws.stl
build/fitgauge.stl: hardware/fitgauge.scad hardware/params.scad \
                    hardware/enclosure_common.scad
	@mkdir -p build
	$(OPENSCAD) -o $@ -D 'part="full"' $<
# v2, after the first print failed the fastener row: posts and solid block at
# the same five pilots, one variable each. ~10 min.
build/fitgauge_screws.stl: hardware/fitgauge.scad hardware/params.scad \
                           hardware/enclosure_common.scad
	@mkdir -p build
	$(OPENSCAD) -o $@ -D 'part="screws"' $<
images/renders/fitgauge.png: hardware/fitgauge.scad hardware/params.scad \
                             hardware/enclosure_common.scad
	@mkdir -p images/renders
	$(OPENSCAD) -o $@ --camera=0,0,0,55,0,340,150 --imgsize=1400,900 $(SCHEME) $<
enclosure: build/enclosure_mcu_base.stl build/enclosure_mcu_lid.stl \
           build/enclosure_pod_a.stl build/enclosure_pod_b.stl
build/enclosure_mcu_base.stl: hardware/enclosure_mcu.scad $(ENC_DEPS)
	@mkdir -p build
	$(OPENSCAD) -o $@ -D 'part="base"' $<
build/enclosure_mcu_lid.stl: hardware/enclosure_mcu.scad $(ENC_DEPS)
	@mkdir -p build
	$(OPENSCAD) -o $@ -D 'part="lid"' $<
build/enclosure_pod_a.stl: hardware/enclosure_sensor.scad $(POD_DEPS)
	@mkdir -p build
	$(OPENSCAD) -o $@ -D 'part="a"' $<
build/enclosure_pod_b.stl: hardware/enclosure_sensor.scad $(POD_DEPS)
	@mkdir -p build
	$(OPENSCAD) -o $@ -D 'part="b"' $<
check: hardware/enclosure_mcu.scad hardware/enclosure_sensor.scad \
       $(ENC_DEPS) $(POD_DEPS)
	@mkdir -p build
	@echo "MCU box:"
	@$(OPENSCAD) -o build/enclosure_mcu_check.stl -D 'part="check"' \
	  hardware/enclosure_mcu.scad 2>&1 | grep -E "top level object|WARNING"
	@echo "sensor pod:"
	@$(OPENSCAD) -o build/enclosure_pod_check.stl -D 'part="check"' \
	  hardware/enclosure_sensor.scad 2>&1 | grep -E "top level object|WARNING"
images/renders/enclosure_mcu_iso.png: hardware/enclosure_mcu.scad $(ENC_DEPS)
	@mkdir -p images/renders
	$(OPENSCAD) -o $@ -D 'part="assembled"' -D 'show_grid=false' \
	  --camera=0,0,4,62,0,205,185 --imgsize=1400,1000 $(SCHEME) $<
images/renders/enclosure_mcu_exploded.png: hardware/enclosure_mcu.scad $(ENC_DEPS)
	@mkdir -p images/renders
	$(OPENSCAD) -o $@ -D 'part="exploded"' -D 'show_grid=false' \
	  --camera=0,0,8,66,0,205,215 --imgsize=1400,1100 $(SCHEME) $<
images/renders/enclosure_pod_exploded.png: hardware/enclosure_sensor.scad $(POD_DEPS)
	@mkdir -p images/renders
	$(OPENSCAD) -o $@ -D 'part="exploded"' \
	  --camera=0,0,-4,72,0,300,140 --imgsize=1300,1000 $(SCHEME) $<
images/renders/enclosure_pod_iso.png: hardware/enclosure_sensor.scad $(POD_DEPS)
	@mkdir -p images/renders
	$(OPENSCAD) -o $@ -D 'part="assembled"' \
	  --camera=0,0,-4,62,0,215,110 --imgsize=1300,1000 $(SCHEME) $<

esp32: build/esp32.stl
build/esp32.stl: hardware/esp32.scad hardware/params.scad
	@mkdir -p build
	$(OPENSCAD) -o $@ $<

# ~30 s: CGAL differencing the ~300 hole grid. Set show_grid=false for speed.
perfboard: build/perfboard.stl
build/perfboard.stl: hardware/perfboard.scad hardware/params.scad
	@mkdir -p build
	$(OPENSCAD) -o $@ $<

renders: images/renders/esp32_iso.png images/renders/esp32_top.png \
         images/renders/perfboard_top.png images/renders/assembly_top.png \
         images/renders/assembly_iso.png images/renders/sensor_assembly_iso.png \
         images/renders/sensor_assembly_top.png \
         images/renders/enclosure_mcu_iso.png \
         images/renders/enclosure_mcu_exploded.png \
         images/renders/enclosure_pod_iso.png \
         images/renders/enclosure_pod_exploded.png \
         images/renders/fitgauge.png
images/renders/perfboard_top.png: hardware/perfboard.scad hardware/params.scad
	@mkdir -p images/renders
	$(OPENSCAD) -o $@ --camera=0,0,0,0,0,0,140 --projection=o --imgsize=1200,850 $(SCHEME) $<
images/renders/esp32_iso.png: hardware/esp32.scad hardware/params.scad
	@mkdir -p images/renders
	$(OPENSCAD) -o $@ $(CAM_ISO) $(SCHEME) $<
images/renders/esp32_top.png: hardware/esp32.scad hardware/params.scad
	@mkdir -p images/renders
	$(OPENSCAD) -o $@ $(CAM_TOP) $(SCHEME) $<

clean:
	rm -rf build
