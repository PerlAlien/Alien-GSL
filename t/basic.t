use strict;
use warnings;

use Test::More tests => 3;
BEGIN { use_ok('Alien::GSL') };

ok( Alien::GSL::have_gsl_version() > 0, "Found GSL" );

my @found = Alien::GSL::available();

ok( @found > 1, "Finds GSL versions available for download" );


