OPENSCAD ?= /Applications/OpenSCAD-2021.01.app/Contents/MacOS/OpenSCAD

CAM_ISO := --camera=0,0,0,62,0,205,150 --imgsize=1400,1000
CAM_TOP := --camera=0,0,0,0,0,0,105 --projection=o --imgsize=1400,900
SCHEME  := --colorscheme=Tomorrow

.PHONY: all esp32 perfboard connector assembly renders clean
all: esp32 perfboard connector assembly renders

connector: build/connector.stl
build/connector.stl: hardware/connector.scad hardware/params.scad
	@mkdir -p build
	$(OPENSCAD) -o $@ $<

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
         images/renders/assembly_iso.png
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
