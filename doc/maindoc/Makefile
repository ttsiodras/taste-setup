PDFFIGS= imgs/assert-logo.pdf							\
	imgs/deploymentview.pdf							\
	imgs/deploymentview-processor-board.pdf					\
	imgs/development-process.pdf						\
	imgs/interface-view-pi-data.pdf						\
	imgs/interface-view-pi-menu.pdf						\
	imgs/interface-view-two-functions.pdf					\
	imgs/interface-view.pdf							\
	imgs/iv_example.pdf							\
	imgs/tastegui.pdf							\
	imgs/tastegui-tasted.pdf							\
	imgs/orchestrator-process.pdf							\
	imgs/msc.pdf							\
	imgs/msc1.pdf							\
	imgs/deploymentview-ex.pdf						\
	imgs/interface-view-pi-properties.pdf					\
	imgs/interface-view-two-functions2.pdf					\
	imgs/interface-view-pi-data2.pdf				\
	imgs/tastegui-gcov.pdf \
	imgs/tastegui-mast.pdf \
	imgs/tastegui-code-generation-menu.pdf \
	imgs/tastegui-mast-menu.pdf \
	imgs/tastegui-main-codegen-conf.pdf \
	imgs/tastegui-main-codegen.pdf \
	imgs/tastegui-main-req.pdf \
	imgs/tastegui-main-sched.pdf \
	imgs/tastegui-vcd-conf.pdf \
	imgs/gtkwave.pdf \
	imgs/tastegui-main.pdf \
	imgs/rtds-tasteiv.pdf \
	imgs/tastegui-xcov-report.pdf \
	imgs/rtds-rtds.pdf \
	imgs/tastegui-compilation-flags.pdf \
	imgs/tasted-exec-protocol.pdf \
	imgs/iv_simulink.png



PDFFILE=taste-documentation.pdf

%.pdf: %.svg
	inkscape --export-pdf=$@ $<

%.pdf: %.png
	convert $< $@

%.pdf: %.jpg
	convert $< $@

all:
	mkdir -p output
#	$(MAKE) html
	cp -f `ocarina-config --prefix`/share/ocarina/AADLv2/taste_properties.aadl .
	cp -f `ocarina-config --prefix`/include/ocarina/runtime/polyorb-hi-c/src/drivers/configuration/1553.asn .
	cp -f `ocarina-config --prefix`/include/ocarina/runtime/polyorb-hi-c/src/drivers/configuration/ip.asn .
	cp -f `ocarina-config --prefix`/include/ocarina/runtime/polyorb-hi-c/src/drivers/configuration/serial.asn .
	cp -f `ocarina-config --prefix`/include/ocarina/runtime/polyorb-hi-c/src/drivers/configuration/spacewire.asn .
	cp -f ../../components-db/src/db-schema.sql db-schema.sql
	$(MAKE) $(PDFFILE)


html: taste-documentation.tex $(PDFFIGS)
	mkdir -p output/html
	latex2html -dir output/html -font_size 10pt -scalable_fonts taste-documentation.tex

$(PDFFILE): taste-documentation.tex $(PDFFIGS)
	pdflatex taste-documentation.tex
	bibtex taste-documentation.aux
	pdflatex taste-documentation.tex
	pdflatex taste-documentation.tex

show: $(PDFFILE)
	if [ `uname` = "Linux" ]; then xpdf $(PDFFILE) ; fi
	if [ `uname` = "Darwin" ]; then open $(PDFFILE) ; fi

clean:
	rm -f *~ *.toc *.mtc* *.out *.maf *.aux *.log *.pdf taste_properties.aadl db-schema.sql *.asn
