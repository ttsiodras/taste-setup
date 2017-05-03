FLAGS=-f -aadlv2
FILES=protocol.aadl ping.aadl software.aadl `ocarina-config --prefix`/share/ocarina/AADLv2/ocarina_components.aadl

parse:
	ocarina $(FLAGS) $(FILES)

instantiate:
	ocarina -i $(FLAGS) $(FILES)

clean:
	$(RM) *~ 
