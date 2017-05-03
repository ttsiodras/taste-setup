FIGFILES=imgs/taste-model-iv.eps \
			imgs/taste-model-dv.eps \
			imgs/simulink-model.eps \
			imgs/taste-process.eps

all: $(FIGFILES)
	pdflatex avicps2012.tex
	pdflatex avicps2012.tex
	bibtex avicps2012
	pdflatex avicps2012.tex
	pdflatex avicps2012.tex

%.eps: %.png
	convert $< $@

clean:
	rm -f *~ *.log *.aux *.pdf

