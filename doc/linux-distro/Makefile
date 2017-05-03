PDFFIGS= 

PDFFILE=taste-linux.pdf

%.pdf: %.svg
	inkscape --export-pdf=$@ $<

%.pdf: %.png
	convert $< $@

%.pdf: %.jpg
	convert $< $@

all:
	mkdir -p output
	$(MAKE) $(PDFFILE)


$(PDFFILE): taste-linux.tex $(PDFFIGS)
	pdflatex taste-linux.tex
	bibtex taste-linux.aux
	pdflatex taste-linux.tex
	pdflatex taste-linux.tex

show: $(PDFFILE)
	if [ `uname` = "Linux" ]; then xpdf $(PDFFILE) ; fi
	if [ `uname` = "Darwin" ]; then open $(PDFFILE) ; fi

clean:
	rm -f *~ *.toc *.mtc* *.out *.maf *.aux *.log *.pdf *.blg *.bbl
