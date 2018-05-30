# Check that ocarina_components.aadl parses correctly
# and install all AADL libraries to Ocarina install folder to make
# the available to buildsupport et al.
# Also copy IV/DV Properties files to Ellidiss GUI folder

check:
	ocarina -f -aadlv2 ocarina_components.aadl

install:
	@echo "Installing AADL libraries in Ocarina"
	@# Patch hardcoded paths on the fly to work with actual install path
	@cat ocarina_components.aadl | \
	   sed "s,/home/taste/tool-inst,$(shell taste-config --prefix)," > \
	   "$(shell ocarina-config --resources)/AADLv2/ocarina_components.aadl"
	@cp TASTE*.aadl $(shell ocarina-config --resources)/AADLv2
	@cp taste*.aadl $(shell ocarina-config --resources)/AADLv2
	@cp TASTE*.aadl ../../ellidiss-GUI/TASTE-linux/config
	@cp TASTE*.aadl ../../ellidiss-GUI/TASTE-linux64/config
	@cp TASTE*.aadl ../../ellidiss-GUI/TASTE-v1-linux/config
	@mkdir -p $(shell taste-config --prefix)/share/config_ellidiss
	@cp TASTE*.aadl $(shell taste-config --prefix)/share/config_ellidiss  # legacy
