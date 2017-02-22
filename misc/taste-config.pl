#!/usr/bin/perl -w

use strict;
use File::Basename;
use Getopt::Long;

my $show_packages;
my $show_orchestrator_path;
my $show_buildsupport_path;
my $show_directives_path;
my $show_dmt_path;
my $show_prefix;
my $result;
my $tmp;
my @tmp;
my $prefix = "INSTALL_PREFIX";


$show_prefix            = 0;
$show_packages          = 0;
$show_orchestrator_path = 0;
$show_buildsupport_path = 0;
$show_directives_path   = 0;
$show_dmt_path          = 0;

$result = GetOptions ("prefix"       => \$show_prefix,
                      "orchestrator" => \$show_orchestrator_path,
                      "buildsupport" => \$show_buildsupport_path,
                      "directives"   => \$show_directives_path,
                      "dmt"          => \$show_dmt_path,
                      "packages"     => \$show_packages);


sub help
{
   print STDERR "Usage: $0 OPTIONS\n";
   print STDERR "Options are:\n";
   print STDERR "   --prefix        - output the TASTE installation prefix\n";
   print STDERR "   --packages      - output the list of installed TASTE packages\n";
   print STDERR "   --orchestrator  - output the list of PATH of the orchestrator\n";
   print STDERR "   --buildsupport  - output the list of PATH of buildsupport\n";
   print STDERR "   --dmt           - output the list of PATH of DMT tools\n";
   print STDERR "   --directives    - output the PATH of the directives file\n";
   exit 1;
}

sub find_dmt_path
{
   my $ret;
   my $tmp;

   $ret = "/foo/bar/i/want/a/hp/touchpad/";

   $tmp = `which asn1.exe`;
   chomp ($tmp);
   if (-x $tmp)
   {
      $tmp =~ s/\/[a-zA-Z0-9\.exe]+$//;
      $tmp =~ s/[a-zA-Z0-9]+$//;
      $ret = $tmp;
   }
   else
   {
      opendir (DIR , "/opt") or exit 1;

      @tmp = readdir (DIR);

      foreach (@tmp)
      {
         if ( (/^DMT-ToolsAndManual.*/) && (-f "/opt/$_/License.txt"))
         {
            $ret = "/opt/$_/";
         }
      }
      closedir (DIR);
   }

   return $ret if (-d $ret);
   return undef;
}

if ($show_prefix == 1)
{
   print "$prefix\n";
   exit 0;
}
elsif ($show_directives_path == 1)
{
   $tmp = $prefix . "/share/taste/TASTE-Directives.asn";
   if (-f $tmp)
   {
      print "$tmp\n";
      exit 0;
   }
   else
   {
      print "DIRECTIVES FILES NOT FOUND\n";
      exit 1;
   }
}
elsif ($show_buildsupport_path == 1)
{
   $tmp = $prefix . "/bin/buildsupport";
   if (-x $tmp)
   {
      print $tmp . "\n";
      exit 0;
   }
   else
   {
      print STDERR "NOT INSTALLED";
      exit 1;
   }
}
elsif ($show_orchestrator_path == 1)
{
   $tmp = $prefix . "/bin/assert-builder-ocarina.py";
   if (-x $tmp)
   {
      print $tmp . "\n";
      exit 0;
   }
   else
   {
      print STDERR "NOT INSTALLED";
      exit 1;
   }
}
elsif ($show_dmt_path == 1)
{
   $tmp = find_dmt_path ();
   if (defined ($tmp) && ( -d $tmp ))
   {
      print $tmp . "\n";
      exit 0;
   }
   else
   {
      print STDERR "DMT NOT INSTALLED\n";
      exit 1;
   }
}
elsif ($show_packages == 1)
{
   $tmp = find_dmt_path ();

   print "INSTALLED TASTE PACKAGES\n";
   print "   * Ocarina\n" if (-x "$prefix/bin/ocarina");
   print "   * Orchestrator\n" if (-x "$prefix/bin/assert-builder-ocarina.py");
   print "   * Buildsupport\n" if (-x "$prefix/bin/buildsupport");
   print "   * PolyORB-HI-C runtime\n" if (-d "$prefix/include/ocarina/runtime/polyorb-hi-c/");
   print "   * PolyORB-HI-Ada runtime\n" if (-d "$prefix/include/ocarina/runtime/polyorb-hi-ada/");
   print "   * TASTEGUI\n" if (-x "$prefix/bin/tastegui");
   print "\n";

   if (defined ($tmp) && ( -d $tmp) )
   {
      print "DMT TOOLS are installed in $tmp\n";
   }
   exit 0;
}
else
{
   help();
   exit 1;
}
