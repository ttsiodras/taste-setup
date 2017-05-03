PDFFIGS=imgs/assert-logo.pdf \
		  imgs/archi-aadl.pdf \
        imgs/archi-globale.pdf 

AADLMODELS= $(wildcard aadl/*.aadl) 

PDFFILE=output/report.pdf

MAINTEX=report.tex

%.pdf: %.svg
	inkscape --export-pdf=$@ $<

%.pdf: %.png
	convert $< $@

%.pdf: %.jpg
	convert $< $@

all:
	mkdir -p output
	$(MAKE) $(PDFFILE)


html: $(MAINTEX) $(PDFFIGS) $(AADLMODELS)
	mkdir -p output/html
	latex2html -dir output/html -font_size 10pt -scalable_fonts $(MAINTEX)

$(PDFFILE): $(MAINTEX) $(PDFFIGS) $(AADLMODELS)
	pdflatex $(MAINTEX)
	pdflatex $(MAINTEX)
	mv report.pdf $(PDFFILE)


show: $(PDFFILE)
	if [ `uname` = "Linux" ]; then xpdf $(PDFFILE) ; fi
	if [ `uname` = "Darwin" ]; then open $(PDFFILE) ; fi

clean:
	rm -f *~ *.toc *.mtc* *.out *.maf *.aux *.log
	rm -rf output
