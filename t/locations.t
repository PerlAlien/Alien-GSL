use strict;
use warnings;

use Test::More;

use Alien::GSL;
use Alien::GSL::ConfigData;
use File::chdir;

if (Alien::GSL::ConfigData->config('location') eq 'share_dir') {
  no warnings 'once';
  $Alien::GSL::share_dir = 'share_dir';
}

## gsl_prefix
ok( -e Alien::GSL::gsl_prefix, "gsl_prefix directory exists");

## gsl_pkgconfig_location
{
  ok( -e Alien::GSL::gsl_pkgconfig_location, "gsl_pkgconfig_location directory exists");
  local $CWD = Alien::GSL::gsl_pkgconfig_location;

  ok( -e 'gsl.pc', "Found gsl.pc" );
}

## gsl_libs
{

  my @gsl_libs = split ' ', Alien::GSL::gsl_libs;
  ok( scalar @gsl_libs, "Alien::GSL::gsl_libs returns information" );

  my @gsl_libs_locations = grep { /^-L/ } @gsl_libs;
  ok( scalar @gsl_libs_locations, "Alien::GSL::gsl_libs returns locations" );

  my @gsl_libs_libraries = grep { $_ ne '-lm' } grep { /^-l/ } @gsl_libs;
  ok( scalar @gsl_libs_libraries, "Alien::GSL::gsl_libs returns libraries" );

  my @libs_found;

  foreach my $location (@gsl_libs_locations) {
    $location =~ s/^-L//;
    ok( -e $location, "Location exists: $location");
    local $CWD = $location;
    opendir( my $dh, $CWD );
    push @libs_found, grep {! -d} readdir($dh);
  }

  foreach my $lib (@gsl_libs_libraries) {
    $lib =~ s/^-l//;

    my @this_lib_found = grep {/$lib/} @libs_found;
    ok( scalar @this_lib_found, "Found lib: $lib");
  }

}

## gsl_cflags
{

  my @gsl_cflags = split ' ', Alien::GSL::gsl_cflags;
  ok( scalar @gsl_cflags, "Alien::GSL::gsl_cflags returns information" );

  my @gsl_inc = grep { /^-I/ } @gsl_cflags;
  ok( scalar @gsl_inc, "Alien::GSL::gsl_cflags returns include dir(s)" );

  my @headers;

  foreach my $location (@gsl_inc) {
    $location =~ s/^-I//;
    ok( -d $location, "Location exists: $location");
    
    local $CWD = $location;
    ok( -d 'gsl', "A gsl subfolder exists in $location");
    push @CWD, 'gsl';

    opendir( my $dh, $CWD );
    push @headers, grep { /\.h$/ } readdir($dh);
  }

  ok( scalar @headers, "Found headers" );
}

done_testing;
