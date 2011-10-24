#!/usr/bin/env perl

use strict;
use warnings;

use Alien::GSL;
use Alien::GSL::ConfigData;

use Getopt::Long;

my $location = Alien::GSL::ConfigData->config('location');
die "This is the 'gsl-config' provided by the Alien::GSL Perl module. You probably want the system installed 'gsl-config'. Sorry\n" 
  if ($location eq 'system');

usage() unless (@ARGV);

my ($version, $libs, $libs_wo_cblas, $cflags, $prefix, $help);
GetOptions(
  'version'            => \$version,
  'libs'               => \$libs,
  'libs-without-cblas' => \$libs_wo_cblas,
  'cflags'             => \$cflags,
  'prefix'             => \$prefix,
  'help'               => \$help,
);

if ($version) {
  print Alien::GSL::gsl_version() . "\n";
  exit;
}

if ($libs) {
  print Alien::GSL::gsl_libs() . "\n";
  exit;
}

if ($libs_wo_cblas) {
  print Alien::GSL::gsl_libs( cblas => 0 ) . "\n";
  exit;
}

if ($cflags) {
  print Alien::GSL::gsl_cflags() . "\n";
  exit;
}

if ($prefix) {
  print Alien::GSL::gsl_prefix() . "\n";
  exit;
}

usage() if $help;

sub usage {
  print <<'USAGE';
Usage: gsl-config [OPTION]

Known values for OPTION are:

  --prefix		show GSL installation prefix 
  --libs		print library linking information, with cblas
  --libs-without-cblas	print library linking information, without cblas
  --cflags		print pre-processor and compiler flags
  --help		display this help and exit
  --version		output version information
USAGE
  exit;
}

