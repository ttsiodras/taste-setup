#!/usr/bin/perl -w
use strict;

select((select(STDOUT), $| = 1)[0]);
 
open DATA, "/home/assert/Demo_Simulink/binary.linux/binaries/mygui_GUI |";

my $data0 = "0";
my $data1 = "0";
while(<DATA>) {
	if (/^togui::gui_in::myint\D+(\d+)/) {
		print "0:$1\n";
	}
       elsif (/^togui::gui_in::myseq::y\D+(\d+)/) {
		print "1:$1\n"; 
	}
}
close DATA;
