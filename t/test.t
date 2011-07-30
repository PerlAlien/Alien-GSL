use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Alien::GSL') };

ok( Alien::GSL::have() > 0, "Found GSL" );

