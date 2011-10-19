#!/usr/bin/env perl

use strict;
use warnings;

use Pod::POM;
use Pod::POM::View::Pod;
 
my $parser = Pod::POM->new();
my $pom = $parser->parse_file('lib/Alien/GSL.pm') || die $parser->error();

open my $fh, '>', 'README.pod';
print $fh Pod::POM::View::Pod->print($pom);
