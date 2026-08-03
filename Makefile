OPENSCAD ?= /Applications/OpenSCAD-2021.01.app/Contents/MacOS/OpenSCAD

CAM_ISO := --camera=0,0,0,62,0,205,150 --imgsize=1400,1000
CAM_TOP := --camera=0,0,0,0,0,0,105 --projection=o --imgsize=1400,900
SCHEME  := --colorscheme=Tomorrow

.PHONY: all esp32 renders clean
all: esp32 renders

esp32: build/esp32.stl
build/esp32.stl: hardware/esp32.scad hardware/params.scad
	@mkdir -p build
	$(OPENSCAD) -o $@ $<

renders: images/renders/esp32_iso.png images/renders/esp32_top.png
images/renders/esp32_iso.png: hardware/esp32.scad hardware/params.scad
	@mkdir -p images/renders
	$(OPENSCAD) -o $@ $(CAM_ISO) $(SCHEME) $<
images/renders/esp32_top.png: hardware/esp32.scad hardware/params.scad
	@mkdir -p images/renders
	$(OPENSCAD) -o $@ $(CAM_TOP) $(SCHEME) $<

clean:
	rm -rf build
