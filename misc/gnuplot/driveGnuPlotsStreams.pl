#!/usr/bin/perl -w
use strict;

sub usage {
    print "Usage: $0 <options>\n";
    print <<OEF;
where options are (in order):

  NumberOfStreams                         How many streams to plot (windows)
  Stream1_WindowSampleSize <Stream2...>   This many window samples for each stream
  Stream1_Title <Stream2_Title> ...       Title used for each stream
  Stream1_geometry <Stream2_geometry>...  X and Y position in pixels from the top left

The last parameters (geometries) are of the form: WIDTHxHEIGHT+XOFF+YOFF
OEF
    exit(1);
}

sub Arg {
    if ($#ARGV < $_[0]) {
	print "Expected parameter missing...\n\n";
	usage;
    }
    $ARGV[int($_[0])];
}

sub main {
    my $argIdx = 0;
    my $numberOfStreams = Arg($argIdx++);
    print "Will display $numberOfStreams Streams (in $numberOfStreams windows)...\n";
    my @sampleSizes;
    for(my $i=0; $i<$numberOfStreams; $i++) {
	my $samples = Arg($argIdx++);
	push @sampleSizes, $samples;
	print "Stream ".($i+1)." will use a window of $samples samples\n";
    }
    my @titles;
    for(my $i=0; $i<$numberOfStreams; $i++) {
	my $title = Arg($argIdx++);
	push @titles, $title;
	print "Stream ".($i+1)." will use a title of '$title'\n";
    }
    my @geometries;
    for(my $i=0; $i<$numberOfStreams; $i++) {
	my $geometry = Arg($argIdx++);
	push @geometries, $geometry;
	print "Stream ".($i+1)." will use a geometry of '$geometry'\n";
    }
    my $terminal = "";
    open GNUPLOT_TERM, "echo 'show terminal;' | gnuplot 2>&1 |";
    while (<GNUPLOT_TERM>) {
	if (m/terminal type is (\w+)/) {
	    $terminal=$1;
	}
    }
    close GNUPLOT_TERM;

    # unfortunately, the wxt terminal type does not support positioning. 
    # hardcode it...
    $terminal  = "x11";

    my @gnuplots;
    my @buffers;
    my @xcounters;
    shift @ARGV; # number of streams
    for(my $i=0; $i<$numberOfStreams; $i++) {
	shift @ARGV; # sample size
	shift @ARGV; # miny
	shift @ARGV; # maxy
	shift @ARGV; # title
	shift @ARGV; # geometry
	local *PIPE;
	my $geometry = $geometries[$i];
	open PIPE, "|gnuplot -geometry $geometry" || die "Can't initialize gnuplot number ".($i+1)."\n";
	select((select(PIPE), $| = 1)[0]);
	push @gnuplots, *PIPE;
	print PIPE "set xtics\n";
	print PIPE "set ytics\n";
	print PIPE "set style data linespoints\n";
	print PIPE "set grid\n";
	if ($numberOfStreams == 1) {
	    print PIPE "set terminal $terminal title '".$titles[0]."' noraise\n";
	} else {
	    print PIPE "set terminal $terminal noraise\n";
	}
	print PIPE "set autoscale\n";
	my @data = [];
	push @buffers, @data;
	push @xcounters, 0;
    }
    my $streamIdx = 0;
    select((select(STDOUT), $| = 1)[0]);
    while(<>) {
	chomp;
	my @parts = split /:/;
	$streamIdx = $parts[0];
	my $buf = $buffers[$streamIdx];
	my $pip = $gnuplots[$streamIdx];
	my $xcounter = $xcounters[$streamIdx];
	my $title = $titles[$streamIdx];

	# data buffering (up to stream sample size)
	push @{$buf}, $parts[1];
	#print "stream $streamIdx: ";
	print $pip "set xrange [".($xcounter-$sampleSizes[$streamIdx]).":".($xcounter+1)."]\n";
	if ($numberOfStreams == 1) {
	    print $pip "plot \"-\"\n";
	} else {
	    print $pip "plot \"-\" title '$title'\n";
	}
	my $cnt = 0;
	for my $elem (reverse @{$buf}) {
	    #print " ".$elem;
	    print $pip ($xcounter-$cnt)." ".$elem."\n";
	    $cnt += 1;
	}
	#print "\n";
	print $pip "e\n";
	if ($cnt>=$sampleSizes[$streamIdx]) {
	    shift @{$buf};
	}
	$xcounters[$streamIdx]++;
    }
    for(my $i=0; $i<$numberOfStreams; $i++) {
	my $pip = $gnuplots[$i];
	print $pip "exit;\n";
	close $pip;
    }
}

main;
