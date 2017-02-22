#!/usr/bin/perl -w
use strict;

if (scalar @ARGV != 1) {
    die "Usage: $0 deploymentView.aadl\n";
}

$/=undef;

my $allText = <>;

my $anchor = "-- copied aadl libraries";

$allText =~ s/$anchor.*$//s;
print $allText.$anchor;
